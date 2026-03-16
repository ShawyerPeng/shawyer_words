import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shawyer_words/features/word_detail/data/sqlite_word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

void main() {
  group('SqliteWordKnowledgeRepository', () {
    late Directory tempDirectory;
    late SqliteWordKnowledgeRepository repository;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'word-knowledge-test-',
      );
      repository = SqliteWordKnowledgeRepository(
        databasePath: '${tempDirectory.path}/knowledge.db',
        databaseFactory: databaseFactoryFfiNoIsolate,
      );
    });

    tearDown(() async {
      await repository.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('returns null when a word has not been stored', () async {
      final record = await repository.getByWord('abandon');

      expect(record, isNull);
    });

    test('saves and reloads a full record', () async {
      final expected = WordKnowledgeRecord(
        word: ' Abandon ',
        isFavorite: true,
        isKnown: true,
        note: 'Often followed by plan',
        skipKnownConfirm: true,
        updatedAt: DateTime.parse('2026-03-16T10:00:00.000Z'),
      );

      await repository.save(expected);

      final actual = await repository.getByWord('ABANDON');

      expect(actual?.toMap(), expected.toMap());
    });

    test('toggleFavorite flips the favorite bit', () async {
      await repository.toggleFavorite('abandon');
      expect((await repository.getByWord('abandon'))?.isFavorite, isTrue);

      await repository.toggleFavorite('abandon');
      expect((await repository.getByWord('abandon'))?.isFavorite, isFalse);
    });

    test('markKnown updates known and skip-confirm flags', () async {
      await repository.markKnown('abandon', skipConfirmNextTime: true);

      final record = await repository.getByWord('abandon');
      expect(record?.isKnown, isTrue);
      expect(record?.skipKnownConfirm, isTrue);
    });

    test('saveNote preserves empty and non-empty note values', () async {
      await repository.saveNote('abandon', 'Common in reading passages');
      expect(
        (await repository.getByWord('abandon'))?.note,
        'Common in reading passages',
      );

      await repository.saveNote('abandon', '   ');
      expect((await repository.getByWord('abandon'))?.note, isEmpty);
    });
  });
}
