import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/domain/app_theme_palette.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('app uses stored appearance and font scale settings', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(
          appearanceMode: AppAppearanceMode.dark,
          fontScale: AppFontScale.large,
          themeName: 'forest',
        ),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await settingsController.load();

    await tester.pumpWidget(
      ShawyerWordsApp(settingsController: settingsController),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme?.colorScheme.primary, isNotNull);
    expect(app.theme?.textTheme.titleMedium?.fontSize, greaterThan(16));
  });

  testWidgets('app uses stored theme palette for light mode background', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(
          appearanceMode: AppAppearanceMode.light,
          themeName: 'purple',
        ),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await settingsController.load();

    await tester.pumpWidget(
      ShawyerWordsApp(settingsController: settingsController),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.theme?.scaffoldBackgroundColor,
      appThemePaletteFor('purple').lightBackground,
    );
  });

  testWidgets('legacy default theme maps to gray palette', (tester) async {
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(
          appearanceMode: AppAppearanceMode.light,
          themeName: 'default',
        ),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await settingsController.load();

    await tester.pumpWidget(
      ShawyerWordsApp(settingsController: settingsController),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.theme?.scaffoldBackgroundColor,
      appThemePaletteFor('gray').lightBackground,
    );
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({required this.settings});

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
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
