import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shawyer_words/features/word_detail/data/lexdb_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';

void main() {
  group('LexDbWordDetailRepository', () {
    late Directory tempDirectory;
    late String databasePath;
    late DatabaseFactory databaseFactory;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('lexdb-test-');
      databasePath = '${tempDirectory.path}/lexdb.db';
      databaseFactory = databaseFactoryFfiNoIsolate;
      final database = await databaseFactory.openDatabase(databasePath);
      await _createSchema(database);
      await _seedLexDb(database);
      await database.close();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('builds structured lexdb entry details from schema tables', () async {
      final repository = LexDbWordDetailRepository(
        databasePath: databasePath,
        dictionaryId: 'ldoce',
        dictionaryName: 'Longman',
        databaseFactory: databaseFactory,
      );

      final results = await repository.lookup('Abandon');

      expect(results, hasLength(1));
      final entry = results.single;
      expect(entry.dictionaryId, 'ldoce');
      expect(entry.dictionaryName, 'Longman');
      expect(entry.headword, 'abandon');
      expect(entry.headwordDisplay, 'a·ban·don');
      expect(entry.entryLabels, const <LexDbLabel>[
        LexDbLabel(type: 'pos', value: 'verb'),
        LexDbLabel(type: 'frequency', value: 'S1'),
      ]);
      expect(
        entry.entryAttributes['ldoce/thesaurus'],
        contains('"word":"leave"'),
      );
      expect(entry.relations, const <LexDbRelation>[
        LexDbRelation(
          relationType: 'synonym',
          clickable: 'quit',
          targetWord: 'quit',
        ),
        LexDbRelation(
          relationType: 'synonym',
          clickable: 'desert',
          targetWord: 'desert',
        ),
      ]);
      expect(entry.pronunciations, const <LexDbPronunciation>[
        LexDbPronunciation(
          variant: 'uk',
          phonetic: '/əˈbændən/',
          audioPath: 'audio/uk/abandon.mp3',
        ),
        LexDbPronunciation(
          variant: 'us',
          phonetic: '/əˈbændən/',
          audioPath: 'audio/us/abandon.mp3',
        ),
      ]);
      expect(entry.senses, hasLength(1));
      final sense = entry.senses.single;
      expect(sense.id, 10);
      expect(sense.number, '1');
      expect(sense.signpost, 'LEAVE');
      expect(sense.definition, 'to leave a place, thing, or person');
      expect(sense.definitionZh, '离弃；抛弃');
      expect(sense.labels, const <LexDbLabel>[
        LexDbLabel(type: 'register', value: 'formal'),
      ]);
      expect(sense.examplesBeforePatterns, const <LexDbExample>[
        LexDbExample(
          text: 'He abandoned the car.',
          textZh: '他弃车而去。',
          audioPath: 'audio/examples/abandon-1.mp3',
        ),
      ]);
      expect(sense.grammarPatterns, const <LexDbGrammarPattern>[
        LexDbGrammarPattern(
          pattern: 'abandon somebody/something',
          gloss: 'to stop supporting',
          examples: <LexDbExample>[
            LexDbExample(
              text: 'Do not abandon your family.',
              audioPath: 'audio/examples/abandon-pattern.mp3',
            ),
          ],
        ),
      ]);
      expect(sense.examplesAfterPatterns, const <LexDbExample>[
        LexDbExample(text: 'The match was abandoned.', textZh: '比赛被中止了。'),
      ]);
      expect(entry.collocations, const <LexDbCollocation>[
        LexDbCollocation(
          collocate: 'abandon hope',
          grammar: 'VERBS',
          definition: 'to stop hoping completely',
          examples: <LexDbExample>[
            LexDbExample(text: 'The doctors never abandoned hope.'),
          ],
        ),
      ]);
    });

    test('provides reusable batch brief definitions lookup', () async {
      final repository = LexDbWordDetailRepository(
        databasePath: databasePath,
        dictionaryId: 'ldoce',
        dictionaryName: 'Longman',
        databaseFactory: databaseFactory,
      );

      final definitions = await repository.lookupBriefDefinitions(
        const <String>['Abandon', 'abandonment', 'englishOnly', 'missing'],
      );

      expect(definitions['abandon'], '放弃');
      expect(definitions['abandonment'], '放弃');
      expect(definitions['englishonly'], 'to stop supporting someone');
      expect(definitions.containsKey('missing'), isFalse);
    });
  });
}

Future<void> _createSchema(Database database) async {
  await database.execute('''
    CREATE TABLE entries (
      id INTEGER PRIMARY KEY,
      dict_id TEXT NOT NULL,
      headword TEXT NOT NULL,
      headword_lower TEXT NOT NULL,
      headword_display TEXT
    )
  ''');
  await database.execute('''
    CREATE TABLE pronunciations (
      id INTEGER PRIMARY KEY,
      entry_id INTEGER NOT NULL,
      variant TEXT,
      ipa TEXT,
      audio_path TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE labels (
      id INTEGER PRIMARY KEY,
      entry_id INTEGER,
      sense_id INTEGER,
      label_type TEXT NOT NULL,
      label_value TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE entry_attributes (
      id INTEGER PRIMARY KEY,
      entry_id INTEGER NOT NULL,
      attr_key TEXT NOT NULL,
      attr_value BLOB
    )
  ''');
  await database.execute('''
    CREATE TABLE relations (
      id INTEGER PRIMARY KEY,
      entry_id INTEGER NOT NULL,
      sense_id INTEGER,
      relation_type TEXT NOT NULL,
      prefix TEXT,
      clickable TEXT NOT NULL,
      suffix TEXT,
      target_word TEXT NOT NULL,
      target_sense TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE senses (
      id INTEGER PRIMARY KEY,
      entry_id INTEGER NOT NULL,
      sense_number TEXT,
      signpost TEXT,
      plural TEXT,
      definition TEXT NOT NULL,
      definition_zh TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE examples (
      id INTEGER PRIMARY KEY,
      sense_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      text_zh TEXT,
      audio_path TEXT,
      position INTEGER DEFAULT 0,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE grammar_patterns (
      id INTEGER PRIMARY KEY,
      sense_id INTEGER NOT NULL,
      pattern TEXT NOT NULL,
      gloss TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE grammar_examples (
      id INTEGER PRIMARY KEY,
      pattern_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      audio_path TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE collocations (
      id INTEGER PRIMARY KEY,
      entry_id INTEGER NOT NULL,
      category TEXT,
      text TEXT NOT NULL,
      gloss TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await database.execute('''
    CREATE TABLE collocation_examples (
      id INTEGER PRIMARY KEY,
      collocation_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0
    )
  ''');
}

Future<void> _seedLexDb(Database database) async {
  await database.insert('entries', <String, Object?>{
    'id': 1,
    'dict_id': 'ldoce',
    'headword': 'abandon',
    'headword_lower': 'abandon',
    'headword_display': 'a·ban·don',
  });
  await database.insert('pronunciations', <String, Object?>{
    'id': 1,
    'entry_id': 1,
    'variant': 'uk',
    'ipa': '/əˈbændən/',
    'audio_path': 'audio/uk/abandon.mp3',
    'sort_order': 0,
  });
  await database.insert('pronunciations', <String, Object?>{
    'id': 2,
    'entry_id': 1,
    'variant': 'us',
    'ipa': '/əˈbændən/',
    'audio_path': 'audio/us/abandon.mp3',
    'sort_order': 1,
  });
  await database.insert('labels', <String, Object?>{
    'id': 1,
    'entry_id': 1,
    'sense_id': null,
    'label_type': 'pos',
    'label_value': 'verb',
    'sort_order': 0,
  });
  await database.insert('labels', <String, Object?>{
    'id': 2,
    'entry_id': 1,
    'sense_id': null,
    'label_type': 'frequency',
    'label_value': 'S1',
    'sort_order': 1,
  });
  await database.insert('entry_attributes', <String, Object?>{
    'id': 1,
    'entry_id': 1,
    'attr_key': 'ldoce/thesaurus',
    'attr_value':
        '[{"header":"THESAURUS","section":"","items":[{"word":"leave","definition":"to go away"}]}]',
  });
  await database.insert('entry_attributes', <String, Object?>{
    'id': 2,
    'entry_id': 1,
    'attr_key': 'tld/sense_ratio_cn',
    'attr_value':
        '[{"meaning":"放弃","percent":76},{"meaning":"离弃","percent":24}]',
  });
  await database.insert('relations', <String, Object?>{
    'id': 1,
    'entry_id': 1,
    'relation_type': 'synonym',
    'clickable': 'quit',
    'target_word': 'quit',
    'sort_order': 0,
  });
  await database.insert('relations', <String, Object?>{
    'id': 2,
    'entry_id': 1,
    'relation_type': 'synonym',
    'clickable': 'desert',
    'target_word': 'desert',
    'sort_order': 1,
  });
  await database.insert('senses', <String, Object?>{
    'id': 10,
    'entry_id': 1,
    'sense_number': '1',
    'signpost': 'LEAVE',
    'definition': 'to leave a place, thing, or person',
    'definition_zh': '离弃；抛弃',
    'sort_order': 0,
  });
  await database.insert('entries', <String, Object?>{
    'id': 2,
    'dict_id': 'ldoce',
    'headword': 'abandonment',
    'headword_lower': 'abandonment',
    'headword_display': 'a·ban·don·ment',
  });
  await database.insert('senses', <String, Object?>{
    'id': 20,
    'entry_id': 2,
    'sense_number': '1',
    'signpost': 'STATE',
    'definition': 'the act of leaving behind completely',
    'definition_zh': '放弃，离弃（名词）',
    'sort_order': 0,
  });
  await database.insert('entries', <String, Object?>{
    'id': 3,
    'dict_id': 'ldoce',
    'headword': 'englishOnly',
    'headword_lower': 'englishonly',
    'headword_display': 'eng·lish·only',
  });
  await database.insert('senses', <String, Object?>{
    'id': 30,
    'entry_id': 3,
    'sense_number': '1',
    'definition': 'to stop supporting someone; to leave',
    'definition_zh': null,
    'sort_order': 0,
  });
  await database.insert('labels', <String, Object?>{
    'id': 3,
    'entry_id': null,
    'sense_id': 10,
    'label_type': 'register',
    'label_value': 'formal',
    'sort_order': 0,
  });
  await database.insert('examples', <String, Object?>{
    'id': 1,
    'sense_id': 10,
    'text': 'He abandoned the car.',
    'text_zh': '他弃车而去。',
    'audio_path': 'audio/examples/abandon-1.mp3',
    'position': 0,
    'sort_order': 0,
  });
  await database.insert('grammar_patterns', <String, Object?>{
    'id': 20,
    'sense_id': 10,
    'pattern': 'abandon somebody/something',
    'gloss': 'to stop supporting',
    'sort_order': 0,
  });
  await database.insert('grammar_examples', <String, Object?>{
    'id': 21,
    'pattern_id': 20,
    'text': 'Do not abandon your family.',
    'audio_path': 'audio/examples/abandon-pattern.mp3',
    'sort_order': 0,
  });
  await database.insert('examples', <String, Object?>{
    'id': 2,
    'sense_id': 10,
    'text': 'The match was abandoned.',
    'text_zh': '比赛被中止了。',
    'position': 1,
    'sort_order': 0,
  });
  await database.insert('collocations', <String, Object?>{
    'id': 30,
    'entry_id': 1,
    'category': 'VERBS',
    'text': 'abandon hope',
    'gloss': 'to stop hoping completely',
    'sort_order': 0,
  });
  await database.insert('collocation_examples', <String, Object?>{
    'id': 31,
    'collocation_id': 30,
    'text': 'The doctors never abandoned hope.',
    'sort_order': 0,
  });
}
