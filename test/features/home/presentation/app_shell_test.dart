import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

void main() {
  testWidgets('shell shows reordered tabs and switches to me tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: DictionaryController(
          dictionaryRepository: _FakeDictionaryRepository(),
          previewRepository: _FakeDictionaryPreviewRepository(),
          studyRepository: _FakeStudyRepository(),
        ),
        pickDictionaryFile: () async => null,
      ),
    );

    expect(find.text('学习广场'), findsOneWidget);
    expect(find.text('背单词'), findsOneWidget);
    expect(find.text('知识库'), findsOneWidget);
    expect(find.text('学习'), findsOneWidget);
    expect(find.text('我的'), findsWidgets);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.text('我的'), findsWidgets);
    expect(find.text('登录'), findsOneWidget);

    final bottomNavPositioned = find.byWidgetPredicate(
      (widget) =>
          widget is Positioned &&
          widget.left == 0 &&
          widget.right == 0 &&
          widget.bottom == 12,
    );
    expect(bottomNavPositioned, findsOneWidget);
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

class _FakeDictionaryPreviewRepository implements DictionaryPreviewRepository {
  @override
  Future<void> disposePreview(DictionaryImportPreview preview) async {}

  @override
  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  }) async {
    return const DictionaryPreviewPage(pageNumber: 1, entries: []);
  }

  @override
  Future<DictionaryImportPreview> preparePreview(
    List<String> sourcePaths,
  ) async {
    return const DictionaryImportPreview(
      sourceRootPath: '/tmp/session',
      title: 'Preview',
      primaryMdxPath: '/tmp/session/main.mdx',
      metadataText: '',
      files: [],
      entryKeys: [],
      totalEntries: 0,
    );
  }

  @override
  Future<WordEntry?> loadEntry({
    required DictionaryImportPreview preview,
    required String key,
  }) async {
    return null;
  }
}
