import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  group('SettingsController', () {
    test('loads saved settings into ready state', () async {
      final controller = SettingsController(
        repository: _FakeAppSettingsRepository(
          stored: const AppSettings(
            myLanguage: 'English',
            appearanceMode: AppAppearanceMode.dark,
            themeName: 'forest',
            fontScale: AppFontScale.medium,
            defaultPronunciation: DefaultPronunciation.us,
            autoPlayPronunciation: false,
            showConversationTranslationByDefault: false,
            dailyStudyTarget: 30,
            reminderEnabled: true,
            reminderHour: 8,
            reminderMinute: 15,
            selectedWordBookId: 'cet4',
            selectedWordBookName: '四级核心词汇',
          ),
        ),
        wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await controller.load();

      expect(controller.state.status, SettingsStatus.ready);
      expect(controller.state.settings.themeName, 'forest');
      expect(controller.state.settings.reminderHour, 8);
    });

    test('update methods persist changes', () async {
      final repository = _FakeAppSettingsRepository();
      final controller = SettingsController(
        repository: repository,
        wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await controller.load();
      await controller.updateAppearance(AppAppearanceMode.dark);
      await controller.updateFontScale(AppFontScale.large);
      await controller.updateReminder(enabled: true, hour: 6, minute: 50);

      expect(
        repository.savedSettings.last.appearanceMode,
        AppAppearanceMode.dark,
      );
      expect(repository.savedSettings.last.fontScale, AppFontScale.large);
      expect(repository.savedSettings.last.reminderEnabled, isTrue);
      expect(repository.savedSettings.last.reminderHour, 6);
      expect(repository.savedSettings.last.reminderMinute, 50);
    });

    test('clearLearningProgress clears knowledge records', () async {
      final knowledgeRepository = _FakeWordKnowledgeRepository();
      final controller = SettingsController(
        repository: _FakeAppSettingsRepository(),
        wordKnowledgeRepository: knowledgeRepository,
      );

      await controller.load();
      await controller.clearLearningProgress();

      expect(knowledgeRepository.clearAllCalls, 1);
    });
  });
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({this.stored = const AppSettings.defaults()});

  AppSettings stored;
  final List<AppSettings> savedSettings = <AppSettings>[];

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
    savedSettings.add(settings);
  }
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  int clearAllCalls = 0;

  @override
  Future<void> clearAll() async {
    clearAllCalls += 1;
  }

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
