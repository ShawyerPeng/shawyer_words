# Dictionary Library Help Dialog Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a help button to the dictionary library management page app bar and show a modal help dialog that matches the provided copy reference.

**Architecture:** Keep the change local to the presentation layer by extending the management page scaffold with an app-bar action and a stateless dialog widget. Verify the user-visible behavior with widget tests that assert both the trigger and the dialog copy.

**Tech Stack:** Flutter, Material 3 widgets, flutter_test

---

### Task 1: Add failing widget coverage for the help entry point

**Files:**
- Modify: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Write the failing test**

Add a widget test that:
- pumps `DictionaryLibraryManagementPage`
- expects a `帮助` button in the app bar
- taps it
- expects the dialog title `如何导入扩展词典包`
- expects representative body copy and the `好的` dismiss button

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

Expected: FAIL because the page does not yet render the `帮助` button or dialog.

### Task 2: Implement the help dialog UI

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_library_management_page.dart`

**Step 1: Add minimal implementation**

Update the management scaffold to accept an optional help action callback and render a pill-shaped `帮助` text button on the right side of the app bar.

Add a helper that opens a modal dialog containing:
- title `如何导入扩展词典包`
- explanatory copy based on the provided screenshot
- a highlighted file-type list for `.mdx`, `.mdd`, `.js`, `.css`, `.jpg/.png`
- a `好的` button that dismisses the dialog

**Step 2: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

Expected: PASS

### Task 3: Verify the final state

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_library_management_page.dart`
- Modify: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Run targeted verification**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

Expected: PASS with 0 failures
