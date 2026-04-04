import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/study_plan/domain/daily_study_plan.dart';
import 'package:shawyer_words/features/study_plan/domain/daily_study_plan_request.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

class DailyTaskPlanner {
  const DailyTaskPlanner();

  static const Duration _probeCooldown = Duration(days: 7);

  DailyStudyPlan plan(DailyStudyPlanRequest request) {
    if (request.bookEntries.isEmpty) {
      return const DailyStudyPlan.empty();
    }

    final reviewCandidates = <PlannedStudyItem>[];
    final newCandidates = <PlannedStudyItem>[];
    final probeCandidates = <PlannedStudyItem>[];

    for (final entry in request.bookEntries) {
      final word = WordKnowledgeRecord.normalizeWord(entry.word);
      final card = request.cardsByWord[word];
      final knowledge = request.knowledgeByWord[word];
      if (card != null && !card.due.isAfter(request.now)) {
        reviewCandidates.add(_buildReviewItem(entry, card, request.now));
        continue;
      }
      if (knowledge != null &&
          (knowledge.isKnown || knowledge.skipKnownConfirm)) {
        if (_isProbeEligible(knowledge: knowledge, now: request.now)) {
          probeCandidates.add(_buildProbeItem(entry, knowledge, request.now));
        }
        continue;
      }
      if (card == null) {
        newCandidates.add(
          PlannedStudyItem(
            entry: entry,
            source: StudyTaskSource.newWord,
            priorityScore: 0,
            reasonTags: const <StudyTaskReason>[StudyTaskReason.freshWord],
          ),
        );
      }
    }

    reviewCandidates.sort(
      (left, right) => right.priorityScore.compareTo(left.priorityScore),
    );

    final backlogLevel = _backlogLevel(
      reviewCount: reviewCandidates.length,
      request: request,
    );
    final planningMode = request.settings.studyPlanningMode;
    final newBudget = _newBudget(
      planningMode: planningMode,
      backlogLevel: backlogLevel,
      reviewCount: reviewCandidates.length,
      request: request,
    );
    final probeBudget = _probeBudget(
      planningMode: planningMode,
      backlogLevel: backlogLevel,
      request: request,
    );
    final reviewBudget = _reviewBudget(request);

    final selectedReviews = reviewCandidates
        .take(reviewBudget)
        .toList(growable: false);
    final selectedProbeWords = probeCandidates
        .take(probeBudget)
        .toList(growable: false);
    final selectedNewWords = newCandidates
        .take(newBudget)
        .toList(growable: false);

    final mustReview = selectedReviews
        .where((item) => item.source == StudyTaskSource.mustReview)
        .toList(growable: false);
    final normalReview = selectedReviews
        .where((item) => item.source == StudyTaskSource.normalReview)
        .toList(growable: false);

    final deferredWords = <PlannedStudyItem>[
      ...reviewCandidates.skip(reviewBudget),
      ...probeCandidates
          .skip(probeBudget)
          .map(
            (item) => PlannedStudyItem(
              entry: item.entry,
              source: item.source,
              priorityScore: item.priorityScore,
              reasonTags: <StudyTaskReason>[
                ...item.reasonTags,
                StudyTaskReason.backlogProtected,
              ],
            ),
          ),
      ...newCandidates
          .skip(newBudget)
          .map(
            (item) => PlannedStudyItem(
              entry: item.entry,
              source: item.source,
              priorityScore: item.priorityScore,
              reasonTags: <StudyTaskReason>[
                ...item.reasonTags,
                StudyTaskReason.backlogProtected,
              ],
            ),
          ),
    ];

    final mixedQueue = _buildMixedQueue(
      planningMode: planningMode,
      mustReview: mustReview,
      normalReview: normalReview,
      probeWords: selectedProbeWords,
      newWords: selectedNewWords,
    );

    return DailyStudyPlan(
      mustReview: mustReview,
      normalReview: normalReview,
      newWords: selectedNewWords,
      probeWords: selectedProbeWords,
      deferredWords: List<PlannedStudyItem>.unmodifiable(deferredWords),
      mixedQueue: List<PlannedStudyItem>.unmodifiable(mixedQueue),
      summary: DailyStudyPlanSummary(
        reviewCount: selectedReviews.length,
        newCount: selectedNewWords.length,
        probeCount: selectedProbeWords.length,
        deferredCount: deferredWords.length,
        backlogLevel: backlogLevel,
        strategyLabel: planningMode.name,
        reasonSummary: _reasonSummary(
          planningMode: planningMode,
          backlogLevel: backlogLevel,
          selectedReviews: selectedReviews.length,
          selectedProbeWords: selectedProbeWords.length,
          selectedNewWords: selectedNewWords.length,
          deferredCount: deferredWords.length,
        ),
      ),
    );
  }

  PlannedStudyItem _buildReviewItem(
    WordEntry entry,
    FsrsCard card,
    DateTime now,
  ) {
    final overdueDays = now.difference(card.due).inHours / 24;
    final retrievabilityScore = card.stability <= 0 ? 10 : 10 / card.stability;
    final priorityScore =
        overdueDays * 10 +
        (10 - card.stability).clamp(0, 10) +
        card.lapses * 3 +
        retrievabilityScore;

    final isMustReview =
        overdueDays >= 2 || card.stability <= 4 || card.lapses >= 2;
    final reasonTags = <StudyTaskReason>[
      StudyTaskReason.overdue,
      if (card.stability <= 4) StudyTaskReason.lowStability,
      if (card.lapses >= 2) StudyTaskReason.highLapseRisk,
    ];

    return PlannedStudyItem(
      entry: entry,
      source: isMustReview
          ? StudyTaskSource.mustReview
          : StudyTaskSource.normalReview,
      priorityScore: priorityScore,
      reasonTags: reasonTags,
    );
  }

  PlannedStudyItem _buildProbeItem(
    WordEntry entry,
    WordKnowledgeRecord knowledge,
    DateTime now,
  ) {
    final daysSinceKnown = now.difference(knowledge.updatedAt).inHours / 24;
    return PlannedStudyItem(
      entry: entry,
      source: StudyTaskSource.probeWord,
      priorityScore: daysSinceKnown,
      reasonTags: const <StudyTaskReason>[StudyTaskReason.probeRecheck],
    );
  }

  int _reviewBudget(DailyStudyPlanRequest request) {
    final dailyNew = request.settings.dailyStudyTarget.clamp(0, 500);
    final multiplier = request.settings.dailyReviewLimitMultiplier;
    if (multiplier <= 0) {
      return 1000000;
    }
    return dailyNew * multiplier;
  }

  int _probeBudget({
    required StudyPlanningMode planningMode,
    required StudyBacklogLevel backlogLevel,
    required DailyStudyPlanRequest request,
  }) {
    final dailyNew = request.settings.dailyStudyTarget.clamp(0, 500);
    final defaultBudget = switch (backlogLevel) {
      StudyBacklogLevel.heavy => 0,
      StudyBacklogLevel.medium => 1,
      _ => (dailyNew ~/ 10 + 1).clamp(1, 3),
    };
    return switch (planningMode) {
      StudyPlanningMode.sprint => defaultBudget.clamp(0, 1),
      _ => defaultBudget,
    };
  }

  int _newBudget({
    required StudyPlanningMode planningMode,
    required StudyBacklogLevel backlogLevel,
    required int reviewCount,
    required DailyStudyPlanRequest request,
  }) {
    final dailyNew = request.settings.dailyStudyTarget.clamp(0, 500);
    if (dailyNew == 0) {
      return 0;
    }
    final sprintTarget = (dailyNew + (dailyNew ~/ 4).clamp(1, 3)).clamp(0, 500);
    return switch (planningMode) {
      StudyPlanningMode.reviewFirst => switch (backlogLevel) {
        StudyBacklogLevel.none => dailyNew,
        StudyBacklogLevel.light => (dailyNew * 0.5).round().clamp(1, dailyNew),
        StudyBacklogLevel.medium => (dailyNew * 0.25).round().clamp(
          1,
          dailyNew,
        ),
        StudyBacklogLevel.heavy => 0,
      },
      StudyPlanningMode.sprint => switch (backlogLevel) {
        StudyBacklogLevel.none => sprintTarget,
        StudyBacklogLevel.light => dailyNew,
        StudyBacklogLevel.medium => (dailyNew * 0.75).round().clamp(
          1,
          sprintTarget,
        ),
        StudyBacklogLevel.heavy => reviewCount > dailyNew * 3 ? 2 : 4,
      },
      StudyPlanningMode.balanced => switch (backlogLevel) {
        StudyBacklogLevel.none => dailyNew,
        StudyBacklogLevel.light => (dailyNew * 0.75).round().clamp(1, dailyNew),
        StudyBacklogLevel.medium => (dailyNew * 0.5).round().clamp(1, dailyNew),
        StudyBacklogLevel.heavy => reviewCount > dailyNew * 2 ? 0 : 3,
      },
    };
  }

  StudyBacklogLevel _backlogLevel({
    required int reviewCount,
    required DailyStudyPlanRequest request,
  }) {
    final reviewBudget = _reviewBudget(request);
    if (reviewCount == 0) {
      return StudyBacklogLevel.none;
    }
    if (reviewCount <= reviewBudget) {
      return StudyBacklogLevel.none;
    }
    final ratio = reviewCount / reviewBudget;
    if (ratio <= 1.25) {
      return StudyBacklogLevel.light;
    }
    if (ratio <= 1.75) {
      return StudyBacklogLevel.medium;
    }
    return StudyBacklogLevel.heavy;
  }

  List<PlannedStudyItem> _buildMixedQueue({
    required StudyPlanningMode planningMode,
    required List<PlannedStudyItem> mustReview,
    required List<PlannedStudyItem> normalReview,
    required List<PlannedStudyItem> probeWords,
    required List<PlannedStudyItem> newWords,
  }) {
    final reviews = <PlannedStudyItem>[
      ...mustReview,
      ...normalReview,
      ...probeWords,
    ];
    final mixed = <PlannedStudyItem>[];
    var reviewIndex = 0;
    var newIndex = 0;
    final reviewBurst = switch (planningMode) {
      StudyPlanningMode.reviewFirst => 4,
      StudyPlanningMode.sprint => 2,
      StudyPlanningMode.balanced => 3,
    };

    while (reviewIndex < reviews.length || newIndex < newWords.length) {
      for (
        var count = 0;
        count < reviewBurst && reviewIndex < reviews.length;
        count += 1
      ) {
        mixed.add(reviews[reviewIndex]);
        reviewIndex += 1;
      }
      if (newIndex < newWords.length) {
        mixed.add(newWords[newIndex]);
        newIndex += 1;
      }
      if (reviewIndex >= reviews.length) {
        while (newIndex < newWords.length) {
          mixed.add(newWords[newIndex]);
          newIndex += 1;
        }
      }
    }
    return mixed;
  }

  List<String> _reasonSummary({
    required StudyPlanningMode planningMode,
    required StudyBacklogLevel backlogLevel,
    required int selectedReviews,
    required int selectedProbeWords,
    required int selectedNewWords,
    required int deferredCount,
  }) {
    return <String>[
      switch (planningMode) {
        StudyPlanningMode.reviewFirst => '当前按复习优先编排，先清理到期任务',
        StudyPlanningMode.sprint => '当前按冲刺突击编排，保留更多新词推进',
        StudyPlanningMode.balanced => '当前按均衡推进编排，复习与新词交替进行',
      },
      switch (backlogLevel) {
        StudyBacklogLevel.none => '当前复习压力稳定，新词按计划推进',
        StudyBacklogLevel.light => '复习稍有积压，新词会轻微收缩',
        StudyBacklogLevel.medium => '复习积压中等，今天先压缩新词',
        StudyBacklogLevel.heavy => '复习积压较重，今天优先清理 backlog',
      },
      if (selectedProbeWords > 0) '安排 $selectedProbeWords 个熟词抽查，确认已掌握单词仍然稳固',
      if (deferredCount > 0) '顺延 $deferredCount 个任务，避免今天超量',
      '今天实际安排 $selectedReviews 个复习、$selectedNewWords 个新词',
    ];
  }

  bool _isProbeEligible({
    required WordKnowledgeRecord knowledge,
    required DateTime now,
  }) {
    if (!knowledge.skipKnownConfirm) {
      return false;
    }
    return !knowledge.updatedAt.add(_probeCooldown).isAfter(now);
  }
}
