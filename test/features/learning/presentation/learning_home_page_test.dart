import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/learning/presentation/learning_home_page.dart';

void main() {
  testWidgets('learning home renders article sections', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LearningHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Saving Elephants'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Explore by Category'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Explore by Category'), findsOneWidget);
  });
}
