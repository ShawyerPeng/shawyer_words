import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqlite_api.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

class SqliteWordKnowledgeRepository implements WordKnowledgeRepository {
  SqliteWordKnowledgeRepository({
    this.databasePath,
    Future<String> Function()? databasePathResolver,
    DatabaseFactory? databaseFactory,
  }) : _databasePathResolver = databasePathResolver,
       _databaseFactory = databaseFactory;

  static const String _tableName = 'word_knowledge';

  final String? databasePath;
  final Future<String> Function()? _databasePathResolver;
  final DatabaseFactory? _databaseFactory;

  Database? _database;

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async {
    final database = await _openDatabase();
    final rows = await database.query(
      _tableName,
      where: 'word = ?',
      whereArgs: <Object?>[WordKnowledgeRecord.normalizeWord(word)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return WordKnowledgeRecord.fromMap(rows.first);
  }

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async {
    final database = await _openDatabase();
    final rows = await database.query(_tableName, orderBy: 'updated_at DESC');
    return rows
        .map((row) => WordKnowledgeRecord.fromMap(row))
        .toList(growable: false);
  }

  @override
  Future<void> save(WordKnowledgeRecord record) async {
    final database = await _openDatabase();
    await database.insert(
      _tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> toggleFavorite(String word) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    await save(
      WordKnowledgeRecord(
        word: current.word,
        isFavorite: !current.isFavorite,
        isKnown: current.isKnown,
        note: current.note,
        skipKnownConfirm: current.skipKnownConfirm,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    await save(
      WordKnowledgeRecord(
        word: current.word,
        isFavorite: current.isFavorite,
        isKnown: true,
        note: current.note,
        skipKnownConfirm: skipConfirmNextTime,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> saveNote(String word, String note) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    await save(
      WordKnowledgeRecord(
        word: current.word,
        isFavorite: current.isFavorite,
        isKnown: current.isKnown,
        note: note,
        skipKnownConfirm: current.skipKnownConfirm,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> clearAll() async {
    final database = await _openDatabase();
    await database.delete(_tableName);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _openDatabase() async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final database = await (_databaseFactory ?? sqflite.databaseFactory)
        .openDatabase(
          await _resolveDatabasePath(),
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await _ensureTable(db);
            },
            onOpen: (db) async {
              await _ensureTable(db);
            },
          ),
        );
    _database = database;
    return database;
  }

  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        word TEXT PRIMARY KEY,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_known INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        skip_known_confirm INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<String> _resolveDatabasePath() async {
    if (databasePath != null) {
      return databasePath!;
    }
    if (_databasePathResolver != null) {
      return _databasePathResolver();
    }
    throw StateError('A database path or resolver is required.');
  }
}
