# Home Figma Layered Rebuild Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the current Flutter home screen as a real HTML structure and capture it into the existing `ShawyerWords` Figma file as editable design layers.

**Architecture:** Use the current Flutter home screen as the visual source of truth, then recreate that screen in a dedicated local HTML capture page with semantic containers and real text. Serve that page locally and use Figma MCP `generate_figma_design` in `existingFile` mode to capture it into the target Figma file. Iterate once if the generated layer structure is too flat or poorly grouped.

**Tech Stack:** Flutter source inspection, static HTML/CSS, local `python3 -m http.server`, Figma MCP `generate_figma_design`.

---

### Task 1: Inspect The Current Home Screen Precisely

**Files:**
- Inspect: `lib/features/home/presentation/home_dashboard_page.dart`
- Inspect: `lib/app/app_shell.dart`
- Inspect: `output/playwright/home-dashboard.png`

**Step 1: Confirm the current visual source**

Read the Flutter home screen implementation and compare it with the existing screenshot artifact.

**Step 2: Record the sections to rebuild**

List the exact sections, labels, and card variants that appear on the screen:

- top icon buttons and search capsule
- coach card
- library switcher
- three course cards
- article card
- bottom nav

**Step 3: Capture any missing visual details**

If needed, refresh the screenshot artifact before implementation so the HTML rebuild follows the current app state.

### Task 2: Replace Screenshot Capture With Structured HTML

**Files:**
- Modify: `output/figma-capture/index.html`
- Inspect: `output/figma-capture/home-dashboard.png`

**Step 1: Remove the screenshot-only layout**

Replace the single `<img>` capture page with semantic HTML containers representing the actual UI.

**Step 2: Build the editable structure**

Create sections and sub-elements for:

- status bar
- top controls
- coach card
- switcher tabs
- horizontal course cards
- article card
- bottom navigation

**Step 3: Mirror current styling**

Recreate the visual look with CSS:

- background gradient and page tone
- white elevated cards
- rounded controls
- green accents
- typography hierarchy
- decorative shapes inside cards

### Task 3: Make The DOM Friendly For Figma Layers

**Files:**
- Modify: `output/figma-capture/index.html`

**Step 1: Clean up naming and grouping**

Use semantic class structure so the resulting Figma output groups logically.

**Step 2: Preserve editability**

Ensure all visible text stays as real text nodes and that decorative shapes are separate elements rather than background images where practical.

**Step 3: Minimize flattening triggers**

Avoid unnecessary transforms, filters, or CSS tricks that might cause the Figma import to flatten parts of the layout.

### Task 4: Serve And Verify The Capture Page

**Files:**
- Verify: `output/figma-capture/index.html`

**Step 1: Start the local server**

Run: `python3 -m http.server 3000`
Expected: local page served from `output/figma-capture`

**Step 2: Verify the page loads**

Run: `curl --noproxy '*' -I http://127.0.0.1:3000/`
Expected: `HTTP/1.0 200 OK`

**Step 3: Open the page manually if needed**

Run the Figma capture hash URL in the browser and visually confirm the reconstructed page appears correctly before capture.

### Task 5: Capture Into The Existing Figma File

**Files:**
- Target Figma file: `https://www.figma.com/design/7yMHos3aW10IK039iJtWXn/ShawyerWords`

**Step 1: Create a capture ID**

Call Figma MCP `generate_figma_design` with:

- `outputMode: "existingFile"`
- `fileKey: "7yMHos3aW10IK039iJtWXn"`

**Step 2: Open the local capture URL**

Open the localhost page with the generated `figmacapture` hash and endpoint values.

**Step 3: Poll until completed**

Use the same `captureId` until Figma MCP returns `completed`.

**Step 4: Record the created node URL**

Keep the returned Figma node link so the user can open the editable frame directly.

### Task 6: Validate Layer Quality And Iterate Once If Needed

**Files:**
- Modify as needed: `output/figma-capture/index.html`

**Step 1: Inspect the generated frame in Figma**

Confirm the frame has editable text and separately selectable major containers.

**Step 2: If grouping is poor, refine the HTML**

Adjust DOM nesting or decorative element structure for cleaner layers.

**Step 3: Re-capture once**

Repeat the capture flow into the same Figma file and compare the result.

### Task 7: Close Out And Preserve The Capture Asset

**Files:**
- Keep: `output/figma-capture/index.html`
- Keep: `output/figma-capture/home-dashboard.png`

**Step 1: Stop the local server**

Terminate the local HTTP server after capture is complete.

**Step 2: Keep the capture page in the repo workspace**

Preserve the structured HTML capture page so future screens can reuse the same workflow.

**Step 3: Report the result**

Return the final Figma node URL and summarize any remaining visual or layer-structure limitations.
