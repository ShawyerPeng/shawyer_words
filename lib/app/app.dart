import 'package:flutter/material.dart' hide SearchController;
import 'package:path_provider/path_provider.dart';
import 'package:shawyer_words/app/app_shell.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/data/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_preferences_store.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/data/dictionary_word_lookup_repository.dart';
import 'package:shawyer_words/features/search/data/in_memory_search_history_repository.dart';
import 'package:shawyer_words/features/search/data/sample_word_lookup_repository.dart';
import 'package:shawyer_words/features/study/data/in_memory_study_repository.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_entry_lookup_repository.dart';
import 'package:shawyer_words/features/word_detail/data/platform_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/data/sqlite_word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

typedef DictionaryFilePicker = Future<String?> Function();

class ShawyerWordsApp extends StatelessWidget {
  factory ShawyerWordsApp({
    Key? key,
    DictionaryController? controller,
    DictionaryLibraryController? dictionaryLibraryController,
    DictionaryFilePicker? pickDictionaryFile,
    SearchController? searchController,
    StudyRepository? studyRepository,
    StudyPlanController? studyPlanController,
    WordDetailPageBuilder? wordDetailPageBuilder,
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
    final wordKnowledgeRepository = SqliteWordKnowledgeRepository(
      databasePathResolver: _wordKnowledgeDatabasePath,
    );
    final resolvedStudyRepository = studyRepository ?? InMemoryStudyRepository();
    final resolvedController =
        controller ??
        DictionaryController(
          dictionaryRepository: PlatformDictionaryRepository(),
          studyRepository: resolvedStudyRepository,
        );
    final resolvedDictionaryLibraryController =
        dictionaryLibraryController ??
        DictionaryLibraryController(repository: dictionaryLibraryRepository);
    final resolvedWordDetailPageBuilder =
        wordDetailPageBuilder ??
        (String word, initialEntry) => WordDetailPage(
          word: word,
          initialEntry: initialEntry,
          controller: WordDetailController(
            detailRepository: PlatformWordDetailRepository(
              lookupRepository: DictionaryEntryLookupRepository(
                libraryRepository: dictionaryLibraryRepository,
                catalog: dictionaryCatalog,
              ),
            ),
            knowledgeRepository: wordKnowledgeRepository,
          ),
        );

    return ShawyerWordsApp._(
      key: key,
      dictionaryLibraryController: resolvedDictionaryLibraryController,
      searchController:
          searchController ??
          SearchController(
            lookupRepository: DictionaryWordLookupRepository(
              dictionaryController: resolvedController,
              fallbackRepository: SampleWordLookupRepository.seeded(),
            ),
            historyRepository: InMemorySearchHistoryRepository(),
          ),
      studyRepository: resolvedStudyRepository,
      studyPlanController:
          studyPlanController ??
          StudyPlanController(repository: InMemoryStudyPlanRepository.seeded()),
      wordDetailPageBuilder: resolvedWordDetailPageBuilder,
    );
  }

  const ShawyerWordsApp._({
    super.key,
    required this.dictionaryLibraryController,
    required this.searchController,
    required this.studyRepository,
    required this.studyPlanController,
    required this.wordDetailPageBuilder,
  });

  final DictionaryLibraryController dictionaryLibraryController;
  final SearchController searchController;
  final StudyRepository studyRepository;
  final StudyPlanController studyPlanController;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0BB58A),
        brightness: Brightness.light,
      ),
      fontFamily: 'Avenir Next',
      scaffoldBackgroundColor: const Color(0xFFF3F5FA),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF1B2030),
        displayColor: const Color(0xFF1B2030),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Shawyer Words',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: AppShell(
        dictionaryLibraryController: dictionaryLibraryController,
        searchController: searchController,
        studyPlanController: studyPlanController,
        studyRepository: studyRepository,
        wordDetailPageBuilder: wordDetailPageBuilder,
      ),
    );
  }
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

const List<BundledDictionarySeed> _bundledDictionarySeeds = <BundledDictionarySeed>[
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
