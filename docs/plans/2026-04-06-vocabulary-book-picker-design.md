# 单词本页 UI 大改版设计

**目标**

在不改变单词本/词书选择、搜索、下载、新建等业务逻辑的前提下，重做 `VocabularyBookPickerPage` 的页面视觉结构，让“我的单词本”和“官方词书”共用统一的高质感卡片体系，并和当前项目里已经重构过的设置页/学习计划页视觉语言保持一致。

**范围**

- 仅改 `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`
- 保留现有页面入口、交互能力、控制器调用和核心测试文案/Key
- 不变更数据模型和控制器逻辑

**现状问题**

1. 页头、搜索、Tab、列表之间是简单堆叠，缺少信息层级。
2. “我的”与“官方词书”列表视觉体系不一致，像两个页面拼在一起。
3. 单词本卡片信息密度偏低，默认/自定义/词数/当前选中态不够明显。
4. 空态只有一行文案，缺少引导性。

**设计方案**

1. 顶部结构重组
   - 保留返回与标题“单词本”
   - 在标题下增加摘要卡，按 Tab 展示不同的概览信息
   - 搜索框与 Tab 变成同一信息组，整体更紧凑

2. Tab 改为胶囊式导航
   - 当前选中态通过背景、文字颜色和阴影共同体现
   - 保留横向滚动，避免分类过多时拥挤

3. “我的单词本”大卡片化
   - 左侧做统一图标封面块
   - 中间展示名称、描述、标签
   - 右侧展示词数和箭头
   - 默认词本强化徽标，当前选中项增加高亮边框/柔和底色

4. 官方词书列表统一风格
   - 复用与单词本一致的卡片容器
   - 词数、远程/本地、下载状态统一成徽标与状态区
   - 视觉和信息密度与“我的”页签对齐

5. 空态升级
   - 改为完整空态卡片，包含图标、标题、提示语
   - 不新增业务入口，只做更清晰的引导

**风险与控制**

- 主要风险是 UI 结构变化导致现有 widget test 失效。
- 控制方式：保留关键文案与 ValueKey，不动 controller 调用路径；新增或调整测试只覆盖视觉结构下的可见行为。

**验证方式**

- `flutter analyze lib/features/study_plan/presentation/vocabulary_book_picker_page.dart test/features/study_plan/presentation/study_home_page_test.dart`
- `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
