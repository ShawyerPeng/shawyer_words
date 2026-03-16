import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

class BundledDictionarySeed {
  const BundledDictionarySeed({
    required this.id,
    required this.name,
    required this.version,
    required this.category,
    required this.entryCount,
    required this.dictionaryAttribute,
    required this.fileSizeBytes,
  });

  final String id;
  final String name;
  final String version;
  final String category;
  final int entryCount;
  final String dictionaryAttribute;
  final int fileSizeBytes;
}

abstract class BundledDictionaryRegistry {
  Future<List<DictionaryPackage>> sync();
}
