import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/presentation/study_statistics_page.dart';
import 'package:shawyer_words/features/study/data/in_memory_study_repository.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('learning status uses latest review logs for today counts', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    final studyPlanController = StudyPlanController(
      repository: _FakeStudyPlanRepository(),
    );
    final studyRepository = InMemoryStudyRepository();
    final fsrsRepository = _FakeFsrsRepository(
      cards: <FsrsCard>[
        FsrsCard(
          word: 'abandon',
          due: DateTime.utc(2026, 4, 5, 8),
          stability: 35,
          difficulty: 4,
          elapsedDays: 3,
          scheduledDays: 5,
          reps: 2,
          lapses: 0,
          learningSteps: 0,
          state: FsrsState.review,
          lastReview: DateTime.utc(2026, 4, 5, 9),
        ),
        FsrsCard(
          word: 'ability',
          due: DateTime.utc(2026, 4, 5, 8),
          stability: 18,
          difficulty: 6,
          elapsedDays: 1,
          scheduledDays: 2,
          reps: 1,
          lapses: 0,
          learningSteps: 0,
          state: FsrsState.review,
          lastReview: DateTime.utc(2026, 4, 5, 10),
        ),
      ],
      latestLogsByWord: <String, FsrsReviewLog>{
        'abandon': FsrsReviewLog(
          word: 'abandon',
          rating: FsrsRating.easy,
          state: FsrsState.review,
          due: DateTime.utc(2026, 4, 5, 8),
          stability: 35,
          difficulty: 4,
          elapsedDays: 3,
          lastElapsedDays: 1,
          scheduledDays: 5,
          learningSteps: 0,
          reviewedAt: DateTime.utc(2026, 4, 5, 9),
        ),
        'ability': FsrsReviewLog(
          word: 'ability',
          rating: FsrsRating.hard,
          state: FsrsState.review,
          due: DateTime.utc(2026, 4, 5, 8),
          stability: 18,
          difficulty: 6,
          elapsedDays: 1,
          lastElapsedDays: 0,
          scheduledDays: 2,
          learningSteps: 0,
          reviewedAt: DateTime.utc(2026, 4, 5, 10),
        ),
      },
    );
    await studyRepository.saveDecision(
      entryId: '1',
      decision: StudyDecisionType.mastered,
    );
    await studyRepository.saveDecision(
      entryId: '2',
      decision: StudyDecisionType.fuzzy,
    );

    await settingsController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: StudyStatisticsPage(
          controller: settingsController,
          studyPlanController: studyPlanController,
          studyRepository: studyRepository,
          wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
          fsrsRepository: fsrsRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('今日已掌握: 1'), 300);

    expect(find.text('今日已掌握: 1'), findsOneWidget);
    expect(find.text('今日认识: 0'), findsOneWidget);
    expect(find.text('今日模糊: 1'), findsOneWidget);
    expect(find.text('今日忘记: 0'), findsOneWidget);
    expect(find.text('今日时长: 4m'), findsOneWidget);
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings.defaults();

  @override
  Future<void> save(AppSettings settings) async {}
}

class _FakeStudyPlanRepository implements StudyPlanRepository {
  static const OfficialVocabularyBook _book = OfficialVocabularyBook(
    id: 'cet4',
    category: 'Exam',
    title: 'CET-4',
    subtitle: 'College English Test',
    wordCount: 2,
    coverKey: 'cet4',
    entries: <WordEntry>[
      WordEntry(id: '1', word: 'abandon', rawContent: 'abandon'),
      WordEntry(id: '2', word: 'ability', rawContent: 'ability'),
    ],
  );

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
    return const <OfficialVocabularyBook>[_book];
  }

  @override
  Future<StudyPlanOverview> loadOverview() async {
    return const StudyPlanOverview(
      currentBook: _book,
      myBooks: <OfficialVocabularyBook>[],
      notebooks: <VocabularyNotebook>[],
      selectedNotebookId: null,
      newCount: 20,
      reviewCount: 0,
      masteredCount: 0,
      remainingCount: 2,
      weekDays: <StudyCalendarDay>[],
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

class _FakeFsrsRepository implements FsrsRepository {
  _FakeFsrsRepository({
    required List<FsrsCard> cards,
    required Map<String, FsrsReviewLog> latestLogsByWord,
  }) : _cards = cards,
       _latestLogsByWord = latestLogsByWord;

  final List<FsrsCard> _cards;
  final Map<String, FsrsReviewLog> _latestLogsByWord;

  @override
  Future<void> addReviewLog(FsrsReviewLog log) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<FsrsCard?> getByWord(String word) async => null;

  @override
  Future<List<FsrsCard>> loadAll() async => _cards;

  @override
  Future<Map<String, FsrsReviewLog>> loadLatestReviewLogsByWord() async {
    return _latestLogsByWord;
  }

  @override
  Future<void> saveReview(FsrsRecordLogItem item) async {}

  @override
  Future<void> saveCard(FsrsCard card) async {}
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  @override
  Future<void> clearAll() async {}

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async => null;

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async {
    return const <WordKnowledgeRecord>[];
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
