#!/bin/bash
# 模块七（首页 6 个交互：换站 / 换源 / 搜索 / 观看历史）的独立验收：
# 不经过测试框架，直接调编译产物。
#
# 跑法： bash acceptance/run-interaction.sh
#
# 步骤：
#   1. 导出单元测试运行时 classpath（含 main/test 编译产物，AAR 已自动拆 classes.jar）
#   2. 编译最小 android 桩类（纯 JVM 没有 android 运行时）
#   3. 裸 JVM 跑验收 Runner，classpath 顺序 = 桩 > 测试 classpath
#
# 注：JDK 用 home 里那份完整 JDK。系统 /usr/lib/jvm 下那份的 conf/security/java.security
#     是断链，会 InternalError: Error loading java.security file。
set -e

# 需要一个"完整"的 JDK 17：有些发行版里 conf/security/java.security 是断链，
# 会报 InternalError: Error loading java.security file。先认 JAVA_HOME，再扫常见安装位置。
JDK_HOME=""
if [ -n "${JAVA_HOME:-}" ] && [ -f "$JAVA_HOME/conf/security/java.security" ]; then
    JDK_HOME="$JAVA_HOME"
else
    for cand in "$HOME"/jdk17/* "$HOME"/jdk/* "$HOME"/.jdks/* /usr/lib/jvm/*; do
        if [ -f "$cand/conf/security/java.security" ]; then
            JDK_HOME="$cand"
            break
        fi
    done
fi
if [ -z "$JDK_HOME" ]; then
    echo "找不到可用的完整 JDK 17，请先 export JAVA_HOME=<你的 jdk17 目录>"
    exit 1
fi
export JAVA_HOME="$JDK_HOME"
# Gradle 缓存目录：默认 ~/.gradle，想用别的就 export GRADLE_USER_HOME
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
echo "== 工程根目录: $ROOT"

echo "== 1/3 导出测试运行时 classpath（顺带编译 test 源集，Runner 在里面）"
./gradlew :app:compileDebugUnitTestKotlin dumpTestClasspath --console=plain --no-daemon -q

echo "== 2/3 编译 android 桩类"
STUB_SRC="$ROOT/acceptance/stubs"
STUB_OUT="$ROOT/acceptance/stub-classes"
rm -rf "$STUB_OUT"
mkdir -p "$STUB_OUT"
shopt -s globstar nullglob
STUB_FILES=("$STUB_SRC"/**/*.java)
javac -nowarn -d "$STUB_OUT" "${STUB_FILES[@]}"
echo "   编译了 ${#STUB_FILES[@]} 个桩文件"

echo "== 3/3 跑独立验收"
java -cp "$STUB_OUT:$(cat "$ROOT/app/build/test-classpath.txt")" \
    com.tvbox.shell.ui.home.InteractionAcceptanceRunnerKt
