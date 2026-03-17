import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

void main() {
  testWidgets('renders action bar, ordered sections, and collapsed dictionary panel', (
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('标熟'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-detail-favorite')), findsOneWidget);
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
  });

  testWidgets('renders imported dictionary panel html content when expanded', (
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
              rawContent:
                  '<div>Line 1</div><div><b>Line 2</b><br/>Line 3</div>',
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Collins'));
    await tester.pump();

    await tester.tap(find.text('Collins'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Line 1'), findsOneWidget);
    expect(find.textContaining('Line 2'), findsOneWidget);
    expect(find.textContaining('Line 3'), findsOneWidget);
    expect(find.textContaining('<div>'), findsNothing);
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
        home: WordDetailPage(
          word: 'abandon',
          controller: controller,
        ),
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
  final Map<String, WordKnowledgeRecord> _records = <String, WordKnowledgeRecord>{};

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
