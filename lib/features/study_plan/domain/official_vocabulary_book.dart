import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class OfficialVocabularyBook {
  const OfficialVocabularyBook({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.wordCount,
    required this.coverKey,
    required this.entries,
  });

  final String id;
  final String category;
  final String title;
  final String subtitle;
  final int wordCount;
  final String coverKey;
  final List<WordEntry> entries;
}
