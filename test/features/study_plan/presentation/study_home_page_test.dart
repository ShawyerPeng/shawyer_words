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
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/presentation/study_home_page.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets(
    'study tab shows official-book empty state instead of dictionary import',
    (tester) async {
      await tester.pumpWidget(
        ShawyerWordsApp(
          controller: DictionaryController(
            dictionaryRepository: _FakeDictionaryRepository(),
            previewRepository: _FakeDictionaryPreviewRepository(),
            studyRepository: _FakeStudyRepository(),
          ),
          studyPlanController: StudyPlanController(
            repository: InMemoryStudyPlanRepository.seeded(),
          ),
          pickDictionaryFile: () async => null,
        ),
      );

      await tester.tap(find.text('背单词').last);
      await tester.pumpAndSettle();

      expect(find.text('导入词库包'), findsNothing);
      expect(find.text('导入词汇'), findsOneWidget);
      expect(find.text('选择词汇表'), findsOneWidget);
    },
  );

  testWidgets('my vocabulary entry opens notebook picker and create dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: DictionaryController(
          dictionaryRepository: _FakeDictionaryRepository(),
          previewRepository: _FakeDictionaryPreviewRepository(),
          studyRepository: _FakeStudyRepository(),
        ),
        studyPlanController: StudyPlanController(
          repository: InMemoryStudyPlanRepository.seeded(),
        ),
        pickDictionaryFile: () async => null,
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('my-vocabulary-entry')));
    await tester.pumpAndSettle();

    expect(find.text('生词本'), findsOneWidget);
    expect(find.text('新建生词本'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-notebook-button')));
    await tester.pumpAndSettle();

    expect(find.text('新建生词本'), findsWidgets);
    expect(
      find.byKey(const ValueKey('create-notebook-name-input')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create-notebook-description-input')),
      findsOneWidget,
    );
  });

  testWidgets('notebook more button shows edit/delete/cancel actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: DictionaryController(
          dictionaryRepository: _FakeDictionaryRepository(),
          previewRepository: _FakeDictionaryPreviewRepository(),
          studyRepository: _FakeStudyRepository(),
        ),
        studyPlanController: StudyPlanController(
          repository: InMemoryStudyPlanRepository.seeded(),
        ),
        pickDictionaryFile: () async => null,
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-vocabulary-entry')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('notebook-actions-my-vocabulary')),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('import button opens import vocabulary page', (tester) async {
    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: DictionaryController(
          dictionaryRepository: _FakeDictionaryRepository(),
          previewRepository: _FakeDictionaryPreviewRepository(),
          studyRepository: _FakeStudyRepository(),
        ),
        studyPlanController: StudyPlanController(
          repository: InMemoryStudyPlanRepository.seeded(),
        ),
        pickDictionaryFile: () async => null,
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();

    final importButton = find.byKey(
      const ValueKey('empty-import-words-button'),
    );
    await tester.scrollUntilVisible(
      importButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(find.text('导入词汇'), findsWidgets);
    expect(find.byKey(const ValueKey('import-words-input')), findsOneWidget);
    expect(find.text('输入单词，每行一个'), findsOneWidget);
  });

  testWidgets(
    'import page notebook selector opens the same notebook sheet with create action',
    (tester) async {
      await tester.pumpWidget(
        ShawyerWordsApp(
          controller: DictionaryController(
            dictionaryRepository: _FakeDictionaryRepository(),
            previewRepository: _FakeDictionaryPreviewRepository(),
            studyRepository: _FakeStudyRepository(),
          ),
          studyPlanController: StudyPlanController(
            repository: InMemoryStudyPlanRepository.seeded(),
          ),
          pickDictionaryFile: () async => null,
        ),
      );

      await tester.tap(find.text('背单词').last);
      await tester.pumpAndSettle();

      final importButton = find.byKey(
        const ValueKey('empty-import-words-button'),
      );
      await tester.scrollUntilVisible(
        importButton,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('import-notebook-selector')));
      await tester.pumpAndSettle();

      expect(find.text('生词本'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-notebook-button')),
        findsOneWidget,
      );
      expect(find.text('新建生词本'), findsOneWidget);
    },
  );

  testWidgets(
    'when notebook is not empty it shows recent words grouped by time and hides import button',
    (tester) async {
      final studyPlanController = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(),
      );
      await studyPlanController.load();
      await studyPlanController.importWordsToNotebook(
        notebookId: 'my-vocabulary',
        words: const <String>['abandon', 'ability'],
      );

      await tester.pumpWidget(
        ShawyerWordsApp(
          controller: DictionaryController(
            dictionaryRepository: _FakeDictionaryRepository(),
            previewRepository: _FakeDictionaryPreviewRepository(),
            studyRepository: _FakeStudyRepository(),
          ),
          studyPlanController: studyPlanController,
          pickDictionaryFile: () async => null,
        ),
      );

      await tester.tap(find.text('背单词').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('empty-import-words-button')),
        findsNothing,
      );
      expect(find.textContaining('今天 ('), findsOneWidget);
      expect(find.text('abandon'), findsOneWidget);
      expect(find.text('ability'), findsOneWidget);
    },
  );

  testWidgets('import words save should return without framework assertion', (
    tester,
  ) async {
    final studyPlanController = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(),
    );

    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: DictionaryController(
          dictionaryRepository: _FakeDictionaryRepository(),
          previewRepository: _FakeDictionaryPreviewRepository(),
          studyRepository: _FakeStudyRepository(),
        ),
        studyPlanController: studyPlanController,
        pickDictionaryFile: () async => null,
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();

    final importButton = find.byKey(
      const ValueKey('empty-import-words-button'),
    );
    await tester.scrollUntilVisible(
      importButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('import-words-input')),
      'abandon\nability',
    );
    await tester.pump();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('import-words-input')), findsNothing);
    expect(find.text('abandon'), findsOneWidget);
  });

  testWidgets('start study uses planner mixed queue order', (tester) async {
    final entries = <WordEntry>[
      _plannerEntry('must-review'),
      _plannerEntry('review-1'),
      _plannerEntry('review-2'),
      _plannerEntry('new-1'),
      _plannerEntry('new-2'),
    ];
    final book = OfficialVocabularyBook(
      id: 'book',
      category: 'Exam',
      title: 'Planner Book',
      subtitle: 'Planner Subtitle',
      wordCount: entries.length,
      coverKey: 'planner-book',
      entries: entries,
    );
    final studyPlanController = StudyPlanController(
      repository: _SingleBookStudyPlanRepository(book: book),
    );
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    final fsrsRepository = _RecordingFsrsRepository(
      cards: <String, FsrsCard>{
        'must-review': _plannerReviewCard(
          word: 'must-review',
          due: DateTime.now().toUtc().subtract(const Duration(days: 5)),
          stability: 2,
          lapses: 4,
        ),
        'review-1': _plannerReviewCard(
          word: 'review-1',
          due: DateTime.now().toUtc().subtract(const Duration(days: 1)),
          stability: 6,
          lapses: 0,
        ),
        'review-2': _plannerReviewCard(
          word: 'review-2',
          due: DateTime.now().toUtc().subtract(const Duration(hours: 12)),
          stability: 7,
          lapses: 0,
        ),
      },
    );

    await settingsController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudyHomePage(
            controller: studyPlanController,
            settingsController: settingsController,
            wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
            fsrsRepository: fsrsRepository,
            studyRepository: _FakeStudyRepository(),
            wordDetailPageBuilder: (word, initialEntry) =>
                const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    expect(find.text('must-review'), findsWidgets);

    await tester.tap(find.text('忘记'));
    await tester.pumpAndSettle();
    expect(find.text('review-1'), findsWidgets);

    await tester.tap(find.text('忘记'));
    await tester.pumpAndSettle();
    expect(find.text('review-2'), findsWidgets);

    await tester.tap(find.text('忘记'));
    await tester.pumpAndSettle();
    expect(find.text('new-1'), findsWidgets);
  });

  testWidgets('shows planner strategy summary on daily task card', (
    tester,
  ) async {
    final entries = <WordEntry>[
      _plannerEntry('review-1'),
      _plannerEntry('review-2'),
      _plannerEntry('review-3'),
      _plannerEntry('review-4'),
      _plannerEntry('review-5'),
      _plannerEntry('review-6'),
      _plannerEntry('probe-word'),
      _plannerEntry('new-1'),
      _plannerEntry('new-2'),
    ];
    final book = OfficialVocabularyBook(
      id: 'planner-book',
      category: 'Exam',
      title: 'Planner Book',
      subtitle: 'Subtitle',
      wordCount: entries.length,
      coverKey: 'planner-book',
      entries: entries,
    );
    final studyPlanController = StudyPlanController(
      repository: _SingleBookStudyPlanRepository(book: book),
    );
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(
        stored: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 4,
          dailyReviewLimitMultiplier: 1,
          studyPlanningMode: StudyPlanningMode.reviewFirst,
        ),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
      records: <WordKnowledgeRecord>[
        WordKnowledgeRecord(
          word: 'probe-word',
          isFavorite: false,
          isKnown: true,
          note: '',
          skipKnownConfirm: true,
          updatedAt: DateTime.now().toUtc().subtract(const Duration(days: 9)),
        ),
      ],
    );

    await settingsController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudyHomePage(
            controller: studyPlanController,
            settingsController: settingsController,
            wordKnowledgeRepository: wordKnowledgeRepository,
            fsrsRepository: _RecordingFsrsRepository(
              cards: <String, FsrsCard>{
                for (final word in <String>[
                  'review-1',
                  'review-2',
                  'review-3',
                  'review-4',
                  'review-5',
                  'review-6',
                ])
                  word: _plannerReviewCard(
                    word: word,
                    due: DateTime.now().toUtc().subtract(
                      const Duration(days: 2),
                    ),
                    stability: 5,
                    lapses: 1,
                  ),
                'probe-word': _plannerReviewCard(
                  word: 'probe-word',
                  due: DateTime.now().toUtc().add(const Duration(days: 14)),
                  stability: 18,
                  lapses: 0,
                ),
              },
            ),
            studyRepository: _FakeStudyRepository(),
            wordDetailPageBuilder: (word, initialEntry) =>
                const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('study-header-new-count')))
          .data,
      '1',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('study-header-review-count')))
          .data,
      '5',
    );
    expect(find.text('复习优先 · 积压中等 · 复习 4 · 新词 1 · 抽查 1'), findsOneWidget);
    expect(find.text('当前按复习优先编排，先清理到期任务 · 复习积压中等，今天先压缩新词'), findsOneWidget);
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

  @override
  Future<List<StudyDecisionRecord>> loadDecisionRecords() async {
    return const <StudyDecisionRecord>[];
  }
}

class _FakeDictionaryPreviewRepository implements DictionaryPreviewRepository {
  @override
  Future<void> disposePreview(DictionaryImportPreview preview) async {}

  @override
  Future<WordEntry?> loadEntry({
    required DictionaryImportPreview preview,
    required String key,
  }) async {
    return null;
  }

  @override
  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  }) async {
    return const DictionaryPreviewPage(pageNumber: 1, entries: []);
  }

  @override
  Future<DictionaryImportPreview> preparePreview(List<String> sourcePaths) {
    throw UnimplementedError();
  }
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({AppSettings? stored})
    : stored =
          stored ??
          const AppSettings.defaults().copyWith(
            dailyStudyTarget: 2,
            dailyReviewLimitMultiplier: 3,
          );

  final AppSettings stored;

  @override
  Future<AppSettings> load() async {
    return stored;
  }

  @override
  Future<void> save(AppSettings settings) async {}
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  _FakeWordKnowledgeRepository({this.records = const <WordKnowledgeRecord>[]});

  final List<WordKnowledgeRecord> records;

  @override
  Future<void> clearAll() async {}

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async => null;

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async {
    return records;
  }

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

class _SingleBookStudyPlanRepository implements StudyPlanRepository {
  _SingleBookStudyPlanRepository({required this.book});

  final OfficialVocabularyBook book;

  @override
  Future<void> createNotebook({
    required String name,
    String description = '',
  }) async {}

  @override
  Future<void> deleteNotebook(String notebookId) async {}

  @override
  Future<void> downloadBook(
    String bookId, {
    VocabularyDownloadProgressCallback? onProgress,
  }) async {}

  @override
  Future<void> importWordsToNotebook({
    required String notebookId,
    required List<String> words,
  }) async {}

  @override
  Future<List<OfficialVocabularyBook>> loadOfficialBooks() async {
    return <OfficialVocabularyBook>[book];
  }

  @override
  Future<StudyPlanOverview> loadOverview() async {
    return StudyPlanOverview(
      currentBook: book,
      myBooks: <OfficialVocabularyBook>[book],
      notebooks: const <VocabularyNotebook>[],
      selectedNotebookId: null,
      newCount: 0,
      reviewCount: 0,
      masteredCount: 0,
      remainingCount: book.wordCount,
      weekDays: const <StudyCalendarDay>[],
    );
  }

  @override
  Future<void> selectBook(String bookId) async {}

  @override
  Future<void> selectNotebook(String notebookId) async {}

  @override
  Future<void> updateNotebook({
    required String notebookId,
    required String name,
    String description = '',
  }) async {}
}

class _RecordingFsrsRepository implements FsrsRepository {
  _RecordingFsrsRepository({required Map<String, FsrsCard> cards})
    : _cards = cards;

  final Map<String, FsrsCard> _cards;

  @override
  Future<void> addReviewLog(FsrsReviewLog log) async {}

  @override
  Future<void> clearAll() async {
    _cards.clear();
  }

  @override
  Future<FsrsCard?> getByWord(String word) async {
    return _cards[WordKnowledgeRecord.normalizeWord(word)];
  }

  @override
  Future<List<FsrsCard>> loadAll() async {
    return _cards.values.toList(growable: false);
  }

  @override
  Future<Map<String, FsrsReviewLog>> loadLatestReviewLogsByWord() async {
    return const <String, FsrsReviewLog>{};
  }

  @override
  Future<void> saveCard(FsrsCard card) async {
    _cards[card.word] = card;
  }

  @override
  Future<void> saveReview(FsrsRecordLogItem item) async {
    _cards[item.card.word] = item.card;
  }
}

WordEntry _plannerEntry(String word) {
  return WordEntry(id: word, word: word, rawContent: word);
}

FsrsCard _plannerReviewCard({
  required String word,
  required DateTime due,
  required double stability,
  required int lapses,
}) {
  return FsrsCard(
    word: word,
    due: due,
    stability: stability,
    difficulty: 5,
    elapsedDays: 3,
    scheduledDays: 5,
    reps: 3,
    lapses: lapses,
    learningSteps: 0,
    state: FsrsState.review,
    lastReview: due.subtract(const Duration(days: 3)),
  );
}
