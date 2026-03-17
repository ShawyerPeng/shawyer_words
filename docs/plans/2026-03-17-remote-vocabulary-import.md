# Remote Vocabulary Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add runtime loading for built-in remote vocabulary books from raw text URLs and show import progress/success/failure status in the vocabulary picker.

**Architecture:** Keep the study-plan flow centered in the existing repository/controller/picker stack. Extend the vocabulary book model with an optional remote text source, resolve remote books lazily in the repository when selected, and surface explicit import feedback through controller state so the picker can render a lightweight status bar.

**Tech Stack:** Flutter, Material 3, `package:http`, unit tests, widget tests

---

### Task 1: Lock repository remote-import behavior in tests

**Files:**
- Modify: `test/features/study_plan/application/study_plan_controller_test.dart`
- Modify: `lib/features/study_plan/data/in_memory_study_plan_repository.dart`
- Test: `test/features/study_plan/application/study_plan_controller_test.dart`

**Step 1: Write the failing test**

Add a test that selects the built-in remote `cet46-remote` book and expects:
- the repository exposes that book from `loadOfficialBooks()`
- selecting it eventually makes it the current book
- its entries are parsed from newline-separated text

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart`
Expected: FAIL because the book does not exist and no remote loading path is implemented.

**Step 3: Write minimal implementation**

Extend the repository and book model just enough to expose the remote book and lazily load it on selection.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart`
Expected: PASS

### Task 2: Lock controller import-state behavior in tests

**Files:**
- Modify: `test/features/study_plan/application/study_plan_controller_test.dart`
- Modify: `lib/features/study_plan/application/study_plan_controller.dart`

**Step 1: Write the failing test**

Add tests asserting that remote selection:
- emits an importing state before completion
- emits a success state after completion
- emits a failure state and preserves the previous current book if loading fails

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart`
Expected: FAIL because no import-progress state exists.

**Step 3: Write minimal implementation**

Add explicit import-feedback state to the controller and set it around `selectBook`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart`
Expected: PASS

### Task 3: Lock picker UI status-bar behavior in tests

**Files:**
- Modify: `test/features/study_plan/presentation/study_home_page_test.dart`
- Create or Modify: `test/features/study_plan/presentation/vocabulary_book_picker_page_test.dart`
- Modify: `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`

**Step 1: Write the failing test**

Assert that:
- the picker shows `CET 4+6`
- tapping the remote book shows `正在导入词汇表...`
- a failure state renders an error status bar

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/presentation/vocabulary_book_picker_page_test.dart`
Expected: FAIL because the picker has no status bar.

**Step 3: Write minimal implementation**

Render the compact status bar in the picker and wire it to the controller state.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/presentation/vocabulary_book_picker_page_test.dart`
Expected: PASS

### Task 4: Verify focused regressions

**Files:**
- Modify: `lib/features/study_plan/domain/official_vocabulary_book.dart`
- Modify: `lib/features/study_plan/domain/study_plan_repository.dart`
- Modify: `lib/features/study_plan/domain/study_plan_models.dart`
- Modify: `lib/features/study_plan/data/in_memory_study_plan_repository.dart`
- Modify: `lib/features/study_plan/application/study_plan_controller.dart`
- Modify: `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`

**Step 1: Run focused tests**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart test/features/study_plan/presentation/vocabulary_book_picker_page_test.dart test/features/study_plan/presentation/study_home_page_test.dart`
Expected: PASS

**Step 2: Commit**

```bash
git add docs/plans/2026-03-17-remote-vocabulary-import-design.md docs/plans/2026-03-17-remote-vocabulary-import.md lib/features/study_plan/domain/official_vocabulary_book.dart lib/features/study_plan/domain/study_plan_models.dart lib/features/study_plan/domain/study_plan_repository.dart lib/features/study_plan/data/in_memory_study_plan_repository.dart lib/features/study_plan/application/study_plan_controller.dart lib/features/study_plan/presentation/vocabulary_book_picker_page.dart test/features/study_plan/application/study_plan_controller_test.dart test/features/study_plan/presentation/vocabulary_book_picker_page_test.dart test/features/study_plan/presentation/study_home_page_test.dart
git commit -m "feat: add remote vocabulary import"
```
