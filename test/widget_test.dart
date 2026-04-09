import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/main.dart';

void main() {
  testWidgets('knowledge plaza and learning page are both reachable', (tester) async {
    await tester.pumpWidget(ShawyerWordsApp());
    await tester.pumpAndSettle();

    final studySearchBar = find.byKey(const ValueKey('study-open-search-page'));
    expect(studySearchBar, findsOneWidget);
    expect(find.text('知识库'), findsOneWidget);

    final studyRect = tester.getRect(studySearchBar);

    await tester.tap(studySearchBar);
    await tester.pumpAndSettle();

    final searchRect = tester.getRect(
      find.byKey(const ValueKey('search-page-search-bar')),
    );
    expect(searchRect.left, studyRect.left);
    expect(searchRect.top, studyRect.top);
    expect(searchRect.width, studyRect.width);
    expect(searchRect.height, studyRect.height);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    expect(find.text('学习广场'), findsOneWidget);

    await tester.tap(find.text('学习'));
    await tester.pumpAndSettle();

    expect(find.text('选择一个模块，进入你的专项练习。'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('open-grammar-page')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('open-grammar-page')));
    await tester.pumpAndSettle();

    expect(find.text('语法'), findsWidgets);
    expect(find.text('Idioms & Phrases'), findsOneWidget);
  });
}
