import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/data/in_memory_search_history_repository.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';

void main() {
  test('updates prefix suggestions and keeps the latest 10 history items', () async {
    final controller = SearchController(
      lookupRepository: _FakeWordLookupRepository(
        [
          const WordEntry(
            id: 'nut',
            word: 'nut',
            partOfSpeech: 'n.',
            definition: '干果, 坚果',
            rawContent: '<p>nut</p>',
          ),
          const WordEntry(
            id: 'nurture',
            word: 'nurture',
            partOfSpeech: 'v.',
            definition: '培养',
            rawContent: '<p>nurture</p>',
          ),
          const WordEntry(
            id: 'career',
            word: 'career',
            partOfSpeech: 'n.',
            definition: '事业, 职业',
            rawContent: '<p>career</p>',
          ),
        ],
      ),
      historyRepository: InMemorySearchHistoryRepository(),
    );

    controller.updateQuery('nu');

    expect(controller.state.results.map((entry) => entry.word), [
      'nut',
      'nurture',
    ]);

    await controller.selectEntry(controller.state.results.first);
    await controller.selectEntry(
      const WordEntry(
        id: 'w2',
        word: 'word-2',
        rawContent: '<p>word-2</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w3',
        word: 'word-3',
        rawContent: '<p>word-3</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w4',
        word: 'word-4',
        rawContent: '<p>word-4</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w5',
        word: 'word-5',
        rawContent: '<p>word-5</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w6',
        word: 'word-6',
        rawContent: '<p>word-6</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w7',
        word: 'word-7',
        rawContent: '<p>word-7</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w8',
        word: 'word-8',
        rawContent: '<p>word-8</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w9',
        word: 'word-9',
        rawContent: '<p>word-9</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w10',
        word: 'word-10',
        rawContent: '<p>word-10</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w11',
        word: 'word-11',
        rawContent: '<p>word-11</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'w12',
        word: 'word-12',
        rawContent: '<p>word-12</p>',
      ),
    );
    await controller.selectEntry(
      const WordEntry(
        id: 'nut',
        word: 'nut',
        partOfSpeech: 'n.',
        definition: '干果, 坚果',
        rawContent: '<p>nut</p>',
      ),
    );

    expect(controller.state.history, hasLength(10));
    expect(controller.state.history.first.word, 'nut');
    expect(controller.state.history.where((entry) => entry.word == 'nut'), hasLength(1));
    expect(controller.state.history.last.word, 'word-4');
  });
}

class _FakeWordLookupRepository implements WordLookupRepository {
  _FakeWordLookupRepository(this.entries);

  final List<WordEntry> entries;

  @override
  WordEntry? findById(String id) {
    for (final entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  @override
  List<WordEntry> searchWords(String query, {int limit = 20}) {
    return entries
        .where((entry) => entry.word.toLowerCase().startsWith(query.toLowerCase()))
        .take(limit)
        .toList();
  }
}
