# LexDB SQLite 单词详情设计

## 目标

为本项目增加一条新的单词详情数据来源：本地 LexDB schema SQLite 数据库。

该能力不走词典导入管理，而是通过配置一个本地 `.db` 路径直接读取，并在单词释义详情页中展示结构化内容，例如：
- headword
- 发音
- 释义
- 例句
- 语法模式
- 搭配

## 约束

- 第一版只支持单个本地 LexDB SQLite 路径
- 只要求支持符合 [schema.md](https://github.com/LuciusChen/lexdb/blob/master/schema.md) 的通用表结构
- 不写 `LDOCE` 特例 SQL
- 不接入搜索页
- 不接入词典导入/词典库管理
- 不要求覆盖所有扩展表和所有 `entry_attributes`

## 方案

### 数据来源

新增一个通用 `LexDbWordDetailRepository`，直接按 LexDB schema 查询 SQLite：
- `entries`
- `pronunciations`
- `labels`
- `senses`
- `examples`
- `grammar_patterns`
- `grammar_examples`
- `collocations`
- `collocation_examples`

Repository 参考 `lexdb.el` / `lexdb-ldoce.el` 的拼装顺序，但实现用本项目现有 Dart / `sqflite` 技术栈。

### 查询规则

按 `headword_lower = ?` 精确查询：

```sql
SELECT id, dict_id, headword, headword_lower, headword_display
FROM entries
WHERE headword_lower = ?
ORDER BY id
```

对于每个 entry，再分层查询：

- `pronunciations`
  - 提取 `variant / phonetic / audio_path`
- `labels`
  - `entry_id = ? AND sense_id IS NULL` 作为 entry-level labels
  - `sense_id = ?` 作为 sense-level labels
- `senses`
  - 按 `sort_order`
- `examples`
  - 按 `position, sort_order`
  - `position = 0` 放在 grammar patterns 前
  - `position = 1` 放在 grammar patterns 后
- `grammar_patterns` / `grammar_examples`
- `collocations` / `collocation_examples`

### Domain 模型

现有 `WordDetail` / `DictionaryEntryDetail` 只够承载摘要和 HTML 词典，不足以表达 LexDB 的结构化关系。

第一版新增一套结构化模型：

- `LexDbEntryDetail`
  - `dictionaryId`
  - `dictionaryName`
  - `headword`
  - `headwordDisplay`
  - `pronunciations`
  - `entryLabels`
  - `senses`
  - `collocations`
- `LexDbPronunciation`
  - `variant`
  - `phonetic`
  - `audioPath`
- `LexDbSense`
  - `id`
  - `number`
  - `signpost`
  - `definition`
  - `definitionZh`
  - `labels`
  - `examplesBeforePatterns`
  - `grammarPatterns`
  - `examplesAfterPatterns`
- `LexDbExample`
  - `text`
  - `textZh`
  - `audioPath`
- `LexDbGrammarPattern`
  - `pattern`
  - `gloss`
  - `examples`
- `LexDbCollocation`
  - `collocate`
  - `grammar`
  - `definition`
  - `examples`

`WordDetail` 增加 `lexDbEntries` 列表，不替换现有 `basic / definitions / examples / dictionaryPanels`。

### 数据聚合

`PlatformWordDetailRepository` 保持“聚合器”职责：
- 继续聚合现有 HTML/MDX 词典摘要到 `basic / definitions / examples`
- 同时读取 LexDB 结构化结果并挂到 `lexDbEntries`

这样：
- 现有导入词典功能不受影响
- LexDB 数据有自己的结构化展示区域
- 两条数据源可以共存

### 页面展示

`WordDetailPage` 新增一个结构化 `LexDB` 区块，放在现有“基本 / 释义 / 例句”主体中，而不是塞进 HTML 词典面板。

第一版展示：

1. `headword` / `headwordDisplay`
2. 发音（UK/US）
3. 义项列表
   - `sense_number`
   - `signpost`
   - `definition`
   - `definition_zh`
   - sense-level labels
4. 例句
   - `examplesBeforePatterns`
   - `grammarPatterns`
   - `examplesAfterPatterns`
5. 搭配
   - 搭配文本
   - 搭配释义
   - 搭配例句

HTML 词典面板继续保留，用于已导入的 MDX/HTML 词典。

### 配置方式

在应用入口增加一个本地 LexDB 路径配置，例如在 `ShawyerWordsApp` 中注入：
- `lexDbPath`
- `lexDbDictionaryName`
- `lexDbDictionaryId`

如果配置存在且数据库文件可读，则启用 `LexDbWordDetailRepository`；
如果未配置，则保持当前行为。

## 错误处理

- SQLite 文件不存在或无法打开：
  - 不让整个详情页失败
  - 只跳过 LexDB 数据源
- 查询表缺失或 schema 不兼容：
  - 在 repository 层转成清晰错误
  - 页面层不展示损坏的 LexDB 区块
- 某些可选表没有数据：
  - 视为该能力不存在
  - 不渲染对应 section

## 测试

### Repository

- 精确查询 `entries.headword_lower`
- 正确拼装 `pronunciations`
- 正确按 `sort_order` 构造 `senses`
- 正确按 `position` 拆分例句前后顺序
- 正确拼装 `grammar_patterns`
- 正确拼装 `collocations`

### Aggregation

- `PlatformWordDetailRepository` 能同时返回：
  - 原有 `dictionaryPanels`
  - 新增 `lexDbEntries`

### Widget

- `WordDetailPage` 在有 `lexDbEntries` 时渲染：
  - headword
  - 义项
  - 例句
  - 搭配
- 当 `lexDbEntries` 为空时不显示该结构化区块

