import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';

class DictionaryEntryLookupRepository {
  DictionaryEntryLookupRepository({
    required DictionaryLibraryRepository libraryRepository,
    required DictionaryCatalog catalog,
    MdictReaderFactory? readerFactory,
    MdxDictionaryParser? parser,
  }) : _libraryRepository = libraryRepository,
       _catalog = catalog,
       _readerFactory = readerFactory ?? ((path) => DictReaderAdapter(path)),
       _parser = parser ?? MdxDictionaryParser();

  final DictionaryLibraryRepository _libraryRepository;
  final DictionaryCatalog _catalog;
  final MdictReaderFactory _readerFactory;
  final MdxDictionaryParser _parser;
  final Map<String, DictionaryPackage> _packageByRootPath =
      <String, DictionaryPackage>{};
  final Map<String, MdictReadable> _readerByMdxPath = <String, MdictReadable>{};
  final Set<String> _openedReaderPaths = <String>{};
  final Map<String, List<String>> _resourcePathCache = <String, List<String>>{};

  Future<List<DictionaryEntryDetail>> lookupAcrossVisibleDictionaries(
    String word,
  ) async {
    final visibleItems = (await _libraryRepository.loadLibraryItems())
        .where((item) => item.isVisible)
        .toList(growable: false);
    final catalogEntries = await _catalog.listPackages();
    final rootPathById = <String, String>{
      for (final entry in catalogEntries) entry.id: entry.rootPath,
    };
    final tasks = visibleItems.map((item) async {
      final rootPath = rootPathById[item.id];
      if (rootPath == null) {
        return null;
      }
      try {
        final package = await _loadPackage(rootPath);
        return await _lookupPackage(
          package: package,
          dictionaryId: item.id,
          dictionaryName: item.name,
          word: word,
        );
      } catch (error) {
        return DictionaryEntryDetail(
          dictionaryId: item.id,
          dictionaryName: item.name,
          word: word.trim().toLowerCase(),
          rawContent: '',
          errorMessage: '$error',
        );
      }
    }).toList(growable: false);

    final resolved = await Future.wait(tasks);
    return resolved
        .whereType<DictionaryEntryDetail>()
        .toList(growable: false);
  }

  Future<DictionaryEntryDetail?> _lookupPackage({
    required DictionaryPackage package,
    required String dictionaryId,
    required String dictionaryName,
    required String word,
  }) async {
    final reader = await _getReader(package.mdxPath);
    final rawContent = await reader.lookup(word);
    if (rawContent == null || rawContent.trim().isEmpty) {
      return null;
    }
    final entry = _parser.mapEntry(word: word, rawContent: rawContent);
    return DictionaryEntryDetail(
      dictionaryId: dictionaryId,
      dictionaryName: dictionaryName,
      word: entry.word,
      rawContent: entry.rawContent,
      resourcesPath: package.resourcesPath,
      mddPaths: package.mddPaths,
      stylesheetPaths: await _resourcePaths(package.resourcesPath, '.css'),
      scriptPaths: await _resourcePaths(package.resourcesPath, '.js'),
      basic: WordBasicSummary(
        headword: entry.word,
        pronunciationUs: entry.pronunciation,
      ),
      definitions: entry.definition == null
          ? const <WordSense>[]
          : <WordSense>[
              WordSense(
                partOfSpeech: entry.partOfSpeech ?? '',
                definitionZh: entry.definition!,
              ),
            ],
      examples: entry.exampleSentence == null
          ? const <WordExample>[]
          : <WordExample>[
              WordExample(english: entry.exampleSentence!, translationZh: ''),
            ],
    );
  }

  Future<DictionaryPackage> _loadPackage(String rootPath) async {
    final cached = _packageByRootPath[rootPath];
    if (cached != null) {
      return cached;
    }
    final manifestFile = File('$rootPath/manifest.json');
    final json =
        jsonDecode(await manifestFile.readAsString()) as Map<String, Object?>;
    final manifest = DictionaryManifest.fromJson(json);
    final package = DictionaryPackage(
      id: manifest.id,
      name: manifest.name,
      type: manifest.type,
      rootPath: rootPath,
      mdxPath: _resolvePath(rootPath: rootPath, manifestPath: manifest.mdxPath),
      mddPaths: manifest.mddPaths
          .map((path) => _resolvePath(rootPath: rootPath, manifestPath: path))
          .toList(growable: false),
      resourcesPath: _resolvePath(
        rootPath: rootPath,
        manifestPath: manifest.resourcesPath,
      ),
      importedAt: manifest.importedAt,
      entryCount: manifest.entryCount,
      version: manifest.version,
      category: manifest.category,
      dictionaryAttribute: manifest.dictionaryAttribute,
      fileSizeBytes: manifest.fileSizeBytes,
    );
    _packageByRootPath[rootPath] = package;
    return package;
  }

  String _resolvePath({
    required String rootPath,
    required String manifestPath,
  }) {
    final normalized = manifestPath.replaceAll('\\', '/');
    if (!normalized.startsWith('/')) {
      return '$rootPath/$normalized';
    }

    final marker = '/source/';
    final sourceIndex = normalized.lastIndexOf(marker);
    if (sourceIndex >= 0) {
      return '$rootPath/source/${normalized.substring(sourceIndex + marker.length)}';
    }

    final resourcesMarker = '/resources';
    final resourcesIndex = normalized.lastIndexOf(resourcesMarker);
    if (resourcesIndex >= 0) {
      final suffix = normalized.substring(
        resourcesIndex + resourcesMarker.length,
      );
      return '$rootPath/resources$suffix';
    }

    return '$rootPath/${normalized.split('/').last}';
  }

  Future<List<String>> _resourcePaths(
    String resourcesPath,
    String extension,
  ) async {
    final cacheKey = '$resourcesPath|$extension';
    final cached = _resourcePathCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final directory = Directory(resourcesPath);
    if (!await directory.exists()) {
      return const <String>[];
    }

    final matches = <String>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }
      if (entity.path.toLowerCase().endsWith(extension)) {
        matches.add(entity.path);
      }
    }
    matches.sort();
    _resourcePathCache[cacheKey] = matches;
    return matches;
  }

  Future<MdictReadable> _getReader(String mdxPath) async {
    final reader = _readerByMdxPath.putIfAbsent(
      mdxPath,
      () => _readerFactory(mdxPath),
    );
    if (_openedReaderPaths.add(mdxPath)) {
      try {
        await reader.open();
      } catch (_) {
        _openedReaderPaths.remove(mdxPath);
        _readerByMdxPath.remove(mdxPath);
        rethrow;
      }
    }
    return reader;
  }

  Future<void> dispose() async {
    final readers = _readerByMdxPath.values.toList(growable: false);
    _readerByMdxPath.clear();
    _openedReaderPaths.clear();
    _resourcePathCache.clear();
    _packageByRootPath.clear();
    for (final reader in readers) {
      await reader.close();
    }
  }
}
