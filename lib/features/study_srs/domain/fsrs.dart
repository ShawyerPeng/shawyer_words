import 'package:fsrs/fsrs.dart' as dart_fsrs;
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';

class Fsrs {
  Fsrs({dart_fsrs.FSRS? engine}) : _engine = engine ?? dart_fsrs.FSRS();

  final dart_fsrs.FSRS _engine;

  FsrsRecordLogItem next(FsrsCard card, DateTime now, FsrsRating rating) {
    if (rating == FsrsRating.manual) {
      throw ArgumentError.value(rating, 'rating', 'Manual rating is not supported');
    }
    final resolvedNow = now.toUtc();
    final sourceCard = _toDartCard(card, resolvedNow);
    final recordLog = _engine.repeat(sourceCard, resolvedNow);
    final key = _toDartRating(rating);
    final info = recordLog[key];
    if (info == null) {
      throw StateError('Missing scheduling info for rating: $rating');
    }
    final nextCard = _fromDartCard(card.word, info.card);
    final nextLog = FsrsReviewLog(
      word: card.word,
      rating: rating,
      state: _fromDartState(info.reviewLog.state),
      due: card.due,
      stability: nextCard.stability,
      difficulty: nextCard.difficulty,
      elapsedDays: info.reviewLog.elapsedDays,
      lastElapsedDays: card.elapsedDays,
      scheduledDays: info.reviewLog.scheduledDays,
      learningSteps: card.learningSteps,
      reviewedAt: info.reviewLog.review.toUtc(),
    );
    return FsrsRecordLogItem(card: nextCard, log: nextLog);
  }
}

dart_fsrs.Card _toDartCard(FsrsCard card, DateTime now) {
  return dart_fsrs.Card.def(
    card.due.toUtc(),
    (card.lastReview ?? now).toUtc(),
    card.stability,
    card.difficulty,
    card.elapsedDays,
    card.scheduledDays,
    card.reps,
    card.lapses,
    _toDartState(card.state),
  );
}

FsrsCard _fromDartCard(String word, dart_fsrs.Card card) {
  return FsrsCard(
    word: word,
    due: card.due.toUtc(),
    stability: card.stability,
    difficulty: card.difficulty,
    elapsedDays: card.elapsedDays,
    scheduledDays: card.scheduledDays,
    reps: card.reps,
    lapses: card.lapses,
    learningSteps: 0,
    state: _fromDartState(card.state),
    lastReview: card.lastReview.toUtc(),
  );
}

dart_fsrs.Rating _toDartRating(FsrsRating rating) {
  return switch (rating) {
    FsrsRating.manual => throw ArgumentError('Manual rating is not supported'),
    FsrsRating.again => dart_fsrs.Rating.again,
    FsrsRating.hard => dart_fsrs.Rating.hard,
    FsrsRating.good => dart_fsrs.Rating.good,
    FsrsRating.easy => dart_fsrs.Rating.easy,
  };
}

dart_fsrs.State _toDartState(FsrsState state) {
  return switch (state) {
    FsrsState.newState => dart_fsrs.State.newState,
    FsrsState.learning => dart_fsrs.State.learning,
    FsrsState.review => dart_fsrs.State.review,
    FsrsState.relearning => dart_fsrs.State.relearning,
  };
}

FsrsState _fromDartState(dart_fsrs.State state) {
  return switch (state) {
    dart_fsrs.State.newState => FsrsState.newState,
    dart_fsrs.State.learning => FsrsState.learning,
    dart_fsrs.State.review => FsrsState.review,
    dart_fsrs.State.relearning => FsrsState.relearning,
  };
}

