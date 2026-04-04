import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/domain/study_statistics.dart';
import 'package:shawyer_words/features/settings/domain/system_settings_opener.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

enum SettingsStatus { idle, loading, ready, failure }

class SettingsState {
  static const Object _sentinel = Object();

  const SettingsState({
    required this.status,
    required this.settings,
    this.errorMessage,
  });

  const SettingsState.idle()
    : status = SettingsStatus.idle,
      settings = const AppSettings.defaults(),
      errorMessage = null;

  final SettingsStatus status;
  final AppSettings settings;
  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    Object? errorMessage = _sentinel,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    required AppSettingsRepository repository,
    required WordKnowledgeRepository wordKnowledgeRepository,
    SystemSettingsOpener systemSettingsOpener =
        const NoopSystemSettingsOpener(),
  }) : _repository = repository,
       _wordKnowledgeRepository = wordKnowledgeRepository,
       _systemSettingsOpener = systemSettingsOpener;

  final AppSettingsRepository _repository;
  final WordKnowledgeRepository _wordKnowledgeRepository;
  final SystemSettingsOpener _systemSettingsOpener;

  SettingsState _state = const SettingsState.idle();

  SettingsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(
      status: SettingsStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final settings = await _repository.load();
      _state = _state.copyWith(
        status: SettingsStatus.ready,
        settings: settings,
        errorMessage: null,
      );
    } catch (error) {
      _state = _state.copyWith(
        status: SettingsStatus.failure,
        errorMessage: '$error',
      );
    }

    notifyListeners();
  }

  Future<void> updateAppearance(AppAppearanceMode mode) {
    return _save(_state.settings.copyWith(appearanceMode: mode));
  }

  Future<void> updateFontScale(AppFontScale scale) {
    return _save(_state.settings.copyWith(fontScale: scale));
  }

  Future<void> updateReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) {
    return _save(
      _state.settings.copyWith(
        reminderEnabled: enabled,
        reminderHour: hour,
        reminderMinute: minute,
      ),
    );
  }

  Future<void> updateMyLanguage(String language) {
    return _save(_state.settings.copyWith(myLanguage: language));
  }

  Future<void> updateThemeName(String themeName) {
    return _save(_state.settings.copyWith(themeName: themeName));
  }

  Future<void> updateDefaultPronunciation(DefaultPronunciation pronunciation) {
    return _save(_state.settings.copyWith(defaultPronunciation: pronunciation));
  }

  Future<void> updateAutoPlayPronunciation(bool enabled) {
    return _save(_state.settings.copyWith(autoPlayPronunciation: enabled));
  }

  Future<void> updateShowConversationTranslation(bool enabled) {
    return _save(
      _state.settings.copyWith(showConversationTranslationByDefault: enabled),
    );
  }

  Future<void> updateDailyStudyTarget(int target) {
    return _save(_state.settings.copyWith(dailyStudyTarget: target));
  }

  Future<void> updateDailyReviewRatio(int ratio) {
    return _save(_state.settings.copyWith(dailyReviewRatio: ratio));
  }

  Future<void> updateDailyReviewLimitMultiplier(int multiplier) {
    return _save(
      _state.settings.copyWith(dailyReviewLimitMultiplier: multiplier),
    );
  }

  Future<void> updateSmartReviewEnabled(bool enabled) {
    return _save(_state.settings.copyWith(smartReviewEnabled: enabled));
  }

  Future<void> updateStudyMode(StudyMode mode) {
    return _save(_state.settings.copyWith(studyMode: mode));
  }

  Future<void> updateWordPreviewEnabled(bool enabled) {
    return _save(_state.settings.copyWith(wordPreviewEnabled: enabled));
  }

  Future<void> updateWordPickMode(WordPickMode mode) {
    return _save(_state.settings.copyWith(wordPickMode: mode));
  }

  Future<void> updateNewWordOrder(NewWordOrder order) {
    return _save(_state.settings.copyWith(newWordOrder: order));
  }

  Future<void> updateReviewOrder(ReviewOrder order) {
    return _save(_state.settings.copyWith(reviewOrder: order));
  }

  Future<void> updateStudyPlanningMode(StudyPlanningMode mode) {
    return _save(_state.settings.copyWith(studyPlanningMode: mode));
  }

  Future<void> updateKnownWordAccelerationEnabled(bool enabled) {
    return _save(
      _state.settings.copyWith(knownWordAccelerationEnabled: enabled),
    );
  }

  Future<void> updateMultiBookEnabled(bool enabled) {
    return _save(_state.settings.copyWith(multiBookEnabled: enabled));
  }

  Future<void> updateSelectedWordBook({
    required String id,
    required String name,
  }) {
    return _save(
      _state.settings.copyWith(
        selectedWordBookId: id,
        selectedWordBookName: name,
      ),
    );
  }

  Future<void> restoreDefaultFontScale() {
    return _save(_state.settings.copyWith(fontScale: AppFontScale.normal));
  }

  Future<void> openSystemLanguageSettings() {
    return _systemSettingsOpener.openLanguageSettings();
  }

  Future<void> clearLearningProgress() async {
    await _wordKnowledgeRepository.clearAll();
    notifyListeners();
  }

  Future<StudyStatistics> loadStatistics() async {
    final records = await _wordKnowledgeRepository.loadAll();
    return _buildStatistics(records);
  }

  Future<void> _save(AppSettings settings) async {
    await _repository.save(settings);
    _state = _state.copyWith(
      status: SettingsStatus.ready,
      settings: settings,
      errorMessage: null,
    );
    notifyListeners();
  }

  StudyStatistics _buildStatistics(List<WordKnowledgeRecord> records) {
    final now = DateTime.now();
    final heatmapCounts = <String, int>{};
    for (final record in records) {
      final key = _dateKey(record.updatedAt);
      heatmapCounts[key] = (heatmapCounts[key] ?? 0) + 1;
    }

    final heatmapDays = List<HeatmapDay>.generate(84, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 83 - index));
      return HeatmapDay(date: day, count: heatmapCounts[_dateKey(day)] ?? 0);
    }, growable: false);

    final monthlyCounts = <String, int>{};
    for (final record in records) {
      final key = '${record.updatedAt.year}-${record.updatedAt.month}';
      monthlyCounts[key] = (monthlyCounts[key] ?? 0) + 1;
    }
    var runningTotal = 0;
    final vocabularyGrowth = List<MonthlyVocabularyPoint>.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index);
      final key = '${month.year}-${month.month}';
      runningTotal += monthlyCounts[key] ?? 0;
      return MonthlyVocabularyPoint(
        label: '${month.month}月',
        totalWords: runningTotal,
      );
    }, growable: false);

    final everydayTrend = List<DailyTrendPoint>.generate(7, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final dayRecords = records
          .where((record) => _dateKey(record.updatedAt) == _dateKey(day))
          .toList(growable: false);
      return DailyTrendPoint(
        label: '${day.month}/${day.day}',
        newWords: dayRecords.where((record) => !record.isKnown).length,
        reviewWords: dayRecords.where((record) => record.isKnown).length,
      );
    }, growable: false);

    return StudyStatistics(
      heatmapDays: heatmapDays,
      vocabularyGrowth: vocabularyGrowth,
      everydayTrend: everydayTrend,
    );
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
