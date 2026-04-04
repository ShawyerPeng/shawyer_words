# Study Task Planning Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a dedicated daily study planner that selects, prioritizes, and paces review/new-word work outside the study home page UI.

**Architecture:** Extract task selection into a pure application-layer planner under `study_plan`, backed by explicit plan models. The home page will assemble a planning request, call the planner, and consume the returned queue instead of building a session inline.

**Tech Stack:** Flutter, Dart, ChangeNotifier, existing FSRS domain models, widget tests, pure Dart unit tests

---

### Task 1: Add planner domain models

**Files:**
- Create: `lib/features/study_plan/domain/daily_study_plan.dart`
- Create: `lib/features/study_plan/domain/daily_study_plan_request.dart`
- Create: `lib/features/study_plan/domain/study_task_source.dart`
- Test: `test/features/study_plan/application/daily_task_planner_test.dart`

**Step 1: Write the failing test**

```dart
test('returns an empty plan when the selected book has no entries', () {
  final planner = DailyTaskPlanner();
  final plan = planner.plan(
    DailyStudyPlanRequest(
      book: emptyBook,
      bookEntries: const <WordEntry>[],
      cardsByWord: const <String, FsrsCard>{},
      knowledgeByWord: const <String, WordKnowledgeRecord>{},
      settings: const AppSettings.defaults(),
      now: DateTime.utc(2026, 4, 5),
    ),
  );

  expect(plan.mixedQueue, isEmpty);
  expect(plan.summary.reviewCount, 0);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "returns an empty plan when the selected book has no entries"`

Expected: FAIL because planner/models do not exist yet.

**Step 3: Write minimal implementation**

Create immutable models with the fields from the approved design and make `DailyStudyPlan.empty()` available for no-work scenarios.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "returns an empty plan when the selected book has no entries"`

Expected: PASS

**Step 5: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.

### Task 2: Introduce the planner skeleton with new-vs-review classification

**Files:**
- Create: `lib/features/study_plan/application/daily_task_planner.dart`
- Modify: `test/features/study_plan/application/daily_task_planner_test.dart`

**Step 1: Write the failing test**

```dart
test('places due cards into review buckets before new words', () {
  final plan = planner.plan(requestWithOneDueCardAndOneFreshWord);

  expect(plan.mustReview.map((item) => item.entry.word), contains('abandon'));
  expect(plan.newWords.map((item) => item.entry.word), contains('ability'));
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "places due cards into review buckets before new words"`

Expected: FAIL because planner classification is missing.

**Step 3: Write minimal implementation**

Implement `DailyTaskPlanner.plan()` to:

- normalize book words
- map due cards into review candidates
- map unseen/unmastered words into new-word candidates
- return categorized lists without advanced scoring yet

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "places due cards into review buckets before new words"`

Expected: PASS

**Step 5: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.

### Task 3: Add backlog-aware budgets and deferred work

**Files:**
- Modify: `lib/features/study_plan/application/daily_task_planner.dart`
- Modify: `lib/features/study_plan/domain/daily_study_plan.dart`
- Modify: `test/features/study_plan/application/daily_task_planner_test.dart`

**Step 1: Write the failing test**

```dart
test('reduces new-word budget when review backlog is heavy', () {
  final plan = planner.plan(requestWithHeavyBacklog);

  expect(plan.summary.backlogLevel, StudyBacklogLevel.heavy);
  expect(plan.newWords.length, lessThan(requestWithHeavyBacklog.settings.dailyStudyTarget));
  expect(plan.deferredWords, isNotEmpty);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "reduces new-word budget when review backlog is heavy"`

Expected: FAIL because budgets and deferred tracking are missing.

**Step 3: Write minimal implementation**

Add:

- backlog-level derivation
- `reviewBudget` and `newBudget`
- heavy-backlog new-word reduction
- `deferredWords` population
- `DailyStudyPlanSummary` counts and labels

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "reduces new-word budget when review backlog is heavy"`

Expected: PASS

**Step 5: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.

### Task 4: Add review priority scoring and mixed queue pacing

**Files:**
- Modify: `lib/features/study_plan/application/daily_task_planner.dart`
- Modify: `lib/features/study_plan/domain/study_task_source.dart`
- Modify: `test/features/study_plan/application/daily_task_planner_test.dart`

**Step 1: Write the failing test**

```dart
test('builds a balanced mixed queue with higher-risk reviews first', () {
  final plan = planner.plan(requestWithThreeReviewsAndTwoNewWords);

  expect(plan.mixedQueue.take(4).map((item) => item.source), <StudyTaskSource>[
    StudyTaskSource.mustReview,
    StudyTaskSource.normalReview,
    StudyTaskSource.normalReview,
    StudyTaskSource.newWord,
  ]);
  expect(plan.mustReview.first.priorityScore, greaterThan(plan.normalReview.last.priorityScore));
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "builds a balanced mixed queue with higher-risk reviews first"`

Expected: FAIL because scoring and pacing are not implemented yet.

**Step 3: Write minimal implementation**

Implement:

- deterministic review priority scoring
- `mustReview` vs `normalReview` split
- balanced-mode `3 review : 1 new` queue builder
- `reasonTags` for explainability

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "builds a balanced mixed queue with higher-risk reviews first"`

Expected: PASS

**Step 5: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.

### Task 5: Integrate the planner into the study home page

**Files:**
- Modify: `lib/features/study_plan/presentation/study_home_page.dart`
- Modify: `test/features/study_plan/presentation/study_home_page_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('start study uses planner queue instead of simple review-plus-new concatenation', (tester) async {
  await tester.pumpWidget(buildStudyHomePageWithPlannerScenario());
  await tester.tap(find.text('开始学习'));
  await tester.pumpAndSettle();

  expect(recordedSessionWords, <String>['due-a', 'due-b', 'due-c', 'new-a']);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/presentation/study_home_page_test.dart --plain-name "start study uses planner queue instead of simple review-plus-new concatenation"`

Expected: FAIL because the home page still builds the queue inline.

**Step 3: Write minimal implementation**

Update `study_home_page.dart` to:

- construct `DailyStudyPlanRequest`
- call `DailyTaskPlanner.plan()`
- flatten `plan.mixedQueue` into the `StudySessionPage` input
- preserve the existing empty-state snackbar behavior

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/presentation/study_home_page_test.dart --plain-name "start study uses planner queue instead of simple review-plus-new concatenation"`

Expected: PASS

**Step 5: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.

### Task 6: Add phase-1 summary surfacing and probe scaffolding

**Files:**
- Modify: `lib/features/study_plan/domain/daily_study_plan.dart`
- Modify: `lib/features/study_plan/application/daily_task_planner.dart`
- Modify: `lib/features/study_plan/presentation/study_home_page.dart`
- Modify: `test/features/study_plan/application/daily_task_planner_test.dart`
- Modify: `test/features/study_plan/presentation/study_home_page_test.dart`

**Step 1: Write the failing test**

```dart
test('summary exposes backlog messaging and leaves probe words disabled by default', () {
  final plan = planner.plan(requestWithKnownWords);

  expect(plan.summary.reasonSummary, isNotEmpty);
  expect(plan.probeWords, isEmpty);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "summary exposes backlog messaging and leaves probe words disabled by default"`

Expected: FAIL because summary reasons and probe scaffolding are incomplete.

**Step 3: Write minimal implementation**

Add:

- `summary.reasonSummary`
- stable strategy labels for balanced mode
- empty `probeWords` behavior with clear future extension points
- optional lightweight home-page copy that reads from the summary

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart --plain-name "summary exposes backlog messaging and leaves probe words disabled by default"`

Expected: PASS

**Step 5: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.

### Task 7: Full verification

**Files:**
- Test: `test/features/study_plan/application/daily_task_planner_test.dart`
- Test: `test/features/study_plan/presentation/study_home_page_test.dart`
- Test: `test/features/study/presentation/study_session_page_test.dart`

**Step 1: Run focused planner and integration tests**

Run: `flutter test test/features/study_plan/application/daily_task_planner_test.dart test/features/study_plan/presentation/study_home_page_test.dart test/features/study/presentation/study_session_page_test.dart`

Expected: PASS

**Step 2: Run targeted analyzer verification**

Run: `flutter analyze lib/features/study_plan lib/features/study test/features/study_plan test/features/study`

Expected: No issues found.

**Step 3: Review phase-1 scope**

Confirm that the implementation includes:

- extracted planner
- backlog-aware budgets
- mixed queue
- summary support
- no active probe scheduling yet

**Step 4: Checkpoint**

Skip git unless the user explicitly asks for checkpoint commits.
