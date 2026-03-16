import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

abstract class DictionaryPackageImporter {
  Future<DictionaryPackage> importPackage(String sourcePath);
}
