import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';

abstract class FsrsRepository {
  Future<FsrsCard?> getByWord(String word);

  Future<List<FsrsCard>> loadAll();

  Future<void> saveCard(FsrsCard card);

  Future<void> addReviewLog(FsrsReviewLog log);

  Future<void> saveReview(FsrsRecordLogItem item) async {
    await saveCard(item.card);
    await addReviewLog(item.log);
  }

  Future<Map<String, FsrsReviewLog>> loadLatestReviewLogsByWord() async {
    return <String, FsrsReviewLog>{};
  }

  Future<void> clearAll();
}
