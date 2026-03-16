import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog_entry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

abstract class DictionaryCatalog {
  Future<List<DictionaryCatalogEntry>> listPackages({
    DictionaryPackageType? type,
  });
}
