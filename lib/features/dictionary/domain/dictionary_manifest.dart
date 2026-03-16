import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

class DictionaryManifest {
  const DictionaryManifest({
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

  DictionaryPackage toPackage() {
    return DictionaryPackage(
      id: id,
      name: name,
      type: type,
      rootPath: rootPath,
      mdxPath: mdxPath,
      mddPaths: mddPaths,
      resourcesPath: resourcesPath,
      importedAt: importedAt,
      entryCount: entryCount,
      version: version,
      category: category,
      dictionaryAttribute: dictionaryAttribute,
      fileSizeBytes: fileSizeBytes,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type.name,
      'rootPath': rootPath,
      'mdxPath': mdxPath,
      'mddPaths': mddPaths,
      'resourcesPath': resourcesPath,
      'importedAt': importedAt,
      'entryCount': entryCount,
      'version': version,
      'category': category,
      'dictionaryAttribute': dictionaryAttribute,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory DictionaryManifest.fromJson(Map<String, Object?> json) {
    return DictionaryManifest(
      id: json['id']! as String,
      name: json['name']! as String,
      type: DictionaryPackageType.values.byName(json['type']! as String),
      rootPath: json['rootPath']! as String,
      mdxPath: json['mdxPath']! as String,
      mddPaths: List<String>.from(json['mddPaths']! as List<Object?>),
      resourcesPath: json['resourcesPath']! as String,
      importedAt: json['importedAt']! as String,
      entryCount: json['entryCount'] as int?,
      version: json['version'] as String?,
      category: json['category'] as String?,
      dictionaryAttribute: json['dictionaryAttribute'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
    );
  }
}
