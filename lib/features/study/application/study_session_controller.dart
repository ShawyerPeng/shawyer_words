import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

class StudySessionState {
  const StudySessionState({
    required this.entries,
    this.currentIndex = 0,
    this.definitionRevealed = false,
    this.forgotCount = 0,
    this.fuzzyCount = 0,
    this.knownCount = 0,
    this.masteredCount = 0,
  });

  final List<WordEntry> entries;
  final int currentIndex;
  final bool definitionRevealed;
  final int forgotCount;
  final int fuzzyCount;
  final int knownCount;
  final int masteredCount;

  WordEntry? get currentEntry {
    if (currentIndex < 0 || currentIndex >= entries.length) {
      return null;
    }

    return entries[currentIndex];
  }

  bool get isComplete => currentIndex >= entries.length;

  StudySessionState copyWith({
    List<WordEntry>? entries,
    int? currentIndex,
    bool? definitionRevealed,
    int? forgotCount,
    int? fuzzyCount,
    int? knownCount,
    int? masteredCount,
  }) {
    return StudySessionState(
      entries: entries ?? this.entries,
      currentIndex: currentIndex ?? this.currentIndex,
      definitionRevealed: definitionRevealed ?? this.definitionRevealed,
      forgotCount: forgotCount ?? this.forgotCount,
      fuzzyCount: fuzzyCount ?? this.fuzzyCount,
      knownCount: knownCount ?? this.knownCount,
      masteredCount: masteredCount ?? this.masteredCount,
    );
  }
}

class StudySessionController extends ChangeNotifier {
  StudySessionController({
    required List<WordEntry> entries,
    required StudyRepository studyRepository,
    required FsrsRepository fsrsRepository,
    required WordKnowledgeRepository wordKnowledgeRepository,
    StudySessionState? initialState,
    Map<String, StudyTaskSource> entrySourcesByWord =
        const <String, StudyTaskSource>{},
  }) : _studyRepository = studyRepository,
       _fsrsRepository = fsrsRepository,
       _wordKnowledgeRepository = wordKnowledgeRepository,
       _entrySourcesByWord = entrySourcesByWord,
       _state = initialState ?? StudySessionState(entries: entries);

  final StudyRepository _studyRepository;
  final FsrsRepository _fsrsRepository;
  final WordKnowledgeRepository _wordKnowledgeRepository;
  final Map<String, StudyTaskSource> _entrySourcesByWord;
  final Fsrs _fsrs = Fsrs();
  StudySessionState _state;

  StudySessionState get state => _state;

  StudyTaskSource? get currentTaskSource {
    final entry = _state.currentEntry;
    if (entry == null) {
      return null;
    }
    return _entrySourcesByWord[WordKnowledgeRecord.normalizeWord(entry.word)];
  }

  void revealDefinition() {
    if (_state.definitionRevealed || _state.currentEntry == null) {
      return;
    }

    _state = _state.copyWith(definitionRevealed: true);
    notifyListeners();
  }

  Future<void> markKnown() async {
    await markGood();
  }

  Future<void> markUnknown() async {
    await markAgain();
  }

  Future<void> markForgot() async {
    await markAgain();
  }

  Future<void> markFuzzy() async {
    await markHard();
  }

  Future<void> markMastered() async {
    await markEasy();
  }

  Future<void> markAgain() async {
    await _saveAndAdvance(
      rating: FsrsRating.again,
      decision: StudyDecisionType.forgot,
    );
  }

  Future<void> markHard() async {
    await _saveAndAdvance(
      rating: FsrsRating.hard,
      decision: StudyDecisionType.fuzzy,
    );
  }

  Future<void> markGood() async {
    await _saveAndAdvance(
      rating: FsrsRating.good,
      decision: StudyDecisionType.known,
    );
  }

  Future<void> markEasy() async {
    await _saveAndAdvance(
      rating: FsrsRating.easy,
      decision: StudyDecisionType.mastered,
    );
  }

  Future<void> _saveAndAdvance({
    required FsrsRating rating,
    required StudyDecisionType decision,
  }) async {
    final entry = _state.currentEntry;
    if (entry == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    final word = WordKnowledgeRecord.normalizeWord(entry.word);
    final currentCard =
        await _fsrsRepository.getByWord(word) ??
        FsrsCard.createEmpty(word, now);
    final item = _fsrs.next(currentCard, now, rating);
    await _fsrsRepository.saveReview(item);

    final currentKnowledge =
        await _wordKnowledgeRepository.getByWord(word) ??
        WordKnowledgeRecord.initial(word);
    final source = _entrySourcesByWord[word];
    final effectiveDecision = _effectiveDecision(
      source: source,
      rating: rating,
      fallback: decision,
    );
    bool isKnown = currentKnowledge.isKnown;
    bool skipKnownConfirm = currentKnowledge.skipKnownConfirm;
    if (source == StudyTaskSource.probeWord) {
      final passedProbe =
          rating == FsrsRating.good || rating == FsrsRating.easy;
      isKnown = passedProbe;
      skipKnownConfirm = passedProbe;
    } else if (rating == FsrsRating.easy) {
      isKnown = true;
      skipKnownConfirm = true;
    }

    await _wordKnowledgeRepository.save(
      WordKnowledgeRecord(
        word: currentKnowledge.word,
        isFavorite: currentKnowledge.isFavorite,
        isKnown: isKnown,
        note: currentKnowledge.note,
        skipKnownConfirm: skipKnownConfirm,
        updatedAt: now,
      ),
    );

    await _studyRepository.saveDecision(
      entryId: entry.id,
      decision: effectiveDecision,
    );
    _state = _state.copyWith(
      currentIndex: _state.currentIndex + 1,
      definitionRevealed: false,
      forgotCount: effectiveDecision == StudyDecisionType.forgot
          ? _state.forgotCount + 1
          : _state.forgotCount,
      fuzzyCount: effectiveDecision == StudyDecisionType.fuzzy
          ? _state.fuzzyCount + 1
          : _state.fuzzyCount,
      knownCount: effectiveDecision == StudyDecisionType.known
          ? _state.knownCount + 1
          : _state.knownCount,
      masteredCount: effectiveDecision == StudyDecisionType.mastered
          ? _state.masteredCount + 1
          : _state.masteredCount,
    );
    notifyListeners();
  }

  StudyDecisionType _effectiveDecision({
    required StudyTaskSource? source,
    required FsrsRating rating,
    required StudyDecisionType fallback,
  }) {
    if (source != StudyTaskSource.probeWord) {
      return fallback;
    }
    return switch (rating) {
      FsrsRating.easy => StudyDecisionType.mastered,
      FsrsRating.good => StudyDecisionType.known,
      FsrsRating.hard => StudyDecisionType.fuzzy,
      FsrsRating.manual || FsrsRating.again => StudyDecisionType.forgot,
    };
  }
}
