# 我的页与设置中心实施计划

1. 建立设置 domain/data/application 层
   - 新增 `AppSettings` 模型与枚举
   - 新增文件持久化 repository
   - 新增 `SettingsController`

2. 扩展学习/知识仓库能力
   - 给 `WordKnowledgeRepository` 增加清空与统计读取接口
   - 在 SQLite 实现里补对应查询

3. 接入 app 根部设置
   - `ShawyerWordsApp` 创建并持有 `SettingsController`
   - `MaterialApp` 根据设置切换 `ThemeMode` 和字体缩放
   - 把 controller 传给 `AppShell` / `MePage`

4. 重构“我的”页入口
   - 调整一级项顺序和文案
   - 接上 `通用设置` / `学习设置` / `数据统计`
   - 保持 `词典库管理` 现有能力

5. 实现设置子页面
   - `GeneralSettingsPage`
   - `LearningSettingsPage`
   - `ReminderSettingsPage`
   - 信息页：`MembershipCenterPage`、`HelpFeedbackPage`

6. 实现统计页
   - 聚合本地知识记录
   - 绘制 Heatmap、月词汇量趋势、每日新词/复习趋势

7. 测试与回归
   - repository/controller 单测
   - 我的页和设置页 widget test
   - app 根主题/字体切换测试
   - 统计页展示测试
