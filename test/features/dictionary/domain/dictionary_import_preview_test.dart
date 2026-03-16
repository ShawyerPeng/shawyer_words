import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';

void main() {
  test('calculates preview paging in blocks of 1000 entries', () {
    const preview = DictionaryImportPreview(
      sourceRootPath: '/tmp/session',
      title: 'Oxford Starter',
      primaryMdxPath: '/tmp/session/main.mdx',
      metadataText: '<Dictionary Title="Oxford Starter" Description="Test" />',
      files: [
        DictionaryPreviewFile(
          path: '/tmp/session/main.mdx',
          name: 'main.mdx',
          kind: DictionaryPreviewFileKind.mdx,
          isPrimary: true,
        ),
      ],
      entryKeys: ['a', 'b', 'c'],
      totalEntries: 2505,
    );

    expect(preview.pageSize, 1000);
    expect(preview.totalPages, 3);
    expect(preview.entryRangeForPage(1), (1, 1000));
    expect(preview.entryRangeForPage(3), (2001, 2505));
  });

  test('groups page buttons in sets of ten', () {
    const preview = DictionaryImportPreview(
      sourceRootPath: '/tmp/session',
      title: 'Large Dictionary',
      primaryMdxPath: '/tmp/session/main.mdx',
      metadataText: '<Dictionary Title="Large Dictionary" />',
      files: [
        DictionaryPreviewFile(
          path: '/tmp/session/main.mdx',
          name: 'main.mdx',
          kind: DictionaryPreviewFileKind.mdx,
          isPrimary: true,
        ),
      ],
      entryKeys: [],
      totalEntries: 12000,
    );

    expect(preview.pageNumbersForGroup(1), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(preview.pageNumbersForGroup(10), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(preview.pageNumbersForGroup(11), [11, 12]);
  });
}
