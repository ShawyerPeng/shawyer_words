import 'dart:io';
import 'dart:typed_data';

import 'package:dict_reader/dict_reader.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

typedef MdictReaderFactory = MdictReadable Function(String path);

class RecordOffsetData {
  const RecordOffsetData({
    required this.keyText,
    required this.recordBlockOffset,
    required this.startOffset,
    required this.endOffset,
    required this.compressedSize,
  });

  final String keyText;
  final int recordBlockOffset;
  final int startOffset;
  final int endOffset;
  final int compressedSize;
}

abstract class DictReaderBackend {
  Future<void> initDict();
  Future<void> close();
  List<String> search(String key, {int? limit});
  Stream<RecordOffsetData> readWithOffset();
  Future<RecordOffsetData?> locate(String key);
  Future<String?> readOneMdx(RecordOffsetData offset);
}

abstract class MdictReadable {
  Future<void> open();
  Future<List<String>> listKeys({int limit = 50});
  Future<String?> lookup(String word);
  Future<void> close();
}

class MdxDictionaryParser {
  MdxDictionaryParser({MdictReaderFactory? readerFactory})
    : _readerFactory = readerFactory ?? ((path) => DictReaderAdapter(path));

  final MdictReaderFactory _readerFactory;

  Future<DictionaryImportResult> parse(
    DictionaryPackage dictionaryPackage,
  ) async {
    final preview = await buildPreview(dictionaryPackage);
    final firstPage = await loadPreviewPage(
      dictionaryPackage,
      preview.entryKeys.take(24).toList(),
    );
    if (firstPage.isEmpty) {
      throw UnsupportedError(
        'This app could not read any usable entries from the selected MDX file. '
        'The dictionary may contain unsupported or corrupted record offsets.',
      );
    }

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
        entryCount: preview.totalEntries,
        version: dictionaryPackage.version,
        category: dictionaryPackage.category,
        dictionaryAttribute: dictionaryPackage.dictionaryAttribute,
        fileSizeBytes: dictionaryPackage.fileSizeBytes,
      ),
      dictionary: DictionarySummary(
        id: dictionaryPackage.id,
        name: dictionaryPackage.name,
        sourcePath: dictionaryPackage.rootPath,
        importedAt: dictionaryPackage.importedAt,
        entryCount: preview.totalEntries,
      ),
      entries: firstPage,
    );
  }

  Future<DictionaryImportPreview> buildPreview(
    DictionaryPackage dictionaryPackage, {
    int pageSize = 1000,
  }) async {
    final reader = _readerFactory(dictionaryPackage.mdxPath);
    try {
      await reader.open();
    } on Object catch (error) {
      _mapOpenError(error);
    }

    try {
      late final List<String> keys;
      try {
        keys = await reader.listKeys(limit: 1 << 30);
      } on RangeError {
        throw UnsupportedError(
          'This app could not read any usable entries from the selected MDX file. '
          'The dictionary may contain unsupported or corrupted record offsets.',
        );
      }
      return DictionaryImportPreview(
        sourceRootPath: dictionaryPackage.rootPath,
        title: dictionaryPackage.name,
        primaryMdxPath: dictionaryPackage.mdxPath,
        metadataText: _readMetadataText(dictionaryPackage.mdxPath),
        files: const <DictionaryPreviewFile>[],
        entryKeys: keys,
        totalEntries: keys.length,
        pageSize: pageSize,
      );
    } finally {
      await reader.close();
    }
  }

  Future<List<WordEntry>> loadPreviewPage(
    DictionaryPackage dictionaryPackage,
    List<String> keys,
  ) async {
    final reader = _readerFactory(dictionaryPackage.mdxPath);
    try {
      await reader.open();
    } on Object catch (error) {
      _mapOpenError(error);
    }

    try {
      final entries = <WordEntry>[];
      for (final key in keys) {
        String? content;
        try {
          content = await reader.lookup(key);
        } on RangeError {
          continue;
        }
        if (content == null || content.trim().isEmpty) {
          continue;
        }
        entries.add(mapEntry(word: key, rawContent: content));
      }
      return entries;
    } finally {
      await reader.close();
    }
  }

  WordEntry mapEntry({required String word, required String rawContent}) {
    return WordEntry(
      id: word,
      word: word,
      pronunciation: _firstMatch(rawContent, const [
        r'<div[^>]*class="[^"]*phonetic[^"]*"[^>]*>(.*?)</div>',
        r'<span[^>]*class="[^"]*phonetic[^"]*"[^>]*>(.*?)</span>',
        r'/[^/\n]+/',
      ]),
      partOfSpeech: _firstMatch(rawContent, const [
        r'<span[^>]*class="[^"]*pos[^"]*"[^>]*>(.*?)</span>',
        r'<div[^>]*class="[^"]*pos[^"]*"[^>]*>(.*?)</div>',
      ]),
      definition: _firstMatch(rawContent, const [
        r'<div[^>]*class="[^"]*definition[^"]*"[^>]*>(.*?)</div>',
        r'<span[^>]*class="[^"]*definition[^"]*"[^>]*>(.*?)</span>',
        r'<li[^>]*>(.*?)</li>',
      ]),
      exampleSentence: _firstMatch(rawContent, const [
        r'<div[^>]*class="[^"]*example[^"]*"[^>]*>(.*?)</div>',
        r'<span[^>]*class="[^"]*example[^"]*"[^>]*>(.*?)</span>',
      ]),
      rawContent: rawContent.trim(),
    );
  }

  String? _firstMatch(String source, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(
        pattern,
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(source);
      if (match == null) {
        continue;
      }

      final candidate = match.groupCount >= 1
          ? match.group(1) ?? match.group(0)
          : match.group(0);
      final normalized = _stripHtml(candidate ?? '');
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  Never _mapOpenError(Object error) {
    final message = '$error';
    if (message.contains('Compression method not supported')) {
      throw UnsupportedError(
        'This app could not decode the selected MDX file because it uses an unsupported compression format.',
      );
    }
    if (error is FormatException ||
        message.contains('Filter error, bad data') ||
        message.contains('Version <2.0 not implemented')) {
      throw UnsupportedError(
        'This app could not decode the selected MDX file. '
        'It is likely encrypted or uses an unsupported compression format.',
      );
    }
    throw error;
  }

  String _readMetadataText(String filePath) {
    try {
      final bytes = File(filePath).readAsBytesSync();
      if (bytes.length < 8) {
        return '';
      }
      final headerLength = ByteData.sublistView(bytes, 0, 4).getUint32(0);
      if (headerLength <= 0 || bytes.length < 4 + headerLength) {
        return '';
      }
      final codeUnits = <int>[];
      for (var index = 4; index < 4 + headerLength; index += 2) {
        codeUnits.add(bytes[index] | (bytes[index + 1] << 8));
      }
      return String.fromCharCodes(codeUnits).trim();
    } on Object {
      return '';
    }
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class DictReaderAdapter implements MdictReadable {
  DictReaderAdapter(String path) : this.fromBackend(_DictReaderBackend(path));

  DictReaderAdapter.fromBackend(DictReaderBackend reader) : _reader = reader;

  final DictReaderBackend _reader;
  final Map<String, RecordOffsetData> _offsetByKey =
      <String, RecordOffsetData>{};

  @override
  Future<void> open() {
    return _reader.initDict();
  }

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    final keys = <String>[];
    for (final key in _reader.search('', limit: limit)) {
      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty || _offsetByKey.containsKey(normalizedKey)) {
        continue;
      }
      keys.add(normalizedKey);
    }

    return keys;
  }

  @override
  Future<String?> lookup(String word) async {
    final offset = _offsetByKey[word] ?? await _reader.locate(word);
    if (offset == null) {
      return null;
    }

    return _reader.readOneMdx(offset);
  }

  @override
  Future<void> close() => _reader.close();
}

class _DictReaderBackend implements DictReaderBackend {
  _DictReaderBackend(String path) : _reader = DictReader(path);

  final DictReader _reader;

  @override
  Future<void> initDict() => _reader.initDict();

  @override
  Future<void> close() => _reader.close();

  @override
  List<String> search(String key, {int? limit}) {
    return _reader.search(key, limit: limit);
  }

  @override
  Stream<RecordOffsetData> readWithOffset() async* {
    await for (final record in _reader.readWithOffset()) {
      yield RecordOffsetData(
        keyText: record.keyText,
        recordBlockOffset: record.recordBlockOffset,
        startOffset: record.startOffset,
        endOffset: record.endOffset,
        compressedSize: record.compressedSize,
      );
    }
  }

  @override
  Future<RecordOffsetData?> locate(String key) async {
    final record = await _reader.locate(key);
    if (record == null) {
      return null;
    }
    return RecordOffsetData(
      keyText: record.keyText,
      recordBlockOffset: record.recordBlockOffset,
      startOffset: record.startOffset,
      endOffset: record.endOffset,
      compressedSize: record.compressedSize,
    );
  }

  @override
  Future<String?> readOneMdx(RecordOffsetData offset) {
    return _reader.readOneMdx(
      RecordOffsetInfo(
        offset.keyText,
        offset.recordBlockOffset,
        offset.startOffset,
        offset.endOffset,
        offset.compressedSize,
      ),
    );
  }
}
