# Home Search Shell Design

**Date:** 2026-03-16

## Goal

Add a polished app shell around the existing dictionary import and study flow, with:

- a visually designed home screen inspired by the provided screenshots
- a dedicated "Me" page reached from the top-left menu button
- a dedicated word search page with instant prefix suggestions
- a word detail page that shows structured dictionary content
- recent search history for the last 10 looked-up words

The first version should feel like a complete iOS app home experience without overcommitting to backend features that are not ready yet.

## Product Direction

The interface should feel soft, airy, and intentionally editorial rather than utility-heavy:

- pale warm-gray background
- rounded white surfaces with subtle elevation
- strong contrast between quiet chrome and bold content cards
- large, touch-friendly controls
- a floating bottom navigation capsule

The visual reference is used for rhythm and composition, not pixel-perfect duplication.

## Information Architecture

The app gains a shell structure with three primary sections in bottom navigation:

- `句库`: placeholder page for future content
- `新学习`: the real home dashboard
- `背单词`: the existing import + swipe study experience

Additional pushed pages sit above the shell:

- `我的`: reached from the top-left button on the home dashboard
- `查询词`: reached from the top search bar
- `单词详情`: reached from search results or history

## Search Data Strategy

Search must work even before an MDX dictionary is imported.

The search source is selected with this rule:

1. If the current imported dictionary has entries loaded in memory, search those entries.
2. Otherwise search a built-in sample lexicon bundled in Dart code.

Prefix matches are prioritized, exact matches rank first, and matching is case-insensitive.

## Search History

Recent history is stored in-memory for the current app session.

Rules:

- keep only the latest 10 selected words
- selecting an existing history item moves it to the top
- "清除" clears the list
- history is shown when the query is empty

## Word Detail Page

The detail page uses a dictionary-style layout rather than a flashcard layout.

Sections:

- word header
- pronunciation and part of speech chips
- definition section
- example sentence section
- raw dictionary content section

Missing fields collapse cleanly so incomplete entries still read well.

## Integration With Existing Study Flow

The current `DictionaryController` remains the source of truth for imported dictionary entries and swipe study progression.

The existing dictionary/study page is moved under the `背单词` tab instead of being the whole app home. This preserves current behavior while allowing the app shell to grow around it.

## State Management

State stays simple and local:

- `DictionaryController`: import and study state
- `SearchController`: query text, suggestions, history, active source
- shell-local tab state: selected bottom-nav item

The search controller depends on a `WordLookupRepository` abstraction so future persistence or indexed search can replace the in-memory implementation without rewriting UI code.

## Testing Strategy

Widget tests cover:

- home screen opens the search page
- home screen opens the "Me" page and returns
- search query shows prefix matches immediately
- selecting a result opens word detail
- recent history keeps at most 10 items and supports clearing

Controller tests cover:

- built-in sample words are used when no dictionary is imported
- imported dictionary entries override the sample lexicon
- duplicate history entries are de-duplicated and promoted

## Risks

- search is currently in-memory, so a very large imported dictionary may need indexing later
- current imported entries are limited by the import strategy already in place
- the final visual polish depends on balancing fidelity to the mock with the app's existing study UI

## Recommended Milestone

Ship the shell, search, history, and detail flow first. Once that is stable, we can add persistent search history, article search, and deeper settings screens behind the already-established navigation structure.
