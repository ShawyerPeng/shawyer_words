abstract interface class SystemSettingsOpener {
  Future<void> openLanguageSettings();

  Future<void> openNotificationSettings();
}

final class NoopSystemSettingsOpener implements SystemSettingsOpener {
  const NoopSystemSettingsOpener();

  @override
  Future<void> openLanguageSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}
}
