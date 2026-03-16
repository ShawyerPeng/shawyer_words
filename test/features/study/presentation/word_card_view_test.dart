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
}

void _noop() {}
