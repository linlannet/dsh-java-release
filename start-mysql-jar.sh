#!/usr/bin/env bash
#
# MySQL 模式启动 dsh-java（默认 profile：jdbc:mysql://127.0.0.1:3306/dsh_java）。
# 启动前请确认 MySQL 实例可用，库/账号与 application.yml 中的数据源配置一致。
#
# 用法：
#   ./start-mysql-jar.sh              # 首次运行会自动执行 ./package.sh 组装 dist/
#   ./start-mysql-jar.sh --rebuild    # 强制重新组装 dist/
#   DSH_JAVA_OPTS="-Xmx2g" ./start-mysql-jar.sh
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

# 不指定 profile 即为 MySQL 模式（dsh-java 默认数据源为 MySQL）
exec "${DIST_DIR}/start.sh" "$@"
