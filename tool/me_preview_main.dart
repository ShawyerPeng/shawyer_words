import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';
import 'package:shawyer_words/features/me/presentation/me_page.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = SettingsController(
    repository: _FakeAppSettingsRepository(),
    wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
  );
  await controller.load();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: MePage(
          settingsController: controller,
          dictionaryLibraryManagementPageBuilder: (context) =>
              const DictionaryLibraryManagementPage(controller: null),
          showCloseButton: false,
        ),
      ),
    ),
  );
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings.defaults();

  @override
  Future<void> save(AppSettings settings) async {}
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  @override
  Future<void> clearAll() async {}

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async => null;

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async =>
      const <WordKnowledgeRecord>[];

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {}

  @override
  Future<void> save(WordKnowledgeRecord record) async {}

  @override
  Future<void> saveNote(String word, String note) async {}

  @override
  Future<void> toggleFavorite(String word) async {}
}
