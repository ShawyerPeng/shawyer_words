enum AppLanguageOption {
  system,
  simplifiedChinese,
  traditionalChinese,
  english,
}

AppLanguageOption appLanguageOptionFromStoredValue(String? value) {
  return switch (value) {
    'system' || 'followSystem' || '跟随系统' => AppLanguageOption.system,
    'simplifiedChinese' ||
    '中文' ||
    '简体中文' => AppLanguageOption.simplifiedChinese,
    'traditionalChinese' || '繁體中文' => AppLanguageOption.traditionalChinese,
    'english' || 'English' => AppLanguageOption.english,
    _ => AppLanguageOption.system,
  };
}

String appLanguageStoredValue(AppLanguageOption option) {
  return option.name;
}

String appLanguageLabel(AppLanguageOption option) {
  return switch (option) {
    AppLanguageOption.system => '跟随系统',
    AppLanguageOption.simplifiedChinese => '简体中文',
    AppLanguageOption.traditionalChinese => '繁體中文',
    AppLanguageOption.english => 'English',
  };
}

String? appLanguageSubtitle(AppLanguageOption option) {
  return switch (option) {
    AppLanguageOption.system => '仅支持简体中文、繁体中文、English',
    _ => null,
  };
}
