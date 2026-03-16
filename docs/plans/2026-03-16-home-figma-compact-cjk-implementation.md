# Home Figma Compact CJK Refinement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the layered homepage denser than the current compact version and improve Chinese text layout stability in the resulting Figma frame.

**Architecture:** Continue using the semantic HTML capture page as the source of truth. Tighten only size, spacing, and line-breaking behavior, then verify the DOM hooks with the local shell script and re-capture into the existing Figma file if MCP import remains available.

**Tech Stack:** Static HTML/CSS, local shell verification script, optional Figma MCP `generate_figma_design`.

---

### Task 1: Define The Second Density Pass

**Files:**
- Inspect: `output/figma-capture/index.html`
- Inspect: `docs/plans/2026-03-16-home-figma-compact-design.md`

**Step 1: Identify remaining loose areas**

Focus on:

- top actions
- hero card
- course rail
- bottom navigation

**Step 2: Identify unstable Chinese text areas**

Focus on:

- search placeholder
- hero title
- hero subtitle
- bottom-nav labels

### Task 2: Tighten CSS Values Again

**Files:**
- Modify: `output/figma-capture/index.html`

**Step 1: Reduce global vertical rhythm**

Lower major section gaps and outer paddings one more step.

**Step 2: Compress component heights**

Reduce top-action sizes, hero-card footprint, course-card dimensions, article-card padding, and bottom-nav footprint.

**Step 3: Reduce typography**

Reduce visible text sizes carefully while preserving hierarchy.

### Task 3: Stabilize Chinese Text Layout

**Files:**
- Modify: `output/figma-capture/index.html`

**Step 1: Add explicit line management**

Use intentional line breaks or line wrappers for Chinese-heavy hero copy.

**Step 2: Protect one-line labels**

Ensure the search label and nav labels keep enough width and non-wrapping behavior.

**Step 3: Keep Figma-friendly semantics**

Do not remove semantic headings, paragraphs, or buttons.

### Task 4: Verify Local Structure

**Files:**
- Verify: `tool/verify_figma_capture_structure.sh`

**Step 1: Run the verification script**

Run: `./tool/verify_figma_capture_structure.sh`
Expected: `Figma capture structure check passed for output/figma-capture/index.html`

### Task 5: Re-capture If Import Calls Still Work

**Files:**
- Target Figma file: `https://www.figma.com/design/7yMHos3aW10IK039iJtWXn/ShawyerWords`

**Step 1: Create a new capture ID**

Call `generate_figma_design` in `existingFile` mode.

**Step 2: Open the local capture page with the hash URL**

Use the generated capture ID and endpoint values.

**Step 3: Poll until completed**

Use the same capture ID until completion.

**Step 4: Report success or quota block**

Return the node URL if successful; otherwise state the precise MCP limit reached.
