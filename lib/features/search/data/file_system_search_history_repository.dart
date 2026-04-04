import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/domain/search_history_repository.dart';

class FileSystemSearchHistoryRepository implements SearchHistoryRepository {
  FileSystemSearchHistoryRepository({
    required Future<String> Function() rootPathResolver,
  }) : _rootPathResolver = rootPathResolver;

  final Future<String> Function() _rootPathResolver;
  List<WordEntry>? _historyCache;

  @override
  Future<void> clear() async {
    await _ensureLoaded();
    _historyCache = <WordEntry>[];
    await _persist();
  }

  @override
  Future<List<WordEntry>> loadHistory() async {
    await _ensureLoaded();
    return List<WordEntry>.unmodifiable(_historyCache!);
  }

  @override
  Future<void> saveEntry(WordEntry entry, {int limit = 10}) async {
    await _ensureLoaded();
    final items = _historyCache!;
    items.removeWhere((item) => item.id == entry.id);
    items.insert(0, entry);
    if (items.length > limit) {
      items.removeRange(limit, items.length);
    }
    await _persist();
  }

  Future<void> _ensureLoaded() async {
    if (_historyCache != null) {
      return;
    }
    final file = await _historyFile();
    if (!await file.exists()) {
      _historyCache = <WordEntry>[];
      return;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      _historyCache = <WordEntry>[];
      return;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _historyCache = list
          .whereType<Map>()
          .map(
            (item) => _decodeEntry(
              Map<String, Object?>.from(item),
            ),
          )
          .toList(growable: true);
    } on Object {
      _historyCache = <WordEntry>[];
    }
  }

  WordEntry _decodeEntry(Map<String, Object?> json) {
    return WordEntry(
      id: (json['id'] as String?) ?? '',
      word: (json['word'] as String?) ?? '',
      pronunciation: json['pronunciation'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      definition: json['definition'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      rawContent: (json['rawContent'] as String?) ?? '',
    );
  }

  Map<String, Object?> _encodeEntry(WordEntry entry) {
    return <String, Object?>{
      'id': entry.id,
      'word': entry.word,
      'pronunciation': entry.pronunciation,
      'partOfSpeech': entry.partOfSpeech,
      'definition': entry.definition,
      'exampleSentence': entry.exampleSentence,
      'rawContent': entry.rawContent,
    };
  }

  Future<void> _persist() async {
    final file = await _historyFile();
    await file.parent.create(recursive: true);
    final payload = (_historyCache ?? const <WordEntry>[])
        .map(_encodeEntry)
        .toList(growable: false);
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<File> _historyFile() async {
    final rootPath = await _rootPathResolver();
    return File('$rootPath/search_history.json');
  }
}
