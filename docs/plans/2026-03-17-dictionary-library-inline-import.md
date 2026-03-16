# Dictionary Library Inline Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the management-page import action into the library list section and run the dictionary import confirmation/preview flow inline without navigating to the dedicated import page.

**Architecture:** Extract the existing import session presentation into a reusable layer. Keep the home page on the full overlay flow, while the management page uses the same confirmation/preview/failure UI but skips the picker overlay stage entirely.

**Tech Stack:** Flutter, Material 3, widget tests

---

### Task 1: Lock the new management-page behavior in tests

**Files:**
- Modify: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Write the failing test**

Assert:
- `导入词库` is rendered beside `显示的词库`
- tapping it calls the picker
- the management page does not show `dictionary-import-overlay`
- the confirmation UI appears in-place

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

Expected: FAIL with the current app-bar button / navigation behavior.

### Task 2: Extract shared import session UI

**Files:**
- Create: `lib/features/dictionary/presentation/dictionary_import_session_layer.dart`
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`

**Step 1: Write minimal implementation**

Move the shared confirm / preview / error / optional overlay presentation into a reusable widget.

**Step 2: Run focused home-page tests**

Run: `flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`

Expected: PASS

### Task 3: Inline the flow on the management page

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_library_management_page.dart`

**Step 1: Write minimal implementation**

- Move the import action into the visible-section header
- restyle it with neutral colors
- call the picker directly in-place
- render the shared import session layer without the picker overlay

**Step 2: Run focused regression tests**

Run: `flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart test/features/me/presentation/me_page_test.dart`

Expected: PASS
