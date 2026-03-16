import 'package:shawyer_words/features/word_detail/data/dictionary_entry_lookup_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';

class PlatformWordDetailRepository implements WordDetailRepository {
  PlatformWordDetailRepository({
    required DictionaryEntryLookupRepository lookupRepository,
  }) : _lookupRepository = lookupRepository;

  final DictionaryEntryLookupRepository _lookupRepository;

  @override
  Future<WordDetail> load(String word) async {
    final details = await _lookupRepository.lookupAcrossVisibleDictionaries(word);
    return aggregate(word: word, details: details);
  }

  static WordDetail aggregate({
    required String word,
    required List<DictionaryEntryDetail> details,
  }) {
    final normalizedWord = word.trim().toLowerCase();
    final definitions = <WordSense>[];
    final definitionKeys = <String>{};
    final examples = <WordExample>[];
    final exampleKeys = <String>{};

    for (final detail in details) {
      for (final definition in detail.definitions) {
        final key = '${definition.partOfSpeech}::${definition.definitionZh}';
        if (definitionKeys.add(key)) {
          definitions.add(definition);
        }
      }
      for (final example in detail.examples) {
        final key = '${example.english}::${example.translationZh}';
        if (exampleKeys.add(key)) {
          examples.add(example);
        }
      }
    }

    return WordDetail(
      word: normalizedWord,
      basic: WordBasicSummary(
        headword: _firstNonEmpty(
              details.map((detail) => detail.basic.headword),
            ) ??
            normalizedWord,
        pronunciationUs: _firstNonEmpty(
          details.map((detail) => detail.basic.pronunciationUs),
        ),
        pronunciationUk: _firstNonEmpty(
          details.map((detail) => detail.basic.pronunciationUk),
        ),
        audioUs: _firstNonEmpty(
          details.map((detail) => detail.basic.audioUs),
        ),
        audioUk: _firstNonEmpty(
          details.map((detail) => detail.basic.audioUk),
        ),
        frequency: _firstNonEmpty(
          details.map((detail) => detail.basic.frequency),
        ),
      ),
      definitions: definitions,
      examples: examples,
      dictionaryPanels: details,
    );
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
