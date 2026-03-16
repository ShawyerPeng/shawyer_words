class DictionarySummary {
  const DictionarySummary({
    required this.id,
    required this.name,
    required this.sourcePath,
    required this.importedAt,
    required this.entryCount,
  });

  final String id;
  final String name;
  final String sourcePath;
  final String importedAt;
  final int entryCount;
}
