import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

class DictionaryLibraryItem {
  const DictionaryLibraryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rootPath,
    required this.importedAt,
    required this.version,
    required this.category,
    required this.entryCount,
    required this.dictionaryAttribute,
    required this.fileSizeBytes,
    required this.fileSizeLabel,
    required this.isVisible,
    required this.autoExpand,
    required this.sortIndex,
  });

  final String id;
  final String name;
  final DictionaryPackageType type;
  final String rootPath;
  final String importedAt;
  final String version;
  final String category;
  final int entryCount;
  final String dictionaryAttribute;
  final int fileSizeBytes;
  final String fileSizeLabel;
  final bool isVisible;
  final bool autoExpand;
  final int sortIndex;

  String get dictionaryTypeLabel {
    return switch (type) {
      DictionaryPackageType.bundled => '系统内置词典',
      DictionaryPackageType.imported => '用户自定义词典',
    };
  }
}
