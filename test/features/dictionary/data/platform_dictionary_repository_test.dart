import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'platform_dictionary_repository_test',
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('importDictionary imports a package before delegating to the mdx parser', () async {
    final importer = _FakeImporter(tempRoot.path);
    final parser = _FakeParser();
    final storage = _FakeStorage();
    final repository = PlatformDictionaryRepository(
      importer: importer,
      parser: parser,
      storage: storage,
    );

    final result = await repository.importDictionary('/tmp/example.zip');

    expect(importer.paths, ['/tmp/example.zip']);
    expect(
      parser.packages.single.mdxPath,
      '${tempRoot.path}/managed/example/source/main.mdx',
    );
    expect(result.dictionary.name, 'Test Dictionary');
    expect(result.entries.single.word, 'abandon');
    expect(result.dictionary.entryCount, 314);
    expect(storage.manifests.single.entryCount, 314);
    expect(
      storage.manifests.single.fileSizeBytes,
      3 + 4 + 5,
    );
  });
}

class _FakeImporter implements DictionaryPackageImporter {
  _FakeImporter(this.rootPath);

  final String rootPath;
  final List<String> paths = <String>[];

  @override
  Future<DictionaryPackage> importPackage(String sourcePath) async {
    paths.add(sourcePath);
    final packageRoot = Directory('$rootPath/managed/example');
    await Directory('${packageRoot.path}/source').create(recursive: true);
    await Directory('${packageRoot.path}/resources').create(recursive: true);
    await File('${packageRoot.path}/source/main.mdx').writeAsString('mdx');
    await File('${packageRoot.path}/source/main.mdd').writeAsString('mdd!');
    await File('${packageRoot.path}/resources/theme.css').writeAsString('style');

    return DictionaryPackage(
      id: 'example',
      name: 'Example',
      type: DictionaryPackageType.imported,
      rootPath: packageRoot.path,
      mdxPath: '${packageRoot.path}/source/main.mdx',
      mddPaths: <String>['${packageRoot.path}/source/main.mdd'],
      resourcesPath: '${packageRoot.path}/resources',
      importedAt: '2026-03-16T00:00:00.000Z',
      entryCount: 1,
    );
  }
}

class _FakeParser extends MdxDictionaryParser {
  _FakeParser() : super(readerFactory: (_) => throw UnimplementedError());

  final List<DictionaryPackage> packages = <DictionaryPackage>[];

  @override
  Future<DictionaryImportResult> parse(DictionaryPackage dictionaryPackage) async {
    packages.add(dictionaryPackage);
    return DictionaryImportResult(
      package: DictionaryPackage(
        id: dictionaryPackage.id,
        name: dictionaryPackage.name,
        type: dictionaryPackage.type,
        rootPath: dictionaryPackage.rootPath,
        mdxPath: dictionaryPackage.mdxPath,
        mddPaths: dictionaryPackage.mddPaths,
        resourcesPath: dictionaryPackage.resourcesPath,
        importedAt: dictionaryPackage.importedAt,
        entryCount: 314,
      ),
      dictionary: const DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 314,
      ),
      entries: [
        WordEntry(
          id: '1',
          word: 'abandon',
          rawContent: '<p>abandon</p>',
        ),
      ],
    );
  }
}

class _FakeStorage implements DictionaryStorage {
  final List<DictionaryManifest> manifests = <DictionaryManifest>[];

  @override
  Future<String> createPackageDirectories({
    required DictionaryPackageType type,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePackage({
    required DictionaryPackageType type,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DictionaryManifest> writeManifest(DictionaryManifest manifest) async {
    manifests.add(manifest);
    return manifest;
  }
}
