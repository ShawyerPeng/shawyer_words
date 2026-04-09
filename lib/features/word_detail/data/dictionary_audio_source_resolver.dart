String? normalizeDictionaryAudioSource(String? rawAudioPath) {
  if (rawAudioPath == null) {
    return null;
  }
  final normalized = rawAudioPath.trim();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }
  if (normalized.startsWith('/media/') || normalized.startsWith('media/')) {
    final mediaPath = normalized.startsWith('/') ? normalized : '/$normalized';
    return 'https://www.ldoceonline.com$mediaPath';
  }
  return normalized;
}
