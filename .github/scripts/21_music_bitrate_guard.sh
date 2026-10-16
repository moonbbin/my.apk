#!/bin/bash
# 21 - 音乐音质验货（防糊）
# 背景：resolveAndPlay 向音源脚本请求高音质时，只要脚本返回非空 URL 就直接播放，
# 从不校验实际码率；音源常回 128k 链接冒充高音质，导致听感发糊。
# 本脚本给 LxPlayerManager 打补丁：
#   1. 新增验货函数：Range 取前 64KB，FLAC 解析 STREAMINFO 采样精度，
#      MP3 解析帧头平均码率，实测档位必须 >= 请求档位才放行；
#   2. 验货不通过则换平台继续试，并记录档位最高的备选 URL；
#   3. 全部试完无达标时降级播放备选（不断歌），实在没有才走原失败流程。
# 幂等：已打过补丁则跳过。
set -e
cd avbox

echo "=== 音乐音质验货补丁（防糊） ==="

python3 << 'PYEOF'
import re

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// ============ 音质验货（防糊） ============"
if MARK in src:
    print("跳过（已打补丁）: " + path)
    raise SystemExit(0)

def must_have(old: str):
    if old not in src:
        print("警告: 锚点未命中: " + old[:70].replace("\n", "\\n"))

# ---- 1. 插入验货函数（放在 probeAndSetQuality 之后） ----
anchor1 = '''    fun probeAndSetQuality(url: String) {
        _currentQuality.value = detectQualityFromUrl(url)
    }
'''
must_have(anchor1)

verify_fns = '''
    // ============ 音质验货（防糊） ============
    // 请求高音质时，用文件头实测直链真实档位，不达标就换平台继续试。
    // 档位：3=Hi-Res(24bit FLAC) 2=FLAC/无损 1=320k档 0=普通/未知

    private fun tierOfQuality(q: String): Int = when (q) {
        "flac24bit" -> 3
        "flac" -> 2
        "320k" -> 1
        else -> 0 // 128k 及未知：底线档，来者不拒
    }

    private fun probeBytes(url: String, size: Int): ByteArray? {
        return try {
            val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "GET"
            conn.connectTimeout = 6000
            conn.readTimeout = 6000
            conn.instanceFollowRedirects = true
            conn.setRequestProperty("Range", "bytes=0-${size - 1}")
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14)")
            conn.connect()
            val code = conn.responseCode
            if (code != 200 && code != 206) { conn.disconnect(); return null }
            val buf = ByteArray(size)
            var off = 0
            conn.inputStream.use { ins ->
                while (off < size) {
                    val n = ins.read(buf, off, size - off)
                    if (n <= 0) break
                    off += n
                }
            }
            conn.disconnect()
            if (off < 64) null else buf.copyOf(off)
        } catch (e: Exception) {
            Log.w(TAG, "验货探测失败: ${e.message}")
            null
        }
    }

    // FLAC STREAMINFO 解析采样精度 bits per sample；失败返回 0
    private fun flacBitsPerSample(b: ByteArray): Int {
        return try {
            if (b.size < 42) return 0
            if (!(b[0] == 0x66.toByte() && b[1] == 0x4C.toByte() && b[2] == 0x61.toByte() && b[3] == 0x43.toByte())) return 0
            if ((b[4].toInt() and 0x7F) != 0) return 0 // 首块不是 STREAMINFO
            // STREAMINFO bytes[10..17]：20bit 采样率 | 3bit 声道数-1 | 5bit 精度-1 | 36bit 总采样数
            // 精度-1 = byte[12]最低位<<4 | byte[13]高4位；文件偏移 = 8 + 12/13
            (((b[20].toInt() and 0x01) shl 4) or ((b[21].toInt() ushr 4) and 0x0F)) + 1
        } catch (e: Exception) { 0 }
    }

    // MP3 帧头解析平均码率(kbps)，采样最多 8 帧；失败返回 0
    private fun mp3BitrateKbps(b: ByteArray): Int {
        return try {
            var pos = 0
            if (b.size > 10 && b[0] == 0x49.toByte() && b[1] == 0x44.toByte() && b[2] == 0x33.toByte()) {
                val tagSize = ((b[6].toInt() and 0x7F) shl 21) or ((b[7].toInt() and 0x7F) shl 14) or
                        ((b[8].toInt() and 0x7F) shl 7) or (b[9].toInt() and 0x7F)
                pos = 10 + tagSize
            }
            val brMpeg1L3 = intArrayOf(0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320)
            val brMpeg2L3 = intArrayOf(0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160)
            val ratesMpeg1 = intArrayOf(44100, 48000, 32000, 0)
            val ratesMpeg2 = intArrayOf(22050, 24000, 16000, 0)
            var sum = 0
            var cnt = 0
            var i = pos
            while (i + 4 < b.size && cnt < 8) {
                if (b[i] == 0xFF.toByte() && (b[i + 1].toInt() and 0xE0) == 0xE0) {
                    val ver = (b[i + 1].toInt() ushr 3) and 0x03
                    val layer = (b[i + 1].toInt() ushr 1) and 0x03
                    val brIdx = (b[i + 2].toInt() ushr 4) and 0x0F
                    val rateIdx = (b[i + 2].toInt() ushr 2) and 0x03
                    if (ver != 1 && layer == 1 && brIdx in 1..14 && rateIdx in 0..2) {
                        val table = if (ver == 3) brMpeg1L3 else brMpeg2L3
                        val rates = if (ver == 3) ratesMpeg1 else ratesMpeg2
                        val br = table[brIdx]
                        val rate = rates[rateIdx]
                        if (br > 0 && rate > 0) { sum += br; cnt++ }
                        val pad = (b[i + 2].toInt() ushr 1) and 0x01
                        val coeff = if (ver == 3) 144 else 72
                        val frameLen = coeff * br * 1000 / rate + pad
                        i += if (frameLen > 4) frameLen else 1
                        continue
                    }
                }
                i++
            }
            if (cnt == 0) 0 else sum / cnt
        } catch (e: Exception) { 0 }
    }

    private fun isAacBytes(b: ByteArray): Boolean {
        if (b.size < 8) return false
        if (b[0] == 0xFF.toByte() && (b[1].toInt() and 0xF0) == 0xF0) return true // ADTS
        return b[4] == 0x66.toByte() && b[5] == 0x74.toByte() && b[6] == 0x79.toByte() && b[7] == 0x70.toByte() // ftyp
    }

    // 实测档位；-1=无法探测
    private fun probeTier(url: String): Int {
        val bytes = probeBytes(url, 65536) ?: return -1
        if (bytes.size >= 42 && bytes[0] == 0x66.toByte() && bytes[1] == 0x4C.toByte() &&
            bytes[2] == 0x61.toByte() && bytes[3] == 0x43.toByte()
        ) {
            return if (flacBitsPerSample(bytes) >= 24) 3 else 2
        }
        val mp3br = mp3BitrateKbps(bytes)
        if (mp3br > 0) return if (mp3br >= 224) 1 else 0
        if (isAacBytes(bytes)) return 1 // AAC 细验成本高，按高档位放行
        return -1
    }

    // 验货：实测档位必须 >= 请求档位；探测失败时放行避免误杀
    private fun verifyQuality(requested: String, url: String): Boolean {
        val need = tierOfQuality(requested)
        if (need <= 0) return true
        val got = probeTier(url)
        if (got < 0) return true
        val ok = got >= need
        if (!ok) Log.i(TAG, "音质验货不通过: 请求=$requested(档$need) 实测档$got url=${url.take(80)}")
        return ok
    }
'''
src = src.replace(anchor1, anchor1 + verify_fns)

# ---- 2. 备选记录变量 ----
anchor2 = '''                var qualityIndex = 0
                var candidateIndex = 0
'''
must_have(anchor2)
src = src.replace(anchor2, anchor2 + '''                // 验货备选：记录所有尝试中实测档位最高的 URL，全部不达标时降级播放
                var bestUrl: String? = null
                var bestTier = -1
                var bestMeta: Map<String, String> = emptyMap()
''')

# ---- 3. onSuccess 改为验货再播 ----
anchor3 = '''                                onSuccess = { url ->
                                    if (url.isNotBlank()) {
                                            // 文件头魔数备用（回调覆盖）
                                            val realQuality = detectQualityFromUrl(url)
                                            Log.i(TAG, "真实音质检测: $realQuality (url=${url.take(80)})")
                                            mainHandler.post {
                                                _currentQuality.value = realQuality
                                                setLoading(false)
                                                setError(null)
                                                recordHistory(cand.songMap + ("url" to url))
                                                play(url, cand.songMap["title"] ?: title, cand.songMap["artist"] ?: artist, cand.songMap["picUrl"] ?: pic)
                                            }
                                    } else {
'''
must_have(anchor3)
new3 = '''                                onSuccess = { url ->
                                    if (url.isNotBlank()) {
                                        // 验货：实测档位必须 >= 请求档位，否则换平台继续试（防糊）
                                        if (!verifyQuality(q, url)) {
                                            val tier = probeTier(url).coerceAtLeast(0)
                                            if (tier > bestTier) {
                                                bestTier = tier
                                                bestUrl = url
                                                bestMeta = cand.songMap
                                            }
                                            Log.w(TAG, "音质 $q @平台 ${cand.plat} 验货不达标(实测档$tier)，换平台重试")
                                            candidateIndex++
                                            tryNext()
                                        } else {
                                            val realQuality = detectQualityFromUrl(url)
                                            Log.i(TAG, "真实音质检测: $realQuality (url=${url.take(80)})")
                                            mainHandler.post {
                                                _currentQuality.value = realQuality
                                                setLoading(false)
                                                setError(null)
                                                recordHistory(cand.songMap + ("url" to url))
                                                play(url, cand.songMap["title"] ?: title, cand.songMap["artist"] ?: artist, cand.songMap["picUrl"] ?: pic)
                                            }
                                        }
                                    } else {
'''
src = src.replace(anchor3, new3)

# ---- 4. 全部试完：有备选就降级播放 ----
anchor4 = '''                    if (qualityIndex >= tryOrder.size) {
                        mainHandler.post {
                            setLoading(false)
                            // 自动切下一曲，失败才报错
                            if (!tryAutoNextOnFailure()) {
                                setError("获取播放地址失败（已尝试所有音质与平台）")
                            }
                        }
                        return
                    }
'''
must_have(anchor4)
new4 = '''                    if (qualityIndex >= tryOrder.size) {
                        // 全部档位试完：有备选就播档位最高的，别让用户听不到歌
                        val fallbackUrl = bestUrl
                        if (fallbackUrl != null) {
                            val fbMeta = bestMeta
                            Log.i(TAG, "无达标音质，降级播放备选（档$bestTier）: ${fallbackUrl.take(80)}")
                            mainHandler.post {
                                val realQuality = detectQualityFromUrl(fallbackUrl)
                                _currentQuality.value = realQuality
                                setLoading(false)
                                setError(null)
                                recordHistory(fbMeta + ("url" to fallbackUrl))
                                play(fallbackUrl, fbMeta["title"] ?: title, fbMeta["artist"] ?: artist, fbMeta["picUrl"] ?: pic)
                            }
                        } else {
                            mainHandler.post {
                                setLoading(false)
                                // 自动切下一曲，失败才报错
                                if (!tryAutoNextOnFailure()) {
                                    setError("获取播放地址失败（已尝试所有音质与平台）")
                                }
                            }
                        }
                        return
                    }
'''
src = src.replace(anchor4, new4)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("已打补丁: " + path)
PYEOF

echo "=== 音质验货补丁完成 ==="
