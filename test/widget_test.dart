import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/main.dart';

void main() {
  testWidgets('shows the new home dashboard shell', (tester) async {
    await tester.pumpWidget(ShawyerWordsApp());

    expect(find.text('学习广场'), findsOneWidget);
    expect(find.text('查单词或搜索文章'), findsOneWidget);
    expect(find.text('知识库'), findsOneWidget);
  });
}
