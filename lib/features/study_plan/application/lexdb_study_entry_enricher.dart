import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/word_detail/data/lexdb_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';

class LexDbStudyEntryEnricher {
  const LexDbStudyEntryEnricher({
    required LexDbWordDetailRepository? repository,
  }) : _repository = repository;

  final LexDbWordDetailRepository? _repository;

  Future<List<WordEntry>> enrichEntries(Iterable<WordEntry> entries) async {
    final repository = _repository;
    final entryList = entries.toList(growable: false);
    if (repository == null || entryList.isEmpty) {
      return entryList;
    }

    final detailCache = <String, LexDbEntryDetail?>{};
    final enrichedEntries = <WordEntry>[];

    for (final entry in entryList) {
      final normalizedWord = entry.word.trim().toLowerCase();
      final cached = detailCache.containsKey(normalizedWord)
          ? detailCache[normalizedWord]
          : detailCache[normalizedWord] = await _loadFirstDetail(
              repository,
              normalizedWord,
            );
      enrichedEntries.add(_mergeEntry(entry, cached));
    }

    return enrichedEntries;
  }

  Future<LexDbEntryDetail?> _loadFirstDetail(
    LexDbWordDetailRepository repository,
    String normalizedWord,
  ) async {
    if (normalizedWord.isEmpty) {
      return null;
    }
    try {
      final details = await repository.lookup(normalizedWord);
      return details.isEmpty ? null : details.first;
    } catch (_) {
      return null;
    }
  }

  WordEntry _mergeEntry(WordEntry entry, LexDbEntryDetail? detail) {
    if (detail == null) {
      return entry;
    }

    return WordEntry(
      id: entry.id,
      word: entry.word,
      pronunciation: _pickValue(
        entry.pronunciation,
        _extractPronunciation(detail),
      ),
      partOfSpeech: _pickValue(
        entry.partOfSpeech,
        _extractPartOfSpeech(detail),
      ),
      definition: _pickValue(entry.definition, _extractDefinition(detail)),
      exampleSentence: _pickValue(
        entry.exampleSentence,
        _extractExampleSentence(detail),
      ),
      exampleAudioPath: _pickValue(
        entry.exampleAudioPath,
        _extractExampleAudioPath(detail),
      ),
      rawContent: entry.rawContent,
    );
  }

  String? _extractPronunciation(LexDbEntryDetail detail) {
    final pronunciations = detail.pronunciations;
    for (final pronunciation in pronunciations) {
      final variant = pronunciation.variant.trim().toLowerCase();
      final phonetic = pronunciation.phonetic?.trim();
      if (phonetic == null || phonetic.isEmpty) {
        continue;
      }
      if (variant.contains('us') || variant.contains('am')) {
        return phonetic;
      }
    }
    for (final pronunciation in pronunciations) {
      final phonetic = pronunciation.phonetic?.trim();
      if (phonetic != null && phonetic.isNotEmpty) {
        return phonetic;
      }
    }
    return null;
  }

  String? _extractPartOfSpeech(LexDbEntryDetail detail) {
    for (final label in detail.entryLabels) {
      final type = label.type.trim().toLowerCase();
      final value = label.value.trim();
      if (value.isEmpty) {
        continue;
      }
      if (type.contains('pos') || type.contains('part_of_speech')) {
        return value;
      }
    }
    return null;
  }

  String? _extractDefinition(LexDbEntryDetail detail) {
    for (final sense in detail.senses) {
      final definitionZh = sense.definitionZh?.trim();
      if (definitionZh != null && definitionZh.isNotEmpty) {
        return definitionZh;
      }
      final definition = sense.definition.trim();
      if (definition.isNotEmpty) {
        return definition;
      }
    }
    for (final collocation in detail.collocations) {
      final definition = collocation.definition?.trim();
      if (definition != null && definition.isNotEmpty) {
        return definition;
      }
    }
    return null;
  }

  String? _extractExampleSentence(LexDbEntryDetail detail) {
    for (final sense in detail.senses) {
      for (final example in sense.examplesBeforePatterns) {
        final text = example.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      for (final pattern in sense.grammarPatterns) {
        for (final example in pattern.examples) {
          final text = example.text.trim();
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
      for (final example in sense.examplesAfterPatterns) {
        final text = example.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    for (final collocation in detail.collocations) {
      for (final example in collocation.examples) {
        final text = example.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }

  String? _extractExampleAudioPath(LexDbEntryDetail detail) {
    for (final sense in detail.senses) {
      for (final example in sense.examplesBeforePatterns) {
        final audioPath = example.audioPath?.trim();
        if (audioPath != null && audioPath.isNotEmpty) {
          return audioPath;
        }
      }
      for (final pattern in sense.grammarPatterns) {
        for (final example in pattern.examples) {
          final audioPath = example.audioPath?.trim();
          if (audioPath != null && audioPath.isNotEmpty) {
            return audioPath;
          }
        }
      }
      for (final example in sense.examplesAfterPatterns) {
        final audioPath = example.audioPath?.trim();
        if (audioPath != null && audioPath.isNotEmpty) {
          return audioPath;
        }
      }
    }
    for (final collocation in detail.collocations) {
      for (final example in collocation.examples) {
        final audioPath = example.audioPath?.trim();
        if (audioPath != null && audioPath.isNotEmpty) {
          return audioPath;
        }
      }
    }
    return null;
  }

  String? _pickValue(String? original, String? enriched) {
    final originalValue = original?.trim();
    if (originalValue != null && originalValue.isNotEmpty) {
      return original;
    }
    final enrichedValue = enriched?.trim();
    if (enrichedValue == null || enrichedValue.isEmpty) {
      return original;
    }
    return enrichedValue;
  }
}
