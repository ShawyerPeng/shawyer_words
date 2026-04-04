import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqlite_api.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

class SqliteFsrsRepository implements FsrsRepository {
  SqliteFsrsRepository({
    this.databasePath,
    Future<String> Function()? databasePathResolver,
    DatabaseFactory? databaseFactory,
  }) : _databasePathResolver = databasePathResolver,
       _databaseFactory = databaseFactory;

  static const String _cardTable = 'fsrs_cards';
  static const String _logTable = 'fsrs_review_logs';

  final String? databasePath;
  final Future<String> Function()? _databasePathResolver;
  final DatabaseFactory? _databaseFactory;

  Database? _database;

  @override
  Future<FsrsCard?> getByWord(String word) async {
    final db = await _openDatabase();
    final rows = await db.query(
      _cardTable,
      where: 'word = ?',
      whereArgs: <Object?>[WordKnowledgeRecord.normalizeWord(word)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _cardFromRow(rows.first);
  }

  @override
  Future<List<FsrsCard>> loadAll() async {
    final db = await _openDatabase();
    final rows = await db.query(_cardTable, orderBy: 'due ASC');
    return rows.map(_cardFromRow).toList(growable: false);
  }

  @override
  Future<void> saveCard(FsrsCard card) async {
    final db = await _openDatabase();
    await db.insert(
      _cardTable,
      _cardToRow(card),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> addReviewLog(FsrsReviewLog log) async {
    final db = await _openDatabase();
    await db.insert(_logTable, _logToRow(log));
  }

  @override
  Future<void> saveReview(FsrsRecordLogItem item) async {
    final db = await _openDatabase();
    await db.transaction((txn) async {
      await txn.insert(
        _cardTable,
        _cardToRow(item.card),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(_logTable, _logToRow(item.log));
    });
  }

  @override
  Future<Map<String, FsrsReviewLog>> loadLatestReviewLogsByWord() async {
    final db = await _openDatabase();
    final rows = await db.query(
      _logTable,
      orderBy: 'word ASC, reviewed_at DESC, id DESC',
    );
    final latestLogs = <String, FsrsReviewLog>{};
    for (final row in rows) {
      final word = (row['word'] as String?) ?? '';
      if (latestLogs.containsKey(word)) {
        continue;
      }
      latestLogs[word] = _logFromRow(row);
    }
    return latestLogs;
  }

  @override
  Future<void> clearAll() async {
    final db = await _openDatabase();
    await db.delete(_cardTable);
    await db.delete(_logTable);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _openDatabase() async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      await _ensureTables(existing);
      return existing;
    }

    final db = await (_databaseFactory ?? sqflite.databaseFactory).openDatabase(
      await _resolveDatabasePath(),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await _ensureTables(db);
        },
        onOpen: (db) async {
          await _ensureTables(db);
        },
      ),
    );
    await _ensureTables(db);
    _database = db;
    return db;
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_cardTable (
        word TEXT PRIMARY KEY,
        due INTEGER NOT NULL,
        stability REAL NOT NULL,
        difficulty REAL NOT NULL,
        elapsed_days INTEGER NOT NULL,
        scheduled_days INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL,
        learning_steps INTEGER NOT NULL,
        state INTEGER NOT NULL,
        last_review INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_logTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        rating INTEGER NOT NULL,
        state INTEGER NOT NULL,
        due INTEGER NOT NULL,
        stability REAL NOT NULL,
        difficulty REAL NOT NULL,
        elapsed_days INTEGER NOT NULL,
        last_elapsed_days INTEGER NOT NULL,
        scheduled_days INTEGER NOT NULL,
        learning_steps INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_cardTable}_due ON $_cardTable(due)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_logTable}_word ON $_logTable(word)',
    );
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

  FsrsCard _cardFromRow(Map<String, Object?> row) {
    final word = (row['word'] as String?) ?? '';
    return FsrsCard(
      word: word,
      due: DateTime.fromMillisecondsSinceEpoch(row['due'] as int, isUtc: true),
      stability: (row['stability'] as num).toDouble(),
      difficulty: (row['difficulty'] as num).toDouble(),
      elapsedDays: (row['elapsed_days'] as int?) ?? 0,
      scheduledDays: (row['scheduled_days'] as int?) ?? 0,
      reps: (row['reps'] as int?) ?? 0,
      lapses: (row['lapses'] as int?) ?? 0,
      learningSteps: (row['learning_steps'] as int?) ?? 0,
      state: _stateFromInt((row['state'] as int?) ?? 0),
      lastReview: row['last_review'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row['last_review'] as int,
              isUtc: true,
            ),
    );
  }

  Map<String, Object?> _cardToRow(FsrsCard card) {
    return <String, Object?>{
      'word': WordKnowledgeRecord.normalizeWord(card.word),
      'due': card.due.toUtc().millisecondsSinceEpoch,
      'stability': card.stability,
      'difficulty': card.difficulty,
      'elapsed_days': card.elapsedDays,
      'scheduled_days': card.scheduledDays,
      'reps': card.reps,
      'lapses': card.lapses,
      'learning_steps': card.learningSteps,
      'state': _stateToInt(card.state),
      'last_review': card.lastReview?.toUtc().millisecondsSinceEpoch,
    };
  }

  Map<String, Object?> _logToRow(FsrsReviewLog log) {
    return <String, Object?>{
      'word': WordKnowledgeRecord.normalizeWord(log.word),
      'rating': _ratingToInt(log.rating),
      'state': _stateToInt(log.state),
      'due': log.due.toUtc().millisecondsSinceEpoch,
      'stability': log.stability,
      'difficulty': log.difficulty,
      'elapsed_days': log.elapsedDays,
      'last_elapsed_days': log.lastElapsedDays,
      'scheduled_days': log.scheduledDays,
      'learning_steps': log.learningSteps,
      'reviewed_at': log.reviewedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  FsrsReviewLog _logFromRow(Map<String, Object?> row) {
    return FsrsReviewLog(
      word: (row['word'] as String?) ?? '',
      rating: _ratingFromInt((row['rating'] as int?) ?? 0),
      state: _stateFromInt((row['state'] as int?) ?? 0),
      due: DateTime.fromMillisecondsSinceEpoch(row['due'] as int, isUtc: true),
      stability: (row['stability'] as num).toDouble(),
      difficulty: (row['difficulty'] as num).toDouble(),
      elapsedDays: (row['elapsed_days'] as int?) ?? 0,
      lastElapsedDays: (row['last_elapsed_days'] as int?) ?? 0,
      scheduledDays: (row['scheduled_days'] as int?) ?? 0,
      learningSteps: (row['learning_steps'] as int?) ?? 0,
      reviewedAt: DateTime.fromMillisecondsSinceEpoch(
        row['reviewed_at'] as int,
        isUtc: true,
      ),
    );
  }

  int _stateToInt(FsrsState state) {
    return switch (state) {
      FsrsState.newState => 0,
      FsrsState.learning => 1,
      FsrsState.review => 2,
      FsrsState.relearning => 3,
    };
  }

  FsrsState _stateFromInt(int value) {
    return switch (value) {
      0 => FsrsState.newState,
      1 => FsrsState.learning,
      2 => FsrsState.review,
      3 => FsrsState.relearning,
      _ => FsrsState.newState,
    };
  }

  int _ratingToInt(FsrsRating rating) {
    return switch (rating) {
      FsrsRating.manual => 0,
      FsrsRating.again => 1,
      FsrsRating.hard => 2,
      FsrsRating.good => 3,
      FsrsRating.easy => 4,
    };
  }

  FsrsRating _ratingFromInt(int value) {
    return switch (value) {
      0 => FsrsRating.manual,
      1 => FsrsRating.again,
      2 => FsrsRating.hard,
      3 => FsrsRating.good,
      4 => FsrsRating.easy,
      _ => FsrsRating.manual,
    };
  }
}
