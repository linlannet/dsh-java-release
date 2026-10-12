#!/usr/bin/env bash
#
# 一键打包：从相邻仓库（../dsh-java、../dsh-java-plugins）的 target 目录收集构件，
# 组装到 ./dist 运行目录：
#
#   dist/
#   ├── dsh-java-app.jar          ← dsh-java/dsh-java-app 的 exec fat jar
#   ├── apps/                     ← 四个插件的 app（exec fat jar，可独立运行）
#   │   ├── dsh-java-mysql-app.jar       (8091)
#   │   ├── dsh-java-mall-app.jar        (8092)
#   │   ├── dsh-java-oceanbase-app.jar   (8093)
#   │   └── dsh-java-dameng-app.jar      (8094)
#   ├── plugins/                  ← 四个插件 jar（Harness 配置 plugins.install-root: ./plugins）
#   │   ├── dsh-java-mysql-plugin.jar
#   │   ├── dsh-java-oceanbase-plugin.jar
#   │   ├── dsh-java-dameng-plugin.jar
#   │   └── dsh-java-mall-plugin.jar
#   ├── workspaces/               ← 空目录，Harness 配置 workspace.root: ./workspaces
#   └── start.sh                  ← 启动脚本
#
# 仓库根目录保留 dsh-java-app.jar、apps/ 与 plugins/（后两者会原样拷入 dist/）。
#
# 用法：
#   ./package.sh            仅打包（要求各模块已执行 mvn package）
#   ./package.sh --build    先执行 mvn package -DskipTests 再打包
#   ./package.sh -h         查看帮助
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DSH_JAVA_DIR="${DSH_JAVA_DIR:-${SCRIPT_DIR}/../dsh-java}"
PLUGINS_DIR="${PLUGINS_DIR:-${SCRIPT_DIR}/../dsh-java-plugins}"
DIST_DIR="${SCRIPT_DIR}/dist"
PLUGINS="mysql oceanbase dameng mall"

usage() {
  cat <<'EOF'
Usage: ./package.sh [--build]

Options:
  --build     先在两个源仓库执行 mvn package -DskipTests，再收集产物
  -h, --help  显示本帮助

产物目录：dist/（dsh-java-app.jar + apps/ + plugins/ + start.sh）
EOF
}

BUILD=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) BUILD=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ "${BUILD}" == true ]]; then
  if ! command -v mvn >/dev/null 2>&1; then
    echo "未找到 mvn，请先安装 Maven 3.9+" >&2
    exit 1
  fi
  echo "构建 dsh-java ..."
  (cd "${DSH_JAVA_DIR}" && mvn package -DskipTests -q)
  echo "构建 dsh-java-plugins ..."
  (cd "${PLUGINS_DIR}" && mvn package -DskipTests -q)
fi

# 在指定目录中按 find 条件挑选 jar（取版本号最大的一个）
find_jar() {
  local dir="$1"; shift
  [[ -d "${dir}" ]] || return 0
  find "${dir}" -maxdepth 1 -type f "$@" -print 2>/dev/null | sort | tail -1
}

MISSING=()
copy_jar() {
  local src="$1" dst="$2" label="$3"
  if [[ -z "${src}" || ! -f "${src}" ]]; then
    MISSING+=("${label}")
    return 0
  fi
  cp "${src}" "${dst}"
  echo "  ${label}  ->  ${dst#${SCRIPT_DIR}/}"
}

echo "收集构件到 ${SCRIPT_DIR} ..."
mkdir -p "${SCRIPT_DIR}/apps" "${SCRIPT_DIR}/plugins"

# 1) dsh-java 主程序：exec fat jar 放到与 apps/ 同级的目录，改名为 dsh-java-app.jar
APP_JAR="$(find_jar "${DSH_JAVA_DIR}/dsh-java-app/target" -name 'dsh-java-app-*-exec.jar')"
copy_jar "${APP_JAR}" "${SCRIPT_DIR}/dsh-java-app.jar" "dsh-java-app (exec)"

# 2) 四个插件：app 的 exec fat jar 放到 apps/，plugin 瘦 jar 放到 plugins/
for name in ${PLUGINS}; do
  APP_SRC="$(find_jar "${PLUGINS_DIR}/dsh-java-${name}/dsh-java-${name}-app/target" \
    -name "dsh-java-${name}-app-*-exec.jar")"
  copy_jar "${APP_SRC}" "${SCRIPT_DIR}/apps/dsh-java-${name}-app.jar" "dsh-java-${name}-app (exec)"

  PLUGIN_SRC="$(find_jar "${PLUGINS_DIR}/dsh-java-${name}/dsh-java-${name}-plugin/target" \
    -name "dsh-java-${name}-plugin-*.jar" \
    ! -name '*-exec.jar' ! -name '*sources.jar' ! -name '*javadoc.jar')"
  copy_jar "${PLUGIN_SRC}" "${SCRIPT_DIR}/plugins/dsh-java-${name}-plugin.jar" "dsh-java-${name}-plugin"
done

# 3) 早期版本把 app 与 plugin 混放在 resources/，这里清理掉旧目录
if [[ -d "${SCRIPT_DIR}/resources" ]]; then
  rm -rf "${SCRIPT_DIR}/resources"
  echo "  已清理旧目录：resources/"
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "" >&2
  echo "以下构件未找到，请先在对应仓库执行 mvn package -DskipTests（或使用 ./package.sh --build）：" >&2
  printf '  - %s\n' "${MISSING[@]}" >&2
  exit 1
fi

# 4) 组装 dist 运行目录
echo "组装 ${DIST_DIR} ..."
rm -rf "${DIST_DIR}"
# workspaces/：Harness 配置 workspace.root: ./workspaces（运行期写入，初始为空）
mkdir -p "${DIST_DIR}/workspaces"

cp "${SCRIPT_DIR}/dsh-java-app.jar" "${DIST_DIR}/dsh-java-app.jar"
cp -R "${SCRIPT_DIR}/apps" "${DIST_DIR}/apps"
echo "  dsh-java-app.jar + apps/  ->  dist/"

# 插件目录：四个 plugin jar（Harness 配置 plugins.install-root: ./plugins）
cp -R "${SCRIPT_DIR}/plugins" "${DIST_DIR}/plugins"
echo "  plugins/  ->  dist/plugins"

# 工作空间目录（Harness 配置 workspace.root: ./workspaces）
echo "  workspaces/  ->  dist/workspaces"

# 4) 生成启动脚本
cat > "${DIST_DIR}/start.sh" <<'EOF'
#!/usr/bin/env bash
#
# 启动运行环境（dist）
#
# 目录：
#   dsh-java-app.jar    dsh-java 主程序
#   apps/               四个插件的可独立运行 app（exec fat jar）
#   plugins/            四个插件 jar（Harness install-root）
#   workspaces/         工作空间根目录（workspace.root，初始为空）
#
# 用法：
#   ./start.sh                                        # 启动主程序（默认 MySQL 模式）
#   ./start.sh --spring.profiles.active=standalone    # 本地 H2 模式
#   ./start.sh --app=mysql                            # 启动 apps/dsh-java-mysql-app.jar
#                                                     # 可选：mysql / mall / oceanbase / dameng
#   JAR_PATH=/path/to/app.jar ./start.sh              # 指定其他 jar
#   DSH_JAVA_OPTS="-Xmx2g" ./start.sh                 # 追加 JVM 参数
#
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 确保运行期写入目录存在（插件安装目录 / 工作空间根目录）
mkdir -p plugins workspaces

JAR="${JAR_PATH:-./dsh-java-app.jar}"

# --app=<name>：改为启动 apps/ 下的插件应用
if [[ "${1:-}" == --app=* ]]; then
  APP_NAME="${1#--app=}"
  shift
  JAR="./apps/dsh-java-${APP_NAME}-app.jar"
  if [[ ! -f "${JAR}" ]]; then
    echo "未找到应用：$(pwd)/${JAR}" >&2
    echo "可选：mysql / mall / oceanbase / dameng" >&2
    exit 1
  fi
fi

if [[ ! -f "${JAR}" ]]; then
  echo "未找到可运行 JAR：$(pwd)/${JAR}" >&2
  echo "请先在发布仓库根目录执行 ./package.sh" >&2
  exit 1
fi

JAVA_BIN="${JAVA_HOME:+${JAVA_HOME}/bin/java}"
JAVA_BIN="${JAVA_BIN:-java}"
if ! command -v "${JAVA_BIN}" >/dev/null 2>&1; then
  echo "未找到 java，请安装 JDK 17+ 或设置 JAVA_HOME" >&2
  exit 1
fi

JAVA_MAJOR="$("${JAVA_BIN}" -version 2>&1 | sed -n '1s/.*version "\([0-9]*\).*/\1/p')"
if [[ -n "${JAVA_MAJOR}" && "${JAVA_MAJOR}" -lt 17 ]]; then
  echo "需要 JDK 17+，当前：$("${JAVA_BIN}" -version 2>&1 | head -1)" >&2
  exit 1
fi

echo "Java:  $("${JAVA_BIN}" -version 2>&1 | head -1)"
echo "启动:  $(pwd)/${JAR#./} $*"
if [[ "${JAR}" == "./dsh-java-app.jar" ]]; then
  echo "控制台: http://127.0.0.1:8090"
fi

exec "${JAVA_BIN}" ${DSH_JAVA_OPTS:-} -jar "${JAR}" "$@"
EOF
chmod +x "${DIST_DIR}/start.sh"

echo ""
echo "完成：${DIST_DIR}"
echo "启动：${DIST_DIR}/start.sh [args]"
