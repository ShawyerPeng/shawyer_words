import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BundledLexDbInstaller {
  BundledLexDbInstaller({
    AssetBundle? assetBundle,
    Future<Directory> Function()? supportDirectoryResolver,
    this.assetPath = 'assets/lexdb/LDOCE.db',
    this.version = '20260320',
    this.dbFileName = 'LDOCE.db',
  }) : _assetBundle = assetBundle ?? rootBundle,
       _supportDirectoryResolver =
           supportDirectoryResolver ?? getApplicationSupportDirectory;

  final AssetBundle _assetBundle;
  final Future<Directory> Function() _supportDirectoryResolver;
  final String assetPath;
  final String version;
  final String dbFileName;

  Future<String?> ensureInstalled() async {
    final supportDirectory = await _supportDirectoryResolver();
    final targetDirectory = Directory('${supportDirectory.path}/lexdb');
    final dbFile = File('${targetDirectory.path}/$dbFileName');
    final manifestFile = File('${targetDirectory.path}/manifest.json');

    final currentManifest = await _readManifest(manifestFile);
    final needsInstall =
        !await dbFile.exists() || currentManifest['version'] != version;

    if (!needsInstall) {
      return dbFile.path;
    }

    final dbBytes = await _loadBundledDbBytes();
    if (dbBytes == null) {
      return await dbFile.exists() ? dbFile.path : null;
    }

    await targetDirectory.create(recursive: true);
    final tempFile = File('${dbFile.path}.tmp');
    await tempFile.writeAsBytes(dbBytes, flush: true);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    await tempFile.rename(dbFile.path);

    await manifestFile.writeAsString(
      jsonEncode(<String, Object?>{
        'version': version,
        'assetPath': assetPath,
        'dbFileName': dbFileName,
      }),
      flush: true,
    );

    return dbFile.path;
  }

  Future<Map<String, Object?>> _readManifest(File manifestFile) async {
    if (!await manifestFile.exists()) {
      return const <String, Object?>{};
    }
    try {
      final raw = await manifestFile.readAsString();
      if (raw.trim().isEmpty) {
        return const <String, Object?>{};
      }
      return Map<String, Object?>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  Future<Uint8List?> _loadBundledDbBytes() async {
    try {
      final byteData = await _assetBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
