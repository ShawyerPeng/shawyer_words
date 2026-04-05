import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/data/file_system_app_settings_repository.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';

void main() {
  group('FileSystemAppSettingsRepository', () {
    late Directory tempDirectory;
    late FileSystemAppSettingsRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('app-settings-');
      repository = FileSystemAppSettingsRepository(
        rootPathResolver: () async => tempDirectory.path,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('returns default settings when file is missing', () async {
      final settings = await repository.load();

      expect(settings, const AppSettings.defaults());
    });

    test('persists and reloads settings', () async {
      final expected = const AppSettings.defaults().copyWith(
        appearanceMode: AppAppearanceMode.dark,
        themeName: 'forest',
        fontScale: AppFontScale.large,
        defaultPronunciation: DefaultPronunciation.us,
        autoPlayPronunciation: false,
        showConversationTranslationByDefault: false,
        dailyStudyTarget: 35,
        studyPlanningMode: StudyPlanningMode.sprint,
        reminderEnabled: true,
        reminderHour: 7,
        reminderMinute: 45,
        selectedWordBookId: 'cet4-core',
        selectedWordBookName: '四级核心词汇',
      );

      await repository.save(expected);

      final actual = await repository.load();

      expect(actual, expected.copyWith(themeName: 'green'));
    });

    test('normalizes legacy default theme from stored json', () async {
      final settingsFile = File('${tempDirectory.path}/app_settings.json');
      await settingsFile.parent.create(recursive: true);
      await settingsFile.writeAsString('{"theme_name":"default"}');

      final actual = await repository.load();

      expect(actual.themeName, 'gray');
    });
  });
}
