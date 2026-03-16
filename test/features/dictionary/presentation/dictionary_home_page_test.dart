import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_home_page.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

void main() {
  testWidgets(
    'keeps the import overlay visible after picker cancellation and can reopen it',
    (tester) async {
      final picker = _SequencedPicker([null, '/tmp/main.mdx']);
      final controller = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: _FakeDictionaryPreviewRepository(),
        studyRepository: _FakeStudyRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryHomePage(
            controller: controller,
            pickDictionaryFile: picker.call,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, '导入词库包'));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('dictionary-import-overlay')),
        findsOneWidget,
      );
      expect(find.text('添加文件'), findsOneWidget);
      expect(picker.calls, 1);

      await tester.tap(
        find.byKey(const ValueKey('dictionary-import-overlay-trigger')),
      );
      await tester.pump();
      await tester.pump();

      expect(picker.calls, 2);
      expect(find.text('确认导入'), findsOneWidget);
      expect(find.text('main.mdx'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '预览'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '安装'), findsOneWidget);
    },
  );

  testWidgets(
    'shows paginated preview and jumps to the first entry of the selected page',
    (tester) async {
      final controller = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: _FakeDictionaryPreviewRepository(),
        studyRepository: _FakeStudyRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryHomePage(
            controller: controller,
            pickDictionaryFile: () async => '/tmp/main.mdx',
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, '导入词库包'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, '预览'));
      await tester.pump();
      await tester.pump();

      expect(find.text('第 1 / 12 页'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dictionary-preview-page-10')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('dictionary-preview-next-group')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('dictionary-preview-page-11')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('dictionary-preview-page-11')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('第 11 / 12 页'), findsOneWidget);
      expect(find.text('word-10001'), findsWidgets);
      expect(find.text('Definition for word-10001'), findsOneWidget);
    },
  );

  testWidgets('picker errors are shown as a friendly message', (tester) async {
    final controller = DictionaryController(
      dictionaryRepository: _FakeDictionaryRepository(),
      previewRepository: _FakeDictionaryPreviewRepository(),
      studyRepository: _FakeStudyRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryHomePage(
            controller: controller,
            pickDictionaryFile: () async {
              throw PlatformException(
                code: 'invalid_file_type',
                message:
                    'Please choose a dictionary folder or archive package.',
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, '导入词库包'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('请选择词库目录、压缩包，或单个 MDX 文件。'), findsOneWidget);
    expect(
      controller.state.importSession.stage,
      DictionaryImportSessionStage.pickerOverlay,
    );
  });
}

class _SequencedPicker {
  _SequencedPicker(this.results);

  final List<String?> results;
  int calls = 0;

  Future<String?> call() async {
    final index = calls;
    calls += 1;
    return results[index];
  }
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
        entryCount: 1,
      ),
      dictionary: DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '/tmp/dictionaries/imported/oxford-starter',
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

class _FakeDictionaryPreviewRepository implements DictionaryPreviewRepository {
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
        definition: 'Definition for word-$entryNumber',
        rawContent:
            '<div class="entry"><div class="definition">Definition for word-$entryNumber</div></div>',
      );
    });

    return DictionaryPreviewPage(pageNumber: pageNumber, entries: entries);
  }

  @override
  Future<DictionaryImportPreview> preparePreview(
    List<String> sourcePaths,
  ) async {
    return const DictionaryImportPreview(
      sourceRootPath: '/tmp/session',
      title: 'Oxford Starter',
      primaryMdxPath: '/tmp/session/main.mdx',
      metadataText:
          '<Dictionary Title="Oxford Starter" Description="Preview metadata" />',
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
        DictionaryPreviewFile(
          path: '/tmp/session/style.css',
          name: 'style.css',
          kind: DictionaryPreviewFileKind.css,
        ),
      ],
      entryKeys: [],
      totalEntries: 12000,
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
