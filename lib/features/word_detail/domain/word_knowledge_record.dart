class WordKnowledgeRecord {
  WordKnowledgeRecord({
    required String word,
    required this.isFavorite,
    required this.isKnown,
    required String note,
    required this.skipKnownConfirm,
    required this.updatedAt,
  }) : word = normalizeWord(word),
       note = note.trim();

  factory WordKnowledgeRecord.initial(String word) {
    return WordKnowledgeRecord(
      word: word,
      isFavorite: false,
      isKnown: false,
      note: '',
      skipKnownConfirm: false,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  factory WordKnowledgeRecord.fromMap(Map<String, Object?> map) {
    return WordKnowledgeRecord(
      word: map['word'] as String? ?? '',
      isFavorite: _readBool(map['is_favorite']),
      isKnown: _readBool(map['is_known']),
      note: map['note'] as String? ?? '',
      skipKnownConfirm: _readBool(map['skip_known_confirm']),
      updatedAt: DateTime.parse(
        map['updated_at'] as String? ?? DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String(),
      ).toUtc(),
    );
  }

  final String word;
  final bool isFavorite;
  final bool isKnown;
  final String note;
  final bool skipKnownConfirm;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'word': word,
      'is_favorite': isFavorite ? 1 : 0,
      'is_known': isKnown ? 1 : 0,
      'note': note,
      'skip_known_confirm': skipKnownConfirm ? 1 : 0,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static String normalizeWord(String word) {
    return word.trim().toLowerCase();
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}
