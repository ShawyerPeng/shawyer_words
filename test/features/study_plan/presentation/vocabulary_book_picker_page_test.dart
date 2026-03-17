import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_book_picker_page.dart';

void main() {
  testWidgets('picker shows built-in CET 4+6 remote book', (tester) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri) async => 'alpha\nbeta\n',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('CET 4+6'), findsOneWidget);
  });

  testWidgets(
    'picker shows importing status bar while remote vocabulary is loading',
    (tester) async {
      final completer = Completer<String>();
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(
          remoteVocabularyLoader: (uri) => completer.future,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CET 4+6'));
      await tester.pump();

      expect(find.text('正在导入词汇表...'), findsOneWidget);

      completer.complete('alpha\nbeta\n');
      await tester.pumpAndSettle();
    },
  );

  testWidgets('picker shows failure status bar when remote import fails', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri) async {
          throw Exception('download failed');
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CET 4+6'));
    await tester.pumpAndSettle();

    expect(find.textContaining('download failed'), findsOneWidget);
  });
}
