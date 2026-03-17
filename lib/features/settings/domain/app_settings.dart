enum AppAppearanceMode { system, light, dark }

enum AppFontScale { normal, medium, large }

enum DefaultPronunciation { uk, us }

class AppSettings {
  const AppSettings({
    required this.myLanguage,
    required this.appearanceMode,
    required this.themeName,
    required this.fontScale,
    required this.defaultPronunciation,
    required this.autoPlayPronunciation,
    required this.showConversationTranslationByDefault,
    required this.dailyStudyTarget,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.selectedWordBookId,
    required this.selectedWordBookName,
  });

  const AppSettings.defaults()
    : myLanguage = '中文',
      appearanceMode = AppAppearanceMode.system,
      themeName = 'default',
      fontScale = AppFontScale.normal,
      defaultPronunciation = DefaultPronunciation.uk,
      autoPlayPronunciation = true,
      showConversationTranslationByDefault = true,
      dailyStudyTarget = 20,
      reminderEnabled = false,
      reminderHour = 20,
      reminderMinute = 0,
      selectedWordBookId = '',
      selectedWordBookName = '';

  final String myLanguage;
  final AppAppearanceMode appearanceMode;
  final String themeName;
  final AppFontScale fontScale;
  final DefaultPronunciation defaultPronunciation;
  final bool autoPlayPronunciation;
  final bool showConversationTranslationByDefault;
  final int dailyStudyTarget;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final String selectedWordBookId;
  final String selectedWordBookName;

  AppSettings copyWith({
    String? myLanguage,
    AppAppearanceMode? appearanceMode,
    String? themeName,
    AppFontScale? fontScale,
    DefaultPronunciation? defaultPronunciation,
    bool? autoPlayPronunciation,
    bool? showConversationTranslationByDefault,
    int? dailyStudyTarget,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? selectedWordBookId,
    String? selectedWordBookName,
  }) {
    return AppSettings(
      myLanguage: myLanguage ?? this.myLanguage,
      appearanceMode: appearanceMode ?? this.appearanceMode,
      themeName: themeName ?? this.themeName,
      fontScale: fontScale ?? this.fontScale,
      defaultPronunciation: defaultPronunciation ?? this.defaultPronunciation,
      autoPlayPronunciation:
          autoPlayPronunciation ?? this.autoPlayPronunciation,
      showConversationTranslationByDefault:
          showConversationTranslationByDefault ??
          this.showConversationTranslationByDefault,
      dailyStudyTarget: dailyStudyTarget ?? this.dailyStudyTarget,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      selectedWordBookId: selectedWordBookId ?? this.selectedWordBookId,
      selectedWordBookName: selectedWordBookName ?? this.selectedWordBookName,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'my_language': myLanguage,
      'appearance_mode': appearanceMode.name,
      'theme_name': themeName,
      'font_scale': fontScale.name,
      'default_pronunciation': defaultPronunciation.name,
      'auto_play_pronunciation': autoPlayPronunciation,
      'show_conversation_translation_by_default':
          showConversationTranslationByDefault,
      'daily_study_target': dailyStudyTarget,
      'reminder_enabled': reminderEnabled,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'selected_word_book_id': selectedWordBookId,
      'selected_word_book_name': selectedWordBookName,
    };
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      myLanguage: json['my_language'] as String? ?? '中文',
      appearanceMode: _appearanceModeFromName(
        json['appearance_mode'] as String?,
      ),
      themeName: json['theme_name'] as String? ?? 'default',
      fontScale: _fontScaleFromName(json['font_scale'] as String?),
      defaultPronunciation: _defaultPronunciationFromName(
        json['default_pronunciation'] as String?,
      ),
      autoPlayPronunciation: json['auto_play_pronunciation'] as bool? ?? true,
      showConversationTranslationByDefault:
          json['show_conversation_translation_by_default'] as bool? ?? true,
      dailyStudyTarget: json['daily_study_target'] as int? ?? 20,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderHour: json['reminder_hour'] as int? ?? 20,
      reminderMinute: json['reminder_minute'] as int? ?? 0,
      selectedWordBookId: json['selected_word_book_id'] as String? ?? '',
      selectedWordBookName: json['selected_word_book_name'] as String? ?? '',
    );
  }

  static AppAppearanceMode _appearanceModeFromName(String? name) {
    return AppAppearanceMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => AppAppearanceMode.system,
    );
  }

  static AppFontScale _fontScaleFromName(String? name) {
    return AppFontScale.values.firstWhere(
      (scale) => scale.name == name,
      orElse: () => AppFontScale.normal,
    );
  }

  static DefaultPronunciation _defaultPronunciationFromName(String? name) {
    return DefaultPronunciation.values.firstWhere(
      (item) => item.name == name,
      orElse: () => DefaultPronunciation.uk,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.myLanguage == myLanguage &&
        other.appearanceMode == appearanceMode &&
        other.themeName == themeName &&
        other.fontScale == fontScale &&
        other.defaultPronunciation == defaultPronunciation &&
        other.autoPlayPronunciation == autoPlayPronunciation &&
        other.showConversationTranslationByDefault ==
            showConversationTranslationByDefault &&
        other.dailyStudyTarget == dailyStudyTarget &&
        other.reminderEnabled == reminderEnabled &&
        other.reminderHour == reminderHour &&
        other.reminderMinute == reminderMinute &&
        other.selectedWordBookId == selectedWordBookId &&
        other.selectedWordBookName == selectedWordBookName;
  }

  @override
  int get hashCode => Object.hash(
    myLanguage,
    appearanceMode,
    themeName,
    fontScale,
    defaultPronunciation,
    autoPlayPronunciation,
    showConversationTranslationByDefault,
    dailyStudyTarget,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    selectedWordBookId,
    selectedWordBookName,
  );
}
