import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';

enum DictionaryLibraryStatus { idle, loading, ready, failure }

class DictionaryLibraryState {
  static const Object _sentinel = Object();

  const DictionaryLibraryState({
    required this.status,
    required this.items,
    required this.query,
    this.errorMessage,
  });

  const DictionaryLibraryState.idle()
    : status = DictionaryLibraryStatus.idle,
      items = const <DictionaryLibraryItem>[],
      query = '',
      errorMessage = null;

  final DictionaryLibraryStatus status;
  final List<DictionaryLibraryItem> items;
  final String query;
  final String? errorMessage;

  DictionaryLibraryState copyWith({
    DictionaryLibraryStatus? status,
    List<DictionaryLibraryItem>? items,
    String? query,
    Object? errorMessage = _sentinel,
  }) {
    return DictionaryLibraryState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class DictionaryLibraryController extends ChangeNotifier {
  DictionaryLibraryController({
    required DictionaryLibraryRepository repository,
  }) : _repository = repository;

  final DictionaryLibraryRepository _repository;

  DictionaryLibraryState _state = const DictionaryLibraryState.idle();

  DictionaryLibraryState get state => _state;

  List<DictionaryLibraryItem> get visibleItems =>
      _filteredItems.where((item) => item.isVisible).toList(growable: false);

  List<DictionaryLibraryItem> get hiddenItems =>
      _filteredItems.where((item) => !item.isVisible).toList(growable: false);

  DictionaryLibraryItem? itemById(String id) {
    for (final item in _state.items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> load() async {
    _state = _state.copyWith(
      status: DictionaryLibraryStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final items = await _repository.loadLibraryItems();
      _state = _state.copyWith(
        status: DictionaryLibraryStatus.ready,
        items: items,
        errorMessage: null,
      );
    } catch (error) {
      _state = _state.copyWith(
        status: DictionaryLibraryStatus.failure,
        errorMessage: '$error',
      );
    }

    notifyListeners();
  }

  void updateQuery(String query) {
    _state = _state.copyWith(query: query);
    notifyListeners();
  }

  Future<void> reorderVisible(List<String> visibleIds) async {
    await _repository.reorderVisible(visibleIds);
    await _reloadKeepingQuery();
  }

  Future<void> deleteDictionary(String id) async {
    await _repository.deleteDictionary(id);
    await _reloadKeepingQuery();
  }

  Future<void> moveToVisibleIndex(String id, int targetIndex) async {
    final item = itemById(id);
    if (item == null) {
      return;
    }

    final visibleIds = _state.items
        .where((entry) => entry.isVisible)
        .map((entry) => entry.id)
        .where((entryId) => entryId != id)
        .toList(growable: true);

    if (!item.isVisible) {
      await _repository.setVisibility(id, true);
    }

    final safeIndex = targetIndex.clamp(0, visibleIds.length);
    visibleIds.insert(safeIndex, id);
    await _repository.reorderVisible(visibleIds);
    await _reloadKeepingQuery();
  }

  Future<void> setVisibility(String id, bool isVisible) async {
    await _repository.setVisibility(id, isVisible);
    await _reloadKeepingQuery();
  }

  Future<void> moveToHidden(String id) async {
    final item = itemById(id);
    if (item == null || !item.isVisible) {
      return;
    }

    await _repository.setVisibility(id, false);
    await _reloadKeepingQuery();
  }

  Future<void> setAutoExpand(String id, bool autoExpand) async {
    await _repository.setAutoExpand(id, autoExpand);
    await _reloadKeepingQuery();
  }

  List<DictionaryLibraryItem> get _filteredItems {
    final keyword = _state.query.trim();
    if (keyword.isEmpty) {
      return _state.items;
    }

    return _state.items
        .where((item) => item.name.contains(keyword))
        .toList(growable: false);
  }

  Future<void> _reloadKeepingQuery() async {
    final query = _state.query;
    await load();
    if (_state.query != query) {
      _state = _state.copyWith(query: query);
      notifyListeners();
    }
  }
}
