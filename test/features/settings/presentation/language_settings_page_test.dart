import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_language_option.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/presentation/language_settings_page.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('shows language options and updates selection in place', (
    tester,
  ) async {
    final repository = _FakeAppSettingsRepository(
      settings: const AppSettings.defaults().copyWith(
        myLanguage: 'simplifiedChinese',
      ),
    );
    final controller = SettingsController(
      repository: repository,
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: LanguageSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('仅支持简体中文、繁体中文、English'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language-option-english')));
    await tester.pumpAndSettle();

    expect(
      appLanguageOptionFromStoredValue(repository.saved.last.myLanguage),
      AppLanguageOption.english,
    );
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({required this.settings});

  AppSettings settings;
  final List<AppSettings> saved = <AppSettings>[];

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
    saved.add(settings);
  }
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
