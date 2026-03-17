import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  test('loads aggregated detail and word knowledge', () async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          basic: WordBasicSummary(headword: 'abandon'),
          definitions: <WordSense>[
            WordSense(partOfSpeech: 'verb', definitionZh: '放弃'),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(
        seed: WordKnowledgeRecord(
          word: 'abandon',
          isFavorite: true,
          isKnown: false,
          note: 'Seen in reading practice',
          skipKnownConfirm: false,
          updatedAt: DateTime.parse('2026-03-16T12:00:00.000Z'),
        ),
      ),
    );

    await controller.load('abandon');

    expect(controller.state.status, WordDetailStatus.ready);
    expect(controller.state.detail?.definitions.single.definitionZh, '放弃');
    expect(controller.state.knowledge?.isFavorite, isTrue);
    expect(controller.state.knowledge?.note, 'Seen in reading practice');
  });

  test('toggleFavorite updates the saved knowledge state', () async {
    final knowledgeRepository = _FakeWordKnowledgeRepository();
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(word: 'abandon'),
      ),
      knowledgeRepository: knowledgeRepository,
    );

    await controller.load('abandon');
    await controller.toggleFavorite();

    expect(controller.state.knowledge?.isFavorite, isTrue);
    expect(
      (await knowledgeRepository.getByWord('abandon'))?.isFavorite,
      isTrue,
    );
  });

  test('markKnown persists known and skip-confirm flags', () async {
    final knowledgeRepository = _FakeWordKnowledgeRepository();
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(word: 'abandon'),
      ),
      knowledgeRepository: knowledgeRepository,
    );

    await controller.load('abandon');
    await controller.markKnown(skipConfirmNextTime: true);

    expect(controller.state.knowledge?.isKnown, isTrue);
    expect(controller.state.knowledge?.skipKnownConfirm, isTrue);
  });

  test('saveNote refreshes controller state from persistence', () async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(word: 'abandon'),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await controller.load('abandon');
    await controller.saveNote('Used in CET4 essays');

    expect(controller.state.knowledge?.note, 'Used in CET4 essays');
  });

  test('load surfaces repository failures', () async {
    final controller = WordDetailController(
      detailRepository: _ThrowingWordDetailRepository(),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await controller.load('abandon');

    expect(controller.state.status, WordDetailStatus.failure);
    expect(controller.state.errorMessage, contains('detail lookup failed'));
  });
}

class _FakeWordDetailRepository implements WordDetailRepository {
  _FakeWordDetailRepository({required this.detail});

  final WordDetail detail;

  @override
  Future<WordDetail> load(String word) async => detail;
}

class _ThrowingWordDetailRepository implements WordDetailRepository {
  @override
  Future<WordDetail> load(String word) async {
    throw StateError('detail lookup failed');
  }
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  _FakeWordKnowledgeRepository({WordKnowledgeRecord? seed}) {
    if (seed != null) {
      _records[seed.word] = seed;
    }
  }

  final Map<String, WordKnowledgeRecord> _records =
      <String, WordKnowledgeRecord>{};

  @override
  Future<void> clearAll() async {
    _records.clear();
  }

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async {
    return _records[WordKnowledgeRecord.normalizeWord(word)];
  }

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async {
    return _records.values.toList(growable: false);
  }

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    _records[current.word] = WordKnowledgeRecord(
      word: current.word,
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
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    _records[current.word] = WordKnowledgeRecord(
      word: current.word,
      isFavorite: current.isFavorite,
      isKnown: current.isKnown,
      note: note,
      skipKnownConfirm: current.skipKnownConfirm,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> toggleFavorite(String word) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    _records[current.word] = WordKnowledgeRecord(
      word: current.word,
      isFavorite: !current.isFavorite,
      isKnown: current.isKnown,
      note: current.note,
      skipKnownConfirm: current.skipKnownConfirm,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
