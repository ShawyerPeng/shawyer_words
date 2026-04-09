import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_book_picker_page.dart';

void main() {
  testWidgets('renders notebook card without summary header', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(),
    );
    await controller.load();
    await controller.importWordsToNotebook(
      notebookId: 'my-vocabulary',
      words: const <String>['abandon', 'ability'],
    );

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('单词本'), findsOneWidget);
    expect(find.text('全部'), findsWidgets);
    expect(find.text('当前词本'), findsNothing);
    await tester.tap(find.text('我的').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notebook-card-my-vocabulary')),
      findsOneWidget,
    );
    expect(find.text('当前'), findsOneWidget);
    expect(find.text('默认'), findsOneWidget);
    expect(find.text('2 词'), findsOneWidget);
  });

  testWidgets('switches to official category and shows second-level tags', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('雅思').first);
    await tester.pumpAndSettle();

    expect(find.text('乱序版'), findsWidgets);
    expect(find.text('词库版'), findsWidgets);
    expect(find.text('CET 4+6'), findsNothing);
    await tester.tap(find.text('乱序版').first);
    await tester.pumpAndSettle();

    expect(find.text('IELTS乱序完整版'), findsWidgets);
    expect(find.text('雅思词库'), findsNothing);
  });

  testWidgets('tapping remote book auto downloads with centered progress', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          onProgress?.call(1, 2);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          onProgress?.call(2, 2);
          return 'abandon\nability';
        },
      ),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('download-cet46-remote')), findsNothing);

    await tester.tap(find.text('CET 4+6').first);
    await tester.pump();

    expect(find.text('词书准备中 0%'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('词书准备中 50%'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.textContaining('词书准备中'), findsNothing);
    expect(controller.state.currentBook?.id, 'cet46-remote');
  });
}
