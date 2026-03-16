import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/home/presentation/home_dashboard_page.dart';

void main() {
  testWidgets('home dashboard uses tighter top controls and compact hero copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardPage(
            onOpenMe: () {},
            onOpenSearch: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hi，我是你的AI\n口语教练。'), findsOneWidget);
    expect(find.text('现在就开始你的口语\n练习吧！'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const ValueKey('open-me-page'))).height,
      50,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('open-search-page'))).height,
      46,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home-coach-card'))).height,
      lessThan(150),
    );
  });
}
