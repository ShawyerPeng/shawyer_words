# Word Detail Design

**Date:** 2026-03-16

## Goal

Build a real word-detail experience that aggregates visible dictionary content for a word, persists word-level user state globally by spelling, and exposes the product sections and actions required by the spec.

## Product Scope

This feature covers:

- a new aggregated word detail page for a word spelling
- top actions:
  - back
  - mark known
  - favorite
  - add note
  - options menu
- page sections:
  - basic
  - definitions
  - examples
  - related words
  - word graph
  - expansion
  - notes
  - dictionaries
- global word-level persistence for:
  - favorite
  - known
  - note
  - skip-known-confirm preference
- querying all visible dictionaries in user-configured order
- SQLite-backed persistence for word-level state

It does not cover:

- cloud sync
- remote correction submission backend
- perfect parsing for every MDX structure
- rich note formatting

## Current State

The current app can:

- navigate from search results to a word detail page
- show a simple detail page for one `WordEntry`
- manage visible dictionary libraries and their order
- persist dictionary library preferences

The current app cannot:

- aggregate content from multiple visible dictionaries
- persist word-level favorite / known / note state
- query per-word detail across all visible MDX libraries
- display the required rich detail sections

## Recommended Architecture

Introduce a dedicated word-detail layer instead of expanding `WordEntry` into a page-sized model.

Keep `WordEntry` as the lightweight lookup result used by search and other list views. Add a new aggregated detail model and controller that:

- loads visible dictionary libraries in configured order
- queries the current word across visible dictionaries
- parses each dictionary hit into a normalized detail structure
- loads and persists global word knowledge from SQLite
- exposes one view model for the page

## Domain Model

### WordDetail

Page-level aggregated model:

- `word`
- `knowledge`
- `basicSummary`
- `definitions`
- `examples`
- `relatedWords`
- `wordGraph`
- `expansion`
- `dictionaryPanels`

### WordKnowledgeRecord

Global user state keyed by normalized word spelling:

- `word`
- `isFavorite`
- `isKnown`
- `note`
- `skipKnownConfirm`
- `updatedAt`

### DictionaryEntryDetail

One dictionary's result for a word:

- `dictionaryId`
- `dictionaryName`
- `entryId`
- `word`
- `rawContent`
- `basic`
- `senses`
- `examples`
- `related`
- `wordGraph`
- `expansion`
- `errorMessage`

### Supporting Section Models

- `WordBasicSummary`
  - headword
  - pronunciationUs
  - pronunciationUk
  - audioUs
  - audioUk
  - frequency
- `WordSense`
  - partOfSpeech
  - definitionZh
- `WordExample`
  - english
  - englishAudio
  - translationZh
  - translationAudio
- `WordRelatedWords`
  - synonyms
  - antonyms
  - lookalikes
  - derivatives
- `WordLookalike`
  - word
  - definitionZh
- `WordExpansion`
  - synonymComparison
  - phrases
  - collocations
  - rootsAffixes
  - etymology
  - mnemonic

## Data Flow

- search or study page opens `WordDetailPage(word: ..., initialEntry: ...)`
- page renders fast with optional initial entry
- `WordDetailController` loads:
  - visible dictionary libraries
  - dictionary hits for the target word
  - `WordKnowledgeRecord` from SQLite
- controller aggregates all results into `WordDetail`
- page renders aggregated sections
- user actions persist through repositories and update the controller state

## Query Strategy

The detail page should not trust a single incoming `WordEntry` as the full source of truth.

Add a dedicated lookup layer for detail loading:

- `DictionaryEntryLookupRepository`
  - `Future<List<DictionaryEntryDetail>> lookupAcrossVisibleDictionaries(String word)`

Repository responsibilities:

- read visible dictionary libraries in user-configured order
- locate each dictionary's MDX path
- look up the target word in each visible dictionary
- parse raw content into normalized `DictionaryEntryDetail`
- ignore non-matching dictionaries
- tolerate per-dictionary failures without failing the whole page

## Parsing Strategy

Parsing should be incremental and tolerant, not all-or-nothing.

### Priority 1: Strong Parsing

Strongly parse these sections when possible:

- basic pronunciation fields
- part of speech
- Chinese definitions
- examples

### Priority 2: Semi-Structured Parsing

Best-effort parse these sections by heading and list patterns:

- synonyms
- antonyms
- lookalikes
- derivatives
- synonym comparison
- phrases
- collocations
- roots / affixes
- etymology
- mnemonic

### Raw Fallback

Every dictionary panel keeps cleaned `rawContent` so information remains visible even when structure extraction is incomplete.

## Aggregation Rules

The page-level sections should show the first non-empty value from visible dictionaries in display order unless the data type naturally merges.

Recommended rules:

- basic fields: first non-empty value
- definitions: merge by sense order, de-duplicate identical pairs
- examples: merge and de-duplicate by English text
- synonyms / antonyms: flatten and de-duplicate, display comma-joined
- lookalikes: keep structured rows with Chinese meaning, display one per line
- derivatives: merge and de-duplicate
- word graph / expansion: first non-empty block or merged list where safe
- dictionaries section: show every hit separately, default collapsed

## Persistence Model

Persist word-level state in SQLite, not JSON.

Recommended initial table:

```sql
CREATE TABLE word_knowledge (
  word TEXT PRIMARY KEY,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_known INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  skip_known_confirm INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);
```

Recommended repository:

- `WordKnowledgeRepository`
  - `Future<WordKnowledgeRecord?> getByWord(String word)`
  - `Future<void> save(WordKnowledgeRecord record)`
  - `Future<void> toggleFavorite(String word)`
  - `Future<void> markKnown(String word, {required bool skipConfirmNextTime})`
  - `Future<void> saveNote(String word, String note)`

Word spelling is the global key, so state is shared across all dictionaries.

## UI Structure

Break the detail UI into focused components:

- `WordDetailPage`
- `WordDetailScaffold`
- `WordDetailHeaderCard`
- `WordActionBar`
- `WordDefinitionsSection`
- `WordExamplesSection`
- `WordRelatedSection`
- `WordGraphSection`
- `WordExpansionSection`
- `WordNoteSection`
- `WordDictionariesSection`
- `DictionaryPanelCard`

## Page Layout

### Top Bar

- left: back button
- right:
  - mark known
  - favorite star
  - add note
  - options menu

### Sections

Display in this order:

1. basic
2. definitions
3. examples
4. related words
5. word graph
6. expansion
7. notes
8. dictionaries

## Interaction Rules

### Mark Known

- tapping `标熟` checks `skipKnownConfirm`
- if false, show bottom sheet:
  - title: `确定标熟吗？`
  - description: `标熟后该单词将不再安排学习和复习`
  - checkbox: `下次不再提示`
  - actions: `取消` and `确定`
- if true, mark known immediately

### Favorite

- star icon reflects `isFavorite`
- unselected uses empty / muted styling
- selected uses filled yellow styling
- action persists immediately

### Note

- action opens note editor
- empty state shows prompt to add note
- saved note is shown in the note section

### Options

- overflow menu includes `纠错`
- menu structure should remain open for future actions

### Examples

- target word occurrences in English examples are highlighted in bold
- matching is case-insensitive

### Dictionaries

- show all visible, matching dictionaries only
- default collapsed
- preserve per-dictionary identity and parsed/raw content

## Error Handling and Empty States

- no dictionary hit:
  - still show header and user actions
  - show empty state for content sections
- partial dictionary failure:
  - continue rendering successful dictionaries
  - failed dictionary may show an inline error in its panel
- SQLite failure:
  - page may still render read-only data
  - mutating actions should surface error feedback

## Testing Scope

### Controller

- loads visible dictionaries in configured order
- aggregates partial results correctly
- toggles favorite and persists
- marks known with and without confirm
- saves note and refreshes state

### Repository

- only visible dictionaries are queried
- per-dictionary failure does not fail the whole lookup
- aggregation rules choose the expected fields
- SQLite mapping round-trips correctly

### Parser

- extracts base fields from representative raw content
- highlights example sentences correctly
- formats related words correctly for display rules

### Widget

- top action buttons exist
- known-confirm bottom sheet behavior is correct
- note section renders empty and filled states
- dictionary section is collapsed by default
- section ordering matches product spec
