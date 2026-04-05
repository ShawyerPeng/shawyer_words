# Learning Grammar Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the `学习` placeholder tab with a learning landing page and add a reference-matched `语法` page reachable from the grammar card.

**Architecture:** Add dedicated presentation pages for the learning tab and grammar detail screen, wire the learning tab through `AppShell`, and verify the interaction with focused widget tests.

**Tech Stack:** Flutter, Material 3, widget tests

---

### Task 1: Build the learning tab surface

**Files:**
- Create: `lib/features/learning/presentation/learning_page.dart`
- Modify: `lib/app/app_shell.dart`
- Test: `test/widget_test.dart`

**Step 1: Write the failing test**

Assert that opening the app shows a real learning landing surface under the `学习` tab, not the old placeholder copy.

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL once the assertion targets the new learning content.

**Step 3: Write minimal implementation**

Create `LearningPage` with:

- a featured `语法` entry card
- secondary learning cards for visual balance
- tap handling that opens the grammar page

Update `AppShell` so the `学习` tab uses `LearningPage`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

### Task 2: Implement the grammar page reference UI

**Files:**
- Create: `lib/features/learning/presentation/grammar_page.dart`
- Modify: `lib/features/learning/presentation/learning_page.dart`

**Step 1: Write the failing test**

Assert that tapping the featured grammar card pushes a page titled `语法` and shows the expected English card labels.

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the page does not exist yet.

**Step 3: Write minimal implementation**

Build `GrammarPage` with:

- custom top bar matching the screenshot rhythm
- stacked pastel cards with alternating tilt
- centered icon/title/subtitle content
- decorative book-stack corner ornaments

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

### Task 3: Verify formatting and regressions

**Files:**
- Modify: `lib/app/app_shell.dart`
- Modify: `test/widget_test.dart`
- Create/Modify: `lib/features/learning/presentation/*.dart`

**Step 1: Format**

Run: `dart format lib/app/app_shell.dart lib/features/learning/presentation/learning_page.dart lib/features/learning/presentation/grammar_page.dart test/widget_test.dart`

**Step 2: Run focused verification**

Run: `flutter test test/widget_test.dart`

**Step 3: Run broader smoke verification**

Run: `flutter test`

Expected: PASS, or report any unrelated pre-existing failures explicitly.
