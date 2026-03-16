import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

class StudySessionState {
  const StudySessionState({
    required this.entries,
    this.currentIndex = 0,
    this.definitionRevealed = false,
    this.knownCount = 0,
    this.unknownCount = 0,
  });

  final List<WordEntry> entries;
  final int currentIndex;
  final bool definitionRevealed;
  final int knownCount;
  final int unknownCount;

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
    int? knownCount,
    int? unknownCount,
  }) {
    return StudySessionState(
      entries: entries ?? this.entries,
      currentIndex: currentIndex ?? this.currentIndex,
      definitionRevealed: definitionRevealed ?? this.definitionRevealed,
      knownCount: knownCount ?? this.knownCount,
      unknownCount: unknownCount ?? this.unknownCount,
    );
  }
}

class StudySessionController extends ChangeNotifier {
  StudySessionController({
    required List<WordEntry> entries,
    required StudyRepository studyRepository,
  }) : _studyRepository = studyRepository,
       _state = StudySessionState(entries: entries);

  final StudyRepository _studyRepository;
  StudySessionState _state;

  StudySessionState get state => _state;

  void revealDefinition() {
    if (_state.definitionRevealed || _state.currentEntry == null) {
      return;
    }

    _state = _state.copyWith(definitionRevealed: true);
    notifyListeners();
  }

  Future<void> markKnown() async {
    await _saveAndAdvance(StudyDecisionType.known);
  }

  Future<void> markUnknown() async {
    await _saveAndAdvance(StudyDecisionType.unknown);
  }

  Future<void> _saveAndAdvance(StudyDecisionType decision) async {
    final entry = _state.currentEntry;
    if (entry == null) {
      return;
    }

    await _studyRepository.saveDecision(entryId: entry.id, decision: decision);
    _state = _state.copyWith(
      currentIndex: _state.currentIndex + 1,
      definitionRevealed: false,
      knownCount: decision == StudyDecisionType.known
          ? _state.knownCount + 1
          : _state.knownCount,
      unknownCount: decision == StudyDecisionType.unknown
          ? _state.unknownCount + 1
          : _state.unknownCount,
    );
    notifyListeners();
  }
}
