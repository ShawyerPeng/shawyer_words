# Home Figma Compact CJK Refinement Design

**Date:** 2026-03-16

## Goal

Push the layered homepage one density level tighter than the previous compact pass, while specifically improving Chinese text behavior in the Figma import.

The page should feel more compressed and product-grade, but Chinese labels and headlines must remain readable and intentional after capture.

## Product Direction

This pass focuses on two things together:

- stronger compression of overall layout density
- explicit stabilization of Chinese text layout for Figma

The page should feel:

- more compact
- more disciplined
- less floaty
- still soft and polished

## Compactness Target

Compared with the previous compact version:

- reduce vertical spacing by another small step
- reduce typography by another half-step where safe
- compress the top controls, hero card, course cards, article card, and bottom nav together
- keep enough breathing room to avoid a utility-dashboard feel

## Chinese Text Refinement Rules

Chinese copy should not rely on browser wrapping alone.

Use explicit structure for Chinese-heavy text where needed:

- break hero title and subtitle intentionally into stable lines
- keep search placeholder on one line
- ensure bottom-nav labels do not collapse to single characters
- keep course titles readable inside reduced card sizes

## Scope

Adjust:

- search placeholder sizing and box width balance
- hero copy line breaks and text box width
- section-title scale
- course-card title scale and content area height
- bottom navigation label stability

Preserve:

- semantic structure for Figma layers
- the current homepage module order
- overall color and shape language

## Validation Criteria

The refinement is successful when:

- the page is visibly denser than node `21:2`
- Chinese text remains readable after Figma capture
- nav labels stay intact as full words
- hero copy feels deliberately typeset rather than auto-wrapped
- no section looks visually starved or broken

## Risks

- excessive compression can make imported text look mechanically cramped
- tighter dimensions can reintroduce Figma text clipping
- Chinese line management may improve readability but create more separate text nodes

## Recommended Milestone

1. Update the local capture HTML with a second density pass.
2. Add stable line structure for Chinese-heavy text.
3. Verify local structure.
4. Re-capture into the Figma file if MCP import calls remain available.
