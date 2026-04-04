import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_wordlist_page.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('我的词表页支持显示设置与批量标记掌握', (tester) async {
    final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
      records: <String, WordKnowledgeRecord>{},
    );
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 10,
          dailyReviewRatio: 4,
        ),
      ),
      wordKnowledgeRepository: wordKnowledgeRepository,
    );
    await settingsController.load();

    final studyPlanController = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(),
    );
    await studyPlanController.load();
    final fsrsRepository = _FakeFsrsRepository();

    const entry = WordEntry(
      id: 'w1',
      word: 'alpha',
      pronunciation: '/a/',
      partOfSpeech: 'n.',
      definition: '中文释义',
      rawContent: '',
    );
    final book = OfficialVocabularyBook(
      id: 'book-1',
      category: 'test',
      title: '测试词书',
      subtitle: '',
      wordCount: 1,
      coverKey: 'test',
      entries: const <WordEntry>[entry],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VocabularyWordListPage(
          book: book,
          settingsController: settingsController,
          studyPlanController: studyPlanController,
          fsrsRepository: fsrsRepository,
          wordKnowledgeRepository: wordKnowledgeRepository,
          wordDetailPageBuilder: (word, initialEntry) => const Scaffold(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('wordlist-action-mark-known')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('wordlist-action-add-notebook')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('wordlist-action-display')),
      findsOneWidget,
    );

    await tester.tap(find.text('未学单词'));
    await tester.pumpAndSettle();

    expect(find.text('中文释义'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wordlist-action-display')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('遮挡释义'));
    await tester.pumpAndSettle();

    expect(find.text('中文释义'), findsNothing);
    expect(find.text('•••'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('wordlist-action-mark-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('暂无数据'), findsOneWidget);
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({required this.settings});

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
  }
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  _FakeWordKnowledgeRepository({
    required Map<String, WordKnowledgeRecord> records,
  }) : _records = records;

  final Map<String, WordKnowledgeRecord> _records;

  @override
  Future<void> clearAll() async {
    _records.clear();
  }

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async {
    final normalized = WordKnowledgeRecord.normalizeWord(word);
    return _records[normalized];
  }

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async => _records.values.toList();

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {
    final normalized = WordKnowledgeRecord.normalizeWord(word);
    final current =
        _records[normalized] ?? WordKnowledgeRecord.initial(normalized);
    _records[normalized] = WordKnowledgeRecord(
      word: normalized,
      isFavorite: current.isFavorite,
      isKnown: true,
      note: current.note,
      skipKnownConfirm: skipConfirmNextTime,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> save(WordKnowledgeRecord record) async {
    _records[record.word] = record;
  }

  @override
  Future<void> saveNote(String word, String note) async {
    final normalized = WordKnowledgeRecord.normalizeWord(word);
    final current =
        _records[normalized] ?? WordKnowledgeRecord.initial(normalized);
    _records[normalized] = WordKnowledgeRecord(
      word: normalized,
      isFavorite: current.isFavorite,
      isKnown: current.isKnown,
      note: note,
      skipKnownConfirm: current.skipKnownConfirm,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> toggleFavorite(String word) async {
    final normalized = WordKnowledgeRecord.normalizeWord(word);
    final current =
        _records[normalized] ?? WordKnowledgeRecord.initial(normalized);
    _records[normalized] = WordKnowledgeRecord(
      word: normalized,
      isFavorite: !current.isFavorite,
      isKnown: current.isKnown,
      note: current.note,
      skipKnownConfirm: current.skipKnownConfirm,
      updatedAt: DateTime.now().toUtc(),
    );
  }
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
  Future<void> saveReview(FsrsRecordLogItem item) async {}

  @override
  Future<void> saveCard(FsrsCard card) async {}
}
