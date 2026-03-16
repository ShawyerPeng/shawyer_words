import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_result.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_summary.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

void main() {
  testWidgets('study tab import button loads the first word card', (tester) async {
    final controller = DictionaryController(
      dictionaryRepository: _FakeDictionaryRepository(),
      studyRepository: _FakeStudyRepository(),
    );

    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: controller,
        pickDictionaryFile: () async => '/tmp/test.zip',
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '导入词库包'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('abandon'), findsOneWidget);
    expect(find.text('/əˈbændən/'), findsOneWidget);
    expect(find.text('to leave behind'), findsOneWidget);
    expect(find.text('Oxford Starter'), findsOneWidget);
  });

  testWidgets('picker errors are shown as a friendly message', (tester) async {
    final controller = DictionaryController(
      dictionaryRepository: _FakeDictionaryRepository(),
      studyRepository: _FakeStudyRepository(),
    );

    await tester.pumpWidget(
      ShawyerWordsApp(
        controller: controller,
        pickDictionaryFile: () async {
          throw PlatformException(
            code: 'invalid_file_type',
            message: 'Please choose a dictionary folder or archive package.',
          );
        },
      ),
    );

    await tester.tap(find.text('背单词').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '导入词库包'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('请选择词库目录、压缩包，或单个 MDX 文件。'), findsOneWidget);
    expect(controller.state.status, DictionaryStatus.idle);
  });
}

class _FakeDictionaryRepository implements DictionaryRepository {
  @override
  Future<DictionaryImportResult> importDictionary(String filePath) async {
    return const DictionaryImportResult(
      package: DictionaryPackage(
        id: 'oxford-starter',
        name: 'Oxford Starter',
        type: DictionaryPackageType.imported,
        rootPath: '/tmp/dictionaries/imported/oxford-starter',
        mdxPath: '/tmp/dictionaries/imported/oxford-starter/source/main.mdx',
        mddPaths: <String>[],
        resourcesPath: '/tmp/dictionaries/imported/oxford-starter/resources',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 1,
      ),
      dictionary: DictionarySummary(
        id: 'dict-1',
        name: 'Test Dictionary',
        sourcePath: '/tmp/dictionaries/imported/oxford-starter',
        importedAt: '2026-03-16T00:00:00.000Z',
        entryCount: 1,
      ),
      entries: [
        WordEntry(
          id: '1',
          word: 'abandon',
          pronunciation: '/əˈbændən/',
          partOfSpeech: 'verb',
          definition: 'to leave behind',
          exampleSentence: 'They abandon the plan at sunrise.',
          rawContent: '<p>abandon</p>',
        ),
      ],
    );
  }
}

class _FakeStudyRepository implements StudyRepository {
  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {}
}
