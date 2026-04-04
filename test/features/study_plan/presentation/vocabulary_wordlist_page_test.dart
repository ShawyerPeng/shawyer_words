import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/study/data/in_memory_study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_plan/presentation/study_home_page.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('词表按钮打开我的词表页并支持条目跳转', (tester) async {
    final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
      records: <String, WordKnowledgeRecord>{},
    );
    final fsrsRepository = _FakeFsrsRepository();
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
    await studyPlanController.selectBook('ielts-complete');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudyHomePage(
            controller: studyPlanController,
            settingsController: settingsController,
            wordKnowledgeRepository: wordKnowledgeRepository,
            fsrsRepository: fsrsRepository,
            studyRepository: InMemoryStudyRepository(),
            wordDetailPageBuilder: (word, initialEntry) =>
                Scaffold(body: Center(child: Text('detail:$word'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('词表'), findsOneWidget);
    await tester.tap(find.text('词表'));
    await tester.pumpAndSettle();

    expect(find.text('我的词表'), findsOneWidget);
    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('未学单词'), findsOneWidget);

    await tester.tap(find.text('未学单词'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('abandon'));
    await tester.pumpAndSettle();

    expect(find.text('detail:abandon'), findsOneWidget);
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
