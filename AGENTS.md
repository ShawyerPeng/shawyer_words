# 项目级 Agent 规则

## Flutter 测试命令

- 若本次改动未修改 `pubspec.yaml` 或 `pubspec.lock`，则执行 `flutter test` 时必须加上 `--no-pub` 参数。
- 仅当本次改动包含 `pubspec.yaml` 或 `pubspec.lock` 变更时，才允许省略 `--no-pub`。
