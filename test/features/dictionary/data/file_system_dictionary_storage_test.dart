import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  late Directory tempRoot;
  late FileSystemDictionaryStorage storage;
  late FileSystemDictionaryCatalog catalog;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'file_system_dictionary_storage_test',
    );
    storage = FileSystemDictionaryStorage(rootPath: tempRoot.path);
    catalog = FileSystemDictionaryCatalog(rootPath: tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('creates isolated package directories and writes manifest.json', () async {
    final rootPath = await storage.createPackageDirectories(
      type: DictionaryPackageType.imported,
      id: 'oxford-mini',
    );
    final manifest = DictionaryManifest(
      id: 'oxford-mini',
      name: 'Oxford Mini',
      type: DictionaryPackageType.imported,
      rootPath: rootPath,
      mdxPath: '$rootPath/source/main.mdx',
      mddPaths: <String>['$rootPath/source/main.mdd'],
      resourcesPath: '$rootPath/resources',
      importedAt: '2026-03-16T00:00:00.000Z',
      entryCount: 24,
    );

    await storage.writeManifest(manifest);

    expect(Directory(rootPath).existsSync(), isTrue);
    expect(Directory('$rootPath/source').existsSync(), isTrue);
    expect(Directory('$rootPath/resources').existsSync(), isTrue);
    expect(Directory('$rootPath/cache').existsSync(), isTrue);

    final manifestFile = File('$rootPath/manifest.json');
    expect(manifestFile.existsSync(), isTrue);

    final decoded = jsonDecode(
      await manifestFile.readAsString(),
    ) as Map<String, Object?>;
    expect(decoded['id'], 'oxford-mini');
    expect(decoded['type'], 'imported');
    expect(decoded['entryCount'], 24);
  });

  test('lists bundled and imported packages separately from manifests', () async {
    final bundledRoot = await storage.createPackageDirectories(
      type: DictionaryPackageType.bundled,
      id: 'core',
    );
    final importedRoot = await storage.createPackageDirectories(
      type: DictionaryPackageType.imported,
      id: 'custom',
    );

    await storage.writeManifest(
      DictionaryManifest(
        id: 'core',
        name: 'Bundled Core',
        type: DictionaryPackageType.bundled,
        rootPath: bundledRoot,
        mdxPath: '$bundledRoot/source/core.mdx',
        mddPaths: const <String>[],
        resourcesPath: '$bundledRoot/resources',
        importedAt: '2026-03-16T00:00:00.000Z',
      ),
    );
    await storage.writeManifest(
      DictionaryManifest(
        id: 'custom',
        name: 'Imported Custom',
        type: DictionaryPackageType.imported,
        rootPath: importedRoot,
        mdxPath: '$importedRoot/source/custom.mdx',
        mddPaths: const <String>[],
        resourcesPath: '$importedRoot/resources',
        importedAt: '2026-03-16T00:00:01.000Z',
        entryCount: 10,
      ),
    );

    final bundled = await catalog.listPackages(
      type: DictionaryPackageType.bundled,
    );
    final imported = await catalog.listPackages(
      type: DictionaryPackageType.imported,
    );

    expect(bundled, hasLength(1));
    expect(imported, hasLength(1));
    expect(bundled.single.id, 'core');
    expect(imported.single.id, 'custom');
    expect(imported.single.entryCount, 10);
  });

  test('deletes imported packages but refuses bundled packages', () async {
    final bundledRoot = await storage.createPackageDirectories(
      type: DictionaryPackageType.bundled,
      id: 'read-only',
    );
    final importedRoot = await storage.createPackageDirectories(
      type: DictionaryPackageType.imported,
      id: 'delete-me',
    );

    expect(
      () => storage.deletePackage(
        type: DictionaryPackageType.bundled,
        id: 'read-only',
      ),
      throwsA(isA<UnsupportedError>()),
    );

    await storage.deletePackage(
      type: DictionaryPackageType.imported,
      id: 'delete-me',
    );

    expect(Directory(importedRoot).existsSync(), isFalse);
    expect(Directory(bundledRoot).existsSync(), isTrue);
  });
}
