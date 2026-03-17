import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';

class FileSystemAppSettingsRepository implements AppSettingsRepository {
  FileSystemAppSettingsRepository({
    required Future<String> Function() rootPathResolver,
  }) : _rootPathResolver = rootPathResolver;

  final Future<String> Function() _rootPathResolver;

  @override
  Future<AppSettings> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return const AppSettings.defaults();
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return const AppSettings.defaults();
    }
    return AppSettings.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }

  Future<File> _settingsFile() async {
    final rootPath = await _rootPathResolver();
    return File('$rootPath/app_settings.json');
  }
}
