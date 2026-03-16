import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';

abstract class DictionaryPreviewRepository {
  Future<DictionaryImportPreview> preparePreview(List<String> sourcePaths);

  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  });

  Future<void> disposePreview(DictionaryImportPreview preview);
}
