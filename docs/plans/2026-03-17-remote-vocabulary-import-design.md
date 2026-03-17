# 远程词汇表导入设计

## 目标

为背单词模块增加基于外部文本链接的词汇表导入能力，并内置一个固定来源的 `CET 4+6` 词汇表。

同时在词汇表选择页增加状态栏式反馈，明确展示导入中、导入成功、导入失败三种状态。

## 约束

- 外部来源先只支持 HTTP(S) raw 文本链接
- 文本格式固定为“每行一个单词”
- 本次不做用户手动输入 URL
- 本次不做持久化缓存
- 保持现有静态内置词汇表可用

## 方案

### 数据模型

- 扩展 `OfficialVocabularyBook`，让它既可以承载现有静态 `entries`，也可以声明远程文本来源 URL。
- 对于远程词汇表，初始列表只提供元数据，真正的 `entries` 在用户选择时动态加载。
- 内置新增一个固定词汇表：
  - `id`: `cet46-remote`
  - `title`: `CET 4+6`
  - `category`: `四六级`
  - `sourceUrl`: `https://raw.githubusercontent.com/mahavivo/english-wordlists/refs/heads/master/CET_4%2B6_edited.txt`

### 数据流

- `StudyPlanRepository.loadOfficialBooks()` 继续返回所有可选词汇表。
- `StudyPlanRepository.selectBook(bookId)` 对静态词汇表沿用现有同步选择流程。
- 当选择远程词汇表时，repository 在内部：
  - 拉取文本内容
  - 按行解析出单词
  - 生成最小可用的 `WordEntry`
  - 构造已加载的 `OfficialVocabularyBook`
  - 再更新当前词汇表和我的词汇表

### UI 状态

- 在 `StudyPlanController` 中增加显式导入状态，区分：
  - 空闲
  - 导入中
  - 导入成功
  - 导入失败
- `VocabularyBookPickerPage` 在顶部搜索框下方渲染一个状态栏提示区：
  - 导入中：展示转圈和“正在导入词汇表...”
  - 导入成功：展示成功文案
  - 导入失败：展示失败原因
- 导入成功后保持短暂成功状态，并由现有点击流程返回上一页。
- 导入失败时留在当前页，允许用户继续选择其他词汇表。

### 解析规则

- 对下载文本做 `LineSplitter` 逐行解析
- 去掉每行首尾空白
- 丢弃空行
- 先不解析音标、词性、释义
- `WordEntry` 最小字段规则：
  - `id`: `${bookId}-${lineNumber}`
  - `word`: 该行文本
  - `pronunciation`: `''`
  - `partOfSpeech`: `''`
  - `definition`: `''`
  - `exampleSentence`: `''`
  - `rawContent`: `<p>{word}</p>`

## 错误处理

- 网络请求失败时抛出明确错误，由 controller 转成失败状态文案
- 下载成功但解析后为空时视为失败，提示词汇表内容为空
- 失败不覆盖已存在的当前词汇表

## 测试

- repository 单测覆盖：
  - 远程词汇表元数据暴露
  - 文本按行解析成 `WordEntry`
  - 选择远程词汇表后成为当前词汇表
  - 空内容和请求失败处理
- controller 单测覆盖：
  - 选择远程词汇表时状态从空闲进入导入中
  - 成功后进入成功状态并更新当前词汇表
  - 失败后进入失败状态并保留原当前词汇表
- widget 测试覆盖：
  - 列表页显示 `CET 4+6`
  - 导入中状态栏出现
  - 失败提示可见
