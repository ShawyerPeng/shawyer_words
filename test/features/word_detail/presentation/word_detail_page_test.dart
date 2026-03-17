import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_player.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_document.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

void main() {
  testWidgets(
    'renders action bar, ordered sections, and collapsed dictionary panel',
    (tester) async {
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
          home: WordDetailPage(word: 'abandon', controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('标熟'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('word-detail-favorite')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('word-detail-note')), findsOneWidget);
      expect(find.byKey(const ValueKey('word-detail-options')), findsOneWidget);

      expect(find.text('基本'), findsOneWidget);
      expect(find.text('释义'), findsOneWidget);
      expect(find.text('例句'), findsOneWidget);
      expect(find.text('相关词'), findsOneWidget);
      expect(find.text('单词图谱'), findsOneWidget);
      expect(find.text('扩展'), findsOneWidget);
      expect(find.text('笔记'), findsOneWidget);
      expect(find.text('词典'), findsOneWidget);
      expect(find.text('原始词典内容'), findsNothing);
      expect(find.text('添加你的学习笔记'), findsOneWidget);
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

      await tester.ensureVisible(find.text('Collins'));
      await tester.pump();

      await tester.tap(find.text('Collins'));
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

    await tester.tap(find.text('Collins'));
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

    await tester.tap(find.text('Collins'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Collins'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('play-sound'));
    await tester.pumpAndSettle();

    expect(soundRepository.lastSoundUrl, 'sound://example.mp3');
    expect(soundRepository.lastPanel?.dictionaryId, 'collins');
    expect(soundPlayer.playedPaths, hasLength(1));
    expect(find.textContaining('detail:'), findsNothing);
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

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  final Map<String, WordKnowledgeRecord> _records =
      <String, WordKnowledgeRecord>{};

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async {
    return _records[WordKnowledgeRecord.normalizeWord(word)];
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
    await file.writeAsBytes(const <int>[1, 2, 3], flush: true);
    return file;
  }
}

class _FakeDictionarySoundPlayer extends DictionarySoundPlayer {
  _FakeDictionarySoundPlayer() : super();

  final List<String> playedPaths = <String>[];

  @override
  Future<void> playFile(File file) async {
    playedPaths.add(file.path);
  }

  @override
  Future<void> dispose() async {}
}
