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

  Future<void> playSource(String source) async {
    final normalized = source.trim();
    if (normalized.isEmpty) {
      return;
    }

    await _player.stop();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      await _player.play(UrlSource(normalized));
      return;
    }
    await _player.play(DeviceFileSource(normalized));
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
