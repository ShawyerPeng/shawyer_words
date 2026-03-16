import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

abstract class DictionaryStorage {
  Future<String> createPackageDirectories({
    required DictionaryPackageType type,
    required String id,
  });

  Future<DictionaryManifest> writeManifest(DictionaryManifest manifest);

  Future<void> deletePackage({
    required DictionaryPackageType type,
    required String id,
  });
}
