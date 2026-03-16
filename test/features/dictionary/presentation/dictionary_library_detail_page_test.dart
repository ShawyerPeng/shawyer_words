import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_detail_page.dart';

void main() {
  testWidgets('shows dictionary detail fields and toggles', (tester) async {
    final repository = _FakeDictionaryLibraryRepository();
    final controller = DictionaryLibraryController(repository: repository);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryDetailPage(
          controller: controller,
          dictionaryId: 'eng-eng',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('英英词典'), findsWidgets);
    expect(find.text('显示该词库'), findsOneWidget);
    expect(find.text('自动展开'), findsOneWidget);
    expect(find.text('词库版本：'), findsOneWidget);
    expect(find.text('系统内置词典'), findsOneWidget);
    expect(find.text('删除该词典'), findsNothing);
  });

  testWidgets('shows delete action for imported dictionaries and confirms deletion', (tester) async {
    final repository = _FakeDictionaryLibraryRepository();
    repository.items.add(
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
        sortIndex: 1,
      ),
    );
    final controller = DictionaryLibraryController(repository: repository);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryDetailPage(
          controller: controller,
          dictionaryId: 'custom',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('删除该词典'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('删除该词典'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('删除该词典'));
    await tester.pumpAndSettle();

    expect(find.text('删除词典？'), findsOneWidget);
    expect(find.text('删除后会同时移除应用内保存的词典文件，且无法恢复。'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, <String>['custom']);
  });
}

class _FakeDictionaryLibraryRepository implements DictionaryLibraryRepository {
  final List<DictionaryLibraryItem> items = <DictionaryLibraryItem>[
    const DictionaryLibraryItem(
      id: 'eng-eng',
      name: '英英词典',
      type: DictionaryPackageType.bundled,
      rootPath: '/tmp/eng-eng',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20251021',
      category: '默认',
      entryCount: 428674,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 90 * 1024 * 1024,
      fileSizeLabel: '90M',
      isVisible: true,
      autoExpand: false,
      sortIndex: 0,
    ),
  ];
  final List<String> deletedIds = <String>[];

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async => items;

  @override
  Future<void> deleteDictionary(String id) async {
    deletedIds.add(id);
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {}

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {}

  @override
  Future<void> setVisibility(String id, bool isVisible) async {}
}
