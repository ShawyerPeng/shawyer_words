import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class DictionaryImportResult {
  const DictionaryImportResult({
    required this.package,
    required this.dictionary,
    required this.entries,
  });

  final DictionaryPackage package;
  final DictionarySummary dictionary;
  final List<WordEntry> entries;
}
