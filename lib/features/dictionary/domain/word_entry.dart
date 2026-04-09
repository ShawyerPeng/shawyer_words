class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
    this.pronunciation,
    this.partOfSpeech,
    this.definition,
    this.exampleSentence,
    this.exampleAudioPath,
    required this.rawContent,
  });

  final String id;
  final String word;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? definition;
  final String? exampleSentence;
  final String? exampleAudioPath;
  final String rawContent;
}
