import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';

typedef RemoteVocabularyLoader =
    Future<String> Function(
      Uri uri, {
      VocabularyDownloadProgressCallback? onProgress,
    });

class InMemoryStudyPlanRepository implements StudyPlanRepository {
  InMemoryStudyPlanRepository._({
    required List<OfficialVocabularyBook> officialBooks,
    required RemoteVocabularyLoader remoteVocabularyLoader,
    required Duration remoteVocabularyTimeout,
    required List<VocabularyNotebook> notebooks,
    required String selectedNotebookId,
    String? currentBookId,
    Set<String>? myBookIds,
  }) : _officialBooks = officialBooks,
       _remoteVocabularyLoader = remoteVocabularyLoader,
       _remoteVocabularyTimeout = remoteVocabularyTimeout,
       _notebooks = notebooks,
       _selectedNotebookId = selectedNotebookId,
       _currentBookId = currentBookId,
       _myBookIds = myBookIds ?? <String>{};

  factory InMemoryStudyPlanRepository.seeded({
    RemoteVocabularyLoader? remoteVocabularyLoader,
    Duration remoteVocabularyTimeout = const Duration(seconds: 8),
  }) {
    return InMemoryStudyPlanRepository._(
      officialBooks: List<OfficialVocabularyBook>.from(_seedBooks),
      remoteVocabularyLoader:
          remoteVocabularyLoader ?? InMemoryStudyPlanRepository._loadRemoteText,
      remoteVocabularyTimeout: remoteVocabularyTimeout,
      notebooks: <VocabularyNotebook>[
        const VocabularyNotebook(
          id: 'my-vocabulary',
          name: '我的词汇',
          description: '默认生词本',
          items: <VocabularyNotebookWord>[],
          isDefault: true,
        ),
      ],
      selectedNotebookId: 'my-vocabulary',
    );
  }

  final List<OfficialVocabularyBook> _officialBooks;
  final RemoteVocabularyLoader _remoteVocabularyLoader;
  final Duration _remoteVocabularyTimeout;
  final List<VocabularyNotebook> _notebooks;
  String _selectedNotebookId;
  final Set<String> _myBookIds;
  String? _currentBookId;

  @override
  Future<StudyPlanOverview> loadOverview() async {
    final currentBook = _bookById(_currentBookId);
    final myBooks = _officialBooks
        .where((book) => _myBookIds.contains(book.id))
        .toList(growable: false);

    return StudyPlanOverview(
      currentBook: currentBook,
      myBooks: myBooks,
      notebooks: List<VocabularyNotebook>.unmodifiable(_notebooks),
      selectedNotebookId: _selectedNotebookId,
      newCount: currentBook == null ? 0 : 20,
      reviewCount: 0,
      masteredCount: 0,
      remainingCount: currentBook?.wordCount ?? 0,
      weekDays: _buildWeekDays(),
    );
  }

  @override
  Future<List<OfficialVocabularyBook>> loadOfficialBooks() async {
    return List<OfficialVocabularyBook>.unmodifiable(_officialBooks);
  }

  @override
  Future<void> selectBook(String bookId) async {
    final book = _bookById(bookId);
    if (book == null) {
      throw ArgumentError.value(bookId, 'bookId', 'Unknown vocabulary book');
    }

    if (book.isRemote && book.entries.isEmpty) {
      throw StateError('词汇表尚未下载');
    }

    _myBookIds.add(bookId);
    _currentBookId = bookId;
  }

  @override
  Future<void> downloadBook(
    String bookId, {
    VocabularyDownloadProgressCallback? onProgress,
  }) async {
    final book = _bookById(bookId);
    if (book == null) {
      throw ArgumentError.value(bookId, 'bookId', 'Unknown vocabulary book');
    }
    if (!book.isRemote || book.entries.isNotEmpty) {
      _myBookIds.add(bookId);
      return;
    }

    await _loadRemoteBook(book, onProgress: onProgress);
    _myBookIds.add(bookId);
  }

  @override
  Future<void> selectNotebook(String notebookId) async {
    final exists = _notebooks.any((notebook) => notebook.id == notebookId);
    if (!exists) {
      throw ArgumentError.value(
        notebookId,
        'notebookId',
        'Unknown vocabulary notebook',
      );
    }
    _selectedNotebookId = notebookId;
  }

  @override
  Future<void> createNotebook({
    required String name,
    String description = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Notebook name is required');
    }
    final id = 'notebook-${DateTime.now().microsecondsSinceEpoch}';
    _notebooks.add(
      VocabularyNotebook(
        id: id,
        name: trimmedName,
        description: description.trim(),
        items: const <VocabularyNotebookWord>[],
      ),
    );
    _selectedNotebookId = id;
  }

  @override
  Future<void> updateNotebook({
    required String notebookId,
    required String name,
    String description = '',
  }) async {
    final index = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (index < 0) {
      throw ArgumentError.value(
        notebookId,
        'notebookId',
        'Unknown vocabulary notebook',
      );
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Notebook name is required');
    }
    final current = _notebooks[index];
    _notebooks[index] = VocabularyNotebook(
      id: current.id,
      name: trimmedName,
      description: description.trim(),
      items: current.items,
      isDefault: current.isDefault,
    );
  }

  @override
  Future<void> deleteNotebook(String notebookId) async {
    final index = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (index < 0) {
      throw ArgumentError.value(
        notebookId,
        'notebookId',
        'Unknown vocabulary notebook',
      );
    }
    final current = _notebooks[index];
    if (current.isDefault) {
      throw StateError('默认生词本不可删除');
    }
    _notebooks.removeAt(index);
    if (_selectedNotebookId == notebookId && _notebooks.isNotEmpty) {
      _selectedNotebookId = _notebooks.first.id;
    }
  }

  @override
  Future<void> importWordsToNotebook({
    required String notebookId,
    required List<String> words,
  }) async {
    final index = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (index < 0) {
      throw ArgumentError.value(
        notebookId,
        'notebookId',
        'Unknown vocabulary notebook',
      );
    }

    final existing = _notebooks[index];
    final mergedItems = <VocabularyNotebookWord>[];
    final dedupe = <String>{};

    for (final item in existing.items) {
      final normalized = item.word.trim().toLowerCase();
      if (normalized.isEmpty || !dedupe.add(normalized)) {
        continue;
      }
      mergedItems.add(item);
    }

    for (final rawWord in words) {
      final trimmed = rawWord.trim();
      final normalized = trimmed.toLowerCase();
      if (trimmed.isEmpty || !dedupe.add(normalized)) {
        continue;
      }
      mergedItems.add(
        VocabularyNotebookWord(word: trimmed, addedAt: DateTime.now().toUtc()),
      );
    }

    _notebooks[index] = VocabularyNotebook(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      items: List<VocabularyNotebookWord>.unmodifiable(mergedItems),
      isDefault: existing.isDefault,
    );
    _selectedNotebookId = notebookId;
  }

  OfficialVocabularyBook? _bookById(String? id) {
    if (id == null) {
      return null;
    }

    for (final book in _officialBooks) {
      if (book.id == id) {
        return book;
      }
    }

    return null;
  }

  Future<void> _loadRemoteBook(
    OfficialVocabularyBook book, {
    VocabularyDownloadProgressCallback? onProgress,
  }) async {
    final sourceUrl = book.sourceUrl;
    if (sourceUrl == null) {
      return;
    }

    final rawText = await _loadRemoteTextWithFallback(
      Uri.parse(sourceUrl),
      onProgress: onProgress,
    );
    final entries = _parseRemoteEntries(book.id, rawText);
    if (entries.isEmpty) {
      throw StateError('词汇表内容为空');
    }

    final index = _officialBooks.indexWhere((item) => item.id == book.id);
    if (index == -1) {
      return;
    }

    _officialBooks[index] = book.copyWith(
      entries: entries,
      wordCount: entries.length,
    );
  }

  Future<String> _loadRemoteTextWithFallback(
    Uri uri, {
    VocabularyDownloadProgressCallback? onProgress,
  }) async {
    final candidates = <Uri>[uri, ..._buildFallbackUris(uri)];
    Object? lastError;

    for (final candidate in candidates) {
      try {
        onProgress?.call(0, null);
        return await _remoteVocabularyLoader(
          candidate,
          onProgress: onProgress,
        ).timeout(
          _remoteVocabularyTimeout,
          onTimeout: () {
            throw TimeoutException('词汇表下载超时');
          },
        );
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw StateError('词汇表下载失败');
  }

  static List<Uri> _buildFallbackUris(Uri uri) {
    if (uri.host == 'shawyerpeng.cn' &&
        uri.path.endsWith('CET_4+6_edited.txt')) {
      final raw = Uri.parse(
        'https://raw.githubusercontent.com/mahavivo/english-wordlists/refs/heads/master/CET_4%2B6_edited.txt',
      );
      final api = _buildGitHubContentsApiUri(raw);
      return <Uri>[
        raw,
        if (api != null) api,
      ];
    }
    final githubApiUri = _buildGitHubContentsApiUri(uri);
    if (githubApiUri == null) {
      return const <Uri>[];
    }

    return <Uri>[githubApiUri];
  }

  static Uri? _buildGitHubContentsApiUri(Uri uri) {
    if (uri.host != 'raw.githubusercontent.com') {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length < 4) {
      return null;
    }

    final owner = segments[0];
    final repo = segments[1];

    late final String ref;
    late final List<String> contentSegments;

    if (segments.length >= 6 &&
        segments[2] == 'refs' &&
        segments[3] == 'heads') {
      ref = segments[4];
      contentSegments = segments.sublist(5);
    } else {
      ref = segments[2];
      contentSegments = segments.sublist(3);
    }

    if (contentSegments.isEmpty) {
      return null;
    }

    return Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/contents/${contentSegments.join('/')}',
      <String, String>{'ref': ref},
    );
  }

  static List<WordEntry> _parseRemoteEntries(String bookId, String rawText) {
    final entries = <WordEntry>[];
    final seenWords = <String>{};

    for (final line in const LineSplitter().convert(rawText)) {
      final word = line.trim();
      if (word.isEmpty || !seenWords.add(word)) {
        continue;
      }

      entries.add(
        WordEntry(
          id: '$bookId-${entries.length + 1}',
          word: word,
          pronunciation: '',
          partOfSpeech: '',
          definition: '',
          exampleSentence: '',
          rawContent: '<p>$word</p>',
        ),
      );
    }

    return List<WordEntry>.unmodifiable(entries);
  }

  static Future<String> _loadRemoteText(
    Uri uri, {
    VocabularyDownloadProgressCallback? onProgress,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Request failed with status ${response.statusCode}',
          uri: uri,
        );
      }

      final totalBytes = response.contentLength > 0
          ? response.contentLength
          : null;
      final buffer = StringBuffer();
      var receivedBytes = 0;

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        buffer.write(utf8.decode(chunk, allowMalformed: true));
        onProgress?.call(receivedBytes, totalBytes);
      }

      return buffer.toString();
    } finally {
      client.close(force: true);
    }
  }

  static List<StudyCalendarDay> _buildWeekDays() {
    const labels = <String>['日', '一', '二', '三', '四', '五', '六'];
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));

    return List<StudyCalendarDay>.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return StudyCalendarDay(
        weekdayLabel: labels[day.weekday % 7],
        dayOfMonth: day.day,
        isToday:
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day,
      );
    }, growable: false);
  }
}

const List<OfficialVocabularyBook> _seedBooks = <OfficialVocabularyBook>[
  OfficialVocabularyBook(
    id: 'cet46-remote',
    category: '四六级',
    title: 'CET 4+6',
    subtitle: '外部词汇表导入',
    wordCount: 0,
    coverKey: 'mint',
    entries: <WordEntry>[],
    sourceUrl:
        // 'https://raw.githubusercontent.com/mahavivo/english-wordlists/refs/heads/master/CET_4%2B6_edited.txt',
        'https://shawyerpeng.cn/CET_4+6_edited.txt',
  ),
  OfficialVocabularyBook(
    id: 'cet4-core',
    category: '四级',
    title: '四级核心词汇',
    subtitle: '大学英语四级高频词',
    wordCount: 2200,
    coverKey: 'mint',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'cet6-core',
    category: '六级',
    title: '六级核心词汇',
    subtitle: '大学英语六级高频词',
    wordCount: 3200,
    coverKey: 'amber',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'postgrad-core',
    category: '考研',
    title: '考研大纲词汇',
    subtitle: '考研英语常考词',
    wordCount: 5500,
    coverKey: 'violet',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'tem4-core',
    category: '专四',
    title: '专四高频词汇',
    subtitle: '英语专业四级核心词',
    wordCount: 4200,
    coverKey: 'sky',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'tem8-core',
    category: '专八',
    title: '专八进阶词汇',
    subtitle: '英语专业八级核心词',
    wordCount: 7600,
    coverKey: 'rose',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'toefl-core',
    category: '托福',
    title: 'TOEFL 核心词',
    subtitle: '托福学术词汇',
    wordCount: 4600,
    coverKey: 'ocean',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'ielts-core',
    category: '雅思',
    title: 'IELTS',
    subtitle: '雅思词库',
    wordCount: 3575,
    coverKey: 'mint',
    entries: _sampleCoreEntries,
  ),
  OfficialVocabularyBook(
    id: 'ielts-complete',
    category: '雅思',
    title: 'IELTS乱序完整版',
    subtitle: 'IELTS乱序完整版',
    wordCount: 9354,
    coverKey: 'aurora',
    entries: <WordEntry>[
      WordEntry(
        id: '1',
        word: 'abandon',
        pronunciation: '/əˈbændən/',
        partOfSpeech: 'verb',
        definition: 'to leave behind',
        exampleSentence: 'They abandon the plan at sunrise.',
        rawContent: '<p>abandon</p>',
      ),
      WordEntry(
        id: '2',
        word: 'brisk',
        pronunciation: '/brɪsk/',
        partOfSpeech: 'adjective',
        definition: 'quick and energetic',
        exampleSentence: 'The morning air felt brisk.',
        rawContent: '<p>brisk</p>',
      ),
      WordEntry(
        id: '3',
        word: 'aristocracy',
        pronunciation: '/ˌærɪˈstɒkrəsi/',
        partOfSpeech: 'noun',
        definition: '贵族统治；贵族阶层',
        exampleSentence:
            'A new managerial elite was replacing the old aristocracy.',
        rawContent: '<p>aristocracy</p>',
      ),
    ],
  ),
  OfficialVocabularyBook(
    id: 'sat-core',
    category: 'SAT',
    title: 'SAT 高频词汇',
    subtitle: 'SAT 阅读与写作词汇',
    wordCount: 5000,
    coverKey: 'graphite',
    entries: _sampleCoreEntries,
  ),
];

const List<WordEntry> _sampleCoreEntries = <WordEntry>[
  WordEntry(
    id: 'sample-1',
    word: 'notable',
    pronunciation: '/ˈnəʊtəbl/',
    partOfSpeech: 'adjective',
    definition: '值得注意的；显著的',
    exampleSentence: 'The city saw notable growth last year.',
    rawContent: '<p>notable</p>',
  ),
  WordEntry(
    id: 'sample-2',
    word: 'refine',
    pronunciation: '/rɪˈfaɪn/',
    partOfSpeech: 'verb',
    definition: '改进；提炼',
    exampleSentence: 'You need to refine the final draft.',
    rawContent: '<p>refine</p>',
  ),
  WordEntry(
    id: 'sample-3',
    word: 'retain',
    pronunciation: '/rɪˈteɪn/',
    partOfSpeech: 'verb',
    definition: '保持；保留',
    exampleSentence: 'It is difficult to retain all the details.',
    rawContent: '<p>retain</p>',
  ),
];
