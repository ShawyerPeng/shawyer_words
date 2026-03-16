# Shawyer Words Design

**Date:** 2026-03-16

## Goal

Build the first iOS Flutter app version for word-card learning with two minimal capabilities:

- Import a local `.mdx` dictionary file from the iPhone Files app
- Display imported dictionary entries as swipeable study cards

The first version must stay simple in user-facing behavior while keeping the code structure extensible for full dictionary, study, and review features later.

## Scope

### In Scope

- Create a new Flutter app in the current empty directory
- Support selecting a local `.mdx` file from iOS Files
- Parse real MDX content through an iOS-native bridge
- Normalize parsed entries into a stable Flutter domain model
- Render word cards with pronunciation, definition, part of speech, example sentence, and fallback raw content
- Support left swipe = unknown, right swipe = known
- Persist imported entries and study actions locally for later extension

### Out of Scope for V1

- Search
- Multiple dictionaries management UI
- Spaced repetition scheduling
- Audio playback
- Cloud sync
- Android implementation

## Architecture

The app is split into four layers:

- `presentation`: pages, widgets, gestures, and view states
- `application`: controllers/use-cases coordinating import, card loading, and swipe actions
- `domain`: stable entities and interfaces
- `data`: repository implementations, local persistence, and platform parser integration

The Flutter layer owns app flow and UI. Real MDX parsing is delegated to iOS native code over a `MethodChannel`. This avoids coupling the app to a fragile pure-Dart parser while keeping the parser behind a replaceable interface.

## Core Domain Model

### `WordEntry`

- `id`
- `word`
- `pronunciation`
- `partOfSpeech`
- `definition`
- `exampleSentence`
- `rawContent`

### `DictionarySummary`

- `id`
- `name`
- `sourcePath`
- `importedAt`
- `entryCount`

### `StudyDecision`

- `entryId`
- `decision` (`known` or `unknown`)
- `createdAt`

## Repositories and Services

### `DictionaryRepository`

Responsibilities:

- import a dictionary from a file path
- expose imported dictionary metadata
- expose the next studyable entry set

### `MdxParser`

Responsibilities:

- receive a file path
- parse the real MDX file on iOS
- return normalized entry payloads

The first concrete implementation is `IosMdxParserChannel`.

### `StudyRepository`

Responsibilities:

- save left/right swipe decisions
- provide current progress state

## Data Flow

1. User opens the app and sees an empty state with an import action.
2. User selects a local `.mdx` file from Files.
3. Flutter passes the selected file path to `DictionaryRepository.importDictionary(path)`.
4. The repository calls `MdxParser`.
5. `IosMdxParserChannel` invokes Swift native code through `MethodChannel`.
6. Native code parses the MDX file and returns normalized payloads.
7. Flutter stores dictionary metadata, entries, and later study decisions in SQLite.
8. The card screen loads the current entry and renders the stable `WordEntry` model.
9. Left swipe stores `unknown`, right swipe stores `known`, then advances to the next card.

## UI Design

### Startup State

- Empty state page
- Primary CTA: import dictionary

### Card Screen

- Top: dictionary name and import/reload action
- Center: word card
- Bottom: subtle left/right affordance for unknown/known

### Card Content Priority

Render fields in this order when available:

1. word
2. pronunciation
3. part of speech
4. definition
5. example sentence
6. raw content fallback

If structured extraction fails for some entries, the card still renders `rawContent` so imported dictionary content is always visible.

## Error Handling

- Reject non-`.mdx` files at the app boundary
- Show a specific import failure state when native parsing fails
- Tolerate missing fields without crashing the card UI
- Show an empty-result state if the dictionary imports but yields no usable entries

## Persistence

SQLite is the preferred first persistence layer because future features will need:

- card progression
- learning records
- random selection
- search indexes
- multiple dictionaries

This is a small increase in V1 complexity that avoids reworking storage after the first milestone.

## Testing Strategy

Flutter tests cover app behavior without depending on native parsing:

- import success transitions into card mode
- swipe left records unknown and advances
- swipe right records known and advances
- missing entry fields still render a valid card

Native integration is validated separately with channel contract checks and real-device import verification.

## Initial File Structure

- `lib/app`
- `lib/features/dictionary/domain`
- `lib/features/dictionary/data`
- `lib/features/dictionary/presentation`
- `lib/features/study`
- `test/features/dictionary`
- `ios/Runner`

## Risks

- Real MDX parsing library choice on iOS may constrain implementation details
- Large dictionaries may require paged import or batched persistence
- Dictionary content structure can vary heavily, so fallback rendering is mandatory

## Recommended First Milestone

Ship a single-dictionary import flow with one study deck and reliable fallback content rendering. That validates the hardest integration point, which is real MDX parsing, without overbuilding study logic.
