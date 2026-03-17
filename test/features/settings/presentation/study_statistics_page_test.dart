import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/settings/presentation/study_statistics_page.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets('renders statistics sections and summary copy', (tester) async {
    final controller = SettingsController(
      repository: _FakeAppSettingsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: StudyStatisticsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('跟踪每日学习记录，每一点努力都算数'), findsOneWidget);
    expect(find.text('Heatmap'), findsOneWidget);
    expect(find.text('Vocabulary Growth Trend'), findsOneWidget);
    expect(find.text('Everyday Trend'), findsOneWidget);
  });
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
  Future<List<WordKnowledgeRecord>> loadAll() async {
    return <WordKnowledgeRecord>[
      WordKnowledgeRecord(
        word: 'abandon',
        isFavorite: false,
        isKnown: false,
        note: '',
        skipKnownConfirm: false,
        updatedAt: DateTime.now().toUtc(),
      ),
      WordKnowledgeRecord(
        word: 'ability',
        isFavorite: false,
        isKnown: true,
        note: '',
        skipKnownConfirm: false,
        updatedAt: DateTime.now().toUtc(),
      ),
    ];
  }

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
