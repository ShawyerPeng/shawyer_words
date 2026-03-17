import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shawyer_words/features/search/data/lexdb_word_lookup_repository.dart';

void main() {
  group('LexDbWordLookupRepository', () {
    late Directory tempDirectory;
    late String databasePath;
    late DatabaseFactory databaseFactory;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'lexdb-search-test-',
      );
      databasePath = '${tempDirectory.path}/lexdb.db';
      databaseFactory = databaseFactoryFfiNoIsolate;
      final database = await databaseFactory.openDatabase(databasePath);
      await database.execute('''
        CREATE TABLE entries (
          id INTEGER PRIMARY KEY,
          dict_id TEXT NOT NULL,
          headword TEXT NOT NULL,
          headword_lower TEXT NOT NULL,
          headword_display TEXT
        )
      ''');
      await database.insert('entries', <String, Object?>{
        'id': 1,
        'dict_id': 'ldoce',
        'headword': 'abandon',
        'headword_lower': 'abandon',
        'headword_display': 'a·ban·don',
      });
      await database.insert('entries', <String, Object?>{
        'id': 2,
        'dict_id': 'ldoce',
        'headword': 'abandonment',
        'headword_lower': 'abandonment',
        'headword_display': 'a·ban·don·ment',
      });
      await database.insert('entries', <String, Object?>{
        'id': 3,
        'dict_id': 'ldoce',
        'headword': 'ability',
        'headword_lower': 'ability',
        'headword_display': 'a·bil·i·ty',
      });
      await database.close();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'returns exact matches before prefix matches and normalizes case',
      () async {
        final repository = LexDbWordLookupRepository(
          databasePath: databasePath,
          databaseFactory: databaseFactory,
        );

        final results = await repository.searchWords('Abandon');

        expect(results.map((entry) => entry.id), <String>[
          'lexdb:1',
          'lexdb:2',
        ]);
        expect(results.map((entry) => entry.word), <String>[
          'abandon',
          'abandonment',
        ]);
      },
    );

    test('findById restores a searched lexdb entry', () async {
      final repository = LexDbWordLookupRepository(
        databasePath: databasePath,
        databaseFactory: databaseFactory,
      );

      await repository.searchWords('ab');
      final entry = repository.findById('lexdb:2');

      expect(entry, isNotNull);
      expect(entry?.word, 'abandonment');
    });
  });
}
