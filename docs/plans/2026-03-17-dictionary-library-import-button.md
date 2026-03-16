# Dictionary Library Import Button Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an `导入词库` entry button to the dictionary library management page and route it through the existing dictionary import flow.

**Architecture:** Inject the existing dictionary import dependencies into the library management page from the app shell, then wire a single management-page button to the same picker and controller actions already used elsewhere. Keep the implementation minimal and avoid duplicating import UI/state.

**Tech Stack:** Flutter, Material 3, widget tests

---

### Task 1: Lock the management-page entry in a failing widget test

**Files:**
- Modify: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Write the failing test**

Add a widget test asserting:
- `导入词库` is visible on the management page
- tapping it calls a fake picker once

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

Expected: FAIL because the button and callback wiring do not exist yet.

### Task 2: Inject import dependencies into the management page

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/app/app_shell.dart`
- Modify: `lib/features/dictionary/presentation/dictionary_library_management_page.dart`

**Step 1: Write minimal implementation**

- Pass `DictionaryController` and `DictionaryFilePicker` from `ShawyerWordsApp` into `AppShell`
- Pass them from `AppShell` into `DictionaryLibraryManagementPage`
- Add a `导入词库` button in the management-page app bar or header
- On tap, call the existing picker and controller import-session methods

**Step 2: Run focused tests**

Run: `flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart test/features/me/presentation/me_page_test.dart test/features/home/presentation/app_shell_test.dart`

Expected: PASS

### Task 3: Verify no regression in existing dictionary import UI

**Files:**
- Test: `test/features/dictionary/presentation/dictionary_home_page_test.dart`

**Step 1: Run regression test**

Run: `flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`

Expected: PASS
