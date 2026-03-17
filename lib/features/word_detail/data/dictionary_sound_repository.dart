import 'dart:io';

import 'package:dict_reader/dict_reader.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';

typedef DictReaderFactory = DictReader Function(String path);

class DictionarySoundRepository {
  DictionarySoundRepository({
    DictReaderFactory? readerFactory,
    Directory Function()? tempDirectoryProvider,
  }) : _readerFactory = readerFactory ?? ((path) => DictReader(path)),
       _tempDirectoryProvider =
           tempDirectoryProvider ?? (() => Directory.systemTemp);

  final DictReaderFactory _readerFactory;
  final Directory Function() _tempDirectoryProvider;

  Future<File?> materializeSoundFile({
    required DictionaryEntryDetail panel,
    required String soundUrl,
  }) async {
    final resourceKey = _normalizeSoundResourceKey(soundUrl);
    if (resourceKey == null) {
      return null;
    }

    for (final mddPath in panel.mddPaths) {
      final bytes = await _readMddBytes(
        mddPath: mddPath,
        resourceKey: resourceKey,
      );
      if (bytes == null) {
        continue;
      }

      final extension = _fileExtension(resourceKey);
      final safeName = panel.dictionaryId.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final outputDirectory = _tempDirectoryProvider();
      await outputDirectory.create(recursive: true);
      final outputFile = File(
        '${outputDirectory.path}/dict-sound-$safeName-${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await outputFile.writeAsBytes(bytes, flush: true);
      return outputFile;
    }

    return null;
  }

  Future<List<int>?> _readMddBytes({
    required String mddPath,
    required String resourceKey,
  }) async {
    final reader = _readerFactory(mddPath);
    await reader.initDict();
    try {
      for (final candidate in _candidateKeys(resourceKey)) {
        final offset = await reader.locate(candidate);
        if (offset == null) {
          continue;
        }
        return reader.readOneMdd(offset);
      }
      return null;
    } finally {
      await reader.close();
    }
  }

  List<String> _candidateKeys(String resourceKey) {
    final slashNormalized = resourceKey.replaceAll('\\', '/');
    final backslashNormalized = slashNormalized.replaceAll('/', '\\');
    return <String>{
      slashNormalized,
      '\\$slashNormalized',
      '/$slashNormalized',
      backslashNormalized,
      '\\$backslashNormalized',
      '/$backslashNormalized',
    }.toList(growable: false);
  }

  String? _normalizeSoundResourceKey(String soundUrl) {
    final uri = Uri.tryParse(soundUrl);
    if (uri == null || uri.scheme != 'sound') {
      return null;
    }
    final rawTarget = uri.path.isNotEmpty
        ? uri.path
        : uri.host + (uri.hasQuery ? '?${uri.query}' : '');
    final normalizedTarget = Uri.decodeComponent(rawTarget).trim();
    if (normalizedTarget.isEmpty) {
      return null;
    }
    return normalizedTarget;
  }

  String _fileExtension(String resourceKey) {
    final dotIndex = resourceKey.lastIndexOf('.');
    if (dotIndex < 0) {
      return '.bin';
    }
    return resourceKey.substring(dotIndex);
  }
}
