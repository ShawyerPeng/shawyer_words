import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/learning/presentation/learning_home_page.dart';

void main() {
  testWidgets('tapping article opens reading page with content', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LearningHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('popular-elephants')));
    await tester.pumpAndSettle();

    expect(find.text('Saving Elephants'), findsWidgets);
    expect(find.text('Aug 20, 2021'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(
      find.textContaining('Around 28,000 elephants die every year'),
      findsOneWidget,
    );
  });
}
