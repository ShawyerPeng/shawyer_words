import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/data/dictionary_root_path_resolver.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog_entry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

class FileSystemDictionaryCatalog implements DictionaryCatalog {
  FileSystemDictionaryCatalog({
    this.rootPath,
    DictionaryRootPathResolver? rootPathResolver,
  }) : _rootPathResolver = rootPathResolver;

  final String? rootPath;
  final DictionaryRootPathResolver? _rootPathResolver;

  @override
  Future<List<DictionaryCatalogEntry>> listPackages({
    DictionaryPackageType? type,
  }) async {
    if (type != null) {
      return _listPackagesForType(type);
    }

    final bundled = await _listPackagesForType(DictionaryPackageType.bundled);
    final imported = await _listPackagesForType(DictionaryPackageType.imported);
    return <DictionaryCatalogEntry>[...bundled, ...imported];
  }

  Future<List<DictionaryCatalogEntry>> _listPackagesForType(
    DictionaryPackageType type,
  ) async {
    final resolvedRootPath = await _resolveRootPath();
    final parent = Directory('$resolvedRootPath/${type.name}');
    if (!await parent.exists()) {
      return const <DictionaryCatalogEntry>[];
    }

    final manifests = <DictionaryCatalogEntry>[];
    await for (final entity in parent.list()) {
      if (entity is! Directory) {
        continue;
      }

      final manifestFile = File('${entity.path}/manifest.json');
      if (!await manifestFile.exists()) {
        continue;
      }

      final json = jsonDecode(
        await manifestFile.readAsString(),
      ) as Map<String, Object?>;
      final manifest = DictionaryManifest.fromJson(json);
      manifests.add(
        DictionaryCatalogEntry(
          id: manifest.id,
          name: manifest.name,
          type: manifest.type,
          rootPath: entity.path,
          importedAt: manifest.importedAt,
          entryCount: manifest.entryCount,
          version: manifest.version,
          category: manifest.category,
          dictionaryAttribute: manifest.dictionaryAttribute,
          fileSizeBytes: manifest.fileSizeBytes,
        ),
      );
    }

    manifests.sort((left, right) => left.id.compareTo(right.id));
    return manifests;
  }

  Future<String> _resolveRootPath() async {
    if (rootPath != null) {
      return rootPath!;
    }
    if (_rootPathResolver != null) {
      return _rootPathResolver();
    }
    throw StateError('A dictionary root path or resolver is required.');
  }
}
