import 'package:flutter_test/flutter_test.dart';
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
  test(
    'adding an import source opens confirmation without changing study state',
    () async {
      final previewRepository = _FakeDictionaryPreviewRepository();
      final controller = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: previewRepository,
        studyRepository: _FakeStudyRepository(),
      );

      controller.startImportSession();
      await controller.addImportSource('/tmp/main.mdx');

      expect(controller.state.status, DictionaryStatus.idle);
      expect(
        controller.state.importSession.stage,
        DictionaryImportSessionStage.confirming,
      );
      expect(previewRepository.prepareCalls, [
        ['/tmp/main.mdx'],
      ]);
      expect(
        controller.state.importSession.preview?.primaryMdxPath,
        '/tmp/session/main.mdx',
      );
    },
  );

  test(
    'preview paging selects the first entry on the requested page',
    () async {
      final controller = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: _FakeDictionaryPreviewRepository(),
        studyRepository: _FakeStudyRepository(),
      );

      controller.startImportSession();
      await controller.addImportSource('/tmp/main.mdx');
      await controller.openImportPreview();

      expect(
        controller.state.importSession.stage,
        DictionaryImportSessionStage.previewing,
      );
      expect(controller.state.importSession.previewPage?.pageNumber, 1);
      expect(
        controller.state.importSession.selectedPreviewEntry?.word,
        'word-1',
      );

      await controller.goToPreviewPage(2);

      expect(controller.state.importSession.previewPage?.pageNumber, 2);
      expect(
        controller.state.importSession.selectedPreviewEntry?.word,
        'word-1001',
      );
    },
  );

  test(
    'installing imports from the prepared preview root only after confirmation',
    () async {
      final dictionaryRepository = _FakeDictionaryRepository();
      final controller = DictionaryController(
        dictionaryRepository: dictionaryRepository,
        previewRepository: _FakeDictionaryPreviewRepository(),
        studyRepository: _FakeStudyRepository(),
      );

      controller.startImportSession();
      await controller.addImportSource('/tmp/main.mdx');
      await controller.installImport();

      expect(dictionaryRepository.importedPaths, ['/tmp/session']);
      expect(controller.state.status, DictionaryStatus.ready);
      expect(controller.state.dictionary?.name, 'Test Dictionary');
      expect(controller.state.activePackage?.name, 'Oxford Starter');
      expect(
        controller.state.importSession.stage,
        DictionaryImportSessionStage.closed,
      );
    },
  );

  test('loads a preview entry on demand for detail view', () async {
    final controller = DictionaryController(
      dictionaryRepository: _FakeDictionaryRepository(),
      previewRepository: _FakeDictionaryPreviewRepository(),
      studyRepository: _FakeStudyRepository(),
    );

    controller.startImportSession();
    await controller.addImportSource('/tmp/main.mdx');

    final entry = await controller.loadPreviewEntry('word-42');

    expect(entry?.word, 'word-42');
    expect(entry?.rawContent, contains('Definition 42'));
  });
}

class _FakeDictionaryRepository implements DictionaryRepository {
  final List<String> importedPaths = <String>[];

  @override
  Future<DictionaryImportResult> importDictionary(String filePath) async {
    importedPaths.add(filePath);
    return DictionaryImportResult(
      package: const DictionaryPackage(
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
      dictionary: const DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '/tmp/dictionaries/imported/oxford-starter',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 2,
      ),
      entries: const [
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
          definition: 'quick and energetic',
          rawContent: '<p>brisk</p>',
        ),
      ],
    );
  }
}

class _FakeDictionaryPreviewRepository implements DictionaryPreviewRepository {
  final List<List<String>> prepareCalls = <List<String>>[];

  @override
  Future<void> disposePreview(DictionaryImportPreview preview) async {}

  @override
  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  }) async {
    final start = (pageNumber - 1) * preview.pageSize;
    final end = (start + preview.pageSize).clamp(0, preview.totalEntries);
    final entries = List<WordEntry>.generate(end - start, (index) {
      final entryNumber = start + index + 1;
      return WordEntry(
        id: 'entry-$entryNumber',
        word: 'word-$entryNumber',
        partOfSpeech: 'noun',
        definition: 'Definition $entryNumber',
        rawContent: '<div class="definition">Definition $entryNumber</div>',
      );
    });

    return DictionaryPreviewPage(pageNumber: pageNumber, entries: entries);
  }

  @override
  Future<DictionaryImportPreview> preparePreview(
    List<String> sourcePaths,
  ) async {
    prepareCalls.add(List<String>.from(sourcePaths));
    return _preview();
  }

  @override
  Future<WordEntry?> loadEntry({
    required DictionaryImportPreview preview,
    required String key,
  }) async {
    return WordEntry(
      id: key,
      word: key,
      rawContent: '<div class="definition">Definition ${key.split('-').last}</div>',
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

DictionaryImportPreview _preview() {
  return const DictionaryImportPreview(
    sourceRootPath: '/tmp/session',
    title: 'Oxford Starter',
    primaryMdxPath: '/tmp/session/main.mdx',
    metadataText: '<Dictionary Title="Oxford Starter" />',
    files: [
      DictionaryPreviewFile(
        path: '/tmp/session/main.mdx',
        name: 'main.mdx',
        kind: DictionaryPreviewFileKind.mdx,
        isPrimary: true,
      ),
      DictionaryPreviewFile(
        path: '/tmp/session/main.mdd',
        name: 'main.mdd',
        kind: DictionaryPreviewFileKind.mdd,
      ),
    ],
    entryKeys: [],
    totalEntries: 12000,
  );
}
