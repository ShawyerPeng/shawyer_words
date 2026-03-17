import 'package:flutter/widgets.dart';
import 'package:shawyer_words/app/app.dart';

export 'package:shawyer_words/app/app.dart';

void main() {
  runApp(
    ShawyerWordsApp(
      lexDbPath: '/Users/shawyerpeng/develop/code/mdx2sqlite/db/LDOCE.db',
    ),
  );
}
