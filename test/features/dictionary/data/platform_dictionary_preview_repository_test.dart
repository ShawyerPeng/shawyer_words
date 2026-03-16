import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';

void main() {
  late Directory tempRoot;
  late PlatformDictionaryPreviewRepository repository;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'dictionary_preview_repository_test',
    );
    repository = PlatformDictionaryPreviewRepository(
      stagingRootPath: tempRoot.path,
      parser: MdxDictionaryParser(readerFactory: (_) => _PreviewMdictReader()),
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('prepares a preview session from multiple selected files', () async {
    final mainMdx = File('${tempRoot.path}/main.mdx');
    await mainMdx.writeAsBytes(
      _buildHeaderFile(
        '<Dictionary Title="Oxford Starter" Description="Preview dictionary metadata." />',
      ),
    );
    final mainMdd = File('${tempRoot.path}/main.mdd')..writeAsStringSync('mdd');
    final styleCss = File('${tempRoot.path}/style.css')
      ..writeAsStringSync('body { color: red; }');
    final scriptJs = File('${tempRoot.path}/script.js')
      ..writeAsStringSync('console.log("preview");');

    final preview = await repository.preparePreview([
      mainMdx.path,
      mainMdd.path,
      styleCss.path,
      scriptJs.path,
    ]);

    expect(preview.primaryMdxPath, endsWith('main.mdx'));
    expect(preview.totalEntries, 2505);
    expect(preview.totalPages, 3);
    expect(preview.files, hasLength(4));
    expect(
      preview.files.where((file) => file.kind == DictionaryPreviewFileKind.mdd),
      hasLength(1),
    );
    expect(
      preview.files.where((file) => file.kind == DictionaryPreviewFileKind.css),
      hasLength(1),
    );
    expect(
      preview.files.where((file) => file.kind == DictionaryPreviewFileKind.js),
      hasLength(1),
    );
    expect(preview.metadataText, contains('Oxford Starter'));
  });

  test('loads a page of 1000 entries and maps the selected range', () async {
    final mainMdx = File('${tempRoot.path}/paged.mdx');
    await mainMdx.writeAsBytes(
      _buildHeaderFile('<Dictionary Title="Paged Dictionary" />'),
    );

    final preview = await repository.preparePreview([mainMdx.path]);
    final page = await repository.loadPage(preview: preview, pageNumber: 2);

    expect(page.pageNumber, 2);
    expect(page.entries, hasLength(1000));
    expect(page.entries.first.word, 'word-1001');
    expect(page.entries.last.word, 'word-2000');
  });
}

class _PreviewMdictReader implements MdictReadable {
  @override
  Future<void> open() async {}

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    final keys = List<String>.generate(2505, (index) => 'word-${index + 1}');
    return keys.take(limit).toList();
  }

  @override
  Future<String?> lookup(String word) async {
    return '''
<div class="entry">
  <span class="pos">noun</span>
  <div class="definition">Definition for $word</div>
  <div class="example">Example sentence for $word.</div>
</div>
''';
  }

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
