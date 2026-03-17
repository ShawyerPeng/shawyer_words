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
    this.sourceUrl,
  });

  final String id;
  final String category;
  final String title;
  final String subtitle;
  final int wordCount;
  final String coverKey;
  final List<WordEntry> entries;
  final String? sourceUrl;

  bool get isRemote => sourceUrl != null;

  OfficialVocabularyBook copyWith({
    String? id,
    String? category,
    String? title,
    String? subtitle,
    int? wordCount,
    String? coverKey,
    List<WordEntry>? entries,
    Object? sourceUrl = _sentinel,
  }) {
    return OfficialVocabularyBook(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      wordCount: wordCount ?? this.wordCount,
      coverKey: coverKey ?? this.coverKey,
      entries: entries ?? this.entries,
      sourceUrl: identical(sourceUrl, _sentinel)
          ? this.sourceUrl
          : sourceUrl as String?,
    );
  }

  static const Object _sentinel = Object();
}
