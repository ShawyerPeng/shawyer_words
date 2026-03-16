import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';

enum StudyPlanStatus { initial, loading, ready, failure }

class StudyPlanState {
  const StudyPlanState({
    required this.status,
    required this.categories,
    required this.selectedCategory,
    required this.query,
    required this.officialBooks,
    required this.myBooks,
    required this.weekDays,
    this.currentBook,
    this.errorMessage,
  });

  const StudyPlanState.initial()
    : status = StudyPlanStatus.initial,
      categories = const <String>[],
      selectedCategory = '雅思',
      query = '',
      officialBooks = const <OfficialVocabularyBook>[],
      myBooks = const <OfficialVocabularyBook>[],
      weekDays = const <StudyCalendarDay>[],
      currentBook = null,
      errorMessage = null;

  final StudyPlanStatus status;
  final List<String> categories;
  final String selectedCategory;
  final String query;
  final List<OfficialVocabularyBook> officialBooks;
  final List<OfficialVocabularyBook> myBooks;
  final List<StudyCalendarDay> weekDays;
  final OfficialVocabularyBook? currentBook;
  final String? errorMessage;

  int get newCount => currentBook == null ? 0 : 20;
  int get reviewCount => currentBook == null ? 0 : 0;
  int get masteredCount => currentBook == null ? 0 : 0;
  int get remainingCount => currentBook?.wordCount ?? 0;

  List<OfficialVocabularyBook> get visibleBooks {
    final keyword = query.trim().toLowerCase();
    return officialBooks
        .where((book) {
          final matchesCategory =
              selectedCategory.isEmpty || book.category == selectedCategory;
          final matchesKeyword =
              keyword.isEmpty ||
              book.title.toLowerCase().contains(keyword) ||
              book.subtitle.toLowerCase().contains(keyword);
          return matchesCategory && matchesKeyword;
        })
        .toList(growable: false);
  }

  StudyPlanState copyWith({
    StudyPlanStatus? status,
    List<String>? categories,
    String? selectedCategory,
    String? query,
    List<OfficialVocabularyBook>? officialBooks,
    List<OfficialVocabularyBook>? myBooks,
    List<StudyCalendarDay>? weekDays,
    Object? currentBook = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return StudyPlanState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      query: query ?? this.query,
      officialBooks: officialBooks ?? this.officialBooks,
      myBooks: myBooks ?? this.myBooks,
      weekDays: weekDays ?? this.weekDays,
      currentBook: identical(currentBook, _sentinel)
          ? this.currentBook
          : currentBook as OfficialVocabularyBook?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _sentinel = Object();
}

class StudyPlanController extends ChangeNotifier {
  StudyPlanController({required StudyPlanRepository repository})
    : _repository = repository;

  final StudyPlanRepository _repository;

  StudyPlanState _state = const StudyPlanState.initial();

  StudyPlanState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(
      status: StudyPlanStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final officialBooks = await _repository.loadOfficialBooks();
      final overview = await _repository.loadOverview();
      final categories = officialBooks
          .map((book) => book.category)
          .toSet()
          .toList(growable: false);
      final fallbackCategory = categories.isEmpty ? '' : categories.first;
      final selectedCategory =
          overview.currentBook?.category ??
          (_state.selectedCategory.isEmpty
              ? fallbackCategory
              : _state.selectedCategory);

      _state = _state.copyWith(
        status: StudyPlanStatus.ready,
        categories: categories,
        selectedCategory: selectedCategory,
        officialBooks: officialBooks,
        myBooks: overview.myBooks,
        weekDays: overview.weekDays,
        currentBook: overview.currentBook,
        errorMessage: null,
      );
    } catch (error) {
      _state = _state.copyWith(
        status: StudyPlanStatus.failure,
        errorMessage: '$error',
      );
    }

    notifyListeners();
  }

  void updateQuery(String query) {
    _state = _state.copyWith(query: query);
    notifyListeners();
  }

  void selectCategory(String category) {
    _state = _state.copyWith(selectedCategory: category);
    notifyListeners();
  }

  Future<void> selectBook(String bookId) async {
    await _repository.selectBook(bookId);
    await load();
  }
}
