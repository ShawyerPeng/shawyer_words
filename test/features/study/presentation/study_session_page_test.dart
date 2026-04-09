import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/application/study_session_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/study_session_page.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('definition is shown directly and known advances to next word', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final studyRepository = _RecordingStudyRepository();
    final fsrsRepository = _FakeFsrsRepository();
    final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
      records: <String, WordKnowledgeRecord>{},
    );
    final controller = StudySessionController(
      entries: const [
        WordEntry(
          id: '1',
          word: 'aristocracy',
          pronunciation: '/ˌærɪˈstɒkrəsi/',
          definition: '贵族统治；贵族阶层',
          exampleSentence:
              'A new managerial elite was replacing the old aristocracy.',
          rawContent: '<p>aristocracy</p>',
        ),
        WordEntry(
          id: '2',
          word: 'brisk',
          pronunciation: '/brɪsk/',
          definition: '轻快的；敏捷的',
          exampleSentence: 'The morning air felt brisk.',
          rawContent: '<p>brisk</p>',
        ),
      ],
      studyRepository: studyRepository,
      fsrsRepository: fsrsRepository,
      wordKnowledgeRepository: wordKnowledgeRepository,
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: StudySessionPage(
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) => Scaffold(
            body: Center(
              child: Text('detail:$word:${initialEntry?.word ?? ''}'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('贵族统治；贵族阶层'), findsOneWidget);
    expect(find.text('aristocracy'), findsOneWidget);
    expect(find.text('标记熟悉'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('study-session-progress-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('study-session-word-card')),
      findsOneWidget,
    );
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('忘记'), findsWidgets);
    expect(find.text('模糊'), findsOneWidget);
    expect(find.text('查看完整释义'), findsOneWidget);

    await tester.ensureVisible(find.text('查看完整释义'));
    await tester.tap(find.text('查看完整释义'));
    await tester.pumpAndSettle();

    expect(find.text('detail:aristocracy:aristocracy'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('认识').last);
    await tester.pumpAndSettle();

    expect(studyRepository.savedEntryIds, ['1']);
    expect(studyRepository.savedDecisions, [StudyDecisionType.known]);
    expect(find.text('brisk'), findsOneWidget);
    expect(find.text('轻快的；敏捷的'), findsOneWidget);
  });

  testWidgets('mark mastered from top action records mastered summary', (
    tester,
  ) async {
    final controller = StudySessionController(
      entries: const [
        WordEntry(
          id: '1',
          word: 'aristocracy',
          rawContent: '<p>aristocracy</p>',
        ),
      ],
      studyRepository: _RecordingStudyRepository(),
      fsrsRepository: _FakeFsrsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionPage(
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.text('标记熟悉'));
    await tester.pumpAndSettle();

    expect(find.text('学习完成'), findsOneWidget);
    expect(find.text('本轮掌握情况'), findsOneWidget);
    expect(find.text('已掌握 1 个'), findsOneWidget);
    expect(find.text('认识 0 个'), findsOneWidget);
    expect(find.text('模糊 0 个'), findsOneWidget);
    expect(find.text('忘记 0 个'), findsOneWidget);
  });

  testWidgets('does not show task source badge for any task type', (
    tester,
  ) async {
    final controller = StudySessionController(
      entries: const [
        WordEntry(id: '1', word: 'fresh-word', rawContent: '<p>fresh-word</p>'),
        WordEntry(
          id: '2',
          word: 'review-word',
          rawContent: '<p>review-word</p>',
        ),
        WordEntry(id: '3', word: 'probe-word', rawContent: '<p>probe-word</p>'),
      ],
      studyRepository: _RecordingStudyRepository(),
      fsrsRepository: _FakeFsrsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{},
      ),
      entrySourcesByWord: const <String, StudyTaskSource>{
        'fresh-word': StudyTaskSource.newWord,
        'review-word': StudyTaskSource.mustReview,
        'probe-word': StudyTaskSource.probeWord,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionPage(
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('新学'), findsNothing);
    expect(find.text('新学任务'), findsNothing);
    expect(find.text('复习'), findsNothing);
    expect(find.text('抽查'), findsNothing);

    await tester.tap(find.text('认识').last);
    await tester.pumpAndSettle();

    expect(find.text('复习'), findsNothing);
    expect(find.text('复习任务'), findsNothing);
    expect(find.text('新学'), findsNothing);
    expect(find.text('抽查'), findsNothing);
    expect(find.text('熟词抽查'), findsNothing);

    await tester.tap(find.text('认识').last);
    await tester.pumpAndSettle();

    expect(find.text('抽查'), findsNothing);
    expect(find.text('熟词抽查'), findsNothing);
    expect(find.text('新学'), findsNothing);
    expect(find.text('复习'), findsNothing);
    expect(find.text('复习任务'), findsNothing);
  });

  testWidgets('swiping card right records known and advances', (tester) async {
    final studyRepository = _RecordingStudyRepository();
    final controller = StudySessionController(
      entries: const [
        WordEntry(id: '1', word: 'alpha', rawContent: '<p>alpha</p>'),
        WordEntry(id: '2', word: 'beta', rawContent: '<p>beta</p>'),
      ],
      studyRepository: studyRepository,
      fsrsRepository: _FakeFsrsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionPage(
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              const SizedBox.shrink(),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('study-session-word-card')),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();

    expect(studyRepository.savedEntryIds, ['1']);
    expect(studyRepository.savedDecisions, [StudyDecisionType.known]);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('swiping card left records forgot and advances', (tester) async {
    final studyRepository = _RecordingStudyRepository();
    final controller = StudySessionController(
      entries: const [
        WordEntry(id: '1', word: 'alpha', rawContent: '<p>alpha</p>'),
        WordEntry(id: '2', word: 'beta', rawContent: '<p>beta</p>'),
      ],
      studyRepository: studyRepository,
      fsrsRepository: _FakeFsrsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionPage(
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              const SizedBox.shrink(),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('study-session-word-card')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();

    expect(studyRepository.savedEntryIds, ['1']);
    expect(studyRepository.savedDecisions, [StudyDecisionType.forgot]);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('short swipe snaps back without recording decision', (tester) async {
    final studyRepository = _RecordingStudyRepository();
    final controller = StudySessionController(
      entries: const [
        WordEntry(id: '1', word: 'alpha', rawContent: '<p>alpha</p>'),
      ],
      studyRepository: studyRepository,
      fsrsRepository: _FakeFsrsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionPage(
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              const SizedBox.shrink(),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('study-session-word-card')),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();

    expect(studyRepository.savedEntryIds, isEmpty);
    expect(studyRepository.savedDecisions, isEmpty);
    expect(find.text('alpha'), findsOneWidget);
  });
}

class _RecordingStudyRepository implements StudyRepository {
  final List<String> savedEntryIds = <String>[];
  final List<StudyDecisionType> savedDecisions = <StudyDecisionType>[];

  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {
    savedEntryIds.add(entryId);
    savedDecisions.add(decision);
  }

  @override
  Future<List<StudyDecisionRecord>> loadDecisionRecords() async {
    return const <StudyDecisionRecord>[];
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
