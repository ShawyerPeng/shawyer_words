# LexDB Word Detail Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a local LexDB SQLite word-detail source and render structured dictionary content in the word detail page for any dictionary that follows the LexDB schema.

**Architecture:** Keep the existing MDX/HTML dictionary path intact and add a parallel LexDB repository path that reads a configured local `.db` file with `sqflite`. Extend the word-detail domain with structured LexDB models, aggregate those results alongside the existing dictionary panels, and render them as first-class sections in the detail page.

**Tech Stack:** Flutter, Dart, `sqflite`, repository tests, widget tests, existing `ChangeNotifier`-based word detail flow

---

### Task 1: Add LexDB domain models to word detail

**Files:**
- Modify: `lib/features/word_detail/domain/word_detail.dart`
- Create: `lib/features/word_detail/domain/lexdb_entry_detail.dart`
- Modify: `test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
- Test: `test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`

**Step 1: Write the failing test**

Add an aggregation test that expects `WordDetail` to carry a `lexDbEntries` list without breaking existing `dictionaryPanels`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
Expected: FAIL because `WordDetail` has no `lexDbEntries` field or related LexDB models.

**Step 3: Write minimal implementation**

Create the LexDB domain types and add `lexDbEntries` to `WordDetail`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
Expected: PASS

### Task 2: Lock LexDB repository query behavior in tests

**Files:**
- Create: `lib/features/word_detail/data/lexdb_word_detail_repository.dart`
- Create: `test/features/word_detail/data/lexdb_word_detail_repository_test.dart`

**Step 1: Write the failing test**

Create a temporary SQLite database matching the LexDB schema subset and assert that a lookup returns:
- headword / headwordDisplay
- pronunciations
- senses in `sort_order`
- examples split by `position`
- grammar patterns and grammar examples
- collocations and collocation examples

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/data/lexdb_word_detail_repository_test.dart`
Expected: FAIL because no LexDB repository exists.

**Step 3: Write minimal implementation**

Implement `LexDbWordDetailRepository` with exact-table queries against:
- `entries`
- `pronunciations`
- `labels`
- `senses`
- `examples`
- `grammar_patterns`
- `grammar_examples`
- `collocations`
- `collocation_examples`

Use `headword_lower = ?` exact match and build the LexDB domain graph.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/data/lexdb_word_detail_repository_test.dart`
Expected: PASS

### Task 3: Aggregate LexDB results into the existing word-detail repository

**Files:**
- Modify: `lib/features/word_detail/data/platform_word_detail_repository.dart`
- Modify: `lib/features/word_detail/domain/word_detail_repository.dart`
- Modify: `test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`

**Step 1: Write the failing test**

Add a test that constructs a `PlatformWordDetailRepository` with:
- existing HTML dictionary results
- LexDB repository results

Expect both to appear in the final `WordDetail`.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
Expected: FAIL because `PlatformWordDetailRepository` cannot aggregate LexDB results.

**Step 3: Write minimal implementation**

Extend the repository contract or constructor shape so `PlatformWordDetailRepository` can optionally load LexDB entries and include them in `WordDetail`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart`
Expected: PASS

### Task 4: Wire local LexDB configuration into app composition

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `test/features/word_detail/presentation/word_detail_page_test.dart`

**Step 1: Write the failing test**

Add a composition-level test or builder-level test that expects the app to pass a configured local LexDB path into the word-detail data flow.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: FAIL because no LexDB path can be configured.

**Step 3: Write minimal implementation**

Add app-level constructor arguments for:
- `lexDbPath`
- `lexDbDictionaryId`
- `lexDbDictionaryName`

Instantiate the LexDB repository only when the path is provided.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: PASS

### Task 5: Render LexDB structured content in the word detail page

**Files:**
- Modify: `lib/features/word_detail/presentation/word_detail_page.dart`
- Modify: `test/features/word_detail/presentation/word_detail_page_test.dart`

**Step 1: Write the failing test**

Add widget tests asserting that when `WordDetail.lexDbEntries` is present, the page renders:
- headword
- pronunciations
- sense number / signpost / definition / definition_zh
- examples
- collocations

Also assert that the LexDB section is hidden when `lexDbEntries` is empty.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: FAIL because the page has no LexDB structured section.

**Step 3: Write minimal implementation**

Add a structured LexDB section to the detail page using small private widgets for:
- entry header
- sense cards
- example rows
- collocation rows

Keep the existing HTML dictionary section intact.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: PASS

### Task 6: Verify focused regressions

**Files:**
- Modify: `lib/features/word_detail/data/lexdb_word_detail_repository.dart`
- Modify: `lib/features/word_detail/data/platform_word_detail_repository.dart`
- Modify: `lib/features/word_detail/presentation/word_detail_page.dart`
- Modify: `lib/app/app.dart`

**Step 1: Run focused tests**

Run: `flutter test test/features/word_detail/data/lexdb_word_detail_repository_test.dart test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart test/features/word_detail/presentation/word_detail_page_test.dart`
Expected: PASS

**Step 2: Run focused analyze**

Run: `flutter analyze lib/app/app.dart lib/features/word_detail/data/lexdb_word_detail_repository.dart lib/features/word_detail/data/platform_word_detail_repository.dart lib/features/word_detail/presentation/word_detail_page.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add docs/plans/2026-03-17-lexdb-word-detail-design.md docs/plans/2026-03-17-lexdb-word-detail.md lib/app/app.dart lib/features/word_detail/domain/word_detail.dart lib/features/word_detail/domain/lexdb_entry_detail.dart lib/features/word_detail/data/lexdb_word_detail_repository.dart lib/features/word_detail/data/platform_word_detail_repository.dart lib/features/word_detail/presentation/word_detail_page.dart test/features/word_detail/data/lexdb_word_detail_repository_test.dart test/features/word_detail/data/dictionary_entry_lookup_repository_test.dart test/features/word_detail/presentation/word_detail_page_test.dart
git commit -m "feat: add lexdb word detail support"
```
