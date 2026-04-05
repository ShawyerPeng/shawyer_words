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
    'shows all first-level me sections and opens dictionary library management',
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

      expect(find.text('词典库管理'), findsOneWidget);
      expect(find.text('通用设置'), findsOneWidget);
      expect(find.text('学习设置'), findsOneWidget);
      expect(find.text('数据统计'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('会员中心'), 300);
      expect(find.text('会员中心'), findsOneWidget);
      expect(find.text('帮助与反馈'), findsOneWidget);
      expect(find.text('词典库管理'), findsOneWidget);

      await tester.tap(find.text('帮助与反馈'));
      await tester.pumpAndSettle();

      expect(find.text('帮助中心'), findsOneWidget);
      expect(find.text('常见问题'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('help-center-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('词典库管理'));
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

  testWidgets('keeps visible spacing between login card and first menu tile', (
    tester,
  ) async {
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

    final loginCard = find.ancestor(
      of: find.text('同步学习进度、收藏和搜索历史'),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container) {
          return false;
        }
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) {
          return false;
        }
        return decoration.boxShadow?.isNotEmpty == true;
      }),
    );
    final firstMenuTile = find.ancestor(
      of: find.text('词典库管理'),
      matching: find.byType(Material),
    );

    final loginCardBottom = tester.getRect(loginCard.first).bottom;
    final firstMenuTileTop = tester.getRect(firstMenuTile.first).top;

    expect(firstMenuTileTop - loginCardBottom, greaterThanOrEqualTo(14));
  });
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
