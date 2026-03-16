import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';

void main() {
  testWidgets('renders visible and hidden sections and filters list', (
    tester,
  ) async {
    final controller = DictionaryLibraryController(
      repository: _FakeDictionaryLibraryRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryManagementPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('显示的词库'), findsOneWidget);
    expect(find.text('隐藏的词库'), findsOneWidget);
    expect(find.text('英英词典'), findsOneWidget);
    expect(find.text('网页书签'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '英英');
    await tester.pumpAndSettle();

    expect(find.text('英英词典'), findsOneWidget);
    expect(find.text('学习笔记'), findsNothing);
  });

  testWidgets('opens detail page from chevron action', (tester) async {
    final controller = DictionaryLibraryController(
      repository: _FakeDictionaryLibraryRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DictionaryLibraryManagementPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dictionary-detail-eng-eng')));
    await tester.pumpAndSettle();

    expect(find.text('显示该词库'), findsOneWidget);
    expect(find.text('自动展开'), findsOneWidget);
  });
}

class _FakeDictionaryLibraryRepository implements DictionaryLibraryRepository {
  final List<DictionaryLibraryItem> items = <DictionaryLibraryItem>[
    const DictionaryLibraryItem(
      id: 'notes',
      name: '学习笔记',
      type: DictionaryPackageType.bundled,
      rootPath: '/tmp/notes',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20251021',
      category: '默认',
      entryCount: 120,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 1024,
      fileSizeLabel: '1K',
      isVisible: true,
      autoExpand: false,
      sortIndex: 0,
    ),
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
      sortIndex: 1,
    ),
    const DictionaryLibraryItem(
      id: 'web',
      name: '网页书签',
      type: DictionaryPackageType.imported,
      rootPath: '/tmp/web',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20260316',
      category: '自定义',
      entryCount: 0,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 0,
      fileSizeLabel: '0B',
      isVisible: false,
      autoExpand: false,
      sortIndex: 2,
    ),
  ];

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async => items;

  @override
  Future<void> deleteDictionary(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {}

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {}

  @override
  Future<void> setVisibility(String id, bool isVisible) async {}
}
