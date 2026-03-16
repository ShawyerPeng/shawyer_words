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
          ),
        ),
      ),
    );

    expect(find.text('<div>fallback dictionary content</div>'), findsOneWidget);
  });

  testWidgets('invokes onTap when the card is pressed', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordCardView(
            entry: const WordEntry(
              id: '2',
              word: 'brisk',
              rawContent: '<div>brisk</div>',
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('brisk'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
