import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_preview_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

enum DictionaryStatus { idle, importing, ready, failure }

enum DictionaryImportSessionStage {
  closed,
  pickerOverlay,
  confirming,
  previewing,
  installing,
  failure,
}

class DictionaryImportSession {
  static const Object _sentinel = Object();

  const DictionaryImportSession({
    required this.stage,
    this.sourcePaths = const <String>[],
    this.preview,
    this.previewPage,
    this.selectedPreviewEntry,
    this.errorMessage,
  });

  const DictionaryImportSession.closed()
    : stage = DictionaryImportSessionStage.closed,
      sourcePaths = const <String>[],
      preview = null,
      previewPage = null,
      selectedPreviewEntry = null,
      errorMessage = null;

  final DictionaryImportSessionStage stage;
  final List<String> sourcePaths;
  final DictionaryImportPreview? preview;
  final DictionaryPreviewPage? previewPage;
  final WordEntry? selectedPreviewEntry;
  final String? errorMessage;

  bool get isOpen => stage != DictionaryImportSessionStage.closed;

  DictionaryImportSession copyWith({
    DictionaryImportSessionStage? stage,
    List<String>? sourcePaths,
    Object? preview = _sentinel,
    Object? previewPage = _sentinel,
    Object? selectedPreviewEntry = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return DictionaryImportSession(
      stage: stage ?? this.stage,
      sourcePaths: sourcePaths ?? this.sourcePaths,
      preview: identical(preview, _sentinel)
          ? this.preview
          : preview as DictionaryImportPreview?,
      previewPage: identical(previewPage, _sentinel)
          ? this.previewPage
          : previewPage as DictionaryPreviewPage?,
      selectedPreviewEntry: identical(selectedPreviewEntry, _sentinel)
          ? this.selectedPreviewEntry
          : selectedPreviewEntry as WordEntry?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class DictionaryState {
  static const Object _sentinel = Object();

  const DictionaryState({
    required this.status,
    required this.entries,
    this.dictionary,
    this.activePackage,
    this.currentIndex = 0,
    this.errorMessage,
    this.importSession = const DictionaryImportSession.closed(),
  });

  const DictionaryState.idle()
    : status = DictionaryStatus.idle,
      entries = const [],
      dictionary = null,
      activePackage = null,
      currentIndex = 0,
      errorMessage = null,
      importSession = const DictionaryImportSession.closed();

  final DictionaryStatus status;
  final List<WordEntry> entries;
  final DictionarySummary? dictionary;
  final DictionaryPackage? activePackage;
  final int currentIndex;
  final String? errorMessage;
  final DictionaryImportSession importSession;

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
    DictionaryImportSession? importSession,
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
      importSession: importSession ?? this.importSession,
    );
  }
}

class DictionaryController extends ChangeNotifier {
  DictionaryController({
    required DictionaryRepository dictionaryRepository,
    required DictionaryPreviewRepository previewRepository,
    required StudyRepository studyRepository,
  }) : _dictionaryRepository = dictionaryRepository,
       _previewRepository = previewRepository,
       _studyRepository = studyRepository;

  final DictionaryRepository _dictionaryRepository;
  final DictionaryPreviewRepository _previewRepository;
  final StudyRepository _studyRepository;

  DictionaryState _state = const DictionaryState.idle();

  DictionaryState get state => _state;

  void startImportSession() {
    _state = _state.copyWith(
      importSession: const DictionaryImportSession(
        stage: DictionaryImportSessionStage.pickerOverlay,
      ),
    );
    notifyListeners();
  }

  Future<void> addImportSource(String sourcePath) async {
    final previousPreview = _state.importSession.preview;
    final nextSourcePaths = [..._state.importSession.sourcePaths, sourcePath];

    try {
      final preview = await _previewRepository.preparePreview(nextSourcePaths);
      if (previousPreview != null) {
        await _previewRepository.disposePreview(previousPreview);
      }
      _state = _state.copyWith(
        importSession: DictionaryImportSession(
          stage: DictionaryImportSessionStage.confirming,
          sourcePaths: nextSourcePaths,
          preview: preview,
        ),
      );
    } catch (error) {
      _state = _state.copyWith(
        importSession: _state.importSession.copyWith(
          stage: DictionaryImportSessionStage.failure,
          sourcePaths: nextSourcePaths,
          errorMessage: _formatError(error),
        ),
      );
    }
    notifyListeners();
  }

  Future<void> openImportPreview() async {
    final preview = _state.importSession.preview;
    if (preview == null) {
      return;
    }
    await _loadPreviewPage(preview: preview, pageNumber: 1);
  }

  void returnToImportConfirmation() {
    if (_state.importSession.preview == null) {
      return;
    }
    _state = _state.copyWith(
      importSession: _state.importSession.copyWith(
        stage: DictionaryImportSessionStage.confirming,
      ),
    );
    notifyListeners();
  }

  Future<void> goToPreviewPage(int pageNumber) async {
    final preview = _state.importSession.preview;
    if (preview == null) {
      return;
    }
    await _loadPreviewPage(preview: preview, pageNumber: pageNumber);
  }

  void selectPreviewEntry(WordEntry entry) {
    _state = _state.copyWith(
      importSession: _state.importSession.copyWith(selectedPreviewEntry: entry),
    );
    notifyListeners();
  }

  Future<void> installImport() async {
    final preview = _state.importSession.preview;
    if (preview == null) {
      return;
    }

    _state = _state.copyWith(
      status: DictionaryStatus.importing,
      entries: const [],
      dictionary: null,
      activePackage: null,
      currentIndex: 0,
      errorMessage: null,
      importSession: _state.importSession.copyWith(
        stage: DictionaryImportSessionStage.installing,
      ),
    );
    notifyListeners();

    await _performImport(preview.sourceRootPath);
    final latestPreview = _state.importSession.preview;
    if (latestPreview != null) {
      await _previewRepository.disposePreview(latestPreview);
    }
    _state = _state.copyWith(
      importSession: const DictionaryImportSession.closed(),
    );
    notifyListeners();
  }

  Future<void> closeImportSession() async {
    final preview = _state.importSession.preview;
    if (preview != null) {
      await _previewRepository.disposePreview(preview);
    }
    _state = _state.copyWith(
      importSession: const DictionaryImportSession.closed(),
    );
    notifyListeners();
  }

  Future<void> importDictionary(String filePath) async {
    await _performImport(filePath);
    notifyListeners();
  }

  Future<void> _performImport(String filePath) async {
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
        importSession: _state.importSession,
      );
    } catch (error) {
      _state = _state.copyWith(
        status: DictionaryStatus.failure,
        entries: const [],
        activePackage: null,
        errorMessage: _formatError(error),
      );
    }
  }

  Future<void> _loadPreviewPage({
    required DictionaryImportPreview preview,
    required int pageNumber,
  }) async {
    try {
      final page = await _previewRepository.loadPage(
        preview: preview,
        pageNumber: pageNumber,
      );
      _state = _state.copyWith(
        importSession: _state.importSession.copyWith(
          stage: DictionaryImportSessionStage.previewing,
          previewPage: page,
          selectedPreviewEntry: page.entries.isEmpty
              ? null
              : page.entries.first,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _state = _state.copyWith(
        importSession: _state.importSession.copyWith(
          stage: DictionaryImportSessionStage.failure,
          errorMessage: _formatError(error),
        ),
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
