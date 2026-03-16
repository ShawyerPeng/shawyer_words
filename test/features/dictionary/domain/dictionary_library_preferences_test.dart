import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

void main() {
  test('library preferences round-trip display order and toggles', () {
    const preferences = DictionaryLibraryPreferences(
      displayOrder: <String>['eng-eng', 'notes', 'encyclopedia'],
      hiddenIds: <String>['encyclopedia'],
      autoExpandIds: <String>['eng-eng'],
      selectedDictionaryId: 'eng-eng',
    );

    final decoded = DictionaryLibraryPreferences.fromJson(preferences.toJson());

    expect(decoded.displayOrder, ['eng-eng', 'notes', 'encyclopedia']);
    expect(decoded.hiddenIds, ['encyclopedia']);
    expect(decoded.autoExpandIds, ['eng-eng']);
    expect(decoded.selectedDictionaryId, 'eng-eng');
  });

  test('library item exposes merged metadata for management UI', () {
    const item = DictionaryLibraryItem(
      id: 'eng-eng',
      name: '英英词典',
      type: DictionaryPackageType.bundled,
      rootPath: '/app/dictionaries/bundled/eng-eng',
      importedAt: '2026-03-16T00:00:00.000Z',
      version: '20251021',
      category: '默认',
      entryCount: 428674,
      dictionaryAttribute: '本地词典',
      fileSizeBytes: 90 * 1024 * 1024,
      fileSizeLabel: '90M',
      isVisible: true,
      autoExpand: false,
      sortIndex: 3,
    );

    expect(item.name, '英英词典');
    expect(item.version, '20251021');
    expect(item.category, '默认');
    expect(item.entryCount, 428674);
    expect(item.dictionaryTypeLabel, '系统内置词典');
    expect(item.fileSizeLabel, '90M');
    expect(item.isVisible, isTrue);
    expect(item.autoExpand, isFalse);
  });
}
