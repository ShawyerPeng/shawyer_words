# LexDB Search Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Route word search through the LexDB SQLite `entries` table instead of MDX key scanning.

**Architecture:** Add a dedicated `WordLookupRepository` backed by LexDB, keep exact-first and prefix-second ranking, and wire the app to use that repository whenever a LexDB path is provided. Preserve the current MDX-backed repository as a fallback only when no LexDB path is configured.

**Tech Stack:** Flutter, sqflite, sqflite_common_ffi, unit tests, widget tests

---

### Task 1: Lock LexDB search behavior in tests

**Files:**
- Create: `test/features/search/data/lexdb_word_lookup_repository_test.dart`
- Modify: `lib/features/search/data/lexdb_word_lookup_repository.dart`

**Step 1: Write the failing test**

Add tests asserting that the repository:
- returns exact matches before prefix matches
- normalizes query case
- maps IDs as `lexdb:<entryId>`
- can restore an entry with `findById`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/search/data/lexdb_word_lookup_repository_test.dart`
Expected: FAIL because the repository does not exist.

**Step 3: Write minimal implementation**

Create `LexDbWordLookupRepository` with:
- lazy SQLite opening
- exact query on `headword_lower = ?`
- prefix query on `headword_lower LIKE ?`
- `findById` by numeric entry id

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/search/data/lexdb_word_lookup_repository_test.dart`
Expected: PASS

### Task 2: Lock app wiring to LexDB search

**Files:**
- Modify: `test/features/search/presentation/search_page_test.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/main.dart`

**Step 1: Write the failing test**

Add a test proving that when `lexDbPath` is provided to `ShawyerWordsApp`, searching returns rows sourced from the LexDB `entries` table instead of the MDX repository.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/search/presentation/search_page_test.dart`
Expected: FAIL because search still uses the MDX-backed repository.

**Step 3: Write minimal implementation**

- In `app.dart`, switch default search repository selection to LexDB when `lexDbPath` is non-null.
- In `main.dart`, pass `/Users/shawyerpeng/develop/code/mdx2sqlite/db/LDOCE.db` into `ShawyerWordsApp`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/search/presentation/search_page_test.dart`
Expected: PASS

### Task 3: Verify focused regressions

**Files:**
- Modify: `lib/features/search/data/lexdb_word_lookup_repository.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/main.dart`
- Modify: `test/features/search/data/lexdb_word_lookup_repository_test.dart`
- Modify: `test/features/search/presentation/search_page_test.dart`

**Step 1: Run focused verification**

Run: `flutter test test/features/search/data/lexdb_word_lookup_repository_test.dart test/features/search/application/search_controller_test.dart test/features/search/presentation/search_page_test.dart test/features/word_detail/data/lexdb_word_detail_repository_test.dart`
Expected: PASS
