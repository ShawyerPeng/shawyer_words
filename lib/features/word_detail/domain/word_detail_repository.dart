import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';

abstract class WordDetailRepository {
  Future<WordDetail> load(String word);
}
