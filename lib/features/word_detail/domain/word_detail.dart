import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';

class WordDetail {
  const WordDetail({
    required this.word,
    this.basic = const WordBasicSummary(),
    this.definitions = const <WordSense>[],
    this.examples = const <WordExample>[],
    this.lexDbEntries = const <LexDbEntryDetail>[],
    this.dictionaryPanels = const <DictionaryEntryDetail>[],
    this.similarSpellingWords = const <String>[],
    this.similarSoundWords = const <String>[],
    this.wordFamilyBriefDefinitions = const <String, String>{},
  });

  final String word;
  final WordBasicSummary basic;
  final List<WordSense> definitions;
  final List<WordExample> examples;
  final List<LexDbEntryDetail> lexDbEntries;
  final List<DictionaryEntryDetail> dictionaryPanels;
  final List<String> similarSpellingWords;
  final List<String> similarSoundWords;
  final Map<String, String> wordFamilyBriefDefinitions;
}
