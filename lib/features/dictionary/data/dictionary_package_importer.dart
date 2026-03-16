import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:shawyer_words/features/dictionary/data/dictionary_root_path_resolver.dart';
import 'package:shawyer_words/features/dictionary/data/dictionary_package_scanner.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';

class FileSystemDictionaryPackageImporter implements DictionaryPackageImporter {
  FileSystemDictionaryPackageImporter({
    this.rootPath,
    DictionaryRootPathResolver? rootPathResolver,
    required DictionaryStorage storage,
    DictionaryPackageScanner? scanner,
    DateTime Function()? clock,
  }) : _storage = storage,
       _rootPathResolver = rootPathResolver,
       _scanner = scanner ?? DictionaryPackageScanner(),
       _clock = clock ?? DateTime.now;

  final String? rootPath;
  final DictionaryRootPathResolver? _rootPathResolver;
  final DictionaryStorage _storage;
  final DictionaryPackageScanner _scanner;
  final DateTime Function() _clock;

  @override
  Future<DictionaryPackage> importPackage(String sourcePath) async {
    final stagingDirectory = await _createStagingDirectory();
    String? packageRootPath;
    String? packageId;

    try {
      final stagingContentPath = '${stagingDirectory.path}/content';
      await Directory(stagingContentPath).create(recursive: true);
      await _copySourceIntoStaging(
        sourcePath: sourcePath,
        stagingContentPath: stagingContentPath,
      );

      final scan = await _scanner.scan(stagingContentPath);
      packageId = await _resolvePackageId(scan.id);
      packageRootPath = await _storage.createPackageDirectories(
        type: DictionaryPackageType.imported,
        id: packageId,
      );

      final sourceRoot = '$packageRootPath/source';
      final resourcesRoot = '$packageRootPath/resources';
      final mdxPath = '$sourceRoot/${_basename(scan.primaryMdxPath)}';
      await _copyFile(scan.primaryMdxPath, mdxPath);

      final mddPaths = <String>[];
      for (final mddPath in scan.mddPaths) {
        final destinationPath = '$sourceRoot/${_basename(mddPath)}';
        await _copyFile(mddPath, destinationPath);
        mddPaths.add(destinationPath);
      }

      for (final resourcePath in scan.resourcePaths) {
        final destinationPath = '$resourcesRoot/${_relativePath(
          rootPath: stagingContentPath,
          filePath: resourcePath,
        )}';
        await _copyFile(resourcePath, destinationPath);
      }

      final manifest = await _storage.writeManifest(
        DictionaryManifest(
          id: packageId,
          name: scan.name,
          type: DictionaryPackageType.imported,
          rootPath: packageRootPath,
          mdxPath: mdxPath,
          mddPaths: mddPaths,
          resourcesPath: resourcesRoot,
          importedAt: _clock().toUtc().toIso8601String(),
        ),
      );
      return manifest.toPackage();
    } catch (_) {
      if (packageRootPath != null && packageId != null) {
        await _storage.deletePackage(
          type: DictionaryPackageType.imported,
          id: packageId,
        );
      }
      rethrow;
    } finally {
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
      await _cleanupStagingRootIfEmpty();
    }
  }

  Future<Directory> _createStagingDirectory() async {
    final resolvedRootPath = await _resolveRootPath();
    final stagingRoot = Directory('$resolvedRootPath/_staging');
    await stagingRoot.create(recursive: true);
    return stagingRoot.createTemp('dictionary-import-');
  }

  Future<void> _cleanupStagingRootIfEmpty() async {
    final resolvedRootPath = await _resolveRootPath();
    final stagingRoot = Directory('$resolvedRootPath/_staging');
    if (!await stagingRoot.exists()) {
      return;
    }

    if (await stagingRoot.list().isEmpty) {
      await stagingRoot.delete();
    }
  }

  Future<void> _copySourceIntoStaging({
    required String sourcePath,
    required String stagingContentPath,
  }) async {
    final sourceDirectory = Directory(sourcePath);
    if (await sourceDirectory.exists()) {
      await _copyDirectoryContents(sourceDirectory, Directory(stagingContentPath));
      return;
    }

    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      if (_isSingleDictionaryFile(sourcePath)) {
        await _copyFile(
          sourcePath,
          '$stagingContentPath/${_basename(sourcePath)}',
        );
        return;
      }
      await extractFileToDisk(sourcePath, stagingContentPath);
      return;
    }

    throw ArgumentError.value(
      sourcePath,
      'sourcePath',
      'The selected dictionary package path does not exist.',
    );
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
    await File(sourcePath).copy(destinationPath);
  }

  Future<String> _resolvePackageId(String baseId) async {
    final resolvedRootPath = await _resolveRootPath();
    var candidate = baseId;
    var suffix = 2;
    while (await Directory(
      '$resolvedRootPath/${DictionaryPackageType.imported.name}/$candidate',
    ).exists()) {
      candidate = '$baseId-$suffix';
      suffix += 1;
    }
    return candidate;
  }

  String _basename(String filePath) {
    return filePath.replaceAll('\\', '/').split('/').last;
  }

  bool _isSingleDictionaryFile(String filePath) {
    return filePath.toLowerCase().endsWith('.mdx');
  }

  String _relativePath({
    required String rootPath,
    required String filePath,
  }) {
    final normalizedRoot = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath
        : '$rootPath${Platform.pathSeparator}';
    if (filePath.startsWith(normalizedRoot)) {
      return filePath.substring(normalizedRoot.length);
    }
    return filePath;
  }

  Future<String> _resolveRootPath() async {
    if (rootPath != null) {
      return rootPath!;
    }
    if (_rootPathResolver != null) {
      return _rootPathResolver();
    }
    throw StateError('A dictionary root path or resolver is required.');
  }
}
