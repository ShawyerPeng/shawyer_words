import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:shawyer_words/features/dictionary/data/dictionary_package_scanner.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class PlatformDictionaryPreviewRepository
    implements DictionaryPreviewRepository {
  PlatformDictionaryPreviewRepository({
    this.stagingRootPath,
    DictionaryPackageScanner? scanner,
    MdxDictionaryParser? parser,
    DateTime Function()? clock,
  }) : _scanner = scanner ?? DictionaryPackageScanner(),
       _parser = parser ?? MdxDictionaryParser(),
       _clock = clock ?? DateTime.now;

  final String? stagingRootPath;
  final DictionaryPackageScanner _scanner;
  final MdxDictionaryParser _parser;
  final DateTime Function() _clock;

  @override
  Future<void> disposePreview(DictionaryImportPreview preview) async {
    final directory = Directory(preview.sourceRootPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<DictionaryPreviewPage> loadPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  }) async {
    final (start, end) = preview.entryRangeForPage(pageNumber);
    if (start == 0 || end == 0) {
      return DictionaryPreviewPage(pageNumber: pageNumber, entries: const []);
    }

    final keys = preview.entryKeys.sublist(start - 1, end);
    final entries = await _parser.loadPreviewPage(
      _packageFromPreview(preview),
      keys,
    );
    return DictionaryPreviewPage(pageNumber: pageNumber, entries: entries);
  }

  @override
  Future<WordEntry?> loadEntry({
    required DictionaryImportPreview preview,
    required String key,
  }) async {
    final entries = await _parser.loadPreviewPage(
      _packageFromPreview(preview),
      <String>[key],
    );
    if (entries.isEmpty) {
      return null;
    }
    return entries.first;
  }

  @override
  Future<DictionaryImportPreview> preparePreview(
    List<String> sourcePaths,
  ) async {
    final sessionRoot = await _createSessionRoot();
    try {
      for (final sourcePath in sourcePaths) {
        await _mergeSourceIntoSession(
          sourcePath: sourcePath,
          sessionRootPath: sessionRoot.path,
        );
      }

      final scan = await _scanner.scan(sessionRoot.path);
      final parserPreview = await _parser.buildPreview(
        DictionaryPackage(
          id: scan.id,
          name: scan.name,
          type: DictionaryPackageType.imported,
          rootPath: sessionRoot.path,
          mdxPath: scan.primaryMdxPath,
          mddPaths: scan.mddPaths,
          resourcesPath: sessionRoot.path,
          importedAt: _clock().toUtc().toIso8601String(),
        ),
      );

      return DictionaryImportPreview(
        sourceRootPath: sessionRoot.path,
        title: parserPreview.title,
        primaryMdxPath: parserPreview.primaryMdxPath,
        metadataText: parserPreview.metadataText,
        files: _mapFiles(scan),
        entryKeys: parserPreview.entryKeys,
        totalEntries: parserPreview.totalEntries,
        pageSize: parserPreview.pageSize,
      );
    } catch (_) {
      if (await sessionRoot.exists()) {
        await sessionRoot.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<Directory> _createSessionRoot() async {
    final basePath = stagingRootPath ?? Directory.systemTemp.path;
    final baseDirectory = Directory('$basePath/dictionary-preview-sessions');
    await baseDirectory.create(recursive: true);
    return baseDirectory.createTemp('session-');
  }

  Future<void> _mergeSourceIntoSession({
    required String sourcePath,
    required String sessionRootPath,
  }) async {
    final sourceDirectory = Directory(sourcePath);
    if (await sourceDirectory.exists()) {
      await _copyDirectoryContents(sourceDirectory, Directory(sessionRootPath));
      return;
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw ArgumentError.value(
        sourcePath,
        'sourcePath',
        'The selected preview source path does not exist.',
      );
    }

    if (_isArchive(sourcePath)) {
      await extractFileToDisk(sourcePath, sessionRootPath);
      return;
    }

    await _copyFile(sourcePath, '$sessionRootPath/${_basename(sourcePath)}');
  }

  Future<void> _copyDirectoryContents(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relativePath = _relativePath(
        rootPath: source.path,
        filePath: entity.path,
      );
      final destinationPath = '${destination.path}/$relativePath';
      if (entity is Directory) {
        await Directory(destinationPath).create(recursive: true);
        continue;
      }
      if (entity is File) {
        await _copyFile(entity.path, destinationPath);
      }
    }
  }

  Future<void> _copyFile(String sourcePath, String destinationPath) async {
    final destinationFile = File(destinationPath);
    await destinationFile.parent.create(recursive: true);
    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }
    await File(sourcePath).copy(destinationPath);
  }

  DictionaryPackage _packageFromPreview(DictionaryImportPreview preview) {
    return DictionaryPackage(
      id: _basenameWithoutExtension(preview.primaryMdxPath),
      name: preview.title,
      type: DictionaryPackageType.imported,
      rootPath: preview.sourceRootPath,
      mdxPath: preview.primaryMdxPath,
      mddPaths: [
        for (final file in preview.files)
          if (file.kind == DictionaryPreviewFileKind.mdd) file.path,
      ],
      resourcesPath: preview.sourceRootPath,
      importedAt: _clock().toUtc().toIso8601String(),
      entryCount: preview.totalEntries,
    );
  }

  List<DictionaryPreviewFile> _mapFiles(DictionaryPackageScanResult scan) {
    return [
      DictionaryPreviewFile(
        path: scan.primaryMdxPath,
        name: _basename(scan.primaryMdxPath),
        kind: DictionaryPreviewFileKind.mdx,
        isPrimary: true,
      ),
      for (final path in scan.mddPaths)
        DictionaryPreviewFile(
          path: path,
          name: _basename(path),
          kind: DictionaryPreviewFileKind.mdd,
        ),
      for (final path in scan.resourcePaths)
        DictionaryPreviewFile(
          path: path,
          name: _basename(path),
          kind: _fileKindForPath(path),
        ),
    ];
  }

  DictionaryPreviewFileKind _fileKindForPath(String path) {
    final lowercasePath = path.toLowerCase();
    if (lowercasePath.endsWith('.css')) {
      return DictionaryPreviewFileKind.css;
    }
    if (lowercasePath.endsWith('.js')) {
      return DictionaryPreviewFileKind.js;
    }
    return DictionaryPreviewFileKind.resource;
  }

  bool _isArchive(String sourcePath) {
    final lowercasePath = sourcePath.toLowerCase();
    return lowercasePath.endsWith('.zip') ||
        lowercasePath.endsWith('.tar') ||
        lowercasePath.endsWith('.tar.gz') ||
        lowercasePath.endsWith('.tgz') ||
        lowercasePath.endsWith('.tar.bz2') ||
        lowercasePath.endsWith('.tbz') ||
        lowercasePath.endsWith('.tar.xz') ||
        lowercasePath.endsWith('.txz');
  }

  String _basename(String filePath) {
    return filePath.replaceAll('\\', '/').split('/').last;
  }

  String _basenameWithoutExtension(String filePath) {
    final basename = _basename(filePath);
    final dotIndex = basename.lastIndexOf('.');
    if (dotIndex < 0) {
      return basename;
    }
    return basename.substring(0, dotIndex);
  }

  String _relativePath({required String rootPath, required String filePath}) {
    final normalizedRoot = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath
        : '$rootPath${Platform.pathSeparator}';
    if (filePath.startsWith(normalizedRoot)) {
      return filePath.substring(normalizedRoot.length);
    }
    return filePath;
  }
}
