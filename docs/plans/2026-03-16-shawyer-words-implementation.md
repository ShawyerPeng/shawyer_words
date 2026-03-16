# Shawyer Words Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the first Flutter iOS app version that imports a local MDX dictionary file and presents imported entries as swipeable word cards.

**Architecture:** Create a new Flutter app with feature-oriented folders and stable domain interfaces. Keep real MDX parsing behind an iOS-native `MethodChannel` parser so the Flutter UI, controllers, and repositories stay testable and replaceable.

**Tech Stack:** Flutter, Dart, Flutter test, SQLite (`sqflite` or equivalent), iOS Swift platform channel, iOS document picker or Flutter file picker plugin.

---

### Task 1: Bootstrap The Flutter App

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `ios/Runner/*`
- Create: `test/widget_test.dart`

**Step 1: Verify Flutter SDK is available**

Run: `flutter --version`
Expected: Flutter version output, not `command not found`

**Step 2: Create the base project**

Run: `flutter create --platforms=ios .`
Expected: Flutter creates app, iOS runner, and test skeleton files

**Step 3: Run the default widget test**

Run: `flutter test`
Expected: PASS for the default starter test

**Step 4: Commit**

```bash
git add .
git commit -m "chore: bootstrap flutter ios app"
```

### Task 2: Add Feature Folders And Domain Models

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/app/app.dart`
- Create: `lib/features/dictionary/domain/word_entry.dart`
- Create: `lib/features/dictionary/domain/dictionary_summary.dart`
- Create: `lib/features/study/domain/study_decision.dart`
- Create: `lib/features/dictionary/domain/dictionary_repository.dart`
- Create: `lib/features/dictionary/domain/mdx_parser.dart`
- Create: `lib/features/study/domain/study_repository.dart`
- Test: `test/features/dictionary/domain_models_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

void main() {
  test('word entry preserves fallback raw content', () {
    const entry = WordEntry(
      id: '1',
      word: 'abandon',
      rawContent: '<p>abandon</p>',
    );

    expect(entry.rawContent, '<p>abandon</p>');
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/domain_models_test.dart`
Expected: FAIL because `WordEntry` does not exist yet

**Step 3: Write minimal implementation**

Create immutable domain entities and abstract repository/parser interfaces with only the fields and methods needed for V1:

- `WordEntry`
- `DictionarySummary`
- `StudyDecision`
- `DictionaryRepository`
- `MdxParser`
- `StudyRepository`

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/domain_models_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat: add dictionary and study domain contracts"
```

### Task 3: Build The Empty State And App Shell

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/app/app.dart`
- Create: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Create: `lib/features/dictionary/presentation/import_empty_state.dart`
- Test: `test/features/dictionary/presentation/dictionary_home_page_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_home_page.dart';

void main() {
  testWidgets('shows import button in empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DictionaryHomePage()));

    expect(find.text('Import MDX Dictionary'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: FAIL because the page does not exist yet

**Step 3: Write minimal implementation**

Render a `MaterialApp` with a home page that shows:

- title text
- import button
- placeholder helper copy

No import logic yet.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat: add app shell and import empty state"
```

### Task 4: Add Import Controller And Test Doubles

**Files:**
- Create: `lib/features/dictionary/application/dictionary_controller.dart`
- Create: `lib/features/dictionary/application/dictionary_state.dart`
- Create: `test/features/dictionary/application/dictionary_controller_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('import success exposes the first entry', () async {
    // Arrange fake repository with one imported entry
    // Act import dictionary
    // Assert state contains imported dictionary and current entry
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: FAIL because controller types do not exist yet

**Step 3: Write minimal implementation**

Create a controller that:

- starts in empty state
- accepts an import request with file path
- delegates to `DictionaryRepository`
- exposes loading, success, and failure states
- stores current entry in memory for the current session

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat: add dictionary import controller"
```

### Task 5: Wire File Selection Into The UI

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Create: `lib/features/dictionary/data/file_picker_dictionary_importer.dart`
- Test: `test/features/dictionary/presentation/dictionary_import_flow_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap import triggers file selection flow', (tester) async {
    // Arrange a fake importer
    // Tap import button
    // Expect the controller import method to receive a file path
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/presentation/dictionary_import_flow_test.dart`
Expected: FAIL because the file selection adapter is not wired

**Step 3: Write minimal implementation**

Add a file picker dependency and a small adapter that:

- opens file selection
- restricts to `.mdx`
- returns a path or cancellation

Connect the import button to the controller through this adapter.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/presentation/dictionary_import_flow_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add pubspec.yaml lib test
git commit -m "feat: connect mdx file picker flow"
```

### Task 6: Add Card Screen And Swipe Actions

**Files:**
- Create: `lib/features/study/presentation/word_card_view.dart`
- Create: `lib/features/study/presentation/study_screen.dart`
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Create: `test/features/study/presentation/study_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('swiping right records known and advances', (tester) async {
    // Arrange a screen with two entries
    // Swipe right
    // Expect known decision stored
    // Expect second entry visible
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study/presentation/study_screen_test.dart`
Expected: FAIL because the study screen does not exist yet

**Step 3: Write minimal implementation**

Build a card screen that:

- displays word, pronunciation, part of speech, definition, and example sentence
- falls back to raw content if structured fields are empty
- handles horizontal swipe gestures
- labels left as unknown and right as known

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study/presentation/study_screen_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat: add swipeable study cards"
```

### Task 7: Persist Study Decisions

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/study/data/local_study_repository.dart`
- Modify: `lib/features/dictionary/application/dictionary_controller.dart`
- Create: `test/features/study/data/local_study_repository_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores a known decision with entry id', () async {
    // Arrange repository
    // Save decision
    // Expect repository query returns saved decision
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/study/data/local_study_repository_test.dart`
Expected: FAIL because the repository implementation does not exist yet

**Step 3: Write minimal implementation**

Add a local persistence implementation for study decisions using SQLite.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/study/data/local_study_repository_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add pubspec.yaml lib test
git commit -m "feat: persist study decisions locally"
```

### Task 8: Persist Imported Dictionary Entries

**Files:**
- Create: `lib/features/dictionary/data/local_dictionary_repository.dart`
- Create: `lib/features/dictionary/data/dictionary_database.dart`
- Create: `test/features/dictionary/data/local_dictionary_repository_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('import stores dictionary metadata and entries', () async {
    // Arrange fake parser payload
    // Import dictionary
    // Expect metadata and entry count persisted
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/data/local_dictionary_repository_test.dart`
Expected: FAIL because the local repository does not exist yet

**Step 3: Write minimal implementation**

Persist:

- dictionary metadata
- imported entries
- a query for the current deck

Keep schema minimal and focused on one imported dictionary first.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/data/local_dictionary_repository_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat: persist imported dictionary entries"
```

### Task 9: Add The iOS MDX Platform Channel Contract

**Files:**
- Create: `lib/features/dictionary/data/ios_mdx_parser_channel.dart`
- Modify: `ios/Runner/AppDelegate.swift`
- Create: `ios/Runner/MdxParserBridge.swift`
- Test: `test/features/dictionary/data/ios_mdx_parser_channel_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parser channel calls import method with file path', () async {
    // Arrange mock method channel handler
    // Act parse file
    // Assert method name and payload shape
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dictionary/data/ios_mdx_parser_channel_test.dart`
Expected: FAIL because the parser channel implementation does not exist yet

**Step 3: Write minimal implementation**

Implement a Dart `MethodChannel` parser contract:

- channel name is constant and documented
- import method accepts file path
- response mapping converts native payloads into `WordEntry`

On iOS, register the channel and return a temporary controlled payload until the real parser library is integrated.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/dictionary/data/ios_mdx_parser_channel_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib ios test
git commit -m "feat: add ios mdx parser channel contract"
```

### Task 10: Integrate A Real iOS MDX Parser

**Files:**
- Modify: `ios/Runner/MdxParserBridge.swift`
- Modify: `ios/Runner.xcodeproj/*`
- Modify: `pubspec.yaml` if plugin coordination changes
- Create: `docs/plans/mdx-parser-notes.md`

**Step 1: Evaluate the chosen MDX parsing library**

Run: inspect the library integration requirements and supported APIs
Expected: a concrete choice with file import and content extraction support

**Step 2: Add a failing integration check**

Run: import a real sample `.mdx` file on simulator or device
Expected: FAIL with placeholder parser behavior or missing native integration

**Step 3: Write minimal implementation**

Integrate the real native parser and map:

- headword
- pronunciation
- part of speech
- definition
- example sentence
- fallback raw content

If some fields cannot be extracted generically, populate `rawContent` and keep optional structured fields nullable.

**Step 4: Run integration verification**

Run: simulator or device import with a real `.mdx` file
Expected: dictionary imports and first card renders content

**Step 5: Commit**

```bash
git add ios pubspec.yaml docs
git commit -m "feat: integrate real ios mdx parser"
```

### Task 11: Verify Full App Flow

**Files:**
- Modify: `test/widget_test.dart`
- Create: `test/features/app/app_smoke_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shows imported card content after successful import', (tester) async {
    // Arrange app with fake repository and fake imported entries
    // Pump app
    // Trigger successful import
    // Assert first card content visible
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/app/app_smoke_test.dart`
Expected: FAIL until the app wiring is complete

**Step 3: Write minimal implementation**

Finish dependency wiring so the app can move from empty state to study screen after a successful import.

**Step 4: Run test to verify it passes**

Run: `flutter test`
Expected: PASS for all Flutter tests

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat: complete mdx import to study flow"
```

### Task 12: iOS Manual Verification

**Files:**
- Modify: `README.md`

**Step 1: Document run prerequisites**

Add:

- Flutter SDK requirement
- Xcode requirement
- how to run on simulator/device
- how to import a local `.mdx` file

**Step 2: Run the app on iOS**

Run: `flutter run`
Expected: app launches on iOS simulator or device

**Step 3: Manually verify**

Confirm:

- import button opens file picker
- valid `.mdx` file imports
- word card displays dictionary content
- left swipe records unknown
- right swipe records known

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add ios run and verification notes"
```
