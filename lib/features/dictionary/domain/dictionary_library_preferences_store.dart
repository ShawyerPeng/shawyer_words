import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences.dart';

abstract class DictionaryLibraryPreferencesStore {
  Future<DictionaryLibraryPreferences> load();

  Future<void> save(DictionaryLibraryPreferences preferences);
}
