import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog_entry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/search/data/installed_dictionary_word_lookup_repository.dart';
import 'package:shawyer_words/features/search/data/sample_word_lookup_repository.dart';

void main() {
  test('searches across installed visible dictionaries instead of fallback seeds', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'installed_dictionary_word_lookup_repository_test',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final packageRoot = Directory('${tempDir.path}/imported/collins')..createSync(recursive: true);
    final manifest = DictionaryManifest(
      id: 'collins',
      name: 'Collins',
      type: DictionaryPackageType.imported,
      rootPath: packageRoot.path,
      mdxPath: '${packageRoot.path}/source/main.mdx',
      mddPaths: const <String>[],
      resourcesPath: '${packageRoot.path}/resources',
      importedAt: '2026-03-17T00:00:00.000Z',
    );
    await File('${packageRoot.path}/manifest.json').writeAsString(
      jsonEncode(manifest.toJson()),
    );

    final repository = InstalledDictionaryWordLookupRepository(
      libraryRepository: _FakeDictionaryLibraryRepository(
        items: [
          DictionaryLibraryItem(
            id: 'collins',
            name: 'Collins',
            type: DictionaryPackageType.imported,
            rootPath: packageRoot.path,
            importedAt: '2026-03-17T00:00:00.000Z',
            version: '1',
            category: 'custom',
            entryCount: 2,
            dictionaryAttribute: '本地词典',
            fileSizeBytes: 1024,
            fileSizeLabel: '1K',
            isVisible: true,
            autoExpand: false,
            sortIndex: 0,
          ),
        ],
      ),
      catalog: _FakeDictionaryCatalog(
        entries: [
          DictionaryCatalogEntry(
            id: 'collins',
            name: 'Collins',
            type: DictionaryPackageType.imported,
            rootPath: packageRoot.path,
            importedAt: '2026-03-17T00:00:00.000Z',
          ),
        ],
      ),
      fallbackRepository: SampleWordLookupRepository.seeded(),
      readerFactory: (_) => _FakeMdictReader(),
    );

    final results = await repository.searchWords('ze');

    expect(results.map((entry) => entry.word), ['zebra', 'zeal']);
  });
}

class _FakeDictionaryLibraryRepository implements DictionaryLibraryRepository {
  _FakeDictionaryLibraryRepository({required this.items});

  final List<DictionaryLibraryItem> items;

  @override
  Future<void> deleteDictionary(String id) async {}

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async => items;

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {}

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {}

  @override
  Future<void> setVisibility(String id, bool isVisible) async {}
}

class _FakeDictionaryCatalog implements DictionaryCatalog {
  _FakeDictionaryCatalog({required this.entries});

  final List<DictionaryCatalogEntry> entries;

  @override
  Future<List<DictionaryCatalogEntry>> listPackages({
    DictionaryPackageType? type,
  }) async {
    if (type == null) {
      return entries;
    }
    return entries.where((entry) => entry.type == type).toList();
  }
}

class _FakeMdictReader implements MdictReadable {
  @override
  Future<void> close() async {}

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    return <String>['zebra', 'zeal', 'abandon'];
  }

  @override
  Future<void> open() async {}

  @override
  Future<String?> lookup(String word) async => null;
}
