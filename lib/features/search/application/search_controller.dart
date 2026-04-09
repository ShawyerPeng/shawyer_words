import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/domain/search_history_repository.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const <WordEntry>[],
    this.history = const <WordEntry>[],
  });

  final String query;
  final List<WordEntry> results;
  final List<WordEntry> history;

  SearchState copyWith({
    String? query,
    List<WordEntry>? results,
    List<WordEntry>? history,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      history: history ?? this.history,
    );
  }
}

class SearchController extends ChangeNotifier {
  SearchController({
    required WordLookupRepository lookupRepository,
    required SearchHistoryRepository historyRepository,
  }) : _lookupRepository = lookupRepository,
       _historyRepository = historyRepository,
       _state = const SearchState() {
    _historyRestoreFuture = _restoreHistory();
  }

  final WordLookupRepository _lookupRepository;
  final SearchHistoryRepository _historyRepository;

  SearchState _state;
  int _searchRequestId = 0;
  Future<void>? _historyRestoreFuture;

  SearchState get state => _state;

  Future<void> _restoreHistory() async {
    final history = await _historyRepository.loadHistory();
    _state = _state.copyWith(history: history);
    notifyListeners();
  }

  Future<void> _ensureHistoryLoaded() {
    return _historyRestoreFuture ??= _restoreHistory();
  }

  Future<void> prepareForOpen() async {
    await _ensureHistoryLoaded();
    if (_state.query.isEmpty && _state.results.isEmpty) {
      return;
    }
    _searchRequestId++;
    _state = _state.copyWith(
      query: '',
      results: const <WordEntry>[],
      history: _state.history,
    );
    notifyListeners();
  }

  Future<void> updateQuery(String query) async {
    await _ensureHistoryLoaded();
    final requestId = ++_searchRequestId;
    final normalized = query.trim();
    final previousQuery = _state.query;
    final previousResults = _state.results;
    _state = _state.copyWith(
      query: query,
      results: const <WordEntry>[],
      history: _state.history,
    );
    if (previousQuery != query || previousResults.isNotEmpty) {
      notifyListeners();
    }

    if (normalized.isEmpty) {
      return;
    }

    final results = await _lookupRepository.searchWords(normalized);
    if (requestId != _searchRequestId || _state.query != query) {
      return;
    }
    final dedupedResults = _dedupeByHeadword(results);

    _state = _state.copyWith(
      query: query,
      results: dedupedResults,
      history: _state.history,
    );
    notifyListeners();
  }

  Future<void> selectEntry(WordEntry entry) async {
    await _ensureHistoryLoaded();
    await _historyRepository.saveEntry(entry);
    _state = _state.copyWith(history: await _historyRepository.loadHistory());
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _ensureHistoryLoaded();
    await _historyRepository.clear();
    _state = _state.copyWith(history: await _historyRepository.loadHistory());
    notifyListeners();
  }

  WordEntry? findById(String id) => _lookupRepository.findById(id);

  List<WordEntry> _dedupeByHeadword(List<WordEntry> entries) {
    final seenHeadwords = <String>{};
    final deduped = <WordEntry>[];
    for (final entry in entries) {
      final headword = entry.word.trim().toLowerCase();
      if (headword.isEmpty || !seenHeadwords.add(headword)) {
        continue;
      }
      deduped.add(entry);
    }
    return deduped;
  }
}
