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
        overflow: hidden;
      }

      body {
        color: #475467;
        font: -apple-system-body;
        line-height: 1.6;
        word-break: break-word;
      }

      #shawyer-root {
        display: block;
      }
    </style>
    <script>
      window.__shawyerLastReportedHeight = 0;
      window.__shawyerPendingHeightReport = null;

      function __shawyerReportHeight() {
        var root = document.getElementById('shawyer-root');
        if (!root) {
          return;
        }
        var rect = root.getBoundingClientRect();
        var height = Math.max(
          root.scrollHeight || 0,
          root.offsetHeight || 0,
          rect.height || 0
        );

        if (Math.abs(height - window.__shawyerLastReportedHeight) < 8) {
          return;
        }
        window.__shawyerLastReportedHeight = height;
        if (window.ShawyerResize && ShawyerResize.postMessage) {
          ShawyerResize.postMessage(String(Math.ceil(height)));
        }
      }

      window.__shawyerScheduleHeightReport = function(delay) {
        if (window.__shawyerPendingHeightReport) {
          clearTimeout(window.__shawyerPendingHeightReport);
        }
        window.__shawyerPendingHeightReport = setTimeout(function() {
          window.__shawyerPendingHeightReport = null;
          __shawyerReportHeight();
        }, delay || 0);
      };

      window.addEventListener('load', function() {
        setTimeout(function() { __shawyerScheduleHeightReport(0); }, 120);
        setTimeout(function() { __shawyerScheduleHeightReport(0); }, 400);
        setTimeout(function() { __shawyerScheduleHeightReport(0); }, 900);
      });

      document.addEventListener('click', function() {
        __shawyerScheduleHeightReport(0);
        setTimeout(function() { __shawyerScheduleHeightReport(0); }, 180);
        setTimeout(function() { __shawyerScheduleHeightReport(0); }, 480);
        setTimeout(function() { __shawyerScheduleHeightReport(0); }, 960);
      }, true);
    </script>
  </head>
  <body>
    <div id="shawyer-root">${detail.rawContent}</div>
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
