# Study Tab Rebuild Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the study tab's dictionary-package import flow with an official vocabulary-book study home, selection flow, and rebuilt fixed-layout study session.

**Architecture:** Add a small study-plan domain and controller layer backed by built-in local data, route the `背单词` tab through the new pages, and replace the swipe card interaction with an explicit session page that controls reveal and next-word actions. Keep the old dictionary import feature in place but disconnected from the study tab.

**Tech Stack:** Flutter, ChangeNotifier, widget tests, in-memory repositories

---

### Task 1: Define study-plan domain models and seeded repository

**Files:**
- Create: `lib/features/study_plan/domain/official_vocabulary_book.dart`
- Create: `lib/features/study_plan/domain/study_plan_models.dart`
- Create: `lib/features/study_plan/domain/study_plan_repository.dart`
- Create: `lib/features/study_plan/data/in_memory_study_plan_repository.dart`
- Test: `test/features/study_plan/data/in_memory_study_plan_repository_test.dart`

**Step 1: Write the failing test**

```dart
test('loads official books and sets selected book as current plan', () async {
  final repository = InMemoryStudyPlanRepository();

  final initial = await repository.loadOverview();
  expect(initial.currentBook, isNull);

  await repository.selectBook('ielts-complete');

  final updated = await repository.loadOverview();
  expect(updated.currentBook?.id, 'ielts-complete');
  expect(updated.myBooks, isNotEmpty);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/data/in_memory_study_plan_repository_test.dart`
Expected: FAIL because the new repository and models do not exist yet.

**Step 3: Write minimal implementation**

Create immutable domain models for:
- official vocabulary books
- owned vocabulary books
- study home overview

Seed the repository with official categories and sample books for:
- 四级
- 六级
- 考研
- 专四
- 专八
- 托福
- 雅思
- SAT

Implement:
- `loadOverview()`
- `loadOfficialBooks()`
- `selectBook(String bookId)`
- `searchBooks(String query, {String? category})`

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/data/in_memory_study_plan_repository_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/study_plan test/features/study_plan
git commit -m "feat: add study plan repository"
```

### Task 2: Add a controller for study-home state

**Files:**
- Create: `lib/features/study_plan/application/study_plan_controller.dart`
- Test: `test/features/study_plan/application/study_plan_controller_test.dart`

**Step 1: Write the failing test**

```dart
test('load exposes empty state then selected current plan', () async {
  final controller = StudyPlanController(repository: InMemoryStudyPlanRepository());

  await controller.load();
  expect(controller.state.currentBook, isNull);

  await controller.selectBook('ielts-complete');
  expect(controller.state.currentBook?.id, 'ielts-complete');
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart`
Expected: FAIL because the controller does not exist yet.

**Step 3: Write minimal implementation**

Implement controller state for:
- loading / ready / failure
- official categories
- current book
- my books
- filtered selection results

Expose methods for:
- initial load
- category changes
- query changes
- selecting a book

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/application/study_plan_controller_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/study_plan test/features/study_plan
git commit -m "feat: add study plan controller"
```

### Task 3: Build the study-home page and selection page

**Files:**
- Create: `lib/features/study_plan/presentation/study_home_page.dart`
- Create: `lib/features/study_plan/presentation/vocabulary_book_picker_page.dart`
- Modify: `lib/app/app_shell.dart`
- Test: `test/features/study_plan/presentation/study_home_page_test.dart`
- Test: `test/features/home/presentation/app_shell_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('study tab shows official-book empty state instead of dictionary import', (tester) async {
  await tester.pumpWidget(ShawyerWordsApp());

  await tester.tap(find.text('背单词').last);
  await tester.pumpAndSettle();

  expect(find.text('导入词库包'), findsNothing);
  expect(find.text('导入词汇'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study_plan/presentation/study_home_page_test.dart test/features/home/presentation/app_shell_test.dart`
Expected: FAIL because the shell still routes to `DictionaryHomePage`.

**Step 3: Write minimal implementation**

Build:
- empty state with `选择词汇表` / `导入词汇`
- populated top card with `开始` and `更改`
- weekly progress card
- `我的词汇表` section
- picker page with local search and category tabs

Update the shell so the `背单词` tab uses the new study-home page and the picker flow instead of `DictionaryHomePage`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study_plan/presentation/study_home_page_test.dart test/features/home/presentation/app_shell_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/app lib/features/study_plan test/features/study_plan test/features/home
git commit -m "feat: rebuild study tab home"
```

### Task 4: Add a study-session controller for fixed-layout card learning

**Files:**
- Create: `lib/features/study/presentation/study_session_page.dart`
- Create: `lib/features/study/application/study_session_controller.dart`
- Modify: `lib/features/study/presentation/word_card_view.dart`
- Test: `test/features/study/application/study_session_controller_test.dart`
- Test: `test/features/study/presentation/study_session_page_test.dart`

**Step 1: Write the failing test**

```dart
test('reveal definition and advance on decision', () {
  final controller = StudySessionController(entries: sampleEntries);

  expect(controller.state.definitionRevealed, isFalse);

  controller.revealDefinition();
  expect(controller.state.definitionRevealed, isTrue);

  controller.markKnown();
  expect(controller.state.currentIndex, 1);
  expect(controller.state.definitionRevealed, isFalse);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study/application/study_session_controller_test.dart test/features/study/presentation/study_session_page_test.dart`
Expected: FAIL because the new controller and page do not exist yet.

**Step 3: Write minimal implementation**

Implement a new study session page with:
- top progress text
- word headline
- pronunciation / accent chip
- collapsed definition card
- visible example card
- bottom `不认识` / `认识` actions

Wire the controller so each decision:
- records to `StudyRepository`
- advances the index
- resets the definition reveal state

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study/application/study_session_controller_test.dart test/features/study/presentation/study_session_page_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/study test/features/study
git commit -m "feat: rebuild study session page"
```

### Task 5: Integrate navigation and remove old tab-specific tests

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `test/features/study/presentation/study_screen_test.dart`
- Modify: `test/widget_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('starting study opens the rebuilt session page', (tester) async {
  await tester.pumpWidget(ShawyerWordsApp());

  await tester.tap(find.text('背单词').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('导入词汇'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('IELTS乱序完整版'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('开始'));
  await tester.pumpAndSettle();

  expect(find.text('释义'), findsOneWidget);
  expect(find.text('认识'), findsOneWidget);
  expect(find.text('不认识'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study/presentation/study_screen_test.dart test/widget_test.dart`
Expected: FAIL until navigation and default app wiring are updated.

**Step 3: Write minimal implementation**

Update app composition so:
- the default app instance builds the new study-plan repository/controller
- the shell can open the picker page and session page
- old study-tab tests stop referencing dictionary import UI

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study/presentation/study_screen_test.dart test/widget_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/app test/features/study test/widget_test.dart
git commit -m "test: update study flow coverage"
```

### Task 6: Run focused regression coverage

**Files:**
- Test: `test/features/study_plan/...`
- Test: `test/features/study/...`
- Test: `test/features/home/...`

**Step 1: Run focused tests**

Run: `flutter test test/features/study_plan test/features/study test/features/home`
Expected: PASS

**Step 2: Run full widget and application coverage that touches shell composition**

Run: `flutter test`
Expected: PASS

**Step 3: Commit**

```bash
git add .
git commit -m "feat: complete study tab rebuild"
```
