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
        findsNothing,
      );

      for (var index = 0; index < 6; index += 1) {
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -4000));
        await tester.pump();
      }

      expect(
        find.byKey(const ValueKey('dictionary-preview-page-10')),
        findsOneWidget,
      );

      await controller.goToPreviewPage(10);
      await tester.pump();

      expect(find.text('第 10 / 12 页'), findsOneWidget);
      expect(
        controller.state.importSession.selectedPreviewEntry?.word,
        'word-9001',
      );
    },
  );

  testWidgets(
    'keeps preview usable on small screens with long dictionary titles',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: _FakeDictionaryPreviewRepository(
          title: '#Collins COBUILD Advanced Learner\'s English Dictionary',
          metadataText: List<String>.filled(
            12,
            '<Dictionary GeneratedByEngineVersion="2.0" Description="Long preview metadata" />',
          ).join(' '),
          files: const [
            DictionaryPreviewFile(
              path: '/tmp/session/main.mdx',
              name:
                  '#Collins COBUILD Advanced Learner\'s English Dictionary.mdx',
              kind: DictionaryPreviewFileKind.mdx,
              isPrimary: true,
            ),
            DictionaryPreviewFile(
              path: '/tmp/session/main.mdd',
              name:
                  '#Collins COBUILD Advanced Learner\'s English Dictionary.mdd',
              kind: DictionaryPreviewFileKind.mdd,
            ),
            DictionaryPreviewFile(
              path: '/tmp/session/switch.js',
              name: 'colcobuildoverhaul_switch.js',
              kind: DictionaryPreviewFileKind.js,
            ),
          ],
        ),
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

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('dictionary-preview-scroll-view')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows description with expand and collapse, keeps files collapsed, and searches entry prefixes across the whole preview',
    (tester) async {
      final controller = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: _FakeDictionaryPreviewRepository(
          metadataText:
              '<Dictionary Title="Oxford Starter" Description="Line 1&lt;br/&gt;&lt;b&gt;Line 2&lt;/b&gt; ${'Extra preview content. ' * 20}" />',
        ),
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

      expect(find.text('更多'), findsOneWidget);
      expect(find.text('收起'), findsNothing);
      expect(find.text('main.mdd'), findsNothing);

      await tester.tap(find.text('更多'));
      await tester.pump();

      expect(find.text('收起'), findsOneWidget);
      expect(find.textContaining('Line 1'), findsWidgets);
      expect(find.textContaining('Line 2'), findsWidgets);

      await tester.tap(find.text('文件信息'));
      await tester.pump();

      expect(find.text('main.mdd'), findsOneWidget);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('dictionary-preview-search-field')),
        'word-10001',
      );
      await tester.pump();

      expect(find.text('搜索结果 1 项'), findsOneWidget);
      expect(find.text('word-10001'), findsWidgets);
      expect(find.text('第 1 / 12 页'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('dictionary-preview-search-field')),
        '',
      );
      await tester.pump();

      expect(find.text('第 1 / 12 页'), findsOneWidget);
    },
  );

  testWidgets(
    'preview entry rows show only the word and open detail through chevron',
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

      expect(find.text('word-1'), findsWidgets);
      expect(find.text('Definition for word-1'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const ValueKey('dictionary-preview-entry-detail-word-1')),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('dictionary-preview-entry-detail-word-1')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('word-1'), findsWidgets);
      expect(find.text('Definition for word-1'), findsOneWidget);
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
  _FakeDictionaryPreviewRepository({
    this.title = 'Oxford Starter',
    this.metadataText =
        '<Dictionary Title="Oxford Starter" Description="Preview metadata" />',
    this.files = const [
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
  });

  final String title;
  final String metadataText;
  final List<DictionaryPreviewFile> files;

  @override
  Future<void> disposePreview(DictionaryImportPreview preview) async {}

  @override
  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  }) async {
    final start = (pageNumber - 1) * preview.pageSize;
    final end = (start + preview.pageSize).clamp(0, preview.totalEntries);
    final visibleCount = (end - start).clamp(0, 4);
    final entries = List<WordEntry>.generate(visibleCount, (index) {
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
    final keys = List<String>.generate(12000, (index) => 'word-${index + 1}');
    return DictionaryImportPreview(
      sourceRootPath: '/tmp/session',
      title: title,
      primaryMdxPath: '/tmp/session/main.mdx',
      metadataText: metadataText,
      files: files,
      entryKeys: keys,
      totalEntries: 12000,
    );
  }

  @override
  Future<WordEntry?> loadEntry({
    required DictionaryImportPreview preview,
    required String key,
  }) async {
    return WordEntry(
      id: key,
      word: key,
      rawContent:
          '<div class="entry"><div class="definition">Definition for $key</div></div>',
    );
  }
}

class _FakeStudyRepository implements StudyRepository {
  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {}

  @override
  Future<List<StudyDecisionRecord>> loadDecisionRecords() async {
    return const <StudyDecisionRecord>[];
  }
}
