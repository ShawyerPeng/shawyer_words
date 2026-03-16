# Home Figma Compact Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tighten the current layered homepage capture so the Figma result feels more compact, with smaller typography and denser section spacing while preserving the same structure.

**Architecture:** Keep the current semantic HTML capture page and adjust only the density-related CSS values and a few text line breaks. Verify the DOM structure with the local shell script, then re-capture into the existing Figma file if the MCP quota permits further imports.

**Tech Stack:** Static HTML/CSS, local shell verification script, optional Figma MCP `generate_figma_design`.

---

### Task 1: Define The Compact Density Pass

**Files:**
- Inspect: `output/figma-capture/index.html`
- Inspect: `docs/plans/2026-03-16-home-figma-layered-design.md`

**Step 1: Identify oversized areas**

Confirm which current sections feel too loose:

- top action row
- hero card
- inter-section gaps
- article card
- bottom navigation

**Step 2: Set density targets**

Choose coordinated reductions for:

- font size
- line height
- padding
- gap
- fixed heights

### Task 2: Update The Capture Page CSS

**Files:**
- Modify: `output/figma-capture/index.html`

**Step 1: Tighten global rhythm**

Reduce the main content stack spacing and any oversized top/bottom paddings.

**Step 2: Tighten module footprints**

Reduce control heights, hero dimensions, course-card interior spacing, article-card padding, and bottom-nav height.

**Step 3: Tighten typography**

Reduce text sizes and line heights in a coordinated way so hierarchy remains clear.

### Task 3: Adjust Markup Only Where Needed

**Files:**
- Modify: `output/figma-capture/index.html`

**Step 1: Stabilize text wrapping**

If needed, add or remove explicit line breaks in hero copy or similar text blocks to keep Figma imports readable after the density pass.

**Step 2: Preserve semantic structure**

Do not remove the heading, paragraph, section, or button semantics that improve the Figma layer structure.

### Task 4: Run Structural Verification

**Files:**
- Verify: `tool/verify_figma_capture_structure.sh`
- Verify: `output/figma-capture/index.html`

**Step 1: Run the verification script**

Run: `./tool/verify_figma_capture_structure.sh`
Expected: `Figma capture structure check passed for output/figma-capture/index.html`

**Step 2: Fix any missing structural hooks**

If the script fails, restore the required section classes and aria labels before moving on.

### Task 5: Attempt Figma Re-capture

**Files:**
- Target Figma file: `https://www.figma.com/design/7yMHos3aW10IK039iJtWXn/ShawyerWords`

**Step 1: Create a new capture ID**

Call `generate_figma_design` with:

- `outputMode: "existingFile"`
- `fileKey: "7yMHos3aW10IK039iJtWXn"`

**Step 2: Open the local capture page with the hash URL**

Use the generated capture ID and endpoint values.

**Step 3: Poll to completion**

Use the same capture ID until Figma MCP reports `completed`.

**Step 4: Record the node URL or quota issue**

If capture succeeds, save the new node URL. If quota blocks further review calls, report that clearly.

### Task 6: Close Out

**Files:**
- Keep: `output/figma-capture/index.html`
- Keep: `tool/verify_figma_capture_structure.sh`

**Step 1: Stop any local server**

Terminate the local HTTP server after capture or after any blocked attempt.

**Step 2: Report the result with evidence**

Return the updated Figma node URL if available and mention the verification command output.
