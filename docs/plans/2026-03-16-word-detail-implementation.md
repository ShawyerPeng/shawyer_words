# Word Detail Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an aggregated word-detail page that loads all visible dictionaries for a word, persists global word knowledge in SQLite, and supports the required sections and top-bar actions.

**Architecture:** Keep `WordEntry` lightweight for search and list usage. Add a dedicated word-detail feature layer with a controller, a multi-dictionary lookup repository, a SQLite-backed word knowledge repository, and a composable presentation tree that renders aggregated sections plus per-dictionary panels.

**Tech Stack:** Flutter, Dart, Material 3, `ChangeNotifier`, widget tests, repository tests, `sqflite`, file-system dictionary package metadata.

---

### Task 1: Add SQLite Support And Word Knowledge Domain

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/word_detail/domain/word_knowledge_record.dart`
- Create: `lib/features/word_detail/domain/word_knowledge_repository.dart`
- Create: `test/features/word_detail/domain/word_knowledge_record_test.dart`

**Step 1: Write the failing test**

Create tests that verify:

- `WordKnowledgeRecord` defaults are stable
- serialization helpers normalize booleans and empty note values
- word keys are normalized consistently for persistence

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/domain/word_knowledge_record_test.dart`
Expected: FAIL because the word-detail domain model does not exist

**Step 3: Write minimal implementation**

Add `sqflite` to `pubspec.yaml` and create the domain model plus repository contract:

- `getByWord`
- `save`
- `toggleFavorite`
- `markKnown`
- `saveNote`

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/domain/word_knowledge_record_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add pubspec.yaml lib/features/word_detail/domain/word_knowledge_record.dart lib/features/word_detail/domain/word_knowledge_repository.dart test/features/word_detail/domain/word_knowledge_record_test.dart
git commit -m "feat: add word knowledge domain contract"
```

### Task 2: Implement SQLite Word Knowledge Storage

**Files:**
- Create: `lib/features/word_detail/data/sqlite_word_knowledge_repository.dart`
- Create: `test/features/word_detail/data/sqlite_word_knowledge_repository_test.dart`

**Step 1: Write the failing test**

Create repository tests that verify:

- reading a missing word returns null
- saving and reloading preserves all fields
- toggling favorite flips the stored bit
- marking known updates `isKnown` and `skipKnownConfirm`
- saving a note preserves non-empty and empty values

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/data/sqlite_word_knowledge_repository_test.dart`
Expected: FAIL because the SQLite repository does not exist

**Step 3: Write minimal implementation**

Implement a small SQLite repository with:

- one `word_knowledge` table
- lazy database initialization
- word normalization on read/write
- integer-to-bool mapping

Use a test-friendly constructor so repository tests can inject an in-memory or temporary database path.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/data/sqlite_word_knowledge_repository_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/word_detail/data/sqlite_word_knowledge_repository.dart test/features/word_detail/data/sqlite_word_knowledge_repository_test.dart
git commit -m "feat: persist word knowledge in sqlite"
```

### Task 3: Add Word Detail Models And Multi-Dictionary Lookup

**Files:**
- Create: `lib/features/word_detail/domain/word_detail.dart`
- Create: `lib/features/word_detail/domain/dictionary_entry_detail.dart`
- Create: `lib/features/word_detail/domain/word_detail_repository.dart`
- Create: `lib/features/word_detail/data/dictionary_entry_lookup_repository.dart`
- Create: `lib/features/word_detail/data/platform_word_detail_repository.dart`
- Modify: `lib/features/dictionary/data/mdx_dictionary_parser.dart`
- Create: `test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
- Modify: `test/features/dictionary/data/mdx_dictionary_parser_test.dart`

**Step 1: Write the failing test**

Create tests that verify:

- only visible dictionaries are queried
- query order matches library display order
- a failure in one dictionary does not discard successful hits
- aggregation prefers the first non-empty basic field
- definitions and examples are merged without duplicates

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
Expected: FAIL because the detail lookup repository and aggregate models do not exist

**Step 3: Write minimal implementation**

Add detail models and a repository stack that:

- reads visible dictionaries from the library repository/controller data source
- opens the dictionary package for each visible MDX
- looks up one word per dictionary
- maps raw content into `DictionaryEntryDetail`
- aggregates dictionary hits into `WordDetail`

Refactor `mdx_dictionary_parser.dart` only enough to reuse cleanup and extraction logic for detail lookup without breaking import behavior.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
Expected: PASS

**Step 5: Run parser regression tests**

Run: `flutter test test/features/dictionary/data/mdx_dictionary_parser_test.dart`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/features/word_detail/domain/word_detail.dart lib/features/word_detail/domain/dictionary_entry_detail.dart lib/features/word_detail/domain/word_detail_repository.dart lib/features/word_detail/data/dictionary_entry_lookup_repository.dart lib/features/word_detail/data/platform_word_detail_repository.dart lib/features/dictionary/data/mdx_dictionary_parser.dart test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart test/features/dictionary/data/mdx_dictionary_parser_test.dart
git commit -m "feat: add aggregated word detail lookup"
```

### Task 4: Add Word Detail Controller And Action Logic

**Files:**
- Create: `lib/features/word_detail/application/word_detail_controller.dart`
- Create: `test/features/word_detail/application/word_detail_controller_test.dart`

**Step 1: Write the failing test**

Create controller tests that verify:

- loading state transitions to ready with aggregated content
- favorite toggling updates state and persistence
- mark-known respects `skipKnownConfirm`
- saving a note refreshes the rendered state
- repository errors surface as failure state without crashing

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/application/word_detail_controller_test.dart`
Expected: FAIL because the controller does not exist

**Step 3: Write minimal implementation**

Implement a `ChangeNotifier` controller that coordinates:

- initial load from word string
- optional optimistic rendering from `initialEntry`
- knowledge mutations
- busy flags for save actions
- error messages for UI feedback

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/application/word_detail_controller_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/word_detail/application/word_detail_controller.dart test/features/word_detail/application/word_detail_controller_test.dart
git commit -m "feat: add word detail controller"
```

### Task 5: Rebuild The Word Detail Presentation

**Files:**
- Modify: `lib/features/word_detail/presentation/word_detail_page.dart`
- Create: `test/features/word_detail/presentation/word_detail_page_test.dart`

**Step 1: Write the failing test**

Create widget tests that verify:

- top-left back button and top-right action buttons exist
- favorite state changes icon styling
- mark-known shows the bottom sheet when required
- the bottom sheet contains the checkbox and cancel/confirm actions
- sections render in the required order
- dictionary panels are collapsed by default
- empty note and filled note states both render

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: FAIL because the redesigned page and interactions do not exist

**Step 3: Write minimal implementation**

Refactor `word_detail_page.dart` into:

- page scaffold and state binding
- reusable section cards
- action bar
- bottom-sheet confirm flow
- note editor entry point
- dictionary accordion panels

Keep the current visual language but render the richer information structure.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/word_detail/presentation/word_detail_page.dart test/features/word_detail/presentation/word_detail_page_test.dart
git commit -m "feat: redesign word detail page"
```

### Task 6: Wire Search, Study, And App Composition To The New Detail Stack

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/features/search/presentation/search_page.dart`
- Modify: `lib/features/study/presentation/word_card_view.dart`
- Modify: `test/features/search/presentation/search_page_test.dart`
- Modify: `test/features/study/presentation/word_card_view_test.dart`
- Modify: `test/features/home/presentation/app_shell_test.dart`

**Step 1: Write the failing test**

Update integration-oriented widget tests so they verify:

- opening a word from search builds the new detail page using `word` plus `initialEntry`
- the study card can open the new detail page for the current word
- app composition provides the repositories needed by the detail page

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/search/presentation/search_page_test.dart test/features/study/presentation/word_card_view_test.dart test/features/home/presentation/app_shell_test.dart`
Expected: FAIL because the app is not yet wired to the new detail dependencies

**Step 3: Write minimal implementation**

Update app composition to create:

- SQLite word knowledge repository
- platform word detail repository
- controller factory or page-level dependency wiring

Then route search and study entry points to the new detail page API.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/search/presentation/search_page_test.dart test/features/study/presentation/word_card_view_test.dart test/features/home/presentation/app_shell_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/app/app.dart lib/features/search/presentation/search_page.dart lib/features/study/presentation/word_card_view.dart test/features/search/presentation/search_page_test.dart test/features/study/presentation/word_card_view_test.dart test/features/home/presentation/app_shell_test.dart
git commit -m "feat: wire aggregated word detail flow"
```

### Task 7: Verify The Whole Feature End To End

**Files:**
- Modify as needed from previous tasks

**Step 1: Run targeted word-detail tests**

Run: `flutter test test/features/word_detail`
Expected: PASS

**Step 2: Run the full widget and repository suite**

Run: `flutter test`
Expected: PASS

**Step 3: Run static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

**Step 4: Manual verification**

Run: `flutter run`
Expected:

- search -> word detail loads aggregated content
- favorite, known, and note changes persist after reopening the page
- dictionary section stays collapsed initially
- mark-known confirm respects the skip checkbox

**Step 5: Commit final cleanup if needed**

```bash
git add pubspec.yaml pubspec.lock lib test
git commit -m "test: verify aggregated word detail flow"
```
