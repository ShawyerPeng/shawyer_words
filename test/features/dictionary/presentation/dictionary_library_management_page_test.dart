import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

void main() {
  testWidgets('renders visible and hidden sections and filters list', (
    tester,
  ) async {
    final controller = DictionaryLibraryController(
      repository: _FakeDictionaryLibraryRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryManagementPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('显示的词库'), findsOneWidget);
    expect(find.text('隐藏的词库'), findsOneWidget);
    expect(find.text('英英词典'), findsOneWidget);
    expect(find.text('网页书签'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '英英');
    await tester.pumpAndSettle();

    expect(find.text('英英词典'), findsOneWidget);
    expect(find.text('学习笔记'), findsNothing);
  });

  testWidgets('opens detail page from chevron action', (tester) async {
    final controller = DictionaryLibraryController(
      repository: _FakeDictionaryLibraryRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryManagementPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dictionary-detail-eng-eng')));
    await tester.pumpAndSettle();

    expect(find.text('显示该词库'), findsOneWidget);
    expect(find.text('自动展开'), findsOneWidget);
  });

  testWidgets('shows help dialog from app bar action', (tester) async {
    final controller = DictionaryLibraryController(
      repository: _FakeDictionaryLibraryRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryManagementPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('帮助'));
    await tester.pumpAndSettle();

    expect(find.text('如何导入扩展词典包'), findsOneWidget);
    expect(find.text('通过互联网或者方格单词社区，您可以获取扩展词典包文件并添加到您的设备。'), findsOneWidget);
    expect(find.text('.mdx 词典主文件（大部分词典只需此文件）'), findsOneWidget);
    expect(find.text('.mdd 词典音频、配图、显示样式等资源'), findsOneWidget);
    expect(find.text('好的'), findsOneWidget);
  });

  testWidgets(
    'shows inline import button under visible section and skips picker overlay',
    (tester) async {
      final controller = DictionaryLibraryController(
        repository: _FakeDictionaryLibraryRepository(),
      );
      final importController = DictionaryController(
        dictionaryRepository: _FakeDictionaryRepository(),
        previewRepository: _FakeDictionaryPreviewRepository(),
        studyRepository: _FakeStudyRepository(),
      );
      final picker = _CountingPicker('/tmp/main.mdx');

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryLibraryManagementPage(
            controller: controller,
            dictionaryController: importController,
            pickDictionaryFile: picker.call,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('显示的词库'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '导入词库'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '导入词库'));
      await tester.pump();
      await tester.pump();

      expect(picker.calls, 1);
      expect(
        find.byKey(const ValueKey('dictionary-import-overlay')),
        findsNothing,
      );
      expect(find.text('确认导入'), findsOneWidget);
      expect(
        importController.state.importSession.stage,
        DictionaryImportSessionStage.confirming,
      );
    },
  );
}

class _CountingPicker {
  _CountingPicker(this.result);

  final String? result;
  int calls = 0;

  Future<String?> call() async {
    calls += 1;
    return result;
  }
}

class _FakeDictionaryLibraryRepository implements DictionaryLibraryRepository {
  final List<DictionaryLibraryItem> items = <DictionaryLibraryItem>[
    const DictionaryLibraryItem(
      id: 'notes',
      name: '学习笔记',
      type: DictionaryPackageType.bundled,
      rootPath: '/tmp/notes',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20251021',
      category: '默认',
      entryCount: 120,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 1024,
      fileSizeLabel: '1K',
      isVisible: true,
      autoExpand: false,
      sortIndex: 0,
    ),
    const DictionaryLibraryItem(
      id: 'eng-eng',
      name: '英英词典',
      type: DictionaryPackageType.bundled,
      rootPath: '/tmp/eng-eng',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20251021',
      category: '默认',
      entryCount: 428674,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 90 * 1024 * 1024,
      fileSizeLabel: '90M',
      isVisible: true,
      autoExpand: false,
      sortIndex: 1,
    ),
    const DictionaryLibraryItem(
      id: 'web',
      name: '网页书签',
      type: DictionaryPackageType.imported,
      rootPath: '/tmp/web',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20260316',
      category: '自定义',
      entryCount: 0,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 0,
      fileSizeLabel: '0B',
      isVisible: false,
      autoExpand: false,
      sortIndex: 2,
    ),
  ];

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async => items;

  @override
  Future<void> deleteDictionary(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {}

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {}

  @override
  Future<void> setVisibility(String id, bool isVisible) async {}
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
      files: [
        DictionaryPreviewFile(
          path: '/tmp/session/main.mdx',
          name: 'main.mdx',
          kind: DictionaryPreviewFileKind.mdx,
          isPrimary: true,
        ),
      ],
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
