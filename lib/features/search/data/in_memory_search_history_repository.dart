import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/domain/search_history_repository.dart';

class InMemorySearchHistoryRepository implements SearchHistoryRepository {
  final List<WordEntry> _history = <WordEntry>[];

  @override
  Future<void> clear() async {
    _history.clear();
  }

  @override
  Future<List<WordEntry>> loadHistory() async {
    return List<WordEntry>.unmodifiable(_history);
  }

  @override
  Future<void> saveEntry(WordEntry entry, {int limit = 10}) async {
    _history.removeWhere((item) => item.id == entry.id);
    _history.insert(0, entry);
    if (_history.length > limit) {
      _history.removeRange(limit, _history.length);
    }
  }
}
