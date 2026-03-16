# Home Figma Compact Layout Design

**Date:** 2026-03-16

## Goal

Tighten the layered Figma home screen so it feels denser, calmer, and more product-like without changing the overall information architecture.

The revised version should preserve the existing module order and visual language while reducing loose spacing, oversized controls, and inflated typography.

## Product Direction

This is a density refinement, not a redesign.

The page should still feel:

- soft and light
- card-based
- iOS-inspired
- education-focused

But it should look more mature and compact:

- smaller type
- shorter cards
- tighter section rhythm
- less empty space above and between modules

## Compactness Target

Use a medium-density adjustment:

- reduce visible font sizes by roughly half a step to one full step
- reduce vertical section gaps by roughly 15% to 20%
- reduce large control heights where possible
- reduce card padding where it currently feels airy rather than intentional

The result should fit more useful content into the first screen without becoming crowded or dashboard-like.

## Scope

Adjust:

- top actions row
- search field height and placeholder scale
- coach hero card height and internal spacing
- section spacing between all primary blocks
- library switcher vertical footprint
- course card height, title balance, and metadata spacing
- article card padding
- bottom navigation height and label density

Do not change:

- page structure
- color palette
- card order
- core card identities
- floating bottom navigation concept

## Design Rules

### Typography

- reduce search placeholder size slightly
- reduce hero title and subtitle sizes
- reduce section-title scale slightly
- reduce nav label size or effective label footprint
- keep enough hierarchy between headings, body text, and metadata

### Layout

- tighten global vertical rhythm first
- shrink large fixed heights before shrinking widths
- shorten buttons and cards in a coordinated way
- keep the course rail readable, even if only one and a half cards are visible

### Visual Balance

- preserve generous rounded corners
- keep shadows soft but avoid oversized white surfaces
- maintain the active green emphasis
- avoid a “compressed” or “busy” feeling by tightening consistently rather than only shrinking text

## Validation Criteria

The compact version is successful when:

- the screen reads as the same homepage, only more disciplined
- text is still legible in Figma
- the hero card no longer dominates the page vertically
- section transitions feel closer together
- the first screen shows more content before the bottom navigation takes over

## Risks

- shrinking text too aggressively can worsen Figma import wrapping for Chinese text
- shrinking controls unevenly can make one section feel visually off-scale
- overly tight values can make the page feel utilitarian instead of polished

## Recommended Milestone

1. Update the HTML capture page with coordinated density changes.
2. Run the local structure verification script.
3. Re-capture into the same Figma file if MCP quota allows.
4. Review the imported frame for text wrapping and perceived density.
