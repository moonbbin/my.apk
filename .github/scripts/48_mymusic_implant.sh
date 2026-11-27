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
MYMUSIC_SHA="3cb7b0615e40f084ef2dbbc8b60a792b3629e6aa"
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

# 3c. R 直接导入：植入后 R 类随 app 模块生成（包名 = AVBox 的 namespace），myMusic 源码里
#     的 R 引用一律改成直接 import 该 R 类，不再用 typealias。
#     （2026-11-27 第五轮 CI 红根因之一：44 个编译错里大半是 Unresolved reference 'R'；
#     第七轮 CI 红：typealias 写法下 R 本身解析了，但 R.drawable/R.string 在 myMusic 文件里
#     仍报 Unresolved reference——typealias 到生成 R 类的嵌套类访问不可靠，改直接导入。
#     资源已在第 8 节并进 app 的 res/，故 app 的 R 类含 myMusic 全部资源。）
NS="$(sed -n 's/^[[:space:]]*namespace[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' app/build.gradle.kts | head -n 1)"
[ -n "$NS" ] || die "app/build.gradle.kts 无 namespace，无法生成 R 导入"
RKT="app/src/main/java/com/mytv/mymusic/R.kt"
rm -f "${RKT}"  # 旧版 typealias 文件若在，删掉（直接导入后不再需要）
python3 - "${NS}" <<'PYEOF'
import sys, os, re
ns = sys.argv[1]
root = "app/src/main/java/com/mytv/mymusic"
# 匹配 app R 引用（R.drawable/R.string/...），排除 android.R.*（框架 R，不用改）
r_pat = re.compile(r"(?<!android\.)\bR\.(drawable|string|color|layout|id|mipmap|raw|anim|font|style|dimen|bool|integer|array|attr|plurals)\b")
changed = 0
for dirpath, _, files in os.walk(root):
    for fn in sorted(files):
        if not fn.endswith(".kt"):
            continue
        p = os.path.join(dirpath, fn)
        s = open(p, encoding="utf-8").read()
        if not r_pat.search(s):
            continue
        if "import com.mytv.mymusic.R" in s:
            assert s.count("import com.mytv.mymusic.R") == 1, f"[48v1] {p} import com.mytv.mymusic.R 出现次数 != 1"
            s = s.replace("import com.mytv.mymusic.R", f"import {ns}.R")
            print(f"[48v1] {p}: import 已改 -> {ns}.R")
            changed += 1
        elif f"import {ns}.R" not in s:
            lines = s.split("\n")
            pkg_idx = [i for i, ln in enumerate(lines) if ln.startswith("package ")]
            assert len(pkg_idx) == 1, f"[48v1] {p} package 行不是唯一"
            lines.insert(pkg_idx[0] + 1, f"import {ns}.R")
            s = "\n".join(lines)
            print(f"[48v1] {p}: import 已加 -> {ns}.R")
            changed += 1
        open(p, "w", encoding="utf-8").write(s)
print(f"[48v1] R 直接导入完成，共改 {changed} 个文件")
PYEOF
info "R 直接导入已完成（namespace=${NS}）"

# 3d. Buttons.kt：ToggleButtonDefaults.ContentPadding 在 AVBox 的 Material3 alpha29 里是
#     private（myMusic 的 alpha25 里可访问），改成本地 PaddingValues。
#     （2026-11-27 第七轮 CI 红根因之二：Buttons.kt:155/240 各 1 处。）
BTN="app/src/main/java/com/mytv/mymusic/ui/components/Buttons.kt"
if grep -F -q "DefaultTogglePadding" "${BTN}"; then
  info "Buttons.kt 已用 DefaultTogglePadding，跳过"
else
  assert_count "${BTN}" "ToggleButtonDefaults.ContentPadding" 2 "Buttons.kt ContentPadding 引用"
  python3 - "${BTN}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = "ToggleButtonDefaults.ContentPadding"
assert s.count(old) == 2, "ToggleButtonDefaults.ContentPadding 出现次数 != 2"
s = s.replace(old, "DefaultTogglePadding")
# 在 CompactTogglePadding 旁加本地默认值（Material3 ToggleButton 默认内边距近似值；
# 水平 16.dp、垂直 8.dp，与 Compact 的垂直 8.dp 一致）
anchor = "private val CompactTogglePadding = PaddingValues(horizontal = 6.dp, vertical = 8.dp)"
assert s.count(anchor) == 1, "CompactTogglePadding 定义行不是唯一"
s = s.replace(anchor, anchor + "\n\n// [48v1] myMusic 植入：Material3 alpha29 里该默认值已为 private，改本地值\nprivate val DefaultTogglePadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)")
open(path, "w", encoding="utf-8").write(s)
print("[48v1] Buttons.kt ContentPadding 已换 DefaultTogglePadding")
PYEOF
fi

# 3e. LibraryScreen.kt：SplitButton 在 AVBox 的 Material3 alpha29 里已被改名/移除
#     （2026-11-27 第八轮 CI 红根因：LibraryScreen.kt:78 import 与 :1225 调用报
#     Unresolved reference 'SplitButton'，其余 3 错是级联的 @Composable 上下文错。
#     myMusic 的 alpha25 有 SplitButton，alpha29 只剩 SplitButtonLayout——Buttons.kt
#     的 PlayAllSplitButton 已用 SplitButtonLayout 且能编过，参数名完全一致，
#     故此处改 SplitButton -> SplitButtonLayout，纯改名。）
LIB="app/src/main/java/com/mytv/mymusic/ui/library/LibraryScreen.kt"
if grep -F -q "import androidx.compose.material3.SplitButtonLayout" "${LIB}"; then
  info "LibraryScreen.kt 已用 SplitButtonLayout，跳过"
else
  # 注意：SplitButtonDefaults 行含 SplitButton 子串，须按整行匹配（^...$），禁子串计数
  [ "$(grep -c '^import androidx.compose.material3.SplitButton$' "${LIB}")" = "1" ] || die "LibraryScreen SplitButton import 不是 1 行"
  python3 - "${LIB}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
# 整行匹配（含换行），避免误伤 SplitButtonDefaults 行
old_imp = "import androidx.compose.material3.SplitButton\n"
assert s.count(old_imp) == 1, "SplitButton import 整行出现次数 != 1"
s = s.replace(old_imp, "import androidx.compose.material3.SplitButtonLayout\n")
# 调用点：仅 NewPlaylistSplitButton 一处用 SplitButton(（其余 SplitButton( 均为自定义 PlayAllSplitButton）
assert s.count("    SplitButton(\n") == 1, "SplitButton( 调用点出现次数 != 1"
s = s.replace("    SplitButton(\n", "    SplitButtonLayout(\n")
open(path, "w", encoding="utf-8").write(s)
print("[48v1] LibraryScreen.kt SplitButton 已换 SplitButtonLayout")
PYEOF
fi

# 3f. AboutScreen.kt：隐藏检查更新/问题反馈/Telegram群组/扫码访问，并关掉更新；
#     更新卡片保留，改成移植说明静态卡片
#     （2026-11-27 用户定：关于页里这 4 项不要，且更新要彻底关掉。
#     原因：检查更新下的是独立 myMusic App 安装包（会另装一个 App，不更新 my.apk
#     里植入的版本），留着误导。改法：删 3 个 ListRow（检查更新/问题反馈/Telegram
#     群组）＋删 LinksCard 项（扫码访问段）；剩余 6 行重编号（count 9→6，index 按
#     剩余顺序重排，否则 segmentShape 圆角错位）；MusicViewModel 的
#     checkUpdatesInBackground() 改空实现，启动时与回到前台的自动检查都不再跑，
#     故“新”徽标/更新弹窗都不会再出现；手动检查入口随检查更新行一起删，
#     checkUpdatesNow() 只剩 AboutScreen 内部调用，已无界面可达。
#     卡片：用户 19:52 截图定保留蓝色卡片，文字换成移植说明（文案用户 19:58 定稿，
#     “想升版须改48脚本重新构建”改成“正版须去项目主页”）；调用点去条件化常显，
#     新增 TransplantCard 静态卡片（同 tertiaryContainer 蓝底、同 28dp 圆角），
#     “立即下载”按钮随旧 UpdateCard 一起不再使用。）
ABOUT="app/src/main/java/com/mytv/mymusic/ui/settings/AboutScreen.kt"
# 注意：守卫必须按 ListRow 标题行匹配（title = "检查更新"），不能只 grep "检查更新"——
# 文件里注释与 ErrorBlock 也含“检查更新”，裸 grep 首跑后仍命中，二跑会误跑进 Python 断言失败
if grep -F -q 'title = "检查更新"' "${ABOUT}"; then
  python3 - "${ABOUT}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()

def find_listrow_block(text, title):
    key = 'title = "' + title + '"'
    idx = text.find(key)
    assert idx != -1, f"[48v2] AboutScreen 无标题 {title}"
    start = text.rfind("ListRow(", 0, idx)
    assert start != -1, f"[48v2] AboutScreen 找不到 {title} 的 ListRow("
    paren = text.find("(", start)
    depth = 1
    i = paren + 1
    while i < len(text) and depth > 0:
        c = text[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        i += 1
    assert depth == 0, f"[48v2] AboutScreen {title} 括号不平衡"
    end = i
    while end < len(text) and text[end] in " \t":
        end += 1
    if end < len(text) and text[end] == "\n":
        end += 1
    return start, end

# 删 3 行
for title in ["检查更新", "问题反馈", "Telegram 群组"]:
    st, en = find_listrow_block(s, title)
    s = s[:st] + s[en:]
# 删扫码访问段（LinksCard 项，单行）
links_key = 'item(key = "links", contentType = "linksCard") { LinksCard(openUri) }'
assert s.count(links_key) == 1, "[48v2] AboutScreen links 项出现次数 != 1"
s = s.replace(links_key + "\n", "")
# 剩余 6 行重编号（count 9→6）
reindex = [
    ("GitHub 镜像源", 2, 0),
    ("隐私说明", 3, 1),
    ("开源许可", 4, 2),
    ("项目主页", 5, 3),
    ("复制诊断信息", 7, 4),
    ("导出日志文件", 8, 5),
]
for title, old_idx, new_idx in reindex:
    st, en = find_listrow_block(s, title)
    block = s[st:en]
    old_index = f"index = {old_idx},"
    assert block.count(old_index) == 1, f"[48v2] AboutScreen {title} index {old_idx} 在块内出现次数 != 1"
    block = block.replace(old_index, f"index = {new_idx},")
    assert block.count("count = 9,") == 1, f"[48v2] AboutScreen {title} count 9 在块内出现次数 != 1"
    block = block.replace("count = 9,", "count = 6,")
    s = s[:st] + block + s[en:]
# 更新卡片改成移植说明静态卡片：调用点去条件化常显，新增 TransplantCard
# （注意：锚点必须含 UpdateCard 上方的 KDoc/@OptIn/@Composable 三行——2026-11-27
#  首推红的根因：只锚函数签名行，卡片插进了 @Composable 与函数签名之间，
#  致 TransplantCard 叠了两个 @Composable（"not repeatable"），UpdateCard 反而
#  丢了 @Composable，级联 6 错；只含 @OptIn/@Composable 时 KDoc 会错挂到新卡片上。）
old_call = (
    '        if (showCard && info != null) {\n'
    '            item(key = "update", contentType = "updateCard") {\n'
    '                UpdateCard(update, actions, progress)\n'
    '            }\n'
    '        }\n'
)
assert s.count(old_call) == 1, "[48v2] AboutScreen 更新卡片调用点出现次数 != 1"
new_call = (
    '        item(key = "update", contentType = "updateCard") {\n'
    '            TransplantCard()\n'
    '        }\n'
)
s = s.replace(old_call, new_call)
anchor = "/** 新版本卡片：更新说明、下载进度、校验和安装都在这里；下载和安装自动进行，系统对话框确认无法省略。 */\n@OptIn(ExperimentalLayoutApi::class)\n@Composable\nprivate fun UpdateCard(update: UpdateUiState, actions: MusicActions, progress: () -> Float) {"
assert s.count(anchor) == 1, "[48v2] AboutScreen UpdateCard 锚点（含 KDoc/@OptIn/@Composable）出现次数 != 1"
card = '''/** [48v2] 移植说明静态卡片：更新已关闭，此卡不再显示更新内容；文案用户 19:58 定稿。 */
@Composable
private fun TransplantCard() {
    val scheme = MaterialTheme.colorScheme
    val content = scheme.onTertiaryContainer
    Column(
        Modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
            .clip(RoundedCornerShape(28.dp))
            .background(scheme.tertiaryContainer)
            .padding(20.dp),
    ) {
        Text("移植说明", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.ExtraBold, color = content)
        Text(
            "myMusic @ 1c14ca28 · 植入 my.apk",
            style = MaterialTheme.typography.bodyMedium,
            color = content.copy(alpha = 0.85f),
        )
        Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("· 本页 myMusic 由 AVBox 主体植入（源码 mytv-android/myMusic @ 1c14ca28），与原有音乐专区并存，互不影响。", style = MaterialTheme.typography.bodyMedium, color = content)
            Text("· 本版不跟随上游自动更新；正版须去项目主页。", style = MaterialTheme.typography.bodyMedium, color = content)
            Text("· 上方版本号 1.2.3-alpha001（构建 35）是宿主 AVBox 的版本，不是 myMusic 的版本。", style = MaterialTheme.typography.bodyMedium, color = content)
            Text("· AGPL-3.0 开源。", style = MaterialTheme.typography.bodyMedium, color = content)
        }
    }
}

'''
s = s.replace(anchor, card + anchor)
open(path, "w", encoding="utf-8").write(s)
print("[48v2] AboutScreen 已隐藏检查更新/问题反馈/Telegram群组/扫码访问，剩余 6 行已重编号，更新卡片已改移植说明")
PYEOF
else
  info "AboutScreen.kt 无检查更新行，跳过"
fi
MVM="app/src/main/java/com/mytv/mymusic/ui/MusicViewModel.kt"
if grep -F -q "[48v2] 更新已关闭" "${MVM}"; then
  info "MusicViewModel 更新检查已关闭，跳过"
else
  python3 - "${MVM}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = (
    "    private fun checkUpdatesInBackground() {\n"
    "        lastUpdateAttemptAt = SystemClock.elapsedRealtime()\n"
    "        viewModelScope.launch {\n"
    "            app.update.check(manual = false)\n"
    "        }\n"
    "    }\n"
)
assert s.count(old) == 1, "[48v2] MusicViewModel checkUpdatesInBackground 出现次数 != 1"
new = (
    "    private fun checkUpdatesInBackground() {\n"
    "        // [48v2] 更新已关闭：不再自动检查更新\n"
    "    }\n"
)
s = s.replace(old, new)
open(path, "w", encoding="utf-8").write(s)
print("[48v2] MusicViewModel 自动更新检查已关闭")
PYEOF
fi

# 3g. TransplantCard 版本号改动态读取（2026-11-27 用户定“改”）
#     （3f 的卡片里版本号是写死的“1.2.3-alpha001”，而宿主实际已是 alpha002，
#     对不上。改法：TransplantCard 签名加 versionName/versionCode 两个参数，
#     第三句用 $versionName/$versionCode 插值，调用点传
#     update.currentVersionName.ifBlank { "1.0" } 与 update.currentVersionCode，
#     与页眉副标题同一来源；以后宿主再升版，卡片自己跟着变。）
ABOUT="app/src/main/java/com/mytv/mymusic/ui/settings/AboutScreen.kt"
if grep -F -q "private fun TransplantCard(versionName" "${ABOUT}"; then
  info "TransplantCard 版本号已动态，跳过"
else
  python3 - "${ABOUT}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old_sig = "private fun TransplantCard() {"
assert s.count(old_sig) == 1, "[48v3] TransplantCard 签名出现次数 != 1"
s = s.replace(old_sig, "private fun TransplantCard(versionName: String, versionCode: Long) {")
old_line = 'Text("· 上方版本号 1.2.3-alpha001（构建 35）是宿主 AVBox 的版本，不是 myMusic 的版本。", style = MaterialTheme.typography.bodyMedium, color = content)'
assert s.count(old_line) == 1, "[48v3] TransplantCard 版本行出现次数 != 1"
new_line = 'Text("· 上方版本号 $versionName（构建 $versionCode）是宿主 AVBox 的版本，不是 myMusic 的版本。", style = MaterialTheme.typography.bodyMedium, color = content)'
s = s.replace(old_line, new_line)
old_call = "            TransplantCard()"
assert s.count(old_call) == 1, "[48v3] TransplantCard 调用点出现次数 != 1"
new_call = '            TransplantCard(update.currentVersionName.ifBlank { "1.0" }, update.currentVersionCode)'
s = s.replace(old_call, new_call)
open(path, "w", encoding="utf-8").write(s)
print("[48v3] TransplantCard 版本号已改动态读取")
PYEOF
fi

# 3h. 黑胶挂件移植（2026-11-27 用户定“把迷你播放条改成音乐专区旋转黑胶”）
#     （32 v124-v134 最终态 → myMusic PhoneBottomBar.kt：废长条 MiniPlayer，
#      只剩 48dp 可拖动旋转黑胶 + 液态控制台；状态走 MusicUiState/actions.transport，
#      不引 LxPlayerManager；颜色走 MaterialTheme.colorScheme，不写死 Hex；
#      图标用 myMusic 现成 PlayPauseButton + Material SkipPrevious/SkipNext/Close，
#      不抄 32 的手搓 Canvas 图标——myMusic 已有带按压动画的 PlayPauseButton 且全 App
#      都用 Material 图标，手搓是 32 为“禁 Unicode、100% tint”立的特例，此处不适用；
#      三态同 32：点 X 隐藏至下一首、切歌关控制台、无歌隐藏；控制台 Box 内居中（v130，
#      不用 Popup）、吸附用 positionInRoot 相减（v131/v132）、封面点按进播放页（v133）。
#      注意：PhoneBottomBar 根改全尺寸 Box——父级 AnimatedVisibility 为 wrap content，
#      全尺寸根会撑满内容区，导航栏贴底，黑胶宿主覆满整层；covered 时整层随之隐藏。
#      MiniPlayer 的 sharedNowPlayingCover 共享元素随之废弃（黑胶/控制台不参与共享过渡，
#      播放页正常打开、无动画而已）；phoneOverlayHeight 去掉迷你条 64dp（黑胶悬浮不占位）。）
PBB="app/src/main/java/com/mytv/mymusic/ui/adaptive/PhoneBottomBar.kt"
if grep -F -q "[48v4]" "${PBB}"; then
  info "黑胶挂件已移植，跳过"
else
  python3 - "${PBB}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()

def rep(old, new, tag, cnt=1):
    global s
    assert s.count(old) == cnt, "[48v4] 锚点: " + tag + " 数=" + str(s.count(old))
    s = s.replace(old, new, cnt)

# 1) imports：加黑胶要的（锚 import border 行，整行匹配）
rep("import androidx.compose.foundation.border",
"""import androidx.compose.foundation.border
import androidx.compose.animation.core.Animatable // [48v4]
import androidx.compose.animation.core.LinearEasing // [48v4]
import androidx.compose.animation.core.animateOffsetAsState // [48v4]
import androidx.compose.animation.core.tween // [48v4]
import androidx.compose.foundation.BorderStroke // [48v4]
import androidx.compose.foundation.clickable // [48v4]
import androidx.compose.foundation.gestures.detectDragGestures // [48v4]
import androidx.compose.foundation.interaction.MutableInteractionSource // [48v4]
import androidx.compose.foundation.layout.BoxWithConstraints // [48v4]
import androidx.compose.foundation.layout.Spacer // [48v4]
import androidx.compose.foundation.layout.aspectRatio // [48v4]
import androidx.compose.foundation.shape.CircleShape // [48v4]
import androidx.compose.material.icons.filled.Close // [48v4]
import androidx.compose.material.icons.filled.SkipPrevious // [48v4]
import androidx.compose.material3.Surface // [48v4]
import androidx.compose.runtime.LaunchedEffect // [48v4]
import androidx.compose.runtime.mutableStateOf // [48v4]
import androidx.compose.runtime.setValue // [48v4]
import androidx.compose.ui.graphics.graphicsLayer // [48v4]
import androidx.compose.ui.layout.onGloballyPositioned // [48v4]
import androidx.compose.ui.layout.positionInRoot // [48v4]
import androidx.compose.ui.platform.LocalConfiguration // [48v4]
import androidx.compose.ui.zIndex // [48v4]
import com.mytv.mymusic.data.Song // [48v4]
import com.mytv.mymusic.ui.CoverBox // [48v4]""",
    "黑胶 imports")

# 2) imports：删迷你条独占的（逐行整行匹配，未用 import 只报 warning，但随函数一并清）
for line, tag in [
    ("import androidx.compose.ui.semantics.clearAndSetSemantics\n", "clearAndSetSemantics"),
    ("import androidx.compose.animation.slideInVertically\n", "slideInVertically"),
    ("import androidx.compose.animation.slideOutVertically\n", "slideOutVertically"),
    ("import androidx.compose.foundation.ExperimentalFoundationApi\n", "ExperimentalFoundationApi"),
    ("import androidx.compose.foundation.combinedClickable\n", "combinedClickable"),
    ("import androidx.compose.foundation.gestures.detectHorizontalDragGestures\n", "detectHorizontalDragGestures"),
    ("import androidx.compose.foundation.gestures.detectVerticalDragGestures\n", "detectVerticalDragGestures"),
    ("import androidx.compose.material.icons.filled.MyLocation\n", "MyLocation"),
    ("import androidx.compose.runtime.rememberUpdatedState\n", "rememberUpdatedState"),
    ("import androidx.compose.ui.draw.drawBehind\n", "drawBehind"),
    ("import androidx.compose.ui.geometry.Size\n", "Size"),
    ("import androidx.compose.ui.semantics.CustomAccessibilityAction\n", "CustomAccessibilityAction"),
    ("import androidx.compose.ui.semantics.contentDescription\n", "contentDescription"),
    ("import androidx.compose.ui.semantics.customActions\n", "customActions"),
    ("import androidx.compose.ui.semantics.semantics\n", "semantics"),
    ("import androidx.compose.ui.text.font.FontWeight\n", "FontWeight"),
    ("import com.mytv.mymusic.data.MiniPlayerTarget\n", "MiniPlayerTarget"),
    ("import com.mytv.mymusic.ui.openLabel\n", "openLabel"),
    ("import com.mytv.mymusic.ui.components.PlayButtonSize\n", "PlayButtonSize"),
    ("import com.mytv.mymusic.ui.components.rememberSettlingOffsetState\n", "rememberSettlingOffsetState"),
    ("import com.mytv.mymusic.ui.components.sharedNowPlayingCover\n", "sharedNowPlayingCover"),
    ("import kotlin.math.abs\n", "abs"),
]:
    assert s.count(line) == 1, "[48v4] 删 import 锚点: " + tag + " 数=" + str(s.count(line))
    s = s.replace(line, "")

# 3) 常量：MiniHeight/MiniGap 随迷你条废弃（只在本文件用）
rep("private val MiniHeight = 64.dp\nprivate val MiniGap = 8.dp\n", "", "删 MiniHeight/MiniGap")

# 4) phoneOverlayHeight：迷你条 64dp 去掉（黑胶悬浮不占位）
rep(""" * 浮层总高度（不含系统导航栏），列表底部要让出这么多。
 * 有歌在播时是迷你播放器 + 短导航栏；没歌在播时只有浮动导航条，它离底边还有 16dp。
 */
fun phoneOverlayHeight(hasMini: Boolean): Dp =
    if (hasMini) NavBarHeight + MiniHeight + MiniGap * 2 else NavBarHeight + FloatingMargin""",
""" * 浮层总高度（不含系统导航栏），列表底部要让出这么多。
 * [48v4] 长条迷你播放器已废，黑胶悬浮不占位：有歌时只剩短导航栏；
 * 没歌时只有浮动导航条，它离底边还有 16dp。
 */
fun phoneOverlayHeight(hasMini: Boolean): Dp =
    if (hasMini) NavBarHeight else NavBarHeight + FloatingMargin""",
    "phoneOverlayHeight 去迷你条高度")

# 5) PhoneBottomBar 体：Column + 迷你条 AnimatedVisibility → 全尺寸 Box + 黑胶宿主 + 贴底导航栏
rep("""    Column(modifier.fillMaxWidth()) {
        AnimatedVisibility(
            visible = state.current != null,
            enter = slideInVertically { it } + fadeIn(),
            exit = slideOutVertically { it } + fadeOut(),
        ) {
            MiniPlayer(state, position, actions, onOpenQueue, Modifier.padding(horizontal = 12.dp, vertical = MiniGap))
        }
""",
"""    // [48v4] 黑胶挂件要全屏浮层：根改全尺寸 Box，导航栏贴底，黑胶宿主覆满整层
    Box(modifier.fillMaxSize()) {
        VinylHost(state, position, actions, Modifier.fillMaxSize())
        Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth()) {
""",
    "PhoneBottomBar 根改 Box + 黑胶宿主")

# 6) PhoneBottomBar 尾：补内层 Column 的闭合（锚点含浮动导航条 KDoc，整行匹配）
rep("""        }
    }
}

/** 浮动导航条一项的宽""",
"""        }
        }
    }
}

/** 浮动导航条一项的宽""",
    "PhoneBottomBar 尾补闭合")

# 6b) 缩进修正：第 5 步只换了头，内层 Column 里的 if/导航栏仍是旧缩进（少 4 空格，
#     编译不报错但难读）。按花括号配对找到内层 Column 的起止，把中间行统一 +4 空格。
col_open = "        Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth()) {"
assert s.count(col_open) == 1, "[48v4] 内层 Column 锚点数=" + str(s.count(col_open))
lines = s.split("\n")
ci = next(i for i, l in enumerate(lines) if l == col_open)
depth = 0
cj = None
for j in range(ci, len(lines)):
    depth += lines[j].count("{") - lines[j].count("}")
    if j > ci and depth == 0:
        cj = j
        break
assert cj is not None, "[48v4] 内层 Column 闭合未找到"
for k in range(ci + 1, cj):
    if lines[k].strip():
        lines[k] = "    " + lines[k]
s = "\n".join(lines)

# 7) MiniPlayer + miniPlayerProgress（文件尾）整体换黑胶三件套
start_mark = """/**
 * 悬浮胶囊迷你播放器。点按按设置打开播放页或海报墙，左滑下一首、右滑打开来源歌单并定位当前歌曲，
 * 上滑总是展开播放页，长按打开队列；手势都有对应的按钮或读屏自定义操作，读屏用户不需要手势。
 */"""
assert s.count(start_mark) == 1, "[48v4] MiniPlayer 起始锚点数=" + str(s.count(start_mark))
si = s.index(start_mark)
old_tail = s[si:]
assert "fun MiniPlayer(" in old_tail and "miniPlayerProgress" in old_tail, "[48v4] MiniPlayer 范围校验失败"
new_code = '''// [48v4] 黑胶宿主：全屏 BoxWithConstraints + 三态（点 X 隐藏至下一首、切歌关控制台、无歌隐藏，
// 同 32 v124）；控制台 Box 内居中（v130，不用 Popup）；吸附用 positionInRoot 相减（v131/v132）。
@Composable
private fun VinylHost(
    state: MusicUiState,
    position: State<Long>,
    actions: MusicActions,
    modifier: Modifier = Modifier,
) {
    val song = state.current
    val progress = if (song != null && state.duration > 0) (position.value.toFloat() / state.duration.toFloat()).coerceIn(0f, 1f) else 0f
    var vinylDismissed by remember { mutableStateOf(false) }
    var showVinylConsole by remember { mutableStateOf(false) }
    var cardPosInBox by remember { mutableStateOf<Offset?>(null) }
    var boxRootPos by remember { mutableStateOf(Offset.Zero) }
    LaunchedEffect(song?.key) {
        if (song != null) vinylDismissed = false
        if (song == null) showVinylConsole = false
    }
    BoxWithConstraints(
        modifier = modifier.fillMaxSize()
            .onGloballyPositioned { boxRootPos = it.positionInRoot() }
    ) {
        val density = LocalDensity.current
        val maxWpx = with(density) { maxWidth.toPx() }
        val maxHpx = with(density) { maxHeight.toPx() }
        val sizePx = with(density) { 48.dp.toPx() }
        var vinylOffset by remember { mutableStateOf<Offset?>(null) }
        val vinylPos = vinylOffset ?: Offset(
            maxWpx - sizePx - with(density) { 16.dp.toPx() },
            maxHpx - sizePx - with(density) { 80.dp.toPx() }
        )
        var isDragging by remember { mutableStateOf(false) }
        val snapInset = with(density) { 12.dp.toPx() }
        val snapTarget: Offset? = if (showVinylConsole) {
            cardPosInBox?.let { pos ->
                Offset(
                    (pos.x - snapInset).coerceIn(0f, maxWpx - sizePx),
                    (pos.y - snapInset).coerceIn(0f, maxHpx - sizePx)
                )
            }
        } else null
        val animatedPos by animateOffsetAsState(
            targetValue = snapTarget ?: vinylPos,
            animationSpec = tween(durationMillis = 300), label = "vinylSnap"
        )
        val displayPos = if (isDragging) vinylPos else animatedPos
        if (showVinylConsole) {
            Box(
                modifier = Modifier.fillMaxSize()
                    .clickable(
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() }
                    ) { showVinylConsole = false }
            )
        }
        AnimatedVisibility(
            visible = showVinylConsole,
            enter = fadeIn(tween(200)),
            exit = fadeOut(tween(200)),
            modifier = Modifier.align(Alignment.Center)
                .onGloballyPositioned { cardPosInBox = it.positionInRoot() - boxRootPos }
        ) {
            if (song != null) {
                VinylConsole(
                    song = song,
                    isPlaying = state.playing,
                    progress = progress,
                    onPrev = { actions.transport("previous") },
                    onNext = { actions.transport("next") },
                    onTogglePlay = { actions.transport("play") },
                    onClose = {
                        showVinylConsole = false
                        vinylDismissed = true
                        if (state.playing) actions.transport("play")
                    },
                    onCoverClick = {
                        showVinylConsole = false
                        actions.openPlayer()
                    },
                )
            }
        }
        if (song != null && !vinylDismissed) {
            VinylWidget(
                song = song,
                isPlaying = state.playing,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset { IntOffset(displayPos.x.roundToInt(), displayPos.y.roundToInt()) }
                    .zIndex(1f)
                    .pointerInput(Unit) {
                        detectDragGestures(
                            onDragStart = { isDragging = true; showVinylConsole = false },
                            onDrag = { change, dragAmount ->
                                change.consume()
                                vinylOffset = Offset(
                                    (vinylPos.x + dragAmount.x).coerceIn(0f, maxWpx - sizePx),
                                    (vinylPos.y + dragAmount.y).coerceIn(0f, maxHpx - sizePx)
                                )
                            },
                            onDragEnd = { isDragging = false }
                        )
                    },
                onClick = { showVinylConsole = true }
            )
        }
    }
}

// [48v4] 悬浮黑胶挂件：48dp 圆形封面 + 匀速旋转（Animatable，暂停留角）
@Composable
private fun VinylWidget(
    song: Song,
    isPlaying: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val rotation = remember { Animatable(0f) }
    LaunchedEffect(isPlaying) {
        if (isPlaying) {
            while (true) {
                rotation.animateTo(
                    rotation.value + 360f,
                    tween(durationMillis = 15000, easing = LinearEasing)
                )
            }
        }
    }
    Box(
        modifier = modifier
            .size(48.dp)
            .clip(CircleShape)
            .border(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.25f), CircleShape)
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Cover(
            url = song.cover,
            key = song.title,
            size = 48.dp,
            modifier = Modifier.graphicsLayer { rotationZ = rotation.value },
            shape = CircleShape,
        )
    }
}

// [48v4] 液态控制台：surfaceContainer 0.85 + extraLarge + 描边 + shadow 16；
// 顶行“正在播放”+ X，封面 0.7f 居中可点进播放页，进度条紧贴封面，底行上一首/播放/下一曲 40/56/40 对称。
@Composable
private fun VinylConsole(
    song: Song,
    isPlaying: Boolean,
    progress: Float,
    onPrev: () -> Unit,
    onNext: () -> Unit,
    onTogglePlay: () -> Unit,
    onClose: () -> Unit,
    onCoverClick: () -> Unit,
) {
    val screenW = LocalConfiguration.current.screenWidthDp.dp
    val cardW = screenW - 72.dp
    Surface(
        modifier = Modifier.width(cardW).shadow(16.dp, MaterialTheme.shapes.extraLarge),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer.copy(alpha = 0.85f),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.25f))
    ) {
        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 20.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "正在播放",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                IconButton(onClick = onClose, modifier = Modifier.size(40.dp)) {
                    Icon(Icons.Filled.Close, "关闭", tint = MaterialTheme.colorScheme.onSurface)
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            CoverBox(
                url = song.cover,
                key = song.title,
                modifier = Modifier.fillMaxWidth(0.7f).align(Alignment.CenterHorizontally).aspectRatio(1f).clickable(onClick = onCoverClick),
                shape = RoundedCornerShape(16.dp),
            )
            Spacer(modifier = Modifier.height(8.dp))
            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(MaterialTheme.colorScheme.outlineVariant)) {
                Box(
                    modifier = Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).height(2.dp)
                        .background(MaterialTheme.colorScheme.primary)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onPrev, modifier = Modifier.size(40.dp)) {
                    Icon(Icons.Filled.SkipPrevious, "上一首", tint = MaterialTheme.colorScheme.onSurface)
                }
                PlayPauseButton(isPlaying, onTogglePlay)
                IconButton(onClick = onNext, modifier = Modifier.size(40.dp)) {
                    Icon(Icons.Filled.SkipNext, "下一首", tint = MaterialTheme.colorScheme.onSurface)
                }
            }
        }
    }
}
'''
s = s[:si] + new_code
# 括号平衡校验
assert s.count("(") == s.count(")"), "[48v4] 括号不平衡 ( " + str(s.count("(")) + "/" + str(s.count(")")) + ")"
assert s.count("{") == s.count("}"), "[48v4] 花括号不平衡 { " + str(s.count("{")) + "/" + str(s.count("}")) + "}"
open(path, "w", encoding="utf-8").write(s)
print("[48v4] 黑胶挂件已移植：MiniPlayer 已废，VinylHost/VinylWidget/VinylConsole 已接")
PYEOF
fi

# 3i. 液态控制台显示歌名/歌手（2026-11-27 用户定“显示歌名”）
#     （3h 的控制台只有“正在播放”+ 封面，不显示歌名/歌手。改法：在封面与进度条之间
#     加两行居中文字：歌名 titleMedium SemiBold、歌手 bodyMedium onSurfaceVariant，
#     各单行省略；song 已是 VinylConsole 入参（song: Song），直接取 song.title/song.artist。）
PBAR="app/src/main/java/com/mytv/mymusic/ui/adaptive/PhoneBottomBar.kt"
if grep -F -q "text = song.title" "${PBAR}"; then
  info "控制台已显示歌名，跳过"
else
  python3 - "${PBAR}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = (
    "            Spacer(modifier = Modifier.height(8.dp))\n"
    "            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(MaterialTheme.colorScheme.outlineVariant)) {"
)
assert s.count(old) == 1, "[48v5] 控制台封面-进度锚点出现次数 != 1"
new = (
    "            Spacer(modifier = Modifier.height(12.dp))\n"
    "            Text(\n"
    "                text = song.title,\n"
    "                style = MaterialTheme.typography.titleMedium,\n"
    "                fontWeight = FontWeight.SemiBold,\n"
    "                color = MaterialTheme.colorScheme.onSurface,\n"
    "                maxLines = 1,\n"
    "                overflow = TextOverflow.Ellipsis,\n"
    "                textAlign = TextAlign.Center,\n"
    "                modifier = Modifier.fillMaxWidth(),\n"
    "            )\n"
    "            Text(\n"
    "                text = song.artist,\n"
    "                style = MaterialTheme.typography.bodyMedium,\n"
    "                color = MaterialTheme.colorScheme.onSurfaceVariant,\n"
    "                maxLines = 1,\n"
    "                overflow = TextOverflow.Ellipsis,\n"
    "                textAlign = TextAlign.Center,\n"
    "                modifier = Modifier.fillMaxWidth(),\n"
    "            )\n"
    "            Spacer(modifier = Modifier.height(8.dp))\n"
    "            Box(modifier = Modifier.fillMaxWidth().height(2.dp).background(MaterialTheme.colorScheme.outlineVariant)) {"
)
s = s.replace(old, new)
open(path, "w", encoding="utf-8").write(s)
print("[48v5] 控制台已显示歌名/歌手")
PYEOF
fi

# 3j. 控制台封面点击跟随“点按迷你播放器打开”设置（2026-11-27 用户问“迷你播放器和这些没通吗”）
#     （3h 的 onCoverClick 写死 actions.openPlayer()，绕过了 miniPlayerTarget 设置；
#     用户选了海报墙，点封面仍进播放页。改法：改调 actions.openNowPlaying()，
#     它按设置分流（Player→openPlayer，PosterWall→openPosterWall），与原 MiniPlayer
#     点按行为一致；上滑黑胶仍直通播放页，不动。）
PBAR="app/src/main/java/com/mytv/mymusic/ui/adaptive/PhoneBottomBar.kt"
if grep -F -q "actions.openNowPlaying()" "${PBAR}"; then
  info "控制台封面点击已跟随设置，跳过"
else
  python3 - "${PBAR}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = (
    "                    onCoverClick = {\n"
    "                        showVinylConsole = false\n"
    "                        actions.openPlayer()\n"
    "                    },"
)
assert s.count(old) == 1, "[48v6] onCoverClick 锚点出现次数 != 1"
new = (
    "                    onCoverClick = {\n"
    "                        showVinylConsole = false\n"
    "                        actions.openNowPlaying()\n"
    "                    },"
)
s = s.replace(old, new)
open(path, "w", encoding="utf-8").write(s)
print("[48v6] 控制台封面点击已跟随“点按迷你播放器打开”设置")
PYEOF
fi

# 3k. 车载蓝牙歌词默认开（2026-11-27 用户定“借”）
#     （实测：v89 已有完整机制——MusicViewModel.syncNotificationLyrics 每 100ms 进度 tick
#     取当前歌词行，setMediaArtist 用 player.replaceMediaItem 只换 artist（歌名/专辑/封面
#     不动、HLS/DASH 跳过、切歌与无歌词时恢复真歌手），唯一缺口是开关 notificationLyrics
#     默认 false。改法：三处默认值 false→true（AppStore DataStore 读默认、AppStore
#     Settings 数据类默认、MusicViewModel UI state 默认），注释“默认关”→“默认开”；
#     设置页开关保留，用户可手动关；已明确关过的用户 DataStore 存 false，不受默认值影响。）
STORE="app/src/main/java/com/mytv/mymusic/data/AppStore.kt"
if grep -F -q "notificationLyrics = values[notificationLyricsKey] ?: true" "${STORE}"; then
  info "通知歌词默认已开，跳过"
else
  python3 - "${STORE}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old1 = "            notificationLyrics = values[notificationLyricsKey] ?: false,"
assert s.count(old1) == 1, "[48v7] AppStore DataStore 读默认锚点出现次数 != 1"
s = s.replace(old1, "            notificationLyrics = values[notificationLyricsKey] ?: true,")
old2 = (
    "    /** 系统媒体播放条第二行显示当前歌词（顶掉歌手名）；默认关。 */\n"
    "    val notificationLyrics: Boolean = false,"
)
assert s.count(old2) == 1, "[48v7] AppStore 数据类默认锚点出现次数 != 1"
s = s.replace(old2, (
    "    /** 系统媒体播放条第二行显示当前歌词（顶掉歌手名）；默认开。 */\n"
    "    val notificationLyrics: Boolean = true,"
))
open(path, "w", encoding="utf-8").write(s)
print("[48v7] AppStore 通知歌词默认已开")
PYEOF
fi
MVM="app/src/main/java/com/mytv/mymusic/ui/MusicViewModel.kt"
if grep -F -q "val notificationLyrics: Boolean = true" "${MVM}"; then
  info "MusicViewModel 通知歌词默认已开，跳过"
else
  python3 - "${MVM}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = "    val notificationLyrics: Boolean = false,"
assert s.count(old) == 1, "[48v7] MusicViewModel UI state 默认锚点出现次数 != 1"
s = s.replace(old, "    val notificationLyrics: Boolean = true,")
open(path, "w", encoding="utf-8").write(s)
print("[48v7] MusicViewModel 通知歌词默认已开")
PYEOF
fi

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
#   - MaterialKolor 统一到 6.0.0（2026-11-27 第十轮 CI 红根因：5.0.1 的 material-kolor
#     与 6.0.0 的 material-kolor-core-android 同含 Contrast/MaterialKolors，
#     checkDebugDuplicateClasses 报错。不同坐标不能共存，必须统一版本。
#     改法：AVBox 现有 materialKolor 版本键 5.0.1 -> 6.0.0，materialkolor 别名
#     模块 material-kolor -> material-kolor-material3；myMusic 的两个别名改指
#     同一版本键 materialKolor，不再另起 materialKolor6）；
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
    ("material-kolor-material3", "com.materialkolor:material-kolor-material3", "materialKolor"),
    ("material-kolor-palette", "com.materialkolor:material-kolor-palette", "materialKolor"),
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

# 7.7 AppThemeState.kt：PaletteStyle.valueOf 在 MaterialKolor 6.0.0 解析下不可用
#     （2026-11-27 第七轮 CI 红根因之三：AppThemeState.kt:34 两错——Cannot infer 'R' 与
#     Unresolved reference 'valueOf'。48 脚本引入的 material-kolor 6.0.0 与 AVBox 自带
#     的 5.0.1 同含 com.materialkolor.PaletteStyle，解析到的 6.0.0 版无 valueOf。
#     改法：把 valueOf(<arg>) 换成按名字查表的 when 表达式（枚举与密封类都适用），
#     不依赖 valueOf。括号平衡扫描处理嵌套括号。）
ATS="app/src/main/java/com/github/avbox/osc/ui/theme/AppThemeState.kt"
if [ -f "${ATS}" ]; then
  if grep -F -q "PaletteStyle.valueOf(" "${ATS}"; then
    python3 - "${ATS}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
key = "PaletteStyle.valueOf("
assert s.count(key) == 1, "[48v1] AppThemeState.kt PaletteStyle.valueOf 出现次数 != 1"
idx = s.find(key)
start = idx + len(key)
depth = 1
i = start
while i < len(s) and depth > 0:
    if s[i] == "(":
        depth += 1
    elif s[i] == ")":
        depth -= 1
    i += 1
assert depth == 0, "[48v1] AppThemeState.kt valueOf 括号不平衡"
arg = s[start:i-1]
when_expr = (
    "when (" + arg + ") {\n"
    '        "TonalSpot" -> PaletteStyle.TonalSpot\n'
    '        "Vibrant" -> PaletteStyle.Vibrant\n'
    '        "Expressive" -> PaletteStyle.Expressive\n'
    '        "Fidelity" -> PaletteStyle.Fidelity\n'
    '        "Content" -> PaletteStyle.Content\n'
    '        "Rainbow" -> PaletteStyle.Rainbow\n'
    '        "FruitSalad" -> PaletteStyle.FruitSalad\n'
    "        else -> DefaultPaletteStyle\n"
    "    }"
)
s = s[:idx] + when_expr + s[i:]
open(path, "w", encoding="utf-8").write(s)
print("[48v1] AppThemeState.kt PaletteStyle.valueOf 已换 when 查表")
PYEOF
  else
    info "AppThemeState.kt 无 PaletteStyle.valueOf 调用，跳过"
  fi
else
  echo "[48] 警告：AppThemeState.kt 不在 ${ATS}，未修 valueOf（[未核实]路径）" >&2
fi

# 7.8 MaterialKolor 统一到 6.0.0（2026-11-27 第十轮 CI 红根因）
#     :app:checkDebugDuplicateClasses 报 Duplicate class Contrast/MaterialKolors——
#     5.0.1 的 material-kolor 与 6.0.0 的 material-kolor-core-android 同含这些类。
#     改法：AVBox 现有 materialKolor 版本键 5.0.1 -> 6.0.0；materialkolor 别名模块
#     material-kolor -> material-kolor-material3（6.0.0 已拆包，旧坐标不存在）；
#     AppThemeState.kt 的 dynamicColorScheme 导入改到 material3 子包（6.0.0 的
#     material3.dynamicColorScheme(seedColor/isDark/style) 签名与 5.0.1 顶层函数
#     一致，其余参数均有默认值，调用点不用改；PaletteStyle 仍在顶层包，不动）。
python3 - "${CATALOG}" <<'PYEOF'
import sys, re
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
# 版本键：materialKolor = "5.0.1" -> "6.0.0"（已是 6.0.0 则跳过）
if re.search(r'^materialKolor\s*=\s*"6\.0\.0"\s*$', s, re.M):
    print("[48v1] materialKolor 已是 6.0.0，跳过")
else:
    assert len(re.findall(r'^materialKolor\s*=\s*"5\.0\.1"\s*$', s, re.M)) == 1, "[48v1] catalog materialKolor 5.0.1 不是唯一"
    s = re.sub(r'^materialKolor\s*=\s*"5\.0\.1"\s*$', 'materialKolor = "6.0.0"', s, count=1, flags=re.M)
    print("[48v1] materialKolor 5.0.1 已升 6.0.0")
# 别名：materialkolor 的 name "material-kolor" -> "material-kolor-material3"（已改则跳过）
if re.search(r'^materialkolor\s*=\s*\{[^}]*name\s*=\s*"material-kolor-material3"', s, re.M):
    print("[48v1] materialkolor 别名已指 material-kolor-material3，跳过")
else:
    m = re.findall(r'^materialkolor\s*=\s*\{[^}]*name\s*=\s*"material-kolor"', s, re.M)
    assert len(m) == 1, "[48v1] catalog materialkolor 别名（material-kolor）不是唯一"
    s = re.sub(r'(^materialkolor\s*=\s*\{[^}]*name\s*=\s*)"material-kolor"', r'\1"material-kolor-material3"', s, count=1, flags=re.M)
    print("[48v1] materialkolor 别名已改指 material-kolor-material3")
open(path, "w", encoding="utf-8").write(s)
PYEOF
if [ -f "${ATS}" ]; then
  if grep -F -q "import com.materialkolor.material3.dynamicColorScheme" "${ATS}"; then
    info "AppThemeState.kt 已用 material3.dynamicColorScheme，跳过"
  else
    assert_count "${ATS}" "import com.materialkolor.dynamicColorScheme" 1 "AppThemeState.kt 顶层 dynamicColorScheme 导入"
    python3 - "${ATS}" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
old = "import com.materialkolor.dynamicColorScheme"
assert s.count(old) == 1, "[48v1] AppThemeState.kt 顶层 dynamicColorScheme 导入出现次数 != 1"
s = s.replace(old, "import com.materialkolor.material3.dynamicColorScheme")
open(path, "w", encoding="utf-8").write(s)
print("[48v1] AppThemeState.kt dynamicColorScheme 已改 material3 子包")
PYEOF
  fi
else
  echo "[48] 警告：AppThemeState.kt 不在 ${ATS}，未修 dynamicColorScheme 导入（[未核实]路径）" >&2
fi

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
# 9.1c lib-runtime-lx 的 Java/Kotlin JVM 目标对齐到 21（与 AVBox app 一致）：
#      9.1b 补了 kotlin.android 插件后，Kotlin 编译任务默认 jvmTarget=21（跟随 JDK 21），
#      而模块无 compileOptions、Java 编译任务默认 11——Gradle 报 Inconsistent JVM Target
#      Compatibility（2026-11-27 第六轮 CI 红根因，:lib-runtime-lx:compileDebugKotlin）。
#      AVBox app 为 Java 21 / JVM_21，此处对齐到 21（不用 myMusic 的 17，以宿主工程为准）。
python3 - "${AVBOX_DIR}/lib-runtime-lx/build.gradle.kts" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
lines = s.split("\n")
if "sourceCompatibility = JavaVersion.VERSION_21" in s:
    print("[48v1] lib-runtime-lx compileOptions 已存在，跳过")
else:
    idx = [i for i, ln in enumerate(lines) if ln.strip() == "android {"]
    assert len(idx) == 1, "[48v1] lib-runtime-lx android { 不是唯一"
    ai = idx[0]
    co = [
        "    compileOptions {",
        "        sourceCompatibility = JavaVersion.VERSION_21",
        "        targetCompatibility = JavaVersion.VERSION_21",
        "    }",
    ]
    lines[ai+1:ai+1] = co
    s = "\n".join(lines)
    lines = s.split("\n")
    print("[48v1] lib-runtime-lx compileOptions 已加：Java 21")
if "jvmTarget" in s:
    print("[48v1] lib-runtime-lx jvmTarget 已存在，跳过")
else:
    kb = [
        "",
        "kotlin {",
        "    compilerOptions {",
        "        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)",
        "    }",
        "}",
    ]
    lines.extend(kb)
    s = "\n".join(lines)
    print("[48v1] lib-runtime-lx kotlin jvmTarget 已加：JVM_21")
open(path, "w", encoding="utf-8").write(s)
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
grep -F -q "import com.github.avbox.osc.R" "app/src/main/java/com/mytv/mymusic/ui/components/ProviderIcon.kt" || grep -F -q "import com.github.tvbox.osc.R" "app/src/main/java/com/mytv/mymusic/ui/components/ProviderIcon.kt" || die "收尾：ProviderIcon.kt 无 app R 直接导入"
[ ! -f "app/src/main/java/com/mytv/mymusic/R.kt" ] || die "收尾：旧 R.kt typealias 文件仍在"
grep -F -q "DefaultTogglePadding" "app/src/main/java/com/mytv/mymusic/ui/components/Buttons.kt" || die "收尾：Buttons.kt 无 DefaultTogglePadding"
grep -F -q "import androidx.compose.material3.SplitButtonLayout" "app/src/main/java/com/mytv/mymusic/ui/library/LibraryScreen.kt" || die "收尾：LibraryScreen.kt 无 SplitButtonLayout 导入"
if grep -q '^import androidx.compose.material3.SplitButton$' "app/src/main/java/com/mytv/mymusic/ui/library/LibraryScreen.kt"; then die "收尾：LibraryScreen.kt 仍有 SplitButton 导入"; fi
grep -q '^materialKolor = "6.0.0"$' "gradle/libs.versions.toml" || die "收尾：catalog materialKolor 不是 6.0.0"
if grep -q 'name = "material-kolor"' "gradle/libs.versions.toml"; then die "收尾：catalog 仍有旧 material-kolor 坐标"; fi
grep -F -q "import com.materialkolor.material3.dynamicColorScheme" "app/src/main/java/com/github/avbox/osc/ui/theme/AppThemeState.kt" || die "收尾：AppThemeState.kt 未用 material3.dynamicColorScheme"
if grep -F -q "PaletteStyle.valueOf(" "app/src/main/java/com/github/avbox/osc/ui/theme/AppThemeState.kt"; then die "收尾：AppThemeState.kt 仍有 PaletteStyle.valueOf"; fi
grep -F -q 'ExperimentalMaterial3Api' "${APPBG}" || die "收尾：app 无 material3 opt-in"
grep -F -q 'alias(libs.plugins.kotlin.android)' "${AVBOX_DIR}/lib-runtime-lx/build.gradle.kts" || die "收尾：lib-runtime-lx 无 kotlin.android 插件"
grep -F -q 'jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)' "${AVBOX_DIR}/lib-runtime-lx/build.gradle.kts" || die "收尾：lib-runtime-lx 无 jvmTarget JVM_21"
grep -F -q 'sourceCompatibility = JavaVersion.VERSION_21' "${AVBOX_DIR}/lib-runtime-lx/build.gradle.kts" || die "收尾：lib-runtime-lx 无 Java 21 compileOptions"
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
