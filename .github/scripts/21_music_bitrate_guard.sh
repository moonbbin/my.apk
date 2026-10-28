#!/bin/bash
# 21 - 播放器音质验货（防糊）：v18
# ============================================================================
# 版本导航（v1→v9 一句话）：
#   v1：Range 取前 64KB 验货（FLAC 解析 STREAMINFO、MP3 解析帧头），实测档位须≥请求档
#       位才播放，不达标换平台；全试完无达标则播最高备选（不断歌）。
#   v2：tierLabel 档位→UI 标签（3=Hi-Res/2=FLAC/1=320k/0=普通）；"320k"显示修正；
#       _measuredBitrate 回传 UI。
#   v3：FLAC 码率改用 STREAMINFO min/max 帧长估算（不依赖 Content-Range）；新增假无损
#       识别：FLAC<400kbps 降为 0 档继续找真货；kbps=0 时不降档（防误杀）。
#   v4：新增 isSuspiciousLossless()（FLAC<500/24bit<800 判可疑），供 22 显示⚠；
#       22 v4.2 已内联，此函数成死代码（保留无害）。
#   v5：tierOfQuality 识别 master/atmos/hires→4 档（母带）；解决脚本支持 Hi-Res
#       但 App 不认的问题。
#   v6：7 档全映射——6=母带(master)/5=全景声+(atmos_plus)/4=全景声(atmos)/
#       3=Hi-Res(hires/flac24bit)/2=FLAC/1=320k/0=普通。
#   v7：尝试升级 QUALITY_ORDER 请求顺序（精确匹配失败，未生效）。
#   v8：宽松正则全文件扫描质量序列（未命中真实格式，未生效）。
#   v9：解码 13 号 base64 找到真实锚点（LxPlayerManager.kt:297
#       `val QUALITY_ORDER = listOf("flac24bit","flac","320k","128k")`），精确替换为
#       master→atmos_plus→atmos→hires→flac24bit→flac→320k→128k。生效。
# ----------------------------------------------------------------------------
# 关键锚点速查（改代码时定位用）：
#   QUALITY_ORDER  请求顺序（LxPlayerManager.kt:297，v9 目标）
#   tierOfQuality()  质量→档位映射（v6 定义 7 档）
#   tierLabel()      档位→中文标签（v6 定义）
#   getQualityTryOrder()/qualityTryOrder()  按用户偏好截取请求顺序
#   verifyQuality()  验货入口：实测档位须≥请求档位
#   probeTier()      探测 URL 真实档位（FLAC/MP3/AAC 解析）
#   isSuspiciousLossless()  v4 死代码（22 已内联，不用动）
# ============================================================================
# 幂等：已打过 v9 则跳过；支持 v6/v7/v8 → v9 增量升级；锚点未命中则报错退出（v7/v8
#      的宽松逻辑保留但已验证 v9 精确锚点为最终生效路径）。
set -e
cd avbox

echo "=== 播放器音质验货补丁 v7 ==="

python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK_V6 = "// ============ 音质验货（防糊）v6 ============"
MARK_V5 = "// ============ 音质验货（防糊）v5 ============"
MARK_V3 = "// ============ 音质验货（防糊）v3 ============"
MARK_V2 = "// ============ 音质验货（防糊）v2 ============"
MARK_V1 = "// ============ 音质验货（防糊） ============"

OLD_FNS_V1 = '''
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
V2_FNS = '''
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
NEW_FNS_V3 = '''
    // ============ 音质验货（防糊）v6 ============
    // 请求高音质时，用文件头实测直链真实档位：不达标就换平台继续试；
    // 实测档位与码率回传 UI，替换原来靠文件魔数猜的假标签。
    // 档位：6=母带 5=全景声+ 4=全景声 3=Hi-Res 2=FLAC 1=320k 0=普通；-1=无法探测

    private fun tierOfQuality(q: String): Int = when (q) {
        "master" -> 6 // 母带：最高档
        "atmos_plus" -> 5 // 全景声+
        "atmos" -> 4 // 全景声
        "hires", "flac24bit" -> 3 // Hi-Res
        "flac" -> 2 // 无损
        "320k" -> 1 // 高品
        else -> 0 // 128k 及以下：底线档，来者不拒
    }

    // 档位标签：回传 UI 的真实档位（替换假标签）。
    // 注意 qualityLabel() 对 "Hi-Res"/"FLAC"/"普通"/"未知" 原样返回；"320k" 已在
    // qualityLabel 中修正为显示 "320k"（原为"HQ"），保证与枚举一致。
    private fun tierLabel(tier: Int): String = when (tier) {
        6 -> "母带"
        5 -> "全景声+"
        4 -> "全景声"
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

    // FLAC 码率估算（不需要文件总大小）：1) STREAMINFO 的 min/max 帧长直接算；
    // 2) 扫描帧同步点取中位帧长；都失败返回 0。用于服务器不返回 Content-Range 时兜底。
    private fun flacBitrateEstimate(b: ByteArray, rate: Int): Int {
        return try {
            if (b.size < 42 || rate <= 0) return 0
            // STREAMINFO：min/max block size = bytes[8..11]，min/max frame size = bytes[12..17]
            val minBlock = ((b[8].toInt() and 0xFF) shl 8) or (b[9].toInt() and 0xFF)
            val maxBlock = ((b[10].toInt() and 0xFF) shl 8) or (b[11].toInt() and 0xFF)
            val blockSize = if (minBlock == maxBlock) minBlock else 0
            val minFrame = ((b[12].toInt() and 0xFF) shl 16) or ((b[13].toInt() and 0xFF) shl 8) or (b[14].toInt() and 0xFF)
            val maxFrame = ((b[15].toInt() and 0xFF) shl 16) or ((b[16].toInt() and 0xFF) shl 8) or (b[17].toInt() and 0xFF)
            if (blockSize > 0 && minFrame > 0 && maxFrame > 0) {
                val avgFrame = (minFrame + maxFrame) / 2.0
                return (avgFrame * 8.0 * rate / blockSize / 1000).toInt()
            }
            // 帧扫描兜底：跳过 metadata 区，找帧同步点(0xFF,0xF8)，中位间距即中位帧长
            var audioStart = 42
            try {
                var p = 4
                var last = false
                while (!last && p + 4 <= b.size) {
                    last = (b[p].toInt() and 0x80) != 0
                    val len = ((b[p + 1].toInt() and 0xFF) shl 16) or
                              ((b[p + 2].toInt() and 0xFF) shl 8) or
                              (b[p + 3].toInt() and 0xFF)
                    p += 4 + len
                    if (p < 0) break
                }
                if (p in 42..b.size) audioStart = p
            } catch (_: Exception) { }
            val syncs = mutableListOf<Int>()
            var i = audioStart
            while (i + 2 < b.size && syncs.size < 24) {
                if (b[i] == 0xFF.toByte() && (b[i + 1].toInt() and 0xFE) == 0xF8) {
                    syncs.add(i)
                    i += 16 // 跳过帧头，避免头内误匹配
                } else i++
            }
            if (syncs.size >= 4 && blockSize > 0) {
                val dists = mutableListOf<Int>()
                for (k in 1 until syncs.size) dists.add(syncs[k] - syncs[k - 1])
                dists.sort()
                val n = dists.size
                val med = dists[n / 2]
                val q1 = dists[n / 4]
                val q3 = dists[n * 3 / 4]
                // 周期性校验（分位数，容忍少量误检）：真帧间距大致均匀
                if (med >= 64 && q1 * 2 >= med && q3 <= med * 2) {
                    return (med * 8.0 * rate / blockSize / 1000).toInt()
                }
            }
            0
        } catch (e: Exception) { 0 }
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
            var tier = if (info.second >= 24) 3 else 2
            var kbps = 0
            if (totalBytes > 0 && info.third > 0) {
                val durationSec = info.third.toDouble() / info.first
                if (durationSec > 0) kbps = (totalBytes * 8.0 / durationSec / 1000).toInt()
            }
            // 总大小拿不到（如服务器不返回 Content-Range）时，用帧长估算兜底，保证"实测约"能显示
            if (kbps <= 0) kbps = flacBitrateEstimate(bytes, info.first)
            // 假无损识别：FLAC 容器但实测码率过低（<400kbps），实际信息量还不如 320k MP3，
            // 降为普通档，使验货继续寻找真无损；kbps=0（未知）时不降档，避免误杀
            if (kbps > 0 && kbps < 400) tier = 0
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
HQ_ANCHOR = '        "320k" -> "HQ"'
HQ_NEW = '        "320k" -> "320k" // v2：与 tierLabel 枚举一致，显示"320k"而非"HQ"'

def rep(old, new):
    global src
    if old not in src:
        print("错误: 锚点未命中: " + old[:80].replace("\n", "\\n"))
        sys.exit(1)
    src = src.replace(old, new, 1)

if MARK_V6 in src:
    print("跳过（已是 v6）: " + path)
elif MARK_V5 in src:
    print("检测到 v5，增量升级 → v6（全档位）")
    OLD_TIER_V5 = """    private fun tierOfQuality(q: String): Int = when (q) {
        "master", "atmos_plus", "atmos", "hires" -> 4 // 母带/全景声：最高档
        "flac24bit" -> 3
        "flac" -> 2
        "320k" -> 1
        else -> 0 // 128k 及未知：底线档，来者不拒
    }"""
    NEW_TIER_V6 = """    private fun tierOfQuality(q: String): Int = when (q) {
        "master" -> 6 // 母带：最高档
        "atmos_plus" -> 5 // 全景声+
        "atmos" -> 4 // 全景声
        "hires", "flac24bit" -> 3 // Hi-Res
        "flac" -> 2 // 无损
        "320k" -> 1 // 高品
        else -> 0 // 128k 及以下：底线档，来者不拒
    }"""
    OLD_LABEL_V5 = """    private fun tierLabel(tier: Int): String = when (tier) {
        4 -> "母带"
        3 -> "Hi-Res"
        2 -> "FLAC"
        1 -> "320k"
        else -> "普通"
    }"""
    NEW_LABEL_V6 = """    private fun tierLabel(tier: Int): String = when (tier) {
        6 -> "母带"
        5 -> "全景声+"
        4 -> "全景声"
        3 -> "Hi-Res"
        2 -> "FLAC"
        1 -> "320k"
        else -> "普通"
    }"""
    if OLD_TIER_V5 in src:
        src = src.replace(OLD_TIER_V5, NEW_TIER_V6)
        print("  tierOfQuality → v6")
    if OLD_LABEL_V5 in src:
        src = src.replace(OLD_LABEL_V5, NEW_LABEL_V6)
        print("  tierLabel → v6")
    src = src.replace(MARK_V5, MARK_V6)
    print("v5 → v6 增量升级完成")
elif MARK_V3 in src:
    print("检测到 v3/v4，增量升级 → v6（全档位）")
    # v5 档位映射（targeted 替换，保留 v4 的 isSuspiciousLossless）
    OLD_TIER_V3 = '''    private fun tierOfQuality(q: String): Int = when (q) {
        "flac24bit" -> 3
        "flac" -> 2
        "320k" -> 1
        else -> 0 // 128k 及未知：底线档，来者不拒
    }'''
    NEW_TIER_V5 = '''    private fun tierOfQuality(q: String): Int = when (q) {
        "master" -> 6 // 母带：最高档
        "atmos_plus" -> 5 // 全景声+
        "atmos" -> 4 // 全景声
        "hires", "flac24bit" -> 3 // Hi-Res
        "flac" -> 2 // 无损
        "320k" -> 1 // 高品
        else -> 0 // 128k 及以下：底线档，来者不拒
    }'''
    OLD_LABEL_V3 = '''    private fun tierLabel(tier: Int): String = when (tier) {
        3 -> "Hi-Res"
        2 -> "FLAC"
        1 -> "320k"
        else -> "普通"
    }'''
    NEW_LABEL_V5 = '''    private fun tierLabel(tier: Int): String = when (tier) {
        6 -> "母带"
        5 -> "全景声+"
        4 -> "全景声"
        3 -> "Hi-Res"
        2 -> "FLAC"
        1 -> "320k"
        else -> "普通"
    }'''
    if OLD_TIER_V3 in src:
        src = src.replace(OLD_TIER_V3, NEW_TIER_V6_FROM_V3)
        print("  tierOfQuality → v5")
    if OLD_LABEL_V3 in src:
        src = src.replace(OLD_LABEL_V3, NEW_LABEL_V6_FROM_V3)
        print("  tierLabel → v5")
    src = src.replace(MARK_V3, MARK_V6)
    print("v3/v4 → v6 增量升级完成")
elif MARK_V2 in src:
    print("检测到 v2，增量升级 → v5")
    rep(V2_FNS, NEW_FNS_V3)   # 函数块整体替换（含标记升级为 v5、Hi-Res 档位）
    print("v2 → v5 增量升级完成")
elif MARK_V1 in src:
    print("检测到 v1，增量升级 → v5")
    rep(OLD_FNS_V1, NEW_FNS_V3)
    rep(OLD_ONSUCC, NEW_ONSUCC)
    rep(OLD_FALLBACK, NEW_FALLBACK)
    rep("                var bestTier = -1\n",
        "                var bestTier = -1\n                var bestKbps = 0\n")
    if HQ_ANCHOR in src:
        rep(HQ_ANCHOR, HQ_NEW)
    print("v1 → v5 增量升级完成")
else:
    print("全新文件，走全量 v5 补丁")
    rep(ANCHOR1, ANCHOR1 + NEW_FNS_V3)
    rep(ANCHOR2, ANCHOR2 + NEW_VARS_FULL)
    rep(ANCHOR3, NEW_ONSUCC)
    rep(ANCHOR4, NEW_FALLBACK)
    if HQ_ANCHOR in src:
        rep(HQ_ANCHOR, HQ_NEW)
    print("全量 v3 补丁完成")

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("=== 音质验货补丁 v7 完成 ===")
PYEOF

# ===== v7：音质请求顺序升级（Hi-Res 优先拉取） =====
python3 << 'PYEOF_V7'
import re
path7 = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path7, encoding="utf-8") as f:
    s7 = f.read()
MARK7 = "// 音质请求顺序 v7"
if MARK7 in s7:
    print("v7：已是最新，跳过")
else:
    NEW_Q = 'listOf("master", "atmos_plus", "atmos", "hires", "flac24bit", "flac", "320k", "128k")'
    n7 = 0
    for pat7, rep7 in [
        (r'listOf\("flac24bit",\s*"flac",\s*"320k",\s*"128k"\)', NEW_Q),
        (r'arrayOf\("flac24bit",\s*"flac",\s*"320k",\s*"128k"\)', NEW_Q.replace("listOf", "arrayOf")),
    ]:
        c7 = len(re.findall(pat7, s7))
        if c7:
            s7 = re.sub(pat7, rep7, s7)
            n7 += c7
    if n7 > 0:
        s7 += "\n" + MARK7 + "\n"
        with open(path7, "w", encoding="utf-8") as f:
            f.write(s7)
        print(f"v7：请求顺序已升级（{n7} 处）")
    else:
        print("v7：未找到顺序定义，跳过（不中断构建）")
PYEOF_V7
# ===== v7 结束 =====



# ===== v8：音质顺序全文件扫描（宽松匹配） =====
python3 << 'PYEOF_V8SCAN'
import re, sys
p8 = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(p8, encoding="utf-8") as f:
    s8 = f.read()
M8 = "// 音质请求顺序 v8"
if M8 in s8:
    print("v8：已是最新，跳过")
    sys.exit(0)
pat8 = re.compile(r'(listOf|arrayOf|setOf)\s*\(\s*"flac24bit"\s*,\s*"flac"\s*,\s*"320k"\s*(,\s*"128k"\s*)?\)', re.MULTILINE)
def r8(m):
    fn8 = m.group(1)
    t8 = ', "128k"' if m.group(2) else ''
    return f'{fn8}("master", "atmos_plus", "atmos", "hires", "flac24bit", "flac", "320k"{t8})'
s8_new, n8 = pat8.subn(r8, s8)
if n8 > 0:
    s8_new += "\n" + M8 + "\n"
    with open(p8, "w", encoding="utf-8") as f:
        f.write(s8_new)
    print(f"v8：质量序列已升级 {n8} 处")
else:
    print("v8：未找到序列，跳过（不中断）")
    s8 += "\n" + M8 + " // 未命中\n"
    with open(p8, "w", encoding="utf-8") as f:
        f.write(s8)
PYEOF_V8SCAN
# ===== v8 结束 =====


# ===== v9：QUALITY_ORDER 精确替换（解码13号确认锚点） =====
python3 << 'PYEOF_V9'
import sys
p9 = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(p9, encoding="utf-8") as f:
    s9 = f.read()
M9 = "// QUALITY_ORDER v9"
if M9 in s9:
    print("v9：已是最新，跳过")
    sys.exit(0)
O9 = 'val QUALITY_ORDER = listOf("flac24bit", "flac", "320k", "128k")'
N9 = 'val QUALITY_ORDER = listOf("master", "atmos_plus", "atmos", "hires", "flac24bit", "flac", "320k", "128k")'
if O9 in s9:
    s9 = s9.replace(O9, N9 + "\n    " + M9, 1)
    with open(p9, "w", encoding="utf-8") as f:
        f.write(s9)
    print("v9：QUALITY_ORDER 已升级（master优先）")
else:
    print("v9：未找到锚点，跳过（不中断）")
PYEOF_V9
# ===== v9 结束 =====


# ===== v10：默认偏好 master =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v10] default quality = master"
if MARK in src:
    print("跳过（已是 v10）")
    sys.exit(0)

OLD = '''    fun getPreferredQuality(): String {
        return try {
            val ctx = appContext ?: return "flac24bit"
            val prefs = ctx.getSharedPreferences("music_quality", android.content.Context.MODE_PRIVATE)
            prefs.getString("music_quality", "flac24bit") ?: "flac24bit"
        } catch (e: Exception) {
            "flac24bit"
        }
    }'''

NEW = '''    fun getPreferredQuality(): String {
        // [v10] default quality = master
        return try {
            val ctx = appContext ?: return "master"
            val prefs = ctx.getSharedPreferences("music_quality", android.content.Context.MODE_PRIVATE)
            prefs.getString("music_quality", "master") ?: "master"
        } catch (e: Exception) {
            "master"
        }
    }'''

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v10：默认偏好已改为 master")
else:
    print("错误：未找到 getPreferredQuality 锚点")
    sys.exit(1)
PYEOF
# ===== v10 结束 =====

echo "=== 完成 ==="

# ===== v16：切歌清错误+重置进度 =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v16] clear error and reset progress on new song"
if MARK in src:
    print("跳过（已是 v16）")
    sys.exit(0)

# 全新文件或 v15：找到 probeAndSetQuality，在开头加清理逻辑
OLD = "    fun probeAndSetQuality(url: String) {"
NEW = """    fun probeAndSetQuality(url: String) {
        // [v16] clear error and reset progress on new song：切歌时清错误、进度归零
        _error.value = null
        _position.value = 0L
        _duration.value = 0L"""

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v16：已在 probeAndSetQuality 入口添加清理逻辑")
else:
    print("错误：未找到 probeAndSetQuality 锚点")
    sys.exit(1)
PYEOF
# ===== v16 结束 =====

# ===== v18：play() 保 bitrate =====
python3 << 'PYEOF'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [v18] keep measuredBitrate on resume"
if MARK in src:
    print("跳过（已是 v18）")
    sys.exit(0)

# 找到 play() 中的 _measuredBitrate.value = 0，注释掉并加说明
OLD = """            _position.value = 0L
            _duration.value = 0L
            _measuredBitrate.value = 0
            val mediaItem = MediaItem.fromUri(url)"""

NEW = """            _position.value = 0L
            _duration.value = 0L
            // [v18] keep measuredBitrate on resume：回列表再进不清除实测码率，徽章持久显示
            // _measuredBitrate.value = 0
            val mediaItem = MediaItem.fromUri(url)"""

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("v18：play() 已保留 measuredBitrate")
else:
    print("错误：未找到 play() 重置锚点")
    sys.exit(1)
PYEOF
# ===== v18 结束 =====

# 21 v19: 切歌时清空音质状态，修复徽章不刷新
# 背景: v18 注释了 play() 中的 _measuredBitrate.value=0，导致切歌时旧徽章残留
# 修复: 在 probeAndSetQuality(url) 入口（新歌才触发）清空质量状态
echo "=== 21 v19: 切歌清空音质状态 ==="

python3 << 'PYEOF'
import re

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(path, encoding="utf-8") as f:
    src = f.read()

MARK = "// [21v19] clear quality on new song"
if MARK in src:
    print("21 v19: 已应用，跳过")
else:
    # 找 probeAndSetQuality(url: String) 函数入口
    # v16 已经在这里加了 _error/_position/_duration 的清空，我们在同一位置加质量状态清空
    pattern = r'(fun\s+probeAndSetQuality\s*\(\s*url\s*:\s*String\s*\)\s*\{)'
    m = re.search(pattern, src)
    if not m:
        print("错误: 未找到 probeAndSetQuality(url: String)")
        exit(1)

    insert_pos = m.end()
    clear_code = f'''
        {MARK}
        _currentQuality.value = ""
        _measuredBitrate.value = 0
        // _bitrate 是 ExoPlayer 估值，由播放器回调更新，这里也清零避免旧值残留
        try {{ _bitrate.value = 0 }} catch (_: Exception) {{}}
'''

    src = src[:insert_pos] + clear_code + src[insert_pos:]

    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("21 v19: 已在 probeAndSetQuality 入口清空 _currentQuality/_measuredBitrate/_bitrate")

print("=== 21 v19 完成 ===")
PYEOF


echo "=== 21 v20 ==="

python3 << 'PYEOF'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v20] clear only on url change"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK in src:
    print("21 v20: 已应用，跳过")
    sys.exit(0)

# 找到 v19 的清空块，替换为条件清空
old_clear = """        // [21v19] clear quality on new song
        _currentQuality.value = ""
        _measuredBitrate.value = 0
        // _bitrate 是 ExoPlayer 估值，由播放器回调更新，这里也清零避免旧值残留
        try { _bitrate.value = 0 } catch (_: Exception) {}"""

new_clear = """        // [21v20] clear only on url change
        if (_lastProbeUrl != url) {
            _currentQuality.value = ""
            _measuredBitrate.value = 0
            try { _bitrate.value = 0 } catch (_: Exception) {}
            _lastProbeUrl = url
        }"""

if old_clear in src:
    src = src.replace(old_clear, new_clear, 1)
    print("✓ v19 清空逻辑已改为条件清空")
else:
    print("✗ 未找到 v19 清空块")
    sys.exit(1)

# 确保 _lastProbeUrl 字段存在（在 _currentQuality 附近声明）
if "_lastProbeUrl" not in src or "private var _lastProbeUrl" not in src:
    # 找到 _currentQuality 的声明位置
    m = re.search(r'(private val _currentQuality[^\n]+\n)', src)
    if m:
        decl = m.group(1)
        new_decl = decl + '    private var _lastProbeUrl: String? = null\n'
        src = src.replace(decl, new_decl, 1)
        print("✓ _lastProbeUrl 字段已添加")
    else:
        print("✗ 未找到 _currentQuality 声明")
        sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("=== 21 v20 完成 ===")
PYEOF

# === 21 v22: 切歌无条件清空（多锚点兜底） ===
echo "=== 21 v22 ==="

python3 << 'PYEOF2'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v22] clear on song change"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK in src:
    print("21 v22: 已应用，跳过")
    sys.exit(0)

# 多锚点按顺序尝试
anchors = [
    (r'(onMediaItemTransition\s*\([^)]*\)\s*\{)', "onMediaItemTransition"),
    (r'(override\s+fun\s+onMediaItemTransition[^{]*\{)', "override onMediaItemTransition"),
    (r'(fun\s+play\s*\([^)]*\)\s*\{)', "fun play("),
]

found = None
for pat, name in anchors:
    m = re.search(pat, src)
    if m:
        found = (m.group(1), name)
        break

if found:
    anchor, name = found
    clear_code = anchor + """
        // [21v22] clear on song change: 切歌立即清空旧徽章数据
        _currentQuality.value = ""
        _measuredBitrate.value = 0
        try { _bitrate.value = 0 } catch (_: Exception) {}"""
    src = src.replace(anchor, clear_code, 1)
    print(f"✓ {name} 已加清空逻辑")
else:
    print("✗ 未找到任何切歌锚点")
    sys.exit(1)

assert MARK in src, "❌ v22 断言失败"

# assert: 确保清空代码已加入
assert MARK in src, "❌ v21 断言失败：清空标记未找到"
assert '_currentQuality.value = ""' in src, "❌ v21 断言失败：清空语句未找到"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 21 v21 补丁完成")
PYEOF2

echo "=== 21 v21 完成 ==="

# === 21 v23: 修复 v22 时序灾难 ===
echo "=== 21 v23 ==="

python3 << 'PYEOF3'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK_V23 = "// [21v23]"
MARK_V22 = "// [21v22] clear on song change"

with open(path, encoding="utf-8") as f:
    src = f.read()

if MARK_V23 in src:
    print("21 v23: 已应用，跳过")
    sys.exit(0)

# 步骤1：移除 v22 在 fun play( 入口的清空（时序灾难根源）
# v22 的清空会误伤探针回调中的 play() 调用
if MARK_V22 in src:
    # 找到 v22 加入的清空块并移除
    v22_block = """        // [21v22] clear on song change: 切歌立即清空旧徽章数据
        _currentQuality.value = ""
        _measuredBitrate.value = 0
        try { _bitrate.value = 0 } catch (_: Exception) {}"""
    if v22_block in src:
        src = src.replace(v22_block, "        // [21v23] v22 清空已移除（时序冲突）", 1)
        print("✓ v22 误伤清空已移除")
    else:
        print("⚠ v22 块格式不匹配，尝试模糊移除")
        # 模糊匹配：删除包含 MARK_V22 的行及后续3行
        lines = src.split("\n")
        new_lines = []
        skip = 0
        for line in lines:
            if MARK_V22 in line:
                skip = 4  # 跳过标记行 + 3行清空代码
                new_lines.append("        // [21v23] v22 清空已移除")
                continue
            if skip > 0:
                skip -= 1
                continue
            new_lines.append(line)
        src = "\n".join(new_lines)
        print("✓ v22 块已模糊移除")

# 步骤2：在真正的切歌入口加清空（next/previous/seekTo）
# 这些是用户主动切歌，不会与探针回调冲突
clear_code = """        // [21v23] 用户切歌：立即清空旧徽章
        _currentQuality.value = ""
        _measuredBitrate.value = 0
        try { _bitrate.value = 0 } catch (_: Exception) {}"""

song_change_fns = [
    (r'(fun\s+next\s*\(\s*\)\s*\{)', "next()"),
    (r'(fun\s+previous\s*\(\s*\)\s*\{)', "previous()"),
    (r'(fun\s+seekToNext\s*\([^)]*\)\s*\{)', "seekToNext()"),
    (r'(fun\s+playNext\s*\([^)]*\)\s*\{)', "playNext()"),
]

patched = []
for pat, name in song_change_fns:
    m = re.search(pat, src)
    if m and MARK_V23 not in src[max(0, m.start()-200):m.start()]:
        anchor = m.group(1)
        # 检查是否已打过补丁（避免重复）
        src = src.replace(anchor, anchor + "\n" + clear_code, 1)
        patched.append(name)
        print(f"✓ {name} 已加清空")

if not patched:
    print("⚠ 未找到切歌函数，尝试 probeAndSetQuality 入口保护")
    # 兜底：在 probeAndSetQuality 入口加 guard，防止重复清空
    # （v20 的条件清空保留，v23 不动它）
    pass
else:
    print(f"✓ 共修补 {len(patched)} 个切歌入口: {', '.join(patched)}")

# 步骤3：assert 确保探针赋值不受影响
# 检查探针赋值代码仍在
assert "_currentQuality.value = label" in src or "_currentQuality.value = realQuality" in src, "❌ v23 断言失败：探针赋值丢失"
assert MARK_V23 in src or len(patched) > 0, "❌ v23 断言失败：未修补任何入口"

with open(path, "w", encoding="utf-8") as f:
    f.write(src)
print("✓ 21 v23 完成")
PYEOF3

echo "=== 21 v23 完成 ==="


# === 21 v25: 探针三重优化（重写 v24） ===
echo "=== 21 v25 ==="

python3 << 'PYEOF25'
import re, sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v25]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("21 v25: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：请求头（UA + 动态 Referer） ---
old_ua = 'conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14)")'
new_ua = '''conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36") // [21v25]
            try { val h = java.net.URL(url).host; if (h.isNotEmpty()) conn.setRequestProperty("Referer", "https://$h/") } catch (_: Exception) { } // [21v25] 动态host防403'''
n = s.count(old_ua)
if n > 0:
    s = s.replace(old_ua, new_ua)
    print(f"✓ 请求头更新 {n} 处")
else:
    print("⚠ 未找到旧UA（可能已是新版）")

# --- 步骤2：probeBytesRange 插到类级别 ---
# 锚点：object LxPlayerManager 声明行，插在其后第一个 private fun 之前
if "fun probeBytesRange" in s:
    print("✓ probeBytesRange 已存在")
else:
    m = re.search(r'(object LxPlayerManager[^\n]*\n)', s)
    if not m:
        print("❌ 未找到 object LxPlayerManager")
        sys.exit(1)
    # 在 object 声明后找第一个 "    private fun"，插在其前
    search_from = m.end()
    m2 = re.search(r'    private fun ', s[search_from:])
    if not m2:
        print("❌ 未找到类内第一个 private fun")
        sys.exit(1)
    insert_at = search_from + m2.start()
    new_func = '''    // [21v25] 支持指定起始偏移的 Range 探测（64KB-256KB 二次探测用）
    private fun probeBytesRange(url: String, start: Long, size: Int): Pair<ByteArray, Long>? {
        return try {
            val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "GET"
            conn.connectTimeout = 6000
            conn.readTimeout = 6000
            conn.instanceFollowRedirects = true
            conn.setRequestProperty("Range", "bytes=${start}-${start + size - 1}")
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36") // [21v25]
            try { val h = java.net.URL(url).host; if (h.isNotEmpty()) conn.setRequestProperty("Referer", "https://$h/") } catch (_: Exception) { } // [21v25]
            conn.connect()
            val code = conn.responseCode
            if (code == 416) { conn.disconnect(); return null } // [21v25] 文件太小越界，直接回null
            if (code != 200 && code != 206) { conn.disconnect(); return null }
            var total: Long = -1
            try {
                val cr = conn.getHeaderField("Content-Range") ?: ""
                val slash = cr.lastIndexOf('/')
                if (slash >= 0) total = cr.substring(slash + 1).trim().toLongOrNull() ?: -1
                if (total <= 0) total = conn.getHeaderFieldLong("Content-Length", -1)
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
            Log.w(TAG, "[21v25] 二次探测失败: ${e.message}")
            null
        }
    }

'''
    s = s[:insert_at] + new_func + s[insert_at:]
    print("✓ probeBytesRange 已插入类级别")

# --- 步骤3：probeAudio 整函数替换 ---
# 找到最后一个 probeAudio 定义（最新的），用行定位法找函数结束
lines = s.split('\n')
func_start = -1
for i, line in enumerate(lines):
    if 'private fun probeAudio(url: String): Pair<Int, Int> {' in line:
        func_start = i  # 取最后一个
if func_start == -1:
    print("❌ 未找到 probeAudio")
    sys.exit(1)
# 数大括号找结束（从 func_start 行开始）
depth = 0
func_end = -1
for i in range(func_start, len(lines)):
    depth += lines[i].count('{') - lines[i].count('}')
    if i > func_start and depth == 0:
        func_end = i
        break
if func_end == -1:
    print("❌ probeAudio 结束未找到")
    sys.exit(1)
print(f"✓ probeAudio 定位：第 {func_start+1}-{func_end+1} 行")

new_probeAudio = '''    // [21v25] 探针：FLAC→MP3(双Range)→AAC→大小盲猜
    private fun probeAudio(url: String): Pair<Int, Int> {
        val probed = probeBytes(url, 65536) ?: return Pair(-1, 0)
        val bytes = probed.first
        val totalBytes = probed.second
        // FLAC：STREAMINFO 定档位
        val info = flacStreamInfo(bytes)
        if (info != null) {
            var tier = if (info.second >= 24) 3 else 2
            var kbps = 0
            if (totalBytes > 0 && info.third > 0) {
                val durationSec = info.third.toDouble() / info.first
                if (durationSec > 0) kbps = (totalBytes * 8.0 / durationSec / 1000).toInt()
            }
            if (kbps <= 0) kbps = flacBitrateEstimate(bytes, info.first)
            if (kbps > 0 && kbps < 400) tier = 0
            return Pair(tier, kbps)
        }
        // MP3：先前64KB，找不到再试64KB-256KB（防大封面）
        var mp3br = mp3BitrateKbps(bytes)
        if (mp3br <= 0) {
            try {
                val p2 = probeBytesRange(url, 65536, 192 * 1024)
                if (p2 != null) {
                    mp3br = mp3BitrateKbps(p2.first)
                    if (mp3br > 0) Log.i(TAG, "[21v25] MP3帧头在64KB-256KB找到")
                }
            } catch (_: Exception) { } // [21v25] 416/网络异常直接吞，继续盲猜
        }
        if (mp3br > 0) return Pair(if (mp3br >= 224) 1 else 0, mp3br)
        // AAC：按高档放行
        if (isAacBytes(bytes)) return Pair(1, 0)
        // [21v25] 大小盲猜兜底
        if (totalBytes > 0) {
            val g: Pair<Int, Int> = when {
                totalBytes > 15 * 1024 * 1024 -> Pair(2, 0)
                totalBytes >= 8 * 1024 * 1024 -> Pair(1, 320)
                totalBytes < 4 * 1024 * 1024 -> Pair(0, 128)
                else -> Pair(1, 0)
            }
            Log.i(TAG, "[21v25] 大小盲猜: ${totalBytes}字节 tier=${g.first}")
            return g
        }
        return Pair(-1, 0)
    }'''
lines[func_start:func_end+1] = [new_probeAudio]
s = '\n'.join(lines)
print("✓ probeAudio 已整函数替换")

assert "[21v25]" in s
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 21 v25 完成")
PYEOF25

echo "=== 21 v25 完成 ==="

# === 21 v26: 探针状态 + 结果缓存（含三并发修正） ===
echo "=== 21 v26 ==="

python3 << 'PYEOF26'
import sys, re

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v26]"

with open(path, encoding="utf-8") as f:
    s = f.read()

if MARK in s:
    print("21 v26: 已应用，跳过")
    sys.exit(0)

# --- 步骤1：加 StateFlow 声明（修正1：ConcurrentHashMap 线程安全） ---
anchor1 = "    val measuredBitrate: StateFlow<Int> = _measuredBitrate"
if anchor1 not in s:
    print("❌ 未找到 _measuredBitrate 声明锚点")
    sys.exit(1)
new_decls = anchor1 + "\n" + \
    "    private val _probeTier = MutableStateFlow(-1) " + MARK + "\n" + \
    "    val probeTier: StateFlow<Int> = _probeTier " + MARK + "\n" + \
    "    private val _isProbing = MutableStateFlow(false) " + MARK + "\n" + \
    "    val isProbing: StateFlow<Boolean> = _isProbing " + MARK + "\n" + \
    "    private val _probeCache = java.util.concurrent.ConcurrentHashMap<String, Triple<String, Int, Int>>() " + MARK
s = s.replace(anchor1, new_decls, 1)
print("✓ StateFlow 声明已加（含 ConcurrentHashMap）")

# --- 步骤2：probeAndSetQuality 整函数替换 ---
lines = s.split('\n')
fs = -1
for i, l in enumerate(lines):
    if re.search(r'^\s*fun probeAndSetQuality\(url: String\)', l):
        fs = i
        break
if fs == -1:
    print("❌ 未找到 probeAndSetQuality")
    sys.exit(1)
depth = 0
fe = -1
for i in range(fs, len(lines)):
    depth += lines[i].count('{') - lines[i].count('}')
    if i > fs and depth == 0:
        fe = i
        break
if fe == -1:
    print("❌ probeAndSetQuality 结束未找到")
    sys.exit(1)

new_func = """    fun probeAndSetQuality(url: String) { // [21v26]
        try {
            val cached = _probeCache[url]
            if (cached != null) {
                _currentQuality.value = cached.first
                _probeTier.value = cached.second
                _measuredBitrate.value = cached.third
                _isProbing.value = false
                return
            }
            _isProbing.value = true
            _probeTier.value = -1
            _currentQuality.value = ""
            _measuredBitrate.value = 0
            _currentQuality.value = detectQualityFromUrl(url)
        } catch (_: Exception) {
            _isProbing.value = false
        }
    }"""
lines[fs:fe+1] = [new_func]
s = '\n'.join(lines)
print("✓ probeAndSetQuality 已替换（含 try-catch）")

# --- 步骤3：探针完成处（修正2：try-catch 包 probeAudio，防卡死） ---
# 找到 onSuccess 里的 probeAudio 调用，加 try-catch
old_probe = "                                        val probed = probeAudio(url) // first="
if old_probe in s:
    new_probe = "                                        val probed = try { probeAudio(url) } catch (_: Exception) { mainHandler.post { _isProbing.value = false } ; Pair(-1, 0) } // [21v26] 异常兜底"
    s = s.replace(old_probe, new_probe, 1)
    print("✓ probeAudio 已包 try-catch")
else:
    print("⚠ 未找到 probeAudio 调用锚点，尝试宽松匹配")
    # 宽松：找 val probed = probeAudio(url)
    m = re.search(r'(val probed = probeAudio\(url\))', s)
    if m:
        s = s.replace(m.group(1), "val probed = try { probeAudio(url) } catch (_: Exception) { Pair(-1, 0) } // [21v26]", 1)
        print("✓ probeAudio 已包 try-catch（宽松）")
    else:
        print("❌ probeAudio 锚点完全未找到")
        sys.exit(1)

# --- 步骤4：mainHandler.post 内加 tier/缓存/isProbing=false ---
old_m = "                                                _measuredBitrate.value = kbps"
if old_m not in s:
    print("❌ 未找到 _measuredBitrate.value = kbps 锚点")
    sys.exit(1)
new_m = old_m + "\n" + \
    "                                                _probeTier.value = tier " + MARK + "\n" + \
    "                                                _probeCache[url] = Triple(label, tier, kbps) " + MARK + "\n" + \
    "                                                _isProbing.value = false " + MARK
s = s.replace(old_m, new_m, 1)
print("✓ 探针完成处已加")

# fallback 路径
old_f = "                                                _measuredBitrate.value = bestKbps"
if old_f in s:
    new_f = old_f + "\n" + \
        "                                                _probeTier.value = bestTier " + MARK + "\n" + \
        "                                                _isProbing.value = false " + MARK
    s = s.replace(old_f, new_f, 1)
    print("✓ fallback 路径已加")

assert MARK in s
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("✓ 21 v26 完成")
PYEOF26

echo "=== 21 v26 完成 ==="


# === 21 v28: 无fallback出口补 _isProbing=false（行级定位） ===
echo "=== 21 v28 ==="

python3 << 'PYEOF28'
import sys

path = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v28]"

with open(path, encoding="utf-8") as f:
    lines = f.readlines()

if MARK in "".join(lines):
    print("21 v28: 已应用，跳过")
    sys.exit(0)

# 前置：_isProbing 必须已由 v26 声明
if "_isProbing" not in "".join(lines):
    print("❌ _isProbing 未声明（v26 未生效？）")
    sys.exit(1)

# 行级定位：找 if (!tryAutoNextOnFailure()) 行
ti = -1
for i, l in enumerate(lines):
    if 'if (!tryAutoNextOnFailure())' in l:
        ti = i
        break
if ti == -1:
    print("❌ 未找到 tryAutoNextOnFailure 行")
    sys.exit(1)
print(f"✓ tryAutoNextOnFailure 第 {ti+1} 行")

# 向上一行找 setLoading(false)（应在 post 块内、tryAutoNext 之前）
si = -1
for j in range(ti - 1, max(0, ti - 6), -1):
    if 'setLoading(false)' in lines[j]:
        si = j
        break
if si == -1:
    print("❌ tryAutoNext 上方 6 行内未找到 setLoading(false)")
    for j in range(max(0, ti - 6), ti):
        print(f"  {j+1}: {lines[j].rstrip()[:70]}")
    sys.exit(1)
print(f"✓ setLoading(false) 第 {si+1} 行")

# 在 setLoading(false) 后插入 _isProbing=false
indent = lines[si][:len(lines[si]) - len(lines[si].lstrip())]
lines.insert(si + 1, f"{indent}_isProbing.value = false {MARK} // 全部音质耗尽无fallback，强制结束探针防卡死\n")

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print(f"✓ 21 v28: 第 {si+2} 行已插入 _isProbing=false")
PYEOF28

echo "=== 21 v28 完成 ==="

# === 21 v29: isProbing 闭环修复（Path A 真探针 try-finally + Path B 探针前置位） ===
echo "=== 21 v29: isProbing 状态闭环 ==="
python3 << 'PYEOF29'
import sys, re
PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(PATH, encoding='utf-8') as f:
    content = f.read()
if '// [21v29]' in content:
    print("21 v29: 已应用，跳过")
    sys.exit(0)
lines = content.split('\n')
NEW_FN = """    fun probeAndSetQuality(url: String) { // [21v29] Path A 真探针：置位→探针→finally 复位
        val cachedA = _probeCache[url]
        if (cachedA != null) {
            _currentQuality.value = cachedA.first
            _probeTier.value = cachedA.second
            _measuredBitrate.value = cachedA.third
            _isProbing.value = false
            return
        }
        _isProbing.value = true
        try {
            _probeTier.value = -1
            _currentQuality.value = ""
            _measuredBitrate.value = 0
            val lblA = detectQualityFromUrl(url)
            _currentQuality.value = lblA
            val prA = try { probeAudio(url) } catch (_: Exception) { Pair(-1, 0) }
            _probeTier.value = prA.first
            if (prA.second > 0) _measuredBitrate.value = prA.second
            if (prA.first >= 0) _probeCache[url] = Triple(lblA, prA.first, prA.second)
        } catch (_: Exception) {
        } finally {
            _isProbing.value = false
        }
    }"""
start = None
for i, l in enumerate(lines):
    if 'fun probeAndSetQuality(url: String)' in l:
        start = i
        break
if start is None:
    print("X 未找到 probeAndSetQuality")
    sys.exit(1)
depth = 0; end = None; begun = False
for j in range(start, len(lines)):
    depth += lines[j].count('{') - lines[j].count('}')
    if '{' in lines[j]: begun = True
    if begun and depth == 0:
        end = j; break
if end is None:
    print("X probeAndSetQuality 花括号计数失败")
    sys.exit(1)
print(f"  probeAndSetQuality 定位: {start+1}~{end+1} 行")
lines = lines[:start] + NEW_FN.split('\n') + lines[end+1:]
content = '\n'.join(lines)
m = re.search(r'^([ ]*)val probed = try \{ probeAudio\(url\) \} catch.*$', content, re.MULTILINE)
if not m:
    print("X 未找到 onSuccess 探针行（v26 包裹形态）")
    sys.exit(1)
indent = m.group(1)
replacement = (indent + "_isProbing.value = true // [21v29] Path B 探针开始置位（终局 post 复位）\n"
    + indent + "val probed = try { probeAudio(url) } catch (_: Exception) { Pair(-1, 0) } // [21v29]")
content = content[:m.start()] + replacement + content[m.end():]
with open(PATH, 'w', encoding='utf-8') as f:
    f.write(content)
assert '_isProbing.value = true // [21v29]' in content
assert 'finally {' in content
print("OK 21 v29 完成（Path A try-finally / Path B 前置位）")
PYEOF29

# === 21 v30: isProbing 密封复位 + probeDbg 探针分支诊断 ===
echo "=== 21 v30: 密封复位 + probeDbg ==="
python3 << 'PYEOF30'
import sys
PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
with open(PATH, encoding='utf-8') as f:
    c = f.read()
if '// [21v30]' in c:
    print("21 v30: 已应用，跳过")
    sys.exit(0)
def rep(old, new, tag):
    global c
    if old not in c:
        print(f"X 未找到锚点: {tag}")
        sys.exit(1)
    c = c.replace(old, new, 1)
    print(f"  OK {tag}")
# 1) probeDbg 声明（紧跟 v26 的 isProbing 声明）
rep("    val isProbing: StateFlow<Boolean> = _isProbing",
    "    val isProbing: StateFlow<Boolean> = _isProbing\n    private val _probeDbg = MutableStateFlow(\"\") // [21v30]\n    val probeDbg: StateFlow<String> = _probeDbg // [21v30]",
    "probeDbg 声明")
# 2) setLoading 密封
rep("""    fun setLoading(loading: Boolean) {
        _isLoading.value = loading
    }""",
    """    fun setLoading(loading: Boolean) { // [21v30] 密封：加载结束必复位探针态
        _isLoading.value = loading
        if (!loading) _isProbing.value = false // [21v30]
    }""",
    "setLoading 密封")
# 3) setError 密封
rep("""    fun setError(msg: String?) {
        _error.value = msg
        if (msg != null) _isLoading.value = false
    }""",
    """    fun setError(msg: String?) { // [21v30] 密封：报错必复位探针态
        _error.value = msg
        if (msg != null) { _isLoading.value = false; _isProbing.value = false } // [21v30]
    }""",
    "setError 密封")
# 4) probeAudio 首行失败记录
rep("        val probed = probeBytes(url, 65536) ?: return Pair(-1, 0)",
    "        val probed = probeBytes(url, 65536)\n        if (probed == null) { _probeDbg.value = \"X:bytes-null\" // [21v30]\n            return Pair(-1, 0) }",
    "probeAudio 首行")
# 5) FLAC 分支记录
rep("""            if (kbps > 0 && kbps < 400) tier = 0
            return Pair(tier, kbps)""",
    """            if (kbps > 0 && kbps < 400) tier = 0
            _probeDbg.value = "F:t$tier,B$totalBytes,S${info.third},R${info.first},D${info.second},K$kbps" // [21v30]
            return Pair(tier, kbps)""",
    "FLAC 分支记录")
# 6) MP3 分支记录
rep("        if (mp3br > 0) return Pair(if (mp3br >= 224) 1 else 0, mp3br)",
    "        if (mp3br > 0) _probeDbg.value = \"M:K$mp3br\" // [21v30]\n        if (mp3br > 0) return Pair(if (mp3br >= 224) 1 else 0, mp3br)",
    "MP3 分支记录")
# 7) AAC 分支记录
rep("        if (isAacBytes(bytes)) return Pair(1, 0)",
    "        if (isAacBytes(bytes)) _probeDbg.value = \"A:B$totalBytes\" // [21v30]\n        if (isAacBytes(bytes)) return Pair(1, 0)",
    "AAC 分支记录")
# 8) 盲猜分支记录
rep("""            Log.i(TAG, "[21v25] 大小盲猜: ${totalBytes}字节 tier=${g.first}")
            return g""",
    """            Log.i(TAG, "[21v25] 大小盲猜: ${totalBytes}字节 tier=${g.first}")
            _probeDbg.value = "G:t${g.first},B$totalBytes,K${g.second}" // [21v30]
            return g""",
    "盲猜分支记录")
# 9) 末尾未知分支记录
rep("""            return g
        }
        return Pair(-1, 0)""",
    """            return g
        }
        _probeDbg.value = "U:B$totalBytes" // [21v30]
        return Pair(-1, 0)""",
    "未知分支记录")
# 10) 缓存命中记录（v29 probeAndSetQuality）
rep("""            _measuredBitrate.value = cachedA.third
            _isProbing.value = false
            return""",
    """            _measuredBitrate.value = cachedA.third
            _probeDbg.value = "C:t${cachedA.second},K${cachedA.third}" // [21v30]
            _isProbing.value = false
            return""",
    "缓存命中记录")
with open(PATH, 'w', encoding='utf-8') as f:
    f.write(c)
assert c.count('// [21v30]') >= 8
print("OK 21 v30 完成")
PYEOF30

# === 21 v31: 探针物理极限判定 + 双时长交叉验证 + 虚标信号流 ===
# FLAC 分支：极限=R*D*2；S/R 时长与 UI 时长（ExoPlayer _duration）偏差>max(2s,5%) 或 S 缺失时，
# 改用 B*8/UI时长 重算 kbps；重算后仍超极限*1.02 → _probeSuspect=true（供 22 徽章显示虚标⚠）。
# 探针只报实测与矛盾判定，绝不编造码率。F 串改新格式 F:[S=,R=,D=,B=,K=,t(,SUS)]。
echo "=== 21 v31 ==="

python3 << 'PYEOF31'
import sys

PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v31]"

with open(PATH, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("21 v31: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 21 v31 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new, 1)
    print(f"  OK {tag}")

# 1) 虚标信号流 + 判定缓存声明（挂在 probeDbg 声明之后）
rep(
    "    val probeDbg: StateFlow<String> = _probeDbg // [21v30] // [21v26]",
    "    val probeDbg: StateFlow<String> = _probeDbg // [21v30] // [21v26]\n"
    "    private val _probeSuspect = MutableStateFlow(false) // [21v31]\n"
    "    val probeSuspect: StateFlow<Boolean> = _probeSuspect // [21v31]\n"
    "    private val _probeSuspectCache = java.util.concurrent.ConcurrentHashMap<String, Boolean>() // [21v31]",
    "probeSuspect 声明",
)

# 2) 缓存命中时恢复虚标判定
rep(
    '            _probeDbg.value = "C:t${cachedA.second},K${cachedA.third}" // [21v30]',
    '            _probeDbg.value = "C:t${cachedA.second},K${cachedA.third}" // [21v30]\n'
    "            _probeSuspect.value = _probeSuspectCache[url] ?: false // [21v31]",
    "缓存命中恢复 suspect",
)

# 3) Path A 探针开始时复位判定
rep(
    "            _probeTier.value = -1",
    "            _probeTier.value = -1\n"
    "            _probeSuspect.value = false // [21v31]",
    "Path A 复位 suspect",
)

# 4) Path A 写缓存时同步判定缓存
rep(
    "            if (prA.first >= 0) _probeCache[url] = Triple(lblA, prA.first, prA.second)",
    "            if (prA.first >= 0) _probeCache[url] = Triple(lblA, prA.first, prA.second)\n"
    "            if (prA.first >= 0) _probeSuspectCache[url] = _probeSuspect.value // [21v31]",
    "Path A 判定缓存",
)

# 5) Chain B 写缓存时同步判定缓存
rep(
    "                                                _probeCache[url] = Triple(label, tier, kbps) // [21v26]",
    "                                                _probeCache[url] = Triple(label, tier, kbps) // [21v26]\n"
    "                                                _probeSuspectCache[url] = _probeSuspect.value // [21v31]",
    "Chain B 判定缓存",
)

# 6) bytes-null 出口复位判定
rep(
    '        if (probed == null) { _probeDbg.value = "X:bytes-null" // [21v30]',
    '        if (probed == null) { _probeSuspect.value = false; _probeDbg.value = "X:bytes-null" // [21v30] // [21v31]',
    "X 出口复位",
)

# 7) 非 FLAC 路径统一不判虚标（FLAC 分支在此之前 return，不受影响）
rep(
    "        // MP3：先前64KB，找不到再试64KB-256KB（防大封面）",
    "        _probeSuspect.value = false // [21v31] 非FLAC路径不判虚标\n"
    "        // MP3：先前64KB，找不到再试64KB-256KB（防大封面）",
    "非FLAC复位",
)

# 8) FLAC 分支整段替换（行级定位：flacStreamInfo 起，到其后第一个 return Pair(tier, kbps) 的下一行 } 止）
lines = c.split("\n")
start = -1
for i, l in enumerate(lines):
    if "val info = flacStreamInfo(bytes)" in l:
        start = i
        break
if start == -1:
    print("X 21 v31 未找到 FLAC 分支起点")
    sys.exit(1)
ret = -1
for i in range(start, min(len(lines), start + 30)):
    if "return Pair(tier, kbps)" in lines[i]:
        ret = i
        break
if ret == -1 or lines[ret + 1].strip() != "}":
    print("X 21 v31 FLAC 分支终点异常")
    sys.exit(1)
seg = "\n".join(lines[start:ret + 2])
if "F:t$tier" not in seg or "flacBitrateEstimate" not in seg:
    print("X 21 v31 FLAC 分支内容校验失败（不是预期的现行分支）")
    sys.exit(1)
new_branch = """        val info = flacStreamInfo(bytes)
        if (info != null) {
            var tier = if (info.second >= 24) 3 else 2
            var kbps = 0
            val durHdr = if (info.third > 0 && info.first > 0) info.third.toDouble() / info.first else 0.0 // [21v31] STREAMINFO 时长 S/R
            if (totalBytes > 0 && durHdr > 0) kbps = (totalBytes * 8.0 / durHdr / 1000).toInt()
            if (kbps <= 0) kbps = flacBitrateEstimate(bytes, info.first)
            // [21v31] 物理极限判定 + 双时长交叉验证：B 与 UI 时长是物理量，S/R 可造假
            val limitKbps = info.first * info.second * 2 / 1000
            var waitMs = 0
            while (_duration.value <= 0L && waitMs < 1500) { Thread.sleep(150); waitMs += 150 }
            val uiDur = _duration.value / 1000.0
            var distrust = false
            if (totalBytes > 0 && uiDur > 0 && durHdr <= 0) {
                distrust = true
                val kbpsUi = (totalBytes * 8.0 / uiDur / 1000).toInt()
                if (kbpsUi > 0) kbps = kbpsUi
            } else if (totalBytes > 0 && uiDur > 0 && durHdr > 0 && kotlin.math.abs(durHdr - uiDur) > kotlin.math.max(2.0, uiDur * 0.05)) {
                distrust = true
                val kbpsUi = (totalBytes * 8.0 / uiDur / 1000).toInt()
                if (kbpsUi > 0) kbps = kbpsUi
            }
            val sus = kbps > (limitKbps * 1.02).toInt()
            if (sus) distrust = true
            _probeSuspect.value = sus // [21v31]
            if (kbps > 0 && kbps < 400) tier = 0
            if (distrust) {
                val cap = if (kbps >= 800) 2 else if (kbps >= 320) 1 else 0
                if (cap < tier) tier = cap
            }
            _probeDbg.value = "F:[S=${info.third},R=${info.first},D=${info.second},B=$totalBytes,K=$kbps,t$tier${if (sus) ",SUS" else ""}]" // [21v31]
            return Pair(tier, kbps)
        }"""
lines[start:ret + 2] = new_branch.split("\n")
c = "\n".join(lines)
print("  OK FLAC 分支极限判定+交叉验证")

assert MARK in c and "_probeSuspect" in c and "limitKbps" in c
with open(PATH, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 21 v31 完成")
PYEOF31

echo "=== 21 v31 完成 ==="

# === 21 v32: 原生 Equalizer 挂载（与响度均衡同款生命周期） ===
# 参数存 SharedPreferences("eq_settings")，页面只写 prefs 后调 applyEqFromPrefs()；
# 频段一律 getBand() 按设备实测映射（找不到跳过），增益按 getBandLevelRange() 钳制；
# 氛围感增益各半叠加到 3k/14k 两段。会话变更时与 bindLoudness 并排重绑。
echo "=== 21 v32 ==="

python3 << 'PYEOF32'
import sys

PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v32]"

with open(PATH, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("21 v32: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 21 v32 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

rep("import android.media.audiofx.LoudnessEnhancer",
    "import android.media.audiofx.LoudnessEnhancer\nimport android.media.audiofx.Equalizer",
    "import Equalizer")

rep("    private var loudEnh: LoudnessEnhancer? = null",
    "    private var loudEnh: LoudnessEnhancer? = null\n    private var eqEffect: Equalizer? = null // [21v32]",
    "eqEffect 字段")

rep("                        try{bindLoudness(sid)}catch(_:Exception){}",
    "                        try{bindLoudness(sid)}catch(_:Exception){}\n                        try{bindEqualizer(sid)}catch(_:Exception){} // [21v32]",
    "会话钩子")

eq_fns = """    // [21v32] 均衡器：与响度均衡同款挂载（会话变更重绑、关则释放）
    private fun bindEqualizer(sid: Int) {
        try{eqEffect?.release()}catch(_:Exception){}
        eqEffect=null
        if(sid==0) return
        if(!isEqOn()) return
        try{
            val eq=Equalizer(0,sid)
            applyEqLevels(eq)
            eq.enabled=true
            eqEffect=eq
        }catch(_:Exception){}
    }

    fun isEqOn(): Boolean {
        return try{appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)?.getBoolean("on",false)?:false}catch(_:Exception){false}
    }

    // [21v32] 页面改完 prefs 后调用：开则按当前会话重应用，关则释放
    fun applyEqFromPrefs() {
        try{
            if(!isEqOn()){
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                return
            }
            val sid=player?.audioSessionId?:0
            val eq=eqEffect
            if(eq==null){
                if(sid!=0) bindEqualizer(sid)
            }else{
                try{applyEqLevels(eq);eq.enabled=true}catch(_:Exception){}
            }
        }catch(_:Exception){}
    }

    // [21v32] 6 维增益(dB) -> 设备实测频段：getBand 找最近段（缺失跳过），氛围感各半叠加 3k/14k，范围钳制
    private fun applyEqLevels(eq: Equalizer) {
        val prefs=appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)?:return
        fun g(k:String)=try{prefs.getFloat(k,0f)}catch(_:Exception){0f}
        val amb=g("amb")
        val targets=listOf(
            60 to g("sub"),
            230 to g("low"),
            910 to g("mid"),
            3000 to (g("clarity")+amb*0.5f),
            14000 to (g("high")+amb*0.5f)
        )
        val range=eq.bandLevelRange
        val lo=range[0].toInt()
        val hi=range[1].toInt()
        for((freq,db) in targets){
            try{
                val band=eq.getBand(freq*1000)
                if(band>=0){
                    val lvl=(db*100).toInt().coerceIn(lo,hi)
                    eq.setBandLevel(band,lvl.toShort())
                }
            }catch(_:Exception){}
        }
    }

"""
rep("    fun isLoudnessOn(): Boolean {",
    eq_fns + "    fun isLoudnessOn(): Boolean {",
    "EQ 函数组")

assert MARK in c and "bindEqualizer" in c and "applyEqFromPrefs" in c
with open(PATH, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 21 v32 完成")
PYEOF32

echo "=== 21 v32 完成 ==="

# === 21 v33: EQ 防失真（量程硬顶 ±8dB + 自动前级增益） ===
# applyEqLevels 的目标值先 cap 到 ±8（存量超限 prefs 也钳）；再取最高正增益 peak，
# 全体减 peak*0.7 当前级回退防削波（曲线相对形状不变），最后仍走硬件范围钳制下发。
echo "=== 21 v33 ==="

python3 << 'PYEOF33'
import sys

PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v33]"

with open(PATH, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("21 v33: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 21 v33 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

old_targets = """        val amb=g("amb")
        val targets=listOf(
            60 to g("sub"),
            230 to g("low"),
            910 to g("mid"),
            3000 to (g("clarity")+amb*0.5f),
            14000 to (g("high")+amb*0.5f)
        )
        val range=eq.bandLevelRange"""

new_targets = """        val amb=g("amb")
        fun cap(v:Float)=v.coerceIn(-8f,8f) // [21v33] 量程硬顶 ±8dB（存量超限 prefs 一并钳）
        val targets=listOf(
            60 to cap(g("sub")),
            230 to cap(g("low")),
            910 to cap(g("mid")),
            3000 to cap(g("clarity")+amb*0.5f),
            14000 to cap(g("high")+amb*0.5f)
        )
        // [21v33] 自动前级：最高正增益的 70% 全局回退防削波（曲线形状不变）
        val peak=targets.maxOf{it.second}
        val pre=if(peak>0f) -peak*0.7f else 0f
        val range=eq.bandLevelRange"""

rep(old_targets, new_targets, "cap+preamp")

rep("                    val lvl=(db*100).toInt().coerceIn(lo,hi)",
    "                    val lvl=((db+pre)*100).toInt().coerceIn(lo,hi) // [21v33]",
    "lvl 用 db+pre")

assert MARK in c and "applyEqLevels" in c
with open(PATH, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 21 v33 完成")
PYEOF33

echo "=== 21 v33 完成 ==="

# === 21 v34: DSP 引擎仲裁（极致音质开关） ===
# dsp 开：释放系统 Equalizer、bindEqualizer 不再挂载、增益直推 EqDspProcessor；
# dsp 关：处理器旁路、系统 EQ 照旧（v32/v33 逻辑）。dsp 默认 false。
# 处理器挂载：buildAudioSink 的处理器数组扩为 (eqDspProcessor, spectrumProcessor)。
echo "=== 21 v34 ==="

python3 << 'PYEOF34'
import sys

PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v34]"

with open(PATH, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("21 v34: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 21 v34 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

rep("    private var eqEffect: Equalizer? = null // [21v32]",
    "    private var eqEffect: Equalizer? = null // [21v32]\n    private val eqDspProcessor = EqDspProcessor() // [21v34]",
    "eqDspProcessor 字段")

rep("                        .setAudioProcessors(arrayOf<AudioProcessor>(spectrumProcessor))",
    "                        .setAudioProcessors(arrayOf<AudioProcessor>(eqDspProcessor, spectrumProcessor)) // [21v34]",
    "sink 处理器数组")

old_head = """    fun applyEqFromPrefs() {
        try{
            if(!isEqOn()){
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                return
            }"""
new_head = """    fun applyEqFromPrefs() {
        try{
            if(!isEqOn()){
                eqDspProcessor.dspEnabled=false // [21v34]
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                return
            }
            // [21v34] DSP 仲裁：开则释放系统 EQ、增益直推处理器；关则处理器旁路走系统 EQ（dsp 默认 false）
            val dspOn=try{appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)?.getBoolean("dsp",false)?:false}catch(_:Exception){false}
            eqDspProcessor.dspEnabled=dspOn
            if(dspOn){
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                val p=appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)
                if(p!=null){
                    fun gg(k:String)=try{p.getFloat(k,0f)}catch(_:Exception){0f}
                    eqDspProcessor.setGains(gg("sub"),gg("low"),gg("mid"),gg("clarity"),gg("high"),gg("amb"))
                }
                return
            }"""
rep(old_head, new_head, "applyEqFromPrefs 仲裁")

old_bind = """        if(!isEqOn()) return
        try{
            val eq=Equalizer(0,sid)"""
new_bind = """        if(!isEqOn()) return
        if(try{appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)?.getBoolean("dsp",false)?:false}catch(_:Exception){false}) return // [21v34] DSP 模式不挂系统 EQ
        try{
            val eq=Equalizer(0,sid)"""
rep(old_bind, new_bind, "bindEqualizer DSP 守卫")

rep('            Log.i(TAG,"ExoOK")',
    '            try{applyEqFromPrefs()}catch(_:Exception){} // [21v34] 建播后按 prefs 自启（含 DSP）\n            Log.i(TAG,"ExoOK")',
    "建播自启 applyEqFromPrefs")

assert MARK in c and "eqDspProcessor" in c
with open(PATH, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 21 v34 完成")
PYEOF34

echo "=== 21 v34 完成 ==="

# === 21 v35: EQ 双引擎互斥仲裁（dsp 优先） ===
# applyEqFromPrefs 头部重构：先判 dsp（开=处理器接管+释放系统 EQ），
# 再判系统 EQ 开关；页面侧 37 v5 已做落盘互斥，这里是引擎侧兜底。
echo "=== 21 v35 ==="

python3 << 'PYEOF35'
import sys

PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v35]"

with open(PATH, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("21 v35: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 21 v35 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

OLD = """    fun applyEqFromPrefs() {
        try{
            if(!isEqOn()){
                eqDspProcessor.dspEnabled=false // [21v34]
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                return
            }
            // [21v34] DSP 仲裁：开则释放系统 EQ、增益直推处理器；关则处理器旁路走系统 EQ（dsp 默认 false）
            val dspOn=try{appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)?.getBoolean("dsp",false)?:false}catch(_:Exception){false}
            eqDspProcessor.dspEnabled=dspOn
            if(dspOn){
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                val p=appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)
                if(p!=null){
                    fun gg(k:String)=try{p.getFloat(k,0f)}catch(_:Exception){0f}
                    eqDspProcessor.setGains(gg("sub"),gg("low"),gg("mid"),gg("clarity"),gg("high"),gg("amb"))
                }
                return
            }"""

NEW = """    fun applyEqFromPrefs() {
        try{
            // [21v35] 双引擎互斥：dsp 优先。开则处理器接管+释放系统 EQ；关则处理器旁路，再看系统 EQ 开关
            val dspOn=try{appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)?.getBoolean("dsp",false)?:false}catch(_:Exception){false}
            if(dspOn){
                eqDspProcessor.dspEnabled=true
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                val p=appContext?.getSharedPreferences("eq_settings",android.content.Context.MODE_PRIVATE)
                if(p!=null){
                    fun gg(k:String)=try{p.getFloat(k,0f)}catch(_:Exception){0f}
                    eqDspProcessor.setGains(gg("sub"),gg("low"),gg("mid"),gg("clarity"),gg("high"),gg("amb"))
                }
                return
            }
            eqDspProcessor.dspEnabled=false
            if(!isEqOn()){
                try{eqEffect?.release()}catch(_:Exception){}
                eqEffect=null
                return
            }"""

rep(OLD, NEW, "applyEqFromPrefs 互斥头")

assert MARK in c
with open(PATH, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 21 v35 完成")
PYEOF35

echo "=== 21 v35 完成 ==="

# === 21 v36: 系统 EQ 遗留标记 @Deprecated（纯 DSP 版本预留移除） ===
# 只加注解不动逻辑：eqEffect 字段、bindEqualizer、applyEqLevels 三处。
# applyEqFromPrefs 是双引擎共用仲裁，不标记。
echo "=== 21 v36 ==="

python3 << 'PYEOF36'
import sys

PATH = "app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
MARK = "// [21v36]"
DEP = '    @Deprecated("系统 EQ 遗留：纯 DSP 版本将移除") // [21v36]'

with open(PATH, encoding="utf-8") as f:
    c = f.read()

if MARK in c:
    print("21 v36: 已应用，跳过")
    sys.exit(0)

def rep(old, new, tag):
    global c
    if c.count(old) != 1:
        print(f"X 21 v36 锚点计数异常 [{tag}]: {c.count(old)}")
        sys.exit(1)
    c = c.replace(old, new)
    print(f"  OK {tag}")

rep("    private var eqEffect: Equalizer? = null // [21v32]",
    DEP + "\n    private var eqEffect: Equalizer? = null // [21v32]",
    "eqEffect 字段标记")

rep("    private fun bindEqualizer(sid: Int) {",
    DEP + "\n    private fun bindEqualizer(sid: Int) {",
    "bindEqualizer 标记")

rep("    private fun applyEqLevels(eq: Equalizer) {",
    DEP + "\n    private fun applyEqLevels(eq: Equalizer) {",
    "applyEqLevels 标记")

assert c.count(MARK) == 3
with open(PATH, "w", encoding="utf-8") as f:
    f.write(c)
print("OK 21 v36 完成")
PYEOF36

echo "=== 21 v36 完成 ==="


# === 21 v37: 纯 DSP（移除系统 EQ 全部遗留代码） ===
python3 << 'PYEOF21V37'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()

def scan_fn(text, sig):
    i = text.index(sig)
    # 回吞紧贴上方的 @Deprecated 行与注释行
    start = i
    lines = text[:i].splitlines(keepends=True)
    j = len(lines)
    while j > 0 and (lines[j-1].lstrip().startswith('@Deprecated') or lines[j-1].lstrip().startswith('// [21v')):
        j -= 1
    start = sum(len(x) for x in lines[:j])
    depth = 0
    k = text.index('{', i)
    m = k
    while True:
        c = text[m]
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: break
        m += 1
    end = m + 1
    if end < len(text) and text[end] == '\n': end += 1
    return start, end

def remove_fn(text, sig):
    a, b = scan_fn(text, sig)
    seg = text[a:b]
    assert sig.split('(')[0] in seg, seg[:80]
    return text[:a] + text[b:]

# 1) import 与字段
old = 'import android.media.audiofx.Equalizer\n'
assert s.count(old) == 1; s = s.replace(old, '', 1)
old = '''    @Deprecated("系统 EQ 遗留：纯 DSP 版本将移除") // [21v36]
    private var eqEffect: Equalizer? = null // [21v32]
'''
assert s.count(old) == 1; s = s.replace(old, '', 1)

# 2) 会话钩子里的 bindEqualizer 调用行（响度钩子保留）
old = '                        try{bindEqualizer(sid)}catch(_:Exception){} // [21v32]\n'
assert s.count(old) == 1; s = s.replace(old, '', 1)

# 3) 删除三个系统 EQ 函数
s = remove_fn(s, 'private fun bindEqualizer(sid: Int)')
s = remove_fn(s, 'fun isEqOn(): Boolean')
s = remove_fn(s, 'private fun applyEqLevels(eq: Equalizer)')

# 4) applyEqFromPrefs 整替为纯 DSP 版
a, b = scan_fn(s, 'fun applyEqFromPrefs()')
new_fn = '''    fun applyEqFromPrefs() { // [21v37] 纯 DSP：系统 EQ 已移除，只剩处理器一条链
        try {
            val p = appContext?.getSharedPreferences("eq_settings", android.content.Context.MODE_PRIVATE)
            val dspOn = try { p?.getBoolean("dsp", false) ?: false } catch (_: Exception) { false }
            eqDspProcessor.dspEnabled = dspOn
            if (dspOn && p != null) {
                fun gg(k: String) = try { p.getFloat(k, 0f) } catch (_: Exception) { 0f }
                eqDspProcessor.setGains(gg("sub"), gg("low"), gg("mid"), gg("clarity"), gg("high"), gg("amb"))
            }
        } catch (_: Exception) {
        }
    }
'''
s = s[:a] + new_fn + s[b:]

for dead in ('Equalizer', 'eqEffect', 'bindEqualizer', 'applyEqLevels', 'isEqOn'):
    if dead in s:
        print(f"X 21v37 残留 {dead}"); sys.exit(1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v37 纯 DSP：系统 EQ 已移除")
PYEOF21V37
echo "=== 21 v37 完成 ==="

# === 21 v38: 立体声拓宽开关下发 ===
python3 << 'PYEOF21V38'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
old = "            eqDspProcessor.dspEnabled = dspOn"
assert s.count(old) == 1
new = """            eqDspProcessor.dspEnabled = dspOn
            eqDspProcessor.stereoWide = try { p?.getBoolean("wide", false) ?: false } catch (_: Exception) { false } // [21v38] 立体声拓宽开关下发"""
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v38 wide 下发已加")
PYEOF21V38
echo "=== 21 v38 完成 ==="

# === 21 v39: 多段压缩开关下发 ===
python3 << 'PYEOF21V39'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
old = 'eqDspProcessor.stereoWide = try { p?.getBoolean("wide", false) ?: false } catch (_: Exception) { false } // [21v38] 立体声拓宽开关下发'
assert s.count(old) == 1
new = old + """
            eqDspProcessor.mbcEnabled = try { p?.getBoolean("mbc", false) ?: false } catch (_: Exception) { false } // [21v39] 多段压缩开关下发"""
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v39 mbc 下发已加")
PYEOF21V39
echo "=== 21 v39 完成 ==="

# === 21 v40: 瞬态增强开关下发 ===
python3 << 'PYEOF21V40'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
old = 'eqDspProcessor.mbcEnabled = try { p?.getBoolean("mbc", false) ?: false } catch (_: Exception) { false } // [21v39] 多段压缩开关下发'
assert s.count(old) == 1
new = old + """
            eqDspProcessor.transEnabled = try { p?.getBoolean("trans", false) ?: false } catch (_: Exception) { false } // [21v40] 瞬态增强开关下发"""
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v40 trans 下发已加")
PYEOF21V40
echo "=== 21 v40 完成 ==="

# === 21 v41: Sub 合成 + Crossfeed 开关下发 ===
python3 << 'PYEOF21V41'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
old = 'eqDspProcessor.transEnabled = try { p?.getBoolean("trans", false) ?: false } catch (_: Exception) { false } // [21v40] 瞬态增强开关下发'
assert s.count(old) == 1
new = old + """
            eqDspProcessor.subEnabled = try { p?.getBoolean("sub", false) ?: false } catch (_: Exception) { false } // [21v41] Sub 谐波合成开关下发
            eqDspProcessor.cfEnabled = try { p?.getBoolean("cross", false) ?: false } catch (_: Exception) { false } // [21v41] Crossfeed 开关下发"""
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v41 sub/cross 下发已加")
PYEOF21V41
echo "=== 21 v41 完成 ==="

# === 21 v42: 评论（只读）StateFlow + 网易云热评拉取 ===
python3 << 'PYEOF21V42'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[21v42]" in s:
    print("跳过（21 v42 已应用）"); sys.exit(0)
old = "import kotlinx.coroutines.launch"
assert s.count(old) == 1, "import launch 锚点"
s = s.replace(old, old + "\nimport kotlinx.coroutines.CoroutineScope\nimport kotlinx.coroutines.Dispatchers", 1)
old = "import org.json.JSONArray"
assert s.count(old) == 1, "import json 锚点"
s = s.replace(old, "import java.net.HttpURLConnection\nimport java.net.URL\n" + old, 1)
old = "object LxPlayerManager {"
assert s.count(old) == 1, "object 锚点"
s = s.replace(old, """// [21v42] 评论条目（只读展示）
data class LxComment(
    val userName: String,
    val avatarUrl: String,
    val content: String,
    val likedCount: Int,
    val timeMs: Long,
)

""" + old, 1)
old = "        fun applyEqFromPrefs() {"
assert s.count(old) == 1, "applyEq 锚点"
new = """        // [21v42] 评论（只读）：网易云公开热评，IO 拉取、4 秒超时、失败静默空列表、令牌防串歌
        private val _comments = MutableStateFlow<List<LxComment>>(emptyList())
        val comments: StateFlow<List<LxComment>> = _comments
        @Volatile private var commentToken = 0
        @Volatile private var commentKey = ""

        fun fetchCommentsAsync(platform: String, songId: String, title: String, artist: String) {
            val key = platform + "|" + songId + "|" + title
            if (key == commentKey && _comments.value.isNotEmpty()) return
            commentKey = key
            val myToken = ++commentToken
            _comments.value = emptyList()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val wyId = if (platform == "wy") songId else findNeteaseSongId(title, artist)
                    if (wyId.isNullOrBlank()) return@launch
                    val list = fetchNeteaseComments(wyId)
                    if (myToken == commentToken) _comments.value = list
                } catch (e: Exception) {
                    android.util.Log.w("LxComment", "评论拉取失败: " + e.message)
                }
            }
        }

        private suspend fun findNeteaseSongId(title: String, artist: String): String? {
            return try {
                val both = LxMusicSearchApi.searchBoth(title + " " + artist)
                val all = both.full + both.display
                val exact = all.firstOrNull { it.platform == "wy" && it.title.contains(title.take(6)) && (artist.isBlank() || it.artist.contains(artist.take(2))) }
                (exact ?: all.firstOrNull { it.platform == "wy" && it.title.contains(title.take(6)) })?.id
            } catch (e: Exception) { null }
        }

        private fun fetchNeteaseComments(wyId: String): List<LxComment> {
            val conn = URL("https://music.163.com/api/v1/resource/comments/R_SO_4_" + wyId + "?limit=20").openConnection() as HttpURLConnection
            conn.connectTimeout = 4000
            conn.readTimeout = 4000
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36")
            conn.setRequestProperty("Referer", "https://music.163.com/")
            val text = conn.inputStream.bufferedReader().use { it.readText() }
            val root = JSONObject(text)
            val hot = root.optJSONArray("hotComments")
            val src = if (hot != null && hot.length() > 0) hot else root.optJSONArray("comments") ?: return emptyList()
            val out = ArrayList<LxComment>()
            val n = if (src.length() < 20) src.length() else 20
            for (i in 0 until n) {
                val c = src.optJSONObject(i) ?: continue
                val u = c.optJSONObject("user")
                out.add(LxComment(
                    userName = u?.optString("nickname").orEmpty(),
                    avatarUrl = u?.optString("avatarUrl").orEmpty(),
                    content = c.optString("content"),
                    likedCount = c.optInt("likedCount"),
                    timeMs = c.optLong("time"),
                ))
            }
            return out
        }

""" + old
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v42 评论链已加")
PYEOF21V42
echo "=== 21 v42 完成 ==="

# === 21 v43: 切歌锁 isChangingTrack（控制台+播放页按钮统一反馈，用户 2026-10-25 确认） ===
# 设计：锁只锁“用户点上/下一首”的解析过程，不锁 togglePlayPause（瞬时操作、无复位事件会卡锁）。
# 置位：playNext/Previous 真推进 index 后、发起解析前；返回 false 的路（队空/队首/队尾）不置位，异常回滚时复位。
# 复位：STATE_READY（真正出声）/ onPlayerError / setError(non-null) / 30 秒超时兜底（对齐引擎 warmup 上限）。
# 不复用 _isLoading：STATE_BUFFERING 时它也为真（1143 行），复用会在卡歌时锁死跳歌。
# 自然播完自动切歌不走 playNext/Previous（STATE_ENDED 内联逻辑），故不置位，合乎“只锁点击”的范围。
python3 << 'PYEOF21V43'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[21v43]" in s:
    print("跳过（21 v43 已应用）"); sys.exit(0)
old = """    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading"""
assert s.count(old) == 1, "v43 isLoading 声明锚点数=" + str(s.count(old))
s = s.replace(old, old + """
    // [21v43] 切歌锁：控制台+播放页两边同看它；置位只在 playNext/Previous 真推进后，复位见 STATE_READY/onPlayerError/setError/超时
    private val _isChangingTrack = MutableStateFlow(false)
    val isChangingTrack: StateFlow<Boolean> = _isChangingTrack
    private val changingTrackTimeout = Runnable { _isChangingTrack.value = false }
    private fun setChangingTrack(value: Boolean) {
        if (value) {
            _isChangingTrack.value = true
            mainHandler.removeCallbacks(changingTrackTimeout)
            mainHandler.postDelayed(changingTrackTimeout, 30_000L)
        } else {
            _isChangingTrack.value = false
            mainHandler.removeCallbacks(changingTrackTimeout)
        }
    }""", 1)
old = """            onResolveQueueSong?.invoke(song) ?: resolveAndPlay(song)
            true
        } catch (e: Exception) {
            Log.e(TAG, "上一首失败", e)
            queueIndex = oldIndex
            false"""
assert s.count(old) == 1, "v43 上一首锚点数=" + str(s.count(old))
s = s.replace(old, """            setChangingTrack(true) // [21v43]
            onResolveQueueSong?.invoke(song) ?: resolveAndPlay(song)
            true
        } catch (e: Exception) {
            Log.e(TAG, "上一首失败", e)
            queueIndex = oldIndex
            setChangingTrack(false) // [21v43]
            false""", 1)
old = """            onResolveQueueSong?.invoke(song) ?: resolveAndPlay(song)
            true
        } catch (e: Exception) {
            Log.e(TAG, "下一首失败", e)
            queueIndex = oldIndex
            false"""
assert s.count(old) == 1, "v43 下一首锚点数=" + str(s.count(old))
s = s.replace(old, """            setChangingTrack(true) // [21v43]
            onResolveQueueSong?.invoke(song) ?: resolveAndPlay(song)
            true
        } catch (e: Exception) {
            Log.e(TAG, "下一首失败", e)
            queueIndex = oldIndex
            setChangingTrack(false) // [21v43]
            false""", 1)
old = """                            Player.STATE_READY -> {
                                _isLoading.value = false
                                _duration.value = duration.coerceAtLeast(0L)
                            }"""
assert s.count(old) == 1, "v43 STATE_READY 锚点数=" + str(s.count(old))
s = s.replace(old, """                            Player.STATE_READY -> {
                                _isLoading.value = false
                                setChangingTrack(false) // [21v43] 真正出声才算切歌成功
                                _duration.value = duration.coerceAtLeast(0L)
                            }""", 1)
old = """                        _isLoading.value = false
                        val code = error.errorCode"""
assert s.count(old) == 1, "v43 onPlayerError 锚点数=" + str(s.count(old))
s = s.replace(old, """                        _isLoading.value = false
                        setChangingTrack(false) // [21v43] 报错先解旧锁，后续自动切歌会重新置位
                        val code = error.errorCode""", 1)
old = "if (msg != null) { _isLoading.value = false; _isProbing.value = false } // [21v30]"
assert s.count(old) == 1, "v43 setError 锚点数=" + str(s.count(old))
s = s.replace(old, "if (msg != null) { _isLoading.value = false; _isProbing.value = false; setChangingTrack(false) } // [21v30] [21v43]", 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v43 切歌锁已加")
PYEOF21V43
echo "=== 21 v43 完成 ==="
# === 21 v44: 激励器 + 等响度开关下发 + 音量刷新 ===
python3 << 'PYEOF21V44'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[21v44]" in s:
    print("跳过（21 v44 已应用）"); sys.exit(0)
old = 'eqDspProcessor.cfEnabled = try { p?.getBoolean("cross", false) ?: false } catch (_: Exception) { false } // [21v41] Crossfeed 开关下发'
assert s.count(old) == 1, "cf 锚点"
new = old + """
            eqDspProcessor.excEnabled = try { p?.getBoolean("exc", false) ?: false } catch (_: Exception) { false } // [21v44] 激励器开关下发
            eqDspProcessor.loudEnabled = try { p?.getBoolean("loud", false) ?: false } catch (_: Exception) { false } // [21v44] 等响度开关下发
            refreshLoudnessVolume() // [21v44] 音量刷新（换歌/改设置时）"""
s = s.replace(old, new, 1)
old2 = "fun applyEqFromPrefs() {"
assert s.count(old2) == 1, "applyEq 锚点"
vol_block = """        // [21v44] 等响度音量来源：系统音乐音量（0..1）；换歌/改设置时刷新 + 音量广播跟随（注册失败则只靠换歌刷新）
        @Volatile private var loudReceiverRegistered = false
        fun refreshLoudnessVolume() {
            try {
                val am = appContext?.getSystemService(android.content.Context.AUDIO_SERVICE) as? android.media.AudioManager
                val vol = am?.getStreamVolume(android.media.AudioManager.STREAM_MUSIC) ?: 0
                val max = am?.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC) ?: 1
                eqDspProcessor.loudVolume = if (max > 0) (vol.toFloat() / max.toFloat()).coerceIn(0f, 1f) else 1f
            } catch (_: Exception) {
            }
            try {
                val ctx = appContext
                if (ctx != null && !loudReceiverRegistered) {
                    ctx.registerReceiver(object : android.content.BroadcastReceiver() {
                        override fun onReceive(c: android.content.Context?, intent: android.content.Intent?) {
                            try { refreshLoudnessVolume() } catch (_: Exception) { }
                        }
                    }, android.content.IntentFilter("android.media.VOLUME_CHANGED_ACTION"))
                    loudReceiverRegistered = true
                }
            } catch (_: Exception) {
            }
        }

"""
s = s.replace(old2, vol_block + old2, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v44 exc/loud 下发 + 音量刷新已加")
PYEOF21V44
echo "=== 21 v44 完成 ==="

# === 21 v45: Sub 开关键改 subfx（避与 60Hz 滑块键 sub 撞键，切歌不再自动关） ===
python3 << 'PYEOF21V45'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[21v45]" in s:
    print("跳过（21 v45 已应用）"); sys.exit(0)
old = 'eqDspProcessor.subEnabled = try { p?.getBoolean("sub", false) ?: false } catch (_: Exception) { false } // [21v41] Sub 谐波合成开关下发'
assert s.count(old) == 1, "sub 锚点"
new = 'eqDspProcessor.subEnabled = try { p?.getBoolean("subfx", false) ?: false } catch (_: Exception) { false } // [21v41] Sub 谐波合成开关下发 [21v45] 键改 subfx'
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v45 Sub 键改 subfx 已加")
PYEOF21V45
echo "=== 21 v45 完成 ==="

# === 21 v46: Autogain 开关下发 + 均衡页调试快照 ===
python3 << 'PYEOF21V46'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[21v46]" in s:
    print("跳过（21 v46 已应用）"); sys.exit(0)
old = 'eqDspProcessor.loudEnabled = try { p?.getBoolean("loud", false) ?: false } catch (_: Exception) { false } // [21v44] 等响度开关下发'
assert s.count(old) == 1, "loud 锚点"
new = old + '\n            eqDspProcessor.agEnabled = try { p?.getBoolean("ag", false) ?: false } catch (_: Exception) { false } // [21v46] Autogain 开关下发'
s = s.replace(old, new, 1)
old2 = "fun applyEqFromPrefs() { // [21v37]"
assert s.count(old2) == 1, "applyEq 锚点"
new2 = "fun dspDebugSnapshot(): EqDspProcessor.DspDebug = eqDspProcessor.debugSnapshot() // [21v46] 均衡页实时状态快照\n    " + old2
s = s.replace(old2, new2, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 21 v46 ag 下发 + 快照已加")
PYEOF21V46
echo "=== 21 v46 完成 ==="
