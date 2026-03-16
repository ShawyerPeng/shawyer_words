import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';

class WordDetail {
  const WordDetail({
    required this.word,
    this.basic = const WordBasicSummary(),
    this.definitions = const <WordSense>[],
    this.examples = const <WordExample>[],
    this.dictionaryPanels = const <DictionaryEntryDetail>[],
  });

  final String word;
  final WordBasicSummary basic;
  final List<WordSense> definitions;
  final List<WordExample> examples;
  final List<DictionaryEntryDetail> dictionaryPanels;
}
