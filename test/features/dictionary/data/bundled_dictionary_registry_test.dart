import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/domain/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  late Directory tempRoot;
  late SeededBundledDictionaryRegistry registry;
  late FileSystemDictionaryCatalog catalog;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'bundled_dictionary_registry_test',
    );
    registry = SeededBundledDictionaryRegistry(
      rootPath: tempRoot.path,
      storage: FileSystemDictionaryStorage(rootPath: tempRoot.path),
      seeds: const <BundledDictionarySeed>[
        BundledDictionarySeed(
          id: 'eng-eng',
          name: '英英词典',
          version: '20251021',
          category: '默认',
          entryCount: 428674,
          dictionaryAttribute: '本地词典',
          fileSizeBytes: 90 * 1024 * 1024,
        ),
        BundledDictionarySeed(
          id: 'notes',
          name: '学习笔记',
          version: '20251021',
          category: '默认',
          entryCount: 120,
          dictionaryAttribute: '本地词典',
          fileSizeBytes: 8 * 1024 * 1024,
        ),
      ],
    );
    catalog = FileSystemDictionaryCatalog(rootPath: tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('registers bundled dictionaries into manifest-backed package directories', () async {
    final packages = await registry.sync();

    expect(packages, hasLength(2));
    expect(packages.first.type, DictionaryPackageType.bundled);
    expect(File(packages.first.mdxPath).existsSync(), isTrue);
    expect(File('${packages.first.rootPath}/manifest.json').existsSync(), isTrue);

    final bundled = await catalog.listPackages(type: DictionaryPackageType.bundled);
    expect(bundled, hasLength(2));
    expect(bundled.first.version, '20251021');
    expect(bundled.first.category, '默认');
    expect(bundled.first.dictionaryAttribute, '本地词典');
    expect(bundled.first.fileSizeBytes, 90 * 1024 * 1024);
  });
}
