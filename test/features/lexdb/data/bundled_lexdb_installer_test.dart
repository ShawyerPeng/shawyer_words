import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/lexdb/data/bundled_lexdb_installer.dart';

void main() {
  group('BundledLexDbInstaller', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'bundled-lexdb-installer-',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('installs bundled database when missing', () async {
      final installer = BundledLexDbInstaller(
        assetBundle: _FakeAssetBundle(<String, List<int>>{
          'assets/lexdb/LDOCE.db': <int>[1, 2, 3, 4],
        }),
        supportDirectoryResolver: () async => tempDirectory,
        version: 'v1',
      );

      final installedPath = await installer.ensureInstalled();

      expect(installedPath, isNotNull);
      expect(await File(installedPath!).readAsBytes(), <int>[1, 2, 3, 4]);
      final manifest = jsonDecode(
        await File('${tempDirectory.path}/lexdb/manifest.json').readAsString(),
      );
      expect(manifest['version'], 'v1');
    });

    test('keeps existing database when version is unchanged', () async {
      final first = BundledLexDbInstaller(
        assetBundle: _FakeAssetBundle(<String, List<int>>{
          'assets/lexdb/LDOCE.db': <int>[1, 2, 3],
        }),
        supportDirectoryResolver: () async => tempDirectory,
        version: 'same',
      );
      await first.ensureInstalled();

      final second = BundledLexDbInstaller(
        assetBundle: _FakeAssetBundle(<String, List<int>>{
          'assets/lexdb/LDOCE.db': <int>[9, 9, 9],
        }),
        supportDirectoryResolver: () async => tempDirectory,
        version: 'same',
      );
      final installedPath = await second.ensureInstalled();

      expect(await File(installedPath!).readAsBytes(), <int>[1, 2, 3]);
    });

    test('reinstalls bundled database when version changes', () async {
      final first = BundledLexDbInstaller(
        assetBundle: _FakeAssetBundle(<String, List<int>>{
          'assets/lexdb/LDOCE.db': <int>[1, 2, 3],
        }),
        supportDirectoryResolver: () async => tempDirectory,
        version: 'v1',
      );
      await first.ensureInstalled();

      final second = BundledLexDbInstaller(
        assetBundle: _FakeAssetBundle(<String, List<int>>{
          'assets/lexdb/LDOCE.db': <int>[7, 8, 9],
        }),
        supportDirectoryResolver: () async => tempDirectory,
        version: 'v2',
      );
      final installedPath = await second.ensureInstalled();

      expect(await File(installedPath!).readAsBytes(), <int>[7, 8, 9]);
      final manifest = jsonDecode(
        await File('${tempDirectory.path}/lexdb/manifest.json').readAsString(),
      );
      expect(manifest['version'], 'v2');
    });

    test('returns null when bundled database asset is missing', () async {
      final installer = BundledLexDbInstaller(
        assetBundle: _FakeAssetBundle(const <String, List<int>>{}),
        supportDirectoryResolver: () async => tempDirectory,
      );

      final installedPath = await installer.ensureInstalled();

      expect(installedPath, isNull);
    });
  });
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, List<int>> _assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = _assets[key];
    if (bytes == null) {
      throw Exception('Unable to load asset: $key');
    }
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}
