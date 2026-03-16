import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dict_reader/dict_reader.dart' as dict_reader;
import 'package:mdict_flutter/mdict_flutter.dart' as mdict_flutter;
import 'package:mdict_reader/mdict_reader.dart' as mdict_reader;

Future<void> main(List<String> args) async {
  final root = args.isNotEmpty
      ? Directory(args.first)
      : Directory('/Users/shawyerpeng/Library/Eudb_en');
  if (!root.existsSync()) {
    stderr.writeln('Directory does not exist: ${root.path}');
    exitCode = 1;
    return;
  }

  final files = root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.mdx'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('Benchmarking ${files.length} MDX files under ${root.path}');

  final backends = <Backend>[
    Backend(name: 'qingshan/mdict_reader', run: _runQingshanMdictReader),
    Backend(name: 'mumu-lhl/dict_reader', run: _runMumuDictReader),
    Backend(name: 'stevennight/mdict_flutter', run: _runStevennightMdictFlutter),
  ];

  final results = <FileBenchmarkResult>[];
  for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
    final file = files[fileIndex];
    stdout.writeln('[${fileIndex + 1}/${files.length}] ${file.path}');
    final header = await _readHeader(file);
    final backendResults = <BackendResult>[];

    for (final backend in backends) {
      final startedAt = DateTime.now();
      try {
        final sample = await runZoned(
          () => backend.run(file.path).timeout(
                const Duration(seconds: 20),
                onTimeout: () => throw TimeoutException(
                  'Timed out after 20 seconds',
                ),
              ),
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) {},
          ),
        );
        backendResults.add(
          BackendResult(
            backend: backend.name,
            success: true,
            elapsedMs: DateTime.now().difference(startedAt).inMilliseconds,
            sampleKey: sample.key,
            sampleLength: sample.content.length,
          ),
        );
      } catch (error, stackTrace) {
        backendResults.add(
          BackendResult(
            backend: backend.name,
            success: false,
            elapsedMs: DateTime.now().difference(startedAt).inMilliseconds,
            errorType: error.runtimeType.toString(),
            errorMessage: _normalizeError(error),
            stackTop: _topStackLine(stackTrace),
          ),
        );
      }
    }

    results.add(
      FileBenchmarkResult(
        path: file.path,
        header: header,
        backendResults: backendResults,
      ),
    );
  }

  final summary = _buildSummary(results);
  final outputDir = Directory('tool/parser_backend_benchmark/output')
    ..createSync(recursive: true);

  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final jsonFile = File('${outputDir.path}/benchmark-$timestamp.json');
  final markdownFile = File('${outputDir.path}/benchmark-$timestamp.md');

  jsonFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary.toJson()),
  );
  markdownFile.writeAsStringSync(summary.toMarkdown());

  stdout.writeln('');
  stdout.writeln(summary.toMarkdown());
  stdout.writeln('');
  stdout.writeln('Saved JSON report to ${jsonFile.path}');
  stdout.writeln('Saved Markdown report to ${markdownFile.path}');
}

Future<SampleRecord> _runStevennightMdictFlutter(String path) async {
  final reader = mdict_flutter.MdictReader(path);
  await reader.open();
  try {
    for (var blockId = 0; blockId < reader.keyBlockInfoList.length; blockId++) {
      final keys = reader.decodeKeyBlockById(blockId);
      for (final item in keys) {
        final key = item.key.trim();
        if (key.isEmpty) {
          continue;
        }
        final content = await reader.lookup(key);
        if (content != null && content.trim().isNotEmpty) {
          return SampleRecord(key: key, content: content);
        }
      }
    }
    throw StateError('No readable key/value pair found.');
  } finally {
    await reader.close();
  }
}

Future<SampleRecord> _runQingshanMdictReader(String path) async {
  final reader = mdict_reader.MdictReader(path);
  final keys = reader.keys();
  if (keys.isEmpty) {
    throw StateError('No keys returned.');
  }
  for (final key in keys) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) {
      continue;
    }
    final content = reader.query(cleaned);
    if (content is String && content.trim().isNotEmpty) {
      return SampleRecord(key: cleaned, content: content);
    }
  }
  throw StateError('No readable record returned from available keys.');
}

Future<SampleRecord> _runMumuDictReader(String path) async {
  final reader = dict_reader.DictReader(path);
  await reader.initDict();
  try {
    await for (final offset in reader.readWithOffset()) {
      final key = offset.keyText.trim();
      if (key.isEmpty) {
        continue;
      }
      final content = await reader.readOneMdx(offset);
      if (content.trim().isNotEmpty) {
        return SampleRecord(key: key, content: content);
      }
    }
    throw StateError('No readable offset/data pair found.');
  } finally {
    await reader.close();
  }
}

Future<Map<String, String>> _readHeader(File file) async {
  final raf = await file.open();
  try {
    final headerLengthBytes = await raf.read(4);
    if (headerLengthBytes.length < 4) {
      return const <String, String>{};
    }

    final headerLength = ByteData.sublistView(
      Uint8List.fromList(headerLengthBytes),
    ).getUint32(0);
    if (headerLength <= 0 || headerLength > 200000) {
      return const <String, String>{};
    }

    final headerBytes = await raf.read(headerLength);
    if (headerBytes.length < headerLength) {
      return const <String, String>{};
    }

    final codeUnits = <int>[];
    for (var index = 0; index + 1 < headerBytes.length; index += 2) {
      codeUnits.add(headerBytes[index] | (headerBytes[index + 1] << 8));
    }

    final headerText = String.fromCharCodes(codeUnits);
    final matches = RegExp(r'(\w+)\s*=\s*"([\s\S]*?)"').allMatches(headerText);

    final attributes = <String, String>{};
    for (final match in matches) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        attributes[key] = value;
      }
    }
    return attributes;
  } finally {
    await raf.close();
  }
}

String _normalizeError(Object error) {
  final text = '$error'.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.length <= 240 ? text : '${text.substring(0, 237)}...';
}

String _topStackLine(StackTrace stackTrace) {
  final lines = stackTrace.toString().trim().split('\n');
  return lines.isEmpty ? '' : lines.first.trim();
}

BenchmarkSummary _buildSummary(List<FileBenchmarkResult> results) {
  final backendNames = results.isEmpty
      ? const <String>[]
      : results.first.backendResults.map((result) => result.backend).toList();
  final backendSummaries = <BackendSummary>[];

  for (final backend in backendNames) {
    final rows = results
        .map((result) => result.backendResults.firstWhere((r) => r.backend == backend))
        .toList();
    final successRows = rows.where((row) => row.success).toList();
    final failureRows = rows.where((row) => !row.success).toList();
    final failuresByMessage = <String, int>{};
    for (final row in failureRows) {
      final key = row.errorMessage ?? row.errorType ?? 'Unknown failure';
      failuresByMessage.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    backendSummaries.add(
      BackendSummary(
        backend: backend,
        total: rows.length,
        success: successRows.length,
        failure: failureRows.length,
        avgElapsedMs: successRows.isEmpty
            ? null
            : successRows.map((row) => row.elapsedMs).reduce((a, b) => a + b) /
                successRows.length,
        topFailures: failuresByMessage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      ),
    );
  }

  final segmented = <String, Map<String, int>>{};
  for (final result in results) {
    final encrypted = result.header['Encrypted'] ?? 'unknown';
    segmented.putIfAbsent(encrypted, () => <String, int>{});
    for (final backendResult in result.backendResults) {
      final key = '${backendResult.backend}:${backendResult.success ? 'success' : 'failure'}';
      segmented[encrypted]!.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  return BenchmarkSummary(
    totalFiles: results.length,
    backendSummaries: backendSummaries,
    encryptedBreakdown: segmented,
    fileResults: results,
  );
}

class Backend {
  const Backend({
    required this.name,
    required this.run,
  });

  final String name;
  final Future<SampleRecord> Function(String path) run;
}

class SampleRecord {
  const SampleRecord({
    required this.key,
    required this.content,
  });

  final String key;
  final String content;
}

class BackendResult {
  const BackendResult({
    required this.backend,
    required this.success,
    required this.elapsedMs,
    this.sampleKey,
    this.sampleLength,
    this.errorType,
    this.errorMessage,
    this.stackTop,
  });

  final String backend;
  final bool success;
  final int elapsedMs;
  final String? sampleKey;
  final int? sampleLength;
  final String? errorType;
  final String? errorMessage;
  final String? stackTop;

  Map<String, Object?> toJson() => <String, Object?>{
        'backend': backend,
        'success': success,
        'elapsedMs': elapsedMs,
        'sampleKey': sampleKey,
        'sampleLength': sampleLength,
        'errorType': errorType,
        'errorMessage': errorMessage,
        'stackTop': stackTop,
      };
}

class FileBenchmarkResult {
  const FileBenchmarkResult({
    required this.path,
    required this.header,
    required this.backendResults,
  });

  final String path;
  final Map<String, String> header;
  final List<BackendResult> backendResults;

  Map<String, Object?> toJson() => <String, Object?>{
        'path': path,
        'header': header,
        'backendResults': backendResults.map((result) => result.toJson()).toList(),
      };
}

class BackendSummary {
  const BackendSummary({
    required this.backend,
    required this.total,
    required this.success,
    required this.failure,
    required this.avgElapsedMs,
    required this.topFailures,
  });

  final String backend;
  final int total;
  final int success;
  final int failure;
  final double? avgElapsedMs;
  final List<MapEntry<String, int>> topFailures;

  Map<String, Object?> toJson() => <String, Object?>{
        'backend': backend,
        'total': total,
        'success': success,
        'failure': failure,
        'avgElapsedMs': avgElapsedMs,
        'topFailures': topFailures
            .map((entry) => <String, Object?>{'message': entry.key, 'count': entry.value})
            .toList(),
      };
}

class BenchmarkSummary {
  const BenchmarkSummary({
    required this.totalFiles,
    required this.backendSummaries,
    required this.encryptedBreakdown,
    required this.fileResults,
  });

  final int totalFiles;
  final List<BackendSummary> backendSummaries;
  final Map<String, Map<String, int>> encryptedBreakdown;
  final List<FileBenchmarkResult> fileResults;

  Map<String, Object?> toJson() => <String, Object?>{
        'totalFiles': totalFiles,
        'backendSummaries': backendSummaries.map((summary) => summary.toJson()).toList(),
        'encryptedBreakdown': encryptedBreakdown,
        'fileResults': fileResults.map((result) => result.toJson()).toList(),
      };

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Parser Backend Benchmark');
    buffer.writeln('');
    buffer.writeln('- Total files: $totalFiles');
    buffer.writeln('');
    buffer.writeln('## Summary');
    buffer.writeln('');
    buffer.writeln('| Backend | Success | Failure | Avg ms (success only) |');
    buffer.writeln('| --- | ---: | ---: | ---: |');
    for (final summary in backendSummaries) {
      final avg = summary.avgElapsedMs == null
          ? '-'
          : summary.avgElapsedMs!.toStringAsFixed(1);
      buffer.writeln(
        '| ${summary.backend} | ${summary.success} | ${summary.failure} | $avg |',
      );
    }

    buffer.writeln('');
    buffer.writeln('## Top Failures');
    buffer.writeln('');
    for (final summary in backendSummaries) {
      buffer.writeln('### ${summary.backend}');
      if (summary.topFailures.isEmpty) {
        buffer.writeln('- No failures');
      } else {
        for (final entry in summary.topFailures.take(5)) {
          buffer.writeln('- ${entry.value}x ${entry.key}');
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('## Encrypted Breakdown');
    buffer.writeln('');
    for (final entry in encryptedBreakdown.entries) {
      buffer.writeln('### Encrypted=${entry.key}');
      final keys = entry.value.keys.toList()..sort();
      for (final key in keys) {
        buffer.writeln('- $key: ${entry.value[key]}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
