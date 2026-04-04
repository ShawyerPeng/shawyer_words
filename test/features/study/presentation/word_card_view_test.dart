import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/presentation/word_card_view.dart';

void main() {
  testWidgets('falls back to raw content when structured fields are missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WordCardView(
            entry: WordEntry(
              id: '1',
              word: 'abandon',
              rawContent: '<div>fallback dictionary content</div>',
            ),
            definitionVisible: false,
            onRevealDefinition: _noop,
            onOpenDetail: _noop,
          ),
        ),
      ),
    );

    expect(find.text('<div>fallback dictionary content</div>'), findsOneWidget);
  });

  testWidgets('shows detail action after definition is revealed', (
    tester,
  ) async {
    var openedDetail = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordCardView(
            entry: const WordEntry(
              id: '2',
              word: 'brisk',
              definition: 'quick and energetic',
              rawContent: '<div>brisk</div>',
            ),
            definitionVisible: true,
            onRevealDefinition: _noop,
            onOpenDetail: () => openedDetail = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('查看完整释义'));
    await tester.pumpAndSettle();

    expect(openedDetail, isTrue);
  });

  testWidgets('shows detail action even when definition text is missing', (
    tester,
  ) async {
    var openedDetail = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordCardView(
            entry: const WordEntry(
              id: '3',
              word: 'abandon',
              definition: '',
              rawContent: '<p>abandon</p>',
            ),
            definitionVisible: true,
            onRevealDefinition: _noop,
            onOpenDetail: () => openedDetail = true,
          ),
        ),
      ),
    );

    expect(find.text('该词条暂无内置释义'), findsOneWidget);
    expect(find.text('查看完整释义'), findsOneWidget);

    await tester.tap(find.text('查看完整释义'));
    await tester.pumpAndSettle();

    expect(openedDetail, isTrue);
  });
}

void _noop() {}
