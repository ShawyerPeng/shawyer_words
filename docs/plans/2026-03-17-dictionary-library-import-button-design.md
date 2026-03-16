# 词典库管理页导入按钮设计

## 目标

在词典库管理页增加一个“导入词库”按钮，点击后直接复用现有词库导入流程，不新增第二套导入逻辑。

## 方案

- 词典库管理页新增一个顶部操作按钮“导入词库”。
- 页面接收 `DictionaryController` 和 `DictionaryFilePicker`，复用现有导入会话。
- 点击按钮后调用与首页一致的导入顺序：
  - `startImportSession()`
  - 调起 `pickDictionaryFile`
  - 选择成功后调用 `addImportSource(...)`
- 导入会话 UI 继续由现有 `DictionaryHomePage` 持有，不在本次改动里复制到管理页。
- 本次按钮作为管理页入口，最小实现先复用已有导入回调，并在成功返回后刷新词典库列表。

## 改动范围

- `lib/app/app.dart`
- `lib/app/app_shell.dart`
- `lib/features/dictionary/presentation/dictionary_library_management_page.dart`
- `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

## 验证

- 管理页可见“导入词库”按钮。
- 点击按钮会调用传入的 picker。
- 相关页面测试通过。
