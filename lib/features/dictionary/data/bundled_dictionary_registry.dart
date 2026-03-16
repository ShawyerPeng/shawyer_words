import 'dart:io';

import 'package:shawyer_words/features/dictionary/domain/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';

class SeededBundledDictionaryRegistry implements BundledDictionaryRegistry {
  SeededBundledDictionaryRegistry({
    required this.rootPath,
    required DictionaryStorage storage,
    required this.seeds,
  }) : _storage = storage;

  final String rootPath;
  final DictionaryStorage _storage;
  final List<BundledDictionarySeed> seeds;

  @override
  Future<List<DictionaryPackage>> sync() async {
    final packages = <DictionaryPackage>[];
    for (final seed in seeds) {
      final packageRoot = await _storage.createPackageDirectories(
        type: DictionaryPackageType.bundled,
        id: seed.id,
      );
      final sourceRoot = '$packageRoot/source';
      final mdxPath = '$sourceRoot/${seed.id}.mdx';
      final mdxFile = File(mdxPath);
      if (!await mdxFile.exists()) {
        await mdxFile.parent.create(recursive: true);
        await mdxFile.writeAsString('Bundled dictionary placeholder: ${seed.name}');
      }

      final manifest = await _storage.writeManifest(
        DictionaryManifest(
          id: seed.id,
          name: seed.name,
          type: DictionaryPackageType.bundled,
          rootPath: packageRoot,
          mdxPath: mdxPath,
          mddPaths: const <String>[],
          resourcesPath: '$packageRoot/resources',
          importedAt: '2026-03-16T00:00:00.000Z',
          entryCount: seed.entryCount,
          version: seed.version,
          category: seed.category,
          dictionaryAttribute: seed.dictionaryAttribute,
          fileSizeBytes: seed.fileSizeBytes,
        ),
      );
      packages.add(manifest.toPackage());
    }
    return packages;
  }
}
