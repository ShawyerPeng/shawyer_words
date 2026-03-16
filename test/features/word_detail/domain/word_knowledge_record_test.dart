import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

void main() {
  group('WordKnowledgeRecord', () {
    test('creates stable defaults for a word', () {
      final record = WordKnowledgeRecord.initial(' Abandon ');

      expect(record.word, 'abandon');
      expect(record.isFavorite, isFalse);
      expect(record.isKnown, isFalse);
      expect(record.note, isEmpty);
      expect(record.skipKnownConfirm, isFalse);
    });

    test('normalizes persistence values from a database row', () {
      final record = WordKnowledgeRecord.fromMap(<String, Object?>{
        'word': '  ABANDON ',
        'is_favorite': 1,
        'is_known': 0,
        'note': null,
        'skip_known_confirm': true,
        'updated_at': '2026-03-16T08:00:00.000Z',
      });

      expect(record.word, 'abandon');
      expect(record.isFavorite, isTrue);
      expect(record.isKnown, isFalse);
      expect(record.note, isEmpty);
      expect(record.skipKnownConfirm, isTrue);
      expect(record.updatedAt.toUtc(), DateTime.parse('2026-03-16T08:00:00.000Z'));
    });

    test('serializes booleans to integer flags', () {
      final updatedAt = DateTime.parse('2026-03-16T09:30:00.000Z');
      final record = WordKnowledgeRecord(
        word: 'Abandon',
        isFavorite: true,
        isKnown: true,
        note: 'Common in test data',
        skipKnownConfirm: false,
        updatedAt: updatedAt,
      );

      expect(record.toMap(), <String, Object?>{
        'word': 'abandon',
        'is_favorite': 1,
        'is_known': 1,
        'note': 'Common in test data',
        'skip_known_confirm': 0,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      });
    });
  });
}
