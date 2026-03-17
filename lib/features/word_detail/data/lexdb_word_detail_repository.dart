import 'package:sqflite/sqlite_api.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';

class LexDbWordDetailRepository {
  LexDbWordDetailRepository({
    required this.databasePath,
    required this.dictionaryId,
    required this.dictionaryName,
    required this.databaseFactory,
  });

  final String databasePath;
  final String dictionaryId;
  final String dictionaryName;
  final DatabaseFactory databaseFactory;

  Database? _database;

  Future<List<LexDbEntryDetail>> lookup(String word) async {
    final normalizedWord = word.trim().toLowerCase();
    if (normalizedWord.isEmpty) {
      return const <LexDbEntryDetail>[];
    }

    final database = await _openDatabase();
    final entryRows = await database.query(
      'entries',
      columns: <String>['id', 'headword', 'headword_display'],
      where: 'headword_lower = ?',
      whereArgs: <Object?>[normalizedWord],
      orderBy: 'id',
    );

    final results = <LexDbEntryDetail>[];
    for (final row in entryRows) {
      final entryId = row['id'] as int;
      results.add(
        LexDbEntryDetail(
          dictionaryId: dictionaryId,
          dictionaryName: dictionaryName,
          headword: row['headword'] as String,
          headwordDisplay: row['headword_display'] as String?,
          pronunciations: await _loadPronunciations(database, entryId),
          entryLabels: await _loadLabels(
            database,
            where: 'entry_id = ? AND sense_id IS NULL',
            whereArgs: <Object?>[entryId],
          ),
          senses: await _loadSenses(database, entryId),
          collocations: await _loadCollocations(database, entryId),
        ),
      );
    }
    return results;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _openDatabase() async {
    final cached = _database;
    if (cached != null && cached.isOpen) {
      return cached;
    }
    _database = await databaseFactory.openDatabase(databasePath);
    return _database!;
  }

  Future<List<LexDbPronunciation>> _loadPronunciations(
    Database database,
    int entryId,
  ) async {
    final rows = await database.query(
      'pronunciations',
      columns: <String>['variant', 'ipa', 'audio_path'],
      where: 'entry_id = ?',
      whereArgs: <Object?>[entryId],
      orderBy: 'sort_order, id',
    );
    return rows
        .map(
          (row) => LexDbPronunciation(
            variant: (row['variant'] as String?) ?? '',
            phonetic: row['ipa'] as String?,
            audioPath: row['audio_path'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<LexDbLabel>> _loadLabels(
    Database database, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final rows = await database.query(
      'labels',
      columns: <String>['label_type', 'label_value'],
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sort_order, id',
    );
    return rows
        .map(
          (row) => LexDbLabel(
            type: row['label_type'] as String,
            value: row['label_value'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<LexDbSense>> _loadSenses(Database database, int entryId) async {
    final rows = await database.query(
      'senses',
      columns: <String>[
        'id',
        'sense_number',
        'signpost',
        'definition',
        'definition_zh',
      ],
      where: 'entry_id = ?',
      whereArgs: <Object?>[entryId],
      orderBy: 'sort_order, id',
    );
    final senses = <LexDbSense>[];
    for (final row in rows) {
      final senseId = row['id'] as int;
      final examples = await _loadExamples(database, senseId);
      senses.add(
        LexDbSense(
          id: senseId,
          number: row['sense_number'] as String?,
          signpost: row['signpost'] as String?,
          definition: row['definition'] as String,
          definitionZh: row['definition_zh'] as String?,
          labels: await _loadLabels(
            database,
            where: 'sense_id = ?',
            whereArgs: <Object?>[senseId],
          ),
          examplesBeforePatterns: examples.$1,
          grammarPatterns: await _loadGrammarPatterns(database, senseId),
          examplesAfterPatterns: examples.$2,
        ),
      );
    }
    return senses;
  }

  Future<(List<LexDbExample>, List<LexDbExample>)> _loadExamples(
    Database database,
    int senseId,
  ) async {
    final rows = await database.query(
      'examples',
      columns: <String>['text', 'text_zh', 'audio_path', 'position'],
      where: 'sense_id = ?',
      whereArgs: <Object?>[senseId],
      orderBy: 'position, sort_order, id',
    );
    final before = <LexDbExample>[];
    final after = <LexDbExample>[];
    for (final row in rows) {
      final example = LexDbExample(
        text: row['text'] as String,
        textZh: row['text_zh'] as String?,
        audioPath: row['audio_path'] as String?,
      );
      if ((row['position'] as int? ?? 0) == 0) {
        before.add(example);
      } else {
        after.add(example);
      }
    }
    return (before, after);
  }

  Future<List<LexDbGrammarPattern>> _loadGrammarPatterns(
    Database database,
    int senseId,
  ) async {
    final rows = await database.query(
      'grammar_patterns',
      columns: <String>['id', 'pattern', 'gloss'],
      where: 'sense_id = ?',
      whereArgs: <Object?>[senseId],
      orderBy: 'sort_order, id',
    );
    final patterns = <LexDbGrammarPattern>[];
    for (final row in rows) {
      final patternId = row['id'] as int;
      final exampleRows = await database.query(
        'grammar_examples',
        columns: <String>['text', 'audio_path'],
        where: 'pattern_id = ?',
        whereArgs: <Object?>[patternId],
        orderBy: 'sort_order, id',
      );
      patterns.add(
        LexDbGrammarPattern(
          pattern: row['pattern'] as String,
          gloss: row['gloss'] as String?,
          examples: exampleRows
              .map(
                (exampleRow) => LexDbExample(
                  text: exampleRow['text'] as String,
                  audioPath: exampleRow['audio_path'] as String?,
                ),
              )
              .toList(growable: false),
        ),
      );
    }
    return patterns;
  }

  Future<List<LexDbCollocation>> _loadCollocations(
    Database database,
    int entryId,
  ) async {
    final rows = await database.query(
      'collocations',
      columns: <String>['id', 'category', 'text', 'gloss'],
      where: 'entry_id = ?',
      whereArgs: <Object?>[entryId],
      orderBy: 'sort_order, id',
    );
    final collocations = <LexDbCollocation>[];
    for (final row in rows) {
      final collocationId = row['id'] as int;
      final exampleRows = await database.query(
        'collocation_examples',
        columns: <String>['text'],
        where: 'collocation_id = ?',
        whereArgs: <Object?>[collocationId],
        orderBy: 'sort_order, id',
      );
      collocations.add(
        LexDbCollocation(
          collocate: row['text'] as String,
          grammar: row['category'] as String?,
          definition: row['gloss'] as String?,
          examples: exampleRows
              .map(
                (exampleRow) =>
                    LexDbExample(text: exampleRow['text'] as String),
              )
              .toList(growable: false),
        ),
      );
    }
    return collocations;
  }
}
