import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/data/file_system_search_history_repository.dart';

void main() {
  group('FileSystemSearchHistoryRepository', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'search-history-test-',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists history across repository instances', () async {
      final firstRepo = FileSystemSearchHistoryRepository(
        rootPathResolver: () async => tempDirectory.path,
      );
      await firstRepo.saveEntry(
        const WordEntry(
          id: 'career',
          word: 'career',
          definition: '事业',
          rawContent: '<p>career</p>',
        ),
      );

      final secondRepo = FileSystemSearchHistoryRepository(
        rootPathResolver: () async => tempDirectory.path,
      );
      final history = await secondRepo.loadHistory();

      expect(history, hasLength(1));
      expect(history.single.word, 'career');
      expect(history.single.definition, '事业');
    });

    test('keeps latest item first and applies limit', () async {
      final repo = FileSystemSearchHistoryRepository(
        rootPathResolver: () async => tempDirectory.path,
      );

      for (var index = 0; index < 12; index += 1) {
        await repo.saveEntry(
          WordEntry(
            id: 'id-$index',
            word: 'word-$index',
            rawContent: '<p>word-$index</p>',
          ),
        );
      }
      await repo.saveEntry(
        const WordEntry(
          id: 'id-3',
          word: 'word-3',
          rawContent: '<p>word-3</p>',
        ),
      );

      final history = await repo.loadHistory();
      expect(history, hasLength(10));
      expect(history.first.id, 'id-3');
      expect(history.where((entry) => entry.id == 'id-3'), hasLength(1));
      expect(history.last.id, 'id-2');
    });
  });
}
