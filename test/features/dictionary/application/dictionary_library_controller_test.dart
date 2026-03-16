import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  test('deleteDictionary reloads items after repository deletion', () async {
    final repository = _FakeDictionaryLibraryRepository();
    final controller = DictionaryLibraryController(repository: repository);

    await controller.load();
    expect(controller.itemById('custom'), isNotNull);

    await controller.deleteDictionary('custom');

    expect(controller.itemById('custom'), isNull);
    expect(repository.deletedIds, <String>['custom']);
  });
}

class _FakeDictionaryLibraryRepository implements DictionaryLibraryRepository {
  final List<DictionaryLibraryItem> _items = <DictionaryLibraryItem>[
    const DictionaryLibraryItem(
      id: 'custom',
      name: '自定义词典',
      type: DictionaryPackageType.imported,
      rootPath: '/tmp/custom',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20260316',
      category: '自定义',
      entryCount: 12,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 1024,
      fileSizeLabel: '1K',
      isVisible: true,
      autoExpand: false,
      sortIndex: 0,
    ),
  ];
  final List<String> deletedIds = <String>[];

  @override
  Future<void> deleteDictionary(String id) async {
    deletedIds.add(id);
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async =>
      List<DictionaryLibraryItem>.from(_items);

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {}

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {}

  @override
  Future<void> setVisibility(String id, bool isVisible) async {}
}
