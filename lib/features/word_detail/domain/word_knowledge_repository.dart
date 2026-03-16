import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

abstract class WordKnowledgeRepository {
  Future<WordKnowledgeRecord?> getByWord(String word);

  Future<void> save(WordKnowledgeRecord record);

  Future<void> toggleFavorite(String word);

  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  });

  Future<void> saveNote(String word, String note);
}
