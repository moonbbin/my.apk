#!/bin/bash
# 21 - 音乐音质验货（防糊）v2
# 背景：resolveAndPlay 向音源脚本请求高音质时，只要脚本返回非空 URL 就直接播放，
# 从不校验实际码率；音源常回 128k 链接冒充高音质，导致听感发糊。
# v1：Range 取前 64KB 验货（FLAC 解析 STREAMINFO 采样精度、MP3 解析帧头码率），
#     实测档位必须 >= 请求档位才放行，否则换平台继续试；全部试完无达标则降级
#     播放档位最高的备选（不断歌）。
# v2 新增：
#   1. tierLabel()：实测档位 → UI 真实标签（3→Hi-Res / 2→FLAC / 1→320k / 0→普通），
#      替换原来靠文件魔数猜的假标签；并把 qualityLabel() 的 "320k"->"HQ" 改为
#      "320k"->"320k"，保证显示与枚举一致。
#   2. 探测失败（tier=-1）时 UI 显示"未知"，绝不把"探测不到"误报成"普通"。
#   3. _measuredBitrate 回传：MP3 取多帧码率中位数（抗静音段波动），FLAC 用
#      Content-Range 总大小 ÷ STREAMINFO 总时长估算平均码率；拿不到填 0，
#      UI（已支持"实测约 Xkbps"）自动隐藏。
#   4. FLAC 码率估算：平均码率 = 总大小×8 ÷ 总时长；总大小来自 Content-Range，
#      拿不到（服务器回 200 不给）则填 0，不误导用户。
# 幂等：已打 v2 跳过；打过 v1 的走增量升级；全新文件走全量补丁。
set -e
cd avbox

echo "=== 音乐音质验货补丁（防糊）v2 ==="

python3 << 'PYEOF'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V2 = "// ============ 音质验货（防糊）v2 ============"
MARK_V1 = "// ============ 音质验货（防糊） ============"

# ---- v1 残留块（增量升级时整体替换；由生成器填入 v1 脚本中的精确原文） ----
OLD_FNS = '''
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
OLD_ONSUCC = '''                                onSuccess = { url ->
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
OLD_FALLBACK = '''                    if (qualityIndex >= tryOrder.size) {
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

# ---- v2 新块 ----
NEW_FNS = '''
    // ============ 音质验货（防糊）v2 ============
    // 请求高音质时，用文件头实测直链真实档位：不达标就换平台继续试；
    // 实测档位与码率回传 UI，替换原来靠文件魔数猜的假标签。
    // 档位：3=Hi-Res(24bit FLAC) 2=FLAC/无损 1=320k档 0=普通；-1=无法探测

    private fun tierOfQuality(q: String): Int = when (q) {
        "flac24bit" -> 3
        "flac" -> 2
        "320k" -> 1
        else -> 0 // 128k 及未知：底线档，来者不拒
    }

    // 档位标签：回传 UI 的真实档位（替换假标签）。
    // 注意 qualityLabel() 对 "Hi-Res"/"FLAC"/"普通"/"未知" 原样返回；"320k" 已在
    // qualityLabel 中修正为显示 "320k"（原为"HQ"），保证与枚举一致。
    private fun tierLabel(tier: Int): String = when (tier) {
        3 -> "Hi-Res"
        2 -> "FLAC"
        1 -> "320k"
        else -> "普通"
    }

    // Range 取前 size 字节；同时从 Content-Range 解析文件总大小（拿不到返回 -1）。
    // 返回 Pair(字节数组, 总大小)；失败返回 null。网络侧只有这一次请求，最多读
    // size 字节就 disconnect()，服务器回 200 全量也不会多跑流量。
    private fun probeBytes(url: String, size: Int): Pair<ByteArray, Long>? {
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
            // Content-Range: bytes 0-65535/12345678 → 斜杠后为文件总大小
            var total: Long = -1
            try {
                val cr = conn.getHeaderField("Content-Range") ?: ""
                val slash = cr.lastIndexOf('/')
                if (slash >= 0) total = cr.substring(slash + 1).trim().toLongOrNull() ?: -1
                if (total <= 0 && code == 200) total = conn.getHeaderFieldLong("Content-Length", -1)
            } catch (_: Exception) { }
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
            if (off < 64) null else Pair(buf.copyOf(off), total)
        } catch (e: Exception) {
            Log.w(TAG, "验货探测失败: ${e.message}")
            null
        }
    }

    // FLAC STREAMINFO 解析：返回 Triple(采样率, 采样精度bits, 总采样数)；失败返回 null。
    // STREAMINFO bytes[10..17] = 20bit 采样率 | 3bit 声道数-1 | 5bit 精度-1 | 36bit 总采样数
    private fun flacStreamInfo(b: ByteArray): Triple<Int, Int, Long>? {
        return try {
            if (b.size < 42) return null
            if (!(b[0] == 0x66.toByte() && b[1] == 0x4C.toByte() && b[2] == 0x61.toByte() && b[3] == 0x43.toByte())) return null
            if ((b[4].toInt() and 0x7F) != 0) return null // 首块不是 STREAMINFO
            val rate = ((b[18].toInt() and 0xFF) shl 12) or ((b[19].toInt() and 0xFF) shl 4) or ((b[20].toInt() ushr 4) and 0x0F)
            // 精度-1 = byte[12]最低位<<4 | byte[13]高4位；文件偏移 = 8(STREAMINFO起始)+12/13
            val bps = (((b[20].toInt() and 0x01) shl 4) or ((b[21].toInt() ushr 4) and 0x0F)) + 1
            // 总采样数 36bit = byte[13]低4位 + bytes[14..17]；文件偏移 21..25
            var total = ((b[21].toInt() and 0x0F).toLong() shl 32)
            for (k in 22..25) {
                total = (total or (((b[k].toInt() and 0xFF).toLong()) shl ((25 - k) * 8)))
            }
            if (rate <= 0) return null
            Triple(rate, bps, total)
        } catch (e: Exception) { null }
    }

    // MP3 帧头解析码率中位数(kbps)：采样最多 8 帧取中位数，抗静音段/波动干扰；失败返回 0。
    // 注意：采样在内存中对已下载的字节做，不产生额外网络请求。
    private fun mp3BitrateKbps(b: ByteArray): Int {
        return try {
            var pos = 0
            // 跳过 ID3v2 标签（常带封面，可达数 KB，帧头在其之后）
            if (b.size > 10 && b[0] == 0x49.toByte() && b[1] == 0x44.toByte() && b[2] == 0x33.toByte()) {
                val tagSize = ((b[6].toInt() and 0x7F) shl 21) or ((b[7].toInt() and 0x7F) shl 14) or
                        ((b[8].toInt() and 0x7F) shl 7) or (b[9].toInt() and 0x7F)
                pos = 10 + tagSize
            }
            val brMpeg1L3 = intArrayOf(0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320)
            val brMpeg2L3 = intArrayOf(0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160)
            val ratesMpeg1 = intArrayOf(44100, 48000, 32000, 0)
            val ratesMpeg2 = intArrayOf(22050, 24000, 16000, 0)
            val found = mutableListOf<Int>()
            var i = pos
            while (i + 4 < b.size && found.size < 8) {
                if (b[i] == 0xFF.toByte() && (b[i + 1].toInt() and 0xE0) == 0xE0) {
                    val ver = (b[i + 1].toInt() ushr 3) and 0x03   // 3=MPEG1，2/0=MPEG2/2.5
                    val layer = (b[i + 1].toInt() ushr 1) and 0x03 // 1=Layer III
                    val brIdx = (b[i + 2].toInt() ushr 4) and 0x0F
                    val rateIdx = (b[i + 2].toInt() ushr 2) and 0x03
                    if (ver != 1 && layer == 1 && brIdx in 1..14 && rateIdx in 0..2) {
                        val table = if (ver == 3) brMpeg1L3 else brMpeg2L3
                        val rates = if (ver == 3) ratesMpeg1 else ratesMpeg2
                        val br = table[brIdx]
                        val rate = rates[rateIdx]
                        if (br > 0 && rate > 0) found.add(br)
                        val pad = (b[i + 2].toInt() ushr 1) and 0x01
                        val coeff = if (ver == 3) 144 else 72
                        val frameLen = coeff * br * 1000 / rate + pad
                        i += if (frameLen > 4) frameLen else 1
                        continue
                    }
                }
                i++
            }
            if (found.isEmpty()) 0 else found.sorted()[found.size / 2]
        } catch (e: Exception) { 0 }
    }

    private fun isAacBytes(b: ByteArray): Boolean {
        if (b.size < 8) return false
        if (b[0] == 0xFF.toByte() && (b[1].toInt() and 0xF0) == 0xF0) return true // ADTS
        return b[4] == 0x66.toByte() && b[5] == 0x74.toByte() && b[6] == 0x79.toByte() && b[7] == 0x70.toByte() // ftyp
    }

    // 验货：返回 Pair(实测档位, 实测kbps)；档位 -1=无法探测，kbps 拿不到=0。
    // 码率只许用文件头解析，禁止"总文件大小÷歌曲时长"（播放前链路无 duration）。
    private fun probeAudio(url: String): Pair<Int, Int> {
        val probed = probeBytes(url, 65536) ?: return Pair(-1, 0)
        val bytes = probed.first
        val totalBytes = probed.second
        // FLAC：STREAMINFO 定档位（24bit=Hi-Res 档）；平均码率 = 总大小×8÷总时长
        val info = flacStreamInfo(bytes)
        if (info != null) {
            val tier = if (info.second >= 24) 3 else 2
            var kbps = 0
            if (totalBytes > 0 && info.third > 0) {
                val durationSec = info.third.toDouble() / info.first
                if (durationSec > 0) kbps = (totalBytes * 8.0 / durationSec / 1000).toInt()
            }
            return Pair(tier, kbps)
        }
        // MP3：帧头码率中位数定档位（>=224k 算 320k 档）
        val mp3br = mp3BitrateKbps(bytes)
        if (mp3br > 0) return Pair(if (mp3br >= 224) 1 else 0, mp3br)
        // AAC：细验成本高，按高档位放行，码率未知
        if (isAacBytes(bytes)) return Pair(1, 0)
        return Pair(-1, 0)
    }
'''
NEW_ONSUCC = '''                                onSuccess = { url ->
                                    if (url.isNotBlank()) {
                                        // 验货：实测档位必须 >= 请求档位，否则换平台继续试（防糊）。
                                        // probeAudio 只做一次 Range（≤64KB），结果复用于档位判定与 UI 回传。
                                        val probed = probeAudio(url) // first=档位(-1=无法探测)，second=实测kbps(0=未知)
                                        val tier = probed.first
                                        val kbps = probed.second
                                        val need = tierOfQuality(q)
                                        if (tier >= 0 && tier < need) {
                                            if (tier > bestTier) {
                                                bestTier = tier
                                                bestKbps = kbps
                                                bestUrl = url
                                                bestMeta = cand.songMap
                                            }
                                            Log.w(TAG, "音质 $q @平台 ${cand.plat} 验货不达标(实测档$tier)，换平台重试")
                                            candidateIndex++
                                            tryNext()
                                        } else {
                                            // 达标或无法探测：播放，并把真实档位/码率回传 UI（替换假标签）。
                                            // 探测失败显示"未知"，绝不把"探测不到"误报成"普通"。
                                            val label = if (tier >= 0) tierLabel(tier) else "未知"
                                            Log.i(TAG, "真实音质: $label${if (kbps > 0) " 约${kbps}kbps" else ""} (url=${url.take(80)})")
                                            mainHandler.post {
                                                _currentQuality.value = label
                                                setLoading(false)
                                                setError(null)
                                                recordHistory(cand.songMap + ("url" to url))
                                                play(url, cand.songMap["title"] ?: title, cand.songMap["artist"] ?: artist, cand.songMap["picUrl"] ?: pic)
                                                // play() 内会清零 _measuredBitrate，故在此之后赋值
                                                _measuredBitrate.value = kbps
                                            }
                                        }
                                    } else {
'''
NEW_FALLBACK = '''                    if (qualityIndex >= tryOrder.size) {
                        // 全部档位试完：有备选就播档位最高的，别让用户听不到歌
                        val fallbackUrl = bestUrl
                        if (fallbackUrl != null) {
                            val fbMeta = bestMeta
                            Log.i(TAG, "无达标音质，降级播放备选（${tierLabel(bestTier)}）: ${fallbackUrl.take(80)}")
                            mainHandler.post {
                                // 播什么档显示什么档；码率用备选中记录的实测值
                                _currentQuality.value = tierLabel(bestTier)
                                setLoading(false)
                                setError(null)
                                recordHistory(fbMeta + ("url" to fallbackUrl))
                                play(fallbackUrl, fbMeta["title"] ?: title, fbMeta["artist"] ?: artist, fbMeta["picUrl"] ?: pic)
                                _measuredBitrate.value = bestKbps
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

# ---- 全新文件锚点（由生成器填入 v1 脚本中的精确原文） ----
ANCHOR1 = '''    fun probeAndSetQuality(url: String) {
        _currentQuality.value = detectQualityFromUrl(url)
    }
'''
ANCHOR2 = '''                var qualityIndex = 0
                var candidateIndex = 0
'''
ANCHOR3 = '''                                onSuccess = { url ->
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
ANCHOR4 = '''                    if (qualityIndex >= tryOrder.size) {
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
NEW_VARS_FULL = '''                // 验货备选：记录所有尝试中实测档位最高的 URL，全部不达标时降级播放
                var bestUrl: String? = null
                var bestTier = -1
                var bestKbps = 0
                var bestMeta: Map<String, String> = emptyMap()
'''

def rep(old, new):
    global src
    if old not in src:
        print("错误: 锚点未命中: " + old[:80].replace("\n", "\\n"))
        sys.exit(1)
    src = src.replace(old, new, 1)

# qualityLabel 显示修正：v1/v2 通用，与验货版本无关
HQ_ANCHOR = '        "320k" -> "HQ"'
HQ_NEW = '        "320k" -> "320k" // v2：与 tierLabel 枚举一致，显示"320k"而非"HQ"'

if MARK_V2 in src:
    print("跳过（已是 v2）: " + path)
elif MARK_V1 in src:
    print("检测到 v1，增量升级 → v2")
    rep(OLD_FNS, NEW_FNS)            # 函数块整体替换（含标记升级为 v2）
    rep(OLD_ONSUCC, NEW_ONSUCC)      # 验货调用点：单次探测 + 真实档位/码率回传 UI
    rep(OLD_FALLBACK, NEW_FALLBACK)  # 降级路径：显示备选档位 + 回传备选码率
    rep("                var bestTier = -1\n",
        "                var bestTier = -1\n                var bestKbps = 0\n")
    if HQ_ANCHOR in src:
        rep(HQ_ANCHOR, HQ_NEW)
    print("v1 → v2 增量升级完成")
else:
    print("全新文件，走全量 v2 补丁")
    rep(ANCHOR1, ANCHOR1 + NEW_FNS)
    rep(ANCHOR2, ANCHOR2 + NEW_VARS_FULL)
    rep(ANCHOR3, NEW_ONSUCC)
    rep(ANCHOR4, NEW_FALLBACK)
    if HQ_ANCHOR in src:
        rep(HQ_ANCHOR, HQ_NEW)
    print("全量 v2 补丁完成")

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("=== 音质验货补丁 v2 完成 ===")
PYEOF

echo "=== 完成 ==="
