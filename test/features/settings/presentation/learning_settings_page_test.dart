import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/presentation/learning_settings_page.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets(
    'shows learning settings entries and opens reminder settings page',
    (tester) async {
      final controller = SettingsController(
        repository: _FakeAppSettingsRepository(),
        wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(home: LearningSettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('单词书'), findsOneWidget);
      expect(find.text('每日学习计划'), findsOneWidget);
      expect(find.text('学习提醒'), findsWidgets);
      expect(find.text('默认发音'), findsOneWidget);
      expect(find.text('自动发音'), findsOneWidget);
      expect(find.text('默认显示对话翻译'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('清除学习进度'), 300);
      expect(find.text('清除学习进度'), findsOneWidget);

      await tester.tap(find.text('学习提醒').last);
      await tester.pumpAndSettle();

      expect(find.text('App提醒'), findsOneWidget);
      expect(find.text('提醒时间'), findsOneWidget);
    },
  );
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings.defaults();

  @override
  Future<void> save(AppSettings settings) async {}
}

class _FakeWordKnowledgeRepository implements WordKnowledgeRepository {
  @override
  Future<void> clearAll() async {}

  @override
  Future<WordKnowledgeRecord?> getByWord(String word) async => null;

  @override
  Future<List<WordKnowledgeRecord>> loadAll() async =>
      const <WordKnowledgeRecord>[];

  @override
  Future<void> markKnown(
    String word, {
    required bool skipConfirmNextTime,
  }) async {}

  @override
  Future<void> save(WordKnowledgeRecord record) async {}

  @override
  Future<void> saveNote(String word, String note) async {}

  @override
  Future<void> toggleFavorite(String word) async {}
}
