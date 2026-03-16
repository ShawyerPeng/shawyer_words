import 'package:dict_reader/dict_reader.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

typedef MdictReaderFactory = MdictReadable Function(String path);

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

  Future<DictionaryImportResult> parse(DictionaryPackage dictionaryPackage) async {
    final reader = _readerFactory(dictionaryPackage.mdxPath);
    try {
      await reader.open();
    } on Object catch (error) {
      final message = '$error';
      if (message.contains('Compression method not supported')) {
        throw UnsupportedError(
          'This app could not decode the selected MDX file because it uses an unsupported compression format.',
        );
      }
      if (
        error is FormatException ||
        message.contains('Filter error, bad data') ||
        message.contains('Version <2.0 not implemented')
      ) {
        throw UnsupportedError(
          'This app could not decode the selected MDX file. '
          'It is likely encrypted or uses an unsupported compression format.',
        );
      }
      rethrow;
    }

    try {
      final keys = await reader.listKeys(limit: 128);
      final entries = <WordEntry>[];

      for (final key in keys) {
        if (entries.length >= 24) {
          break;
        }

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

      if (entries.isEmpty) {
        throw UnsupportedError(
          'This app could not read any usable entries from the selected MDX file. '
          'The dictionary may contain unsupported or corrupted record offsets.',
        );
      }

      return DictionaryImportResult(
        package: dictionaryPackage,
        dictionary: DictionarySummary(
          id: dictionaryPackage.id,
          name: dictionaryPackage.name,
          sourcePath: dictionaryPackage.rootPath,
          importedAt: dictionaryPackage.importedAt,
          entryCount: entries.length,
        ),
        entries: entries,
      );
    } finally {
      await reader.close();
    }
  }
  WordEntry mapEntry({
    required String word,
    required String rawContent,
  }) {
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
  DictReaderAdapter(String path) : _reader = DictReader(path);

  final DictReader _reader;
  final Map<String, RecordOffsetInfo> _offsetByKey = <String, RecordOffsetInfo>{};

  @override
  Future<void> open() {
    return _reader.initDict();
  }

  @override
  Future<List<String>> listKeys({int limit = 50}) async {
    final keys = <String>[];
    await for (final record in _reader.readWithOffset()) {
      final key = record.keyText.trim();
      if (key.isEmpty || _offsetByKey.containsKey(key)) {
        continue;
      }
      _offsetByKey[key] = record;
      keys.add(key);
      if (keys.length >= limit) {
        break;
      }
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
