# Study Tab Rebuild Design

**Goal:** Replace the current dictionary-package import flow under the `背单词` tab with an official vocabulary-book learning flow, and rebuild the study card screen to match the new product structure.

**Context**

The current `背单词` tab is wired to `DictionaryHomePage`, which centers the experience around importing MDX-based dictionary packages and studying imported entries. That is the wrong product model for this tab. The tab should instead start from a selected official vocabulary book, let the user add official books into "我的词汇表", and use that selection as the current study plan.

## Product Scope

### 1. Study Home

The `背单词` tab becomes a study home page.

When a current vocabulary book exists:
- show a top study-plan card with the selected vocabulary-book title
- show summary counts for `待学习`, `待复习`, `已掌握`, and remaining words
- show a `开始` button to enter study mode
- show a `更改` button to switch the current vocabulary book
- show a weekly calendar-style progress panel
- show a `我的词汇表` section for the user-owned books

When no current vocabulary book exists:
- replace the top card with an onboarding state that asks the user to choose an official vocabulary book
- keep the `我的词汇表` section, but show an empty-state card
- the empty-state action uses `导入词汇`

### 2. Vocabulary Book Selection

The app provides official vocabulary books instead of local file import.

The selection page should:
- show a search box with local filtering
- show official category tabs such as `四级`, `六级`, `考研`, `专四`, `专八`, `托福`, `雅思`, `SAT`
- list official vocabulary books under the selected category
- allow a book to be added into `我的词汇表`
- set the chosen book as the current study plan

`更改` and `导入词汇` both navigate to this page.

### 3. Study Card Screen

The old swipe-driven card screen is replaced with a fixed-layout study page.

The new study page should:
- show a top bar with back, progress text, and icon actions
- show the current word prominently
- show pronunciation / accent information when available
- show a `释义` card that is hidden by default and revealed on tap
- show an `例句` card that is visible by default
- show bottom fixed actions for `不认识` and `认识`
- advance to the next word after either action

This version does not need full spaced-repetition scheduling. It only needs local per-session progression and basic plan counters that can be shown on the home screen.

## Architecture

Create a new study-focused feature layer instead of reusing the dictionary-package import flow.

Recommended structure:
- `study_plan` domain models for official books, owned books, and current plan snapshot
- `study_plan` application controller for home-page state and vocabulary-book selection
- `study_session` application state for the rebuilt card screen
- local in-memory repository implementations seeded with built-in official vocabulary data

Keep the existing dictionary import feature in the repository for now, but remove it from the `背单词` tab navigation path.

## Data Model

### OfficialVocabularyBook

Represents an official system-provided vocabulary book.

Suggested fields:
- `id`
- `category`
- `title`
- `subtitle`
- `wordCount`
- `coverVariant`
- `entries`

### MyVocabularyBook

Represents a book added into the user's owned vocabulary list.

Suggested fields:
- `bookId`
- `addedAt`
- `isCurrentPlan`

### StudyPlanSnapshot

Represents the aggregated study-home card state.

Suggested fields:
- `currentBook`
- `newCount`
- `reviewCount`
- `masteredCount`
- `remainingCount`
- `weekDays`

### StudySessionState

Represents the per-session state of the card learning screen.

Suggested fields:
- `entries`
- `currentIndex`
- `definitionRevealed`
- `knownCount`
- `unknownCount`

## UI Notes

The visual direction should follow the user-provided references:
- light gray page background
- white rounded cards with soft shadows
- restrained green accents for active actions and progress highlights
- fixed bottom learning actions instead of drag gestures
- a compact, mobile-first layout

## Testing Scope

Add or update tests for:
- opening the `背单词` tab without showing `导入词库包`
- empty state when no current plan exists
- selecting an official vocabulary book and returning to a populated study home
- opening the rebuilt study session page from `开始`
- hiding the definition initially and revealing it on tap
- pressing `认识` / `不认识` to move to the next word

## Explicit Non-Goals

This iteration should not include:
- local file import for vocabulary books
- MDX package selection inside the study tab
- spaced-repetition scheduling algorithms
- server sync
- persistence beyond simple local repository abstractions unless it is trivially cheap
