import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_manifest.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  test('manifest serialization preserves bundled vs imported types', () {
    const manifest = DictionaryManifest(
      id: 'oxford-mini',
      name: 'Oxford Mini',
      type: DictionaryPackageType.imported,
      rootPath: '/app-data/dictionaries/imported/oxford-mini',
      mdxPath: '/app-data/dictionaries/imported/oxford-mini/source/main.mdx',
      mddPaths: <String>[
        '/app-data/dictionaries/imported/oxford-mini/source/main.mdd',
      ],
      resourcesPath: '/app-data/dictionaries/imported/oxford-mini/resources',
      importedAt: '2026-03-16T00:00:00.000Z',
      entryCount: 24,
      version: '20251021',
      category: '默认',
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 94371840,
    );

    final decoded = DictionaryManifest.fromJson(manifest.toJson());

    expect(decoded.type, DictionaryPackageType.imported);
    expect(decoded.mdxPath, endsWith('main.mdx'));
    expect(decoded.mddPaths.single, endsWith('main.mdd'));
    expect(decoded.entryCount, 24);
    expect(decoded.version, '20251021');
    expect(decoded.category, '默认');
    expect(decoded.dictionaryAttribute, '本地词典');
    expect(decoded.fileSizeBytes, 94371840);
  });

  test('manifest converts into a package with deterministic primary mdx path', () {
    const manifest = DictionaryManifest(
      id: 'bundled-core',
      name: 'Bundled Core',
      type: DictionaryPackageType.bundled,
      rootPath: '/app-data/dictionaries/bundled/bundled-core',
      mdxPath: '/app-data/dictionaries/bundled/bundled-core/source/core.mdx',
      mddPaths: <String>[],
      resourcesPath: '/app-data/dictionaries/bundled/bundled-core/resources',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20251021',
      category: '默认',
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 90 * 1024 * 1024,
    );

    final package = manifest.toPackage();

    expect(package.type, DictionaryPackageType.bundled);
    expect(package.mdxPath, endsWith('core.mdx'));
    expect(package.mddPaths, isEmpty);
    expect(package.rootPath, contains('/bundled/'));
    expect(package.version, '20251021');
    expect(package.category, '默认');
    expect(package.dictionaryAttribute, '本地词典');
    expect(package.fileSizeBytes, 90 * 1024 * 1024);
  });
}
