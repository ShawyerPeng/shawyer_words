# Dictionary Package Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the single-file `MDX` import flow with an app-managed dictionary package system that supports directory/archive import, isolates bundled and imported dictionaries, and preserves `MDX`/`MDD`/resource files under per-dictionary directories.

**Architecture:** Add a storage/catalog layer that owns dictionary package directories and manifests. Import goes through staging, normalization, validation, and atomic publish into app-managed storage. Existing parsing logic is adapted from a raw `filePath` input to a package-driven flow so the active dictionary package becomes the source of truth.

**Tech Stack:** Flutter, Dart, local filesystem APIs, platform channel/file-picker integration, dictionary package manifests, paginated preview state, HTML rendering, Flutter tests.

---

### Task 1: Define Package Domain Types

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_package.dart`
- Create: `lib/features/dictionary/domain/dictionary_manifest.dart`
- Create: `lib/features/dictionary/domain/dictionary_catalog_entry.dart`
- Test: `test/features/dictionary/domain/dictionary_package_test.dart`

**Step 1: Write the failing test**

Create tests that define:

- bundled vs imported package typing
- manifest serialization/deserialization
- deterministic primary `MDX` path handling

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_package_test.dart`
Expected: FAIL because the package domain models do not exist yet

**Step 3: Write minimal implementation**

Add immutable domain models for package metadata and manifest persistence.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_package_test.dart`
Expected: PASS

### Task 2: Add Dictionary Storage And Catalog Abstractions

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_storage.dart`
- Create: `lib/features/dictionary/domain/dictionary_catalog.dart`
- Create: `lib/features/dictionary/data/file_system_dictionary_storage.dart`
- Create: `lib/features/dictionary/data/file_system_dictionary_catalog.dart`
- Test: `test/features/dictionary/data/file_system_dictionary_storage_test.dart`

**Step 1: Write the failing test**

Create tests for:

- creating isolated package directories
- writing `manifest.json`
- listing bundled and imported packages separately
- deleting imported packages safely

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/file_system_dictionary_storage_test.dart`
Expected: FAIL because storage and catalog layers do not exist yet

**Step 3: Write minimal implementation**

Implement filesystem-backed package storage and catalog classes.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/file_system_dictionary_storage_test.dart`
Expected: PASS

### Task 3: Build Package Importer With Staging

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_package_importer.dart`
- Create: `lib/features/dictionary/data/dictionary_package_importer.dart`
- Create: `lib/features/dictionary/data/dictionary_package_scanner.dart`
- Test: `test/features/dictionary/data/dictionary_package_importer_test.dart`

**Step 1: Write the failing test**

Create tests for:

- importing from a directory
- importing from an archive
- rejecting missing-`MDX` packages
- cleaning staging on failure

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/dictionary_package_importer_test.dart`
Expected: FAIL because package import staging and scanning do not exist yet

**Step 3: Write minimal implementation**

Implement staging import flow, package scanning, validation, and atomic publish.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/dictionary_package_importer_test.dart`
Expected: PASS

### Task 4: Adapt Parser And Repository To Package Inputs

**Files:**
- Modify: `lib/features/dictionary/data/mdx_dictionary_parser.dart`
- Modify: `lib/features/dictionary/data/platform_dictionary_repository.dart`
- Modify: `lib/features/dictionary/domain/dictionary_repository.dart`
- Test: `test/features/dictionary/data/platform_dictionary_repository_test.dart`
- Test: `test/features/dictionary/data/mdx_dictionary_parser_test.dart`

**Step 1: Write the failing test**

Update tests to expect dictionary parsing from a package manifest or package model rather than a bare `MDX` file path.

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/platform_dictionary_repository_test.dart test/features/dictionary/data/mdx_dictionary_parser_test.dart`
Expected: FAIL because repository and parser still assume a single file path

**Step 3: Write minimal implementation**

Make repository import through the package importer and parse from the selected package’s primary `MDX`.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/platform_dictionary_repository_test.dart test/features/dictionary/data/mdx_dictionary_parser_test.dart`
Expected: PASS

### Task 5: Replace File Picker Entry Point

**Files:**
- Modify: `lib/features/dictionary/data/platform_dictionary_file_picker.dart`
- Modify: platform-specific file-picker implementation files as needed
- Test: `test/features/dictionary/data/platform_dictionary_file_picker_test.dart`

**Step 1: Write the failing test**

Update tests so the picker contract supports selecting a directory or archive source rather than only `pickMdxFile`.

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/platform_dictionary_file_picker_test.dart`
Expected: FAIL because the picker still exposes the old single-file API

**Step 3: Write minimal implementation**

Replace the picker contract with a package-source selection flow and update platform channel naming/methods as needed.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/platform_dictionary_file_picker_test.dart`
Expected: PASS

### Task 6: Update Controller State For Managed Packages

**Files:**
- Modify: `lib/features/dictionary/application/dictionary_controller.dart`
- Modify: `lib/features/dictionary/domain/dictionary_summary.dart`
- Test: `test/features/dictionary/application/dictionary_controller_test.dart`

**Step 1: Write the failing test**

Add tests for:

- successful package import updates active dictionary state
- imported package metadata is available in controller state
- failures preserve clean state

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: FAIL because controller state does not model package-driven imports

**Step 3: Write minimal implementation**

Adjust controller behavior to work with managed dictionary packages.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: PASS

### Task 7: Update Dictionary UI Copy And Entry Flow

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Test: `test/features/dictionary/presentation/dictionary_home_page_test.dart`

**Step 1: Write the failing test**

Update UI tests to expect:

- import copy for dictionary folders/archives
- support messaging for `MDX`, `MDD`, and resources
- package-oriented import button labeling

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: FAIL because the UI still describes single-file `MDX` import

**Step 3: Write minimal implementation**

Update empty/failure states and import entry behavior to match package import.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: PASS

### Task 8: Add Dictionary Package Management Surface

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Create: helper widgets/files only if needed
- Test: `test/features/dictionary/presentation/dictionary_home_page_test.dart`

**Step 1: Write the failing test**

Add tests for:

- showing bundled/imported package information
- showing the active package name
- exposing delete action only for imported packages

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: FAIL because package management UI does not exist yet

**Step 3: Write minimal implementation**

Add the smallest useful package management UI needed to reflect the new architecture.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: PASS

### Task 9: Verify End To End

**Files:**
- Modify as needed from previous tasks

**Step 1: Run targeted dictionary tests**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary`
Expected: PASS

**Step 2: Run the full test suite**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test`
Expected: PASS

**Step 3: Run static analysis**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter analyze`
Expected: `No issues found!`

### Task 10: Add Import Session Preview Models

**Files:**
- Create: `lib/features/dictionary/domain/dictionary_import_preview.dart`
- Create: `lib/features/dictionary/domain/dictionary_preview_repository.dart`
- Test: `test/features/dictionary/domain/dictionary_import_preview_test.dart`

**Step 1: Write the failing test**

Create tests for:

- preview session summaries for primary `MDX` and related resource files
- page metadata for `1000` entries per page
- 10-page grouped pagination math

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_import_preview_test.dart`
Expected: FAIL because preview models do not exist yet

**Step 3: Write minimal implementation**

Add immutable preview models and pagination helpers.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/domain/dictionary_import_preview_test.dart`
Expected: PASS

### Task 11: Build Preview Repository

**Files:**
- Create: `lib/features/dictionary/data/platform_dictionary_preview_repository.dart`
- Modify: `lib/features/dictionary/data/dictionary_package_scanner.dart`
- Modify: `lib/features/dictionary/data/mdx_dictionary_parser.dart`
- Test: `test/features/dictionary/data/platform_dictionary_preview_repository_test.dart`

**Step 1: Write the failing test**

Create tests for:

- scanning and classifying selected files across repeated picker additions
- previewing dictionary metadata and file inventory without installation
- loading preview pages at `1000` entries per page
- loading entry detail HTML for a selected preview item

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/platform_dictionary_preview_repository_test.dart`
Expected: FAIL because preview repository support does not exist yet

**Step 3: Write minimal implementation**

Implement a preview repository that reuses package scanning/parsing logic while
keeping installation separate.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/data/platform_dictionary_preview_repository_test.dart`
Expected: PASS

### Task 12: Add Import Session Controller State

**Files:**
- Modify: `lib/features/dictionary/application/dictionary_controller.dart`
- Test: `test/features/dictionary/application/dictionary_controller_test.dart`

**Step 1: Write the failing test**

Add tests for:

- opening the overlay starts an import session
- cancelling picker keeps the overlay active
- adding files transitions to confirmation state
- previewing loads the first page and first entry
- installing triggers the existing repository import only after confirmation

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: FAIL because import-session state and actions do not exist yet

**Step 3: Write minimal implementation**

Extend the controller with an isolated import-session state machine and preview
actions that do not disturb the installed-study state.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/application/dictionary_controller_test.dart`
Expected: PASS

### Task 13: Build Overlay, Confirmation, And Preview UI

**Files:**
- Modify: `lib/features/dictionary/presentation/dictionary_home_page.dart`
- Modify: `pubspec.yaml`
- Test: `test/features/dictionary/presentation/dictionary_home_page_test.dart`

**Step 1: Write the failing test**

Add tests for:

- showing the import overlay before opening the picker
- keeping the overlay visible after picker cancellation
- reopening the picker from the center icon and the "添加文件" action
- showing the confirmation dialog with detected files
- previewing `1000` entries per page
- showing 10-page grouped square page buttons
- jumping to the selected page and focusing the first entry

**Step 2: Run test to verify it fails**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: FAIL because the overlay, confirmation, and preview UI do not exist yet

**Step 3: Write minimal implementation**

Add the import-session overlay, confirmation dialog, full-screen preview, and
HTML entry detail rendering.

**Step 4: Run test to verify it passes**

Run: `/Users/shawyerpeng/sdk/flutter/bin/flutter test test/features/dictionary/presentation/dictionary_home_page_test.dart`
Expected: PASS
