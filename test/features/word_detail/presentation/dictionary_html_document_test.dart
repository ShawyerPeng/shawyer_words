import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_document.dart';

void main() {
  test('builds a full html document with resource links and base url', () {
    const detail = DictionaryEntryDetail(
      dictionaryId: 'collins',
      dictionaryName: 'Collins',
      word: 'abandon',
      rawContent: '<div class="entry">content</div>',
      resourcesPath: '/tmp/dictionaries/collins/resources',
      stylesheetPaths: <String>[
        '/tmp/dictionaries/collins/resources/theme.css',
      ],
      scriptPaths: <String>['/tmp/dictionaries/collins/resources/theme.js'],
    );

    final document = buildDictionaryHtmlDocument(detail);

    expect(document.baseUrl, 'file:///tmp/dictionaries/collins/resources/');
    expect(
      document.html,
      contains('<base href="file:///tmp/dictionaries/collins/resources/">'),
    );
    expect(
      document.html,
      contains(
        '<link rel="stylesheet" href="file:///tmp/dictionaries/collins/resources/theme.css">',
      ),
    );
    expect(
      document.html,
      contains(
        '<script src="file:///tmp/dictionaries/collins/resources/theme.js"></script>',
      ),
    );
    expect(document.html, contains('<div class="entry">content</div>'));
  });
}
