import 'package:app_settings/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/system_settings_opener.dart';

final class PlatformSystemSettingsOpener implements SystemSettingsOpener {
  const PlatformSystemSettingsOpener();

  @override
  Future<void> openLanguageSettings() {
    return AppSettings.openAppSettings(type: AppSettingsType.settings);
  }
}
