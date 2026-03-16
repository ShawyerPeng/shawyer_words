import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/mdx_dictionary_parser.dart';

void main() {
  test('lists keys through search and reads entries through locate', () async {
    final backend = _FakeDictReaderBackend();
    final reader = DictReaderAdapter.fromBackend(backend);

    await reader.open();
    final keys = await reader.listKeys(limit: 10);
    final content = await reader.lookup('abandon');
    await reader.close();

    expect(keys, <String>['abandon', 'ability']);
    expect(content, '<div>abandon</div>');
    expect(backend.readWithOffsetCalled, isFalse);
    expect(backend.searchCalls, 1);
    expect(backend.locateCalls, 1);
  });
}

class _FakeDictReaderBackend implements DictReaderBackend {
  bool readWithOffsetCalled = false;
  int searchCalls = 0;
  int locateCalls = 0;

  @override
  Future<void> close() async {}

  @override
  Future<void> initDict() async {}

  @override
  Future<RecordOffsetData?> locate(String key) async {
    locateCalls += 1;
    if (key == 'abandon') {
      return const RecordOffsetData(
        keyText: 'abandon',
        recordBlockOffset: 100,
        startOffset: 0,
        endOffset: 32,
        compressedSize: 48,
      );
    }
    return null;
  }

  @override
  Future<String?> readOneMdx(RecordOffsetData offset) async {
    return '<div>${offset.keyText}</div>';
  }

  @override
  Stream<RecordOffsetData> readWithOffset() async* {
    readWithOffsetCalled = true;
    throw UnimplementedError('should not use readWithOffset');
  }

  @override
  List<String> search(String key, {int? limit}) {
    searchCalls += 1;
    return <String>['abandon', 'ability'];
  }
}
