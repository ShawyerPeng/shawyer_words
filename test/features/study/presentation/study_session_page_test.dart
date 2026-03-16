import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/application/study_session_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/study_session_page.dart';

void main() {
  testWidgets(
    'definition is hidden until revealed and known advances to next word',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final studyRepository = _RecordingStudyRepository();
      final controller = StudySessionController(
        entries: const [
          WordEntry(
            id: '1',
            word: 'aristocracy',
            pronunciation: '/ˌærɪˈstɒkrəsi/',
            definition: '贵族统治；贵族阶层',
            exampleSentence:
                'A new managerial elite was replacing the old aristocracy.',
            rawContent: '<p>aristocracy</p>',
          ),
          WordEntry(
            id: '2',
            word: 'brisk',
            pronunciation: '/brɪsk/',
            definition: '轻快的；敏捷的',
            exampleSentence: 'The morning air felt brisk.',
            rawContent: '<p>brisk</p>',
          ),
        ],
        studyRepository: studyRepository,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: StudySessionPage(
            controller: controller,
            wordDetailPageBuilder: (word, initialEntry) => Scaffold(
              body: Center(
                child: Text('detail:$word:${initialEntry?.word ?? ''}'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('贵族统治；贵族阶层'), findsNothing);
      expect(find.text('aristocracy'), findsOneWidget);
      expect(find.text('查看完整释义'), findsNothing);

      await tester.tap(find.text('释义'));
      await tester.pumpAndSettle();

      expect(find.text('贵族统治；贵族阶层'), findsOneWidget);
      expect(find.text('查看完整释义'), findsOneWidget);

      await tester.tap(find.text('查看完整释义'));
      await tester.pumpAndSettle();

      expect(find.text('detail:aristocracy:aristocracy'), findsOneWidget);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('认识'));
      await tester.pumpAndSettle();

      expect(studyRepository.savedEntryIds, ['1']);
      expect(studyRepository.savedDecisions, [StudyDecisionType.known]);
      expect(find.text('brisk'), findsOneWidget);
      expect(find.text('轻快的；敏捷的'), findsNothing);
    },
  );
}

class _RecordingStudyRepository implements StudyRepository {
  final List<String> savedEntryIds = <String>[];
  final List<StudyDecisionType> savedDecisions = <StudyDecisionType>[];

  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {
    savedEntryIds.add(entryId);
    savedDecisions.add(decision);
  }
}
