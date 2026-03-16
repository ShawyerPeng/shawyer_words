import 'package:shawyer_words/features/dictionary/domain/bundled_dictionary_registry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_catalog_entry.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_preferences_store.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_repository.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_storage.dart';

class FileSystemDictionaryLibraryRepository
    implements DictionaryLibraryRepository {
  FileSystemDictionaryLibraryRepository({
    required DictionaryCatalog catalog,
    required DictionaryLibraryPreferencesStore preferencesStore,
    required BundledDictionaryRegistry bundledRegistry,
    required DictionaryStorage storage,
  }) : _catalog = catalog,
       _preferencesStore = preferencesStore,
       _bundledRegistry = bundledRegistry,
       _storage = storage;

  final DictionaryCatalog _catalog;
  final DictionaryLibraryPreferencesStore _preferencesStore;
  final BundledDictionaryRegistry _bundledRegistry;
  final DictionaryStorage _storage;

  @override
  Future<List<DictionaryLibraryItem>> loadLibraryItems() async {
    await _bundledRegistry.sync();
    final preferences = await _preferencesStore.load();
    final entries = await _catalog.listPackages();
    final order = _buildOrder(entries, preferences.displayOrder);
    final hiddenIds = preferences.hiddenIds.toSet();
    final autoExpandIds = preferences.autoExpandIds.toSet();

    final visible = <DictionaryLibraryItem>[];
    final hidden = <DictionaryLibraryItem>[];

    for (var index = 0; index < order.length; index++) {
      final entry = order[index];
      final item = _toLibraryItem(
        entry: entry,
        sortIndex: index,
        isVisible: !hiddenIds.contains(entry.id),
        autoExpand: autoExpandIds.contains(entry.id),
      );
      if (item.isVisible) {
        visible.add(item);
      } else {
        hidden.add(item);
      }
    }

    return <DictionaryLibraryItem>[...visible, ...hidden];
  }

  @override
  Future<void> reorderVisible(List<String> visibleIds) async {
    await _bundledRegistry.sync();
    final entries = await _catalog.listPackages();
    final preferences = await _preferencesStore.load();
    final hiddenIds = preferences.hiddenIds.toSet();
    final currentOrder = _buildOrder(entries, preferences.displayOrder);
    final remainingVisibleIds = currentOrder
        .where(
          (entry) =>
              !hiddenIds.contains(entry.id) && !visibleIds.contains(entry.id),
        )
        .map((entry) => entry.id)
        .toList();
    final hiddenInOrder = currentOrder
        .where((entry) => hiddenIds.contains(entry.id))
        .map((entry) => entry.id)
        .toList();
    final nextOrder = <String>[
      ...visibleIds,
      ...remainingVisibleIds,
      ...hiddenInOrder.where((id) => !visibleIds.contains(id)),
    ];
    await _preferencesStore.save(
      DictionaryLibraryPreferences(
        displayOrder: nextOrder,
        hiddenIds: preferences.hiddenIds,
        autoExpandIds: preferences.autoExpandIds,
        selectedDictionaryId: preferences.selectedDictionaryId,
      ),
    );
  }

  @override
  Future<void> deleteDictionary(String id) async {
    await _bundledRegistry.sync();
    final entries = await _catalog.listPackages();
    final entry = entries.where((candidate) => candidate.id == id).firstOrNull;
    if (entry == null) {
      throw StateError('The selected dictionary could not be found.');
    }
    if (entry.type == DictionaryPackageType.bundled) {
      throw UnsupportedError('Bundled dictionaries cannot be deleted.');
    }

    await _storage.deletePackage(
      type: DictionaryPackageType.imported,
      id: id,
    );

    final preferences = await _preferencesStore.load();
    await _preferencesStore.save(
      DictionaryLibraryPreferences(
        displayOrder: preferences.displayOrder.where((value) => value != id).toList(),
        hiddenIds: preferences.hiddenIds.where((value) => value != id).toList(),
        autoExpandIds: preferences.autoExpandIds.where((value) => value != id).toList(),
        selectedDictionaryId: preferences.selectedDictionaryId == id
            ? null
            : preferences.selectedDictionaryId,
      ),
    );
  }

  @override
  Future<void> setAutoExpand(String id, bool autoExpand) async {
    await _bundledRegistry.sync();
    final preferences = await _preferencesStore.load();
    final autoExpandIds = preferences.autoExpandIds.toSet();
    if (autoExpand) {
      autoExpandIds.add(id);
    } else {
      autoExpandIds.remove(id);
    }
    await _preferencesStore.save(
      DictionaryLibraryPreferences(
        displayOrder: preferences.displayOrder,
        hiddenIds: preferences.hiddenIds,
        autoExpandIds: autoExpandIds.toList(),
        selectedDictionaryId: preferences.selectedDictionaryId,
      ),
    );
  }

  @override
  Future<void> setVisibility(String id, bool isVisible) async {
    await _bundledRegistry.sync();
    final entries = await _catalog.listPackages();
    final preferences = await _preferencesStore.load();
    final hiddenIds = preferences.hiddenIds.toSet();
    final displayOrder = _buildOrder(entries, preferences.displayOrder)
        .map((entry) => entry.id)
        .toList();

    if (isVisible) {
      hiddenIds.remove(id);
      if (!displayOrder.contains(id)) {
        displayOrder.add(id);
      }
    } else {
      hiddenIds.add(id);
    }

    await _preferencesStore.save(
      DictionaryLibraryPreferences(
        displayOrder: displayOrder,
        hiddenIds: hiddenIds.toList(),
        autoExpandIds: preferences.autoExpandIds,
        selectedDictionaryId: preferences.selectedDictionaryId,
      ),
    );
  }

  List<DictionaryCatalogEntry> _buildOrder(
    List<DictionaryCatalogEntry> entries,
    List<String> preferredOrder,
  ) {
    final byId = <String, DictionaryCatalogEntry>{
      for (final entry in entries) entry.id: entry,
    };
    final ordered = <DictionaryCatalogEntry>[];
    for (final id in preferredOrder) {
      final entry = byId.remove(id);
      if (entry != null) {
        ordered.add(entry);
      }
    }

    final remaining = byId.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    ordered.addAll(remaining);
    return ordered;
  }

  DictionaryLibraryItem _toLibraryItem({
    required DictionaryCatalogEntry entry,
    required int sortIndex,
    required bool isVisible,
    required bool autoExpand,
  }) {
    final fileSizeBytes = entry.fileSizeBytes ?? 0;
    return DictionaryLibraryItem(
      id: entry.id,
      name: entry.name,
      type: entry.type,
      rootPath: entry.rootPath,
      importedAt: entry.importedAt,
      version: entry.version ?? _defaultVersion(entry.importedAt),
      category: entry.category ?? '默认',
      entryCount: entry.entryCount ?? 0,
      dictionaryAttribute: entry.dictionaryAttribute ?? '本地词典',
      fileSizeBytes: fileSizeBytes,
      fileSizeLabel: _formatFileSize(fileSizeBytes),
      isVisible: isVisible,
      autoExpand: autoExpand,
      sortIndex: sortIndex,
    );
  }

  String _defaultVersion(String importedAt) {
    final digits = importedAt.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 8 ? digits.substring(0, 8) : '00000000';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0B';
    }
    const units = <String>['B', 'K', 'M', 'G'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    final rounded = unitIndex == 0 ? value.toStringAsFixed(0) : value.round().toString();
    return '$rounded${units[unitIndex]}';
  }
}
