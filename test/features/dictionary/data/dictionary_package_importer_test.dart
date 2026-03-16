import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  late Directory tempRoot;
  late FileSystemDictionaryStorage storage;
  late FileSystemDictionaryPackageImporter importer;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'dictionary_package_importer_test',
    );
    storage = FileSystemDictionaryStorage(rootPath: tempRoot.path);
    importer = FileSystemDictionaryPackageImporter(
      rootPath: tempRoot.path,
      storage: storage,
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('imports a directory into an isolated managed package', () async {
    final source = await Directory('${tempRoot.path}/source-directory').create();
    await File('${source.path}/main.mdx').writeAsString('mdx');
    await File('${source.path}/main.mdd').writeAsString('mdd');
    await File('${source.path}/style.css').writeAsString('body {}');
    await Directory('${source.path}/assets').create();
    await File('${source.path}/assets/sound.mp3').writeAsString('audio');

    final package = await importer.importPackage(source.path);

    expect(package.type, DictionaryPackageType.imported);
    expect(package.mdxPath, endsWith('/source/main.mdx'));
    expect(File(package.mdxPath).existsSync(), isTrue);
    expect(File(package.mddPaths.single).existsSync(), isTrue);
    expect(
      File('${package.resourcesPath}/style.css').readAsStringSync(),
      contains('body'),
    );
    expect(
      File('${package.resourcesPath}/assets/sound.mp3').readAsStringSync(),
      'audio',
    );
    expect(File('${package.rootPath}/manifest.json').existsSync(), isTrue);
  });

  test('imports a zip archive into an isolated managed package', () async {
    final archiveFile = File('${tempRoot.path}/archive.zip');
    final archive = Archive()
      ..add(ArchiveFile.string('archive/main.mdx', 'mdx'))
      ..add(ArchiveFile.string('archive/main.mdd', 'mdd'))
      ..add(ArchiveFile.string('archive/theme.css', 'body { color: red; }'));
    await archiveFile.writeAsBytes(ZipEncoder().encode(archive));

    final package = await importer.importPackage(archiveFile.path);

    expect(File(package.mdxPath).existsSync(), isTrue);
    expect(package.mddPaths, hasLength(1));
    expect(
      File('${package.resourcesPath}/archive/theme.css').existsSync(),
      isTrue,
    );
  });

  test('ignores Apple metadata files when importing a zip archive', () async {
    final archiveFile = File('${tempRoot.path}/archive-with-macos-metadata.zip');
    final archive = Archive()
      ..add(ArchiveFile.string('archive/main.mdx', 'mdx'))
      ..add(ArchiveFile.string('__MACOSX/archive/._main.mdx', 'metadata'))
      ..add(ArchiveFile.string('archive/main.mdd', 'mdd'));
    await archiveFile.writeAsBytes(ZipEncoder().encode(archive));

    final package = await importer.importPackage(archiveFile.path);

    expect(package.mdxPath, endsWith('/source/main.mdx'));
    expect(File(package.mdxPath).existsSync(), isTrue);
    expect(package.mddPaths, hasLength(1));
  });

  test('imports a single mdx file as a minimal managed package', () async {
    final mdxFile = File('${tempRoot.path}/single.mdx');
    await mdxFile.writeAsString('mdx');

    final package = await importer.importPackage(mdxFile.path);

    expect(package.mdxPath, endsWith('/source/single.mdx'));
    expect(File(package.mdxPath).existsSync(), isTrue);
    expect(package.mddPaths, isEmpty);
    expect(Directory(package.resourcesPath).existsSync(), isTrue);
    expect(Directory(package.resourcesPath).listSync(), isEmpty);
  });

  test('rejects packages that do not include an MDX file', () async {
    final source = await Directory('${tempRoot.path}/missing-mdx').create();
    await File('${source.path}/style.css').writeAsString('body {}');

    await expectLater(
      importer.importPackage(source.path),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('MDX'),
        ),
      ),
    );
  });

  test('cleans staging directories when an import fails', () async {
    final source = await Directory('${tempRoot.path}/broken-package').create();
    await File('${source.path}/notes.txt').writeAsString('not a dictionary');

    await expectLater(
      importer.importPackage(source.path),
      throwsA(isA<UnsupportedError>()),
    );

    final stagingRoot = Directory('${tempRoot.path}/_staging');
    if (!stagingRoot.existsSync()) {
      return;
    }

    expect(stagingRoot.listSync(), isEmpty);
  });
}
