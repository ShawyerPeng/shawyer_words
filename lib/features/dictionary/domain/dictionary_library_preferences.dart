class DictionaryLibraryPreferences {
  const DictionaryLibraryPreferences({
    this.displayOrder = const <String>[],
    this.hiddenIds = const <String>[],
    this.autoExpandIds = const <String>[],
    this.selectedDictionaryId,
  });

  final List<String> displayOrder;
  final List<String> hiddenIds;
  final List<String> autoExpandIds;
  final String? selectedDictionaryId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'displayOrder': displayOrder,
      'hiddenIds': hiddenIds,
      'autoExpandIds': autoExpandIds,
      'selectedDictionaryId': selectedDictionaryId,
    };
  }

  factory DictionaryLibraryPreferences.fromJson(Map<String, Object?> json) {
    return DictionaryLibraryPreferences(
      displayOrder: List<String>.from(
        json['displayOrder'] as List<Object?>? ?? const <Object?>[],
      ),
      hiddenIds: List<String>.from(
        json['hiddenIds'] as List<Object?>? ?? const <Object?>[],
      ),
      autoExpandIds: List<String>.from(
        json['autoExpandIds'] as List<Object?>? ?? const <Object?>[],
      ),
      selectedDictionaryId: json['selectedDictionaryId'] as String?,
    );
  }
}
