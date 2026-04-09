import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study_plan/application/lexdb_study_entry_enricher.dart';
import 'package:shawyer_words/features/word_detail/data/lexdb_word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';
import 'package:sqflite/sqlite_api.dart';

void main() {
  test(
    'enriches missing fields from lexdb and keeps existing values',
    () async {
      final enricher = LexDbStudyEntryEnricher(
        repository: _FakeLexDbWordDetailRepository(
          detailsByWord: <String, List<LexDbEntryDetail>>{
            'abandon': const <LexDbEntryDetail>[
              LexDbEntryDetail(
                dictionaryId: 'lexdb',
                dictionaryName: 'LexDB',
                headword: 'abandon',
                pronunciations: <LexDbPronunciation>[
                  LexDbPronunciation(variant: 'us', phonetic: '/əˈbændən/'),
                ],
                senses: <LexDbSense>[
                  LexDbSense(
                    id: 1,
                    definition: 'to leave behind',
                    definitionZh: '放弃；离弃',
                    examplesBeforePatterns: <LexDbExample>[
                      LexDbExample(
                        text: 'They abandon the plan at sunrise.',
                        audioPath: '/media/english/examples/abandon.mp3',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          },
        ),
      );

      final entries = await enricher.enrichEntries(const <WordEntry>[
        WordEntry(id: '1', word: 'abandon', rawContent: '<p>abandon</p>'),
        WordEntry(
          id: '2',
          word: 'keep',
          pronunciation: '/kiːp/',
          definition: '保留',
          exampleSentence: 'Keep moving.',
          rawContent: '<p>keep</p>',
        ),
      ]);

      expect(entries.first.pronunciation, '/əˈbændən/');
      expect(entries.first.definition, '放弃；离弃');
      expect(
        entries.first.exampleSentence,
        'They abandon the plan at sunrise.',
      );
      expect(
        entries.first.exampleAudioPath,
        '/media/english/examples/abandon.mp3',
      );
      expect(entries[1].pronunciation, '/kiːp/');
      expect(entries[1].definition, '保留');
      expect(entries[1].exampleSentence, 'Keep moving.');
    },
  );
}

class _FakeLexDbWordDetailRepository extends LexDbWordDetailRepository {
  _FakeLexDbWordDetailRepository({required this.detailsByWord})
    : super(
        databasePath: '/tmp/fake-lexdb.db',
        dictionaryId: 'lexdb',
        dictionaryName: 'LexDB',
        databaseFactory: _UnusedDatabaseFactory(),
      );

  final Map<String, List<LexDbEntryDetail>> detailsByWord;

  @override
  Future<List<LexDbEntryDetail>> lookup(String word) async {
    return detailsByWord[word.trim().toLowerCase()] ??
        const <LexDbEntryDetail>[];
  }
}

class _UnusedDatabaseFactory implements DatabaseFactory {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
