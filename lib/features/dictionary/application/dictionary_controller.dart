import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

enum DictionaryStatus { idle, importing, ready, failure }

class DictionaryState {
  static const Object _sentinel = Object();

  const DictionaryState({
    required this.status,
    required this.entries,
    this.dictionary,
    this.activePackage,
    this.currentIndex = 0,
    this.errorMessage,
  });

  const DictionaryState.idle()
      : status = DictionaryStatus.idle,
        entries = const [],
        dictionary = null,
        activePackage = null,
        currentIndex = 0,
        errorMessage = null;

  final DictionaryStatus status;
  final List<WordEntry> entries;
  final DictionarySummary? dictionary;
  final DictionaryPackage? activePackage;
  final int currentIndex;
  final String? errorMessage;

  WordEntry? get currentEntry {
    if (currentIndex < 0 || currentIndex >= entries.length) {
      return null;
    }

    return entries[currentIndex];
  }

  DictionaryState copyWith({
    DictionaryStatus? status,
    List<WordEntry>? entries,
    Object? dictionary = _sentinel,
    Object? activePackage = _sentinel,
    int? currentIndex,
    Object? errorMessage = _sentinel,
  }) {
    return DictionaryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      dictionary: identical(dictionary, _sentinel)
          ? this.dictionary
          : dictionary as DictionarySummary?,
      activePackage: identical(activePackage, _sentinel)
          ? this.activePackage
          : activePackage as DictionaryPackage?,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class DictionaryController extends ChangeNotifier {
  DictionaryController({
    required DictionaryRepository dictionaryRepository,
    required StudyRepository studyRepository,
  }) : _dictionaryRepository = dictionaryRepository,
       _studyRepository = studyRepository;

  final DictionaryRepository _dictionaryRepository;
  final StudyRepository _studyRepository;

  DictionaryState _state = const DictionaryState.idle();

  DictionaryState get state => _state;

  Future<void> importDictionary(String filePath) async {
    _state = _state.copyWith(
      status: DictionaryStatus.importing,
      entries: const [],
      dictionary: null,
      activePackage: null,
      currentIndex: 0,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final result = await _dictionaryRepository.importDictionary(filePath);
      _state = DictionaryState(
        status: DictionaryStatus.ready,
        entries: result.entries,
        dictionary: result.dictionary,
        activePackage: result.package,
        currentIndex: 0,
      );
    } catch (error) {
      _state = DictionaryState(
        status: DictionaryStatus.failure,
        entries: const [],
        activePackage: null,
        errorMessage: _formatError(error),
      );
    }

    notifyListeners();
  }

  Future<void> recordDecision(StudyDecisionType decision) async {
    final entry = _state.currentEntry;
    if (entry == null) {
      return;
    }

    await _studyRepository.saveDecision(entryId: entry.id, decision: decision);
    final nextIndex = _state.currentIndex + 1;
    _state = _state.copyWith(currentIndex: nextIndex);
    notifyListeners();
  }

  String _formatError(Object error) {
    if (error is UnsupportedError && error.message != null) {
      return error.message!;
    }

    return '$error';
  }
}
