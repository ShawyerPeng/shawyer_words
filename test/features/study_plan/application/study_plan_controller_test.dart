import 'dart:async';
import 'dart:io';

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

  test('downloading remote book loads newline-separated entries', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async {
          expect(
            uri.toString(),
            'https://shawyerpeng.cn/CET_4+6_edited.txt',
          );
          return 'abandon\n\n brisk \nability\n';
        },
      ),
    );

    await controller.load();
    final downloaded = await controller.downloadBook('cet46-remote');

    expect(downloaded, isTrue);
    expect(controller.state.currentBook, isNull);
    final remoteBook = controller.state.officialBooks.firstWhere(
      (book) => book.id == 'cet46-remote',
    );
    expect(remoteBook.title, 'CET 4+6');
    expect(remoteBook.entries.map((entry) => entry.word).toList(), <String>[
      'abandon',
      'brisk',
      'ability',
    ]);
    expect(
      controller.state.downloadStates['cet46-remote']?.status,
      VocabularyDownloadStatus.downloaded,
    );
  });

  test(
    'downloading remote book falls back to GitHub contents API after raw fetch reset',
    () async {
      final requestedUris = <String>[];
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(
          remoteVocabularyLoader: (uri, {onProgress}) async {
            requestedUris.add(uri.toString());
            if (uri.host == 'shawyerpeng.cn') {
              throw const HttpException('Connection reset by peer');
            }
            if (uri.host == 'raw.githubusercontent.com') {
              throw const HttpException('Connection reset by peer');
            }
            if (uri.host == 'api.github.com') {
              return 'alpha\nbeta\n';
            }
            throw StateError('Unexpected URI: $uri');
          },
        ),
      );

      await controller.load();
      final downloaded = await controller.downloadBook('cet46-remote');

      expect(downloaded, isTrue);
      final remoteBook = controller.state.officialBooks.firstWhere(
        (book) => book.id == 'cet46-remote',
      );
      expect(remoteBook.entries.map((entry) => entry.word).toList(), <String>[
        'alpha',
        'beta',
      ]);
      expect(requestedUris, <String>[
        'https://shawyerpeng.cn/CET_4+6_edited.txt',
        'https://raw.githubusercontent.com/mahavivo/english-wordlists/refs/heads/master/CET_4%2B6_edited.txt',
        'https://api.github.com/repos/mahavivo/english-wordlists/contents/CET_4+6_edited.txt?ref=master',
      ]);
    },
  );

  test('remote download emits importing progress then success state', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async {
          onProgress?.call(25, 100);
          onProgress?.call(100, 100);
          return 'alpha\nbeta\n';
        },
      ),
    );
    final seenStates = <VocabularyImportStatus>[];

    controller.addListener(() {
      seenStates.add(controller.state.importStatus);
    });

    await controller.load();
    await controller.downloadBook('cet46-remote');

    expect(seenStates, contains(VocabularyImportStatus.importing));
    expect(controller.state.importStatus, VocabularyImportStatus.success);
    expect(controller.state.importMessage, '词汇表导入成功');
    expect(controller.state.downloadStates['cet46-remote']?.progress, 1);
  });

  test(
    'remote download emits failure and preserves previous current book',
    () async {
      final controller = StudyPlanController(
        repository: InMemoryStudyPlanRepository.seeded(
          remoteVocabularyLoader: (uri, {onProgress}) async {
            throw Exception('network down');
          },
        ),
      );

      await controller.load();
      await controller.selectBook('ielts-complete');
      await controller.downloadBook('cet46-remote');

      expect(controller.state.currentBook?.id, 'ielts-complete');
      expect(controller.state.importStatus, VocabularyImportStatus.failure);
      expect(controller.state.importMessage, contains('network down'));
      expect(
        controller.state.downloadStates['cet46-remote']?.status,
        VocabularyDownloadStatus.failure,
      );
    },
  );

  test('remote download times out and exits importing state', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) =>
            Completer<String>().future,
        remoteVocabularyTimeout: const Duration(milliseconds: 20),
      ),
    );

    await controller.load();
    await controller.selectBook('ielts-complete');
    final selected = await controller.downloadBook('cet46-remote');

    expect(selected, isFalse);
    expect(controller.state.currentBook?.id, 'ielts-complete');
    expect(controller.state.importStatus, VocabularyImportStatus.failure);
    expect(controller.state.importMessage, contains('超时'));
  });

  test('remote book cannot be selected before it is downloaded', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(
        remoteVocabularyLoader: (uri, {onProgress}) async => 'alpha\nbeta\n',
      ),
    );

    await controller.load();
    final selected = await controller.selectBook('cet46-remote');

    expect(selected, isFalse);
    expect(controller.state.currentBook, isNull);
    expect(controller.state.importStatus, VocabularyImportStatus.idle);
  });

  test('can create notebook, import words and switch notebook', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(),
    );

    await controller.load();
    expect(controller.state.notebooks, hasLength(1));
    expect(controller.state.selectedNotebook?.name, '我的词汇');

    final created = await controller.createNotebook(
      name: '雅思生词',
      description: '测试本',
    );
    expect(created, isTrue);
    expect(
      controller.state.notebooks.map((item) => item.name),
      contains('雅思生词'),
    );

    final targetNotebook = controller.state.notebooks.firstWhere(
      (item) => item.name == '雅思生词',
    );
    final imported = await controller.importWordsToNotebook(
      notebookId: targetNotebook.id,
      words: const <String>['abandon', 'ability', 'abandon'],
    );

    expect(imported, isTrue);
    expect(controller.state.selectedNotebook?.id, targetNotebook.id);
    expect(controller.state.selectedNotebook?.words, const <String>[
      'abandon',
      'ability',
    ]);

    final switched = await controller.selectNotebook('my-vocabulary');
    expect(switched, isTrue);
    expect(controller.state.selectedNotebook?.id, 'my-vocabulary');
  });

  test('can update and delete notebook', () async {
    final controller = StudyPlanController(
      repository: InMemoryStudyPlanRepository.seeded(),
    );

    await controller.load();
    final created = await controller.createNotebook(
      name: '临时词本',
      description: '待编辑',
    );
    expect(created, isTrue);

    final createdNotebook = controller.state.notebooks.firstWhere(
      (item) => item.name == '临时词本',
    );
    final updated = await controller.updateNotebook(
      notebookId: createdNotebook.id,
      name: '雅思词本',
      description: '已编辑',
    );
    expect(updated, isTrue);
    expect(
      controller.state.notebooks.any(
        (item) => item.name == '雅思词本' && item.description == '已编辑',
      ),
      isTrue,
    );

    final deleted = await controller.deleteNotebook(createdNotebook.id);
    expect(deleted, isTrue);
    expect(
      controller.state.notebooks.any((item) => item.id == createdNotebook.id),
      isFalse,
    );
  });
}
