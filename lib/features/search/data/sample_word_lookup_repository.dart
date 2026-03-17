import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/domain/word_lookup_repository.dart';

class SampleWordLookupRepository implements WordLookupRepository {
  SampleWordLookupRepository(this.entries);

  factory SampleWordLookupRepository.seeded() {
    return SampleWordLookupRepository(_seedEntries);
  }

  final List<WordEntry> entries;

  @override
  WordEntry? findById(String id) {
    for (final entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  @override
  Future<List<WordEntry>> searchWords(String query, {int limit = 20}) async {
    return rankWordEntries(entries, query, limit: limit);
  }
}

List<WordEntry> rankWordEntries(
  List<WordEntry> entries,
  String query, {
  required int limit,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const <WordEntry>[];
  }

  final exactMatches = <WordEntry>[];
  final prefixMatches = <WordEntry>[];

  for (final entry in entries) {
    final word = entry.word.toLowerCase();
    if (word == normalized) {
      exactMatches.add(entry);
      continue;
    }
    if (word.startsWith(normalized)) {
      prefixMatches.add(entry);
    }
  }

  final ranked = <WordEntry>[...exactMatches, ...prefixMatches];
  return ranked.take(limit).toList();
}

const List<WordEntry> _seedEntries = <WordEntry>[
  WordEntry(
    id: 'nut',
    word: 'nut',
    pronunciation: '/nʌt/',
    partOfSpeech: 'n.',
    definition: '干果, 坚果; 螺母',
    exampleSentence: 'She added crushed nuts to the cake batter.',
    rawContent: '<p>nut n. 干果, 坚果; 螺母</p>',
  ),
  WordEntry(
    id: 'career',
    word: 'career',
    pronunciation: '/kəˈrɪr/',
    partOfSpeech: 'n.',
    definition: '事业, 职业; 生涯',
    exampleSentence: 'He started a new career in design.',
    rawContent: '<p>career n. 事业, 职业; 生涯</p>',
  ),
  WordEntry(
    id: 'lackluster',
    word: 'lackluster',
    pronunciation: '/ˈlækˌlʌstər/',
    partOfSpeech: 'adj.',
    definition: '无光泽的, 毫无生气的, 暗淡无光的',
    exampleSentence: 'The team gave a lackluster performance.',
    rawContent: '<p>lackluster adj. 无光泽的, 毫无生气的, 暗淡无光的</p>',
  ),
  WordEntry(
    id: 'nurture',
    word: 'nurture',
    pronunciation: '/ˈnɜːrtʃər/',
    partOfSpeech: 'v.',
    definition: '培养, 培育, 促进',
    exampleSentence: 'Great teachers nurture curiosity.',
    rawContent: '<p>nurture v. 培养, 培育, 促进</p>',
  ),
  WordEntry(
    id: 'notion',
    word: 'notion',
    pronunciation: '/ˈnoʊʃən/',
    partOfSpeech: 'n.',
    definition: '概念, 想法, 观念',
    exampleSentence: 'She rejected the notion that talent is fixed.',
    rawContent: '<p>notion n. 概念, 想法, 观念</p>',
  ),
  WordEntry(
    id: 'notable',
    word: 'notable',
    pronunciation: '/ˈnoʊtəbəl/',
    partOfSpeech: 'adj.',
    definition: '值得注意的, 显著的',
    exampleSentence: 'The city saw notable growth last year.',
    rawContent: '<p>notable adj. 值得注意的, 显著的</p>',
  ),
];
