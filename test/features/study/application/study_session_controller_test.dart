import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/application/study_session_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  test(
    'probe failure clears known state and records a forgot decision',
    () async {
      final studyRepository = _RecordingStudyRepository();
      final fsrsRepository = _FakeFsrsRepository();
      final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{
          'probe-word': WordKnowledgeRecord(
            word: 'probe-word',
            isFavorite: false,
            isKnown: true,
            note: '',
            skipKnownConfirm: true,
            updatedAt: DateTime.utc(2026, 4, 1),
          ),
        },
      );
      final controller = StudySessionController(
        entries: const <WordEntry>[
          WordEntry(id: '1', word: 'probe-word', rawContent: 'probe-word'),
        ],
        studyRepository: studyRepository,
        fsrsRepository: fsrsRepository,
        wordKnowledgeRepository: wordKnowledgeRepository,
        entrySourcesByWord: const <String, StudyTaskSource>{
          'probe-word': StudyTaskSource.probeWord,
        },
      );

      await controller.markAgain();

      final saved = await wordKnowledgeRepository.getByWord('probe-word');
      expect(saved?.isKnown, isFalse);
      expect(saved?.skipKnownConfirm, isFalse);
      expect(studyRepository.savedDecisions, <StudyDecisionType>[
        StudyDecisionType.forgot,
      ]);
      expect(controller.state.forgotCount, 1);
    },
  );

  test(
    'probe success keeps known state and renews skip confirmation',
    () async {
      final studyRepository = _RecordingStudyRepository();
      final fsrsRepository = _FakeFsrsRepository();
      final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
        records: <String, WordKnowledgeRecord>{
          'probe-word': WordKnowledgeRecord(
            word: 'probe-word',
            isFavorite: false,
            isKnown: true,
            note: '',
            skipKnownConfirm: true,
            updatedAt: DateTime.utc(2026, 4, 1),
          ),
        },
      );
      final controller = StudySessionController(
        entries: const <WordEntry>[
          WordEntry(id: '1', word: 'probe-word', rawContent: 'probe-word'),
        ],
        studyRepository: studyRepository,
        fsrsRepository: fsrsRepository,
        wordKnowledgeRepository: wordKnowledgeRepository,
        entrySourcesByWord: const <String, StudyTaskSource>{
          'probe-word': StudyTaskSource.probeWord,
        },
      );

      await controller.markGood();

      final saved = await wordKnowledgeRepository.getByWord('probe-word');
      expect(saved?.isKnown, isTrue);
      expect(saved?.skipKnownConfirm, isTrue);
      expect(studyRepository.savedDecisions, <StudyDecisionType>[
        StudyDecisionType.known,
      ]);
      expect(controller.state.knownCount, 1);
    },
  );

  test('hard rating records a fuzzy decision without marking known', () async {
    final studyRepository = _RecordingStudyRepository();
    final fsrsRepository = _FakeFsrsRepository();
    final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
      records: <String, WordKnowledgeRecord>{},
    );
    final controller = StudySessionController(
      entries: const <WordEntry>[
        WordEntry(id: '1', word: 'word', rawContent: 'word'),
      ],
      studyRepository: studyRepository,
      fsrsRepository: fsrsRepository,
      wordKnowledgeRepository: wordKnowledgeRepository,
    );

    await controller.markHard();

    final saved = await wordKnowledgeRepository.getByWord('word');
    expect(saved?.isKnown, isFalse);
    expect(saved?.skipKnownConfirm, isFalse);
    expect(studyRepository.savedDecisions, <StudyDecisionType>[
      StudyDecisionType.fuzzy,
    ]);
    expect(controller.state.fuzzyCount, 1);
  });

  test('easy rating records mastered and enables known acceleration', () async {
    final studyRepository = _RecordingStudyRepository();
    final fsrsRepository = _FakeFsrsRepository();
    final wordKnowledgeRepository = _FakeWordKnowledgeRepository(
      records: <String, WordKnowledgeRecord>{},
    );
    final controller = StudySessionController(
      entries: const <WordEntry>[
        WordEntry(id: '1', word: 'word', rawContent: 'word'),
      ],
      studyRepository: studyRepository,
      fsrsRepository: fsrsRepository,
      wordKnowledgeRepository: wordKnowledgeRepository,
    );

    await controller.markEasy();

    final saved = await wordKnowledgeRepository.getByWord('word');
    expect(saved?.isKnown, isTrue);
    expect(saved?.skipKnownConfirm, isTrue);
    expect(studyRepository.savedDecisions, <StudyDecisionType>[
      StudyDecisionType.mastered,
    ]);
    expect(controller.state.masteredCount, 1);
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
  Future<void> saveCard(FsrsCard card) async {}

  @override
  Future<void> saveReview(FsrsRecordLogItem item) async {}
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
    return _records[WordKnowledgeRecord.normalizeWord(word)];
  }

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async => _records.values.toList();

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {}

  @override
  Future<void> save(WordKnowledgeRecord record) async {
    _records[record.word] = record;
  }

  @override
  Future<void> saveNote(String word, String note) async {}

  @override
  Future<void> toggleFavorite(String word) async {}
}
