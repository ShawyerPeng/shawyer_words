import 'dart:io';

import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/data/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';
import 'package:path_provider/path_provider.dart';

class PlatformDictionaryRepository implements DictionaryRepository {
  PlatformDictionaryRepository({
    DictionaryPackageImporter? importer,
    MdxDictionaryParser? parser,
    DictionaryStorage? storage,
  }) : _importer = importer ?? _defaultImporter(),
       _parser = parser ?? MdxDictionaryParser(),
       _storage = storage ?? _defaultStorage();

  final DictionaryPackageImporter _importer;
  final MdxDictionaryParser _parser;
  final DictionaryStorage _storage;

  @override
  Future<DictionaryImportResult> importDictionary(String sourcePath) async {
    final package = await _importer.importPackage(sourcePath);
    final result = await _parser.parse(package);
    await _writeManifest(result.package);
    return result;
  }

  static DictionaryPackageImporter _defaultImporter() {
    return FileSystemDictionaryPackageImporter(
      rootPathResolver: _dictionaryRootPath,
      storage: _defaultStorage(),
    );
  }

  static DictionaryStorage _defaultStorage() {
    return FileSystemDictionaryStorage(rootPathResolver: _dictionaryRootPath);
  }

  static Future<String> _dictionaryRootPath() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return '${supportDirectory.path}/dictionaries';
  }

  Future<void> _writeManifest(DictionaryPackage package) async {
    final fileSizeBytes = await _calculateDirectorySize(package.rootPath);
    await _storage.writeManifest(
      DictionaryManifest(
        id: package.id,
        name: package.name,
        type: package.type,
        rootPath: package.rootPath,
        mdxPath: package.mdxPath,
        mddPaths: package.mddPaths,
        resourcesPath: package.resourcesPath,
        importedAt: package.importedAt,
        entryCount: package.entryCount,
        version: package.version,
        category: package.category,
        dictionaryAttribute: package.dictionaryAttribute,
        fileSizeBytes: fileSizeBytes,
      ),
    );
  }

  Future<int> _calculateDirectorySize(String rootPath) async {
    final directory = Directory(rootPath);
    if (!await directory.exists()) {
      return 0;
    }

    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      total += await entity.length();
    }
    return total;
  }
}
