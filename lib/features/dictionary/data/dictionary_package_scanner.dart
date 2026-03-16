import 'dart:io';

class DictionaryPackageScanResult {
  const DictionaryPackageScanResult({
    required this.id,
    required this.name,
    required this.primaryMdxPath,
    required this.mddPaths,
    required this.resourcePaths,
  });

  final String id;
  final String name;
  final String primaryMdxPath;
  final List<String> mddPaths;
  final List<String> resourcePaths;
}

class DictionaryPackageScanner {
  Future<DictionaryPackageScanResult> scan(String rootPath) async {
    final mdxPaths = <String>[];
    final mddPaths = <String>[];
    final resourcePaths = <String>[];

    await for (final entity in Directory(rootPath).list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      final filePath = entity.path;
      final relativePath = _relativePath(rootPath: rootPath, filePath: filePath);
      final normalizedRelativePath = relativePath.replaceAll('\\', '/');
      final lowercasePath = normalizedRelativePath.toLowerCase();

      if (
        normalizedRelativePath == 'manifest.json' ||
        normalizedRelativePath.startsWith('cache/')
      ) {
        continue;
      }

      if (lowercasePath.endsWith('.mdx')) {
        mdxPaths.add(filePath);
        continue;
      }
      if (lowercasePath.endsWith('.mdd')) {
        mddPaths.add(filePath);
        continue;
      }

      resourcePaths.add(filePath);
    }

    mdxPaths.sort();
    mddPaths.sort();
    resourcePaths.sort();

    if (mdxPaths.isEmpty) {
      throw UnsupportedError(
        'The selected dictionary package does not include an MDX file.',
      );
    }
    if (mdxPaths.length > 1) {
      throw UnsupportedError(
        'The selected dictionary package includes multiple MDX files and no deterministic primary file could be chosen.',
      );
    }

    final primaryMdxPath = mdxPaths.single;
    final name = _basenameWithoutExtension(primaryMdxPath);
    return DictionaryPackageScanResult(
      id: _slugify(name),
      name: name,
      primaryMdxPath: primaryMdxPath,
      mddPaths: mddPaths,
      resourcePaths: resourcePaths,
    );
  }

  String _basenameWithoutExtension(String filePath) {
    final filename = filePath.replaceAll('\\', '/').split('/').last;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0) {
      return filename;
    }
    return filename.substring(0, dotIndex);
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

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'dictionary' : slug;
  }
}
