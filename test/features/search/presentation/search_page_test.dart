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

void main() {
  testWidgets('search shows prefix matches, opens detail, and records history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: DictionaryController(
          dictionaryRepository: _FakeDictionaryRepository(),
          studyRepository: _FakeStudyRepository(),
        ),
        pickDictionaryFile: () async => null,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-search-page')));
    await tester.pumpAndSettle();

    expect(find.text('历史查询'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'nu');
    await tester.pumpAndSettle();

    expect(find.text('nut'), findsOneWidget);

    await tester.tap(find.text('nut'));
    await tester.pumpAndSettle();

    expect(find.text('Raw dictionary content'), findsOneWidget);
    expect(find.text('干果, 坚果; 螺母'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('nut'), findsOneWidget);

    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();

    expect(find.text('nut'), findsNothing);
  });
}

class _FakeDictionaryRepository implements DictionaryRepository {
  @override
  Future<DictionaryImportResult> importDictionary(String filePath) async {
    return const DictionaryImportResult(
      package: DictionaryPackage(
        id: 'dict-1',
        name: 'Test Dictionary Package',
        type: DictionaryPackageType.imported,
        rootPath: '/tmp/dictionaries/imported/test-dictionary',
        mdxPath: '/tmp/dictionaries/imported/test-dictionary/source/main.mdx',
        mddPaths: <String>[],
        resourcesPath: '/tmp/dictionaries/imported/test-dictionary/resources',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 1,
      ),
      dictionary: DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '/tmp/dictionaries/imported/test-dictionary',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 1,
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
      ],
    );
  }
}

class _FakeStudyRepository implements StudyRepository {
  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {}
}
