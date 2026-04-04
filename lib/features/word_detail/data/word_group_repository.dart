import 'package:sqflite/sqlite_api.dart';

class WordGroupRepository {
  WordGroupRepository({
    required this.databasePath,
    required this.databaseFactory,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;

  Database? _database;

  Future<(List<String>, List<String>)> lookupSimilarWords(String word) async {
    final normalized = word.trim().toLowerCase();
    if (normalized.isEmpty) {
      return (const <String>[], const <String>[]);
    }
    final database = await _openDatabase();
    final spelling = await _lookupByType(
      database: database,
      word: normalized,
      groupType: 'similar_spelling',
    );
    final sound = await _lookupByType(
      database: database,
      word: normalized,
      groupType: 'similar_sound',
    );
    return (spelling, sound);
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

  Future<List<String>> _lookupByType({
    required Database database,
    required String word,
    required String groupType,
  }) async {
    try {
      final rows = await database.rawQuery(
        '''
        SELECT wgm2.word AS word
        FROM word_group_members wgm1
        JOIN word_groups wg
          ON wg.id = wgm1.group_id
        JOIN word_group_members wgm2
          ON wgm2.group_id = wg.id
        WHERE lower(wgm1.word) = ?
          AND wg.group_type = ?
        ORDER BY wg.id, wgm2.sort_order, wgm2.word
        ''',
        <Object?>[word, groupType],
      );
      final values = <String>[];
      final dedupe = <String>{};
      for (final row in rows) {
        final raw = '${row['word'] ?? ''}'.trim();
        if (raw.isEmpty) {
          continue;
        }
        final lowered = raw.toLowerCase();
        if (lowered == word || !dedupe.add(lowered)) {
          continue;
        }
        values.add(raw);
      }
      return values;
    } on DatabaseException {
      return const <String>[];
    }
  }
}
