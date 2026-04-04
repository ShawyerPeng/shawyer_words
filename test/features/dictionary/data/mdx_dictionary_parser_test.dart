import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  test('maps mdict lookup html into a word entry', () async {
    final parser = MdxDictionaryParser(
      readerFactory: (_) => _FakeMdictReader(),
    );

    final result = await parser.parse(_testPackage('/tmp/test.mdx'));

    expect(result.dictionary.name, 'test');
    expect(result.dictionary.sourcePath, '/tmp');
    expect(result.dictionary.entryCount, 1);
    expect(result.package.entryCount, 1);
    expect(result.entries, hasLength(1));
    expect(result.entries.single.word, 'abandon');
    expect(result.entries.single.pronunciation, '/əˈbændən/');
    expect(result.entries.single.partOfSpeech, 'verb');
    expect(result.entries.single.definition, 'to leave behind');
    expect(
      result.entries.single.exampleSentence,
      'They abandon the plan at sunrise.',
    );
  });

  test('maps one raw lookup result directly into a word entry', () {
    final parser = MdxDictionaryParser();

    final entry = parser.mapEntry(
      word: 'abandon',
      rawContent: '''
<div class="entry">
  <div class="phonetic">/əˈbændən/</div>
  <span class="pos">verb</span>
  <div class="definition">to leave behind</div>
  <div class="example">They abandon the plan at sunrise.</div>
</div>
''',
    );

    expect(entry.word, 'abandon');
    expect(entry.pronunciation, '/əˈbændən/');
    expect(entry.partOfSpeech, 'verb');
    expect(entry.definition, 'to leave behind');
    expect(entry.exampleSentence, 'They abandon the plan at sunrise.');
  });

  test('does not treat css paths as pronunciation fallback', () {
    final parser = MdxDictionaryParser();

    final entry = parser.mapEntry(
      word: 'absorb',
      rawContent: '''
<div class="entry">
  <link rel="stylesheet" href="/css/main.css" />
  <script src="/js/main.js"></script>
  <div class="definition">to take in</div>
</div>
''',
    );

    expect(entry.pronunciation, isNull);
    expect(entry.definition, 'to take in');
  });

  test('does not capture sound href fragments as pronunciation', () {
    final parser = MdxDictionaryParser();

    final entry = parser.mapEntry(
      word: 'absorb',
      rawContent: '''
<div class="entry">
  <a href="sound://00201.mp3">/əbˈzɔːrb/</a>
  <div class="definition">to take in</div>
</div>
''',
    );

    expect(entry.pronunciation, '/əbˈzɔːrb/');
    expect(entry.definition, 'to take in');
  });

  test('extracts pronunciation from anchor phonetic class without href noise', () {
    final parser = MdxDictionaryParser();

    final entry = parser.mapEntry(
      word: 'career',
      rawContent: '''
<div class="entry">
  <a class="phonetic" href="sound://00201.mp3">/kəˈrɪə(r)/</a>
  <div class="definition">profession</div>
</div>
''',
    );

    expect(entry.pronunciation, '/kəˈrɪə(r)/');
    expect(entry.pronunciation, isNot(contains('mp3')));
  });

  test('extracts non-slashed pronunciation from anchor phonetic class', () {
    final parser = MdxDictionaryParser();

    final entry = parser.mapEntry(
      word: 'career',
      rawContent: '''
<div class="entry">
  <a class="phonetic" href="sound://00201.mp3">kəˈrɪə(r)</a>
  <div class="definition">profession</div>
</div>
''',
    );

    expect(entry.pronunciation, 'kəˈrɪə(r)');
    expect(entry.pronunciation, isNot(contains('mp3')));
  });

  test('allows legacy mdx dictionaries when the backend can read them', () async {
    final tempDir = await Directory.systemTemp.createTemp('legacy_mdx_test');
    final file = File('${tempDir.path}/legacy.mdx');
    await file.writeAsBytes(_buildHeaderFile('<Dictionary GeneratedByEngineVersion="1.2" />'));

    final parser = MdxDictionaryParser(
      readerFactory: (_) => _FakeMdictReader(),
    );

    final result = await parser.parse(_testPackage(file.path));

    expect(result.entries.single.word, 'abandon');
  });

  test('allows encrypted mdx dictionaries when the backend can read them', () async {
    final tempDir = await Directory.systemTemp.createTemp('encrypted_mdx_test');
    final file = File('${tempDir.path}/encrypted.mdx');
    await file.writeAsBytes(
      _buildHeaderFile(
        '<Dictionary GeneratedByEngineVersion="2.0" Encrypted="2" Title="Encrypted Dict" />',
      ),
    );

    final parser = MdxDictionaryParser(
      readerFactory: (_) => _FakeMdictReader(),
    );

    final result = await parser.parse(_testPackage(file.path));

    expect(result.entries.single.word, 'abandon');
  });

  test('maps unsupported compression failures into a clean error', () async {
    final parser = MdxDictionaryParser(
      readerFactory: (_) => _ThrowingMdictReader('Compression method not supported'),
    );

    await expectLater(
      () => parser.parse(_testPackage('/tmp/test.mdx')),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('unsupported compression format'),
        ),
      ),
    );
  });

  test('skips unreadable entries when a single mdx lookup throws range error', () async {
    final parser = MdxDictionaryParser(
      readerFactory: (_) => _PartiallyBrokenMdictReader(),
    );

    final result = await parser.parse(_testPackage('/tmp/test.mdx'));

    expect(result.entries, hasLength(1));
    expect(result.entries.single.word, 'brisk');
    expect(result.entries.single.definition, 'quick and energetic');
  });

  test('maps range errors from key listing into a clean unsupported error', () async {
    final parser = MdxDictionaryParser(
      readerFactory: (_) => _BrokenKeyListingMdictReader(),
    );

    await expectLater(
      () => parser.buildPreview(_testPackage('/tmp/test.mdx')),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('unsupported or corrupted record offsets'),
        ),
      ),
    );
  });
}

DictionaryPackage _testPackage(String mdxPath) {
  return DictionaryPackage(
    id: 'test',
    name: 'test',
    type: DictionaryPackageType.imported,
    rootPath: '/tmp',
    mdxPath: mdxPath,
    mddPaths: const <String>[],
    resourcesPath: '/tmp/resources',
    importedAt: '2026-03-16T00:00:00.000Z',
  );
}

class _FakeMdictReader implements MdictReadable {
  bool opened = false;
  bool closed = false;

  @override
  Future<void> open() async {
    opened = true;
  }

  @override
  Future<String?> lookup(String word) async {
    if (word == 'abandon') {
      return '''
<div class="entry">
  <div class="phonetic">/əˈbændən/</div>
  <span class="pos">verb</span>
  <div class="definition">to leave behind</div>
  <div class="example">They abandon the plan at sunrise.</div>
</div>
''';
    }
    return null;
  }

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    return <String>['abandon'];
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

class _ThrowingMdictReader implements MdictReadable {
  _ThrowingMdictReader(this.error);

  final Object error;

  @override
  Future<void> open() async {
    throw error;
  }

  @override
  Future<List<String>> listKeys({int limit = 50}) async => <String>[];

  @override
  Future<String?> lookup(String word) async => null;

  @override
  Future<void> close() async {}
}

class _PartiallyBrokenMdictReader implements MdictReadable {
  @override
  Future<void> open() async {}

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    return <String>['broken', 'brisk'];
  }

  @override
  Future<String?> lookup(String word) async {
    if (word == 'broken') {
      throw RangeError.range(3142786, 7132, 63121, 'end');
    }
    if (word == 'brisk') {
      return '<div class="definition">quick and energetic</div>';
    }
    return null;
  }

  @override
  Future<void> close() async {}
}

class _BrokenKeyListingMdictReader implements MdictReadable {
  @override
  Future<void> open() async {}

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    throw RangeError.range(3142786, 7132, 63121, 'end');
  }

  @override
  Future<String?> lookup(String word) async => null;

  @override
  Future<void> close() async {}
}

Uint8List _buildHeaderFile(String headerXml) {
  final codeUnits = headerXml.codeUnits;
  final headerBytes = Uint8List(codeUnits.length * 2);
  for (var index = 0; index < codeUnits.length; index++) {
    final unit = codeUnits[index];
    headerBytes[index * 2] = unit & 0xFF;
    headerBytes[index * 2 + 1] = (unit >> 8) & 0xFF;
  }
  final length = ByteData(4)..setUint32(0, headerBytes.length);
  return Uint8List.fromList(<int>[
    ...length.buffer.asUint8List(),
    ...headerBytes,
    0,
    0,
    0,
    0,
  ]);
}
