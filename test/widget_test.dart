import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/main.dart';

void main() {
  testWidgets('knowledge plaza and learning page are both reachable', (tester) async {
    await tester.pumpWidget(ShawyerWordsApp());

    expect(find.text('学习广场'), findsOneWidget);
    expect(find.text('查单词或搜索文章'), findsOneWidget);
    expect(find.text('知识库'), findsOneWidget);

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
