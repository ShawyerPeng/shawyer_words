import 'package:sqflite/sqlite_api.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';

class LexDbWordLookupRepository implements WordLookupRepository {
  LexDbWordLookupRepository({
    required this.databasePath,
    required this.databaseFactory,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;

  Database? _database;
  Map<String, WordEntry> _cachedEntriesById = const <String, WordEntry>{};

  @override
  WordEntry? findById(String id) {
    return _cachedEntriesById[id];
  }

  @override
  Future<List<WordEntry>> searchWords(String query, {int limit = 20}) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty || limit <= 0) {
      return const <WordEntry>[];
    }

    final database = await _openDatabase();
    final exactRows = await database.query(
      'entries',
      columns: <String>['id', 'headword'],
      where: 'headword_lower = ?',
      whereArgs: <Object?>[normalizedQuery],
      orderBy: 'id',
      limit: limit,
    );

    final remaining = limit - exactRows.length;
    final prefixRows = remaining <= 0
        ? const <Map<String, Object?>>[]
        : await database.query(
            'entries',
            columns: <String>['id', 'headword'],
            where: 'headword_lower LIKE ? AND headword_lower != ?',
            whereArgs: <Object?>['$normalizedQuery%', normalizedQuery],
            orderBy: 'headword_lower, id',
            limit: remaining,
          );

    final entries = <WordEntry>[
      ...exactRows.map(_mapRow),
      ...prefixRows.map(_mapRow),
    ];
    _cachedEntriesById = <String, WordEntry>{
      for (final entry in entries) entry.id: entry,
    };
    return entries;
  }

  Future<Database> _openDatabase() async {
    final cached = _database;
    if (cached != null && cached.isOpen) {
      return cached;
    }
    _database = await databaseFactory.openDatabase(databasePath);
    return _database!;
  }

  WordEntry _mapRow(Map<String, Object?> row) {
    final entryId = row['id'] as int;
    return WordEntry(
      id: 'lexdb:$entryId',
      word: row['headword'] as String,
      rawContent: '',
    );
  }
}
