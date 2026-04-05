import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';
import 'package:shawyer_words/features/me/presentation/me_page.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_settings_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';

void main() {
  testWidgets(
    'shows me showcase cards and retained setting entries, then opens dictionary library management',
    (tester) async {
      final settingsController = SettingsController(
        repository: _FakeAppSettingsRepository(),
        wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      );
      await settingsController.load();

      await tester.pumpWidget(
        MaterialApp(
          home: MePage(
            settingsController: settingsController,
            dictionaryLibraryManagementPageBuilder: _buildManagementPage,
          ),
        ),
      );

      expect(find.text('收藏'), findsOneWidget);
      expect(find.text('录音'), findsOneWidget);
      expect(find.text('文件'), findsOneWidget);
      expect(find.text('账号设置'), findsOneWidget);
      expect(find.text('通用设置'), findsOneWidget);
      expect(find.text('学习设置'), findsOneWidget);
      expect(find.text('词典库管理'), findsOneWidget);
      expect(find.text('会员中心'), findsOneWidget);
      expect(find.text('登录'), findsOneWidget);

      final accountTop = tester
          .getRect(find.byKey(const ValueKey('me-entry-account-settings')))
          .top;
      final generalTop = tester
          .getRect(find.byKey(const ValueKey('me-entry-general-settings')))
          .top;
      final learningTop = tester
          .getRect(find.byKey(const ValueKey('me-entry-learning-settings')))
          .top;
      final dictionaryTop = tester
          .getRect(find.byKey(const ValueKey('me-entry-dictionary-management')))
          .top;

      expect(accountTop, lessThan(generalTop));
      expect(generalTop, lessThan(learningTop));
      expect(learningTop, lessThan(dictionaryTop));

      await tester.scrollUntilVisible(
        find.text('数据统计'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('数据统计'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('邀请好友'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('邀请好友'), findsOneWidget);

      final helpEntry = find.byKey(const ValueKey('me-entry-help-feedback'));
      await tester.ensureVisible(helpEntry);
      await tester.pumpAndSettle();
      await tester.tap(helpEntry, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('帮助中心'), findsOneWidget);
      expect(find.text('常见问题'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('help-center-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('me-entry-account-settings')));
      await tester.pumpAndSettle();

      expect(find.text('账号设置'), findsWidgets);
      expect(find.text('管理账号信息、登录方式与同步相关设置。'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('me-entry-dictionary-management')),
      );
      await tester.pumpAndSettle();

      expect(find.text('所有词典库'), findsOneWidget);
    },
  );

  testWidgets('adds extra bottom inset when rendered as a tab page', (
    tester,
  ) async {
    final settingsController = SettingsController(
      repository: _FakeAppSettingsRepository(),
      wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
    );
    await settingsController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: MePage(
            settingsController: settingsController,
            showCloseButton: false,
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.padding, isA<EdgeInsets>());
    final padding = listView.padding! as EdgeInsets;
    expect(padding.bottom, greaterThanOrEqualTo(140));
  });

  testWidgets(
    'keeps visible spacing between profile header and showcase cards',
    (tester) async {
      final settingsController = SettingsController(
        repository: _FakeAppSettingsRepository(),
        wordKnowledgeRepository: _FakeWordKnowledgeRepository(),
      );
      await settingsController.load();

      await tester.pumpWidget(
        MaterialApp(
          home: MePage(
            settingsController: settingsController,
            dictionaryLibraryManagementPageBuilder: _buildManagementPage,
          ),
        ),
      );

      final header = find.text('登录');
      final showcaseCard = find.text('收藏');

      final headerBottom = tester.getRect(header).bottom;
      final showcaseTop = tester.getRect(showcaseCard).top;

      expect(showcaseTop - headerBottom, greaterThanOrEqualTo(24));
    },
  );
}

Widget _buildManagementPage(BuildContext context) {
  return const DictionaryLibraryManagementPage(controller: null);
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
