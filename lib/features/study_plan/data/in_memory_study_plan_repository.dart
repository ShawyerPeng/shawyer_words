import 'dart:convert';
import 'dart:io';

import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_repository.dart';

typedef RemoteVocabularyLoader = Future<String> Function(Uri uri);

class InMemoryStudyPlanRepository implements StudyPlanRepository {
  InMemoryStudyPlanRepository._({
    required List<OfficialVocabularyBook> officialBooks,
    required RemoteVocabularyLoader remoteVocabularyLoader,
    String? currentBookId,
    Set<String>? myBookIds,
  }) : _officialBooks = officialBooks,
       _remoteVocabularyLoader = remoteVocabularyLoader,
       _currentBookId = currentBookId,
       _myBookIds = myBookIds ?? <String>{};

  factory InMemoryStudyPlanRepository.seeded({
    RemoteVocabularyLoader? remoteVocabularyLoader,
  }) {
    return InMemoryStudyPlanRepository._(
      officialBooks: List<OfficialVocabularyBook>.from(_seedBooks),
      remoteVocabularyLoader:
          remoteVocabularyLoader ?? InMemoryStudyPlanRepository._loadRemoteText,
    );
  }

  final List<OfficialVocabularyBook> _officialBooks;
  final RemoteVocabularyLoader _remoteVocabularyLoader;
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
      await _loadRemoteBook(book);
    }

    _myBookIds.add(bookId);
    _currentBookId = bookId;
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

  Future<void> _loadRemoteBook(OfficialVocabularyBook book) async {
    final sourceUrl = book.sourceUrl;
    if (sourceUrl == null) {
      return;
    }

    final rawText = await _remoteVocabularyLoader(Uri.parse(sourceUrl));
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

  static Future<String> _loadRemoteText(Uri uri) async {
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

      return response.transform(utf8.decoder).join();
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
        'https://raw.githubusercontent.com/mahavivo/english-wordlists/refs/heads/master/CET_4%2B6_edited.txt',
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
