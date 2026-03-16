import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';
import 'package:shawyer_words/features/me/presentation/me_page.dart';

void main() {
  testWidgets('shows dictionary library management under general settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MePage(
          dictionaryLibraryManagementPageBuilder: _buildManagementPage,
        ),
      ),
    );

    expect(find.text('通用设置'), findsOneWidget);
    expect(find.text('词典库管理'), findsOneWidget);

    await tester.tap(find.text('词典库管理'));
    await tester.pumpAndSettle();

    expect(find.text('所有词典库'), findsOneWidget);
  });
}

Widget _buildManagementPage(BuildContext context) {
  return const DictionaryLibraryManagementPage(
    controller: null,
  );
}
