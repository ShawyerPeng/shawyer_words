import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

abstract class SearchHistoryRepository {
  List<WordEntry> loadHistory();

  void saveEntry(WordEntry entry, {int limit = 10});

  void clear();
}
