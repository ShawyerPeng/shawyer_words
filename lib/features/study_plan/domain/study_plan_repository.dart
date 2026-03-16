import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';

abstract class StudyPlanRepository {
  Future<StudyPlanOverview> loadOverview();

  Future<List<OfficialVocabularyBook>> loadOfficialBooks();

  Future<void> selectBook(String bookId);
}
