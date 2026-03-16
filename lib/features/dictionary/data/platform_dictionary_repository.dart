import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';
import 'package:shawyer_words/features/dictionary/data/file_system_dictionary_storage.dart';
import 'package:shawyer_words/features/dictionary/data/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package_importer.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:path_provider/path_provider.dart';

class PlatformDictionaryRepository implements DictionaryRepository {
  PlatformDictionaryRepository({
    DictionaryPackageImporter? importer,
    MdxDictionaryParser? parser,
  }) : _importer = importer ?? _defaultImporter(),
       _parser = parser ?? MdxDictionaryParser();

  final DictionaryPackageImporter _importer;
  final MdxDictionaryParser _parser;

  @override
  Future<DictionaryImportResult> importDictionary(String sourcePath) async {
    final package = await _importer.importPackage(sourcePath);
    return _parser.parse(package);
  }

  static DictionaryPackageImporter _defaultImporter() {
    return FileSystemDictionaryPackageImporter(
      rootPathResolver: _dictionaryRootPath,
      storage: FileSystemDictionaryStorage(
        rootPathResolver: _dictionaryRootPath,
      ),
    );
  }

  static Future<String> _dictionaryRootPath() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return '${supportDirectory.path}/dictionaries';
  }
}
