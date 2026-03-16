import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/data/in_memory_study_plan_repository.dart';

void main() {
  test(
    'load exposes empty state and selecting a book makes it current',
    () async {
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(),
      );

      await controller.load();

      expect(controller.state.currentBook, isNull);
      expect(controller.state.myBooks, isEmpty);

      await controller.selectBook('ielts-complete');

      expect(controller.state.currentBook?.id, 'ielts-complete');
      expect(
        controller.state.myBooks.map((book) => book.id),
        contains('ielts-complete'),
      );
    },
  );
}
