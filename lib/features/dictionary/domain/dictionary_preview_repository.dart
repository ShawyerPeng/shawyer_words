import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

abstract class DictionaryPreviewRepository {
  Future<DictionaryImportPreview> preparePreview(List<String> sourcePaths);

  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  });

  Future<WordEntry?> loadEntry({
    required DictionaryImportPreview preview,
    required String key,
  });

  Future<void> disposePreview(DictionaryImportPreview preview);
}
