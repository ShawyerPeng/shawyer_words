import 'dart:io';

import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';

class DictionaryHtmlDocument {
  const DictionaryHtmlDocument({required this.html, this.baseUrl});

  final String html;
  final String? baseUrl;
}

DictionaryHtmlDocument buildDictionaryHtmlDocument(
  DictionaryEntryDetail detail,
) {
  final baseUrl = _baseUrlFor(detail.resourcesPath);
  final stylesheetTags = [
    for (final path in detail.stylesheetPaths)
      '<link rel="stylesheet" href="${Uri.file(path).toString()}">',
  ].join('\n');
  final scriptTags = [
    for (final path in detail.scriptPaths)
      '<script src="${Uri.file(path).toString()}"></script>',
  ].join('\n');
  final baseTag = baseUrl == null ? '' : '<base href="$baseUrl">';

  return DictionaryHtmlDocument(
    baseUrl: baseUrl,
    html:
        '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    $baseTag
    $stylesheetTags
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: transparent;
      }

      body {
        color: #475467;
        font: -apple-system-body;
        line-height: 1.6;
        word-break: break-word;
      }
    </style>
  </head>
  <body>
    ${detail.rawContent}
    $scriptTags
  </body>
</html>
''',
  );
}

String? _baseUrlFor(String? resourcesPath) {
  if (resourcesPath == null || resourcesPath.trim().isEmpty) {
    return null;
  }

  final directory = Directory(resourcesPath);
  return Uri.directory(directory.absolute.path).toString();
}
