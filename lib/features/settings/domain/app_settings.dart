enum AppAppearanceMode { system, light, dark }

enum AppFontScale { normal, medium, large }

enum DefaultPronunciation { uk, us }

enum StudyMode { easy, fast, intensive, phonics }

enum WordPickMode { system, manual }

enum NewWordOrder { unit, alphabetAsc, alphabetDesc, frequency, random }

enum ReviewOrder { reviewFirst, learnFirst, mixed }

enum StudyPlanningMode { balanced, reviewFirst, sprint }

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
    required this.dailyReviewRatio,
    required this.dailyReviewLimitMultiplier,
    required this.smartReviewEnabled,
    required this.studyMode,
    required this.wordPreviewEnabled,
    required this.wordPickMode,
    required this.newWordOrder,
    required this.reviewOrder,
    required this.studyPlanningMode,
    required this.knownWordAccelerationEnabled,
    required this.multiBookEnabled,
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
      dailyReviewRatio = 4,
      dailyReviewLimitMultiplier = 5,
      smartReviewEnabled = true,
      studyMode = StudyMode.easy,
      wordPreviewEnabled = false,
      wordPickMode = WordPickMode.system,
      newWordOrder = NewWordOrder.unit,
      reviewOrder = ReviewOrder.reviewFirst,
      studyPlanningMode = StudyPlanningMode.balanced,
      knownWordAccelerationEnabled = true,
      multiBookEnabled = false,
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
  final int dailyReviewRatio;
  final int dailyReviewLimitMultiplier;
  final bool smartReviewEnabled;
  final StudyMode studyMode;
  final bool wordPreviewEnabled;
  final WordPickMode wordPickMode;
  final NewWordOrder newWordOrder;
  final ReviewOrder reviewOrder;
  final StudyPlanningMode studyPlanningMode;
  final bool knownWordAccelerationEnabled;
  final bool multiBookEnabled;
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
    int? dailyReviewRatio,
    int? dailyReviewLimitMultiplier,
    bool? smartReviewEnabled,
    StudyMode? studyMode,
    bool? wordPreviewEnabled,
    WordPickMode? wordPickMode,
    NewWordOrder? newWordOrder,
    ReviewOrder? reviewOrder,
    StudyPlanningMode? studyPlanningMode,
    bool? knownWordAccelerationEnabled,
    bool? multiBookEnabled,
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
      dailyReviewRatio: dailyReviewRatio ?? this.dailyReviewRatio,
      dailyReviewLimitMultiplier:
          dailyReviewLimitMultiplier ?? this.dailyReviewLimitMultiplier,
      smartReviewEnabled: smartReviewEnabled ?? this.smartReviewEnabled,
      studyMode: studyMode ?? this.studyMode,
      wordPreviewEnabled: wordPreviewEnabled ?? this.wordPreviewEnabled,
      wordPickMode: wordPickMode ?? this.wordPickMode,
      newWordOrder: newWordOrder ?? this.newWordOrder,
      reviewOrder: reviewOrder ?? this.reviewOrder,
      studyPlanningMode: studyPlanningMode ?? this.studyPlanningMode,
      knownWordAccelerationEnabled:
          knownWordAccelerationEnabled ?? this.knownWordAccelerationEnabled,
      multiBookEnabled: multiBookEnabled ?? this.multiBookEnabled,
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
      'daily_review_ratio': dailyReviewRatio,
      'daily_review_limit_multiplier': dailyReviewLimitMultiplier,
      'smart_review_enabled': smartReviewEnabled,
      'study_mode': studyMode.name,
      'word_preview_enabled': wordPreviewEnabled,
      'word_pick_mode': wordPickMode.name,
      'new_word_order': newWordOrder.name,
      'review_order': reviewOrder.name,
      'study_planning_mode': studyPlanningMode.name,
      'known_word_acceleration_enabled': knownWordAccelerationEnabled,
      'multi_book_enabled': multiBookEnabled,
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
      dailyReviewRatio: _dailyReviewRatioFromJson(json['daily_review_ratio']),
      dailyReviewLimitMultiplier: _dailyReviewLimitMultiplierFromJson(
        json['daily_review_limit_multiplier'],
      ),
      smartReviewEnabled: json['smart_review_enabled'] as bool? ?? true,
      studyMode: _studyModeFromName(json['study_mode'] as String?),
      wordPreviewEnabled: json['word_preview_enabled'] as bool? ?? false,
      wordPickMode: _wordPickModeFromName(json['word_pick_mode'] as String?),
      newWordOrder: _newWordOrderFromName(json['new_word_order'] as String?),
      reviewOrder: _reviewOrderFromName(json['review_order'] as String?),
      studyPlanningMode: _studyPlanningModeFromName(
        json['study_planning_mode'] as String?,
      ),
      knownWordAccelerationEnabled:
          json['known_word_acceleration_enabled'] as bool? ?? true,
      multiBookEnabled: json['multi_book_enabled'] as bool? ?? false,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderHour: json['reminder_hour'] as int? ?? 20,
      reminderMinute: json['reminder_minute'] as int? ?? 0,
      selectedWordBookId: json['selected_word_book_id'] as String? ?? '',
      selectedWordBookName: json['selected_word_book_name'] as String? ?? '',
    );
  }

  static int _dailyReviewLimitMultiplierFromJson(Object? value) {
    final multiplier = switch (value) {
      final int v => v,
      final String v => int.tryParse(v),
      _ => null,
    };
    if (multiplier == null) {
      return 5;
    }
    return multiplier.clamp(0, 5);
  }

  static int _dailyReviewRatioFromJson(Object? value) {
    final ratio = switch (value) {
      final int v => v,
      final String v => int.tryParse(v),
      _ => null,
    };
    if (ratio == null) {
      return 4;
    }
    return ratio.clamp(1, 4);
  }

  static StudyMode _studyModeFromName(String? name) {
    return StudyMode.values.firstWhere(
      (item) => item.name == name,
      orElse: () => StudyMode.easy,
    );
  }

  static WordPickMode _wordPickModeFromName(String? name) {
    return WordPickMode.values.firstWhere(
      (item) => item.name == name,
      orElse: () => WordPickMode.system,
    );
  }

  static NewWordOrder _newWordOrderFromName(String? name) {
    return NewWordOrder.values.firstWhere(
      (item) => item.name == name,
      orElse: () => NewWordOrder.unit,
    );
  }

  static ReviewOrder _reviewOrderFromName(String? name) {
    return ReviewOrder.values.firstWhere(
      (item) => item.name == name,
      orElse: () => ReviewOrder.reviewFirst,
    );
  }

  static StudyPlanningMode _studyPlanningModeFromName(String? name) {
    return StudyPlanningMode.values.firstWhere(
      (item) => item.name == name,
      orElse: () => StudyPlanningMode.balanced,
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
        other.dailyReviewRatio == dailyReviewRatio &&
        other.dailyReviewLimitMultiplier == dailyReviewLimitMultiplier &&
        other.smartReviewEnabled == smartReviewEnabled &&
        other.studyMode == studyMode &&
        other.wordPreviewEnabled == wordPreviewEnabled &&
        other.wordPickMode == wordPickMode &&
        other.newWordOrder == newWordOrder &&
        other.reviewOrder == reviewOrder &&
        other.studyPlanningMode == studyPlanningMode &&
        other.knownWordAccelerationEnabled == knownWordAccelerationEnabled &&
        other.multiBookEnabled == multiBookEnabled &&
        other.reminderEnabled == reminderEnabled &&
        other.reminderHour == reminderHour &&
        other.reminderMinute == reminderMinute &&
        other.selectedWordBookId == selectedWordBookId &&
        other.selectedWordBookName == selectedWordBookName;
  }

  @override
  int get hashCode => Object.hashAll([
    myLanguage,
    appearanceMode,
    themeName,
    fontScale,
    defaultPronunciation,
    autoPlayPronunciation,
    showConversationTranslationByDefault,
    dailyStudyTarget,
    dailyReviewRatio,
    dailyReviewLimitMultiplier,
    smartReviewEnabled,
    studyMode,
    wordPreviewEnabled,
    wordPickMode,
    newWordOrder,
    reviewOrder,
    studyPlanningMode,
    knownWordAccelerationEnabled,
    multiBookEnabled,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    selectedWordBookId,
    selectedWordBookName,
  ]);
}
