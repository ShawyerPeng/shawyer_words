import 'dart:convert';

import 'package:shawyer_words/features/word_detail/data/dictionary_entry_lookup_repository.dart';
import 'package:shawyer_words/features/word_detail/data/lexdb_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/data/word_group_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';

class PlatformWordDetailRepository implements WordDetailRepository {
  PlatformWordDetailRepository({
    required DictionaryEntryLookupRepository lookupRepository,
    LexDbWordDetailRepository? lexDbRepository,
    WordGroupRepository? wordGroupRepository,
  }) : _lookupRepository = lookupRepository,
       _lexDbRepository = lexDbRepository,
       _wordGroupRepository = wordGroupRepository;

  final DictionaryEntryLookupRepository _lookupRepository;
  final LexDbWordDetailRepository? _lexDbRepository;
  final WordGroupRepository? _wordGroupRepository;

  @override
  Future<WordDetail> load(String word) async {
    final detailsFuture = _lookupRepository.lookupAcrossVisibleDictionaries(
      word,
    );
    final lexDbFuture = _loadLexDbEntries(word);
    final wordFamilyDefinitionsFuture = lexDbFuture.then(
      _loadWordFamilyBriefDefinitions,
    );
    final similarWordsFuture = _loadSimilarWords(word);
    final details = await detailsFuture;
    final lexDbEntries = await lexDbFuture;
    final wordFamilyDefinitions = await wordFamilyDefinitionsFuture;
    final similarWords = await similarWordsFuture;
    return aggregate(
      word: word,
      details: details,
      lexDbEntries: lexDbEntries,
      similarSpellingWords: similarWords.$1,
      similarSoundWords: similarWords.$2,
      wordFamilyBriefDefinitions: wordFamilyDefinitions,
    );
  }

  Future<List<LexDbEntryDetail>> _loadLexDbEntries(String word) async {
    try {
      return await _lexDbRepository?.lookup(word) ?? const <LexDbEntryDetail>[];
    } catch (_) {
      return const <LexDbEntryDetail>[];
    }
  }

  Future<(List<String>, List<String>)> _loadSimilarWords(String word) async {
    try {
      return await _wordGroupRepository?.lookupSimilarWords(word) ??
          (const <String>[], const <String>[]);
    } catch (_) {
      return (const <String>[], const <String>[]);
    }
  }

  Future<Map<String, String>> _loadWordFamilyBriefDefinitions(
    List<LexDbEntryDetail> entries,
  ) async {
    final repository = _lexDbRepository;
    if (repository == null) {
      return const <String, String>{};
    }
    final words = _extractWordFamilyWords(entries);
    if (words.isEmpty) {
      return const <String, String>{};
    }
    try {
      return await repository.lookupBriefDefinitions(words);
    } catch (_) {
      return const <String, String>{};
    }
  }

  Set<String> _extractWordFamilyWords(List<LexDbEntryDetail> entries) {
    final words = <String>{};

    void addWord(String value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        return;
      }
      words.add(normalized);
    }

    void collectWordFamily(Object? value) {
      if (value == null) {
        return;
      }
      if (value is String) {
        for (final part in value.split(RegExp(r'[,/;\n]+'))) {
          final normalized = part.trim();
          if (normalized.isEmpty) {
            continue;
          }
          addWord(normalized);
        }
        return;
      }
      if (value is List) {
        for (final item in value) {
          collectWordFamily(item);
        }
        return;
      }
      if (value is Map) {
        final map = Map<String, Object?>.from(value);
        collectWordFamily(map['word']);
        collectWordFamily(map['value']);
        collectWordFamily(map['text']);
        collectWordFamily(map['name']);
        collectWordFamily(map['words']);
        collectWordFamily(map['items']);
        collectWordFamily(map['groups']);
        collectWordFamily(map['forms']);
        collectWordFamily(map['entries']);
        collectWordFamily(map['members']);
      }
    }

    for (final entry in entries) {
      for (final attribute in entry.entryAttributes.entries) {
        final key = attribute.key.trim().toLowerCase();
        if (!(key.contains('word_family') ||
            key.contains('word_famil') ||
            key.contains('wordfamily') ||
            key.contains('wordfamil') ||
            key.endsWith('/family') ||
            key == 'family')) {
          continue;
        }

        final rawValue = attribute.value.trim();
        if (rawValue.isEmpty) {
          continue;
        }
        try {
          collectWordFamily(jsonDecode(rawValue));
        } on Object {
          collectWordFamily(rawValue);
        }
      }
    }
    return words;
  }

  static WordDetail aggregate({
    required String word,
    required List<DictionaryEntryDetail> details,
    List<LexDbEntryDetail> lexDbEntries = const <LexDbEntryDetail>[],
    List<String> similarSpellingWords = const <String>[],
    List<String> similarSoundWords = const <String>[],
    Map<String, String> wordFamilyBriefDefinitions = const <String, String>{},
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
        headword:
            _firstNonEmpty(details.map((detail) => detail.basic.headword)) ??
            normalizedWord,
        pronunciationUs: _firstNonEmpty(
          details.map((detail) => detail.basic.pronunciationUs),
        ),
        pronunciationUk: _firstNonEmpty(
          details.map((detail) => detail.basic.pronunciationUk),
        ),
        audioUs: _firstNonEmpty(details.map((detail) => detail.basic.audioUs)),
        audioUk: _firstNonEmpty(details.map((detail) => detail.basic.audioUk)),
        frequency: _firstNonEmpty(
          details.map((detail) => detail.basic.frequency),
        ),
      ),
      definitions: definitions,
      examples: examples,
      lexDbEntries: lexDbEntries,
      dictionaryPanels: details,
      similarSpellingWords: similarSpellingWords,
      similarSoundWords: similarSoundWords,
      wordFamilyBriefDefinitions: wordFamilyBriefDefinitions,
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
