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
    final details = <DictionaryEntryDetail>[];

    for (final item in visibleItems) {
      final rootPath = rootPathById[item.id];
      if (rootPath == null) {
        continue;
      }

      try {
        final package = await _loadPackage(rootPath);
        final detail = await _lookupPackage(
          package: package,
          dictionaryId: item.id,
          dictionaryName: item.name,
          word: word,
        );
        if (detail != null) {
          details.add(detail);
        }
      } catch (error) {
        details.add(
          DictionaryEntryDetail(
            dictionaryId: item.id,
            dictionaryName: item.name,
            word: word.trim().toLowerCase(),
            rawContent: '',
            errorMessage: '$error',
          ),
        );
      }
    }

    return details;
  }

  Future<DictionaryEntryDetail?> _lookupPackage({
    required DictionaryPackage package,
    required String dictionaryId,
    required String dictionaryName,
    required String word,
  }) async {
    final reader = _readerFactory(package.mdxPath);
    await reader.open();
    try {
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
                WordExample(
                  english: entry.exampleSentence!,
                  translationZh: '',
                ),
              ],
      );
    } finally {
      await reader.close();
    }
  }

  Future<DictionaryPackage> _loadPackage(String rootPath) async {
    final manifestFile = File('$rootPath/manifest.json');
    final json = jsonDecode(
      await manifestFile.readAsString(),
    ) as Map<String, Object?>;
    return DictionaryManifest.fromJson(json).toPackage();
  }
}
