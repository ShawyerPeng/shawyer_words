import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';

@immutable
class PlannedStudyItem {
  const PlannedStudyItem({
    required this.entry,
    required this.source,
    required this.priorityScore,
    required this.reasonTags,
  });

  final WordEntry entry;
  final StudyTaskSource source;
  final double priorityScore;
  final List<StudyTaskReason> reasonTags;
}

@immutable
class DailyStudyPlanSummary {
  const DailyStudyPlanSummary({
    required this.reviewCount,
    required this.newCount,
    required this.probeCount,
    required this.deferredCount,
    required this.backlogLevel,
    required this.strategyLabel,
    required this.reasonSummary,
  });

  const DailyStudyPlanSummary.empty()
    : reviewCount = 0,
      newCount = 0,
      probeCount = 0,
      deferredCount = 0,
      backlogLevel = StudyBacklogLevel.none,
      strategyLabel = 'balanced',
      reasonSummary = const <String>[];

  final int reviewCount;
  final int newCount;
  final int probeCount;
  final int deferredCount;
  final StudyBacklogLevel backlogLevel;
  final String strategyLabel;
  final List<String> reasonSummary;
}

@immutable
class DailyStudyPlan {
  const DailyStudyPlan({
    required this.mustReview,
    required this.normalReview,
    required this.newWords,
    required this.probeWords,
    required this.deferredWords,
    required this.mixedQueue,
    required this.summary,
  });

  const DailyStudyPlan.empty()
    : mustReview = const <PlannedStudyItem>[],
      normalReview = const <PlannedStudyItem>[],
      newWords = const <PlannedStudyItem>[],
      probeWords = const <PlannedStudyItem>[],
      deferredWords = const <PlannedStudyItem>[],
      mixedQueue = const <PlannedStudyItem>[],
      summary = const DailyStudyPlanSummary.empty();

  final List<PlannedStudyItem> mustReview;
  final List<PlannedStudyItem> normalReview;
  final List<PlannedStudyItem> newWords;
  final List<PlannedStudyItem> probeWords;
  final List<PlannedStudyItem> deferredWords;
  final List<PlannedStudyItem> mixedQueue;
  final DailyStudyPlanSummary summary;
}
