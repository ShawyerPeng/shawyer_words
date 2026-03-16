# 词典库管理页内嵌导入设计

## 目标

调整词典库管理页的导入交互：

- “导入词库”按钮移到“显示的词库”标题行
- 按钮不再使用绿色强调，改为页面已有的中性色
- 点击按钮后不跳转导入页，直接在当前页拉起 picker
- 选择成功后在当前页进入确认/预览
- 不显示“请选择词典主文件和关联资源文件”的那块蒙层

## 方案

- 抽取导入会话层组件，供首页和管理页共同复用。
- 首页保留完整流程：蒙层 + 确认 + 预览。
- 管理页只复用确认/预览/失败层，跳过 picker 蒙层。
- 管理页点击“导入词库”时：
  - 调用 `startImportSession()`
  - 直接调起 picker
  - 取消时关闭会话
  - 成功时进入确认/预览

## 改动范围

- `lib/features/dictionary/presentation/dictionary_home_page.dart`
- `lib/features/dictionary/presentation/dictionary_library_management_page.dart`
- `lib/features/dictionary/presentation/dictionary_import_session_layer.dart`
- `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
- `test/features/dictionary/presentation/dictionary_home_page_test.dart`
