import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/presentation/help_center_page.dart';

void main() {
  testWidgets('renders help center faq and keeps all items collapsed by default', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpCenterPage()));
    await tester.pumpAndSettle();

    expect(find.text('帮助中心'), findsOneWidget);
    expect(find.text('常见问题'), findsOneWidget);
    expect(find.text('一个账号可支持几台设备同时使用？'), findsOneWidget);
    expect(
      find.text('一个账号支持同时在多台移动端设备（手机、平板电脑等）上登录，还支持在网页端同时使用。'),
      findsNothing,
    );

    await tester.tap(find.text('一个账号可支持几台设备同时使用？'));
    await tester.pumpAndSettle();

    expect(
      find.text('一个账号支持同时在多台移动端设备（手机、平板电脑等）上登录，还支持在网页端同时使用。'),
      findsOneWidget,
    );
  });
}
