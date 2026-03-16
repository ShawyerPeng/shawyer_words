import 'package:flutter/services.dart';

class PlatformDictionaryFilePicker {
  static const String channelName = 'shawyer_words/dictionary_file_picker';

  static const MethodChannel _channel = MethodChannel(channelName);

  Future<String?> pickDictionaryPackageSource() async {
    return _channel.invokeMethod<String>('pickDictionaryPackageSource');
  }

  Future<String?> pickDictionaryFile() async {
    return pickDictionaryPackageSource();
  }
}
