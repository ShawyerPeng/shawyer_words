# Dictionary Import Apple Metadata Filter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent dictionary zip imports from failing when macOS metadata files like `__MACOSX/.../._main.mdx` are present.

**Architecture:** Keep the fix in the package scanner so both import and preview flows benefit automatically. Treat Apple metadata as ignorable noise and preserve the existing error for real multi-MDX packages.

**Tech Stack:** Dart, Flutter tests, archive package

---

### Task 1: Add a failing importer regression test

**Files:**
- Modify: `test/features/dictionary/data/dictionary_package_importer_test.dart`

**Step 1: Write the failing test**

Add a zip archive containing:
- `archive/main.mdx`
- `__MACOSX/archive/._main.mdx`
- optional non-MDX resources

Assert the importer succeeds and selects `main.mdx`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/data/dictionary_package_importer_test.dart`

Expected: FAIL with the current multiple-MDX error.

### Task 2: Filter Apple metadata in the scanner

**Files:**
- Modify: `lib/features/dictionary/data/dictionary_package_scanner.dart`

**Step 1: Write minimal implementation**

Ignore:
- paths under `__MACOSX/`
- path segments starting with `._`
- `.DS_Store`

**Step 2: Run focused tests**

Run: `flutter test test/features/dictionary/data/dictionary_package_importer_test.dart`

Expected: PASS

### Task 3: Verify related dictionary data tests still pass

**Files:**
- Test: `test/features/dictionary/data/platform_dictionary_preview_repository_test.dart`

**Step 1: Run regression test**

Run: `flutter test test/features/dictionary/data/platform_dictionary_preview_repository_test.dart`

Expected: PASS
