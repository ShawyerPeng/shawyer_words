import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/study_srs/data/sqlite_fsrs_repository.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test(
    'loadLatestReviewLogsByWord returns the latest log for each word',
    () async {
      final repository = SqliteFsrsRepository(
        databasePath: ':memory:',
        databaseFactory: databaseFactoryFfiNoIsolate,
      );

      await repository.addReviewLog(
        FsrsReviewLog(
          word: 'abandon',
          rating: FsrsRating.again,
          state: FsrsState.learning,
          due: DateTime.utc(2026, 4, 5, 8),
          stability: 1,
          difficulty: 8,
          elapsedDays: 0,
          lastElapsedDays: 0,
          scheduledDays: 0,
          learningSteps: 0,
          reviewedAt: DateTime.utc(2026, 4, 5, 8),
        ),
      );
      await repository.addReviewLog(
        FsrsReviewLog(
          word: 'abandon',
          rating: FsrsRating.good,
          state: FsrsState.review,
          due: DateTime.utc(2026, 4, 10, 8),
          stability: 12,
          difficulty: 5,
          elapsedDays: 2,
          lastElapsedDays: 0,
          scheduledDays: 5,
          learningSteps: 0,
          reviewedAt: DateTime.utc(2026, 4, 5, 10),
        ),
      );
      await repository.addReviewLog(
        FsrsReviewLog(
          word: 'ability',
          rating: FsrsRating.easy,
          state: FsrsState.review,
          due: DateTime.utc(2026, 4, 12, 8),
          stability: 20,
          difficulty: 4,
          elapsedDays: 3,
          lastElapsedDays: 1,
          scheduledDays: 7,
          learningSteps: 0,
          reviewedAt: DateTime.utc(2026, 4, 5, 9),
        ),
      );

      final latestLogs = await repository.loadLatestReviewLogsByWord();

      expect(latestLogs, hasLength(2));
      expect(latestLogs['abandon']?.rating, FsrsRating.good);
      expect(latestLogs['ability']?.rating, FsrsRating.easy);

      await repository.close();
    },
  );
}
