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

  test(
    'selecting remote book loads newline-separated entries and makes it current',
    () async {
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(
          remoteVocabularyLoader: (uri) async {
            expect(
              uri.toString(),
              'https://raw.githubusercontent.com/mahavivo/english-wordlists/refs/heads/master/CET_4%2B6_edited.txt',
            );
            return 'abandon\n\n brisk \nability\n';
          },
        ),
      );

      await controller.load();
      await controller.selectBook('cet46-remote');

      expect(controller.state.currentBook?.id, 'cet46-remote');
      expect(controller.state.currentBook?.title, 'CET 4+6');
      expect(
        controller.state.currentBook?.entries
            .map((entry) => entry.word)
            .toList(),
        <String>['abandon', 'brisk', 'ability'],
      );
    },
  );

  test('remote selection emits importing then success state', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri) async => 'alpha\nbeta\n',
      ),
    );
    final seenStates = <VocabularyImportStatus>[];

    controller.addListener(() {
      seenStates.add(controller.state.importStatus);
    });

    await controller.load();
    await controller.selectBook('cet46-remote');

    expect(seenStates, contains(VocabularyImportStatus.importing));
    expect(controller.state.importStatus, VocabularyImportStatus.success);
    expect(controller.state.importMessage, '词汇表导入成功');
  });

  test(
    'remote selection emits failure and preserves previous current book',
    () async {
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(
          remoteVocabularyLoader: (uri) async {
            throw Exception('network down');
          },
        ),
      );

      await controller.load();
      await controller.selectBook('ielts-complete');
      await controller.selectBook('cet46-remote');

      expect(controller.state.currentBook?.id, 'ielts-complete');
      expect(controller.state.importStatus, VocabularyImportStatus.failure);
      expect(controller.state.importMessage, contains('network down'));
    },
  );
}
