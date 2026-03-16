import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/data/dictionary_root_path_resolver.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';

class FileSystemDictionaryStorage implements DictionaryStorage {
  FileSystemDictionaryStorage({
    this.rootPath,
    DictionaryRootPathResolver? rootPathResolver,
  }) : _rootPathResolver = rootPathResolver;

  final String? rootPath;
  final DictionaryRootPathResolver? _rootPathResolver;

  @override
  Future<String> createPackageDirectories({
    required DictionaryPackageType type,
    required String id,
  }) async {
    final packageRoot = await _packageRootPath(type: type, id: id);
    await Directory('$packageRoot/source').create(recursive: true);
    await Directory('$packageRoot/resources').create(recursive: true);
    await Directory('$packageRoot/cache').create(recursive: true);
    return packageRoot;
  }

  @override
  Future<void> deletePackage({
    required DictionaryPackageType type,
    required String id,
  }) async {
    if (type == DictionaryPackageType.bundled) {
      throw UnsupportedError('Bundled dictionaries are read-only.');
    }

    final directory = Directory(await _packageRootPath(type: type, id: id));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<DictionaryManifest> writeManifest(DictionaryManifest manifest) async {
    final file = File('${manifest.rootPath}/manifest.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    return manifest;
  }

  Future<String> _packageRootPath({
    required DictionaryPackageType type,
    required String id,
  }) async {
    final resolvedRootPath = await _resolveRootPath();
    return '$resolvedRootPath/${type.name}/$id';
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
