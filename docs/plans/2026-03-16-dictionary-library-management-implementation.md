# Dictionary Library Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a persistent dictionary library management system with bundled/imported dictionary registration, hide/show and ordering controls, and settings/detail pages that operate on real dictionary data.

**Architecture:** Add a library-management layer on top of package storage/catalog. Persist user preferences separately from package manifests, register bundled dictionaries into the same package system, and feed both the settings UI and runtime dictionary selection from the merged library view.

**Tech Stack:** Flutter, Dart, local filesystem JSON persistence, existing dictionary package storage/catalog, widget tests, Flutter unit tests.

---

### Task 1: Define Library Preference And Detail Models

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_library_preferences.dart`
- Create: `lib/features/dictionary/domain/dictionary_library_item.dart`
- Test: `test/features/dictionary/domain/dictionary_library_preferences_test.dart`

**Step 1: Write the failing test**

Add tests that cover:

- `displayOrder`, `hiddenIds`, `autoExpandIds`, and `selectedDictionaryId` JSON round-trip
- converting merged metadata into a `DictionaryLibraryItem`

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_library_preferences_test.dart`
Expected: FAIL because the models do not exist yet.

**Step 3: Write minimal implementation**

Create the preference and library item models with JSON serialization and immutable fields only.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_library_preferences_test.dart`
Expected: PASS.

### Task 2: Add Library Preference Storage

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_library_preferences_store.dart`
- Create: `lib/features/dictionary/data/file_system_dictionary_library_preferences_store.dart`
- Test: `test/features/dictionary/data/file_system_dictionary_library_preferences_store_test.dart`

**Step 1: Write the failing test**

Add tests for:

- loading default preferences when no file exists
- saving preferences to `library_preferences.json`
- reading the saved file back

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/file_system_dictionary_library_preferences_store_test.dart`
Expected: FAIL because the store does not exist yet.

**Step 3: Write minimal implementation**

Implement filesystem-backed preference load/save using the dictionary root path resolver.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/file_system_dictionary_library_preferences_store_test.dart`
Expected: PASS.

### Task 3: Expand Manifest Metadata For Library Details

**Files:**
- Modify: `lib/features/dictionary/domain/dictionary_manifest.dart`
- Modify: `lib/features/dictionary/domain/dictionary_package.dart`
- Modify: `test/features/dictionary/domain/dictionary_package_test.dart`

**Step 1: Write the failing test**

Extend tests to expect optional detail fields:

- version
- category
- dictionaryAttribute
- fileSizeBytes

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_package_test.dart`
Expected: FAIL because the manifest/package models do not carry the new fields.

**Step 3: Write minimal implementation**

Add optional fields to the manifest/package models and keep old callers working with stable defaults.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_package_test.dart`
Expected: PASS.

### Task 4: Add Bundled Dictionary Registration

**Files:**
- Create: `lib/features/dictionary/domain/bundled_dictionary_registry.dart`
- Create: `lib/features/dictionary/data/bundled_dictionary_registry.dart`
- Test: `test/features/dictionary/data/bundled_dictionary_registry_test.dart`

**Step 1: Write the failing test**

Add tests that cover:

- registering bundled dictionaries into `bundled/<id>/`
- writing manifest-backed bundled packages
- preserving bundled metadata such as version/category/type label source

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/bundled_dictionary_registry_test.dart`
Expected: FAIL because bundled registration does not exist.

**Step 3: Write minimal implementation**

Implement a small bundled registry source and synchronize it into the existing package storage layout.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/bundled_dictionary_registry_test.dart`
Expected: PASS.

### Task 5: Build Dictionary Library Repository

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_library_repository.dart`
- Create: `lib/features/dictionary/data/file_system_dictionary_library_repository.dart`
- Test: `test/features/dictionary/data/file_system_dictionary_library_repository_test.dart`

**Step 1: Write the failing test**

Add tests for:

- merging bundled/imported package manifests
- applying saved display order
- splitting visible vs hidden dictionaries
- exposing detail rows with stable fallback values

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/file_system_dictionary_library_repository_test.dart`
Expected: FAIL because the repository does not exist.

**Step 3: Write minimal implementation**

Implement library repository methods for:

- loading library items
- reordering visible dictionaries
- hiding/showing dictionaries
- toggling auto-expand
- returning detail metadata

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/file_system_dictionary_library_repository_test.dart`
Expected: PASS.

### Task 6: Connect Active Dictionary Selection To Library Rules

**Files:**
- Modify: `lib/features/dictionary/application/dictionary_controller.dart`
- Modify: `lib/features/dictionary/domain/dictionary_repository.dart`
- Modify: `lib/features/dictionary/data/platform_dictionary_repository.dart`
- Test: `test/features/dictionary/application/dictionary_controller_test.dart`

**Step 1: Write the failing test**

Add tests that cover:

- active dictionary fallback when the current library item becomes hidden
- preserving active package metadata across library updates

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: FAIL because controller state does not respond to library visibility changes.

**Step 3: Write minimal implementation**

Add the smallest controller/repository hooks needed to load the selected visible dictionary and react when it becomes hidden.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: PASS.

### Task 7: Add Me Page Settings Entry

**Files:**
- Modify: `lib/features/me/presentation/me_page.dart`
- Create: `test/features/me/presentation/me_page_test.dart`

**Step 1: Write the failing test**

Add tests for:

- showing `词典库管理` inside `通用设置`
- navigating from `我的` to the dictionary library management page

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/me/presentation/me_page_test.dart`
Expected: FAIL because the entry and navigation do not exist.

**Step 3: Write minimal implementation**

Add the new settings row and route push only.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/me/presentation/me_page_test.dart`
Expected: PASS.

### Task 8: Build Dictionary Library Management Page

**Files:**
- Create: `lib/features/dictionary/presentation/dictionary_library_management_page.dart`
- Create: `lib/features/dictionary/application/dictionary_library_controller.dart`
- Test: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Write the failing test**

Add widget tests for:

- rendering visible and hidden sections
- filtering the list from the search box
- tapping the chevron to open detail

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
Expected: FAIL because the page/controller do not exist.

**Step 3: Write minimal implementation**

Build the page using the merged library repository data and create a small controller for loading and mutating library items.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
Expected: PASS.

### Task 9: Add Reorder And Hide Interactions

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_library_management_page.dart`
- Modify: `lib/features/dictionary/application/dictionary_library_controller.dart`
- Test: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Write the failing test**

Add tests for:

- drag handle based visible-list reorder
- moving a visible dictionary into the hidden zone
- restoring a hidden dictionary to visible

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
Expected: FAIL because reorder/hide interactions are not implemented.

**Step 3: Write minimal implementation**

Use Flutter reorderable list primitives plus explicit visible/hidden drop targets and persist each mutation immediately.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
Expected: PASS.

### Task 10: Build Dictionary Detail Page

**Files:**
- Create: `lib/features/dictionary/presentation/dictionary_library_detail_page.dart`
- Test: `test/features/dictionary/presentation/dictionary_library_detail_page_test.dart`

**Step 1: Write the failing test**

Add tests for:

- showing detail fields
- toggling `显示该词库`
- toggling `自动展开`
- reflecting system/user dictionary type labels

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_detail_page_test.dart`
Expected: FAIL because the detail page does not exist.

**Step 3: Write minimal implementation**

Build the detail page and wire its toggles to the library repository/controller.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_library_detail_page_test.dart`
Expected: PASS.

### Task 11: Apply Visibility To Runtime Entry Points

**Files:**
- Modify: `lib/features/search/data/dictionary_word_lookup_repository.dart`
- Modify: `lib/app/app.dart`
- Modify: any dictionary-switch UI introduced for the library flow
- Test: `test/features/search/presentation/search_page_test.dart`
- Test: `test/features/dictionary/presentation/dictionary_library_management_page_test.dart`

**Step 1: Write the failing test**

Add tests that verify:

- hidden dictionaries are excluded from user-facing available-library lists
- hiding the selected dictionary switches to the next visible dictionary

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/search/presentation/search_page_test.dart test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
Expected: FAIL because runtime entry points do not yet consume library visibility.

**Step 3: Write minimal implementation**

Feed the runtime dictionary entry points from the library layer’s visible dictionaries and perform fallback selection when needed.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/search/presentation/search_page_test.dart test/features/dictionary/presentation/dictionary_library_management_page_test.dart`
Expected: PASS.

### Task 12: Verify End To End

**Files:**
- Modify as needed from previous tasks

**Step 1: Run targeted library and dictionary tests**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary test/features/me`
Expected: PASS.

**Step 2: Run full test suite**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test`
Expected: PASS.

**Step 3: Run static analysis**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter analyze`
Expected: `No issues found!`
