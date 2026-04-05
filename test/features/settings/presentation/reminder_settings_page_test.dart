import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/domain/system_settings_opener.dart';
import 'package:shawyer_words/features/settings/presentation/reminder_settings_page.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('enabling app reminder opens notification settings', (
    tester,
  ) async {
    final repository = _FakeAppSettingsRepository();
    final systemSettingsOpener = _FakeSystemSettingsOpener();
    final controller = SettingsController(
      repository: repository,
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      systemSettingsOpener: systemSettingsOpener,
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: ReminderSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository.saved.last.reminderEnabled, isTrue);
    expect(systemSettingsOpener.openNotificationCalls, 1);
  });

  testWidgets('tapping reminder time saves picked time', (tester) async {
    final repository = _FakeAppSettingsRepository();
    final controller = SettingsController(
      repository: repository,
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      systemSettingsOpener: _FakeSystemSettingsOpener(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ReminderSettingsPage(
          controller: controller,
          pickTime: (context, initialTime) async =>
              const TimeOfDay(hour: 7, minute: 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('提醒时间'));
    await tester.pumpAndSettle();

    expect(repository.saved.last.reminderHour, 7);
    expect(repository.saved.last.reminderMinute, 30);
    expect(find.text('07:30'), findsOneWidget);
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository();

  AppSettings settings = const AppSettings.defaults();
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
  int openNotificationCalls = 0;

  @override
  Future<void> openLanguageSettings() async {}

  @override
  Future<void> openNotificationSettings() async {
    openNotificationCalls += 1;
  }
}
