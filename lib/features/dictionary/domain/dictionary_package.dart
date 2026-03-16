enum DictionaryPackageType { bundled, imported }

class DictionaryPackage {
  const DictionaryPackage({
    required this.id,
    required this.name,
    required this.type,
    required this.rootPath,
    required this.mdxPath,
    required this.mddPaths,
    required this.resourcesPath,
    required this.importedAt,
    this.entryCount,
    this.version,
    this.category,
    this.dictionaryAttribute,
    this.fileSizeBytes,
  });

  final String id;
  final String name;
  final DictionaryPackageType type;
  final String rootPath;
  final String mdxPath;
  final List<String> mddPaths;
  final String resourcesPath;
  final String importedAt;
  final int? entryCount;
  final String? version;
  final String? category;
  final String? dictionaryAttribute;
  final int? fileSizeBytes;
}
