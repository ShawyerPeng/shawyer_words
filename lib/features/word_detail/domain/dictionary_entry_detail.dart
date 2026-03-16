class DictionaryEntryDetail {
  const DictionaryEntryDetail({
    required this.dictionaryId,
    required this.dictionaryName,
    required this.word,
    required this.rawContent,
    this.basic = const WordBasicSummary(),
    this.definitions = const <WordSense>[],
    this.examples = const <WordExample>[],
    this.errorMessage,
  });

  final String dictionaryId;
  final String dictionaryName;
  final String word;
  final String rawContent;
  final WordBasicSummary basic;
  final List<WordSense> definitions;
  final List<WordExample> examples;
  final String? errorMessage;
}

class WordBasicSummary {
  const WordBasicSummary({
    this.headword,
    this.pronunciationUs,
    this.pronunciationUk,
    this.audioUs,
    this.audioUk,
    this.frequency,
  });

  final String? headword;
  final String? pronunciationUs;
  final String? pronunciationUk;
  final String? audioUs;
  final String? audioUk;
  final String? frequency;

  @override
  bool operator ==(Object other) {
    return other is WordBasicSummary &&
        other.headword == headword &&
        other.pronunciationUs == pronunciationUs &&
        other.pronunciationUk == pronunciationUk &&
        other.audioUs == audioUs &&
        other.audioUk == audioUk &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => Object.hash(
    headword,
    pronunciationUs,
    pronunciationUk,
    audioUs,
    audioUk,
    frequency,
  );
}

class WordSense {
  const WordSense({
    required this.partOfSpeech,
    required this.definitionZh,
  });

  final String partOfSpeech;
  final String definitionZh;

  @override
  bool operator ==(Object other) {
    return other is WordSense &&
        other.partOfSpeech == partOfSpeech &&
        other.definitionZh == definitionZh;
  }

  @override
  int get hashCode => Object.hash(partOfSpeech, definitionZh);
}

class WordExample {
  const WordExample({
    required this.english,
    this.englishAudio,
    required this.translationZh,
    this.translationAudio,
  });

  final String english;
  final String? englishAudio;
  final String translationZh;
  final String? translationAudio;

  @override
  bool operator ==(Object other) {
    return other is WordExample &&
        other.english == english &&
        other.englishAudio == englishAudio &&
        other.translationZh == translationZh &&
        other.translationAudio == translationAudio;
  }

  @override
  int get hashCode => Object.hash(
    english,
    englishAudio,
    translationZh,
    translationAudio,
  );
}
