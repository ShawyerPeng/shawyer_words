import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_preferences_store.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/domain/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  late Directory tempRoot;
  late FileSystemDictionaryLibraryRepository repository;
  late FileSystemDictionaryStorage storage;
  late FileSystemDictionaryLibraryPreferencesStore preferencesStore;
  late SeededBundledDictionaryRegistry bundledRegistry;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'dictionary_library_repository_test',
    );
    storage = FileSystemDictionaryStorage(rootPath: tempRoot.path);
    preferencesStore = FileSystemDictionaryLibraryPreferencesStore(
      rootPath: tempRoot.path,
    );
    bundledRegistry = SeededBundledDictionaryRegistry(
      rootPath: tempRoot.path,
      storage: storage,
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
    repository = FileSystemDictionaryLibraryRepository(
      catalog: FileSystemDictionaryCatalog(rootPath: tempRoot.path),
      preferencesStore: preferencesStore,
      storage: storage,
      bundledRegistry: bundledRegistry,
    );

    final importedRoot = await storage.createPackageDirectories(
      type: DictionaryPackageType.imported,
      id: 'custom',
    );
    await storage.writeManifest(
      DictionaryManifest(
        id: 'custom',
        name: '用户词库',
        type: DictionaryPackageType.imported,
        rootPath: importedRoot,
        mdxPath: '$importedRoot/source/custom.mdx',
        mddPaths: const <String>[],
        resourcesPath: '$importedRoot/resources',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 321,
        category: '自定义',
        dictionaryAttribute: '本地词典',
      ),
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('merges bundled and imported packages with visible order and fallback details', () async {
    await preferencesStore.save(
      const DictionaryLibraryPreferences(
        displayOrder: <String>['custom', 'eng-eng', 'notes'],
        hiddenIds: <String>['notes'],
        autoExpandIds: <String>['eng-eng'],
        selectedDictionaryId: 'custom',
      ),
    );

    final items = await repository.loadLibraryItems();

    expect(items.map((item) => item.id).toList(), ['custom', 'eng-eng', 'notes']);
    expect(items[0].isVisible, isTrue);
    expect(items[1].autoExpand, isTrue);
    expect(items[2].isVisible, isFalse);
    expect(items[0].category, '自定义');
    expect(items[0].version, '20260316');
    expect(items[0].fileSizeLabel, '0B');
    expect(items[1].dictionaryTypeLabel, '系统内置词典');
  });

  test('reorders visible items and persists hide/show and auto expand', () async {
    await repository.reorderVisible(<String>['eng-eng', 'custom']);
    await repository.setVisibility('custom', false);
    await repository.setVisibility('notes', true);
    await repository.setAutoExpand('notes', true);

    final items = await repository.loadLibraryItems();

    expect(items.where((item) => item.isVisible).map((item) => item.id).toList(), [
      'eng-eng',
      'notes',
    ]);
    expect(items.where((item) => !item.isVisible).map((item) => item.id).toList(), [
      'custom',
    ]);
    expect(
      items.firstWhere((item) => item.id == 'notes').autoExpand,
      isTrue,
    );
  });

  test('deletes imported package directories and clears saved preferences', () async {
    await preferencesStore.save(
      const DictionaryLibraryPreferences(
        displayOrder: <String>['custom', 'eng-eng', 'notes'],
        hiddenIds: <String>['custom'],
        autoExpandIds: <String>['custom', 'notes'],
        selectedDictionaryId: 'custom',
      ),
    );

    expect(
      Directory('${tempRoot.path}/imported/custom').existsSync(),
      isTrue,
    );

    await repository.deleteDictionary('custom');

    final items = await repository.loadLibraryItems();
    final preferences = await preferencesStore.load();

    expect(items.map((item) => item.id), isNot(contains('custom')));
    expect(
      Directory('${tempRoot.path}/imported/custom').existsSync(),
      isFalse,
    );
    expect(preferences.displayOrder, isNot(contains('custom')));
    expect(preferences.hiddenIds, isNot(contains('custom')));
    expect(preferences.autoExpandIds, isNot(contains('custom')));
    expect(preferences.selectedDictionaryId, isNull);
  });

  test('rejects deleting bundled dictionaries', () async {
    await expectLater(
      () => repository.deleteDictionary('eng-eng'),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('Bundled dictionaries cannot be deleted'),
        ),
      ),
    );
  });
}
