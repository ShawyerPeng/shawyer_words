# Vocabulary Book Picker Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 重构单词本页 UI，让单词本与官方词书共用统一的高质量视觉结构，同时保持现有业务逻辑和入口不变。

**Architecture:** 继续在 `VocabularyBookPickerPage` 单文件内完成页面重构，优先复用现有控制器与交互回调。通过新增摘要卡、胶囊 Tab、统一卡片组件和空态组件来提升视觉层级，同时保持已有关键文案与测试 key 不变。

**Tech Stack:** Flutter, Material, existing StudyPlanController, widget tests

---

### Task 1: 重组页面头部与摘要区

**Files:**
- Modify: `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`
- Test: `test/features/study_plan/presentation/study_home_page_test.dart`

**Step 1: Write the failing test**

为“我的词汇入口打开单词本页”测试补充对新摘要文案的断言，例如保留 `生词本`，并新增 `当前词本` 或摘要信息。

**Step 2: Run test to verify it fails**

Run: `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
Expected: 现有 UI 尚未出现新摘要信息，新增断言失败。

**Step 3: Write minimal implementation**

在 `VocabularyBookPickerPage` 中新增摘要卡与更紧凑的头部布局，按当前 Tab 计算摘要文本。

**Step 4: Run test to verify it passes**

Run: `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
Expected: 新断言通过，已有入口行为不变。

**Step 5: Commit**

```bash
git add lib/features/study_plan/presentation/vocabulary_book_picker_page.dart test/features/study_plan/presentation/study_home_page_test.dart docs/plans/2026-04-06-vocabulary-book-picker-design.md docs/plans/2026-04-06-vocabulary-book-picker-implementation.md
git commit -m "refactor(study): 重构单词本页视觉结构"
```

### Task 2: 重做“我的单词本”列表卡片

**Files:**
- Modify: `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`
- Test: `test/features/study_plan/presentation/study_home_page_test.dart`

**Step 1: Write the failing test**

给单词本列表补充对默认词本标签、当前词本文案或词数徽标的断言。

**Step 2: Run test to verify it fails**

Run: `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
Expected: 新增视觉信息尚未出现，测试失败。

**Step 3: Write minimal implementation**

改造 `_NotebookSection`，加入统一封面块、标签、词数徽标、选中态卡片边框。

**Step 4: Run test to verify it passes**

Run: `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
Expected: 单词本相关测试继续通过，新断言通过。

**Step 5: Commit**

```bash
git add lib/features/study_plan/presentation/vocabulary_book_picker_page.dart test/features/study_plan/presentation/study_home_page_test.dart
git commit -m "refactor(study): 优化单词本卡片样式"
```

### Task 3: 统一官方词书卡片和空态

**Files:**
- Modify: `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`
- Test: `test/features/study_plan/presentation/study_home_page_test.dart`

**Step 1: Write the failing test**

补充至少一个对官方词书页签或空态卡片文案的断言。

**Step 2: Run test to verify it fails**

Run: `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
Expected: 新 UI 文案不存在，测试失败。

**Step 3: Write minimal implementation**

统一 `_PickerBookTile` 容器样式，并新增空态卡片组件；保持下载按钮和下载进度逻辑不变。

**Step 4: Run test to verify it passes**

Run: `flutter test --no-pub test/features/study_plan/presentation/study_home_page_test.dart`
Expected: 所有测试通过。

**Step 5: Commit**

```bash
git add lib/features/study_plan/presentation/vocabulary_book_picker_page.dart test/features/study_plan/presentation/study_home_page_test.dart
git commit -m "refactor(study): 统一单词本与词书列表视觉"
```
