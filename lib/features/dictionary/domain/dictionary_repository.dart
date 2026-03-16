import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';

abstract class DictionaryRepository {
  Future<DictionaryImportResult> importDictionary(String filePath);
}
