import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_language_option.dart';
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

    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('字体大小'), findsOneWidget);
    expect(find.text('系统语言'), findsOneWidget);
    expect(find.text('个性化'), findsOneWidget);
    expect(find.text('恢复默认大小'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('帮助与反馈'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('消息通知'), findsOneWidget);
    expect(find.text('数据与隐私'), findsOneWidget);
    expect(find.text('帮助与反馈'), findsOneWidget);
    expect(find.text('关于应用'), findsOneWidget);

    await tester.tap(find.text('恢复默认大小'));
    await tester.pumpAndSettle();

    expect(repository.saved.last.fontScale, AppFontScale.normal);
  });

  testWidgets('tapping 语言设置 opens language detail page', (tester) async {
    final controller = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(
          myLanguage: 'traditionalChinese',
        ),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GeneralSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('general-settings-language-tile')),
    );
    await tester.pumpAndSettle();

    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
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

    await tester.tap(find.text('系统语言'));
    await tester.pumpAndSettle();

    expect(systemSettingsOpener.openCalls, 1);
  });

  testWidgets('tapping 主题 shows popup and saves selected theme', (
    tester,
  ) async {
    final repository = _FakeAppSettingsRepository(
      settings: const AppSettings.defaults(),
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

    await tester.tap(find.byKey(const ValueKey('general-settings-theme-tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-choice-popup')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-gray')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-blue')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-purple')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-option-blue')));
    await tester.pumpAndSettle();

    expect(repository.saved.last.themeName, 'blue');
    expect(find.byKey(const ValueKey('theme-choice-popup')), findsNothing);
    expect(find.text('蓝色'), findsOneWidget);
  });

  testWidgets('legacy default theme displays as gray', (tester) async {
    final controller = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(themeName: 'default'),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GeneralSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('灰色'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('general-settings-theme-tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-option-gray')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-default')), findsNothing);
  });

  testWidgets('additional settings groups open expected pages', (tester) async {
    final controller = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults(),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GeneralSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('帮助与反馈'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('帮助与反馈'));
    await tester.pumpAndSettle();
    expect(find.text('帮助中心'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('help-center-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('关于应用'));
    await tester.pumpAndSettle();
    expect(find.text('关于应用'), findsWidgets);
    expect(find.text('查看应用版本、功能说明和产品相关信息。'), findsOneWidget);
  });

  testWidgets('language selection label follows normalized stored value', (
    tester,
  ) async {
    final controller = SettingsController(
      repository: _FakeAppSettingsRepository(
        settings: const AppSettings.defaults().copyWith(myLanguage: '中文'),
      ),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GeneralSettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(appLanguageLabel(AppLanguageOption.simplifiedChinese)),
      findsOneWidget,
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

class _FakeSystemSettingsOpener implements SystemSettingsOpener {
  int openCalls = 0;

  @override
  Future<void> openLanguageSettings() async {
    openCalls += 1;
  }

  @override
  Future<void> openNotificationSettings() async {}
}
