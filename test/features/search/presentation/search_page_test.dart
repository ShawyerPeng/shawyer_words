import 'package:flutter/material.dart' hide SearchController;
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
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/data/in_memory_search_history_repository.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

void main() {
  testWidgets(
    'search shows prefix matches, opens detail, and records history',
    (tester) async {
      await tester.pumpWidget(
        ShawyerWordsApp(
          controller: DictionaryController(
            dictionaryRepository: _FakeDictionaryRepository(),
            previewRepository: _FakeDictionaryPreviewRepository(),
            studyRepository: _FakeStudyRepository(),
          ),
          searchController: SearchController(
            lookupRepository: _FakeWordLookupRepository(),
            historyRepository: InMemorySearchHistoryRepository(),
          ),
          pickDictionaryFile: () async => null,
          wordDetailPageBuilder: (word, initialEntry) => WordDetailPage(
            word: word,
            initialEntry: initialEntry,
            controller: WordDetailController(
              detailRepository: _FakeWordDetailRepository(),
              knowledgeRepository: _FakeWordKnowledgeRepository(),
            ),
          ),
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

      expect(find.text('基本'), findsOneWidget);
      expect(find.text('干果, 坚果; 螺母'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('nut'), findsOneWidget);

      await tester.tap(find.text('清除'));
      await tester.pumpAndSettle();

      expect(find.text('nut'), findsNothing);
    },
  );
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

class _FakeWordDetailRepository implements WordDetailRepository {
  @override
  Future<WordDetail> load(String word) async {
    return const WordDetail(
      word: 'nut',
      basic: WordBasicSummary(
        headword: 'nut',
        pronunciationUs: '/nʌt/',
        pronunciationUk: '/nʌt/',
        frequency: 'CET4',
      ),
      definitions: <WordSense>[
        WordSense(partOfSpeech: 'noun', definitionZh: '干果, 坚果; 螺母'),
      ],
      examples: <WordExample>[
        WordExample(
          english: 'The child cracked a nut.',
          translationZh: '孩子敲开了一颗坚果。',
        ),
      ],
      dictionaryPanels: <DictionaryEntryDetail>[
        DictionaryEntryDetail(
          dictionaryId: 'eng-zh',
          dictionaryName: '英汉词典',
          word: 'nut',
          rawContent: '原始词典内容',
        ),
      ],
    );
  }
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  @override
  Future<void> clearAll() async {}

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async => null;

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async =>
      const <WordKnowledgeRecord>[];

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {}

  @override
  Future<void> save(WordKnowledgeRecord record) async {}

  @override
  Future<void> saveNote(String word, String note) async {}

  @override
  Future<void> toggleFavorite(String word) async {}
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

class _FakeWordLookupRepository implements WordLookupRepository {
  @override
  WordEntry? findById(String id) => null;

  @override
  Future<List<WordEntry>> searchWords(String query, {int limit = 20}) async {
    const entries = <WordEntry>[
      WordEntry(
        id: 'nut',
        word: 'nut',
        partOfSpeech: 'n.',
        definition: '干果, 坚果; 螺母',
        rawContent: '<p>nut</p>',
      ),
      WordEntry(
        id: 'nurture',
        word: 'nurture',
        partOfSpeech: 'v.',
        definition: '培养',
        rawContent: '<p>nurture</p>',
      ),
    ];
    return entries
        .where(
          (entry) => entry.word.toLowerCase().startsWith(query.toLowerCase()),
        )
        .take(limit)
        .toList();
  }
}
