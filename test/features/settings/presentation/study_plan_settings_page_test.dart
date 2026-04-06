import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/presentation/study_plan_settings_page.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('updates study planning mode from settings sheet', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    final studyPlanController = StudyPlanController(
      repository: _SingleBookStudyPlanRepository(book: _book()),
    );
    await settingsController.load();
    await studyPlanController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: StudyPlanSettingsPage(
          settingsController: settingsController,
          studyPlanController: studyPlanController,
          wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
          fsrsRepository: _FakeFsrsRepository(),
          wordDetailPageBuilder: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('学习计划'), findsOneWidget);
    expect(find.text('查看词表'), findsOneWidget);
    expect(find.text('复习任务上限'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('出词顺序'), 200);
    expect(find.text('出词顺序'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('计划策略'), 200);
    expect(find.text('计划策略'), findsOneWidget);
    expect(find.text('均衡推进'), findsOneWidget);

    await tester.tap(find.text('计划策略'));
    await tester.pumpAndSettle();

    expect(find.text('冲刺突击'), findsOneWidget);

    await tester.tap(find.text('冲刺突击'));
    await tester.pumpAndSettle();

    expect(
      settingsController.state.settings.studyPlanningMode,
      StudyPlanningMode.sprint,
    );
    expect(find.text('冲刺突击'), findsOneWidget);
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  AppSettings _settings = const AppSettings.defaults();

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
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

class _FakeFsrsRepository implements FsrsRepository {
  @override
  Future<void> addReviewLog(FsrsReviewLog log) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<FsrsCard?> getByWord(String word) async => null;

  @override
  Future<List<FsrsCard>> loadAll() async => const <FsrsCard>[];

  @override
  Future<Map<String, FsrsReviewLog>> loadLatestReviewLogsByWord() async {
    return const <String, FsrsReviewLog>{};
  }

  @override
  Future<void> saveCard(FsrsCard card) async {}

  @override
  Future<void> saveReview(FsrsRecordLogItem item) async {}
}

OfficialVocabularyBook _book() {
  const entry = WordEntry(
    id: 'abandon',
    word: 'abandon',
    rawContent: 'abandon',
  );
  return const OfficialVocabularyBook(
    id: 'book',
    category: 'Exam',
    title: 'Book',
    subtitle: 'Subtitle',
    wordCount: 1,
    coverKey: 'book',
    entries: <WordEntry>[entry],
  );
}
