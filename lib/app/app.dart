import 'dart:io';

import 'package:flutter/material.dart' hide SearchController;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:shawyer_words/app/app_shell.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/data/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_preferences_store.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_file_picker.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/data/file_system_search_history_repository.dart';
import 'package:shawyer_words/features/search/data/installed_dictionary_word_lookup_repository.dart';
import 'package:shawyer_words/features/search/data/lexdb_word_lookup_repository.dart';
import 'package:shawyer_words/features/search/data/sample_word_lookup_repository.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/data/file_system_app_settings_repository.dart';
import 'package:shawyer_words/features/settings/data/platform_system_settings_opener.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_theme_palette.dart';
import 'package:shawyer_words/features/study/data/in_memory_study_repository.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/study_srs/data/sqlite_fsrs_repository.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_entry_lookup_repository.dart';
import 'package:shawyer_words/features/word_detail/data/lexdb_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/data/platform_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/data/sqlite_word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/data/word_group_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

typedef DictionaryFilePicker = Future<String?> Function();

class ShawyerWordsApp extends StatelessWidget {
  factory ShawyerWordsApp({
    Key? key,
    DictionaryController? controller,
    DictionaryLibraryController? dictionaryLibraryController,
    DictionaryFilePicker? pickDictionaryFile,
    SearchController? searchController,
    SettingsController? settingsController,
    StudyRepository? studyRepository,
    StudyPlanController? studyPlanController,
    FsrsRepository? fsrsRepository,
    WordDetailPageBuilder? wordDetailPageBuilder,
    WordKnowledgeRepository? wordKnowledgeRepository,
    String? lexDbPath,
    String? thingDbPath,
    String lexDbDictionaryId = 'lexdb',
    String lexDbDictionaryName = 'LexDB',
    sqflite.DatabaseFactory? lexDbDatabaseFactory,
  }) {
    final dictionaryCatalog = FileSystemDictionaryCatalog(
      rootPathResolver: _dictionaryRootPath,
    );
    final dictionaryStorage = FileSystemDictionaryStorage(
      rootPathResolver: _dictionaryRootPath,
    );
    final dictionaryLibraryRepository = _buildDictionaryLibraryRepository(
      catalog: dictionaryCatalog,
      storage: dictionaryStorage,
    );
    final resolvedWordKnowledgeRepository =
        wordKnowledgeRepository ??
        SqliteWordKnowledgeRepository(
          databasePathResolver: _wordKnowledgeDatabasePath,
        );
    final resolvedFsrsRepository =
        fsrsRepository ??
        SqliteFsrsRepository(databasePathResolver: _wordKnowledgeDatabasePath);
    final resolvedStudyRepository =
        studyRepository ?? InMemoryStudyRepository();
    final resolvedController =
        controller ??
        DictionaryController(
          dictionaryRepository: PlatformDictionaryRepository(),
          previewRepository: PlatformDictionaryPreviewRepository(),
          studyRepository: resolvedStudyRepository,
        );
    final resolvedDictionaryLibraryController =
        dictionaryLibraryController ??
        DictionaryLibraryController(repository: dictionaryLibraryRepository);
    final resolvedThingDbPath = () {
      if (thingDbPath != null && thingDbPath.trim().isNotEmpty) {
        return thingDbPath;
      }
      if (lexDbPath == null || lexDbPath.trim().isEmpty) {
        return null;
      }
      final siblingPath = '${File(lexDbPath).parent.path}/thing.db';
      return File(siblingPath).existsSync() ? siblingPath : null;
    }();
    late final WordDetailPageBuilder resolvedWordDetailPageBuilder;
    resolvedWordDetailPageBuilder =
        wordDetailPageBuilder ??
        (String word, initialEntry) => WordDetailPage(
          word: word,
          initialEntry: initialEntry,
          wordDetailPageBuilder: resolvedWordDetailPageBuilder,
          controller: WordDetailController(
            detailRepository: PlatformWordDetailRepository(
              lookupRepository: DictionaryEntryLookupRepository(
                libraryRepository: dictionaryLibraryRepository,
                catalog: dictionaryCatalog,
              ),
              lexDbRepository: lexDbPath == null
                  ? null
                  : LexDbWordDetailRepository(
                      databasePath: lexDbPath,
                      dictionaryId: lexDbDictionaryId,
                      dictionaryName: lexDbDictionaryName,
                      databaseFactory:
                          lexDbDatabaseFactory ?? sqflite.databaseFactory,
                    ),
              wordGroupRepository: resolvedThingDbPath == null
                  ? null
                  : WordGroupRepository(
                      databasePath: resolvedThingDbPath,
                      databaseFactory:
                          lexDbDatabaseFactory ?? sqflite.databaseFactory,
                    ),
            ),
            knowledgeRepository: resolvedWordKnowledgeRepository,
          ),
        );

    final resolvedPickDictionaryFile =
        pickDictionaryFile ?? PlatformDictionaryFilePicker().pickDictionaryFile;
    final resolvedSettingsController =
        settingsController ??
        SettingsController(
          repository: FileSystemAppSettingsRepository(
            rootPathResolver: _settingsRootPath,
          ),
          wordKnowledgeRepository: resolvedWordKnowledgeRepository,
          systemSettingsOpener: const PlatformSystemSettingsOpener(),
        );
    if (resolvedSettingsController.state.status == SettingsStatus.idle) {
      resolvedSettingsController.load();
    }

    return ShawyerWordsApp._(
      key: key,
      dictionaryController: resolvedController,
      dictionaryLibraryController: resolvedDictionaryLibraryController,
      pickDictionaryFile: resolvedPickDictionaryFile,
      searchController:
          searchController ??
          SearchController(
            lookupRepository: lexDbPath == null
                ? InstalledDictionaryWordLookupRepository(
                    libraryRepository: dictionaryLibraryRepository,
                    catalog: dictionaryCatalog,
                    fallbackRepository: SampleWordLookupRepository.seeded(),
                  )
                : LexDbWordLookupRepository(
                    databasePath: lexDbPath,
                    databaseFactory:
                        lexDbDatabaseFactory ?? sqflite.databaseFactory,
                  ),
            historyRepository: FileSystemSearchHistoryRepository(
              rootPathResolver: _settingsRootPath,
            ),
          ),
      settingsController: resolvedSettingsController,
      wordKnowledgeRepository: resolvedWordKnowledgeRepository,
      fsrsRepository: resolvedFsrsRepository,
      studyRepository: resolvedStudyRepository,
      studyPlanController:
          studyPlanController ??
          StudyPlanController(repository: InMemoryStudyPlanRepository.seeded()),
      wordDetailPageBuilder: resolvedWordDetailPageBuilder,
    );
  }

  const ShawyerWordsApp._({
    super.key,
    required this.dictionaryController,
    required this.dictionaryLibraryController,
    required this.pickDictionaryFile,
    required this.searchController,
    required this.settingsController,
    required this.wordKnowledgeRepository,
    required this.fsrsRepository,
    required this.studyRepository,
    required this.studyPlanController,
    required this.wordDetailPageBuilder,
  });

  final DictionaryController dictionaryController;
  final DictionaryLibraryController dictionaryLibraryController;
  final DictionaryFilePicker pickDictionaryFile;
  final SearchController searchController;
  final SettingsController settingsController;
  final WordKnowledgeRepository wordKnowledgeRepository;
  final FsrsRepository fsrsRepository;
  final StudyRepository studyRepository;
  final StudyPlanController studyPlanController;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final settings = settingsController.state.settings;
        return MaterialApp(
          title: 'Shawyer Words',
          debugShowCheckedModeBanner: false,
          themeMode: _themeModeFor(settings.appearanceMode),
          theme: _buildTheme(settings, brightness: Brightness.light),
          darkTheme: _buildTheme(settings, brightness: Brightness.dark),
          home: AppShell(
            dictionaryController: dictionaryController,
            dictionaryLibraryController: dictionaryLibraryController,
            pickDictionaryFile: pickDictionaryFile,
            searchController: searchController,
            settingsController: settingsController,
            wordKnowledgeRepository: wordKnowledgeRepository,
            fsrsRepository: fsrsRepository,
            studyPlanController: studyPlanController,
            studyRepository: studyRepository,
            wordDetailPageBuilder: wordDetailPageBuilder,
          ),
        );
      },
    );
  }
}

ThemeData _buildTheme(AppSettings settings, {required Brightness brightness}) {
  final palette = appThemePaletteFor(settings.themeName);
  final fontScale = switch (settings.fontScale) {
    AppFontScale.normal => 1.0,
    AppFontScale.medium => 1.08,
    AppFontScale.large => 1.16,
  };

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: brightness,
    ),
    fontFamily: 'Avenir Next',
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF0F1117)
        : palette.lightBackground,
    textTheme: _scaledTextTheme(
      ThemeData(brightness: brightness).textTheme,
      factor: fontScale,
      color: brightness == Brightness.dark
          ? const Color(0xFFF5F7FA)
          : const Color(0xFF1B2030),
    ),
    useMaterial3: true,
  );
}

ThemeMode _themeModeFor(AppAppearanceMode mode) {
  return switch (mode) {
    AppAppearanceMode.system => ThemeMode.system,
    AppAppearanceMode.light => ThemeMode.light,
    AppAppearanceMode.dark => ThemeMode.dark,
  };
}

TextTheme _scaledTextTheme(
  TextTheme textTheme, {
  required double factor,
  required Color color,
}) {
  TextStyle scale(TextStyle? style, double fallbackSize) {
    final resolvedStyle = style ?? TextStyle(fontSize: fallbackSize);
    return resolvedStyle.copyWith(
      color: color,
      fontSize: (resolvedStyle.fontSize ?? fallbackSize) * factor,
    );
  }

  return TextTheme(
    displayLarge: scale(textTheme.displayLarge, 57),
    displayMedium: scale(textTheme.displayMedium, 45),
    displaySmall: scale(textTheme.displaySmall, 36),
    headlineLarge: scale(textTheme.headlineLarge, 32),
    headlineMedium: scale(textTheme.headlineMedium, 28),
    headlineSmall: scale(textTheme.headlineSmall, 24),
    titleLarge: scale(textTheme.titleLarge, 22),
    titleMedium: scale(textTheme.titleMedium, 16),
    titleSmall: scale(textTheme.titleSmall, 14),
    bodyLarge: scale(textTheme.bodyLarge, 16),
    bodyMedium: scale(textTheme.bodyMedium, 14),
    bodySmall: scale(textTheme.bodySmall, 12),
    labelLarge: scale(textTheme.labelLarge, 14),
    labelMedium: scale(textTheme.labelMedium, 12),
    labelSmall: scale(textTheme.labelSmall, 11),
  );
}

DictionaryLibraryRepository _buildDictionaryLibraryRepository({
  required DictionaryCatalog catalog,
  required DictionaryStorage storage,
}) {
  return FileSystemDictionaryLibraryRepository(
    catalog: catalog,
    preferencesStore: FileSystemDictionaryLibraryPreferencesStore(
      rootPathResolver: _dictionaryRootPath,
    ),
    storage: storage,
    bundledRegistry: SeededBundledDictionaryRegistry(
      rootPath: '',
      storage: storage,
      seeds: _bundledDictionarySeeds,
    ),
  );
}

const List<BundledDictionarySeed> _bundledDictionarySeeds =
    <BundledDictionarySeed>[
      BundledDictionarySeed(
        id: 'notes',
        name: '学习笔记',
        version: '20251021',
        category: '默认',
        entryCount: 120,
        dictionaryAttribute: '本地词典',
        fileSizeBytes: 8 * 1024 * 1024,
      ),
      BundledDictionarySeed(
        id: 'eng-zh',
        name: '英汉－汉英词典',
        version: '20251021',
        category: '默认',
        entryCount: 354021,
        dictionaryAttribute: '本地词典',
        fileSizeBytes: 72 * 1024 * 1024,
      ),
      BundledDictionarySeed(
        id: 'synonyms',
        name: '近义、反义、联想词',
        version: '20251021',
        category: '默认',
        entryCount: 146212,
        dictionaryAttribute: '本地词典',
        fileSizeBytes: 36 * 1024 * 1024,
      ),
      BundledDictionarySeed(
        id: 'phrasebook',
        name: '词组｜习惯用语',
        version: '20251021',
        category: '默认',
        entryCount: 88432,
        dictionaryAttribute: '本地词典',
        fileSizeBytes: 28 * 1024 * 1024,
      ),
      BundledDictionarySeed(
        id: 'example-bank',
        name: '常用例句库',
        version: '20251021',
        category: '默认',
        entryCount: 163540,
        dictionaryAttribute: '本地词典',
        fileSizeBytes: 41 * 1024 * 1024,
      ),
      BundledDictionarySeed(
        id: 'eng-eng',
        name: '英英词典',
        version: '20251021',
        category: '默认',
        entryCount: 428674,
        dictionaryAttribute: '本地词典',
        fileSizeBytes: 90 * 1024 * 1024,
      ),
    ];

Future<String> _dictionaryRootPath() async {
  final supportDirectory = await getApplicationSupportDirectory();
  return '${supportDirectory.path}/dictionaries';
}

Future<String> _wordKnowledgeDatabasePath() async {
  final supportDirectory = await getApplicationSupportDirectory();
  return '${supportDirectory.path}/word_knowledge.db';
}

Future<String> _settingsRootPath() async {
  final supportDirectory = await getApplicationSupportDirectory();
  return '${supportDirectory.path}/settings';
}
