# Home Figma Layered Rebuild Design

**Date:** 2026-03-16

## Goal

Rebuild the current app home screen as a fully editable, layered Figma frame instead of a screenshot capture.

The output should preserve the existing visual composition while making text, cards, buttons, and layout containers individually editable in Figma.

## Product Direction

The rebuilt frame should remain faithful to the current shipped home screen:

- pale gray editorial background
- rounded white surfaces with soft elevation
- green as the active accent
- strong card-based hierarchy
- floating bottom navigation capsule

This is a structural rebuild, not a visual redesign.

## Deliverable

Create a new editable home screen frame inside the existing Figma file:

- file: `ShawyerWords`
- output type: standard Figma design layers
- target fidelity: visually aligned with the current app home screen

The first version covers only the default home screen state.

## Scope

Included:

- status bar
- top actions row
- AI coach hero card
- learning library switcher row
- horizontal course card rail
- article/content card
- floating bottom navigation

Excluded:

- search page
- me page
- dictionary page
- pressed states
- empty states
- alternate responsive layouts

## Rebuild Strategy

The layered Figma version will be generated from a purpose-built local HTML page, not from the Flutter runtime screenshot.

Reasoning:

- the current screenshot import produces a bitmap-like editing experience
- Figma MCP `generate_figma_design` creates better editable layers from real DOM structure
- rebuilding the home screen in HTML gives control over semantic structure, editable text, and layout grouping

The HTML page should mirror the current screen using:

- real text nodes
- separate card containers
- separate icon and decorative shape layers where practical
- Auto Layout-friendly grouping in the generated Figma output

## Figma Layer Structure

The target frame should be organized into semantic top-level sections:

- `Status Bar`
- `Top Actions`
- `Coach Hero Card`
- `Library Switcher`
- `Course Carousel`
- `Article Card`
- `Bottom Navigation`

Repeated or structurally similar elements should use consistent naming patterns such as:

- `Button / Icon / Menu`
- `Button / Search / Hero`
- `Card / Coach / Primary`
- `Card / Course / Warmup`
- `Card / Course / IELTS`
- `Nav Item / Home / Active`

## Layout Rules

The generated frame should be easy to continue editing in Figma:

- use vertical page structure with consistent section spacing
- keep primary containers rectangular and semantic
- preserve editable text for all labels and headlines
- keep decorative circles and accents as separate shapes where possible
- avoid flattening shadows, fills, or rounded containers into images

## Fidelity Rules

Keep the following visually consistent with the current app screen:

- spacing rhythm
- card sizing and radius
- hierarchy between quiet chrome and bold content surfaces
- green active states
- course card balance, label placement, and metadata rows
- floating bottom bar proportions

Small implementation adjustments are acceptable when needed to preserve editability:

- replace non-portable icons with visually equivalent editable vectors
- express shadows as standard effects
- split decorative background shapes into independent layers

## Validation Criteria

The rebuild is successful when:

- the Figma frame is made of editable layers, not a single image
- text layers can be directly edited in Figma
- major containers can be moved independently
- the frame remains visually close to the current home screen
- the result is easier to annotate, duplicate, and extend than the screenshot capture

## Risks

- some Flutter icon shapes may not transfer exactly and may require equivalent vectors
- Figma MCP may group certain DOM structures differently than ideal, which can require iterative recapture
- pixel-perfect parity depends on careful HTML reconstruction before capture

## Recommended Milestone

1. Build a 1:1 local HTML reconstruction of the home screen.
2. Capture it into the existing Figma file with Figma MCP.
3. Review the resulting layer structure in Figma.
4. If needed, refine the HTML structure and recapture once more for cleaner layer grouping.
