import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/study_plan/application/daily_task_planner.dart';
import 'package:shawyer_words/features/study_plan/domain/daily_study_plan_request.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

void main() {
  final planner = DailyTaskPlanner();
  final now = DateTime.utc(2026, 4, 5, 12);

  test('returns an empty plan when the selected book has no entries', () {
    final plan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: const <WordEntry>[]),
        bookEntries: const <WordEntry>[],
        cardsByWord: const <String, FsrsCard>{},
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults(),
        now: now,
      ),
    );

    expect(plan.mustReview, isEmpty);
    expect(plan.newWords, isEmpty);
    expect(plan.mixedQueue, isEmpty);
    expect(plan.summary.reviewCount, 0);
    expect(plan.summary.newCount, 0);
  });

  test('places due cards into review buckets before new words', () {
    final dueEntry = _entry('due-word');
    final newEntry = _entry('new-word');
    final plan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: <WordEntry>[dueEntry, newEntry]),
        bookEntries: <WordEntry>[dueEntry, newEntry],
        cardsByWord: <String, FsrsCard>{
          'due-word': _reviewCard(
            word: 'due-word',
            due: now.subtract(const Duration(days: 2)),
            stability: 4,
            lapses: 2,
          ),
        },
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults(),
        now: now,
      ),
    );

    expect(
      plan.mustReview.map((item) => item.entry.word),
      contains('due-word'),
    );
    expect(plan.newWords.map((item) => item.entry.word), contains('new-word'));
    expect(plan.mixedQueue.first.source, StudyTaskSource.mustReview);
  });

  test('reduces new-word budget when review backlog is heavy', () {
    final entries = <WordEntry>[
      _entry('review-1'),
      _entry('review-2'),
      _entry('review-3'),
      _entry('review-4'),
      _entry('review-5'),
      _entry('review-6'),
      _entry('review-7'),
      _entry('review-8'),
      _entry('new-1'),
      _entry('new-2'),
      _entry('new-3'),
      _entry('new-4'),
    ];
    final plan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: entries),
        bookEntries: entries,
        cardsByWord: <String, FsrsCard>{
          for (final word in <String>[
            'review-1',
            'review-2',
            'review-3',
            'review-4',
            'review-5',
            'review-6',
            'review-7',
            'review-8',
          ])
            word: _reviewCard(
              word: word,
              due: now.subtract(const Duration(days: 3)),
              stability: 3,
              lapses: 3,
            ),
        },
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 4,
          dailyReviewLimitMultiplier: 1,
        ),
        now: now,
      ),
    );

    expect(plan.summary.backlogLevel, StudyBacklogLevel.heavy);
    expect(plan.newWords.length, lessThan(4));
    expect(plan.deferredWords, isNotEmpty);
  });

  test('builds a balanced mixed queue with higher-risk reviews first', () {
    final entries = <WordEntry>[
      _entry('must-review'),
      _entry('review-1'),
      _entry('review-2'),
      _entry('new-1'),
      _entry('new-2'),
    ];
    final plan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: entries),
        bookEntries: entries,
        cardsByWord: <String, FsrsCard>{
          'must-review': _reviewCard(
            word: 'must-review',
            due: now.subtract(const Duration(days: 5)),
            stability: 2,
            lapses: 4,
          ),
          'review-1': _reviewCard(
            word: 'review-1',
            due: now.subtract(const Duration(days: 1)),
            stability: 6,
            lapses: 0,
          ),
          'review-2': _reviewCard(
            word: 'review-2',
            due: now.subtract(const Duration(hours: 12)),
            stability: 7,
            lapses: 0,
          ),
        },
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 2,
          dailyReviewLimitMultiplier: 3,
        ),
        now: now,
      ),
    );

    expect(
      plan.mixedQueue.take(4).map((item) => item.source).toList(),
      <StudyTaskSource>[
        StudyTaskSource.mustReview,
        StudyTaskSource.normalReview,
        StudyTaskSource.normalReview,
        StudyTaskSource.newWord,
      ],
    );
    expect(
      plan.mustReview.first.priorityScore,
      greaterThan(plan.normalReview.last.priorityScore),
    );
  });

  test(
    'adds eligible known words as probe tasks with a small daily budget',
    () {
      final probeEntry = _entry('probe-word');
      final newEntry = _entry('new-word');
      final plan = planner.plan(
        DailyStudyPlanRequest(
          book: _book(entries: <WordEntry>[probeEntry, newEntry]),
          bookEntries: <WordEntry>[probeEntry, newEntry],
          cardsByWord: <String, FsrsCard>{
            'probe-word': _reviewCard(
              word: 'probe-word',
              due: now.add(const Duration(days: 14)),
              stability: 18,
              lapses: 0,
            ),
          },
          knowledgeByWord: <String, WordKnowledgeRecord>{
            'probe-word': WordKnowledgeRecord(
              word: 'probe-word',
              isFavorite: false,
              isKnown: true,
              note: '',
              skipKnownConfirm: true,
              updatedAt: now.subtract(const Duration(days: 9)),
            ),
          },
          settings: const AppSettings.defaults().copyWith(
            dailyStudyTarget: 6,
            dailyReviewLimitMultiplier: 2,
          ),
          now: now,
        ),
      );

      expect(
        plan.probeWords.map((item) => item.entry.word),
        contains('probe-word'),
      );
      expect(plan.summary.probeCount, 1);
      expect(plan.mixedQueue.first.source, StudyTaskSource.probeWord);
      expect(
        plan.newWords.map((item) => item.entry.word),
        contains('new-word'),
      );
    },
  );

  test('review-first mode reduces new words and paces queue 4-to-1', () {
    final entries = <WordEntry>[
      _entry('review-1'),
      _entry('review-2'),
      _entry('review-3'),
      _entry('review-4'),
      _entry('review-5'),
      _entry('new-1'),
      _entry('new-2'),
      _entry('new-3'),
      _entry('new-4'),
    ];
    final plan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: entries),
        bookEntries: entries,
        cardsByWord: <String, FsrsCard>{
          for (final word in <String>[
            'review-1',
            'review-2',
            'review-3',
            'review-4',
            'review-5',
          ])
            word: _reviewCard(
              word: word,
              due: now.subtract(const Duration(days: 2)),
              stability: 5,
              lapses: 1,
            ),
        },
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 4,
          dailyReviewLimitMultiplier: 1,
          studyPlanningMode: StudyPlanningMode.reviewFirst,
        ),
        now: now,
      ),
    );

    expect(plan.summary.strategyLabel, 'reviewFirst');
    expect(plan.newWords.length, 2);
    expect(
      plan.mixedQueue.take(5).map((item) => item.source).toList(),
      <StudyTaskSource>[
        StudyTaskSource.mustReview,
        StudyTaskSource.mustReview,
        StudyTaskSource.mustReview,
        StudyTaskSource.mustReview,
        StudyTaskSource.newWord,
      ],
    );
  });

  test('builds readable reason summary for strategy backlog and probes', () {
    final entries = <WordEntry>[
      _entry('review-1'),
      _entry('review-2'),
      _entry('review-3'),
      _entry('review-4'),
      _entry('review-5'),
      _entry('review-6'),
      _entry('probe-word'),
      _entry('new-1'),
      _entry('new-2'),
    ];
    final plan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: entries),
        bookEntries: entries,
        cardsByWord: <String, FsrsCard>{
          for (final word in <String>[
            'review-1',
            'review-2',
            'review-3',
            'review-4',
            'review-5',
            'review-6',
          ])
            word: _reviewCard(
              word: word,
              due: now.subtract(const Duration(days: 2)),
              stability: 5,
              lapses: 1,
            ),
          'probe-word': _reviewCard(
            word: 'probe-word',
            due: now.add(const Duration(days: 14)),
            stability: 18,
            lapses: 0,
          ),
        },
        knowledgeByWord: <String, WordKnowledgeRecord>{
          'probe-word': WordKnowledgeRecord(
            word: 'probe-word',
            isFavorite: false,
            isKnown: true,
            note: '',
            skipKnownConfirm: true,
            updatedAt: now.subtract(const Duration(days: 9)),
          ),
        },
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 4,
          dailyReviewLimitMultiplier: 1,
          studyPlanningMode: StudyPlanningMode.reviewFirst,
        ),
        now: now,
      ),
    );

    expect(plan.summary.reasonSummary, contains('当前按复习优先编排，先清理到期任务'));
    expect(plan.summary.reasonSummary, contains('复习积压中等，今天先压缩新词'));
    expect(plan.summary.reasonSummary, contains('安排 1 个熟词抽查，确认已掌握单词仍然稳固'));
    expect(plan.summary.reasonSummary, contains('顺延 3 个任务，避免今天超量'));
  });

  test('sprint mode keeps more new words and paces queue 2-to-1', () {
    final entries = <WordEntry>[
      _entry('review-1'),
      _entry('review-2'),
      _entry('review-3'),
      _entry('review-4'),
      _entry('review-5'),
      _entry('new-1'),
      _entry('new-2'),
      _entry('new-3'),
      _entry('new-4'),
      _entry('new-5'),
    ];
    final balancedPlan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: entries),
        bookEntries: entries,
        cardsByWord: <String, FsrsCard>{
          for (final word in <String>[
            'review-1',
            'review-2',
            'review-3',
            'review-4',
            'review-5',
          ])
            word: _reviewCard(
              word: word,
              due: now.subtract(const Duration(days: 2)),
              stability: 5,
              lapses: 1,
            ),
        },
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 4,
          dailyReviewLimitMultiplier: 1,
        ),
        now: now,
      ),
    );
    final sprintPlan = planner.plan(
      DailyStudyPlanRequest(
        book: _book(entries: entries),
        bookEntries: entries,
        cardsByWord: <String, FsrsCard>{
          for (final word in <String>[
            'review-1',
            'review-2',
            'review-3',
            'review-4',
            'review-5',
          ])
            word: _reviewCard(
              word: word,
              due: now.subtract(const Duration(days: 2)),
              stability: 5,
              lapses: 1,
            ),
        },
        knowledgeByWord: const <String, WordKnowledgeRecord>{},
        settings: const AppSettings.defaults().copyWith(
          dailyStudyTarget: 4,
          dailyReviewLimitMultiplier: 1,
          studyPlanningMode: StudyPlanningMode.sprint,
        ),
        now: now,
      ),
    );

    expect(sprintPlan.summary.strategyLabel, 'sprint');
    expect(
      sprintPlan.newWords.length,
      greaterThan(balancedPlan.newWords.length),
    );
    expect(
      sprintPlan.mixedQueue.take(3).map((item) => item.source).toList(),
      <StudyTaskSource>[
        StudyTaskSource.mustReview,
        StudyTaskSource.mustReview,
        StudyTaskSource.newWord,
      ],
    );
  });
}

OfficialVocabularyBook _book({required List<WordEntry> entries}) {
  return OfficialVocabularyBook(
    id: 'book',
    category: 'Exam',
    title: 'Book',
    subtitle: 'Subtitle',
    wordCount: entries.length,
    coverKey: 'book',
    entries: entries,
  );
}

WordEntry _entry(String word) {
  return WordEntry(id: word, word: word, rawContent: word);
}

FsrsCard _reviewCard({
  required String word,
  required DateTime due,
  required double stability,
  required int lapses,
}) {
  return FsrsCard(
    word: word,
    due: due,
    stability: stability,
    difficulty: 5,
    elapsedDays: 3,
    scheduledDays: 5,
    reps: 3,
    lapses: lapses,
    learningSteps: 0,
    state: FsrsState.review,
    lastReview: due.subtract(const Duration(days: 3)),
  );
}
