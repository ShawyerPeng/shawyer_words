import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

class DictionaryCatalogEntry {
  const DictionaryCatalogEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.rootPath,
    required this.importedAt,
    this.entryCount,
    this.version,
    this.category,
    this.dictionaryAttribute,
    this.fileSizeBytes,
  });

  final String id;
  final String name;
  final DictionaryPackageType type;
  final String rootPath;
  final String importedAt;
  final int? entryCount;
  final String? version;
  final String? category;
  final String? dictionaryAttribute;
  final int? fileSizeBytes;
}
