import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/word_card_view.dart';

void main() {
  testWidgets('swiping right records known and advances', (tester) async {
    final studyRepository = _RecordingStudyRepository();
    final controller = DictionaryController(
      dictionaryRepository: _FakeDictionaryRepository(),
      studyRepository: studyRepository,
    );

    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: controller,
        pickDictionaryFile: () async => '/tmp/test.zip',
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '导入词库包'));
    await tester.pumpAndSettle();

    expect(find.text('abandon'), findsOneWidget);

    await tester.drag(find.byType(WordCardView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(studyRepository.savedEntryIds, ['1']);
    expect(studyRepository.savedDecisions, [StudyDecisionType.known]);
    expect(find.text('brisk'), findsOneWidget);
  });
}

class _FakeDictionaryRepository implements DictionaryRepository {
  @override
  Future<DictionaryImportResult> importDictionary(String filePath) async {
    return const DictionaryImportResult(
      package: DictionaryPackage(
        id: 'oxford-starter',
        name: 'Oxford Starter',
        type: DictionaryPackageType.imported,
        rootPath: '/tmp/dictionaries/imported/oxford-starter',
        mdxPath: '/tmp/dictionaries/imported/oxford-starter/source/main.mdx',
        mddPaths: <String>[],
        resourcesPath: '/tmp/dictionaries/imported/oxford-starter/resources',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 2,
      ),
      dictionary: DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '/tmp/dictionaries/imported/oxford-starter',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 2,
      ),
      entries: [
        WordEntry(
          id: '1',
          word: 'abandon',
          pronunciation: '/əˈbændən/',
          partOfSpeech: 'verb',
          definition: 'to leave behind',
          exampleSentence: 'They abandon the plan at sunrise.',
          rawContent: '<p>abandon</p>',
        ),
        WordEntry(
          id: '2',
          word: 'brisk',
          pronunciation: '/brɪsk/',
          partOfSpeech: 'adjective',
          definition: 'quick and energetic',
          exampleSentence: 'The morning air felt brisk.',
          rawContent: '<p>brisk</p>',
        ),
      ],
    );
  }
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
