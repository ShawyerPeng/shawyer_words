# Learning Grammar Design

**Goal:** Replace the current placeholder `学习` tab with a real learning home, and add a new `语法` detail page whose UI closely reproduces the provided reference screenshot while keeping the inner card copy in English.

## Context

The current `学习` tab is still wired to `PlaceholderSectionPage`, so the user has no usable learning surface yet. The requested behavior is:

- the `学习` tab should show a real landing page
- tapping the `语法` card should open a new page titled `语法`
- the new page should visually match the rightmost screenshot as closely as possible
- the page title should be Chinese, while the card labels remain English

The existing app already has its own global shell and bottom navigation. We should preserve that shell instead of replacing it with the reference app's bottom tab bar.

## Product Scope

### 1. Learning Home

The `学习` tab becomes a dedicated page instead of a placeholder.

This page should:

- keep the app's existing overall shell and bottom navigation
- present a compact set of learning entry cards
- include a primary `语法` card as the top actionable entry
- push a new page when that card is tapped

### 2. Grammar Detail Page

The new `语法` page should:

- use a light lavender-gray background and white top safe area
- show a left-aligned Chinese title `语法`
- show a bell icon action at the top-right
- display four large pastel cards in a vertically stacked list
- keep English card copy to match the reference composition
- reproduce the rounded corners, spacing, rotation rhythm, and visual weight of the screenshot as closely as practical with native Flutter widgets

## Architecture

Use two new presentation pages:

- `LearningPage` for the `学习` tab surface
- `GrammarPage` for the pushed detail page

Update `AppShell` to route the `学习` tab to `LearningPage`.

Navigation should follow the existing repository pattern and continue using `Navigator.of(context).push(MaterialPageRoute(...))` instead of introducing a new routing system solely for this feature.

## Visual Direction

### Learning Home

The learning home should feel aligned with the rest of the app, not with the reference app's exact shell.

Recommended direction:

- same scaffold background family as the existing app
- rounded white cards with soft shadows
- one featured grammar entry card
- a few secondary learning cards to avoid a sparse placeholder look

### Grammar Page

The grammar page should prioritize reference fidelity over reuse.

Important visual signals:

- large rounded rectangles with soft pastel fills
- slightly alternating card tilt to mimic the screenshot
- centered icon + title + subtitle composition
- decorative corner book-stack motifs drawn with Flutter primitives and icons
- generous vertical spacing and wide side padding

## Content Model

Use static local presentation data for this iteration.

Suggested cards:

1. `Idioms & Phrases`
2. `Vegetable, fruits etc`
3. `Proverbs`
4. `Daily speaking`

All cards use `More than 200+ words` as the subtitle for now.

## Testing Scope

Add widget coverage for:

- the `学习` tab showing real learning content instead of the placeholder text
- tapping the grammar entry opening the new `语法` page
- the grammar page rendering the expected key English card titles

## Non-Goals

This iteration should not include:

- backend-driven grammar content
- detail pages for the inner grammar cards
- replacing the app-wide bottom navigation
- adding image assets purely for decoration
