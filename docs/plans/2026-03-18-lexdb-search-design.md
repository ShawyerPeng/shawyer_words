# LexDB 搜索接入设计

## 目标

让查词页基于 `/Users/shawyerpeng/develop/code/mdx2sqlite/db/LDOCE.db` 的 LexDB 数据进行搜索，不再依赖 MDX `listKeys()` 建索引。

## 范围

- 查词页搜索结果改为来自 LexDB `entries` 表。
- 详情页继续使用现有 `LexDbWordDetailRepository` 读取结构化释义。
- 不再把自定义 MDX 词典作为查词页的数据源。
- 本次不改搜索页 UI，不改历史记录交互。

## 现状问题

- 当前查词页使用 `InstalledDictionaryWordLookupRepository`。
- 它会遍历“可见词典”，重新打开每本 MDX 并读取 `listKeys()`。
- 这条链路与导入预览/详情链路分离，导入成功不等于查词可用。
- 读取某本 MDX 失败时会静默跳过，用户只能看到“搜不到”。

## 目标方案

### 数据源

- 新增 `LexDbWordLookupRepository`，实现 `WordLookupRepository`。
- 搜索只查询 LexDB 的 `entries` 表，使用现有索引列：
  - `headword_lower`
  - `headword_display`
- 匹配策略保持当前搜索页预期：
  - 精确匹配优先
  - 前缀匹配其次
  - 结果数受 `limit` 控制

### 结果映射

- 每条搜索结果映射为 `WordEntry`：
  - `id`: `lexdb:<entryId>`
  - `word`: `headword`
  - `rawContent`: `''`
  - 其余字段留空
- `findById` 支持按 `lexdb:<entryId>` 重新读取单条 entry，保证历史记录和详情页跳转可用。

### 运行时接线

- `ShawyerWordsApp` 保持“传入 controller 时优先使用传入值”的测试友好模式。
- 当调用方提供 `lexDbPath` 时：
  - 搜索页默认注入 `LexDbWordLookupRepository`
  - 详情页继续注入 `LexDbWordDetailRepository`
- 当 `lexDbPath` 未提供时：
  - 搜索页继续回退到现有 `InstalledDictionaryWordLookupRepository`
  - 详情页维持现有行为
- `main.dart` 显式把 `/Users/shawyerpeng/develop/code/mdx2sqlite/db/LDOCE.db` 传给 `ShawyerWordsApp`，使桌面开发运行时默认启用 LexDB 搜索。

## 错误处理

- LexDB 查询失败时直接抛错给调用层，不做静默吞掉。
- 数据库不存在或打不开时，搜索结果返回空列表之外，还应在测试中覆盖异常路径至少不崩溃。
- 本次不新增搜索页错误 UI。

## 测试

- 新增 `LexDbWordLookupRepository` 单测：
  - 精确匹配优先于前缀匹配
  - `findById` 能按 `lexdb:<entryId>` 找回条目
  - 大小写无关
- 更新应用装配测试：
  - `lexDbPath` 存在时搜索页使用 LexDB 结果
  - 未提供 `lexDbPath` 时现有注入方式不受影响
