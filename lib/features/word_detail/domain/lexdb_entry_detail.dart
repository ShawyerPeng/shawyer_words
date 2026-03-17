class LexDbEntryDetail {
  const LexDbEntryDetail({
    required this.dictionaryId,
    required this.dictionaryName,
    required this.headword,
    this.headwordDisplay,
    this.pronunciations = const <LexDbPronunciation>[],
    this.entryLabels = const <LexDbLabel>[],
    this.senses = const <LexDbSense>[],
    this.collocations = const <LexDbCollocation>[],
  });

  final String dictionaryId;
  final String dictionaryName;
  final String headword;
  final String? headwordDisplay;
  final List<LexDbPronunciation> pronunciations;
  final List<LexDbLabel> entryLabels;
  final List<LexDbSense> senses;
  final List<LexDbCollocation> collocations;

  @override
  bool operator ==(Object other) {
    return other is LexDbEntryDetail &&
        other.dictionaryId == dictionaryId &&
        other.dictionaryName == dictionaryName &&
        other.headword == headword &&
        other.headwordDisplay == headwordDisplay &&
        _listEquals(other.pronunciations, pronunciations) &&
        _listEquals(other.entryLabels, entryLabels) &&
        _listEquals(other.senses, senses) &&
        _listEquals(other.collocations, collocations);
  }

  @override
  int get hashCode => Object.hash(
    dictionaryId,
    dictionaryName,
    headword,
    headwordDisplay,
    Object.hashAll(pronunciations),
    Object.hashAll(entryLabels),
    Object.hashAll(senses),
    Object.hashAll(collocations),
  );
}

class LexDbPronunciation {
  const LexDbPronunciation({
    required this.variant,
    this.phonetic,
    this.audioPath,
  });

  final String variant;
  final String? phonetic;
  final String? audioPath;

  @override
  bool operator ==(Object other) {
    return other is LexDbPronunciation &&
        other.variant == variant &&
        other.phonetic == phonetic &&
        other.audioPath == audioPath;
  }

  @override
  int get hashCode => Object.hash(variant, phonetic, audioPath);
}

class LexDbLabel {
  const LexDbLabel({required this.type, required this.value});

  final String type;
  final String value;

  @override
  bool operator ==(Object other) {
    return other is LexDbLabel && other.type == type && other.value == value;
  }

  @override
  int get hashCode => Object.hash(type, value);
}

class LexDbSense {
  const LexDbSense({
    required this.id,
    this.number,
    this.signpost,
    required this.definition,
    this.definitionZh,
    this.labels = const <LexDbLabel>[],
    this.examplesBeforePatterns = const <LexDbExample>[],
    this.grammarPatterns = const <LexDbGrammarPattern>[],
    this.examplesAfterPatterns = const <LexDbExample>[],
  });

  final int id;
  final String? number;
  final String? signpost;
  final String definition;
  final String? definitionZh;
  final List<LexDbLabel> labels;
  final List<LexDbExample> examplesBeforePatterns;
  final List<LexDbGrammarPattern> grammarPatterns;
  final List<LexDbExample> examplesAfterPatterns;

  @override
  bool operator ==(Object other) {
    return other is LexDbSense &&
        other.id == id &&
        other.number == number &&
        other.signpost == signpost &&
        other.definition == definition &&
        other.definitionZh == definitionZh &&
        _listEquals(other.labels, labels) &&
        _listEquals(other.examplesBeforePatterns, examplesBeforePatterns) &&
        _listEquals(other.grammarPatterns, grammarPatterns) &&
        _listEquals(other.examplesAfterPatterns, examplesAfterPatterns);
  }

  @override
  int get hashCode => Object.hash(
    id,
    number,
    signpost,
    definition,
    definitionZh,
    Object.hashAll(labels),
    Object.hashAll(examplesBeforePatterns),
    Object.hashAll(grammarPatterns),
    Object.hashAll(examplesAfterPatterns),
  );
}

class LexDbExample {
  const LexDbExample({required this.text, this.textZh, this.audioPath});

  final String text;
  final String? textZh;
  final String? audioPath;

  @override
  bool operator ==(Object other) {
    return other is LexDbExample &&
        other.text == text &&
        other.textZh == textZh &&
        other.audioPath == audioPath;
  }

  @override
  int get hashCode => Object.hash(text, textZh, audioPath);
}

class LexDbGrammarPattern {
  const LexDbGrammarPattern({
    required this.pattern,
    this.gloss,
    this.examples = const <LexDbExample>[],
  });

  final String pattern;
  final String? gloss;
  final List<LexDbExample> examples;

  @override
  bool operator ==(Object other) {
    return other is LexDbGrammarPattern &&
        other.pattern == pattern &&
        other.gloss == gloss &&
        _listEquals(other.examples, examples);
  }

  @override
  int get hashCode => Object.hash(pattern, gloss, Object.hashAll(examples));
}

class LexDbCollocation {
  const LexDbCollocation({
    required this.collocate,
    this.grammar,
    this.definition,
    this.examples = const <LexDbExample>[],
  });

  final String collocate;
  final String? grammar;
  final String? definition;
  final List<LexDbExample> examples;

  @override
  bool operator ==(Object other) {
    return other is LexDbCollocation &&
        other.collocate == collocate &&
        other.grammar == grammar &&
        other.definition == definition &&
        _listEquals(other.examples, examples);
  }

  @override
  int get hashCode =>
      Object.hash(collocate, grammar, definition, Object.hashAll(examples));
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
