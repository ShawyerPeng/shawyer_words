import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

void main() {
  test('importDictionary imports a package before delegating to the mdx parser', () async {
    final importer = _FakeImporter();
    final parser = _FakeParser();
    final repository = PlatformDictionaryRepository(
      importer: importer,
      parser: parser,
    );

    final result = await repository.importDictionary('/tmp/example.zip');

    expect(importer.paths, ['/tmp/example.zip']);
    expect(parser.packages.single.mdxPath, '/tmp/managed/example/source/main.mdx');
    expect(result.dictionary.name, 'Test Dictionary');
    expect(result.entries.single.word, 'abandon');
  });
}

class _FakeImporter implements DictionaryPackageImporter {
  final List<String> paths = <String>[];

  @override
  Future<DictionaryPackage> importPackage(String sourcePath) async {
    paths.add(sourcePath);
    return const DictionaryPackage(
      id: 'example',
      name: 'Example',
      type: DictionaryPackageType.imported,
      rootPath: '/tmp/managed/example',
      mdxPath: '/tmp/managed/example/source/main.mdx',
      mddPaths: <String>['/tmp/managed/example/source/main.mdd'],
      resourcesPath: '/tmp/managed/example/resources',
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
    return const DictionaryImportResult(
      package: DictionaryPackage(
        id: 'example',
        name: 'Example',
        type: DictionaryPackageType.imported,
        rootPath: '/tmp/managed/example',
        mdxPath: '/tmp/managed/example/source/main.mdx',
        mddPaths: <String>['/tmp/managed/example/source/main.mdd'],
        resourcesPath: '/tmp/managed/example/resources',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 1,
      ),
      dictionary: DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '/tmp/managed/example',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 1,
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
