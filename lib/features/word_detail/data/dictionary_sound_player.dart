import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

class DictionarySoundPlayer {
  DictionarySoundPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<void> playFile(File file) async {
    await _player.stop();
    await _player.play(DeviceFileSource(file.path));
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
