import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/data/sample_word_lookup_repository.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';

class DictionaryWordLookupRepository implements WordLookupRepository {
  DictionaryWordLookupRepository({
    required DictionaryController dictionaryController,
    required WordLookupRepository fallbackRepository,
  }) : _dictionaryController = dictionaryController,
       _fallbackRepository = fallbackRepository;

  final DictionaryController _dictionaryController;
  final WordLookupRepository _fallbackRepository;

  @override
  WordEntry? findById(String id) {
    for (final entry in _dictionaryController.state.entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return _fallbackRepository.findById(id);
  }

  @override
  List<WordEntry> searchWords(String query, {int limit = 20}) {
    final importedEntries = _dictionaryController.state.entries;
    if (importedEntries.isNotEmpty) {
      return rankWordEntries(importedEntries, query, limit: limit);
    }
    return _fallbackRepository.searchWords(query, limit: limit);
  }
}
