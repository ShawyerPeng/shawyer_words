import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

enum DictionaryPreviewFileKind { mdx, mdd, css, js, resource }

class DictionaryPreviewFile {
  const DictionaryPreviewFile({
    required this.path,
    required this.name,
    required this.kind,
    this.isPrimary = false,
  });

  final String path;
  final String name;
  final DictionaryPreviewFileKind kind;
  final bool isPrimary;
}

class DictionaryImportPreview {
  const DictionaryImportPreview({
    required this.sourceRootPath,
    required this.title,
    required this.primaryMdxPath,
    required this.metadataText,
    required this.files,
    required this.entryKeys,
    required this.totalEntries,
    this.pageSize = 1000,
  });

  final String sourceRootPath;
  final String title;
  final String primaryMdxPath;
  final String metadataText;
  final List<DictionaryPreviewFile> files;
  final List<String> entryKeys;
  final int totalEntries;
  final int pageSize;

  int get totalPages {
    if (totalEntries == 0) {
      return 0;
    }
    return ((totalEntries - 1) ~/ pageSize) + 1;
  }

  (int, int) entryRangeForPage(int pageNumber) {
    if (totalEntries == 0) {
      return (0, 0);
    }
    final normalizedPage = pageNumber.clamp(1, totalPages);
    final start = ((normalizedPage - 1) * pageSize) + 1;
    final end = (normalizedPage * pageSize).clamp(0, totalEntries);
    return (start, end);
  }

  List<int> pageNumbersForGroup(int pageNumber) {
    if (totalPages == 0) {
      return const <int>[];
    }
    final normalizedPage = pageNumber.clamp(1, totalPages);
    final start = (((normalizedPage - 1) ~/ 10) * 10) + 1;
    final end = (start + 9).clamp(0, totalPages);
    return [for (var page = start; page <= end; page += 1) page];
  }
}

class DictionaryPreviewPage {
  const DictionaryPreviewPage({
    required this.pageNumber,
    required this.entries,
  });

  final int pageNumber;
  final List<WordEntry> entries;
}
