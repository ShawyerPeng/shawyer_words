import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';

typedef VocabularyDownloadProgressCallback =
    void Function(int receivedBytes, int? totalBytes);

abstract class StudyPlanRepository {
  Future<StudyPlanOverview> loadOverview();

  Future<List<OfficialVocabularyBook>> loadOfficialBooks();

  Future<void> selectBook(String bookId);

  Future<void> downloadBook(
    String bookId, {
    VocabularyDownloadProgressCallback? onProgress,
  });

  Future<void> selectNotebook(String notebookId);

  Future<void> createNotebook({required String name, String description = ''});

  Future<void> updateNotebook({
    required String notebookId,
    required String name,
    String description = '',
  });

  Future<void> deleteNotebook(String notebookId);

  Future<void> importWordsToNotebook({
    required String notebookId,
    required List<String> words,
  });
}
