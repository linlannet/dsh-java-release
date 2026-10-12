#!/usr/bin/env bash
#
# 本地模式启动 dsh-java（standalone profile，内置 H2 文件库，无需 MySQL）。
#
# 用法：
#   ./start-local-jar.sh              # 首次运行会自动执行 ./package.sh 组装 dist/
#   ./start-local-jar.sh --rebuild    # 强制重新组装 dist/
#   DSH_JAVA_OPTS="-Xmx2g" ./start-local-jar.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
PACKAGE_SH="${SCRIPT_DIR}/package.sh"

REBUILD=false
if [[ "${1:-}" == "--rebuild" ]]; then
  REBUILD=true
  shift
fi

if [[ ! -f "${DIST_DIR}/start.sh" || "${REBUILD}" == true ]]; then
  if [[ ! -f "${PACKAGE_SH}" ]]; then
    echo "未找到打包脚本：${PACKAGE_SH}" >&2
    exit 1
  fi
  "${PACKAGE_SH}"
fi

exec "${DIST_DIR}/start.sh" --spring.profiles.active=standalone "$@"
