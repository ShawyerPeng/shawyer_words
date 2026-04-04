import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

abstract class SearchHistoryRepository {
  Future<List<WordEntry>> loadHistory();

  Future<void> saveEntry(WordEntry entry, {int limit = 10});

  Future<void> clear();
}
