import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

enum WordDetailStatus { idle, loading, ready, failure }

class WordDetailState {
  static const Object _sentinel = Object();

  const WordDetailState({
    required this.status,
    this.word = '',
    this.detail,
    this.knowledge,
    this.errorMessage,
    this.isMutating = false,
  });

  const WordDetailState.idle() : this(status: WordDetailStatus.idle);

  final WordDetailStatus status;
  final String word;
  final WordDetail? detail;
  final WordKnowledgeRecord? knowledge;
  final String? errorMessage;
  final bool isMutating;

  WordDetailState copyWith({
    WordDetailStatus? status,
    String? word,
    Object? detail = _sentinel,
    Object? knowledge = _sentinel,
    Object? errorMessage = _sentinel,
    bool? isMutating,
  }) {
    return WordDetailState(
      status: status ?? this.status,
      word: word ?? this.word,
      detail: identical(detail, _sentinel) ? this.detail : detail as WordDetail?,
      knowledge: identical(knowledge, _sentinel)
          ? this.knowledge
          : knowledge as WordKnowledgeRecord?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class WordDetailController extends ChangeNotifier {
  WordDetailController({
    required WordDetailRepository detailRepository,
    required WordKnowledgeRepository knowledgeRepository,
  }) : _detailRepository = detailRepository,
       _knowledgeRepository = knowledgeRepository;

  final WordDetailRepository _detailRepository;
  final WordKnowledgeRepository _knowledgeRepository;

  WordDetailState _state = const WordDetailState.idle();

  WordDetailState get state => _state;

  Future<void> load(String word) async {
    final normalizedWord = WordKnowledgeRecord.normalizeWord(word);
    _state = _state.copyWith(
      status: WordDetailStatus.loading,
      word: normalizedWord,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final detail = await _detailRepository.load(normalizedWord);
      final knowledge =
          await _knowledgeRepository.getByWord(normalizedWord) ??
          WordKnowledgeRecord.initial(normalizedWord);
      _state = _state.copyWith(
        status: WordDetailStatus.ready,
        word: normalizedWord,
        detail: detail,
        knowledge: knowledge,
        errorMessage: null,
      );
    } catch (error) {
      _state = _state.copyWith(
        status: WordDetailStatus.failure,
        word: normalizedWord,
        errorMessage: '$error',
      );
    }
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final word = _state.word;
    if (word.isEmpty) {
      return;
    }
    await _mutate(() => _knowledgeRepository.toggleFavorite(word));
  }

  Future<void> markKnown({required bool skipConfirmNextTime}) async {
    final word = _state.word;
    if (word.isEmpty) {
      return;
    }
    await _mutate(
      () => _knowledgeRepository.markKnown(
        word,
        skipConfirmNextTime: skipConfirmNextTime,
      ),
    );
  }

  Future<void> saveNote(String note) async {
    final word = _state.word;
    if (word.isEmpty) {
      return;
    }
    await _mutate(() => _knowledgeRepository.saveNote(word, note));
  }

  Future<void> _mutate(Future<void> Function() action) async {
    _state = _state.copyWith(isMutating: true, errorMessage: null);
    notifyListeners();

    try {
      await action();
      final knowledge =
          await _knowledgeRepository.getByWord(_state.word) ??
          WordKnowledgeRecord.initial(_state.word);
      _state = _state.copyWith(
        status: WordDetailStatus.ready,
        knowledge: knowledge,
        isMutating: false,
      );
    } catch (error) {
      _state = _state.copyWith(
        isMutating: false,
        errorMessage: '$error',
      );
    }
    notifyListeners();
  }
}
