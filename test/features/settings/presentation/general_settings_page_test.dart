import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/domain/system_settings_opener.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('shows general settings entries and reset font size action', (
    tester,
  ) async {
    final repository = _FakeAppSettingsRepository(
      settings: const AppSettings.defaults().copyWith(
        fontScale: AppFontScale.large,
      ),
    );
    final controller = SettingsController(
      repository: repository,
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GeneralSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的语言'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('字体大小'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('恢复默认大小'), findsOneWidget);

    await tester.tap(find.text('恢复默认大小'));
    await tester.pumpAndSettle();

    expect(repository.saved.last.fontScale, AppFontScale.normal);
  });

  testWidgets('tapping 系统语言 opens system settings', (tester) async {
    final systemSettingsOpener = _FakeSystemSettingsOpener();
    final controller = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults(),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      systemSettingsOpener: systemSettingsOpener,
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GeneralSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();

    expect(systemSettingsOpener.openCalls, 1);
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

class _FakeSystemSettingsOpener implements SystemSettingsOpener {
  int openCalls = 0;

  @override
  Future<void> openLanguageSettings() async {
    openCalls += 1;
  }
}
