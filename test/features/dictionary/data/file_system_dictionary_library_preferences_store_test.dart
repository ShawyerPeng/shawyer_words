import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_preferences_store.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences.dart';

void main() {
  late Directory tempRoot;
  late FileSystemDictionaryLibraryPreferencesStore store;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'dictionary_library_preferences_store_test',
    );
    store = FileSystemDictionaryLibraryPreferencesStore(rootPath: tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('returns default preferences when no file exists', () async {
    final preferences = await store.load();

    expect(preferences.displayOrder, isEmpty);
    expect(preferences.hiddenIds, isEmpty);
    expect(preferences.autoExpandIds, isEmpty);
    expect(preferences.selectedDictionaryId, isNull);
  });

  test('saves and reloads library preferences', () async {
    const preferences = DictionaryLibraryPreferences(
      displayOrder: <String>['a', 'b', 'c'],
      hiddenIds: <String>['c'],
      autoExpandIds: <String>['b'],
      selectedDictionaryId: 'a',
    );

    await store.save(preferences);

    final file = File('${tempRoot.path}/library_preferences.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    expect(decoded['selectedDictionaryId'], 'a');

    final loaded = await store.load();
    expect(loaded.displayOrder, ['a', 'b', 'c']);
    expect(loaded.hiddenIds, ['c']);
    expect(loaded.autoExpandIds, ['b']);
    expect(loaded.selectedDictionaryId, 'a');
  });
}
