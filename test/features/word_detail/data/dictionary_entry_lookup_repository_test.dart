import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog_entry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_entry_lookup_repository.dart';
import 'package:shawyer_words/features/word_detail/data/lexdb_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/data/platform_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';

void main() {
  group('DictionaryEntryLookupRepository', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp(
        'dictionary-entry-lookup-test-',
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('queries only visible dictionaries in configured order', () async {
      final packages = <DictionaryPackage>[
        await _writePackage(tempRoot.path, id: 'alpha', name: 'Alpha'),
        await _writePackage(tempRoot.path, id: 'beta', name: 'Beta'),
        await _writePackage(tempRoot.path, id: 'gamma', name: 'Gamma'),
      ];
      final recordedPaths = <String>[];
      final repository = DictionaryEntryLookupRepository(
        libraryRepository: _FakeDictionaryLibraryRepository(
          items: <DictionaryLibraryItem>[
            _libraryItem(packages[2], isVisible: true, sortIndex: 0),
            _libraryItem(packages[0], isVisible: true, sortIndex: 1),
            _libraryItem(packages[1], isVisible: false, sortIndex: 2),
          ],
        ),
        catalog: _FakeDictionaryCatalog(packages),
        readerFactory: (path) => _LookupReader(
          path: path,
          onLookup: (word) {
            recordedPaths.add(path);
            return '<div class="definition">$word in $path</div>';
          },
        ),
      );

      final details = await repository.lookupAcrossVisibleDictionaries(
        'abandon',
      );

      expect(recordedPaths, <String>[packages[2].mdxPath, packages[0].mdxPath]);
      expect(details.map((detail) => detail.dictionaryId).toList(), <String>[
        'gamma',
        'alpha',
      ]);
      expect(details.every((detail) => detail.dictionaryId != 'beta'), isTrue);
    });

    test(
      'keeps successful dictionary hits when one dictionary fails',
      () async {
        final packages = <DictionaryPackage>[
          await _writePackage(tempRoot.path, id: 'working', name: 'Working'),
          await _writePackage(tempRoot.path, id: 'broken', name: 'Broken'),
        ];
        final repository = DictionaryEntryLookupRepository(
          libraryRepository: _FakeDictionaryLibraryRepository(
            items: <DictionaryLibraryItem>[
              _libraryItem(packages[0], isVisible: true, sortIndex: 0),
              _libraryItem(packages[1], isVisible: true, sortIndex: 1),
            ],
          ),
          catalog: _FakeDictionaryCatalog(packages),
          readerFactory: (path) {
            if (path == packages[1].mdxPath) {
              return _LookupReader(
                path: path,
                onLookup: (_) => throw StateError('reader failed'),
              );
            }
            return _LookupReader(
              path: path,
              onLookup: (_) => '''
<div class="phonetic">/wɜːkɪŋ/</div>
<span class="pos">verb</span>
<div class="definition">有效的</div>
<div class="example">A working example helps.</div>
''',
            );
          },
        );

        final details = await repository.lookupAcrossVisibleDictionaries(
          'working',
        );

        expect(details, hasLength(2));
        expect(details.first.errorMessage, isNull);
        expect(details.first.definitions.single.definitionZh, '有效的');
        expect(details.last.dictionaryId, 'broken');
        expect(details.last.errorMessage, contains('reader failed'));
      },
    );

    test(
      'uses current package directory when manifest stores stale absolute paths',
      () async {
        final package = await _writePackage(
          '${tempRoot.path}/imported',
          id: 'stale',
          name: 'Stale',
          manifestRootPath:
              '/var/mobile/Containers/Data/Application/OLD-ID/Library/Application Support/dictionaries/imported/stale',
        );
        final recordedPaths = <String>[];
        final repository = DictionaryEntryLookupRepository(
          libraryRepository: _FakeDictionaryLibraryRepository(
            items: <DictionaryLibraryItem>[
              _libraryItem(package, isVisible: true, sortIndex: 0),
            ],
          ),
          catalog: FileSystemDictionaryCatalog(rootPath: tempRoot.path),
          readerFactory: (path) => _LookupReader(
            path: path,
            onLookup: (_) {
              recordedPaths.add(path);
              return '<div class="definition">resolved from current directory</div>';
            },
          ),
        );

        final details = await repository.lookupAcrossVisibleDictionaries(
          'abandon',
        );

        expect(details, hasLength(1));
        expect(details.single.errorMessage, isNull);
        expect(recordedPaths, <String>[
          '${tempRoot.path}/imported/stale/source/stale.mdx',
        ]);
      },
    );

    test(
      'includes imported css and js resources in dictionary details',
      () async {
        final package = await _writePackage(
          tempRoot.path,
          id: 'collins',
          name: 'Collins',
        );
        await File(
          '${package.resourcesPath}/theme.css',
        ).writeAsString('body {}');
        await File(
          '${package.resourcesPath}/switch.js',
        ).writeAsString('console.log(1);');

        final repository = DictionaryEntryLookupRepository(
          libraryRepository: _FakeDictionaryLibraryRepository(
            items: <DictionaryLibraryItem>[
              _libraryItem(package, isVisible: true, sortIndex: 0),
            ],
          ),
          catalog: _FakeDictionaryCatalog(<DictionaryPackage>[package]),
          readerFactory: (path) => _LookupReader(
            path: path,
            onLookup: (_) => '<div class="definition">styled</div>',
          ),
        );

        final details = await repository.lookupAcrossVisibleDictionaries(
          'abandon',
        );

        expect(details, hasLength(1));
        expect(details.single.resourcesPath, package.resourcesPath);
        expect(details.single.mddPaths, package.mddPaths);
        expect(details.single.stylesheetPaths, <String>[
          '${package.resourcesPath}/theme.css',
        ]);
        expect(details.single.scriptPaths, <String>[
          '${package.resourcesPath}/switch.js',
        ]);
      },
    );
  });

  group('PlatformWordDetailRepository', () {
    test('word detail carries lexdb entries alongside dictionary panels', () {
      const detail = WordDetail(
        word: 'abandon',
        dictionaryPanels: <DictionaryEntryDetail>[
          DictionaryEntryDetail(
            dictionaryId: 'html',
            dictionaryName: 'HTML Dictionary',
            word: 'abandon',
            rawContent: '<p>html</p>',
          ),
        ],
        lexDbEntries: <LexDbEntryDetail>[
          LexDbEntryDetail(
            dictionaryId: 'lexdb',
            dictionaryName: 'LexDB',
            headword: 'abandon',
            headwordDisplay: 'a·ban·don',
          ),
        ],
      );

      expect(detail.dictionaryPanels, hasLength(1));
      expect(detail.lexDbEntries, hasLength(1));
      expect(detail.lexDbEntries.single.headword, 'abandon');
    });

    test(
      'aggregates first non-empty basic fields and de-duplicates content',
      () async {
        final repository = PlatformWordDetailRepository(
          lookupRepository: _FakeLookupRepository(<DictionaryEntryDetail>[
            DictionaryEntryDetail(
              dictionaryId: 'primary',
              dictionaryName: 'Primary',
              word: 'abandon',
              rawContent: '<p>primary</p>',
              basic: const WordBasicSummary(
                headword: 'abandon',
                pronunciationUs: '/əˈbændən/',
              ),
              definitions: const <WordSense>[
                WordSense(partOfSpeech: 'verb', definitionZh: '放弃'),
              ],
              examples: const <WordExample>[
                WordExample(
                  english: 'They abandon the plan.',
                  translationZh: '他们放弃了计划。',
                ),
              ],
            ),
            DictionaryEntryDetail(
              dictionaryId: 'secondary',
              dictionaryName: 'Secondary',
              word: 'abandon',
              rawContent: '<p>secondary</p>',
              basic: const WordBasicSummary(
                headword: 'abandon',
                pronunciationUk: '/əˈbændən/',
                frequency: 'CET4',
              ),
              definitions: const <WordSense>[
                WordSense(partOfSpeech: 'verb', definitionZh: '放弃'),
                WordSense(partOfSpeech: 'noun', definitionZh: '放任'),
              ],
              examples: const <WordExample>[
                WordExample(
                  english: 'They abandon the plan.',
                  translationZh: '他们放弃了计划。',
                ),
                WordExample(
                  english: 'Abandon all doubt.',
                  translationZh: '丢开所有怀疑。',
                ),
              ],
            ),
          ]),
          lexDbRepository: _FakeLexDbWordDetailRepository(<LexDbEntryDetail>[
            const LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'LexDB',
              headword: 'abandon',
              headwordDisplay: 'a·ban·don',
            ),
          ]),
        );

        final detail = await repository.load('abandon');

        expect(detail.word, 'abandon');
        expect(detail.basic.pronunciationUs, '/əˈbændən/');
        expect(detail.basic.pronunciationUk, '/əˈbændən/');
        expect(detail.basic.frequency, 'CET4');
        expect(detail.definitions, const <WordSense>[
          WordSense(partOfSpeech: 'verb', definitionZh: '放弃'),
          WordSense(partOfSpeech: 'noun', definitionZh: '放任'),
        ]);
        expect(detail.examples, const <WordExample>[
          WordExample(
            english: 'They abandon the plan.',
            translationZh: '他们放弃了计划。',
          ),
          WordExample(english: 'Abandon all doubt.', translationZh: '丢开所有怀疑。'),
        ]);
        expect(detail.dictionaryPanels, hasLength(2));
        expect(detail.lexDbEntries, const <LexDbEntryDetail>[
          LexDbEntryDetail(
            dictionaryId: 'lexdb',
            dictionaryName: 'LexDB',
            headword: 'abandon',
            headwordDisplay: 'a·ban·don',
          ),
        ]);
      },
    );

    test(
      'ignores lexdb lookup failures and preserves dictionary details',
      () async {
        final repository = PlatformWordDetailRepository(
          lookupRepository: _FakeLookupRepository(<DictionaryEntryDetail>[
            const DictionaryEntryDetail(
              dictionaryId: 'primary',
              dictionaryName: 'Primary',
              word: 'abandon',
              rawContent: '<p>primary</p>',
            ),
          ]),
          lexDbRepository: _ThrowingLexDbWordDetailRepository(),
        );

        final detail = await repository.load('abandon');

        expect(detail.dictionaryPanels, hasLength(1));
        expect(detail.lexDbEntries, isEmpty);
      },
    );
  });
}

Future<DictionaryPackage> _writePackage(
  String rootPath, {
  required String id,
  required String name,
  String? manifestRootPath,
}) async {
  final packageRoot = Directory('$rootPath/$id');
  await packageRoot.create(recursive: true);
  await Directory('${packageRoot.path}/source').create();
  await Directory('${packageRoot.path}/resources').create();
  final mdxPath = '${packageRoot.path}/source/$id.mdx';
  await File(mdxPath).writeAsString('mock');
  final manifest = DictionaryManifest(
    id: id,
    name: name,
    type: DictionaryPackageType.imported,
    rootPath: manifestRootPath ?? packageRoot.path,
    mdxPath: manifestRootPath == null
        ? mdxPath
        : '$manifestRootPath/source/$id.mdx',
    mddPaths: const <String>[],
    resourcesPath: manifestRootPath == null
        ? '${packageRoot.path}/resources'
        : '$manifestRootPath/resources',
    importedAt: '2026-03-16T00:00:00.000Z',
  );
  await File(
    '${packageRoot.path}/manifest.json',
  ).writeAsString(jsonEncode(manifest.toJson()));
  return manifest.toPackage();
}

DictionaryLibraryItem _libraryItem(
  DictionaryPackage package, {
  required bool isVisible,
  required int sortIndex,
}) {
  return DictionaryLibraryItem(
    id: package.id,
    name: package.name,
    type: package.type,
    rootPath: package.rootPath,
    importedAt: package.importedAt,
    version: package.version ?? '20260316',
    category: package.category ?? '默认',
    entryCount: package.entryCount ?? 0,
    dictionaryAttribute: package.dictionaryAttribute ?? '本地词典',
    fileSizeBytes: package.fileSizeBytes ?? 0,
    fileSizeLabel: '0B',
    isVisible: isVisible,
    autoExpand: false,
    sortIndex: sortIndex,
  );
}

class _FakeDictionaryLibraryRepository implements DictionaryLibraryRepository {
  _FakeDictionaryLibraryRepository({required this.items});

  final List<DictionaryLibraryItem> items;

  @override
  Future<void> deleteDictionary(String id) async {}

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async => items;

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {}

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {}

  @override
  Future<void> setVisibility(String id, bool isVisible) async {}
}

class _FakeDictionaryCatalog implements DictionaryCatalog {
  _FakeDictionaryCatalog(this.packages);

  final List<DictionaryPackage> packages;

  @override
  Future<List<DictionaryCatalogEntry>> listPackages({
    DictionaryPackageType? type,
  }) async {
    return packages
        .where((package) => type == null || package.type == type)
        .map(
          (package) => DictionaryCatalogEntry(
            id: package.id,
            name: package.name,
            type: package.type,
            rootPath: package.rootPath,
            importedAt: package.importedAt,
          ),
        )
        .toList(growable: false);
  }
}

class _LookupReader implements MdictReadable {
  _LookupReader({
    required this.path,
    required String? Function(String word) onLookup,
  }) : _onLookup = onLookup;

  final String path;
  final String? Function(String word) _onLookup;

  @override
  Future<void> close() async {}

  @override
  Future<List<String>> listKeys({int limit = 50}) async => <String>[];

  @override
  Future<void> open() async {}

  @override
  Future<String?> lookup(String word) async => _onLookup(word);
}

class _FakeLookupRepository extends DictionaryEntryLookupRepository {
  _FakeLookupRepository(this.details)
    : super(
        libraryRepository: _FakeDictionaryLibraryRepository(items: const []),
        catalog: _FakeDictionaryCatalog(const <DictionaryPackage>[]),
      );

  final List<DictionaryEntryDetail> details;

  @override
  Future<List<DictionaryEntryDetail>> lookupAcrossVisibleDictionaries(
    String word,
  ) async {
    return details;
  }
}

class _FakeLexDbWordDetailRepository extends LexDbWordDetailRepository {
  _FakeLexDbWordDetailRepository(this.details)
    : super(
        databasePath: ':memory:',
        dictionaryId: 'lexdb',
        dictionaryName: 'LexDB',
        databaseFactory: databaseFactoryFfiNoIsolate,
      );

  final List<LexDbEntryDetail> details;

  @override
  Future<List<LexDbEntryDetail>> lookup(String word) async => details;
}

class _ThrowingLexDbWordDetailRepository extends LexDbWordDetailRepository {
  _ThrowingLexDbWordDetailRepository()
    : super(
        databasePath: ':memory:',
        dictionaryId: 'lexdb',
        dictionaryName: 'LexDB',
        databaseFactory: databaseFactoryFfiNoIsolate,
      );

  @override
  Future<List<LexDbEntryDetail>> lookup(String word) async {
    throw StateError('lexdb failed');
  }
}
