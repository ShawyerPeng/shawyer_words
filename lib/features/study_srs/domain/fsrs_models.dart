import 'package:flutter/foundation.dart';

enum FsrsState { newState, learning, review, relearning }

enum FsrsRating { manual, again, hard, good, easy }

@immutable
class FsrsCard {
  const FsrsCard({
    required this.word,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.elapsedDays,
    required this.scheduledDays,
    required this.reps,
    required this.lapses,
    required this.learningSteps,
    required this.state,
    required this.lastReview,
  });

  factory FsrsCard.createEmpty(String word, DateTime now) {
    return FsrsCard(
      word: word,
      due: now,
      stability: 0,
      difficulty: 0,
      elapsedDays: 0,
      scheduledDays: 0,
      reps: 0,
      lapses: 0,
      learningSteps: 0,
      state: FsrsState.newState,
      lastReview: null,
    );
  }

  final String word;
  final DateTime due;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final int learningSteps;
  final FsrsState state;
  final DateTime? lastReview;

  FsrsCard copyWith({
    String? word,
    DateTime? due,
    double? stability,
    double? difficulty,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    int? learningSteps,
    FsrsState? state,
    Object? lastReview = _sentinel,
  }) {
    return FsrsCard(
      word: word ?? this.word,
      due: due ?? this.due,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      learningSteps: learningSteps ?? this.learningSteps,
      state: state ?? this.state,
      lastReview: identical(lastReview, _sentinel)
          ? this.lastReview
          : lastReview as DateTime?,
    );
  }

  static const Object _sentinel = Object();
}

@immutable
class FsrsReviewLog {
  const FsrsReviewLog({
    required this.word,
    required this.rating,
    required this.state,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.elapsedDays,
    required this.lastElapsedDays,
    required this.scheduledDays,
    required this.learningSteps,
    required this.reviewedAt,
  });

  final String word;
  final FsrsRating rating;
  final FsrsState state;
  final DateTime due;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int lastElapsedDays;
  final int scheduledDays;
  final int learningSteps;
  final DateTime reviewedAt;
}

@immutable
class FsrsRecordLogItem {
  const FsrsRecordLogItem({required this.card, required this.log});

  final FsrsCard card;
  final FsrsReviewLog log;
}

