abstract interface class SystemSettingsOpener {
  Future<void> openLanguageSettings();
}

final class NoopSystemSettingsOpener implements SystemSettingsOpener {
  const NoopSystemSettingsOpener();

  @override
  Future<void> openLanguageSettings() async {}
}
