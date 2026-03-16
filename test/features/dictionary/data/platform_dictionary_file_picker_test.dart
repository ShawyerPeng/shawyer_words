import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/data/platform_dictionary_file_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pickDictionaryPackageSource invokes the package picker channel', () async {
    const channel = MethodChannel(
      PlatformDictionaryFilePicker.channelName,
    );
    final calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return '/tmp/example.zip';
        });

    final picker = PlatformDictionaryFilePicker();
    final filePath = await picker.pickDictionaryPackageSource();

    expect(filePath, '/tmp/example.zip');
    expect(calls, hasLength(1));
    expect(calls.single.method, 'pickDictionaryPackageSource');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
