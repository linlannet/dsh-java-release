# 版本变更日志

> 本文件记录 `dsh-java-release` 各次发版的变更。功能内容对应 `dsh-java` 仓库的版本基线，
> 打包动作对应本仓库 `scripts/package-*.sh` 将 `../dsh-java`、`../dsh-java-plugins` 构件组装为 `dist/` 运行目录的过程。

## 版本号：0.2.2

- 更新日期：2026-11-06
- 基线构件：`dsh-java` 0.2.2 exec 构件
- 自 `0.2.1` 起共变更 297 个文件（约 +50k / -1.1k 行），含大量新增单测。

### 新增

- **数字人（Digital Human）与多 Agent 协同**：
  - 新增 6 张协同表 `digital_human`、`collaboration_room`、`room_participant`、`collaboration_task`、`collaboration_artifact`、`room_event`，修复此前仅有 DAO 引用、缺建表语句导致运行期 `table doesn't exist` 的问题。
  - `CollaborationService` / `PlannerService` / `RemoteAgentGateway` 改造，支持多 Agent 编排与远端 Agent 调度。
- **飞书（Feishu / Lark）Bot 集成**：
  - 新增 `feishu_bot` 表，持久化飞书长连接 Bot 配置与启停状态（`app_secret` 不落库，仅存 `secret_ref` 凭据引用键）。
  - `dsh-java-trigger` 新增 `BotController`（`/api/harness/bots` 提供增删改查、配对、启停、测试接口），以及 `FeishuInboundConfig`、`ApiKeyAuthInterceptor`。
  - 飞书消息 / 配对 / 长连接 WS 网关接入，扩展 Bot 支持范围。
- **技能（Skills）配置与调用**：新增 `skills/` 目录（如 `baidu-ai-search`），打包时随 `dist/` 分发至 `skills/`。
- **平台能力对齐**：对齐参考源 `v0.2.2-alpha.2` 升级指南的平台能力；约束为不引入新第三方依赖、不新增 Maven 模块、不新增数据库表（调度在 standalone 模式仍为内存实现）。
- **LLM 能力**：`dsh-java-domain` 新增 LLM 重试策略与错误分类等能力。
- **可观测性**：OTLP 导出器按 `dsh.otel.enabled=true` 条件装配，端点 `dsh.otel.exporter.otlp-endpoint` 默认 `http://127.0.0.1:4318/v1/traces`；修复无默认构造器导致 Spring 上下文启动失败。

### 变更 / 优化

- 补齐此前遗漏项：迁移 SQL 文件名规范、护栏三件套（Guardrails）、内容寻址存储（CAS）、`Workspace` 实体、SHA-256 实现。
- SQL 脚本 `lead` 关键字统一调整为 `leader`。
- 预置插件规范化：`dsh-demo-plugin`（DSH_NODE_BRIDGE，入口 `index.js`）与 `sample-tools-plugin`（JAVA_NATIVE，jar `sample-tools-plugin-1.0.0.jar`）随 `harness.yml` 预置，打包时拷入 `dist/plugins/`。
- 补充适配器与检索能力及其单元测试：HTTP MCP 资源端口、目录选择器后端、SenseVoice 语音、本地子进程执行、Bing / Google 翻译、Cpython PTC、Lucene 会话检索索引、飞书消息/配对/WS 网关、OTLP 导出器等。

### 修复

- 数字人 / 协同表缺失建表语句（`table doesn't exist`）。
- OTLP 导出器无默认构造器导致 Spring 上下文启动失败。
- 数据迁移补齐：`token_snapshot`、`anonymous_user_id`、`checkpoint`、`message_feedback`、`slash_command`、`spill_ref`、`workspace`、`agent_team` 等迁移脚本。

### 工程 / 打包

- 新增 `scripts/check-sql-parity.sh`：校验 `schema.sql` / `dsh_java.sql` / `db/migration` 三处表集合口径一致（并校验 README 声明表数量）。
- 重新打包：从 `../dsh-java`、`../dsh-java-plugins` 收集 0.2.2 exec 构件重建 `dist/` 运行目录。
- `dist/dsh-java-app.jar` 与根目录缓存 `dsh-java-app.jar` 同步刷新至 dsh-java 0.2.2 exec 构件（哈希一致校验）。

## 版本号：0.2.1

- 更新日期：2026-10-12

### 新增

- `package.sh` 一键打包脚本：从 `../dsh-java`、`../dsh-java-plugins` 收集构件并组装 `dist/` 运行目录（支持 `--build` 先构建再打包）。
- `dist/start.sh` 启动脚本：JDK 17+ 校验、参数透传 Spring Boot；新增 `--app=<name>` 可直接启动 `apps/` 下的插件应用（mysql / mall / oceanbase / dameng）。
- `start-local-jar.sh`（standalone + 内置 H2）、`start-mysql-jar.sh`（MySQL 数据源）两个快捷启动脚本。
- `dist/workspaces/` 空目录（Harness `workspace.root: ./workspaces`），打包时自动创建，启动前自动补齐。
- `dist/plugins/`（Harness `plugins.install-root: ./plugins`），打包时拷贝四个 plugin jar。

### 变更

- 产物瘦身：主程序与四个插件 app 改用 exec 打包，默认 jar 为瘦 jar（可上传 Maven Central），fat jar 输出为 `*-exec.jar` 且不随仓库分发。
- 目录重构：原 `resources/` 拆分为 `apps/`（仅 app，可独立运行）与 `plugins/`（仅 plugin jar），旧目录在打包时自动清理。
- 四个插件 app 端口收敛：mysql 8091、mall 8092、oceanbase 8093、dameng 8094。

## 版本号：0.2.0

- 更新日期：2026-10-11
- 初始化发布工程结构。

## 版本号：0.1.0

- 更新日期：2026-10-08
- 初始化版本。
