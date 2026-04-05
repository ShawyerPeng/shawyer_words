# Learning Tab Article UI Design

**Goal:** Replace the placeholder `学习` tab with a polished article-discovery page inspired by the provided reference, and open a dedicated article-reading page when a user taps an article.

## Context

The current `学习` tab is still a placeholder page routed from `lib/app/app_shell.dart`. The user wants a two-step experience matching the supplied visual reference:
- a discovery/list page styled like the left mobile screen
- an article content page styled like the right mobile screen

This should feel visually distinct from the existing study-plan tab while still fitting the app's current soft-card, mobile-first shell.

## Product Scope

### 1. Learning Home Page

The tab becomes a content discovery surface with three sections:
- `Popular`: horizontally scrollable featured cards with large cover images
- `Recent`: vertically stacked article list rows with thumbnail, title, date, and topic tag
- `Explore by Category`: colorful rounded category cards near the bottom

The page should use:
- a light neutral background
- a large rounded white main container
- soft shadows and generous whitespace
- dark, clean typography with restrained secondary metadata

### 2. Article Reading Page

When the user taps an article card or row, the app pushes a dedicated reading page.

The reading page should include:
- a large hero image with overlay title and metadata
- top overlay controls for back and bookmark affordances
- a level-selection segmented control styled after the reference
- an audio control strip styled like the reference for now (UI-first; real audio playback is out of scope)
- the article body in a readable scrolling layout

### 3. Data Model

Use local seeded article data for this iteration.

Each article should contain at least:
- `id`
- `title`
- `category`
- `publishedAtLabel`
- `heroImageUrl`
- `summary`
- `content`
- `difficultyLevels`
- `durationLabel`
- `isPopular`

The category section can be driven by a smaller category model or derived values.

## Architecture

Add a dedicated `learning` feature rather than overloading existing study or home modules.

Recommended structure:
- `lib/features/learning/domain/learning_article.dart`
- `lib/features/learning/data/in_memory_learning_repository.dart`
- `lib/features/learning/presentation/learning_home_page.dart`
- `lib/features/learning/presentation/learning_article_page.dart`

Keep the first version static and self-contained:
- no remote fetch
- no persistence
- no shared controller unless it becomes necessary

A lightweight in-memory repository is enough because the primary goal is UI structure and article-to-detail navigation.

## Interaction Design

### Home page
- Tapping any popular card opens that article
- Tapping any recent list item opens that article
- Category cards are presentational in this iteration and do not need filtering unless it is trivially cheap

### Detail page
- Back button pops the route
- Bookmark button is decorative for now unless a simple local toggle is essentially free
- Difficulty chip group can switch visual selection locally
- Audio controls are visual only in this iteration

## Visual Direction

Use the supplied reference as the primary style cue:
- rounded white mobile sheet floating on a pale background
- large media cards with clipped corners and subtle text overlays
- typography that is clean and editorial without becoming heavy
- metadata in muted gray
- low-noise iconography
- bottom navigation remains consistent with the current app shell

Adaptation notes:
- keep the reference's spatial rhythm and card hierarchy
- do not mimic its exact content taxonomy or copy
- align colors and spacing with the existing app shell so the new tab does not feel imported from a different product

## Error / Empty States

For this iteration, seeded local data means no runtime loading or network error state is needed.

If the article list is empty in tests or future wiring:
- show a simple empty-state card within the same visual system
- keep the page layout stable rather than falling back to a generic placeholder screen

## Testing Scope

Add or update widget tests for:
- the `学习` tab no longer showing the placeholder page
- the learning home page rendering `Popular`, `Recent`, and `Explore by Category`
- tapping an article opening the article detail page
- the detail page rendering article title and body content
- the shell still preserving the bottom navigation layout

## Explicit Non-Goals

This iteration should not include:
- real audio playback
- article bookmarking persistence
- backend article sync
- category filtering logic beyond simple static presentation
- markdown or rich text rendering beyond plain styled text blocks
