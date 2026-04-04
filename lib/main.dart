import 'package:flutter/widgets.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/lexdb/data/bundled_lexdb_installer.dart';

export 'package:shawyer_words/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lexDbPath = await BundledLexDbInstaller().ensureInstalled();

  runApp(ShawyerWordsApp(lexDbPath: lexDbPath));
}
