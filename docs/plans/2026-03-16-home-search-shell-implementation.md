# Home Search Shell Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a tab-based app shell with a designed home dashboard, a dedicated search flow, a "Me" page, and a word detail page on top of the current dictionary import/study implementation.

**Architecture:** Keep the existing dictionary import/study stack intact and embed it under the vocabulary tab. Add a search layer with a small `WordLookupRepository` abstraction so the home and search pages can work from built-in sample words before import, then switch to imported entries when available.

**Tech Stack:** Flutter, Dart, Flutter widget tests, `ChangeNotifier`, Material 3, in-memory repositories/controllers.

---

### Task 1: Add Search Domain Contracts

**Files:**
- Create: `lib/features/search/domain/word_lookup_repository.dart`
- Create: `lib/features/search/domain/search_history_repository.dart`
- Test: `test/features/search/application/search_controller_test.dart`

**Step 1: Write the failing test**

Create a controller test that expects built-in entries to be returned for a prefix query and recent history to be de-duplicated and capped at 10 items.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/search/application/search_controller_test.dart`
Expected: FAIL because search contracts and controller do not exist yet

**Step 3: Write minimal implementation**

Create the search contracts needed by the controller and UI:

- search by prefix
- find by entry id
- load/save/clear recent history

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/search/application/search_controller_test.dart`
Expected: PASS

### Task 2: Build Search Controller And In-Memory Sources

**Files:**
- Create: `lib/features/search/application/search_controller.dart`
- Create: `lib/features/search/data/in_memory_search_history_repository.dart`
- Create: `lib/features/search/data/sample_word_lookup_repository.dart`
- Create: `lib/features/search/data/dictionary_word_lookup_repository.dart`
- Test: `test/features/search/application/search_controller_test.dart`

**Step 1: Write the failing test**

Add tests for:

- prefix suggestions update immediately
- imported dictionary entries override sample entries when available
- selecting a word updates history

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/search/application/search_controller_test.dart`
Expected: FAIL with missing controller/repository behavior

**Step 3: Write minimal implementation**

Implement `SearchController` plus small repository classes and sample seed data.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/search/application/search_controller_test.dart`
Expected: PASS

### Task 3: Add App Shell And Navigation

**Files:**
- Modify: `lib/app/app.dart`
- Create: `lib/app/app_shell.dart`
- Create: `lib/features/home/presentation/home_dashboard_page.dart`
- Create: `lib/features/me/presentation/me_page.dart`
- Create: `lib/features/shared/presentation/placeholder_section_page.dart`
- Test: `test/features/home/presentation/app_shell_test.dart`

**Step 1: Write the failing test**

Create widget tests for:

- opening the search page from home
- opening the me page and returning
- switching bottom navigation tabs

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/app_shell_test.dart`
Expected: FAIL because shell pages and navigation do not exist

**Step 3: Write minimal implementation**

Build the visual shell with a floating bottom bar and styled home dashboard.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/app_shell_test.dart`
Expected: PASS

### Task 4: Build Search Page And Word Detail Page

**Files:**
- Create: `lib/features/search/presentation/search_page.dart`
- Create: `lib/features/word_detail/presentation/word_detail_page.dart`
- Test: `test/features/search/presentation/search_page_test.dart`

**Step 1: Write the failing test**

Create widget tests for:

- showing recent history when the query is empty
- showing matching results while typing
- opening a detail page from a result tap
- clearing history

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/search/presentation/search_page_test.dart`
Expected: FAIL because search and detail pages do not exist

**Step 3: Write minimal implementation**

Implement the search and detail UI with the approved layout and behavior.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/search/presentation/search_page_test.dart`
Expected: PASS

### Task 5: Reconnect Existing Dictionary Study UI

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Modify: `test/features/dictionary/presentation/dictionary_home_page_test.dart`
- Modify: `test/widget_test.dart`

**Step 1: Write the failing test**

Update the existing dictionary page test so it verifies the study tab still imports a dictionary and shows the first word card inside the new shell.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: FAIL because the shell changes the entry point

**Step 3: Write minimal implementation**

Embed the old study page under the vocabulary tab and keep its import/swipe behavior intact.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: PASS

### Task 6: Verify The Whole App

**Files:**
- Modify as needed from previous tasks

**Step 1: Run the full test suite**

Run: `flutter test`
Expected: PASS

**Step 2: Run static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

**Step 3: Manually run the app if needed**

Run: `flutter run`
Expected: app launches with home shell and search flow
