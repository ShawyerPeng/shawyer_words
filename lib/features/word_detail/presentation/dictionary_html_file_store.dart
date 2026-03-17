import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_document.dart';

class DictionaryHtmlFileStore {
  DictionaryHtmlFileStore({
    Future<Directory> Function()? temporaryDirectoryProvider,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  final Future<Directory> Function() _temporaryDirectoryProvider;

  Future<File> writeDocument({
    required DictionaryEntryDetail detail,
    required DictionaryHtmlDocument document,
    required String signature,
  }) async {
    final directory = await _renderDirectoryFor(detail);
    final file = File(
      '${directory.path}/.shawyer_render_${_safeSegment(detail.dictionaryId)}_${_signatureDigest(signature)}.html',
    );

    if (await file.exists()) {
      final existing = await file.readAsString();
      if (existing == document.html) {
        return file;
      }
    }

    await file.writeAsString(document.html, flush: true);
    return file;
  }

  Future<Directory> _renderDirectoryFor(DictionaryEntryDetail detail) async {
    final resourcesPath = detail.resourcesPath?.trim();
    if (resourcesPath != null && resourcesPath.isNotEmpty) {
      final directory = Directory(resourcesPath);
      await directory.create(recursive: true);
      return directory;
    }

    final temporaryDirectory = await _temporaryDirectoryProvider();
    final renderDirectory = Directory(
      '${temporaryDirectory.path}/dictionary_html',
    );
    await renderDirectory.create(recursive: true);
    return renderDirectory;
  }

  String _safeSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'dictionary' : sanitized;
  }

  String _signatureDigest(String signature) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in signature.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}
