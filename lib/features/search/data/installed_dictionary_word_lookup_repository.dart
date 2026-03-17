import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/data/sample_word_lookup_repository.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';

class InstalledDictionaryWordLookupRepository implements WordLookupRepository {
  InstalledDictionaryWordLookupRepository({
    required DictionaryLibraryRepository libraryRepository,
    required DictionaryCatalog catalog,
    required WordLookupRepository fallbackRepository,
    MdictReaderFactory? readerFactory,
  }) : _libraryRepository = libraryRepository,
       _catalog = catalog,
       _fallbackRepository = fallbackRepository,
       _readerFactory = readerFactory ?? ((path) => DictReaderAdapter(path));

  final DictionaryLibraryRepository _libraryRepository;
  final DictionaryCatalog _catalog;
  final WordLookupRepository _fallbackRepository;
  final MdictReaderFactory _readerFactory;

  String? _cachedSignature;
  List<WordEntry> _cachedEntries = const <WordEntry>[];
  Map<String, WordEntry> _cachedEntryById = const <String, WordEntry>{};

  @override
  WordEntry? findById(String id) {
    return _cachedEntryById[id] ?? _fallbackRepository.findById(id);
  }

  @override
  Future<List<WordEntry>> searchWords(String query, {int limit = 20}) async {
    final entries = await _loadVisibleEntries();
    if (entries.isNotEmpty) {
      return rankWordEntries(entries, query, limit: limit);
    }
    return _fallbackRepository.searchWords(query, limit: limit);
  }

  Future<List<WordEntry>> _loadVisibleEntries() async {
    final visibleItems = (await _libraryRepository.loadLibraryItems())
        .where((item) => item.isVisible)
        .toList(growable: false);
    final catalogEntries = await _catalog.listPackages();
    final rootPathById = <String, String>{
      for (final entry in catalogEntries) entry.id: entry.rootPath,
    };
    final signature = visibleItems
        .map((item) => '${item.id}:${rootPathById[item.id] ?? ''}')
        .join('|');

    if (_cachedSignature == signature) {
      return _cachedEntries;
    }

    final entries = <WordEntry>[];
    final seenWords = <String>{};

    for (final item in visibleItems) {
      final rootPath = rootPathById[item.id];
      if (rootPath == null) {
        continue;
      }

      try {
        final package = await _loadPackage(rootPath);
        final keys = await _loadKeys(package.mdxPath);
        for (final key in keys) {
          final normalizedWord = key.trim();
          if (normalizedWord.isEmpty || !seenWords.add(normalizedWord)) {
            continue;
          }
          entries.add(
            WordEntry(id: normalizedWord, word: normalizedWord, rawContent: ''),
          );
        }
      } on Object {
        continue;
      }
    }

    _cachedSignature = signature;
    _cachedEntries = entries;
    _cachedEntryById = <String, WordEntry>{
      for (final entry in entries) entry.id: entry,
    };
    return entries;
  }

  Future<List<String>> _loadKeys(String mdxPath) async {
    final reader = _readerFactory(mdxPath);
    await reader.open();
    try {
      return reader.listKeys(limit: 1 << 30);
    } finally {
      await reader.close();
    }
  }

  Future<DictionaryPackage> _loadPackage(String rootPath) async {
    final manifestFile = File('$rootPath/manifest.json');
    final json = jsonDecode(
      await manifestFile.readAsString(),
    ) as Map<String, Object?>;
    final manifest = DictionaryManifest.fromJson(json);
    return manifest.toPackage();
  }
}
