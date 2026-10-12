# 版本

## 版本号：0.2.1

- 更新日期：2026-10-12

新增

- `package.sh` 一键打包脚本：从 `../dsh-java`、`../dsh-java-plugins` 收集构件并组装 `dist/` 运行目录（支持 `--build` 先构建再打包）
- `dist/start.sh` 启动脚本：JDK 17+ 校验、参数透传 Spring Boot；新增 `--app=<name>` 可直接启动 `apps/` 下的插件应用（mysql / mall / oceanbase / dameng）
- `start-local-jar.sh`（standalone + 内置 H2）、`start-mysql-jar.sh`（MySQL 数据源）两个快捷启动脚本
- `dist/workspaces/` 空目录（Harness `workspace.root: ./workspaces`），打包时自动创建，启动前自动补齐
- `dist/plugins/`（Harness `plugins.install-root: ./plugins`），打包时拷贝四个 plugin jar

变更

- 产物瘦身：主程序与四个插件 app 改用 exec 打包，默认 jar 为瘦 jar（可上传 Maven Central），fat jar 输出为 `*-exec.jar` 且不随仓库分发
- 目录重构：原 `resources/` 拆分为 `apps/`（仅 app，可独立运行）与 `plugins/`（仅 plugin jar），旧目录在打包时自动清理
- 四个插件 app 端口收敛：mysql 8091、mall 8092、oceanbase 8093、dameng 8094


## 版本号：0.2.0

- 更新日期：2026-10-11
- 初始化发布工程结构


## 版本号：0.1.0

- 更新日期：2026-10-08
- 初始化版本
