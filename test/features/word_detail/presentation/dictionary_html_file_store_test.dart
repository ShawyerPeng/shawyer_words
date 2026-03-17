import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_document.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_file_store.dart';

void main() {
  test(
    'writes rendered html into dictionary resources directory when present',
    () async {
      final resourcesDirectory = await Directory.systemTemp.createTemp(
        'dictionary_html_resources_',
      );
      addTearDown(() async {
        if (await resourcesDirectory.exists()) {
          await resourcesDirectory.delete(recursive: true);
        }
      });

      final store = DictionaryHtmlFileStore();
      final detail = DictionaryEntryDetail(
        dictionaryId: 'collins',
        dictionaryName: 'Collins',
        word: 'abandon',
        rawContent: '<div>content</div>',
        resourcesPath: resourcesDirectory.path,
      );

      final file = await store.writeDocument(
        detail: detail,
        document: buildDictionaryHtmlDocument(detail),
        signature: 'collins|abandon|content',
      );

      expect(file.path.startsWith(resourcesDirectory.path), isTrue);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), contains('<div>content</div>'));
    },
  );

  test(
    'falls back to a temporary render directory when resources are missing',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'dictionary_html_fallback_',
      );
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });

      final store = DictionaryHtmlFileStore(
        temporaryDirectoryProvider: () async => temporaryDirectory,
      );
      const detail = DictionaryEntryDetail(
        dictionaryId: 'plain',
        dictionaryName: 'Plain',
        word: 'abandon',
        rawContent: '<div>content</div>',
      );

      final file = await store.writeDocument(
        detail: detail,
        document: buildDictionaryHtmlDocument(detail),
        signature: 'plain|abandon|content',
      );

      expect(
        file.path,
        contains('${temporaryDirectory.path}/dictionary_html/'),
      );
      expect(await file.exists(), isTrue);
    },
  );
}
