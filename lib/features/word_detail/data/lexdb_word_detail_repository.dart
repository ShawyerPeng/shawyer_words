import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
          entryAttributes: await _loadEntryAttributes(database, entryId),
          relations: await _loadRelations(database, entryId),
          senses: await _loadSenses(database, entryId),
          collocations: await _loadCollocations(database, entryId),
        ),
      );
    }
    return results;
  }

  Future<Map<String, String>> lookupBriefDefinitions(
    Iterable<String> words,
  ) async {
    final normalizedWords = <String>[];
    final dedupe = <String>{};
    for (final word in words) {
      final normalized = word.trim().toLowerCase();
      if (normalized.isEmpty || !dedupe.add(normalized)) {
        continue;
      }
      normalizedWords.add(normalized);
    }
    if (normalizedWords.isEmpty) {
      return const <String, String>{};
    }

    final database = await _openDatabase();
    final placeholders = List<String>.filled(
      normalizedWords.length,
      '?',
    ).join(',');
    final tldRows = await database.rawQuery('''
      SELECT
        e.headword_lower AS headword_lower,
        ea.attr_value AS attr_value
      FROM entries e
      JOIN entry_attributes ea
        ON ea.entry_id = e.id
       AND ea.attr_key = 'tld/sense_ratio_cn'
      WHERE e.headword_lower IN ($placeholders)
      ORDER BY e.headword_lower, ea.id
      ''', normalizedWords);

    final tldByWord = <String, String>{};
    for (final row in tldRows) {
      final key = ((row['headword_lower'] as String?) ?? '')
          .trim()
          .toLowerCase();
      if (key.isEmpty || tldByWord.containsKey(key)) {
        continue;
      }
      final brief = _extractTldBriefMeaning(row['attr_value']);
      if (brief.isEmpty) {
        continue;
      }
      tldByWord[key] = brief;
    }

    final rows = await database.rawQuery('''
      SELECT
        e.headword_lower AS headword_lower,
        s.definition_zh AS definition_zh,
        s.definition AS definition
      FROM entries e
      LEFT JOIN senses s ON s.entry_id = e.id
      WHERE e.headword_lower IN ($placeholders)
      ORDER BY e.headword_lower, e.id, s.sort_order, s.id
      ''', normalizedWords);

    final zhByWord = <String, String>{};
    final fallbackByWord = <String, String>{};

    for (final row in rows) {
      final key = ((row['headword_lower'] as String?) ?? '')
          .trim()
          .toLowerCase();
      if (key.isEmpty) {
        continue;
      }

      final definitionZh = ((row['definition_zh'] as String?) ?? '').trim();
      if (definitionZh.isNotEmpty && !zhByWord.containsKey(key)) {
        zhByWord[key] = _compactDefinition(definitionZh);
      }

      final definition = ((row['definition'] as String?) ?? '').trim();
      if (definition.isNotEmpty && !fallbackByWord.containsKey(key)) {
        fallbackByWord[key] = _compactDefinition(definition);
      }
    }

    final result = <String, String>{};
    for (final word in normalizedWords) {
      final value = tldByWord[word] ?? zhByWord[word] ?? fallbackByWord[word];
      if (value == null || value.isEmpty) {
        continue;
      }
      result[word] = value;
    }
    return result;
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

  Future<Map<String, String>> _loadEntryAttributes(
    Database database,
    int entryId,
  ) async {
    try {
      final rows = await database.query(
        'entry_attributes',
        columns: <String>['attr_key', 'attr_value'],
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
        orderBy: 'id',
      );
      final attributes = <String, String>{};
      for (final row in rows) {
        final key = (row['attr_key'] as String?)?.trim() ?? '';
        if (key.isEmpty) {
          continue;
        }
        final value = _decodeAttributeValue(row['attr_value']);
        if (value.isEmpty) {
          continue;
        }
        attributes[key] = value;
      }
      return attributes;
    } on DatabaseException {
      return const <String, String>{};
    }
  }

  Future<List<LexDbRelation>> _loadRelations(
    Database database,
    int entryId,
  ) async {
    try {
      final rows = await database.query(
        'relations',
        columns: <String>[
          'relation_type',
          'clickable',
          'target_word',
          'prefix',
          'suffix',
        ],
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
        orderBy: 'sort_order, id',
      );
      return rows
          .map(
            (row) => LexDbRelation(
              relationType: (row['relation_type'] as String?) ?? '',
              clickable: (row['clickable'] as String?) ?? '',
              targetWord: (row['target_word'] as String?) ?? '',
              prefix: row['prefix'] as String?,
              suffix: row['suffix'] as String?,
            ),
          )
          .where(
            (relation) =>
                relation.relationType.trim().isNotEmpty &&
                relation.targetWord.trim().isNotEmpty,
          )
          .toList(growable: false);
    } on DatabaseException {
      return const <LexDbRelation>[];
    }
  }

  String _decodeAttributeValue(Object? rawValue) {
    if (rawValue == null) {
      return '';
    }
    if (rawValue is String) {
      return rawValue.trim();
    }
    final bytes = switch (rawValue) {
      Uint8List value => value,
      List<int> value => Uint8List.fromList(value),
      _ => null,
    };
    if (bytes == null || bytes.isEmpty) {
      return '';
    }

    final plainText = utf8.decode(bytes, allowMalformed: true).trim();
    if (plainText.isNotEmpty &&
        (plainText.startsWith('[') || plainText.startsWith('{'))) {
      return plainText;
    }

    try {
      final inflated = ZLibCodec().decode(bytes);
      return utf8.decode(inflated, allowMalformed: true).trim();
    } on Object {
      return plainText;
    }
  }

  String _compactDefinition(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    var text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      return '';
    }

    final separators = <String>['；', ';', '。', '.', '，', ','];
    var cutIndex = -1;
    for (final separator in separators) {
      final index = text.indexOf(separator);
      if (index <= 0) {
        continue;
      }
      if (cutIndex < 0 || index < cutIndex) {
        cutIndex = index;
      }
    }
    if (cutIndex > 0) {
      text = text.substring(0, cutIndex).trim();
    }

    const maxLength = 30;
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}…';
    }
    return text;
  }

  String _extractTldBriefMeaning(Object? rawAttrValue) {
    final decoded = _decodeAttributeValue(rawAttrValue);
    if (decoded.isEmpty) {
      return '';
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(decoded);
    } on Object {
      return _compactDefinition(decoded);
    }

    if (parsed is! List) {
      return '';
    }

    String bestMeaning = '';
    double bestPercent = -1;

    for (final item in parsed) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, Object?>.from(item);
      final meaning = ((map['meaning'] as String?) ?? '').trim();
      if (meaning.isEmpty) {
        continue;
      }
      final percent = _parseNumeric(map['percent']);
      if (percent > bestPercent) {
        bestPercent = percent;
        bestMeaning = meaning;
      }
    }

    if (bestMeaning.isNotEmpty) {
      return _compactDefinition(bestMeaning);
    }
    return '';
  }

  double _parseNumeric(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? -1;
    }
    return -1;
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
