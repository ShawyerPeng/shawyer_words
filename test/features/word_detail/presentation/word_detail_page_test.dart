import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_player.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_document.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

void main() {
  testWidgets('renders gradient header and collapsed dictionary panel', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: WordDetail(
          word: 'abandon',
          basic: const WordBasicSummary(
            headword: 'abandon',
            pronunciationUs: '/əˈbændən/',
            pronunciationUk: '/əˈbændən/',
            frequency: 'CET4',
          ),
          definitions: const <WordSense>[
            WordSense(partOfSpeech: 'verb', definitionZh: '放弃'),
          ],
          examples: const <WordExample>[
            WordExample(
              english: 'They abandon the plan at sunrise.',
              translationZh: '他们在日出时放弃了计划。',
            ),
          ],
          dictionaryPanels: const <DictionaryEntryDetail>[
            DictionaryEntryDetail(
              dictionaryId: 'eng-zh',
              dictionaryName: '英汉词典',
              word: 'abandon',
              rawContent: '原始词典内容',
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          dictionaryHtmlViewBuilder: (panel, onEntryLinkTap, onSoundLinkTap) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('word-detail-search-shell')),
      findsOneWidget,
    );
    expect(find.text('取消'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-detail-favorite')), findsOneWidget);
    expect(find.text('词频 CET4'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-detail-options')), findsOneWidget);

    expect(find.text('原声例句'), findsNothing);
    await _scrollUntilVisible(tester, find.text('词典'));
    expect(find.text('词典'), findsOneWidget);
    expect(find.text('原始词典内容'), findsNothing);
  });

  testWidgets('hides top gradient background after scrolling down', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: WordDetail(
          word: 'absorb',
          lexDbEntries: List<LexDbEntryDetail>.generate(1, (_) {
            return LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'absorb',
              senses: List<LexDbSense>.generate(24, (index) {
                return LexDbSense(
                  id: index + 1,
                  number: '${index + 1}',
                  definition: 'definition ${index + 1}',
                  definitionZh: '释义${index + 1}',
                );
              }),
            );
          }),
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'absorb', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final before = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('word-detail-top-gradient')),
    );
    expect(before.opacity, 1);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    final after = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('word-detail-top-gradient')),
    );
    expect(after.opacity, 0);
  });

  testWidgets('prefers lexdb frequency attributes over fallback frequency', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'absorb',
          basic: WordBasicSummary(frequency: 'CET4'),
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'absorb',
              entryAttributes: <String, String>{
                'ldoce/frequency': 'S3 W2',
                'ldoce/frequency-dots': '●●●●○',
              },
              senses: <LexDbSense>[LexDbSense(id: 1, definition: 'to take in')],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'absorb', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('词频 ●●●●○'), findsOneWidget);
    expect(find.text('词频 CET4'), findsNothing);
  });

  testWidgets('renders TLD definition panel at top of definition section', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abnormal',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abnormal',
              entryAttributes: <String, String>{
                'tld/exam_tags': '["CET4","CET6"]',
                'tld/difficulty_level': '2',
                'tld/coca':
                    '[{"pos":"v","rank":3139,"total":10484,"distribution":{"spoken":1920,"fiction":1666,"magazine":1895,"newspaper":1982,"academic":3021}}]',
                'tld/iweb': '[{"pos":"VERB","rank":3213,"total":361238}]',
                'tld/spoken_rank':
                    '{"rank":3857,"total":7255,"lemmas":[{"form":"absorbed","count":2685},{"form":"absorbing","count":1742}]}',
                'tld/sense_ratio_cn':
                    '[{"meaning":"不正常的","percent":56},{"meaning":"反常的","percent":26},{"meaning":"变态的","percent":13},{"meaning":"不正常的人","percent":5}]',
              },
              senses: <LexDbSense>[LexDbSense(id: 1, definition: 'not normal')],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abnormal', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CET4'), findsOneWidget);
    expect(find.text('CET6'), findsOneWidget);
    expect(find.textContaining('Level: ⭐⭐'), findsOneWidget);
    expect(find.text('词频排名'), findsOneWidget);
    expect(find.textContaining('COCA: #3139'), findsOneWidget);
    expect(find.textContaining('iWeb: #3213'), findsOneWidget);
    expect(find.textContaining('口语: #3857'), findsOneWidget);
    expect(find.text('分布统计'), findsOneWidget);
    expect(find.text('词义分布'), findsNothing);
    expect(find.text('词性分布'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tld-distribution-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('词义分布'), findsOneWidget);
    expect(find.text('词性分布'), findsOneWidget);
    expect(find.textContaining('不正常的 56%'), findsOneWidget);
    expect(find.textContaining('动词 100%'), findsOneWidget);
  });

  testWidgets(
    'shows dedicated loading view on initial load instead of empty placeholders',
    (tester) async {
      final controller = WordDetailController(
        detailRepository: _DelayedWordDetailRepository(
          detail: const WordDetail(word: 'absorb'),
        ),
        knowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailPage(word: 'absorb', controller: controller),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const ValueKey('word-detail-loading')), findsOneWidget);
      expect(find.text('当前词典还没有提供可解析的释义。'), findsNothing);
      expect(find.text('当前没有可展示的词典结果。'), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'renders imported dictionary panel with html renderer when expanded',
    (tester) async {
      late DictionaryHtmlDocument capturedDocument;
      final controller = WordDetailController(
        detailRepository: _FakeWordDetailRepository(
          detail: WordDetail(
            word: 'abandon',
            dictionaryPanels: const <DictionaryEntryDetail>[
              DictionaryEntryDetail(
                dictionaryId: 'collins',
                dictionaryName: 'Collins',
                word: 'abandon',
                rawContent: '<div class="entry">Line 1</div>',
                resourcesPath: '/tmp/dictionaries/collins/resources',
                stylesheetPaths: <String>[
                  '/tmp/dictionaries/collins/resources/theme.css',
                ],
                scriptPaths: <String>[
                  '/tmp/dictionaries/collins/resources/theme.js',
                ],
              ),
            ],
          ),
        ),
        knowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailPage(
            word: 'abandon',
            controller: controller,
            dictionaryHtmlViewBuilder: (panel, onEntryLinkTap, onSoundLinkTap) {
              capturedDocument = buildDictionaryHtmlDocument(panel);
              return const SizedBox(
                key: ValueKey('dictionary-html-renderer'),
                height: 120,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(tester, find.textContaining('Collins'));
      await tester.tap(find.textContaining('Collins'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('dictionary-html-renderer')),
        findsOneWidget,
      );
      expect(
        capturedDocument.html,
        contains('<div class="entry">Line 1</div>'),
      );
      expect(capturedDocument.html, contains('theme.css'));
      expect(capturedDocument.html, contains('theme.js'));
    },
  );

  testWidgets('renders structured lexdb sections when present', (tester) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              headwordDisplay: 'a·ban·don',
              pronunciations: <LexDbPronunciation>[
                LexDbPronunciation(variant: 'uk', phonetic: '/əˈbændən/'),
              ],
              senses: <LexDbSense>[
                LexDbSense(
                  id: 1,
                  number: '1',
                  signpost: 'LEAVE',
                  definition: 'to leave a place, thing, or person',
                  definitionZh: '离弃；抛弃',
                  labels: <LexDbLabel>[
                    LexDbLabel(type: 'pos', value: 'verb'),
                    LexDbLabel(type: 'register', value: 'formal'),
                    LexDbLabel(type: 'geo', value: 'British English'),
                    LexDbLabel(type: 'domain', value: 'legal'),
                  ],
                  examplesBeforePatterns: <LexDbExample>[
                    LexDbExample(
                      text: 'He abandoned the car.',
                      textZh: '他弃车而去。',
                    ),
                  ],
                ),
              ],
              collocations: <LexDbCollocation>[
                LexDbCollocation(
                  collocate: 'abandon hope',
                  grammar: 'VERBS',
                  definition: 'to stop hoping completely',
                  examples: <LexDbExample>[
                    LexDbExample(text: 'The doctors never abandoned hope.'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abandon', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Longman'), findsNothing);
    expect(find.textContaining('/əˈbændən/'), findsWidgets);
    expect(find.text('1 LEAVE'), findsOneWidget);
    expect(find.text('to leave a place, thing, or person'), findsOneWidget);
    expect(find.text('离弃；抛弃'), findsOneWidget);
    expect(find.text('词性 verb'), findsOneWidget);
    expect(find.text('语域 formal'), findsOneWidget);
    expect(find.text('地域 British English'), findsOneWidget);
    expect(find.text('领域 legal'), findsOneWidget);
    expect(find.textContaining('He abandoned the car.'), findsOneWidget);
    expect(find.text('他弃车而去。'), findsWidgets);
    expect(find.text('abandon hope'), findsWidgets);
    expect(find.text('to stop hoping completely'), findsWidgets);
    expect(
      find.textContaining('The doctors never abandoned hope.'),
      findsOneWidget,
    );
  });

  testWidgets('switches between multiple lexdb entries with pos tabs', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'last',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb-1',
              dictionaryName: 'Longman',
              headword: 'last',
              entryLabels: <LexDbLabel>[
                LexDbLabel(type: 'pos', value: 'determiner'),
              ],
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'det definition only'),
              ],
            ),
            LexDbEntryDetail(
              dictionaryId: 'lexdb-2',
              dictionaryName: 'Longman',
              headword: 'last',
              entryLabels: <LexDbLabel>[LexDbLabel(type: 'pos', value: 'verb')],
              senses: <LexDbSense>[
                LexDbSense(id: 2, definition: 'verb definition only'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'last', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lexdb-entry-tab-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('lexdb-entry-tab-1')), findsOneWidget);
    expect(find.text('det.'), findsOneWidget);
    expect(find.text('verb'), findsOneWidget);

    expect(find.text('det definition only'), findsOneWidget);
    expect(find.text('verb definition only'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('lexdb-entry-tab-1')));
    await tester.pumpAndSettle();

    expect(find.text('det definition only'), findsNothing);
    expect(find.text('verb definition only'), findsOneWidget);
  });

  testWidgets('renders sense meta tags from entry-level labels as fallback', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              entryLabels: <LexDbLabel>[
                LexDbLabel(type: 'pos', value: 'verb'),
                LexDbLabel(type: 'register', value: 'formal'),
                LexDbLabel(type: 'geo', value: 'American English'),
                LexDbLabel(type: 'domain', value: 'computing'),
              ],
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'to leave a place'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abandon', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('词性 verb'), findsOneWidget);
    expect(find.text('语域 formal'), findsOneWidget);
    expect(find.text('地域 American English'), findsOneWidget);
    expect(find.text('领域 computing'), findsOneWidget);
  });

  testWidgets('builds inflection rows from ldoce/inflections and supports jump', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              entryAttributes: <String, String>{
                'ldoce/inflections':
                    '{"plural":"abandons","third_person_singular":"abandons","past":"abandoned","past_participle":"abandoned","present_participle":"abandoning"}',
              },
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'to leave someone'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              Scaffold(body: Text('detail:$word')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('词形变化'), findsWidgets);
    expect(find.text('复数'), findsOneWidget);
    expect(find.text('第三人称单数'), findsOneWidget);
    expect(find.text('过去式'), findsOneWidget);
    expect(find.text('过去分词'), findsOneWidget);
    expect(find.text('现在分词'), findsOneWidget);
    expect(find.text('abandoned'), findsWidgets);
    expect(find.text('abandoning'), findsOneWidget);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('inflection-pastParticiple-abandoned')),
    );
    await tester.tap(
      find.byKey(const ValueKey('inflection-pastParticiple-abandoned')),
    );
    await tester.pumpAndSettle();
    expect(find.text('detail:abandoned'), findsOneWidget);
  });

  testWidgets(
    'renders related module with synonym antonym inflection and family',
    (tester) async {
      final controller = WordDetailController(
        detailRepository: _FakeWordDetailRepository(
          detail: WordDetail(
            word: 'abandon',
            lexDbEntries: <LexDbEntryDetail>[
              LexDbEntryDetail(
                dictionaryId: 'lexdb',
                dictionaryName: 'Longman',
                headword: 'abandon',
                relations: <LexDbRelation>[
                  LexDbRelation(
                    relationType: 'synonym',
                    clickable: '1',
                    targetWord: 'forsake',
                  ),
                  LexDbRelation(
                    relationType: 'antonym',
                    clickable: '1',
                    targetWord: 'keep',
                  ),
                ],
                entryAttributes: <String, String>{
                  'ldoce/inflections':
                      '{"past":"abandoned","present_participle":"abandoning"}',
                  'ldoce/thesaurus': jsonEncode([
                    {
                      'header': 'THESAURUS',
                      'items': [
                        {
                          'word': 'thing',
                          'definition':
                              'used when you do not need to say the name',
                          'definition_cn': '东西〔用于不必说出名称或不知其名时〕',
                          'examples': [
                            {
                              'text': "What's that thing on the kitchen table?",
                              'text_cn': '厨房桌子上那东西是什么？',
                            },
                          ],
                        },
                      ],
                    },
                  ]),
                  'ldoce/word_family':
                      '[{"word":"abandonment"},{"word":"abandoned"}]',
                },
                senses: <LexDbSense>[
                  LexDbSense(id: 1, definition: 'to leave someone'),
                ],
              ),
            ],
          ),
        ),
        knowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailPage(
            word: 'abandon',
            controller: controller,
            wordDetailPageBuilder: (word, initialEntry) =>
                Scaffold(body: Text('detail:$word')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('相关词'), findsWidgets);
      expect(find.text('同义词'), findsOneWidget);
      expect(find.text('反义词'), findsOneWidget);
      expect(find.text('词形变化'), findsWidgets);
      expect(find.text('词族'), findsOneWidget);
      expect(find.text('forsake'), findsOneWidget);
      expect(find.text('keep'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('related-synonyms-inline')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('related-antonyms-inline')),
        findsOneWidget,
      );
      expect(
        find.textContaining('used when you do not need to say the name'),
        findsOneWidget,
      );
      expect(find.textContaining('东西〔用于不必说出名称或不知其名时〕'), findsOneWidget);
      expect(
        find.textContaining("What's that thing on the kitchen table?"),
        findsOneWidget,
      );
      expect(find.textContaining('厨房桌子上那东西是什么？'), findsOneWidget);
      expect(find.text('abandoned'), findsWidgets);
      expect(find.text('abandoning'), findsOneWidget);
      expect(find.text('abandonment'), findsOneWidget);

      await tester.tap(find.text('forsake'));
      await tester.pumpAndSettle();
      expect(find.text('detail:forsake'), findsOneWidget);
    },
  );

  testWidgets('renders similar spelling and similar sound in related section', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'jaunt',
          similarSpellingWords: <String>['daunt', 'gaunt', 'haunt', 'taunt'],
          similarSoundWords: <String>['flaunt', 'saunter'],
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'jaunt',
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'a short journey'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'jaunt', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('相关词'), findsWidgets);
    expect(find.text('形近词'), findsOneWidget);
    expect(find.text('音近词'), findsOneWidget);
    expect(find.text('daunt'), findsOneWidget);
    expect(find.text('gaunt'), findsOneWidget);
    expect(find.text('flaunt'), findsOneWidget);
    expect(find.text('saunter'), findsOneWidget);
  });

  testWidgets('decodes encoded phrase in synonym and antonym relations', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              relations: <LexDbRelation>[
                LexDbRelation(
                  relationType: 'synonym',
                  clickable: '1',
                  targetWord: 'give%20up',
                ),
                LexDbRelation(
                  relationType: 'antonym',
                  clickable: '1',
                  targetWord: 'hold+on',
                ),
              ],
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'to leave someone'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              Scaffold(body: Text('detail:$word')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('give up'), findsOneWidget);
    expect(find.text('hold on'), findsOneWidget);
    expect(find.text('give%20up'), findsNothing);
    expect(find.text('hold+on'), findsNothing);

    await tester.tap(find.text('give up'));
    await tester.pumpAndSettle();
    expect(find.text('detail:give up'), findsOneWidget);
  });

  testWidgets(
    'phrase module reads ldoce/phrasal-verbs instead of collocations',
    (tester) async {
      final controller = WordDetailController(
        detailRepository: _FakeWordDetailRepository(
          detail: const WordDetail(
            word: 'take',
            lexDbEntries: <LexDbEntryDetail>[
              LexDbEntryDetail(
                dictionaryId: 'lexdb',
                dictionaryName: 'Longman',
                headword: 'take',
                entryAttributes: <String, String>{
                  'ldoce/phrasal-verbs':
                      '[{"phrasal_verb":"take off","definition":"起飞; 脱下"}]',
                },
                collocations: <LexDbCollocation>[
                  LexDbCollocation(
                    collocate: 'collocation only',
                    definition: '搭配释义',
                  ),
                ],
                senses: <LexDbSense>[
                  LexDbSense(id: 1, definition: 'to get hold of'),
                ],
              ),
            ],
          ),
        ),
        knowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailPage(word: 'take', controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('短语'), findsWidgets);
      expect(find.textContaining('take off'), findsWidgets);
      expect(find.text('起飞; 脱下'), findsOneWidget);
    },
  );

  testWidgets('phrase module extracts nested definitions from phrasal-verbs', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'take',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'take',
              entryAttributes: <String, String>{
                'ldoce/phrasal-verbs':
                    '[{"phrasal_verb":"take in","definitions":[{"definition":"to understand"},{"definition_zh":"理解"}]}]',
              },
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'to get hold of'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'take', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('take in'), findsWidgets);
    expect(find.text('to understand；理解'), findsOneWidget);
  });

  testWidgets('parses word_family groups json structure', (tester) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'take',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'take',
              entryAttributes: <String, String>{
                'ldoce/word_family':
                    '[{"header":"Word family","groups":[{"pos":"noun","words":["takings","undertaking","take","taker"]},{"pos":"verb","words":["take","overtake","undertake"]}]}]',
              },
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'to get hold of'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'take', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('词族'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    expect(find.text('verb'), findsOneWidget);
    expect(find.text('takings'), findsOneWidget);
    expect(find.text('undertaking'), findsOneWidget);
    expect(find.text('take'), findsWidgets);
    expect(find.text('taker'), findsOneWidget);
    expect(find.text('overtake'), findsOneWidget);
    expect(find.text('undertake'), findsOneWidget);
  });

  testWidgets('word family tree supports tap to show brief chinese meaning', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'take',
          wordFamilyBriefDefinitions: <String, String>{'undertaking': '事业；任务'},
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'take',
              entryAttributes: <String, String>{
                'ldoce/word_family':
                    '[{"header":"Word family","groups":[{"pos":"noun","words":["take","undertaking"]}]}]',
              },
              senses: <LexDbSense>[
                LexDbSense(id: 1, definition: 'to get hold of'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'take', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final nodeKey = find.byKey(
      const ValueKey('word-family-node-0:undertaking'),
    );
    expect(nodeKey, findsOneWidget);

    await tester.tap(nodeKey);
    await tester.pumpAndSettle();

    expect(find.text('事业；任务'), findsOneWidget);

    final textFinder = find.descendant(
      of: nodeKey,
      matching: find.byType(Text),
    );
    final targetText = tester
        .widgetList<Text>(textFinder)
        .firstWhere((widget) => widget.data == null && widget.textSpan != null);
    final rootSpan = targetText.textSpan!;
    expect(rootSpan.toPlainText(), 'undertaking');
    expect(_containsWordFamilyHighlight(rootSpan), isTrue);
  });

  testWidgets('parses coded inflections json and keeps required order', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'good',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'good',
              entryAttributes: <String, String>{
                'ldoce/inflections':
                    '[{"type":"PLURAL","forms":["goods"]},{"type":"TPS","forms":["goods"]},{"type":"PT","forms":["gooded"]},{"type":"PP","forms":["gooded"]},{"type":"PTnPP","forms":["bettered"]},{"type":"PRE","forms":["gooding"]},{"type":"ADV","forms":["well"]},{"type":"POSS","forms":["good\'s"]},{"type":"COMPAR","forms":["better"]},{"type":"SUPERL","forms":["best"]}]',
              },
              senses: <LexDbSense>[LexDbSense(id: 1, definition: 'well')],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'good', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final pluralY = tester.getTopLeft(find.text('复数')).dy;
    final thirdSingularY = tester.getTopLeft(find.text('第三人称单数')).dy;
    final pastY = tester.getTopLeft(find.text('过去式')).dy;
    final pastParticipleY = tester.getTopLeft(find.text('过去分词')).dy;
    final presentParticipleY = tester.getTopLeft(find.text('现在分词')).dy;
    final adverbY = tester.getTopLeft(find.text('副词')).dy;
    final possessiveY = tester.getTopLeft(find.text('所有格')).dy;
    final comparativeY = tester.getTopLeft(find.text('比较级')).dy;
    final superlativeY = tester.getTopLeft(find.text('最高级')).dy;
    expect(pluralY, lessThan(thirdSingularY));
    expect(thirdSingularY, lessThan(pastY));
    expect(pastY, lessThan(pastParticipleY));
    expect(pastParticipleY, lessThan(presentParticipleY));
    expect(presentParticipleY, lessThan(adverbY));
    expect(adverbY, lessThan(possessiveY));
    expect(possessiveY, lessThan(comparativeY));
    expect(comparativeY, lessThan(superlativeY));
    expect(find.text('goods'), findsWidgets);
    expect(find.text('gooded'), findsWidgets);
    expect(find.text('bettered'), findsWidgets);
    expect(find.text('gooding'), findsOneWidget);
    expect(find.text('well'), findsWidgets);
    expect(find.text("good's"), findsOneWidget);
    expect(find.text('better'), findsOneWidget);
    expect(find.text('best'), findsOneWidget);
  });

  testWidgets('renders example english+zh in one line and bolds matched word', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              senses: <LexDbSense>[
                LexDbSense(
                  id: 1,
                  definition: 'to leave',
                  examplesBeforePatterns: <LexDbExample>[
                    LexDbExample(
                      text: 'They abandon the plan.',
                      textZh: '他们放弃了计划。',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abandon', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final richText = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) {
          final text = widget.text.toPlainText();
          return text.contains('They abandon the plan.') &&
              text.contains('他们放弃了计划。');
        });
    final plainText = richText.text.toPlainText();
    expect(plainText, contains('They abandon the plan.'));
    expect(plainText, contains('他们放弃了计划。'));
    expect(plainText, isNot(contains('\n')));
    expect(_hasBoldSpanText(richText.text, 'abandon'), isTrue);
  });

  testWidgets('tapping header word toggles hyphenation display', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              headwordDisplay: 'a·ban·don',
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abandon', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hyphenation'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('word-detail-headword')));
    await tester.pumpAndSettle();

    expect(find.text('Hyphenation'), findsNothing);
    expect(find.text('a·ban·don'), findsOneWidget);
  });

  testWidgets(
    'tab content ignores mdx parsed definitions and uses lexdb only',
    (tester) async {
      final controller = WordDetailController(
        detailRepository: _FakeWordDetailRepository(
          detail: const WordDetail(
            word: 'abandon',
            definitions: <WordSense>[
              WordSense(partOfSpeech: 'verb', definitionZh: 'MDX定义不应展示'),
            ],
            examples: <WordExample>[
              WordExample(
                english: 'This MDX example should not appear.',
                translationZh: '这条MDX例句不应展示',
              ),
            ],
            lexDbEntries: <LexDbEntryDetail>[
              LexDbEntryDetail(
                dictionaryId: 'lexdb',
                dictionaryName: 'Longman',
                headword: 'abandon',
                senses: <LexDbSense>[
                  LexDbSense(
                    id: 1,
                    definition: 'lexdb definition visible',
                    definitionZh: 'LexDB释义应该展示',
                    examplesBeforePatterns: <LexDbExample>[
                      LexDbExample(
                        text: 'LexDB example visible',
                        textZh: 'LexDB例句应该展示',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        knowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailPage(word: 'abandon', controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MDX定义不应展示'), findsNothing);
      expect(find.text('This MDX example should not appear.'), findsNothing);
      expect(find.text('lexdb definition visible'), findsOneWidget);
      expect(find.text('LexDB释义应该展示'), findsOneWidget);
      expect(find.textContaining('LexDB example visible'), findsOneWidget);
      expect(find.text('LexDB例句应该展示'), findsWidgets);
    },
  );

  testWidgets('shows extended lexdb modules when data exists', (tester) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              entryLabels: <LexDbLabel>[
                LexDbLabel(type: 'mnemonic', value: 'ab+bandon => 放弃约束'),
                LexDbLabel(type: 'root_affix', value: 'ab- 离开'),
              ],
              entryAttributes: <String, String>{
                'ldoce/origin_century': 'Middle English',
                'ldoce/origin_language': 'Latin',
                'ldoce/origin_full':
                    'Middle English, from Latin abandonare and Old French abandoner.',
              },
              senses: <LexDbSense>[
                LexDbSense(
                  id: 1,
                  definition: 'to leave',
                  labels: <LexDbLabel>[
                    LexDbLabel(type: 'register', value: 'formal'),
                    LexDbLabel(type: 'word_form', value: 'abandoning'),
                  ],
                  grammarPatterns: <LexDbGrammarPattern>[
                    LexDbGrammarPattern(pattern: 'abandon + noun'),
                  ],
                ),
              ],
              collocations: <LexDbCollocation>[
                LexDbCollocation(collocate: 'abandon ship', grammar: 'idiom'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abandon', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('词汇助记'), findsWidgets);
    expect(find.text('语域'), findsWidgets);
    expect(find.text('语法行为'), findsWidgets);
    expect(find.text('习语'), findsWidgets);
    expect(find.text('词根词缀'), findsWidgets);
    expect(find.text('词源'), findsWidgets);
    expect(find.text('formal'), findsOneWidget);
    expect(find.text('abandon + noun'), findsWidgets);
    expect(find.text('abandon ship'), findsWidgets);
    expect(find.text('ab+bandon => 放弃约束'), findsOneWidget);
    expect(find.text('ab- 离开'), findsOneWidget);
    expect(find.text('年代 Middle English'), findsOneWidget);
    expect(find.text('语源 Latin'), findsOneWidget);
    expect(
      _findRichTextContaining(
        tester,
        'from Latin abandonare and Old French abandoner',
      ),
      isTrue,
    );
  });

  testWidgets(
    'tapping a tab scrolls to corresponding section instead of switching page',
    (tester) async {
      final controller = WordDetailController(
        detailRepository: _FakeWordDetailRepository(
          detail: WordDetail(
            word: 'absorb',
            lexDbEntries: List<LexDbEntryDetail>.generate(1, (entryIndex) {
              return LexDbEntryDetail(
                dictionaryId: 'lexdb',
                dictionaryName: 'Longman',
                headword: 'absorb',
                senses: List<LexDbSense>.generate(20, (senseIndex) {
                  return LexDbSense(
                    id: senseIndex + 1,
                    definition:
                        'definition $senseIndex to make the page long enough for anchor scrolling',
                    definitionZh: '释义 $senseIndex',
                    examplesBeforePatterns: const <LexDbExample>[
                      LexDbExample(text: 'normal example text', textZh: '普通例句'),
                      LexDbExample(
                        text: 'audio example text',
                        textZh: '音频例句',
                        audioPath: '/tmp/fake-audio.mp3',
                      ),
                    ],
                  );
                }),
                collocations: List<LexDbCollocation>.generate(20, (
                  collocationIndex,
                ) {
                  return LexDbCollocation(
                    collocate: 'phrase $collocationIndex',
                    definition: '短语释义 $collocationIndex',
                    examples: const <LexDbExample>[
                      LexDbExample(text: 'phrase example', textZh: '短语例句'),
                    ],
                  );
                }),
              );
            }),
          ),
        ),
        knowledgeRepository: _FakeWordKnowledgeRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailPage(word: 'absorb', controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final scrollableState = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final initialOffset = scrollableState.position.pixels;

      await tester.tap(find.text('例句').first);
      await tester.pumpAndSettle();

      final movedOffset = scrollableState.position.pixels;
      expect(movedOffset, greaterThan(initialOffset));
    },
  );

  testWidgets('expands dictionary inline without immersive overlay', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: WordDetail(
          word: 'abandon',
          dictionaryPanels: const <DictionaryEntryDetail>[
            DictionaryEntryDetail(
              dictionaryId: 'collins',
              dictionaryName: 'Collins',
              word: 'abandon',
              rawContent: '<div class="entry">Line 1</div>',
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          dictionaryHtmlViewBuilder: (panel, onEntryLinkTap, onSoundLinkTap) {
            return Container(
              key: ValueKey('dictionary-html-renderer-${panel.dictionaryId}'),
              color: Colors.blue,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.textContaining('Collins'));
    await tester.tap(find.textContaining('Collins'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dictionary-html-renderer-collins')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('immersive-dictionary-view')),
      findsNothing,
    );
  });

  testWidgets('opens a new word detail page for entry scheme links', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: WordDetail(
          word: 'abandon',
          dictionaryPanels: const <DictionaryEntryDetail>[
            DictionaryEntryDetail(
              dictionaryId: 'collins',
              dictionaryName: 'Collins',
              word: 'abandon',
              rawContent: '<a href="entry://career">career</a>',
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          wordDetailPageBuilder: (word, initialEntry) =>
              Scaffold(body: Text('detail:$word')),
          dictionaryHtmlViewBuilder: (panel, onEntryLinkTap, onSoundLinkTap) {
            return TextButton(
              onPressed: () => onEntryLinkTap('career'),
              child: const Text('jump-entry'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Collins'));
    await tester.tap(find.text('Collins'));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('jump-entry'));
    await tester.tap(find.text('jump-entry'));
    await tester.pumpAndSettle();

    expect(find.text('detail:career'), findsOneWidget);
  });

  testWidgets('plays sound scheme links without navigating', (tester) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: WordDetail(
          word: 'abandon',
          dictionaryPanels: const <DictionaryEntryDetail>[
            DictionaryEntryDetail(
              dictionaryId: 'collins',
              dictionaryName: 'Collins',
              word: 'abandon',
              rawContent: '<a href="sound://example.mp3">play</a>',
              mddPaths: <String>['/tmp/collins.mdd'],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    final soundRepository = _FakeDictionarySoundRepository();
    final soundPlayer = _FakeDictionarySoundPlayer();

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          soundRepository: soundRepository,
          soundPlayer: soundPlayer,
          dictionaryHtmlViewBuilder: (panel, onEntryLinkTap, onSoundLinkTap) {
            return TextButton(
              onPressed: () => onSoundLinkTap('sound://example.mp3'),
              child: const Text('play-sound'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Collins'));
    await tester.tap(find.text('Collins'));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('play-sound'));
    await tester.tap(find.text('play-sound'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(soundRepository.lastSoundUrl, 'sound://example.mp3');
    expect(soundRepository.lastPanel?.dictionaryId, 'collins');
    expect(soundPlayer.playedPaths, hasLength(1));
    expect(find.textContaining('detail:'), findsNothing);
  });

  testWidgets('shows online dictionaries after custom dictionary panels', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: WordDetail(
          word: 'absorb',
          dictionaryPanels: const <DictionaryEntryDetail>[
            DictionaryEntryDetail(
              dictionaryId: 'collins',
              dictionaryName: 'Collins',
              word: 'absorb',
              rawContent: '<div>content</div>',
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'absorb',
          controller: controller,
          dictionaryHtmlViewBuilder: (panel, onEntryLinkTap, onSoundLinkTap) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('在线词典'));
    expect(find.text('在线词典'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('online-dictionary-logo-maimemo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('online-dictionary-logo-iciba')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('online-dictionary-logo-youdao')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('online-dictionary-logo-haici')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('online-dictionary-logo-bing')),
      findsOneWidget,
    );

    final customDictionaryY = tester
        .getTopLeft(find.textContaining('Collins'))
        .dy;
    final onlineDictionaryY = tester.getTopLeft(find.text('在线词典')).dy;
    expect(onlineDictionaryY, greaterThan(customDictionaryY));
  });

  testWidgets('plays pronunciation badge audio from lexdb media path', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'abandon',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'abandon',
              pronunciations: <LexDbPronunciation>[
                LexDbPronunciation(
                  variant: 'uk',
                  phonetic: '/əˈbændən/',
                  audioPath: '/media/english/breProns/ld5_1.mp3',
                ),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    final soundPlayer = _FakeDictionarySoundPlayer();

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
          soundPlayer: soundPlayer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('word-detail-pronunciation-0')));
    await tester.pumpAndSettle();

    expect(
      soundPlayer.playedSources,
      contains('https://www.ldoceonline.com/media/english/breProns/ld5_1.mp3'),
    );
  });

  testWidgets('uses only first lexdb entry pronunciations', (tester) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(
          word: 'lead',
          lexDbEntries: <LexDbEntryDetail>[
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'lead',
              pronunciations: <LexDbPronunciation>[
                LexDbPronunciation(variant: 'uk', phonetic: '/liːd/'),
                LexDbPronunciation(variant: 'us', phonetic: '/lid/'),
              ],
            ),
            LexDbEntryDetail(
              dictionaryId: 'lexdb',
              dictionaryName: 'Longman',
              headword: 'lead',
              pronunciations: <LexDbPronunciation>[
                LexDbPronunciation(variant: 'uk', phonetic: '/lɛd/'),
                LexDbPronunciation(variant: 'us', phonetic: '/lɛd/'),
              ],
            ),
          ],
        ),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'lead', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('word-detail-pronunciation-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('word-detail-pronunciation-1')),
      findsOneWidget,
    );
    expect(find.text('/liːd/'), findsOneWidget);
    expect(find.text('/lid/'), findsOneWidget);
    expect(find.text('/lɛd/'), findsNothing);
  });

  testWidgets('supports favorite toggle and known confirmation sheet', (
    tester,
  ) async {
    final controller = WordDetailController(
      detailRepository: _FakeWordDetailRepository(
        detail: const WordDetail(word: 'abandon'),
      ),
      knowledgeRepository: _FakeWordKnowledgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WordDetailPage(word: 'abandon', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('☆'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('word-detail-favorite')));
    await tester.pumpAndSettle();

    expect(find.text('⭐'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('word-detail-options')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('标熟'));
    await tester.pumpAndSettle();

    expect(find.text('确定标熟吗？'), findsOneWidget);
    expect(find.text('标熟后该单词将不再安排学习和复习'), findsOneWidget);
    expect(find.text('下次不再提示'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(controller.state.knowledge?.isKnown, isTrue);
  });
}

class _FakeWordDetailRepository implements WordDetailRepository {
  _FakeWordDetailRepository({required this.detail});

  final WordDetail detail;

  @override
  Future<WordDetail> load(String word) async => detail;
}

class _DelayedWordDetailRepository implements WordDetailRepository {
  _DelayedWordDetailRepository({required this.detail});

  final WordDetail detail;

  @override
  Future<WordDetail> load(String word) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return detail;
  }
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  final Map<String, WordKnowledgeRecord> _records =
      <String, WordKnowledgeRecord>{};

  @override
  Future<void> clearAll() async {
    _records.clear();
  }

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async {
    return _records[WordKnowledgeRecord.normalizeWord(word)];
  }

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async {
    return _records.values.toList(growable: false);
  }

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    _records[current.word] = WordKnowledgeRecord(
      word: current.word,
      isFavorite: current.isFavorite,
      isKnown: true,
      note: current.note,
      skipKnownConfirm: skipConfirmNextTime,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> save(WordKnowledgeRecord record) async {
    _records[record.word] = record;
  }

  @override
  Future<void> saveNote(String word, String note) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    _records[current.word] = WordKnowledgeRecord(
      word: current.word,
      isFavorite: current.isFavorite,
      isKnown: current.isKnown,
      note: note,
      skipKnownConfirm: current.skipKnownConfirm,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> toggleFavorite(String word) async {
    final current = await getByWord(word) ?? WordKnowledgeRecord.initial(word);
    _records[current.word] = WordKnowledgeRecord(
      word: current.word,
      isFavorite: !current.isFavorite,
      isKnown: current.isKnown,
      note: current.note,
      skipKnownConfirm: current.skipKnownConfirm,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

class _FakeDictionarySoundRepository extends DictionarySoundRepository {
  _FakeDictionarySoundRepository()
    : super(tempDirectoryProvider: () => Directory.systemTemp);

  DictionaryEntryDetail? lastPanel;
  String? lastSoundUrl;

  @override
  Future<File?> materializeSoundFile({
    required DictionaryEntryDetail panel,
    required String soundUrl,
  }) async {
    lastPanel = panel;
    lastSoundUrl = soundUrl;
    final file = File(
      '${Directory.systemTemp.path}/fake-dict-sound-${DateTime.now().microsecondsSinceEpoch}.mp3',
    );
    file.writeAsBytesSync(const <int>[1, 2, 3], flush: true);
    return file;
  }
}

class _FakeDictionarySoundPlayer extends DictionarySoundPlayer {
  _FakeDictionarySoundPlayer() : super();

  final List<String> playedPaths = <String>[];
  final List<String> playedSources = <String>[];

  @override
  Future<void> playFile(File file) async {
    playedPaths.add(file.path);
  }

  @override
  Future<void> playSource(String source) async {
    playedSources.add(source);
  }

  @override
  Future<void> dispose() async {}
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

bool _hasBoldSpanText(InlineSpan root, String text) {
  if (root is TextSpan) {
    if ((root.text ?? '').toLowerCase() == text.toLowerCase() &&
        (root.style?.fontWeight == FontWeight.w700 ||
            root.style?.fontWeight == FontWeight.bold ||
            root.style?.fontWeight == FontWeight.w800)) {
      return true;
    }
    final children = root.children;
    if (children == null) {
      return false;
    }
    for (final child in children) {
      if (_hasBoldSpanText(child, text)) {
        return true;
      }
    }
  }
  return false;
}

bool _findRichTextContaining(WidgetTester tester, String target) {
  for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
    final plain = widget.text.toPlainText();
    if (plain.contains(target)) {
      return true;
    }
  }
  return false;
}

bool _containsWordFamilyHighlight(InlineSpan root) {
  if (root is TextSpan) {
    final color = root.style?.color;
    if (color == const Color(0xFF8AA9B4)) {
      return true;
    }
    final children = root.children;
    if (children == null) {
      return false;
    }
    for (final child in children) {
      if (_containsWordFamilyHighlight(child)) {
        return true;
      }
    }
  }
  return false;
}
