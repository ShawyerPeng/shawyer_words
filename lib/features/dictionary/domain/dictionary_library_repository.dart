import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';

abstract class DictionaryLibraryRepository {
  Future<List<DictionaryLibraryItem>> loadLibraryItems();

  Future<void> reorderVisible(List<String> visibleIds);

  Future<void> deleteDictionary(String id);

  Future<void> setVisibility(String id, bool isVisible);

  Future<void> setAutoExpand(String id, bool autoExpand);
}
