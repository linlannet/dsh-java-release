# dsh-java-release
基于DSH Java 的可发布运行环境，可直接下载发布和运行

## 一键打包

从相邻仓库（`../dsh-java`、`../dsh-java-plugins`）的 `target` 目录收集构件：

```bash
./package.sh            # 仅打包（各模块需已执行 mvn package）
./package.sh --build    # 先 mvn package -DskipTests 再打包
```

产物布局：

```text
dsh-java-app.jar        dsh-java 主程序（exec fat jar）
apps/                   四个插件的 app（exec fat jar，可独立运行）
plugins/                四个插件 jar（Harness install-root）
dist/                   运行目录
├── dsh-java-app.jar
├── apps/
│   ├── dsh-java-mysql-app.jar       (8091)
│   ├── dsh-java-mall-app.jar        (8092)
│   ├── dsh-java-oceanbase-app.jar   (8093)
│   └── dsh-java-dameng-app.jar      (8094)
├── plugins/            四个插件 jar（plugins.install-root）
├── workspaces/         空目录，workspace.root（会话工作区）
└── start.sh
```

## 启动

```bash
./start-local-jar.sh              # 本地模式（standalone，内置 H2）
./start-mysql-jar.sh              # MySQL 模式（默认数据源）
./start-local-jar.sh --rebuild    # 强制重新组装 dist/ 后再启动
dist/start.sh [args]              # 直接启动，参数透传给 Spring Boot
dist/start.sh --app=mysql         # 启动 apps/ 下的插件应用（mysql/mall/oceanbase/dameng）
```

环境变量：`JAVA_HOME`、`DSH_JAVA_OPTS`（额外 JVM 参数）、`JAR_PATH`（指定其他 jar）。

控制台：<http://127.0.0.1:8090>
