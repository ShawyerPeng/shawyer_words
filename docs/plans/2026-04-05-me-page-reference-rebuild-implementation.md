# Me Page Reference Rebuild Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the `我的` page to match the provided reference styling while preserving all existing first-level entries and navigation targets.

**Architecture:** Keep routing and data flow unchanged, rewrite `MePage` composition into a reference-inspired header, three shortcut cards, membership banner, and grouped action panels, then refresh widget tests to assert the retained entry behavior.

**Tech Stack:** Flutter, Material 3, widget tests

---

### Task 1: Rewrite the Me page layout shell

**Files:**
- Modify: `lib/features/me/presentation/me_page.dart`

**Step 1: Rebuild the page structure**

Replace the current stacked utility cards with:
- profile header
- three shortcut cards
- membership banner
- grouped lower action panels

**Step 2: Preserve existing tap behavior**

Keep the existing destinations for:
- `词典库管理`
- `通用设置`
- `学习设置`
- `数据统计`
- `会员中心`
- `帮助与反馈`

**Step 3: Align spacing and colors to the reference**

Tune:
- background color
- radii
- CTA pill styling
- icon scale and icon tint
- card spacing and insets

**Step 4: Format files**

Run `dart format` on modified files.

### Task 2: Update widget tests for retained entry behavior

**Files:**
- Modify: `test/features/me/presentation/me_page_test.dart`

**Step 1: Refresh assertions**

Keep assertions for all preserved first-level entries.

**Step 2: Keep navigation tests**

Ensure tapping `帮助与反馈` and `词典库管理` still opens the correct pages.

**Step 3: Keep layout regression coverage**

Retain or adapt the bottom inset check and one spacing-oriented regression check appropriate to the new layout.

### Task 3: Run targeted verification

**Files:**
- Modify if needed: `lib/features/me/presentation/me_page.dart`
- Modify if needed: `test/features/me/presentation/me_page_test.dart`

**Step 1: Static analysis**

Run:
```bash
flutter analyze lib/features/me/presentation/me_page.dart test/features/me/presentation/me_page_test.dart
```

**Step 2: Widget tests**

Run:
```bash
flutter test --no-pub test/features/me/presentation/me_page_test.dart
```

**Step 3: Fix any visual/test regressions and rerun**

Only finish after both commands pass.
