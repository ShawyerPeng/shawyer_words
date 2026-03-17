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
       _state = SearchState(history: historyRepository.loadHistory());

  final WordLookupRepository _lookupRepository;
  final SearchHistoryRepository _historyRepository;

  SearchState _state;
  int _searchRequestId = 0;

  SearchState get state => _state;

  Future<void> updateQuery(String query) async {
    final requestId = ++_searchRequestId;
    final normalized = query.trim();
    _state = _state.copyWith(
      query: query,
      results: normalized.isEmpty ? const <WordEntry>[] : const <WordEntry>[],
      history: _historyRepository.loadHistory(),
    );
    notifyListeners();

    if (normalized.isEmpty) {
      return;
    }

    final results = await _lookupRepository.searchWords(normalized);
    if (requestId != _searchRequestId || _state.query != query) {
      return;
    }

    _state = _state.copyWith(
      query: query,
      results: results,
      history: _historyRepository.loadHistory(),
    );
    notifyListeners();
  }

  Future<void> selectEntry(WordEntry entry) async {
    _historyRepository.saveEntry(entry);
    _state = _state.copyWith(history: _historyRepository.loadHistory());
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _historyRepository.clear();
    _state = _state.copyWith(history: _historyRepository.loadHistory());
    notifyListeners();
  }

  WordEntry? findById(String id) => _lookupRepository.findById(id);
}
