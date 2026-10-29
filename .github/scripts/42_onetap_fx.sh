#!/bin/bash
set -e
# 42 - 一键音效（蝰蛇味组合：参数调好、一键开/关；新系统，build.yml 调用行由用户手动加在 41 之后）
cd "$(dirname "$0")/../.."
echo "=== 42 一键音效 ==="

# === 42 v1: 引擎：一键三新级 + BS2B 分支 + 系数 + 快照 + 复位 ===
python3 << 'PYEOF42V1ENG'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v1]" in s:
    print("跳过（42 v1 引擎已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)
def rep2(old, new, name):
    global s
    assert s.count(old) == 2, name
    s = s.replace(old, new)

rep1(r"""    private var lfSlowCoef = 0.005f

    // [38dsp10] Sub 谐波合成（参数=深空流光包：分频 90Hz、合成增益 +4dB、mix 0.30）：默认关""",
r"""    private var lfSlowCoef = 0.005f

    // [42v1] 一键音效总开关（页面一键卡片 + 21 下发）；开 = 三个新级 + BS2B 分支，关 = 全停
    @Volatile
    var onetapEnabled: Boolean = false

    // [42v1] 一键低频（ViPER Subwoofer 式：PEAK 44Hz +7.96dB Q0.75、PEAK-low 80Hz -10.10dB Q0.2、LP 380Hz Q0.6；混合 = 干声 x0.5 + 残差 x0.6）
    private val vbPk = Biquad()
    private val vbPkLow = Biquad()
    private val vbLp = Biquad()

    // [42v1] 动态低音（DynamicBass 简模式：55Hz 低通单声道叠加，Q 跟增益走）
    private val dbLp = Biquad()

    // [42v1] 高频扩展（SpectrumExtend 式：HP 7600Hz -> Chebyshev 奇次谐波 -> LP(nyquist-2000)，激励量 1.0，加回干声）
    private val seHp = Biquad()
    private val seLp = Biquad()
    private val seCoeffs = DoubleArray(11)
    private val seLast = DoubleArray(2)
    private val sePrevOut = DoubleArray(2)
    private val seCounter = IntArray(2)

    // [42v1] BS2B crossfeed 系数与状态（700Hz / 4.5dB 档；仅一键开时走此分支，手动 cross 仍走旧简化版）
    private var bsA0Lo = 0f
    private var bsB1Lo = 0f
    private var bsA0Hi = 0f
    private var bsA1Hi = 0f
    private var bsB1Hi = 0f
    private var bsGain = 1f
    private val bsLo = FloatArray(2)
    private val bsHi = FloatArray(2)
    private val bsAsis = FloatArray(2)

    // [38dsp10] Sub 谐波合成（参数=深空流光包：分频 90Hz、合成增益 +4dB、mix 0.30）：默认关""", "一键字段")

rep1(r"""    var dbgLfprocPeak: Float = 0f""",
r"""    var dbgLfprocPeak: Float = 0f
    @Volatile
    var dbgVbPeak: Float = 0f // [42v1]
    @Volatile
    var dbgDbPeak: Float = 0f // [42v1]
    @Volatile
    var dbgSePeak: Float = 0f // [42v1]""", "一键峰值字段")

rep1(r"""    private var appliedVersion: Int = -1""",
r"""    private var appliedVersion: Int = -1
    private var appliedOnetap: Boolean = false // [42v1]""", "appliedOnetap 字段")

rep1(r"""        // [38dsp12] 各级独立生效：十四级全关才旁路 [38dsp15][38dsp18][38dsp19][38dsp20][38dsp21][38dsp22]；主开关只管 PEQ 本身（runChain 内门控）""",
r"""        // [38dsp12] 各级独立生效：各级全关才旁路 [38dsp15][38dsp18][38dsp19][38dsp20][38dsp21][38dsp22][42v1]；主开关只管 PEQ 本身（runChain 内门控）""", "旁路注释")

rep1(r"""        val anyStageOn = dspEnabled || subEnabled || transEnabled || mbcEnabled || stereoWide || cfEnabled || excEnabled || loudEnabled || agEnabled || revEnabled || deessEnabled || taEnabled || punchEnabled || lfprocAmount > 0f""",
r"""        val anyStageOn = dspEnabled || subEnabled || transEnabled || mbcEnabled || stereoWide || cfEnabled || excEnabled || loudEnabled || agEnabled || revEnabled || deessEnabled || taEnabled || punchEnabled || lfprocAmount > 0f || onetapEnabled // [42v1]""", "anyStageOn")

rep1(r"""            if (appliedVersion != configVersion) {
                updateCoefficients()
                appliedVersion = configVersion
            }""",
r"""            if (appliedVersion != configVersion) {
                updateCoefficients()
                appliedVersion = configVersion
            }
            if (onetapEnabled != appliedOnetap) { // [42v1] 一键开关变了：重算一键级系数（与增益变化无关，防纯开关切换时系数未初始化）
                updateCoefficients()
                appliedOnetap = onetapEnabled
            }""", "一键系数刷新")

rep1(r"""            dbgLfprocPeak = 0f // [38dsp22]""",
r"""            dbgLfprocPeak = 0f // [38dsp22]
            dbgVbPeak = 0f // [42v1]
            dbgDbPeak = 0f // [42v1]
            dbgSePeak = 0f // [42v1]""", "一键峰值复位")

rep2(r"""                    dbgPeqPeak = maxOf(dbgPeqPeak, abs(frameSamples[0]), abs(frameSamples[1])) // [38dsp18]
                    if (subEnabled) subFrame() // [38dsp10]""",
r"""                    dbgPeqPeak = maxOf(dbgPeqPeak, abs(frameSamples[0]), abs(frameSamples[1])) // [38dsp18]
                    if (onetapEnabled) specExtFrame() // [42v1]
                    dbgSePeak = maxOf(dbgSePeak, abs(frameSamples[0]), abs(frameSamples[1])) // [42v1]
                    if (subEnabled) subFrame() // [38dsp10]""", "高频扩展调用点")

rep2(r"""                    if (subEnabled) subFrame() // [38dsp10]
                    dbgSubPeak = maxOf(dbgSubPeak, abs(frameSamples[0]), abs(frameSamples[1])) // [38dsp18]
                    if (excEnabled) excFrame() // [38dsp15]""",
r"""                    if (subEnabled) subFrame() // [38dsp10]
                    dbgSubPeak = maxOf(dbgSubPeak, abs(frameSamples[0]), abs(frameSamples[1])) // [38dsp18]
                    if (onetapEnabled) dynBassFrame() // [42v1]
                    dbgDbPeak = maxOf(dbgDbPeak, abs(frameSamples[0]), abs(frameSamples[1])) // [42v1]
                    if (onetapEnabled) viperBassFrame() // [42v1]
                    dbgVbPeak = maxOf(dbgVbPeak, abs(frameSamples[0]), abs(frameSamples[1])) // [42v1]
                    if (excEnabled) excFrame() // [38dsp15]""", "低频调用点")

rep1(r"""    // [38dsp11] Crossfeed 一帧：对侧声道经一极低通 + 延迟后以 -6dB 混入（声道联动，帧级处理）
    private fun crossFrame() {
        val l = frameSamples[0]""",
r"""    // [38dsp11] Crossfeed 一帧：对侧声道经一极低通 + 延迟后以 -6dB 混入（声道联动，帧级处理）；[42v1] 一键开时走 BS2B 分支（700Hz/4.5dB 公式版），手动 cross 仍走旧简化版
    private fun crossFrame() {
        if (onetapEnabled) { bs2bFrame(); return }
        val l = frameSamples[0]""", "crossFrame 分支")

rep1(r"""        frameSamples[0] = l + crossIntoL * 0.5f
        frameSamples[1] = r + crossIntoR * 0.5f
    }""",
r"""        frameSamples[0] = l + crossIntoL * 0.5f
        frameSamples[1] = r + crossIntoR * 0.5f
    }

    // [42v1] 一键低频一帧（ViPER Subwoofer 式）：PEAK 44Hz -> PEAK-low 80Hz -> LP 380Hz（残差 = 峰值链输出减干声再过低通）；混合 = 干声 x0.5 + 残差 x0.6
    private fun viperBassFrame() {
        for (ch in 0 until 2) {
            val y = frameSamples[ch]
            var tmp = vbPk.process(ch, y)
            tmp = vbPkLow.process(ch, tmp)
            tmp = vbLp.process(ch, tmp - y)
            frameSamples[ch] = y * 0.5f + tmp * 0.6f
        }
    }

    // [42v1] 动态低音一帧（DynamicBass 简模式）：55Hz 低通取左右声道和的单声道低频，叠加回双声道（低频单声道化 + 叠加）
    private fun dynBassFrame() {
        val sum = frameSamples[0] + frameSamples[1]
        val avg = dbLp.process(0, sum)
        frameSamples[0] += avg
        frameSamples[1] += avg
    }

    // [42v1] 高频扩展一帧（SpectrumExtend 式）：HP 7600Hz -> Chebyshev 奇次谐波 -> LP(nyquist-2000)，激励量 1.0，加回干声
    private fun specExtFrame() {
        for (ch in 0 until 2) {
            val y = frameSamples[ch]
            var tmp = seHp.process(ch, y).toDouble()
            tmp = seHarmonic(ch, tmp)
            val lp = seLp.process(ch, tmp.toFloat())
            frameSamples[ch] = y + lp
        }
    }

    // [42v1] Chebyshev 谐波发生器（ViPER Harmonic 式）：系数经 Chebyshev 递推转幂级数后 Horner 求值，再过漏积分微分器；前 200 采样暖机静音（与原版一致）
    private fun seHarmonic(ch: Int, x: Double): Double {
        val prevLast = seLast[ch]
        var v = seCoeffs[10]
        for (i in 9 downTo 0) v = v * x + seCoeffs[i]
        seLast[ch] = v
        sePrevOut[ch] = (v + sePrevOut[ch] * 0.999) - prevLast
        if (seCounter[ch] < 200) {
            seCounter[ch]++
            return 0.0
        }
        return sePrevOut[ch]
    }

    // [42v1] Chebyshev 系数换算（ViPER Harmonic::UpdateCoeffs 式）：10 个谐波系数（0.02 x T1/T3/T5/T7/T9）-> 11 阶幂级数系数
    private fun seComputeCoeffs() {
        val harm = doubleArrayOf(0.02, 0.0, 0.02, 0.0, 0.02, 0.0, 0.02, 0.0, 0.02, 0.0)
        var absSum = 0.0
        var biggest = 0.0
        for (i in 0 until 10) {
            val a = abs(harm[i])
            absSum += a
            if (a > biggest) biggest = a
        }
        val unk1 = DoubleArray(11)
        var unk = 1.0
        if (absSum > 1.0) unk = 1.0 / absSum
        for (i in 1 until 11) unk1[i] = harm[i - 1] * unk
        val unk2 = DoubleArray(11)
        val c = DoubleArray(11)
        c[10] = unk1[10]
        for (i in 2 until 11) {
            for (j in 0 until i) {
                val tmp = unk2[i - j]
                unk2[i - j] = c[i - j]
                c[i - j] = c[i - j - 1] * 2.0 - tmp
            }
            val tmp = unk1[10 - i + 1] - unk2[0]
            unk2[0] = c[0]
            c[0] = tmp
        }
        for (i in 1 until 11) {
            c[10 - i + 1] = c[10 - i] - unk2[10 - i + 1]
        }
        c[0] = unk1[0] / 2.0 - unk2[0]
        for (i in 0 until 11) seCoeffs[i] = c[i]
    }

    // [42v1] BS2B crossfeed 一帧（Bauer 双耳滤波：低通支路 + 高架支路交叉混合，归一化增益）
    private fun bs2bFrame() {
        val l = frameSamples[0]
        val r = frameSamples[1]
        bsLo[0] = bsA0Lo * l + bsB1Lo * bsLo[0]
        bsLo[1] = bsA0Lo * r + bsB1Lo * bsLo[1]
        bsHi[0] = bsA0Hi * l + bsA1Hi * bsAsis[0] + bsB1Hi * bsHi[0]
        bsHi[1] = bsA0Hi * r + bsA1Hi * bsAsis[1] + bsB1Hi * bsHi[1]
        bsAsis[0] = l
        bsAsis[1] = r
        frameSamples[0] = (bsHi[0] + bsLo[1]) * bsGain
        frameSamples[1] = (bsHi[1] + bsLo[0]) * bsGain
    }""", "一键级函数")

rep1(r"""        lfEnvF = 0f // [38dsp22]
        lfEnvS = 0f // [38dsp22]
        subLp1.reset() // [38dsp10]""",
r"""        lfEnvF = 0f // [38dsp22]
        lfEnvS = 0f // [38dsp22]
        vbPk.reset() // [42v1]
        vbPkLow.reset() // [42v1]
        vbLp.reset() // [42v1]
        dbLp.reset() // [42v1]
        seHp.reset() // [42v1]
        seLp.reset() // [42v1]
        seLast.fill(0.0) // [42v1]
        sePrevOut.fill(0.0) // [42v1]
        seCounter.fill(0) // [42v1]
        bsLo.fill(0f) // [42v1]
        bsHi.fill(0f) // [42v1]
        bsAsis.fill(0f) // [42v1]
        subLp1.reset() // [38dsp10]""", "一键复位")

rep1(r"""                StagePeak("PEQ", dspEnabled, dbgPeqPeak),""",
r"""                StagePeak("PEQ", dspEnabled, dbgPeqPeak),
                StagePeak("高频扩展", onetapEnabled, dbgSePeak), // [42v1]""", "快照高频扩展")

rep1(r"""                StagePeak("Sub", subEnabled, dbgSubPeak),""",
r"""                StagePeak("Sub", subEnabled, dbgSubPeak),
                StagePeak("动态低音", onetapEnabled, dbgDbPeak), // [42v1]
                StagePeak("一键低频", onetapEnabled, dbgVbPeak), // [42v1]""", "快照低频")

rep1(r"""        updateLoudnessCoefficients()
    }""",
r"""        // [42v1] 一键低频滤波器（ViPER Subwoofer::SetBassGain，因子 1.0 -> PEAK 44Hz +7.96dB Q0.75、PEAK-low 80Hz -10.10dB Q0.2、LP 380Hz Q0.6）
        setPeaking(vbPk, 44.0, 0.75, 20.0 * log10(2.5), sr)
        setPeaking(vbPkLow, 80.0, 0.2, 20.0 * log10(2.5 / 8.0), sr)
        setLowpass(vbLp, 380.0, 0.6, sr)
        // [42v1] 动态低音 55Hz 低通（DynamicBass 简模式，gain=2.0 -> qPeak=80 -> Q 0.62）
        setLowpass(dbLp, 55.0, 0.5 + 80.0 / 666.0, sr)
        // [42v1] 高频扩展分频（SpectrumExtend 式：HP 7600Hz Q0.717 + LP(nyquist-2000) Q0.717）+ Chebyshev 系数
        setHighpass(seHp, 7600.0, 0.717, sr)
        setLowpass(seLp, sr / 2.0 - 2000.0, 0.717, sr)
        seComputeCoeffs()
        // [42v1] BS2B crossfeed 系数（700Hz / 4.5dB 档，公式见 ViPER Crossfeed::Reset）
        val bsLevel = 4.5
        val bsGbLo = bsLevel * -5.0 / 6.0 - 3.0
        val bsGbHi = bsLevel / 6.0 - 3.0
        val bsGLo = 10.0.pow(bsGbLo / 20.0)
        val bsGHi = 1.0 - 10.0.pow(bsGbHi / 20.0)
        val bsFcHi = 700.0 * 2.0.pow((bsGbLo - 20.0 * log10(bsGHi)) / 12.0)
        var bsX = exp(-2.0 * PI * 700.0 / sr)
        bsB1Lo = bsX.toFloat()
        bsA0Lo = (bsGLo * (1.0 - bsX)).toFloat()
        bsX = exp(-2.0 * PI * bsFcHi / sr)
        bsB1Hi = bsX.toFloat()
        bsA0Hi = (1.0 - bsGHi * (1.0 - bsX)).toFloat()
        bsA1Hi = (-bsX).toFloat()
        bsGain = (1.0 / (1.0 - bsGHi + bsGLo)).toFloat()
        updateLoudnessCoefficients()
    }""", "一键系数")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v1 引擎已加")
PYEOF42V1ENG
echo "=== 42 v1 引擎完成 ==="

# === 42 v1: 页面：一键卡片 + 状态变量 + 预设清一键 ===
python3 << 'PYEOF42V1PAGE'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v1]" in s:
    print("跳过（42 v1 页面已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""        )
    }

    // [37eq16] 两页 Pager：0=均衡（总开关+预设+六段），1=音效（十二级独立开关 + 低频处理器滑块）[37eq18][37eq20][37eq22][37eq24][37eq25][37eq26]""",
r"""        )
    }

    // [42v1] 一键音效开关（默认关；开=固定组合，关=原声）
    var onetap by remember {
        mutableStateOf(
            try {
                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).getBoolean("onetap", false)
            } catch (_: Exception) {
                false
            }
        )
    }

    // [37eq16] 两页 Pager：0=均衡（总开关+预设+六段），1=音效（十二级独立开关 + 低频处理器滑块）[37eq18][37eq20][37eq22][37eq24][37eq25][37eq26]""", "一键状态变量")

rep1(r"""                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.large,
                        colors = CardDefaults.cardColors(containerColor = musicColors().card)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "极致音质（DSP 引擎）",""",
r"""                    Card( // [42v1] 一键音效
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.large,
                        colors = CardDefaults.cardColors(containerColor = musicColors().card)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "一键音效",
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = musicColors().textPrimary
                                )
                                Text(
                                    "调好的组合一键开/关：低频增强 + 动态低音 + 高频扩展 + 环绕 + 混响；关就是原声",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = musicColors().textSecondary
                                )
                            }
                            Switch(
                                checked = onetap,
                                onCheckedChange = {
                                    onetap = it
                                    try { context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).edit().putBoolean("onetap", it).commit() } catch (_: Exception) { }
                                    if (it) {
                                        gains = listOf(3f, -1f, 0f, 2f, 0f, 0f)
                                        dsp = true
                                        wide = false
                                        mbc = false
                                        trans = false
                                        sub = true
                                        cross = true
                                        exc = false
                                        loud = false
                                        ag = false
                                        rev = true
                                        deess = false
                                        ta = false
                                        punch = true
                                        lfproc = 0.10f
                                    } else {
                                        gains = List(6) { 0f }
                                        dsp = false
                                        wide = false
                                        mbc = false
                                        trans = false
                                        sub = false
                                        cross = false
                                        exc = false
                                        loud = false
                                        ag = false
                                        rev = false
                                        deess = false
                                        ta = false
                                        taL = 0f
                                        taR = 0f
                                        punch = false
                                        lfproc = 0f
                                    }
                                    persistEq(context, dsp, wide, mbc, trans, sub, cross, exc, loud, ag, rev, deess, ta, taL, taR, punch, lfproc, gains)
                                },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = musicColors().accentText,
                                    checkedTrackColor = musicColors().accent,
                                    uncheckedThumbColor = musicColors().textSecondary,
                                    uncheckedTrackColor = musicColors().cardSecondary
                                )
                            )
                        }
                    }
                Spacer(Modifier.height(16.dp))
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.large,
                        colors = CardDefaults.cardColors(containerColor = musicColors().card)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "极致音质（DSP 引擎）",""", "一键卡片")

rep1(r"""                                    savePresetName(context, name) // [37eq20]
                                    persistEq(context, dsp, wide, mbc, trans, sub, cross, exc, loud, ag, rev, deess, ta, taL, taR, punch, lfproc, gains)""",
r"""                                    onetap = false // [42v1] 换预设 = 换整套组合，一键状态清掉
                                    try { context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).edit().putBoolean("onetap", false).commit() } catch (_: Exception) { }
                                    savePresetName(context, name) // [37eq20]
                                    persistEq(context, dsp, wide, mbc, trans, sub, cross, exc, loud, ag, rev, deess, ta, taL, taR, punch, lfproc, gains)""", "预设清一键")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v1 页面已加")
PYEOF42V1PAGE
echo "=== 42 v1 页面完成 ==="

# === 42 v1: 下发：一键开关经 applyEqFromPrefs 到引擎 ===
python3 << 'PYEOF42V1MGR'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v1]" in s:
    print("跳过（42 v1 下发已应用）"); sys.exit(0)
old = 'eqDspProcessor.lfprocAmount = try { p?.getFloat("lfproc", 0f) ?: 0f } catch (_: Exception) { 0f } // [21v50] 低频处理器力度下发'
assert s.count(old) == 1, "lfproc 锚点"
new = old + '\n            eqDspProcessor.onetapEnabled = try { p?.getBoolean("onetap", false) ?: false } catch (_: Exception) { false } // [42v1] 一键音效开关下发'
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 42 v1 一键下发已加")
PYEOF42V1MGR
echo "=== 42 v1 下发完成 ==="

# === 42 v2: 卷积空间（分区 FFT 卷积，链首，仅一键） ===
python3 << 'PYEOF42V2ENG'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v2]" in s:
    print("跳过（42 v2 引擎已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)
def rep2(old, new, name):
    global s
    assert s.count(old) == 2, name
    s = s.replace(old, new)

rep1(r"""    private val bsAsis = FloatArray(2)

    // [38dsp10] Sub""",
r"""    private val bsAsis = FloatArray(2)

    // [42v2] 卷积空间（分区卷积，分区 256，FFT 512；湿声延迟一区作预延迟，干声直通；仅一键开）
    private val convN = 256
    private val convFftN = 512
    private val convRingSize = 1024
    private val convWet = 0.5f
    private val convFft = Fft(512)
    private var convSr = -1
    private var convIrRe: Array<Array<FloatArray>> = emptyArray()
    private var convIrIm: Array<Array<FloatArray>> = emptyArray()
    private var convHistRe: Array<Array<FloatArray>> = emptyArray()
    private var convHistIm: Array<Array<FloatArray>> = emptyArray()
    private var convInBlock: Array<FloatArray> = emptyArray()
    private var convTail: Array<FloatArray> = emptyArray()
    private var convOutRing: Array<FloatArray> = emptyArray()
    private var convInPos = IntArray(2)
    private var convRd = IntArray(2)
    private var convWr = 0
    private var convBlock = 0
    private var convTmpRe = FloatArray(convFftN)
    private var convTmpIm = FloatArray(convFftN)
    private var convAccRe = FloatArray(convFftN)
    private var convAccIm = FloatArray(convFftN)

    // [38dsp10] Sub""", "卷积字段")

rep1(r"""    var dbgSePeak: Float = 0f // [42v1]""",
r"""    var dbgSePeak: Float = 0f // [42v1]
    @Volatile
    var dbgConvPeak: Float = 0f // [42v2]""", "卷积峰值字段")

rep2(r"""                        frameSamples[ch] = runChain(ch, s)""",
r"""                        val cs = if (onetapEnabled) convSample(ch, s) else s // [42v2]
                        frameSamples[ch] = runChain(ch, cs)""", "链首卷积调用")

rep1(r"""            dbgSePeak = 0f // [42v1]""",
r"""            dbgSePeak = 0f // [42v1]
            dbgConvPeak = 0f // [42v2]""", "卷积峰值复位")

rep1(r"""                appliedOnetap = onetapEnabled""",
r"""                appliedOnetap = onetapEnabled
                convReset() // [42v2] 一键开关变了：清卷积缓冲（防旧声残留混入）""", "一键切换清卷积")

rep1(r"""        limiterGain = 1f
    }""",
r"""        convReset() // [42v2]
        limiterGain = 1f
    }""", "复位清卷积")

rep1(r"""                StagePeak("PEQ", dspEnabled, dbgPeqPeak),""",
r"""                StagePeak("卷积空间", onetapEnabled, dbgConvPeak), // [42v2]
                StagePeak("PEQ", dspEnabled, dbgPeqPeak),""", "卷积状态行")

rep1(r"""        updateLoudnessCoefficients()
    }""",
r"""        // [42v2] 卷积器 IR（采样率变化时重算；1.0 秒合成 IR，分区频谱）
        if (sr > 0 && sr.toInt() != convSr) {
            convGenerateIr(sr)
            convSr = sr.toInt()
        }
        updateLoudnessCoefficients()
    }""", "卷积 IR 重算")

rep1(r"""        frameSamples[0] = (bsHi[0] + bsLo[1]) * bsGain
        frameSamples[1] = (bsHi[1] + bsLo[0]) * bsGain
    }""",
r"""        frameSamples[0] = (bsHi[0] + bsLo[1]) * bsGain
        frameSamples[1] = (bsHi[1] + bsLo[0]) * bsGain
    }

    // [42v2] 卷积一采样：干声直通 + 湿声（延迟一区，约 5.8ms 预延迟）x0.5；IR 未就绪时直通
    private fun convSample(ch: Int, s: Float): Float {
        if (convIrRe.isEmpty()) return s
        convInBlock[ch][convInPos[ch]] = s
        convInPos[ch]++
        val w = convOutRing[ch][convRd[ch]]
        convOutRing[ch][convRd[ch]] = 0f
        convRd[ch] = (convRd[ch] + 1) % convRingSize
        val aw = abs(w)
        if (aw > dbgConvPeak) dbgConvPeak = aw
        if (convInPos[0] >= convN && convInPos[1] >= convN) {
            convProcessBlock()
            convInPos[0] = 0
            convInPos[1] = 0
        }
        return s + w * convWet
    }

    // [42v2] 卷积一区：输入区 FFT -> 历史谱环 -> 各分区谱乘累加 -> 逆 FFT -> 交叠相加（前半出环、后半存尾）
    private fun convProcessBlock() {
        if (convIrRe.isEmpty()) return
        val pCount = convIrRe[0].size
        for (ch in 0 until 2) {
            for (i in 0 until convN) {
                convTmpRe[i] = convInBlock[ch][i]
                convTmpIm[i] = 0f
            }
            for (i in convN until convFftN) {
                convTmpRe[i] = 0f
                convTmpIm[i] = 0f
            }
            convFft.forward(convTmpRe, convTmpIm)
            val wIdx = convBlock % pCount
            for (i in 0 until convFftN) {
                convHistRe[ch][wIdx][i] = convTmpRe[i]
                convHistIm[ch][wIdx][i] = convTmpIm[i]
            }
            for (i in 0 until convFftN) {
                convAccRe[i] = 0f
                convAccIm[i] = 0f
            }
            for (p in 0 until pCount) {
                var idx = wIdx - p
                if (idx < 0) idx += pCount
                val hr = convHistRe[ch][idx]
                val hi = convHistIm[ch][idx]
                val ir = convIrRe[ch][p]
                val ii = convIrIm[ch][p]
                for (i in 0 until convFftN) {
                    convAccRe[i] += hr[i] * ir[i] - hi[i] * ii[i]
                    convAccIm[i] += hr[i] * ii[i] + hi[i] * ir[i]
                }
            }
            convFft.inverse(convAccRe, convAccIm)
            for (i in 0 until convN) {
                convOutRing[ch][(convWr + i) % convRingSize] = convAccRe[i] + convTail[ch][i]
            }
            for (i in 0 until convN) {
                convTail[ch][i] = convAccRe[convN + i]
            }
        }
        convWr = (convWr + convN) % convRingSize
        convBlock++
    }

    // [42v2] 合成 IR：直达 0（干声另走直通）+ 早期反射 4 抽头 + 1.0 秒指数衰减噪声尾（能量归一到 1，采样率无关响度）；分段 FFT 存谱
    private fun convGenerateIr(sr: Double) {
        val len = sr.toInt().coerceAtLeast(4410)
        val pCount = (len + convN - 1) / convN
        convIrRe = Array(2) { Array(pCount) { FloatArray(convFftN) } }
        convIrIm = Array(2) { Array(pCount) { FloatArray(convFftN) } }
        convHistRe = Array(2) { Array(pCount) { FloatArray(convFftN) } }
        convHistIm = Array(2) { Array(pCount) { FloatArray(convFftN) } }
        convInBlock = Array(2) { FloatArray(convN) }
        convTail = Array(2) { FloatArray(convN) }
        convOutRing = Array(2) { FloatArray(convRingSize) }
        val early = arrayOf(0.005 to 0.3f, 0.011 to 0.2f, 0.019 to 0.15f, 0.029 to 0.1f)
        for (ch in 0 until 2) {
            val ir = FloatArray(len)
            var seed = 0x12345678L + ch * 0x9E3779B9L
            for (i in 1 until len) {
                seed = seed * 6364136223846793005L + 1442695040888963407L
                val noise = ((seed ushr 33) and 0xFFFFFFL).toFloat() / 16777216f * 2f - 1f
                val t = i / sr
                ir[i] = noise * (0.3f * 10.0.pow(-3.0 * t).toFloat())
            }
            var energy = 0.0
            for (i in 1 until len) {
                val v = ir[i].toDouble()
                energy += v * v
            }
            val scale = if (energy > 0.0) (1.0 / sqrt(energy)).toFloat() else 1f
            for (i in 1 until len) {
                ir[i] *= scale
            }
            for ((t, g) in early) {
                val pos = ((t * sr).toInt() + ch * (0.0003 * sr).toInt()).coerceIn(1, len - 1)
                ir[pos] += g
            }
            for (p in 0 until pCount) {
                for (i in 0 until convFftN) {
                    val src = p * convN + i
                    convTmpRe[i] = if (i < convN && src < len) ir[src] else 0f
                    convTmpIm[i] = 0f
                }
                convFft.forward(convTmpRe, convTmpIm)
                for (i in 0 until convFftN) {
                    convIrRe[ch][p][i] = convTmpRe[i]
                    convIrIm[ch][p][i] = convTmpIm[i]
                }
            }
        }
        convReset()
    }

    // [42v2] 清卷积音频缓冲（IR 频谱不动；采样率未变时重算系数也不丢 IR）
    private fun convReset() {
        for (ch in 0 until 2) {
            if (ch < convInBlock.size) convInBlock[ch].fill(0f)
            if (ch < convTail.size) convTail[ch].fill(0f)
            if (ch < convOutRing.size) convOutRing[ch].fill(0f)
            if (ch < convHistRe.size) {
                for (p in convHistRe[ch].indices) {
                    convHistRe[ch][p].fill(0f)
                    convHistIm[ch][p].fill(0f)
                }
            }
        }
        convInPos.fill(0)
        for (ch in 0 until 2) {
            convRd[ch] = convRingSize - convN
        }
        convWr = 0
        convBlock = 0
    }

    // [42v2] 基 2 迭代 FFT（分区卷积用，定长 512；正变换不缩放，逆变换除以 N）
    private class Fft(private val n: Int) {
        private val rev = IntArray(n)
        init {
            var j = 0
            for (i in 1 until n) {
                var bit = n shr 1
                while (j and bit != 0) {
                    j = j xor bit
                    bit = bit shr 1
                }
                j = j xor bit
                rev[i] = j
            }
        }
        fun forward(re: FloatArray, im: FloatArray) {
            transform(re, im, false)
        }
        fun inverse(re: FloatArray, im: FloatArray) {
            transform(re, im, true)
        }
        private fun transform(re: FloatArray, im: FloatArray, inverse: Boolean) {
            for (i in 0 until n) {
                val j = rev[i]
                if (j > i) {
                    val tr = re[i]
                    re[i] = re[j]
                    re[j] = tr
                    val ti = im[i]
                    im[i] = im[j]
                    im[j] = ti
                }
            }
            var len = 2
            while (len <= n) {
                val ang = 2.0 * PI / len * (if (inverse) 1.0 else -1.0)
                val wr = cos(ang)
                val wi = sin(ang)
                var i = 0
                while (i < n) {
                    var wRe = 1.0
                    var wIm = 0.0
                    for (k in 0 until len / 2) {
                        val uRe = re[i + k].toDouble()
                        val uIm = im[i + k].toDouble()
                        val vRe = re[i + k + len / 2].toDouble() * wRe - im[i + k + len / 2].toDouble() * wIm
                        val vIm = re[i + k + len / 2].toDouble() * wIm + im[i + k + len / 2].toDouble() * wRe
                        re[i + k] = (uRe + vRe).toFloat()
                        im[i + k] = (uIm + vIm).toFloat()
                        re[i + k + len / 2] = (uRe - vRe).toFloat()
                        im[i + k + len / 2] = (uIm - vIm).toFloat()
                        val nWRe = wRe * wr - wIm * wi
                        val nWIm = wRe * wi + wIm * wr
                        wRe = nWRe
                        wIm = nWIm
                    }
                    i += len
                }
                len *= 2
            }
            if (inverse) {
                for (i in 0 until n) {
                    re[i] /= n.toFloat()
                    im[i] /= n.toFloat()
                }
            }
        }
    }""", "卷积函数组")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v2 引擎已写")
PYEOF42V2ENG
echo "=== 42 v2 引擎完成 ==="

python3 << 'PYEOF42V2PAGE'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v2]" in s:
    print("跳过（42 v2 页面已应用）"); sys.exit(0)
old = r"""                                    "调好的组合一键开/关：低频增强 + 动态低音 + 高频扩展 + 环绕 + 混响；关就是原声","""
assert s.count(old) == 1, "一键卡片文案"
new = r"""                                    "调好的组合一键开/关：卷积空间 + 低频增强 + 动态低音 + 高频扩展 + 环绕 + 混响；关就是原声", // [42v2]"""
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 42 v2 页面已写")
PYEOF42V2PAGE
echo "=== 42 v2 页面完成 ==="

# === 42 v3: 卷积开销自适应（修超时闩锁：开销随采样率平方涨） ===
python3 << 'PYEOF42V3ENG'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v3]" in s:
    print("跳过（42 v3 引擎已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""    // [42v2] 卷积空间（分区卷积，分区 256，FFT 512；湿声延迟一区作预延迟，干声直通；仅一键开）
    private val convN = 256
    private val convFftN = 512
    private val convRingSize = 1024
    private val convWet = 0.5f
    private val convFft = Fft(512)""",
r"""    // [42v3] 卷积开销自适应：分区 N 跟采样率走（≤48k 用 256，>48k 用 1024），IR 封顶 65536 采样；FFT 改 float
    private var convN = 256
    private var convFftN = 512
    private var convRingSize = 1024
    private val convWet = 0.5f
    private var convFft = Fft(512)""", "卷积字段改自适应")

rep1(r"""    private fun convGenerateIr(sr: Double) {
        val len = sr.toInt().coerceAtLeast(4410)
        val pCount = (len + convN - 1) / convN""",
r"""    private fun convGenerateIr(sr: Double) {
        convN = if (sr <= 48000.0) 256 else 1024 // [42v3] 分区跟采样率走：96k 下 1024 分区，MAC 量压回 44.1k 水平
        convFftN = convN * 2
        convFft = Fft(convFftN)
        convRingSize = convN * 4
        val len = minOf(sr.toInt(), 65536).coerceAtLeast(4410) // [42v3] IR 封顶 65536 采样（96k 下约 0.68 秒）
        val pCount = (len + convN - 1) / convN
        convTmpRe = FloatArray(convFftN)
        convTmpIm = FloatArray(convFftN)
        convAccRe = FloatArray(convFftN)
        convAccIm = FloatArray(convFftN)""", "自适应分区与封顶")

rep1(r"""            var seed = 0x12345678L + ch * 0x9E3779B9L
            for (i in 1 until len) {
                seed = seed * 6364136223846793005L + 1442695040888963407L
                val noise = ((seed ushr 33) and 0xFFFFFFL).toFloat() / 16777216f * 2f - 1f
                val t = i / sr
                ir[i] = noise * (0.3f * 10.0.pow(-3.0 * t).toFloat())
            }""",
r"""            var seed = 0x12345678L + ch * 0x9E3779B9L
            val decayStep = 10.0.pow(-3.0 / sr)
            var decay = 0.3 * decayStep // [42v3] 迭代衰减（等价 0.3 x 10^(-3t)，免每采样 pow）
            for (i in 1 until len) {
                seed = seed * 6364136223846793005L + 1442695040888963407L
                val noise = ((seed ushr 33) and 0xFFFFFFL).toFloat() / 16777216f * 2f - 1f
                ir[i] = (noise * decay).toFloat()
                decay *= decayStep
            }""", "迭代衰减")

rep1(r"""                val ang = 2.0 * PI / len * (if (inverse) 1.0 else -1.0)
                val wr = cos(ang)
                val wi = sin(ang)""",
r"""                val ang = 2.0 * PI / len * (if (inverse) 1.0 else -1.0)
                val wr = cos(ang).toFloat() // [42v3] FFT 改 float 运算（精度够音频用，开销降）
                val wi = sin(ang).toFloat()""", "FFT float 系数")

rep1(r"""                    var wRe = 1.0
                    var wIm = 0.0""",
r"""                    var wRe = 1f
                    var wIm = 0f""", "FFT float 旋转因子")

rep1(r"""                        val uRe = re[i + k].toDouble()
                        val uIm = im[i + k].toDouble()
                        val vRe = re[i + k + len / 2].toDouble() * wRe - im[i + k + len / 2].toDouble() * wIm
                        val vIm = re[i + k + len / 2].toDouble() * wIm + im[i + k + len / 2].toDouble() * wRe
                        re[i + k] = (uRe + vRe).toFloat()
                        im[i + k] = (uIm + vIm).toFloat()
                        re[i + k + len / 2] = (uRe - vRe).toFloat()
                        im[i + k + len / 2] = (uIm - vIm).toFloat()""",
r"""                        val uRe = re[i + k]
                        val uIm = im[i + k]
                        val vRe = re[i + k + len / 2] * wRe - im[i + k + len / 2] * wIm
                        val vIm = re[i + k + len / 2] * wIm + im[i + k + len / 2] * wRe
                        re[i + k] = uRe + vRe
                        im[i + k] = uIm + vIm
                        re[i + k + len / 2] = uRe - vRe
                        im[i + k + len / 2] = uIm - vIm""", "FFT float 蝶形")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v3 引擎已写")
PYEOF42V3ENG
echo "=== 42 v3 引擎完成 ==="

# === 42 v4: 清晰度包（按案例：双混响去一 + 湿声 0.30 + 尾巴双频段阻尼） ===
python3 << 'PYEOF42V4ENG'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v4]" in s:
    print("跳过（42 v4 引擎已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""    private val convWet = 0.5f""",
r"""    private val convWet = 0.30f // [42v4] 湿声按案例人声/通用档 20-30% 取上限（原 0.5 属主导混响档）""", "湿声 0.30")

rep1(r"""            var seed = 0x12345678L + ch * 0x9E3779B9L
            val decayStep = 10.0.pow(-3.0 / sr)
            var decay = 0.3 * decayStep // [42v3] 迭代衰减（等价 0.3 x 10^(-3t)，免每采样 pow）
            for (i in 1 until len) {
                seed = seed * 6364136223846793005L + 1442695040888963407L
                val noise = ((seed ushr 33) and 0xFFFFFFL).toFloat() / 16777216f * 2f - 1f
                ir[i] = (noise * decay).toFloat()
                decay *= decayStep
            }""",
r"""            var seed = 0x12345678L + ch * 0x9E3779B9L
            val decayStepSlow = 10.0.pow(-3.0 / sr) // [42v4] 双频段阻尼：低频段 -60dB/1 秒，高频段 -60dB/0.5 秒（HF damping，越往后高频越少）
            val decayStepFast = 10.0.pow(-6.0 / sr)
            var decaySlow = 0.3 * decayStepSlow
            var decayFast = 0.3 * decayStepFast
            var lp = 0.0
            val lpAlpha = 1.0 - exp(-2.0 * PI * 3000.0 / sr)
            for (i in 1 until len) {
                seed = seed * 6364136223846793005L + 1442695040888963407L
                val noise = ((seed ushr 33) and 0xFFFFFFL).toFloat() / 16777216f * 2f - 1f
                lp += lpAlpha * (noise.toDouble() - lp)
                val low = lp
                val high = noise.toDouble() - lp
                ir[i] = (low * decaySlow + high * decayFast).toFloat()
                decaySlow *= decayStepSlow
                decayFast *= decayStepFast
            }""", "双频段阻尼尾")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v4 引擎已写")
PYEOF42V4ENG
echo "=== 42 v4 引擎完成 ==="

python3 << 'PYEOF42V4PAGE'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v4]" in s:
    print("跳过（42 v4 页面已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""                                        rev = true
                                        deess = false
                                        ta = false
                                        punch = true""",
r"""                                        rev = false // [42v4] 一键开时关 Freeverb（卷积已供空间，双混响糊）
                                        deess = false
                                        ta = false
                                        punch = true""", "一键关 Freeverb")

rep1(r"""                                    "调好的组合一键开/关：卷积空间 + 低频增强 + 动态低音 + 高频扩展 + 环绕 + 混响；关就是原声", // [42v2]""",
r"""                                    "调好的组合一键开/关：卷积空间 + 低频增强 + 动态低音 + 高频扩展 + 环绕；关就是原声", // [42v2][42v4]""", "一键卡片文案去混响（保留 [42v2]：此行是页文件唯一的 v2 标记，删掉会导致 v2 页块重跑时守卫失效）")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v4 页面已写")
PYEOF42V4PAGE
echo "=== 42 v4 页面完成 ==="

grep -q 'onetapEnabled' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 42 v1 引擎写入失败"; exit 1; }
grep -q '一键音效' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt || { echo "X 42 v1 页面写入失败"; exit 1; }
grep -q 'onetapEnabled' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt || { echo "X 42 v1 下发写入失败"; exit 1; }
echo "OK 42 v1 一键音效已写入"
echo "=== 42 v1 完成 ==="

grep -q 'convSample' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 42 v2 卷积写入失败"; exit 1; }
grep -q '卷积空间' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt || { echo "X 42 v2 文案写入失败"; exit 1; }
echo "OK 42 v2 卷积空间已写入"
echo "=== 42 v2 完成 ==="

grep -q '42v3' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 42 v3 自适应写入失败"; exit 1; }
echo "OK 42 v3 卷积自适应已写入"
echo "=== 42 v3 完成 ==="

# === 42 v5: 一键改手机专用（目标：手机上比原声稍好即过，不堆加工） ===
python3 << 'PYEOF42V5ENG'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v5]" in s:
    print("跳过（42 v5 引擎已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)
def repAll(old, new, name, n):
    global s
    assert s.count(old) == n, name
    s = s.replace(old, new)

rep1(r"""    // [42v1] 一键音效总开关（页面一键卡片 + 21 下发）；开 = 三个新级 + BS2B 分支，关 = 全停""",
r"""    // [42v1] 一键音效总开关（页面一键卡片 + 21 下发）；[42v5] 手机专用：开 = 卷积 + 高频扩展，一键低频/动态低音走 onetapBassEnabled（默认关），BS2B 需 cross 开关""", "总开关注释")

rep1(r"""    var onetapEnabled: Boolean = false""",
r"""    var onetapEnabled: Boolean = false
    var onetapBassEnabled: Boolean = false // [42v5] 一键低频/动态低音门（手机专用一键默认关；代码保留，以后力量不够再开，不删）""", "一键低频门字段")

rep1(r"""    private val convWet = 0.30f // [42v4] 湿声按案例人声/通用档 20-30% 取上限（原 0.5 属主导混响档）""",
r"""    private val convWet = 0.20f // [42v5] 手机专用：湿声按案例微妙档 10-30% 取中（原 0.30 仍偏明显；目标稍好于原声，不抢戏）""", "湿声 0.20")

repAll(r"""                    if (onetapEnabled) dynBassFrame() // [42v1]""",
r"""                    if (onetapEnabled && onetapBassEnabled) dynBassFrame() // [42v5]""", "动态低音门控", 2)

repAll(r"""                    if (onetapEnabled) viperBassFrame() // [42v1]""",
r"""                    if (onetapEnabled && onetapBassEnabled) viperBassFrame() // [42v5]""", "一键低频门控", 2)

rep1(r"""                StagePeak("动态低音", onetapEnabled, dbgDbPeak), // [42v1]""",
r"""                StagePeak("动态低音", onetapEnabled && onetapBassEnabled, dbgDbPeak), // [42v5]""", "动态低音状态行门控")

rep1(r"""                StagePeak("一键低频", onetapEnabled, dbgVbPeak), // [42v1]""",
r"""                StagePeak("一键低频", onetapEnabled && onetapBassEnabled, dbgVbPeak), // [42v5]""", "一键低频状态行门控")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v5 引擎已写")
PYEOF42V5ENG
echo "=== 42 v5 引擎完成 ==="

python3 << 'PYEOF42V5PAGE'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v5]" in s:
    print("跳过（42 v5 页面已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""                                    "一键音效",""",
r"""                                    "一键音效（手机）", // [42v5]""", "卡片标题手机专用")

rep1(r"""                                    "调好的组合一键开/关：卷积空间 + 低频增强 + 动态低音 + 高频扩展 + 环绕；关就是原声", // [42v2][42v4]""",
r"""                                    "手机专用一键开/关：卷积空间 + 高频扩展 + 默认档低频（Sub/低频起振/低频处理）；关就是原声", // [42v2][42v5]""", "卡片文案手机专用（保留 [42v2]：此行仍是页文件唯一的 v2 标记）")

rep1(r"""                                        sub = true
                                        cross = true
                                        exc = false""",
r"""                                        sub = true
                                        cross = false // [42v5] 手机专用：手机扬声器自带声学串馈，不用 BS2B 环绕
                                        exc = false""", "一键关环绕")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v5 页面已写")
PYEOF42V5PAGE
echo "=== 42 v5 页面完成 ==="

grep -q '42v4' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 42 v4 清晰度写入失败"; exit 1; }
grep -q '42v4' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt || { echo "X 42 v4 文案写入失败"; exit 1; }
echo "OK 42 v4 清晰度包已写入"
echo "=== 42 v4 完成 ==="

grep -q '42v5' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 42 v5 手机专用写入失败"; exit 1; }
grep -q '42v5' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt || { echo "X 42 v5 文案写入失败"; exit 1; }
echo "OK 42 v5 手机专用包已写入"
echo "=== 42 v5 完成 ==="

# === 42 v6: 推条（临时调校滑块：湿声/高频扩展量活量 + 下发，调好锁定后删掉） ===
python3 << 'PYEOF42V6ENG'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v6]" in s:
    print("跳过（42 v6 引擎已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""    private val convWet = 0.20f // [42v5] 手机专用：湿声按案例微妙档 10-30% 取中（原 0.30 仍偏明显；目标稍好于原声，不抢戏）""",
r"""    var convWet = 0.20f // [42v5][42v6] 推条版：湿声改活量（推条拨动即时生效；起点仍 0.20，锁定版再写死；保留 [42v5]，不删旧标记）""", "湿声活量")

rep1(r"""    private fun specExtFrame() {""",
r"""    var specExtAmount: Float = 1.0f // [42v6] 推条：高频扩展量活量（起点 1.0，锁定版再写死）

    private fun specExtFrame() {""", "高频扩展量字段")

rep1(r"""            frameSamples[ch] = y + lp""",
r"""            frameSamples[ch] = y + lp * specExtAmount // [42v6]""", "高频扩展量混音")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v6 引擎已写")
PYEOF42V6ENG
echo "=== 42 v6 引擎完成 ==="

python3 << 'PYEOF42V6MGR'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v6]" in s:
    print("跳过（42 v6 下发已应用）"); sys.exit(0)
old = '            eqDspProcessor.onetapEnabled = try { p?.getBoolean("onetap", false) ?: false } catch (_: Exception) { false } // [42v1] 一键音效开关下发'
assert s.count(old) == 1, "一键下发锚点"
new = old + '\n            eqDspProcessor.convWet = try { p?.getFloat("convwet", 0.20f) ?: 0.20f } catch (_: Exception) { 0.20f } // [42v6] 推条：湿声下发'
new = new + '\n            eqDspProcessor.specExtAmount = try { p?.getFloat("specext", 1.0f) ?: 1.0f } catch (_: Exception) { 1.0f } // [42v6] 推条：高频扩展量下发'
s = s.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(s)
print("OK 42 v6 下发已加")
PYEOF42V6MGR
echo "=== 42 v6 下发完成 ==="

python3 << 'PYEOF42V6PAGE'
import sys, os
P = "avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt"
while not os.path.exists(P) and os.getcwd() != "/":
    os.chdir("..")
s = open(P, encoding="utf-8").read()
if "[42v6]" in s:
    print("跳过（42 v6 页面已应用）"); sys.exit(0)
def rep1(old, new, name):
    global s
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)

rep1(r"""    // [42v1] 一键音效开关（默认关；开=固定组合，关=原声）
    var onetap by remember {
        mutableStateOf(
            try {
                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).getBoolean("onetap", false)
            } catch (_: Exception) {
                false
            }
        )
    }""",
r"""    // [42v1] 一键音效开关（默认关；开=固定组合，关=原声）
    var onetap by remember {
        mutableStateOf(
            try {
                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).getBoolean("onetap", false)
            } catch (_: Exception) {
                false
            }
        )
    }

    // [42v6] 推条状态（临时调校，锁定后删掉）
    var convWetSlider by remember {
        mutableStateOf(
            try {
                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).getFloat("convwet", 0.20f)
            } catch (_: Exception) {
                0.20f
            }
        )
    }
    var specExtSlider by remember {
        mutableStateOf(
            try {
                context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).getFloat("specext", 1.0f)
            } catch (_: Exception) {
                1.0f
            }
        )
    }""", "推条状态")

rep1(r"""                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.large,
                        colors = CardDefaults.cardColors(containerColor = musicColors().card)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "极致音质（DSP 引擎）",""",
r"""                    Card( // [42v6] 推条：临时调校滑块区（调好锁定后删掉，成品不留）
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.large,
                        colors = CardDefaults.cardColors(containerColor = musicColors().card)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                "推条（临时调校，调好发数值锁定后删掉；仅一键开时生效）", // [42v6]
                                style = MaterialTheme.typography.bodySmall,
                                color = musicColors().textSecondary
                            )
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    "卷积湿声",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().textPrimary,
                                    modifier = Modifier.weight(1f)
                                )
                                Text(
                                    String.format("%.2f", convWetSlider),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().accent
                                )
                            }
                            Slider(
                                value = convWetSlider,
                                onValueChange = { v ->
                                    convWetSlider = v
                                    try { context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).edit().putFloat("convwet", v).commit() } catch (_: Exception) { }
                                    try { LxPlayerManager.applyEqFromPrefs() } catch (_: Exception) { }
                                },
                                valueRange = 0f..0.5f,
                                colors = SliderDefaults.colors(
                                    thumbColor = musicColors().accent,
                                    activeTrackColor = musicColors().accent,
                                    inactiveTrackColor = musicColors().cardSecondary
                                )
                            )
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    "高频扩展量",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().textPrimary,
                                    modifier = Modifier.weight(1f)
                                )
                                Text(
                                    String.format("%.2f", specExtSlider),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = musicColors().accent
                                )
                            }
                            Slider(
                                value = specExtSlider,
                                onValueChange = { v ->
                                    specExtSlider = v
                                    try { context.getSharedPreferences("eq_settings", Context.MODE_PRIVATE).edit().putFloat("specext", v).commit() } catch (_: Exception) { }
                                    try { LxPlayerManager.applyEqFromPrefs() } catch (_: Exception) { }
                                },
                                valueRange = 0f..2f,
                                colors = SliderDefaults.colors(
                                    thumbColor = musicColors().accent,
                                    activeTrackColor = musicColors().accent,
                                    inactiveTrackColor = musicColors().cardSecondary
                                )
                            )
                        }
                    }
                Spacer(Modifier.height(16.dp))
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.large,
                        colors = CardDefaults.cardColors(containerColor = musicColors().card)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "极致音质（DSP 引擎）",""", "推条卡片")

open(P, "w", encoding="utf-8").write(s)
print("OK 42 v6 页面已写")
PYEOF42V6PAGE
echo "=== 42 v6 页面完成 ==="

grep -q '42v6' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/EqDspProcessor.kt || { echo "X 42 v6 引擎写入失败"; exit 1; }
grep -q '42v6' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxPlayerManager.kt || { echo "X 42 v6 下发写入失败"; exit 1; }
grep -q '42v6' avbox/app/src/main/java/com/github/tvbox/osc/ui/activity/LxEqSettingsActivity.kt || { echo "X 42 v6 页面写入失败"; exit 1; }
echo "OK 42 v6 推条已写入"
echo "=== 42 v6 完成 ==="
