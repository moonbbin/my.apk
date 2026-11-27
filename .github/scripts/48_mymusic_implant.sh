#!/bin/bash
# [48v1] myMusic 植入：把 mytv-android/myMusic（HEAD 1c14ca28）完整植入 moonbbin/AVBox
#
# 用法：由 .github/workflows/build.yml 在全新 clone 后调用（build.yml 调用行由用户在网页端加，
#       App 无 workflows 权限）。脚本在仓库根目录执行，内部 cd 到 avbox/ 操作。
#       构建顺序：48 与音乐专区解耦（Tab 已改锚 [48v2]，不再依赖 05），放 46 之后即可。
#
# 覆盖范围（6 大项 + G9）：
#   ① Application 合并：.base.App 继承 MyMusicApp；super.onCreate() 落点为 initParams() 之后、
#      HttpClients.init() 之前（application_merge.md §2/§3，按真实 App.kt 重写）。
#   ② Tab 入口 MYMUSIC：[48v2]（stage48/tab_entry_v2.sh 原样嵌入，两态仿真已过）。
#   ③ Manifest 合并：权限 +5、uses-feature +2、queries +8 intent、application 属性 +3、
#      lyricon meta-data +4、组件 +6（MainActivity/PlaybackService/ResumeButtonReceiver/
#      FloatingLyricsService/SubsonicCoverProvider/InitializationProvider）。
#   ④ 依赖：catalog 新增 15 个版本键 + 26 个库别名 + 1 个插件别名；app build.gradle.kts
#      新增 24 行 implementation/ksp + 1 行插件；Room 双版本共存（roomLegacy 2.8.5 + room3 3.0.3）。
#   ⑤ 资源：java 源码整树 + assets 整树 + res 选择性合并（values 合并进 mymusic_values.xml、
#      file_paths 9 条并集、app_name 改名 mymusic_app_name、启动图标改名）。
#   ⑥ 原生库：lib-runtime-lx / lib-decoder-flac 两模块原样拷进工程根目录 + settings include +
#      app implementation(project(...))；NDK/CMake/buildTools 键显式检查。
#   ⑦ G9：CI fresh clone 里 grep "playback" 字符串字面量，确认 AVBox 无 filesDir/playback 占用。
#
# 重要：本脚本按“跳过本地仿真、直接推让 CI 验”路子编写（用户 2026-11-27 12:13 授权，接受变红风险）。
#   未做全链仿真（取 AVBox HEAD 建基线被安全分类器拦掉，见 stage48/BASELINE_BLOCKED.md）。
#   每个锚点都标 [已核实] 或 [未核实]：
#     [已核实] = G1G6_VERIFY.md 有 HEAD 66b1691f 的文件/行号直接证据，或 myMusic 侧本地同提交
#                clone（HEAD 1c14ca28）直读。
#     [未核实] = 依据本地旧检出或草案，未对 HEAD 66b1691f 复核；脚本用 grep 特征字符串锚点
#                + fail-fast（未命中即 exit 1 报明），CI 红了按 STAGE48_WRITE.md 修。
#   现有音乐专区一点不动（不改 05/11/12/13/14/15/16/17 及 LxPlayerManager/LxMusicSearchApi）。
#
# 约定：set -e；UTF-8/LF；幂等可重入（重跑只跳过已完成的步骤，不报错）；
#       注入的 UI 代码遵守 UI_SPEC（禁写死颜色——本脚本不注入任何 Compose UI 代码，
#       Tab 入口只复用 [48v2] 的现有 ic_music_page 图标与 tab_home 字符串）。
#       版本标记：本脚本首版各块标 [48v1]；Tab 块保留已仿真的 [48v2] 标记不动。
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AVBOX_DIR="${REPO_ROOT}/avbox"
MYMUSIC_SRC="${REPO_ROOT}/mymusic-src"
MYMUSIC_SHA="1c14ca286acbab5be6048ddbba3bbdfa2b29e943"
MYMUSIC_TARBALL="https://github.com/mytv-android/myMusic/archive/${MYMUSIC_SHA}.tar.gz"

die() { echo "[48] ERROR: $*" >&2; exit 1; }
info() { echo "[48] $*"; }

# 断言：文件 $1 中固定字符串 $2 出现行数 == $3（grep -F -c，按行计）。不符即 exit 1 报明。
assert_count() {
  local file="$1" pattern="$2" expected="$3" label="$4"
  local n
  n="$(grep -F -c -- "$pattern" "$file" || true)"
  if [ "$n" != "$expected" ]; then
    die "锚点不符 [$label]：文件 $file 中 '$pattern' 出现 $n 行，期望 $expected 行"
  fi
}

# 断言：文件 $1 中固定字符串 $2 出现行数 >= $3。不符即 exit 1 报明。
assert_at_least() {
  local file="$1" pattern="$2" expected="$3" label="$4"
  local n
  n="$(grep -F -c -- "$pattern" "$file" || true)"
  if [ "$n" -lt "$expected" ]; then
    die "锚点不符 [$label]：文件 $file 中 '$pattern' 出现 $n 行，期望至少 $expected 行"
  fi
}

# 若文件 $1 中不存在固定字符串 $2，则把 $3 追加到文件末尾（幂等）。
append_if_absent() {
  local file="$1" pattern="$2" line="$3" label="$4"
  if grep -F -q -- "$pattern" "$file"; then
    info "已存在，跳过 [$label]"
  else
    printf '%s\n' "$line" >> "$file"
    info "已追加 [$label]"
  fi
}

# ============ 1. 取 myMusic 源码（pin HEAD 1c14ca28） ============
# 源文件策略：CI 里下载 myMusic 指定提交 tarball（精确 pin，不用 git clone 取最新 HEAD）；
# push-files 推不了二进制，故源码不在 48 脚本里 base64，改在 CI 构建时现取。
info "== 1. 取 myMusic 源码（pin ${MYMUSIC_SHA}） =="
if [ -f "${MYMUSIC_SRC}/app/src/main/java/com/mytv/mymusic/MyMusicApp.kt" ]; then
  info "myMusic 源码已存在，跳过下载：${MYMUSIC_SRC}"
else
  info "下载 tarball：${MYMUSIC_TARBALL}"
  # 注意：此处不要 mkdir -p mymusic-src——目标目录若已存在，mv 会把 myMusic-<sha> 移进它里面，
  # 变成 mymusic-src/myMusic-<sha>/，导致后续关键文件校验失败（2026-11-27 首轮 CI 红根因）。
  # 不建目录时，mv 直接把 myMusic-<sha> 重命名为 mymusic-src。
  curl -fsSL --retry 3 -o "${REPO_ROOT}/mymusic.tar.gz" "${MYMUSIC_TARBALL}" \
    || die "下载 myMusic tarball 失败：${MYMUSIC_TARBALL}（网络或该提交已被 force-push？）"
  tar -xzf "${REPO_ROOT}/mymusic.tar.gz" -C "${REPO_ROOT}" \
    || die "解压 myMusic tarball 失败"
  # GitHub archive tarball 顶层目录名为 myMusic-<sha>
  mv "${REPO_ROOT}/myMusic-${MYMUSIC_SHA}" "${MYMUSIC_SRC}" \
    || die "移动 myMusic 源码目录失败（顶层目录名与预期 myMusic-${MYMUSIC_SHA} 不符？）"
  rm -f "${REPO_ROOT}/mymusic.tar.gz"
  info "myMusic 源码已下载到 ${MYMUSIC_SRC}"
fi
# 校验关键文件在位（myMusic 侧，[已核实]：本地同提交 clone 直读）
for f in \
  "app/src/main/java/com/mytv/mymusic/MyMusicApp.kt" \
  "app/src/main/java/com/mytv/mymusic/MainActivity.kt" \
  "app/src/main/java/com/mytv/mymusic/ui/settings/AboutScreen.kt" \
  "app/src/main/AndroidManifest.xml" \
  "app/src/main/res/xml/file_paths.xml" \
  "app/src/main/res/values/strings.xml" \
  "app/src/main/res/values/colors.xml" \
  "app/src/main/res/values/themes.xml" \
  "app/src/main/res/values/lyricon.xml" \
  "app/src/main/res/values-night/colors.xml" \
  "gradle/libs.versions.toml" \
  "app/build.gradle.kts" \
  "lib-runtime-lx/build.gradle.kts" \
  "lib-decoder-flac/build.gradle.kts" \
  ; do
  [ -f "${MYMUSIC_SRC}/${f}" ] || die "myMusic 源码缺关键文件：${f}"
done
info "myMusic 源码关键文件齐全"

# ============ 2. G9：确认 AVBox 无 filesDir/playback 占用 ============
# 必须在拷源码之前跑：拷入后 avbox/ 里会有 myMusic 自己的 File(filesDir, "playback")，
# 再 grep 会自报自撞。G9 真正要查的是 AVBox 原生代码是否占用该目录。
info "== 2. G9 检查（AVBox 侧，须在拷源码前跑） =="
[ -d "${AVBOX_DIR}" ] || die "AVBox clone 不在 ${AVBOX_DIR}（build.yml 须先 clone 到 avbox/）"
cd "${AVBOX_DIR}"
# 说明：裸 grep -rn playback 会误报 AVBox 自身的 PlaybackService（类名/注释含 playback）。
# G9 真正要查的是“filesDir 下名为 playback 的目录”是否被 AVBox 占用（与 myMusic 的
# QueueStore.kt File(filesDir, "playback") 撞）。因此只查字符串字面量 "playback"。
# [未核实]：FileUtils.kt 全文无 playback（G1G6 §8.1，HEAD 直读）；其余文件未逐个核对。
if grep -rn --include='*.kt' --include='*.java' -F '"playback"' app/src/main/java/ ; then
  die "G9 命中：AVBox 已有 filesDir/playback 用途（见上方 grep 结果），与 myMusic QueueStore 冲突，须改 myMusic 侧目录名后再推"
fi
info "G9 通过：AVBox 无 filesDir/playback 占用"

# ============ 3. 拷 myMusic 源码树与 assets ============
info "== 3. 拷 myMusic 源码树与 assets =="
# 3a. java 源码整树（包名 com.mytv.mymusic，与 AVBox 的 com.github.avbox.osc 无重叠）
#     [已核实] myMusic 侧 378 文件（本地同提交 clone 直读）；AVBox 侧无 com/mytv 目录
#     （G1G6 未逐文件核对，但包名前缀不同，冲突概率极低；脚本做在位检查）。
if [ -f "app/src/main/java/com/mytv/mymusic/MyMusicApp.kt" ]; then
  info "myMusic 源码树已在位，跳过拷贝"
else
  [ -d "app/src/main/java/com/mytv" ] && die "app/src/main/java/com/mytv 已存在但非 myMusic 源码（MyMusicApp.kt 不在位），须人工确认"
  cp -r "${MYMUSIC_SRC}/app/src/main/java/com/mytv" "app/src/main/java/com/" \
    || die "拷贝 myMusic java 源码树失败"
  info "已拷贝 java 源码树"
fi
assert_count "app/src/main/java/com/mytv/mymusic/MyMusicApp.kt" "class MyMusicApp" 1 "MyMusicApp.kt 类声明"

# 3b. assets 整树（resource_conflicts.md：22 vs 22，零重叠——[未核实]，AVBox 侧以本地旧检出为准；
#     脚本做逐文件碰撞检查：内容一致视为已在位（重跑），内容不同即 exit 1）
info "检查 assets 碰撞…"
collision=""
while IFS= read -r -d '' f; do
  rel="${f#${MYMUSIC_SRC}/app/src/main/assets/}"
  if [ -e "app/src/main/assets/${rel}" ]; then
    if ! cmp -s "$f" "app/src/main/assets/${rel}"; then
      collision="${collision} ${rel}"
    fi
  fi
done < <(find "${MYMUSIC_SRC}/app/src/main/assets" -type f -print0)
if [ -n "${collision}" ]; then
  die "assets 文件名碰撞（AVBox 已有同名但内容不同的文件）：${collision}"
fi
cp -r "${MYMUSIC_SRC}/app/src/main/assets/." "app/src/main/assets/" \
  || die "拷贝 myMusic assets 失败"
info "已拷贝 assets（零碰撞）"

# 3c. R 别名：植入后 R 类随 app 模块生成（包名 = AVBox 的 namespace），myMusic 源码里的
#     裸 R 与 `import com.mytv.mymusic.R` 都靠这个别名解析。
#     （2026-11-27 第五轮 CI 红根因之一：44 个编译错里大半是 Unresolved reference 'R'——
#     myMusic 源码在 com.mytv.mymusic.* 包里，裸 R 解析不到 app 模块的 R 类。资源已在
#     第 8 节并进 app 的 res/，故 app 的 R 类含 myMusic 全部资源，别名即可解析。）
NS="$(sed -n 's/^[[:space:]]*namespace[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' app/build.gradle.kts | head -n 1)"
[ -n "$NS" ] || die "app/build.gradle.kts 无 namespace，无法生成 R 别名"
RKT="app/src/main/java/com/mytv/mymusic/R.kt"
cat > "${RKT}" <<EOF
package com.mytv.mymusic

// [48v1] myMusic 植入：R 类随 app 模块生成（包名 ${NS}），myMusic 源码里的裸 R 与
// import com.mytv.mymusic.R 都靠这个别名解析。资源已在第 8 节并进 app 的 res/，故 ${NS}.R
// 含 myMusic 全部资源。
typealias R = ${NS}.R
EOF
grep -F -q "typealias R = ${NS}.R" "${RKT}" || die "R 别名文件写入失败"
info "R 别名已写：${RKT} -> ${NS}.R"

# ============ 4. Application 合并 ============
info "== 4. Application 合并 =="
# 4a. MyMusicApp 加 open（myMusic 侧，[已核实]：本地同提交 clone 直读 MyMusicApp.kt:50，
#     类声明为 class MyMusicApp : Application()，上方有 @OptIn(UnstableApi::class)）
MYAPP="app/src/main/java/com/mytv/mymusic/MyMusicApp.kt"
if grep -F -q "open class MyMusicApp : Application()" "${MYAPP}"; then
  info "MyMusicApp 已是 open，跳过"
else
  assert_count "${MYAPP}" "class MyMusicApp : Application()" 1 "MyMusicApp 类声明"
  python3 - "${MYAPP}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = "class MyMusicApp : Application()"
new = "open class MyMusicApp : Application()"
assert s.count(old) == 1, "MyMusicApp 类声明出现次数 != 1"
s = s.replace(old, new)
open(path, "w", encoding="utf-8").write(s)
print("[48] MyMusicApp 已加 open")
PYEOF
fi

# 4b. .base.App 继承 MyMusicApp（AVBox 侧，[已核实]：G1G6 §2，HEAD App.kt 类声明
#     class App : Application()；包名 com.github.avbox.osc，文件在 base/App.kt）
APPKT="app/src/main/java/com/github/avbox/osc/base/App.kt"
[ -f "${APPKT}" ] || die "App.kt 不在 ${APPKT}（包名已改？G1G6 称 HEAD 包名为 com.github.avbox.osc）"
if grep -F -q "class App : MyMusicApp()" "${APPKT}"; then
  info ".base.App 已继承 MyMusicApp，跳过类声明改动"
else
  assert_count "${APPKT}" "class App : Application()" 1 "App 类声明"
  python3 - "${APPKT}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old_decl = "class App : Application()"
new_decl = "class App : MyMusicApp()"
assert s.count(old_decl) == 1, "App 类声明出现次数 != 1"
s = s.replace(old_decl, new_decl)
if "import android.app.Application" in s:
    assert s.count("import android.app.Application") == 1, "import android.app.Application 出现次数 != 1"
    s = s.replace("import android.app.Application", "import com.mytv.mymusic.MyMusicApp")
    print("[48] App.kt：import android.app.Application 已换成 MyMusicApp")
else:
    lines = s.split("\n")
    pkg_idx = [i for i, ln in enumerate(lines) if ln.startswith("package ")]
    assert len(pkg_idx) == 1, "package 行不是唯一"
    lines.insert(pkg_idx[0] + 1, "import com.mytv.mymusic.MyMusicApp")
    s = "\n".join(lines)
    print("[48] App.kt：已在 package 行后插入 import MyMusicApp")
open(path, "w", encoding="utf-8").write(s)
print("[48] .base.App 已继承 MyMusicApp")
PYEOF
fi

# 4c. super.onCreate() 落点：从 onCreate 开头移到 initParams() 之后、HttpClients.init() 之前
#     [已核实]：G1G6 §2.2，HEAD App.kt onCreate：super.onCreate() 在首行，
#     initParams() 在 BootGuard.install() 之后、Probe.trace("boot:httpClients") 之前。
#     边缘风险（G1G6）：BootGuard 是 jar 源启动看门狗，com.mytv.mymusic.* 不在其忽略前缀里；
#     myMusic 崩溃会被判源相关而写 marker，jar 加载期累计 3 次可能误禁用该 jar 源。
#     列入首启验收检查项（见 STAGE48_WRITE.md），不是本脚本的否决项。
if grep -F -q 'super.onCreate()  // [48v1]' "${APPKT}"; then
  info "super.onCreate() 已移到 initParams() 之后，跳过"
else
  assert_count "${APPKT}" "super.onCreate()" 1 "App.kt super.onCreate()"
  assert_count "${APPKT}" 'bootMark("initParams")' 1 "App.kt bootMark initParams"
  python3 - "${APPKT}" <<'PYEOF'
import sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
idx_super = [i for i, ln in enumerate(lines) if "super.onCreate()" in ln]
assert len(idx_super) == 1, "super.onCreate() 行数 != 1"
del lines[idx_super[0]]
idx_init = [i for i, ln in enumerate(lines) if 'bootMark("initParams")' in ln]
assert len(idx_init) == 1, 'bootMark("initParams") 行数 != 1'
indent = lines[idx_init[0]][:len(lines[idx_init[0]]) - len(lines[idx_init[0]].lstrip())]
insert = indent + "super.onCreate()  // [48v1] MyMusicApp.onCreate：CrashReporter -> Room -> PlaybackService 等"
lines.insert(idx_init[0] + 1, insert)
open(path, "w", encoding="utf-8").write("\n".join(lines))
print("[48] super.onCreate() 已移到 initParams() 之后")
PYEOF
fi
# 4d. 收尾断言
assert_count "${APPKT}" "class App : MyMusicApp()" 1 "App 继承 MyMusicApp"
assert_count "${APPKT}" "super.onCreate()" 1 "App.kt super.onCreate() 唯一"
assert_count "${APPKT}" "import com.mytv.mymusic.MyMusicApp" 1 "App.kt import MyMusicApp"
info "Application 合并完成"

# ============ 5. Tab 入口 MYMUSIC —— [48v2] 原样嵌入 ============
# 以下为 stage48/tab_entry_v2.sh 原样嵌入（仅去掉独立脚本的 shebang / set -e /
# SCRIPT_DIR / cd avbox——父脚本已做 set -e 且已 cd 到 avbox/；其余逻辑与注释逐字保留）。
# 两态仿真（2026-11-27）：05 跑过与没跑各首跑 exit 0 + 幂等二跑零改动 + 反向 exit 1，
# 共 4 个反向，全部通过。改锚说明见 tab_entry_v2.sh 头部注释。
info "== 5. Tab 入口 MYMUSIC [48v2] =="
MS=app/src/main/java/com/github/avbox/osc/ui/page/MainScreen.kt
SX=app/src/main/res/values/strings.xml
ICON_SRC=app/src/main/res/drawable/ic_music_page.xml
ICON_DST=app/src/main/res/drawable/ic_tab_mymusic.xml

# ---- 前置断言（HEAD 原生项，不依赖 05）----
for f in "$MS" "$SX" "$ICON_SRC"; do
    [ -f "$f" ] || { echo "[48v2] 缺失前置文件: $f" >&2; exit 1; }
done
# SETTINGS 枚举行（HEAD 原生，G1G6 §4.1 L90-95）必须唯一存在
[ "$(grep -c 'SETTINGS(R.string.tab_mine' "$MS")" = "1" ] || { echo "[48v2] MainScreen.kt 未见唯一 SETTINGS 枚举行" >&2; exit 1; }
# AppTab.SETTINGS -> 内容分支（HEAD 原生，G1G6 §4.1 L315-320）必须唯一存在
[ "$(grep -c 'AppTab.SETTINGS ->' "$MS")" = "1" ] || { echo "[48v2] MainScreen.kt 未见唯一 AppTab.SETTINGS 分支" >&2; exit 1; }
# tab_mine 字符串行（HEAD 原生，G1G6 §6 L207）必须唯一存在
[ "$(grep -c 'name="tab_mine"' "$SX")" = "1" ] || { echo "[48v2] strings.xml 未见唯一 tab_mine 行" >&2; exit 1; }

# ---- 1. MainScreen.kt：枚举 + 内容分支（python 做，避免 bash 引号问题）----
python3 - "$MS" <<'PYEOF'
import sys

ms_file = sys.argv[1]
with open(ms_file, 'r', encoding='utf-8') as f:
    lines = f.read().split('\n')

# 1a. AppTab 枚举加 MYMUSIC（插在 SETTINGS 行之后，即枚举末尾；行定位，不依赖后继项）
#     [48v2] 改锚：原 [48v1] 锚 MUSIC 行（05 产物），现锚 SETTINGS 行（HEAD 原生）
if any('MYMUSIC(R.string.tab_mymusic' in ln for ln in lines):
    print("[48v2] 枚举 MYMUSIC 已存在，跳过")
else:
    idx = [i for i, ln in enumerate(lines) if 'SETTINGS(R.string.tab_mine' in ln]
    assert len(idx) == 1, f"[48v2] SETTINGS 枚举行不是唯一：{len(idx)} 行"
    i = idx[0]
    indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
    lines.insert(i + 1, indent + 'MYMUSIC(R.string.tab_mymusic, R.drawable.ic_tab_mymusic), // [48v2]')
    print("[48v2] 枚举 MYMUSIC 已添加")

# 1b. 内容分支：点按钮起 myMusic MainActivity（无 extras；类名用全限定，
#     避开与 AVBox 自身 com.github.avbox.osc.ui.MainActivity 的 import 冲突）
#     [48v2] 改锚：原 [48v1] 锚 AppTab.MUSIC -> 分支（05 产物），现锚 AppTab.SETTINGS -> 分支（HEAD 原生）
if any('AppTab.MYMUSIC ->' in ln for ln in lines):
    print("[48v2] 内容分支 MYMUSIC 已存在，跳过")
else:
    idx = [i for i, ln in enumerate(lines) if 'AppTab.SETTINGS ->' in ln]
    assert len(idx) == 1, f"[48v2] AppTab.SETTINGS 内容分支不是唯一：{len(idx)} 行"
    i = idx[0]
    indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
    branch = (indent + 'AppTab.MYMUSIC -> { val ctx = LocalContext.current; '
              'Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { '
              'Button(onClick = { ctx.startActivity(Intent(ctx, com.mytv.mymusic.MainActivity::class.java)) }) '
              '{ Text("进入 myMusic") } } } // [48v2]')
    lines.insert(i + 1, branch)
    print("[48v2] 内容分支 MYMUSIC 已添加")

# 1c. 所需 import（05 已加过时直接跳过；缺失才补，与 modify_mainscreen.py 同款做法）
#     插在 package 行之后：MainScreen.kt:1 是 @file:OptIn(...)，插文件头会编译不过
#     （G1G6_VERIFY §4.5；05 跑过后 6 个 import 已存在，正常不触发；05 没跑时 6 个全缺，在此补齐）
missing = [imp for imp in ["import android.content.Intent",
            "import androidx.compose.ui.platform.LocalContext",
            "import androidx.compose.foundation.layout.Box",
            "import androidx.compose.ui.Alignment",
            "import androidx.compose.material3.Button",
            "import androidx.compose.material3.Text"] if imp not in '\n'.join(lines)]
if missing:
    pkg = [i for i, ln in enumerate(lines) if ln.startswith('package ')]
    assert len(pkg) == 1, f"[48v2] package 行不是唯一：{len(pkg)} 行"
    for j, imp in enumerate(missing):
        lines.insert(pkg[0] + 1 + j, imp)
        print(f"[48v2] import 已补：{imp}")
content = '\n'.join(lines)

# 1d. 括号平衡校验（大段替换后必查；只数括号，不算验过分隔符——本行无多参数调用）
pairs = [('{', '}'), ('(', ')'), ('[', ']')]
for o, c in pairs:
    assert content.count(o) == content.count(c), \
        f"[48v2] 括号失衡 {o}{c}: {content.count(o)} vs {content.count(c)}"
print(f"[48v2] 括号平衡通过：{{}}={content.count(chr(123))} ()={content.count(chr(40))} []={content.count(chr(91))}")

with open(ms_file, 'w', encoding='utf-8') as f:
    f.write(content)
print("[48v2] MainScreen.kt 修改完成")
PYEOF

# ---- 2. 字符串资源：tab_mymusic（插在 HEAD 原生的 tab_mine 行之后）----
# [48v2] 改锚：原 [48v1] 锚 05 的 tab_music 行，现锚 HEAD 原生的 tab_mine 行（G1G6 §6 L207）
if grep -q 'name="tab_mymusic"' "$SX"; then
    echo "[48v2] 字符串 tab_mymusic 已存在，跳过"
else
    sed -i 's|<string name="tab_mine">我的</string>|<string name="tab_mine">我的</string>\n    <string name="tab_mymusic">myMusic</string> <!-- [48v2] -->|' "$SX"
    grep -q 'name="tab_mymusic"' "$SX" || { echo "[48v2] tab_mymusic 写入失败" >&2; exit 1; }
    echo "[48v2] 字符串 tab_mymusic 已添加"
fi

# ---- 3. 图标：复用 05 的做法（ic_music_page.xml 复制一份改名；不新画图）----
# 注：ic_music_page.xml 是 AVBox HEAD 原生文件（G1G6 §9 已直读下载），不是 05 的产物，
#     故 05 跑过与否均可复制。myMusic 自带品牌图标 res/drawable/ic_stat_mymusic.xml
#     （屏幕框+音符）是更贴切的 Tab 图标，但它在 myMusic 源码树里，本脚本运行时源码合并
#     脚本未必已跑；先用 05 同款复制做法保构建，待源码并入脚本落地后再换品牌图标。
if [ -f "$ICON_DST" ]; then
    echo "[48v2] 图标 ic_tab_mymusic.xml 已存在，跳过"
else
    cp "$ICON_SRC" "$ICON_DST"
    echo "[48v2] 图标 ic_tab_mymusic.xml 已添加（复制自 ic_music_page.xml）"
fi

# ---- 4. 收尾断言 ----
grep -q 'MYMUSIC(R.string.tab_mymusic' "$MS"
grep -q 'AppTab.MYMUSIC ->' "$MS"
grep -q 'name="tab_mymusic"' "$SX"
[ -f "$ICON_DST" ]
echo "[48v2] myMusic Tab 入口添加完成"

# ============ 6. Manifest 合并 ============
# 依据：stage1/manifest_merge.md + manifest_merge_draft.xml（myMusic 真实清单 253 行，HEAD 1c14ca28）。
# AVBox 侧行号以本地旧检出（150 行清单）为准、未对 HEAD 66b1691f 复核——
# 故锚点一律用特征字符串 grep（全文唯一断言），不用行号。
# [已核实] 仅 android:name=".base.App"（G1G6 §2.1，HEAD Manifest L40）；
# 其余 AVBox 侧锚点（权限行、FileProvider、queries）均为 [未核实]。
info "== 6. Manifest 合并 =="
MANIFEST="app/src/main/AndroidManifest.xml"
[ -f "${MANIFEST}" ] || die "AndroidManifest.xml 不在 ${MANIFEST}"
assert_count "${MANIFEST}" 'android:name=".base.App"' 1 "Manifest android:name=.base.App [已核实]"
assert_count "${MANIFEST}" "<application" 1 "Manifest <application"
assert_count "${MANIFEST}" "</application>" 1 "Manifest </application>"

python3 - "${MANIFEST}" <<'PYEOF'
import sys, re
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
orig = s
def must_once(sub, label):
    n = s.count(sub)
    assert n == 1, f"[48v1] Manifest 锚点不符 [{label}]：'{sub}' 出现 {n} 次，期望 1 次"
    return n
def has(sub):
    return sub in s

# --- 6.0 xmlns:tools（InitializationProvider 用 tools:node，须有该命名空间）---
# [未核实]：manifest_merge.md 称 AVBox 清单已有 xmlns:tools（本地旧检出）；缺失则补。
if not has("xmlns:tools="):
    m = re.search(r"<manifest\b", s)
    assert m, "[48v1] 未找到 <manifest 标签"
    # 在 <manifest 之后插入命名空间声明
    s = s[:m.end()] + '\n    xmlns:tools="http://schemas.android.com/tools"' + s[m.end():]
    print("[48v1] 已补 xmlns:tools 命名空间")
else:
    print("[48v1] xmlns:tools 已存在，跳过")

# --- 6.1 权限 +5（插在 <application 之前；已存在则跳过）---
# [未核实]：AVBox 清单无对应项（本地旧检出）；每条按权限名去重。
perms = [
    "android.permission.WAKE_LOCK",
    "android.permission.FOREGROUND_SERVICE_DATA_SYNC",
    "android.permission.SYSTEM_ALERT_WINDOW",
    "android.permission.MODIFY_AUDIO_SETTINGS",
    "android.permission.RECORD_AUDIO",
]
app_idx = s.index("<application")
add_perms = []
for p in perms:
    if not has('android:name="%s"' % p):
        add_perms.append('    <uses-permission android:name="%s" /> <!-- [48v1] -->' % p)
    else:
        print(f"[48v1] 权限已存在，跳过：{p}")
if add_perms:
    s = s[:app_idx] + "\n".join(add_perms) + "\n" + s[app_idx:]
    print(f"[48v1] 已加权限 {len(add_perms)} 条")

# --- 6.1b WRITE_EXTERNAL_STORAGE：AVBox 已有 maxSdkVersion=32 则不动；整条缺失才补（32）---
# [未核实]：AVBox :15 有该权限 maxSdkVersion=32（本地旧检出）；myMusic 的 28 不另加（防合并冲突）。
if not has('android:name="android.permission.WRITE_EXTERNAL_STORAGE"'):
    app_idx = s.index("<application")
    line = '    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" /> <!-- [48v1] -->'
    s = s[:app_idx] + line + "\n" + s[app_idx:]
    print("[48v1] WRITE_EXTERNAL_STORAGE 缺失，已补 maxSdkVersion=32")
else:
    print("[48v1] WRITE_EXTERNAL_STORAGE 已存在，保留 AVBox 的 maxSdkVersion，不另加")

# --- 6.2 uses-feature +2（插在 <application 之前）---
# [未核实]：touchscreen 一项 AVBox 已有，不重复；leanback/microphone 新增。
features = [
    ('android.software.leanback', '    <uses-feature android:name="android.software.leanback" android:required="false" /> <!-- [48v1] -->'),
    ('android.hardware.microphone', '    <uses-feature android:name="android.hardware.microphone" android:required="false" /> <!-- [48v1] -->'),
]
app_idx = s.index("<application")
add_feat = []
for name, line in features:
    if not has('android:name="%s"' % name):
        add_feat.append(line)
    else:
        print(f"[48v1] uses-feature 已存在，跳过：{name}")
if add_feat:
    s = s[:app_idx] + "\n".join(add_feat) + "\n" + s[app_idx:]
    print(f"[48v1] 已加 uses-feature {len(add_feat)} 条")

# --- 6.3 queries +8 intent ---
# [未核实]：AVBox 现有 queries（本地旧检出 :43-54）是 1 个 VIEW/https intent + 5 个播放器包名，
# 无冲突。去重键按 action/data：VIEW+apk 与 INSTALL_PACKAGE+apk 共用 apk mimeType 键；
# SEND+json 与 CREATE_DOCUMENT+json 共用 application/json 键。
INTENTS = [
    ("android.speech.RecognitionService",
     '        <intent>\n            <action android:name="android.speech.RecognitionService" />\n        </intent>'),
    ("android.speech.action.RECOGNIZE_SPEECH",
     '        <intent>\n            <action android:name="android.speech.action.RECOGNIZE_SPEECH" />\n        </intent>'),
    ("application/vnd.android.package-archive",
     '        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:mimeType="application/vnd.android.package-archive" />\n        </intent>\n'
     '        <intent>\n            <action android:name="android.intent.action.INSTALL_PACKAGE" />\n            <data android:mimeType="application/vnd.android.package-archive" />\n        </intent>'),
    ("android.intent.action.OPEN_DOCUMENT_TREE",
     '        <intent>\n            <action android:name="android.intent.action.OPEN_DOCUMENT_TREE" />\n        </intent>'),
    ("application/json",
     '        <intent>\n            <action android:name="android.intent.action.SEND" />\n            <data android:mimeType="application/json" />\n        </intent>\n'
     '        <intent>\n            <action android:name="android.intent.action.CREATE_DOCUMENT" />\n            <data android:mimeType="application/json" />\n        </intent>'),
    ("android.intent.action.OPEN_DOCUMENT",
     '        <intent>\n            <action android:name="android.intent.action.OPEN_DOCUMENT" />\n            <data android:mimeType="*/*" />\n        </intent>'),
]
add_intents = []
for key, block in INTENTS:
    if has(key):
        print(f"[48v1] queries intent 已存在，跳过（键：{key}）")
    else:
        add_intents.append(block)
if add_intents:
    if "<queries>" in s:
        assert s.count("</queries>") == 1, "[48v1] </queries> 不是唯一"
        q_idx = s.index("</queries>")
        s = s[:q_idx] + "\n".join(add_intents) + "\n    " + s[q_idx:]
        print(f"[48v1] 已向现有 <queries> 追加 intent {len(add_intents)} 组")
    else:
        app_idx = s.index("<application")
        block = "    <queries>\n" + "\n".join(add_intents) + "\n    </queries>\n"
        s = s[:app_idx] + block + s[app_idx:]
        print(f"[48v1] AVBox 无 <queries>，已新建并写入 intent {len(add_intents)} 组")

# --- 6.4 <application> 属性 +3（插在 android:name=".base.App" 之后；逐项去重）---
# [已核实] android:name=".base.App"（G1G6 §2.1，HEAD L40）；三属性为 myMusic 有、AVBox 无。
attrs = [
    ('android:dataExtractionRules="@xml/data_extraction_rules"', '        android:dataExtractionRules="@xml/data_extraction_rules"'),
    ('android:fullBackupContent="@xml/backup_rules"', '        android:fullBackupContent="@xml/backup_rules"'),
    ('android:enableOnBackInvokedCallback="true"', '        android:enableOnBackInvokedCallback="true"'),
]
anchor = 'android:name=".base.App"'
must_once(anchor, 'android:name=".base.App"')
missing_attrs = [line for key, line in attrs if not has(key)]
for key, line in attrs:
    if has(key):
        print(f"[48v1] application 属性已存在，跳过：{key}")
if missing_attrs:
    s = s.replace(anchor, anchor + "\n" + "\n".join(missing_attrs), 1)
    print(f"[48v1] 已加 application 属性 {len(missing_attrs)} 项")

# --- 6.5 lyricon meta-data +4（插在 </application> 之前；逐项去重）---
# [未核实]：myMusic 真实清单行 95-100；AVBox 无。
lyricon = [
    ('lyricon_module"', '    <meta-data android:name="lyricon_module" android:value="true" /> <!-- [48v1] -->'),
    ('lyricon_module_author', '    <meta-data android:name="lyricon_module_author" android:value="mytv-android" /> <!-- [48v1] -->'),
    ('lyricon_module_description', '    <meta-data\n        android:name="lyricon_module_description"\n        android:value="myMusic 歌曲、歌词与播放状态" /> <!-- [48v1] -->'),
    ('lyricon_module_tags', '    <meta-data android:name="lyricon_module_tags" android:resource="@array/lyricon_module_tags" /> <!-- [48v1] -->'),
]
add_meta = []
for key, line in lyricon:
    if has(key):
        print(f"[48v1] lyricon meta-data 已存在，跳过：{key}")
    else:
        add_meta.append(line)

# --- 6.6 组件 +6（插在 </application> 之前；逐项按 android:name 去重）---
# [未核实]：myMusic 真实清单原文；MainActivity 已删整个 intent-filter（只留一个桌面入口）。
components = [
    ("com.mytv.mymusic.MainActivity",
     '    <activity\n        android:name="com.mytv.mymusic.MainActivity"\n        android:exported="true"\n        android:configChanges="keyboard|keyboardHidden|navigation|orientation|screenLayout|screenSize|smallestScreenSize" /> <!-- [48v1] -->'),
    ("com.mytv.mymusic.playback.PlaybackService",
     '    <service\n        android:name="com.mytv.mymusic.playback.PlaybackService"\n        android:exported="true"\n        android:foregroundServiceType="mediaPlayback">\n        <intent-filter>\n            <action android:name="androidx.media3.session.MediaSessionService" />\n        </intent-filter>\n    </service> <!-- [48v1] -->'),
    ("com.mytv.mymusic.playback.ResumeButtonReceiver",
     '    <receiver\n        android:name="com.mytv.mymusic.playback.ResumeButtonReceiver"\n        android:exported="true">\n        <intent-filter>\n            <action android:name="android.intent.action.MEDIA_BUTTON" />\n        </intent-filter>\n    </receiver> <!-- [48v1] -->'),
    ("com.mytv.mymusic.overlay.FloatingLyricsService",
     '    <service\n        android:name="com.mytv.mymusic.overlay.FloatingLyricsService"\n        android:exported="false" /> <!-- [48v1] -->'),
    ("com.mytv.mymusic.data.subsonic.SubsonicCoverProvider",
     '    <provider\n        android:name="com.mytv.mymusic.data.subsonic.SubsonicCoverProvider"\n        android:authorities="${applicationId}.subsonic-covers"\n        android:exported="false"\n        android:grantUriPermissions="false" /> <!-- [48v1] -->'),
    ("androidx.startup.InitializationProvider",
     '    <provider\n        android:name="androidx.startup.InitializationProvider"\n        android:authorities="${applicationId}.androidx-startup"\n        android:exported="false"\n        tools:node="merge">\n        <meta-data\n            android:name="androidx.work.WorkManagerInitializer"\n            android:value="androidx.startup"\n            tools:node="remove" />\n    </provider> <!-- [48v1] -->'),
]
add_comp = []
for name, block in components:
    if has('android:name="%s"' % name):
        print(f"[48v1] 组件已存在，跳过：{name}")
    else:
        add_comp.append(block)

# --- 6.7 FileProvider：AVBox 已有则不动；缺失才按标准块补一个（file_paths 内容见第 8 节合并）---
# [未核实]：AVBox 清单 :128-136 有 FileProvider（本地旧检出）；若 HEAD 缺失才补。
if has("androidx.core.content.FileProvider"):
    print("[48v1] FileProvider 已存在，保留 AVBox 的写法，不另加")
else:
    add_comp.append(
     '    <provider\n        android:name="androidx.core.content.FileProvider"\n        android:authorities="${applicationId}.fileprovider"\n        android:exported="false"\n        android:grantUriPermissions="true">\n        <meta-data\n            android:name="android.support.FILE_PROVIDER_PATHS"\n            android:resource="@xml/file_paths" />\n    </provider> <!-- [48v1] AVBox 原无 FileProvider 时补 -->')
    print("[48v1] AVBox 无 FileProvider，已按标准块补一个")

# --- 6.5+6.6+6.7 统一插在 </application> 之前 ---
to_insert = add_meta + add_comp
if to_insert:
    assert s.count("</application>") == 1, "[48v1] </application> 不是唯一"
    idx = s.index("</application>")
    s = s[:idx] + "\n".join(to_insert) + "\n" + s[idx:]
    print(f"[48v1] 已向 </application> 前插入 {len(to_insert)} 块（meta-data {len(add_meta)} + 组件 {len(add_comp)}）")

# --- 6.8 XML 良构校验 ---
import xml.etree.ElementTree as ET
try:
    ET.fromstring(s)
except ET.ParseError as e:
    open("/tmp/manifest_48v1_broken.xml", "w", encoding="utf-8").write(s)
    print(f"[48v1] Manifest XML 解析失败：{e}；破损版已存 /tmp/manifest_48v1_broken.xml", file=sys.stderr)
    sys.exit(1)
print("[48v1] Manifest XML 良构校验通过")
if s != orig:
    open(path, "w", encoding="utf-8").write(s)
    print("[48v1] AndroidManifest.xml 已写入")
else:
    print("[48v1] Manifest 无改动（全部已在位）")
PYEOF
# 6.9 收尾断言（grep 特征字符串）
assert_count "${MANIFEST}" 'android.permission.WAKE_LOCK' 1 "Manifest WAKE_LOCK"
assert_count "${MANIFEST}" 'android.permission.RECORD_AUDIO' 1 "Manifest RECORD_AUDIO"
assert_count "${MANIFEST}" 'android.software.leanback' 1 "Manifest leanback"
assert_count "${MANIFEST}" 'android.hardware.microphone' 1 "Manifest microphone"
# 注意：锚点必须带 android:name="..." 的闭合引号——4 条 lyricon meta-data
# （lyricon_module / _author / _description / _tags）都含 lyricon_module 前缀，
# 裸串会数出 4 行（2026-11-27 第二轮 CI 红根因）；带闭合引号只命中第一条。
assert_count "${MANIFEST}" 'android:name="lyricon_module"' 1 "Manifest lyricon_module"
assert_count "${MANIFEST}" 'com.mytv.mymusic.MainActivity' 1 "Manifest MainActivity"
assert_count "${MANIFEST}" 'com.mytv.mymusic.playback.PlaybackService' 1 "Manifest PlaybackService"
assert_count "${MANIFEST}" 'androidx.startup.InitializationProvider' 1 "Manifest InitializationProvider"
assert_at_least "${MANIFEST}" 'android.speech.RecognitionService' 1 "Manifest queries RecognitionService"
info "Manifest 合并完成"

# ============ 7. 依赖 ============
# 依据：stage0/dependencies.md（myMusic 真实 catalog/app build.gradle.kts，HEAD 1c14ca28；
#       AVBox 侧以本地旧检出为准，[未核实]）。catalog 锚点用特征字符串 grep + fail-fast。
# 路线（已定，见 STAGE48_WRITE.md）：
#   - material3 不加 strictly，按 AVBox 的 alpha29 编（AVBox 现有代码按 alpha29 写）；
#   - MaterialKolor 用新别名 material-kolor-material3/material-kolor-palette 加 6.0.0
#     （与 AVBox 的 5.0.1 不同坐标，可共存，catalog 另起版本键 materialKolor6 避重）；
#   - QuickJS 不另加 2.4.0 依赖，沿用 AVBox 现有 :quickjs 模块（导出 wrapper-android 3.2.3）；
#   - Room 按 dependencies.md §3 双版本共存（roomLegacy 2.8.5 + 双 KSP，sqlite 默认解析 2.7.1 不强制）。
info "== 7. 依赖 =="
CATALOG="gradle/libs.versions.toml"
APPBG="app/build.gradle.kts"
[ -f "${CATALOG}" ] || die "libs.versions.toml 不在 ${CATALOG}"
[ -f "${APPBG}" ] || die "app/build.gradle.kts 不在 ${APPBG}"
assert_count "${CATALOG}" "[versions]" 1 "catalog [versions]"
assert_count "${CATALOG}" "[libraries]" 1 "catalog [libraries]"
assert_count "${CATALOG}" "[plugins]" 1 "catalog [plugins]"
# 模块构建必需的既有别名/版本键（[未核实]：本地旧检出称 AVBox 有；缺失即 exit 1）
assert_count "${CATALOG}" "android-library" 1 "catalog android-library 插件别名"
assert_at_least "${CATALOG}" "compileSdk" 1 "catalog compileSdk 版本键"
assert_at_least "${CATALOG}" "minSdk" 1 "catalog minSdk 版本键"
assert_at_least "${CATALOG}" 'media3 = ' 1 "catalog media3 版本键"
assert_at_least "${CATALOG}" 'kotlin = ' 1 "catalog kotlin 版本键"
assert_count "${APPBG}" "dependencies {" 1 "app build.gradle.kts dependencies 块"
assert_count "${APPBG}" "plugins {" 1 "app build.gradle.kts plugins 块"
# QuickJS：沿用 AVBox 现有 :quickjs 模块（[未核实]：本地旧检出称 app build.gradle.kts 有 project(":quickjs")）
assert_at_least "${APPBG}" 'project(":quickjs")' 1 "app build.gradle.kts :quickjs 模块"

python3 - "${CATALOG}" <<'PYEOF'
import sys, re
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
orig = s
lines = s.split("\n")

def section_range(header):
    idx = [i for i, ln in enumerate(lines) if ln.strip() == header]
    assert len(idx) == 1, f"[48v1] catalog {header} 不是唯一"
    start = idx[0]
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("[") and lines[j].strip().endswith("]"):
            end = j
            break
    return start, end

def version_key_exists(key):
    return any(re.match(rf"^{re.escape(key)}\s*=", ln) for ln in lines)

def alias_exists(alias):
    return any(re.match(rf"^{re.escape(alias)}\s*=", ln) for ln in lines)

def version_ref_of_module(module):
    # 若该 module 已在 catalog 里（别名可能不同），返回其 version.ref（或 inline version）
    for ln in lines:
        if module in ln:
            m = re.search(r'version\.ref\s*=\s*"([^"]+)"', ln)
            if m:
                return m.group(1)
            m = re.search(r'version\s*=\s*"([^"]+)"', ln)
            if m:
                return ("inline", m.group(1))
    return None

# --- 7.1 版本键（插在 [libraries] 之前；已存在则跳过）---
v_start, v_end = section_range("[versions]")
lib_start, lib_end = section_range("[libraries]")
new_versions = [
    ("navigationCompose", '"2.9.8"'),
    ("datastore", '"1.2.1"'),
    ("work", '"2.10.5"'),
    ("glance", '"1.2.0"'),
    ("haze", '"2.0.1"'),
    ("lyricon", '"0.1.70"'),
    ("roomLegacy", '"2.8.5"'),
    ("window", '"1.5.1"'),
    ("profileinstaller", '"1.4.1"'),
    ("kotlinxSerialization", '"1.11.0"'),
    ("kotlinxCoroutines", '"1.10.2"'),
    ("coreKtx", '"1.19.1"'),
    ("checkerQual", '"3.42.0"'),
    ("materialKolor6", '"6.0.0"'),
    ("buildTools", '"37.0.0"'),
]
added_v = []
for key, val in new_versions:
    if version_key_exists(key):
        print(f"[48v1] 版本键已存在，跳过：{key}")
    else:
        lines.insert(lib_start, f'{key} = {val}')
        lib_start += 1
        added_v.append(key)
        print(f"[48v1] 版本键已加：{key} = {val}")
print(f"[48v1] 版本键共加 {len(added_v)} 个")

# --- 7.2 库别名（插在 [plugins] 之前；已存在则跳过）---
plug_start, plug_end = section_range("[plugins]")
# annotation 的 version.ref：优先 AVBox 现有 androidxAnnotation（1.11.0），否则新键 annotation
if not version_key_exists("androidxAnnotation") and not version_key_exists("annotation"):
    lines.insert(lib_start, 'annotation = "1.11.0"')
    lib_start += 1
    plug_start += 1
    print('[48v1] 版本键已加：annotation = "1.11.0"（AVBox 无 androidxAnnotation 键时补）')
if version_key_exists("androidxAnnotation"):
    annotation_ref = "androidxAnnotation"
else:
    annotation_ref = "annotation"
new_libs = [
    ("androidx-navigation-compose", "androidx.navigation:navigation-compose", "navigationCompose"),
    ("androidx-datastore-preferences", "androidx.datastore:datastore-preferences", "datastore"),
    ("androidx-work-runtime-ktx", "androidx.work:work-runtime-ktx", "work"),
    ("androidx-glance-appwidget", "androidx.glance:glance-appwidget", "glance"),
    # 注意：别名不能叫 haze / haze-blur——Gradle 里别名若是另一别名的前缀，libs.haze 会
    # 生成成组访问器（HazeLibraryAccessors）而非依赖，implementation(libs.haze) 报
    # "Cannot convert ... HazeLibraryAccessors"（2026-11-27 第四轮 CI 红根因，app
    # build.gradle.kts:119）。改叫 haze-core / haze-blur-core，三个别名互不为前缀。
    ("haze-core", "dev.chrisbanes.haze:haze", "haze"),
    ("haze-blur-core", "dev.chrisbanes.haze:haze-blur", "haze"),
    ("haze-blur-materials", "dev.chrisbanes.haze:haze-blur-materials", "haze"),
    ("lyricon-provider", "io.github.proify.lyricon:provider", "lyricon"),
    ("lyricon-subscriber", "io.github.proify.lyricon:subscriber", "lyricon"),
    ("androidx-media3-common", "androidx.media3:media3-common", "media3"),
    ("androidx-media3-datasource-okhttp", "androidx.media3:media3-datasource-okhttp", "media3"),
    ("androidx-media3-decoder", "androidx.media3:media3-decoder", "media3"),
    ("androidx-media3-session", "androidx.media3:media3-session", "media3"),
    ("androidx-room-legacy-runtime", "androidx.room:room-runtime", "roomLegacy"),
    ("androidx-room-legacy-ktx", "androidx.room:room-ktx", "roomLegacy"),
    ("androidx-room-legacy-compiler", "androidx.room:room-compiler", "roomLegacy"),
    ("androidx-window", "androidx.window:window", "window"),
    ("androidx-profileinstaller", "androidx.profileinstaller:profileinstaller", "profileinstaller"),
    ("kotlinx-serialization-json", "org.jetbrains.kotlinx:kotlinx-serialization-json", "kotlinxSerialization"),
    ("kotlinx-coroutines-android", "org.jetbrains.kotlinx:kotlinx-coroutines-android", "kotlinxCoroutines"),
    ("androidx-core-ktx", "androidx.core:core-ktx", "coreKtx"),
    ("checker-qual", "org.checkerframework:checker-qual", "checkerQual"),
    ("material-kolor-material3", "com.materialkolor:material-kolor-material3", "materialKolor6"),
    ("material-kolor-palette", "com.materialkolor:material-kolor-palette", "materialKolor6"),
]
added_l = []
for alias, module, ref in new_libs:
    if alias_exists(alias):
        print(f"[48v1] 库别名已存在，跳过：{alias}")
    else:
        lines.insert(plug_start, f'{alias} = {{ module = "{module}", version.ref = "{ref}" }}')
        plug_start += 1
        added_l.append(alias)
        print(f"[48v1] 库别名已加：{alias}")
print(f"[48v1] 库别名共加 {len(added_l)} 个")
# media3-exoplayer / annotation：模块构建必需的 accessor；若 AVBox 已有该 module 但别名不同，
# 补一个同名别名（与既有条目同版本），否则按给定 version.ref 新建。
for alias, module, default_ref in [
    ("androidx-media3-exoplayer", "androidx.media3:media3-exoplayer", "media3"),
    ("androidx-annotation", "androidx.annotation:annotation", annotation_ref),
]:
    if alias_exists(alias):
        print(f"[48v1] 库别名已存在，跳过：{alias}")
        continue
    existing_ref = version_ref_of_module(module)
    if isinstance(existing_ref, tuple):
        # 既有条目用 inline version；新别名用同名版本键（media3/annotation 键必存在，否则下面断言会拦）
        ref = default_ref
        print(f"[48v1] {module} 已有 inline 版本 {existing_ref[1]}，新别名 {alias} 用 version.ref={ref}")
    elif existing_ref:
        ref = existing_ref
        print(f"[48v1] {module} 已有 version.ref={ref}，新别名 {alias} 沿用")
    else:
        ref = default_ref
        print(f"[48v1] {module} 不在 catalog，新别名 {alias} 用 version.ref={ref}")
    assert version_key_exists(ref), f"[48v1] 版本键缺失：{ref}（{alias} 的 version.ref 无此键）"
    lines.insert(plug_start, f'{alias} = {{ module = "{module}", version.ref = "{ref}" }}')
    plug_start += 1
    added_l.append(alias)
    print(f"[48v1] 库别名已加：{alias}")

# --- 7.3 插件别名 kotlin-serialization（追加到文件末尾；已存在则跳过）---
if alias_exists("kotlin-serialization"):
    print("[48v1] 插件别名已存在，跳过：kotlin-serialization")
else:
    assert version_key_exists("kotlin"), "[48v1] 版本键缺失：kotlin（kotlin-serialization 的 version.ref）"
    lines.append('kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }')
    print("[48v1] 插件别名已加：kotlin-serialization")

s = "\n".join(lines)
if s != orig:
    open(path, "w", encoding="utf-8").write(s)
    print("[48v1] libs.versions.toml 已写入")
else:
    print("[48v1] libs.versions.toml 无改动（全部已在位）")
PYEOF

# 7.4 app/build.gradle.kts：插件 + 依赖（插在 plugins { / dependencies { 块内第一行）
python3 - "${APPBG}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
orig = s
lines = s.split("\n")
def find_block(header):
    idx = [i for i, ln in enumerate(lines) if header in ln]
    assert len(idx) == 1, f"[48v1] {header} 不是唯一"
    return idx[0]
# 插件：alias(libs.plugins.kotlin.serialization)（myMusic app build.gradle.kts:7）
plug_alias = "alias(libs.plugins.kotlin.serialization)"
if plug_alias in s:
    print("[48v1] 插件 alias 已存在，跳过：kotlin.serialization")
else:
    pi = find_block("plugins {")
    lines.insert(pi + 1, "    " + plug_alias + " // [48v1]")
    print("[48v1] 插件 alias 已加：kotlin.serialization")
    s = "\n".join(lines)
    lines = s.split("\n")
# 依赖：新依赖插在 dependencies { 块内第一行（gradle 依赖注入铁律）
deps = [
    'implementation(libs.androidx.navigation.compose)',
    'implementation(libs.androidx.datastore.preferences)',
    'implementation(libs.androidx.work.runtime.ktx)',
    'implementation(libs.androidx.glance.appwidget)',
    'implementation(libs.haze.core)',
    'implementation(libs.haze.blur.core)',
    'implementation(libs.haze.blur.materials)',
    'implementation(libs.lyricon.provider)',
    'implementation(libs.lyricon.subscriber)',
    'implementation(libs.androidx.media3.common)',
    'implementation(libs.androidx.media3.datasource.okhttp)',
    'implementation(libs.androidx.media3.session)',
    'implementation(libs.material.kolor.material3)',
    'implementation(libs.material.kolor.palette)',
    'implementation(libs.kotlinx.serialization.json)',
    'implementation(libs.kotlinx.coroutines.android)',
    'implementation(libs.androidx.core.ktx)',
    'implementation(libs.androidx.window)',
    'implementation(libs.androidx.profileinstaller)',
    'implementation(libs.androidx.room.legacy.runtime)',
    'implementation(libs.androidx.room.legacy.ktx)',
    'ksp(libs.androidx.room.legacy.compiler)',
    'implementation(project(":lib-decoder-flac"))',
    'implementation(project(":lib-runtime-lx"))',
]
di = find_block("dependencies {")
added = 0
# 从后往前插，保证最终顺序与 deps 列表一致
for dep in reversed(deps):
    if dep in s:
        print(f"[48v1] 依赖已存在，跳过：{dep}")
    else:
        lines.insert(di + 1, "    " + dep + " // [48v1]")
        added += 1
        s = "\n".join(lines)
        lines = s.split("\n")
print(f"[48v1] app/build.gradle.kts 依赖共加 {added} 行")
s = "\n".join(lines)
if s != orig:
    open(path, "w", encoding="utf-8").write(s)
    print("[48v1] app/build.gradle.kts 已写入")
else:
    print("[48v1] app/build.gradle.kts 无改动（全部已在位）")
PYEOF

# 7.4b app/build.gradle.kts：material3 实验 API opt-in（myMusic app build.gradle.kts:84-87
#      模块层 opt-in；AVBox app build 无此 opt-in，myMusic 源码里 ExperimentalMaterial3Api /
#      Expressive 用法全报 e: "This material3 API is experimental..."。
#      2026-11-27 第五轮 CI 红根因之一。）
python3 - "${APPBG}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
lines = s.split("\n")
if "ExperimentalMaterial3Api" in s:
    print("[48v1] material3 opt-in 已存在，跳过")
else:
    idx = [i for i, ln in enumerate(lines) if "compilerOptions {" in ln]
    assert len(idx) == 1, "[48v1] compilerOptions { 不是唯一"
    ci = idx[0]
    optin = [
        '        // [48v1] myMusic 植入：opt-in 实验性 Material3 API（myMusic 模块层同款）',
        '        freeCompilerArgs.addAll(',
        '            "-opt-in=androidx.compose.material3.ExperimentalMaterial3Api",',
        '            "-opt-in=androidx.compose.material3.ExperimentalMaterial3ExpressiveApi",',
        '        )',
    ]
    lines[ci+1:ci+1] = optin
    open(path, "w", encoding="utf-8").write("\n".join(lines))
    print("[48v1] material3 opt-in 已加：ExperimentalMaterial3Api + ExpressiveApi")
PYEOF

# 7.5 gradle.properties：保留 android.uniquePackageNames=false 豁免
# [未核实]：dependencies.md C5 称 AVBox 已有该行（本地旧检出），理由是本地 :quickjs 模块与
# wrapper-android 同包名 com.whl.quickjs.wrapper；myMusic 的 LxSources 同样走此包，豁免仍需保留。
# 缺失则补（否则合并后构建报重复类）。
GP="gradle.properties"
if [ -f "${GP}" ]; then
  append_if_absent "${GP}" "android.uniquePackageNames=false" "android.uniquePackageNames=false # [48v1] myMusic 植入：保留，:quickjs 模块与 wrapper-android 同包名" "gradle.properties uniquePackageNames"
else
  echo "[48] 警告：gradle.properties 不存在，未补 uniquePackageNames 豁免（[未核实]）" >&2
fi
# 7.6 收尾断言
assert_count "${CATALOG}" 'roomLegacy = "2.8.5"' 1 "catalog roomLegacy 版本键"
assert_count "${CATALOG}" 'androidx-room-legacy-runtime' 1 "catalog room-legacy-runtime 别名"
assert_count "${CATALOG}" 'androidx-media3-decoder' 1 "catalog media3-decoder 别名"
assert_count "${CATALOG}" 'checker-qual' 1 "catalog checker-qual 别名"
assert_count "${CATALOG}" 'kotlin-serialization' 1 "catalog kotlin-serialization 插件别名"
assert_count "${APPBG}" 'alias(libs.plugins.kotlin.serialization)' 1 "app kotlin.serialization 插件"
assert_count "${APPBG}" 'libs.androidx.room.legacy.compiler' 1 "app room legacy compiler"
assert_count "${APPBG}" 'project(":lib-runtime-lx")' 1 "app lib-runtime-lx"
assert_count "${APPBG}" 'project(":lib-decoder-flac")' 1 "app lib-decoder-flac"
info "依赖合并完成"

# ============ 8. 资源 ============
# 依据：stage0/resource_conflicts.md（myMusic 侧本地同提交 clone 直读；AVBox 侧本地旧检出，[未核实]）。
# 策略：res 选择性拷贝（排除 values/values-night/mipmap-*/冲突文件），values 合并进新文件，
#       file_paths 取 9 条并集，app_name 改名，启动图标改名，network_security_config 留 AVBox 的。
info "== 8. 资源 =="
MYRES="${MYMUSIC_SRC}/app/src/main/res"
AVRES="app/src/main/res"
[ -d "${MYRES}" ] || die "myMusic res 目录不在 ${MYRES}"
# 8.1 res 选择性拷贝（find + cp；排除项见注释）
#     排除：values/* 与 values-night/*（8.3 合并进新文件，不覆盖 AVBox 的 values 文件）；
#           mipmap-*/*（全部是 ic_launcher/ic_launcher_round 启动图标，丢弃）；
#           drawable/ic_launcher_foreground.xml（8.2 改名另拷）；
#           drawable/ic_launcher_monochrome.xml（丢弃，只被已丢弃的 mipmap 图标引用）；
#           xml/file_paths.xml（8.4 并集，不覆盖）；xml/network_security_config.xml（留 AVBox 的）。
find_res_files() {
  find "${MYRES}" -type f \
    ! -path "${MYRES}/values/*" ! -path "${MYRES}/values-night/*" \
    ! -path "${MYRES}/mipmap-*/*" \
    ! -name 'ic_launcher_foreground.xml' \
    ! -name 'ic_launcher_monochrome.xml' \
    ! -path "${MYRES}/xml/file_paths.xml" \
    ! -path "${MYRES}/xml/network_security_config.xml" \
    -print0
}
info "检查 res 碰撞…"
collision=""
while IFS= read -r -d '' f; do
  rel="${f#${MYRES}/}"
  if [ -e "${AVRES}/${rel}" ]; then
    if ! cmp -s "$f" "${AVRES}/${rel}"; then
      collision="${collision} ${rel}"
    fi
  fi
done < <(find_res_files)
if [ -n "${collision}" ]; then
  die "res 文件名碰撞（AVBox 已有同名但内容不同的文件）：${collision}"
fi
copied=0
while IFS= read -r -d '' f; do
  rel="${f#${MYRES}/}"
  mkdir -p "${AVRES}/$(dirname "${rel}")"
  cp "$f" "${AVRES}/${rel}"
  copied=$((copied + 1))
done < <(find_res_files)
info "已拷贝 res 文件 ${copied} 个（零碰撞）"

# 8.2 启动图标改名 + AboutScreen 引用修正
# [已核实] myMusic 侧：ic_launcher_foreground.xml 在 drawable/（本地 clone 直读）；
# R.drawable.ic_launcher_foreground 全仓唯一引用在 AboutScreen.kt:468（本地 clone grep 仅 1 处）。
# ic_launcher_background.xml 保留原名（N1：R.drawable 与 R.color 可共存，无冲突）。
if [ -f "${AVRES}/drawable/mymusic_ic_launcher_foreground.xml" ]; then
  info "mymusic_ic_launcher_foreground.xml 已在位，跳过"
else
  cp "${MYRES}/drawable/ic_launcher_foreground.xml" "${AVRES}/drawable/mymusic_ic_launcher_foreground.xml" \
    || die "拷贝 ic_launcher_foreground.xml 失败"
  info "启动图标已改名：mymusic_ic_launcher_foreground.xml"
fi
ABOUT="app/src/main/java/com/mytv/mymusic/ui/settings/AboutScreen.kt"
if grep -F -q "R.drawable.mymusic_ic_launcher_foreground" "${ABOUT}"; then
  info "AboutScreen.kt 引用已改名，跳过"
else
  assert_count "${ABOUT}" "R.drawable.ic_launcher_foreground" 1 "AboutScreen ic_launcher_foreground 引用"
  python3 - "${ABOUT}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = "R.drawable.ic_launcher_foreground"
new = "R.drawable.mymusic_ic_launcher_foreground"
assert s.count(old) == 1, "R.drawable.ic_launcher_foreground 出现次数 != 1"
s = s.replace(old, new)
open(path, "w", encoding="utf-8").write(s)
print("[48] AboutScreen.kt 引用已改名")
PYEOF
fi

# 8.3 values 合并：myMusic 的 values/*.xml → values/mymusic_values.xml（新文件，不覆盖 AVBox 的）；
#     values-night/*.xml → values-night/mymusic_values.xml；app_name 改名 mymusic_app_name。
# [已核实] myMusic 侧 values 仅 4 文件 + values-night 1 文件（本地 clone 直读）；
# app_name="myMusic" 与 AVBox 的 app_name="AVBox" 冲突（G1G6 §6，HEAD strings.xml:2，[已核实]）。
# 其余资源名无冲突（resource_conflicts.md，AVBox 侧本地旧检出，[未核实]——脚本逐名复核）。
python3 - "${MYRES}" "${AVRES}" <<'PYEOF'
import sys, re, os
myres, avres = sys.argv[1], sys.argv[2]
def inner(xml_text):
    m = re.search(r"<resources[^>]*>(.*)</resources>", xml_text, re.S)
    assert m, "[48v1] values 文件无 <resources> 包裹"
    return m.group(1).strip()
def names_of(inner_text):
    return re.findall(r'name="([^"]+)"', inner_text)
# 收集 AVBox 现有 values 资源名（用于碰撞复核）
av_names = set()
for d in ("values", "values-night"):
    vd = os.path.join(avres, d)
    if os.path.isdir(vd):
        for fn in os.listdir(vd):
            if fn.endswith(".xml") and fn != "mymusic_values.xml":  # 排除本脚本上次生成的合并文件，否则重跑自撞
                txt = open(os.path.join(vd, fn), encoding="utf-8").read()
                av_names.update(names_of(txt))
for src_dir, dst_file in (("values", "values/mymusic_values.xml"),
                          ("values-night", "values-night/mymusic_values.xml")):
    src = os.path.join(myres, src_dir)
    parts = []
    for fn in sorted(os.listdir(src)):
        if not fn.endswith(".xml"):
            continue
        txt = open(os.path.join(src, fn), encoding="utf-8").read()
        body = inner(txt)
        # app_name 改名（只在 values/strings.xml 里出现；values-night 无此项）
        body = body.replace('name="app_name"', 'name="mymusic_app_name"')
        for nm in names_of(body):
            if nm == "mymusic_app_name":
                continue
            assert nm not in av_names, f"[48v1] values 资源名碰撞：{nm}（AVBox 已有同名资源）"
        parts.append(f"    <!-- 来自 myMusic {src_dir}/{fn} [48v1] -->\n" + body)
    dst = os.path.join(avres, dst_file)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    content = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n' + "\n".join(parts) + "\n</resources>\n"
    if os.path.exists(dst) and open(dst, encoding="utf-8").read() == content:
        print(f"[48v1] {dst_file} 内容一致，跳过")
    else:
        open(dst, "w", encoding="utf-8").write(content)
        print(f"[48v1] {dst_file} 已写入（合并自 myMusic {src_dir}/*.xml）")
PYEOF
assert_count "${AVRES}/values/mymusic_values.xml" 'name="mymusic_app_name"' 1 "mymusic_values.xml app_name 改名"
assert_count "${AVRES}/values/mymusic_values.xml" 'name="app_name"' 0 "mymusic_values.xml 无残留 app_name"

# 8.4 file_paths 并集 9 条（AVBox 5 条 + myMusic 4 条，name 不重叠）
# [未核实]：AVBox 5 条（vod_cache_path/vod_external_path/vod_external_cache_path/
# beta_external_path/beta_external_files_path）来自本地旧检出；脚本读 HEAD 现行文件做并集，
# name 撞上即 exit 1。myMusic 4 条：updates/logs/share/exports（cache-path）。
python3 - "${MYRES}/xml/file_paths.xml" "${AVRES}/xml/file_paths.xml" <<'PYEOF'
import sys, re, os
my_fp, av_fp = sys.argv[1], sys.argv[2]
def inner_paths(txt):
    m = re.search(r"<paths[^>]*>(.*)</paths>", txt, re.S)
    assert m, "[48v1] file_paths.xml 无 <paths> 包裹"
    return m.group(1).strip()
def names_of(body):
    return re.findall(r'name="([^"]+)"', body)
my_txt = open(my_fp, encoding="utf-8").read()
my_body = inner_paths(my_txt)
my_names = names_of(my_body)
assert len(my_names) == 4, f"[48v1] myMusic file_paths 应为 4 条，实为 {len(my_names)} 条：{my_names}"
if not os.path.exists(av_fp):
    open(av_fp, "w", encoding="utf-8").write(my_txt)
    print("[48v1] AVBox 无 file_paths.xml，已直接采用 myMusic 的 4 条")
    sys.exit(0)
av_txt = open(av_fp, encoding="utf-8").read()
av_body = inner_paths(av_txt)
av_names = names_of(av_body)
if all(n in av_names for n in my_names):
    print("[48v1] file_paths 已含 myMusic 4 条，跳过")
    sys.exit(0)
overlap = set(my_names) & set(av_names)
assert not overlap, f"[48v1] file_paths name 碰撞：{sorted(overlap)}"
merged = '<?xml version="1.0" encoding="utf-8"?>\n<paths>\n' + av_body + "\n" + my_body + "\n</paths>\n"
open(av_fp, "w", encoding="utf-8").write(merged)
print(f"[48v1] file_paths 已合并：AVBox {len(av_names)} 条 + myMusic {len(my_names)} 条 = {len(av_names) + len(my_names)} 条")
PYEOF
info "资源合并完成"

# ============ 9. 原生库 ============
# 依据：stage48/native_modules_check.md。两模块目录原样拷进工程根目录（C++ 源码，非 .so 二进制；
# 禁止把 .so 二进制 base64 进脚本——.so 由 Gradle 在 CI 里现编）。
# [已核实] myMusic 侧：两模块 build.gradle.kts 存在（本地同提交 clone 直读）；
# 两模块能在 CI 里编出 .so（本地已有一次完整绿构建为证，20 个 .so 实物）。
# [未核实]：NDK 27.0.12077973 vs AVBox 27.2.12479018、CMake 3.22.1、catalog buildTools 键——
# 须 CI 验证，脚本做显式检查（见 9.3）。
info "== 9. 原生库 =="
# 9.1 两模块目录原样拷进 AVBox 工程根目录（即 avbox/，与 settings.gradle.kts 同级）
for mod in lib-runtime-lx lib-decoder-flac; do
  if [ -f "${AVBOX_DIR}/${mod}/build.gradle.kts" ]; then
    info "模块 ${mod} 已在 AVBox 工程根目录，跳过拷贝"
  else
    [ -d "${MYMUSIC_SRC}/${mod}" ] || die "myMusic 源码缺模块目录：${mod}"
    cp -r "${MYMUSIC_SRC}/${mod}" "${AVBOX_DIR}/" || die "拷贝模块 ${mod} 失败"
    info "模块 ${mod} 已拷进 AVBox 工程根目录"
  fi
  [ -f "${AVBOX_DIR}/${mod}/build.gradle.kts" ] || die "模块 ${mod} 缺 build.gradle.kts"
done
# 9.1b lib-runtime-lx 加 kotlin.android 插件：该模块唯一 Kotlin 源码 LxQuickJsInterrupt.kt，
#      但 build.gradle.kts 只 apply 了 android.library，未 apply Kotlin 插件——Kotlin 源码
#      不编译，app 侧 import com.mytv.mymusic.lxruntime.LxQuickJsInterrupt 报 Unresolved
#      reference（2026-11-27 第五轮 CI 红根因之一）。lib-decoder-flac 无 Kotlin 源码，不用加。
#      AVBox catalog 有 kotlin-android 别名（app 模块即用它）。
assert_count "${CATALOG}" 'kotlin-android = ' 1 "catalog kotlin-android 插件别名（lib-runtime-lx 必需）"
python3 - "${AVBOX_DIR}/lib-runtime-lx/build.gradle.kts" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
lines = s.split("\n")
alias = "alias(libs.plugins.kotlin.android)"
if alias in s:
    print("[48v1] lib-runtime-lx kotlin.android 插件已存在，跳过")
else:
    idx = [i for i, ln in enumerate(lines) if ln.strip() == "alias(libs.plugins.android.library)"]
    assert len(idx) == 1, "[48v1] lib-runtime-lx plugins 块里 android.library 不是唯一"
    lines.insert(idx[0] + 1, "    " + alias + " // [48v1] myMusic 植入：模块含 Kotlin 源码，须 apply Kotlin 插件才编译")
    open(path, "w", encoding="utf-8").write("\n".join(lines))
    print("[48v1] lib-runtime-lx kotlin.android 插件已加")
PYEOF
# 9.2 settings.gradle.kts 加两行 include（追加到文件末尾；已存在则跳过）
SETTINGS="settings.gradle.kts"
[ -f "${SETTINGS}" ] || die "settings.gradle.kts 不在 ${SETTINGS}"
append_if_absent "${SETTINGS}" 'include(":lib-decoder-flac")' 'include(":lib-decoder-flac") // [48v1] myMusic 植入：FLAC 扩展解码' "settings include lib-decoder-flac"
append_if_absent "${SETTINGS}" 'include(":lib-runtime-lx")' 'include(":lib-runtime-lx") // [48v1] myMusic 植入：洛雪 JS 沙箱原生运行时' "settings include lib-runtime-lx"
# 9.3 NDK / CMake / buildTools 键显式检查
# buildTools 键：第 7 节已补（若 AVBox catalog 原无）；此处复核（模块 build.gradle.kts 用
# libs.versions.buildTools.get()，缺键即构建失败）。
assert_count "${CATALOG}" 'buildTools = ' 1 "catalog buildTools 版本键"
# 模块必需的 catalog 别名复核（第 7 节已加/验证；缺失即 exit 1）
for alias in androidx-media3-exoplayer androidx-media3-decoder androidx-annotation checker-qual; do
  assert_count "${CATALOG}" "${alias} = " 1 "catalog ${alias} 别名（模块必需）"
done
assert_at_least "${CATALOG}" 'compileSdk = ' 1 "catalog compileSdk（模块必需）"
assert_at_least "${CATALOG}" 'minSdk = ' 1 "catalog minSdk（模块必需）"
# NDK / CMake 版本对齐：两模块原声明 ndkVersion 27.0.12077973、cmake 3.22.1；CI 只装了
# AVBox 的 NDK 27.2.12479018（27.0 未装，2026-11-27 第三轮 CI 红根因）。此处按 SDK 已装
# 版本对齐两模块：优先 AVBox 的 27.2.12479018 / 原声明的 3.22.1，否则取已装最新版；
# SDK 下一个都没装才 exit 1（须 build.yml 加 sdkmanager 装）。
SDK_DIR=""
for cand in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "/opt/android-sdk" "/usr/lib/android-sdk"; do
  if [ -n "$cand" ] && [ -d "$cand" ]; then SDK_DIR="$cand"; break; fi
done
if [ -z "$SDK_DIR" ]; then
  echo "[48] 提示：未找到 Android SDK 目录（ANDROID_HOME/ANDROID_SDK_ROOT 未设），NDK/CMake 版本无法核查，交由 Gradle 构建时报错定位" >&2
else
  info "Android SDK 目录：${SDK_DIR}"
  NDK_VER=""
  if [ -d "${SDK_DIR}/ndk/27.2.12479018" ]; then
    NDK_VER="27.2.12479018"
  else
    NDK_VER="$(ls "${SDK_DIR}/ndk/" 2>/dev/null | sort -V | tail -n 1)"
  fi
  [ -n "$NDK_VER" ] || die "SDK 下未装任何 NDK（SDK：${SDK_DIR}）。修法：build.yml 加 sdkmanager 装 ndk;27.2.12479018"
  CMAKE_VER=""
  if [ -d "${SDK_DIR}/cmake/3.22.1" ]; then
    CMAKE_VER="3.22.1"
  else
    CMAKE_VER="$(ls "${SDK_DIR}/cmake/" 2>/dev/null | sort -V | tail -n 1)"
  fi
  [ -n "$CMAKE_VER" ] || die "SDK 下未装任何 CMake（SDK：${SDK_DIR}）。修法：build.yml 加 sdkmanager 装 cmake;3.22.1"
  info "NDK 对齐到 ${NDK_VER}，CMake 对齐到 ${CMAKE_VER}"
  for mod in lib-runtime-lx lib-decoder-flac; do
    f="${AVBOX_DIR}/${mod}/build.gradle.kts"
    if grep -F -q 'ndkVersion = "27.0.12077973"' "$f"; then
      assert_count "$f" 'ndkVersion = "27.0.12077973"' 1 "模块 ${mod} ndkVersion 原值"
      sed -i "s/ndkVersion = \"27.0.12077973\"/ndkVersion = \"${NDK_VER}\"/" "$f"
    fi
    assert_count "$f" "ndkVersion = \"${NDK_VER}\"" 1 "模块 ${mod} ndkVersion"
    if grep -F -q 'version = "3.22.1"' "$f"; then
      assert_count "$f" 'version = "3.22.1"' 1 "模块 ${mod} cmake 原值"
      sed -i "s/version = \"3.22.1\"/version = \"${CMAKE_VER}\"/" "$f"
    fi
    assert_count "$f" "version = \"${CMAKE_VER}\"" 1 "模块 ${mod} cmake"
    info "模块 ${mod} 已对齐：ndkVersion=${NDK_VER}，cmake=${CMAKE_VER}"
  done
fi
info "原生库合并完成"

# ============ 10. 收尾断言与汇总 ============
info "== 10. 收尾断言 =="
# 源码与 Application
[ -f "app/src/main/java/com/mytv/mymusic/MyMusicApp.kt" ] || die "收尾：MyMusicApp.kt 缺失"
grep -F -q "open class MyMusicApp : Application()" "app/src/main/java/com/mytv/mymusic/MyMusicApp.kt" || die "收尾：MyMusicApp 未加 open"
grep -F -q "class App : MyMusicApp()" "${APPKT}" || die "收尾：.base.App 未继承 MyMusicApp"
# Tab
grep -F -q 'MYMUSIC(R.string.tab_mymusic' "${MS}" || die "收尾：MainScreen.kt 无 MYMUSIC 枚举"
grep -F -q 'AppTab.MYMUSIC ->' "${MS}" || die "收尾：MainScreen.kt 无 MYMUSIC 分支"
# Manifest
grep -F -q 'com.mytv.mymusic.MainActivity' "${MANIFEST}" || die "收尾：Manifest 无 myMusic MainActivity"
grep -F -q 'com.mytv.mymusic.playback.PlaybackService' "${MANIFEST}" || die "收尾：Manifest 无 PlaybackService"
# 依赖
grep -F -q 'libs.androidx.room.legacy.compiler' "${APPBG}" || die "收尾：app 无 room legacy compiler"
grep -F -q 'include(":lib-runtime-lx")' "${SETTINGS}" || die "收尾：settings 无 lib-runtime-lx"
grep -F -q 'include(":lib-decoder-flac")' "${SETTINGS}" || die "收尾：settings 无 lib-decoder-flac"
# 第五轮 CI 红修：R 别名 / material3 opt-in / lib-runtime-lx Kotlin 插件
grep -F -q "typealias R = " "app/src/main/java/com/mytv/mymusic/R.kt" || die "收尾：R 别名文件缺失"
grep -F -q 'ExperimentalMaterial3Api' "${APPBG}" || die "收尾：app 无 material3 opt-in"
grep -F -q 'alias(libs.plugins.kotlin.android)' "${AVBOX_DIR}/lib-runtime-lx/build.gradle.kts" || die "收尾：lib-runtime-lx 无 kotlin.android 插件"
# 资源
[ -f "${AVRES}/values/mymusic_values.xml" ] || die "收尾：mymusic_values.xml 缺失"
[ -f "${AVRES}/values-night/mymusic_values.xml" ] || die "收尾：values-night/mymusic_values.xml 缺失"
[ -f "${AVRES}/drawable/mymusic_ic_launcher_foreground.xml" ] || die "收尾：mymusic_ic_launcher_foreground.xml 缺失"
# file_paths 应为 9 条（AVBox 5 + myMusic 4；若 AVBox 原无 file_paths，则为 myMusic 的 4 条）
fp_count="$(grep -c 'name="' "${AVRES}/xml/file_paths.xml")"
if [ "$fp_count" != "9" ] && [ "$fp_count" != "4" ]; then
  die "收尾：file_paths 条目数为 ${fp_count}，期望 9（AVBox 5 + myMusic 4）或 4（AVBox 原无 file_paths 时）"
fi
info "file_paths 条目数：${fp_count}"
echo "=== [48v1] myMusic 植入脚本执行完成 ==="
echo "[48] 注意：本脚本未做全链仿真（基线被拦），CI 变红时按 STAGE48_WRITE.md 定位修法。"
echo "[48] 推后步骤：用户在网页端给 build.yml 加 48 调用行 → 手动触发 workflow_dispatch → 按验收清单装机验证。"
