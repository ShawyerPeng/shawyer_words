# Study Session Detail Link Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `查看完整释义` action to the rebuilt study session so users can jump from the revealed definition to the existing word detail page.

**Architecture:** Keep the detail page unchanged and extend the study session UI only. The reveal state stays in `StudySessionController`; the session page owns navigation and passes the current `WordEntry` into the existing `WordDetailPage`.

**Tech Stack:** Flutter, widget tests, ChangeNotifier

---

### Task 1: Add a failing widget test for the new detail action

**Files:**
- Modify: `test/features/study/presentation/study_session_page_test.dart`
- Modify: `lib/features/study/presentation/study_session_page.dart`
- Modify: `lib/features/study/presentation/word_card_view.dart`

**Step 1: Write the failing test**

Add assertions that:
- `查看完整释义` is hidden before reveal
- it appears after tapping `释义`
- tapping it opens `WordDetailPage`

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study/presentation/study_session_page_test.dart`
Expected: FAIL because the button and navigation do not exist yet.

**Step 3: Write minimal implementation**

Add a callback path from the study session page into the definition card UI and push the existing detail page with the current entry.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study/presentation/study_session_page_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add docs/plans/2026-03-16-study-session-detail-link-implementation.md test/features/study/presentation/study_session_page_test.dart lib/features/study/presentation/study_session_page.dart lib/features/study/presentation/word_card_view.dart
git commit -m "feat: link study session to word detail page"
```
