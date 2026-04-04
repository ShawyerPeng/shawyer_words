import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_book_picker_page.dart';

void main() {
  testWidgets('picker defaults to 我的 tab and can switch to CET 4+6', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async => 'alpha\nbeta\n',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的'), findsOneWidget);
    expect(find.textContaining('我的词汇'), findsOneWidget);
    expect(find.text('CET 4+6'), findsNothing);

    await tester.tap(find.text('四六级'));
    await tester.pumpAndSettle();

    expect(find.text('CET 4+6'), findsOneWidget);
  });

  testWidgets(
    'picker shows download button and inline progress while remote vocabulary is loading',
    (tester) async {
      final completer = Completer<String>();
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(
          remoteVocabularyLoader: (uri, {onProgress}) {
            onProgress?.call(25, 100);
            return completer.future;
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('四六级'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('download-cet46-remote')));
      await tester.pump();

      expect(find.text('已下载 25%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      completer.complete('alpha\nbeta\n');
      await tester.pumpAndSettle();

      expect(find.text('已下载'), findsWidgets);
    },
  );

  testWidgets('picker does not download when tapping remote item title', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async => 'alpha\nbeta\n',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('四六级'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CET 4+6'));
    await tester.pumpAndSettle();

    expect(find.text('下载'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('picker shows inline failure when remote download fails', (
    tester,
  ) async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async {
          throw Exception('download failed');
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: VocabularyBookPickerPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('四六级'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('download-cet46-remote')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('download failed'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
