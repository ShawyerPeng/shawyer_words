import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

abstract class WordLookupRepository {
  List<WordEntry> searchWords(String query, {int limit = 20});

  WordEntry? findById(String id);
}
