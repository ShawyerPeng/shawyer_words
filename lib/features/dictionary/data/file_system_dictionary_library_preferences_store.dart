import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/data/dictionary_root_path_resolver.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences_store.dart';

class FileSystemDictionaryLibraryPreferencesStore
    implements DictionaryLibraryPreferencesStore {
  FileSystemDictionaryLibraryPreferencesStore({
    this.rootPath,
    DictionaryRootPathResolver? rootPathResolver,
  }) : _rootPathResolver = rootPathResolver;

  final String? rootPath;
  final DictionaryRootPathResolver? _rootPathResolver;

  @override
  Future<DictionaryLibraryPreferences> load() async {
    final file = await _preferencesFile();
    if (!await file.exists()) {
      return const DictionaryLibraryPreferences();
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    return DictionaryLibraryPreferences.fromJson(json);
  }

  @override
  Future<void> save(DictionaryLibraryPreferences preferences) async {
    final file = await _preferencesFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(preferences.toJson()),
    );
  }

  Future<File> _preferencesFile() async {
    final resolvedRoot = await _resolveRootPath();
    return File('$resolvedRoot/library_preferences.json');
  }

  Future<String> _resolveRootPath() async {
    if (rootPath != null) {
      return rootPath!;
    }
    if (_rootPathResolver != null) {
      return _rootPathResolver();
    }
    throw StateError('A dictionary root path or resolver is required.');
  }
}
