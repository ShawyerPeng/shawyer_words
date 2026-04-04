import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';

enum StudyPlanStatus { initial, loading, ready, failure }

enum VocabularyImportStatus { idle, importing, success, failure }

enum VocabularyDownloadStatus { idle, downloading, downloaded, failure }

class VocabularyDownloadState {
  const VocabularyDownloadState({
    required this.status,
    this.progress,
    this.message,
  });

  const VocabularyDownloadState.idle()
    : status = VocabularyDownloadStatus.idle,
      progress = null,
      message = null;

  final VocabularyDownloadStatus status;
  final double? progress;
  final String? message;

  VocabularyDownloadState copyWith({
    VocabularyDownloadStatus? status,
    Object? progress = StudyPlanState._sentinel,
    Object? message = StudyPlanState._sentinel,
  }) {
    return VocabularyDownloadState(
      status: status ?? this.status,
      progress: identical(progress, StudyPlanState._sentinel)
          ? this.progress
          : progress as double?,
      message: identical(message, StudyPlanState._sentinel)
          ? this.message
          : message as String?,
    );
  }
}

class StudyPlanState {
  const StudyPlanState({
    required this.status,
    required this.categories,
    required this.selectedCategory,
    required this.query,
    required this.officialBooks,
    required this.myBooks,
    required this.notebooks,
    required this.selectedNotebookId,
    required this.weekDays,
    required this.importStatus,
    required this.downloadStates,
    this.currentBook,
    this.errorMessage,
    this.importMessage,
  });

  const StudyPlanState.initial()
    : status = StudyPlanStatus.initial,
      categories = const <String>[],
      selectedCategory = '',
      query = '',
      officialBooks = const <OfficialVocabularyBook>[],
      myBooks = const <OfficialVocabularyBook>[],
      notebooks = const <VocabularyNotebook>[],
      selectedNotebookId = null,
      weekDays = const <StudyCalendarDay>[],
      importStatus = VocabularyImportStatus.idle,
      downloadStates = const <String, VocabularyDownloadState>{},
      currentBook = null,
      errorMessage = null,
      importMessage = null;

  final StudyPlanStatus status;
  final List<String> categories;
  final String selectedCategory;
  final String query;
  final List<OfficialVocabularyBook> officialBooks;
  final List<OfficialVocabularyBook> myBooks;
  final List<VocabularyNotebook> notebooks;
  final String? selectedNotebookId;
  final List<StudyCalendarDay> weekDays;
  final VocabularyImportStatus importStatus;
  final Map<String, VocabularyDownloadState> downloadStates;
  final OfficialVocabularyBook? currentBook;
  final String? errorMessage;
  final String? importMessage;

  int get newCount => currentBook == null ? 0 : 20;
  int get reviewCount => currentBook == null ? 0 : 0;
  int get masteredCount => currentBook == null ? 0 : 0;
  int get remainingCount => currentBook?.wordCount ?? 0;
  VocabularyNotebook? get selectedNotebook {
    final currentId = selectedNotebookId;
    if (notebooks.isEmpty) {
      return null;
    }
    if (currentId == null) {
      return notebooks.first;
    }
    for (final notebook in notebooks) {
      if (notebook.id == currentId) {
        return notebook;
      }
    }
    return notebooks.first;
  }

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
    List<VocabularyNotebook>? notebooks,
    Object? selectedNotebookId = _sentinel,
    List<StudyCalendarDay>? weekDays,
    VocabularyImportStatus? importStatus,
    Map<String, VocabularyDownloadState>? downloadStates,
    Object? currentBook = _sentinel,
    Object? errorMessage = _sentinel,
    Object? importMessage = _sentinel,
  }) {
    return StudyPlanState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      query: query ?? this.query,
      officialBooks: officialBooks ?? this.officialBooks,
      myBooks: myBooks ?? this.myBooks,
      notebooks: notebooks ?? this.notebooks,
      selectedNotebookId: identical(selectedNotebookId, _sentinel)
          ? this.selectedNotebookId
          : selectedNotebookId as String?,
      weekDays: weekDays ?? this.weekDays,
      importStatus: importStatus ?? this.importStatus,
      downloadStates: downloadStates ?? this.downloadStates,
      currentBook: identical(currentBook, _sentinel)
          ? this.currentBook
          : currentBook as OfficialVocabularyBook?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      importMessage: identical(importMessage, _sentinel)
          ? this.importMessage
          : importMessage as String?,
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
      final preferredCategory =
          overview.currentBook?.category ?? _state.selectedCategory;
      final selectedCategory = preferredCategory.isEmpty
          ? ''
          : (categories.contains(preferredCategory)
                ? preferredCategory
                : fallbackCategory);

      _state = _state.copyWith(
        status: StudyPlanStatus.ready,
        categories: categories,
        selectedCategory: selectedCategory,
        officialBooks: officialBooks,
        myBooks: overview.myBooks,
        notebooks: overview.notebooks,
        selectedNotebookId: overview.selectedNotebookId,
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

  Future<bool> downloadBook(String bookId) async {
    OfficialVocabularyBook? book;
    for (final candidate in _state.officialBooks) {
      if (candidate.id == bookId) {
        book = candidate;
        break;
      }
    }

    if (book == null) {
      return false;
    }

    if (!book.isRemote || book.entries.isNotEmpty) {
      _state = _state.copyWith(
        downloadStates: _withDownloadState(
          bookId,
          const VocabularyDownloadState(
            status: VocabularyDownloadStatus.downloaded,
            progress: 1,
          ),
        ),
      );
      notifyListeners();
      return true;
    }

    _state = _state.copyWith(
      importStatus: VocabularyImportStatus.importing,
      importMessage: '正在导入词汇表...',
      downloadStates: _withDownloadState(
        bookId,
        const VocabularyDownloadState(
          status: VocabularyDownloadStatus.downloading,
          progress: 0,
          message: '正在下载',
        ),
      ),
    );
    notifyListeners();

    try {
      await _repository.downloadBook(
        bookId,
        onProgress: (receivedBytes, totalBytes) {
          final progress = totalBytes == null || totalBytes <= 0
              ? null
              : (receivedBytes / totalBytes).clamp(0, 1).toDouble();
          _state = _state.copyWith(
            downloadStates: _withDownloadState(
              bookId,
              VocabularyDownloadState(
                status: VocabularyDownloadStatus.downloading,
                progress: progress,
                message: totalBytes == null || totalBytes <= 0
                    ? '正在下载'
                    : '已下载 ${(progress! * 100).round()}%',
              ),
            ),
          );
          notifyListeners();
        },
      );
      await load();
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.success,
        importMessage: '词汇表导入成功',
        downloadStates: _withDownloadState(
          bookId,
          const VocabularyDownloadState(
            status: VocabularyDownloadStatus.downloaded,
            progress: 1,
            message: '已下载',
          ),
        ),
      );
      notifyListeners();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '词汇表导入失败：$error',
        downloadStates: _withDownloadState(
          bookId,
          VocabularyDownloadState(
            status: VocabularyDownloadStatus.failure,
            progress: null,
            message: '$error',
          ),
        ),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectBook(String bookId) async {
    OfficialVocabularyBook? book;
    for (final candidate in _state.officialBooks) {
      if (candidate.id == bookId) {
        book = candidate;
        break;
      }
    }
    final isRemote = book?.isRemote ?? false;
    final requiresDownload = isRemote && (book?.entries.isEmpty ?? true);

    if (requiresDownload) {
      return false;
    }

    if (isRemote &&
        (_state.importStatus != VocabularyImportStatus.idle ||
            _state.importMessage != null)) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.idle,
        importMessage: null,
      );
      notifyListeners();
    }

    try {
      await _repository.selectBook(bookId);
      await load();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '词本选择失败：$error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectNotebook(String notebookId) async {
    try {
      await _repository.selectNotebook(notebookId);
      await load();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '生词本切换失败：$error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> createNotebook({
    required String name,
    String description = '',
  }) async {
    try {
      await _repository.createNotebook(name: name, description: description);
      await load();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '新建生词本失败：$error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotebook({
    required String notebookId,
    required String name,
    String description = '',
  }) async {
    try {
      await _repository.updateNotebook(
        notebookId: notebookId,
        name: name,
        description: description,
      );
      await load();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '编辑生词本失败：$error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotebook(String notebookId) async {
    try {
      await _repository.deleteNotebook(notebookId);
      await load();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '删除生词本失败：$error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> importWordsToNotebook({
    required String notebookId,
    required List<String> words,
  }) async {
    _state = _state.copyWith(
      importStatus: VocabularyImportStatus.importing,
      importMessage: '正在导入词汇...',
    );
    notifyListeners();
    try {
      await _repository.importWordsToNotebook(
        notebookId: notebookId,
        words: words,
      );
      await load();
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.success,
        importMessage: '已导入 ${words.length} 个单词',
      );
      notifyListeners();
      return true;
    } catch (error) {
      _state = _state.copyWith(
        importStatus: VocabularyImportStatus.failure,
        importMessage: '导入词汇失败：$error',
      );
      notifyListeners();
      return false;
    }
  }

  Map<String, VocabularyDownloadState> _withDownloadState(
    String bookId,
    VocabularyDownloadState nextState,
  ) {
    return <String, VocabularyDownloadState>{
      ..._state.downloadStates,
      bookId: nextState,
    };
  }
}
