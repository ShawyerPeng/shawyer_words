# Dictionary Library Management Design

**Date:** 2026-03-16

## Goal

Add a persistent dictionary library management experience under `我的 > 通用设置 > 词典库管理` that manages real bundled and imported dictionaries, supports drag reordering, hide/show, and dictionary detail settings, and applies hidden-state filtering to actual dictionary usage entry points.

## Product Scope

This feature covers:

- a new settings entry called `词典库管理`
- a management page with:
  - `显示的词库`
  - `隐藏的词库`
  - local list filtering
- drag handle based reordering
- drag from visible to hidden and back
- a dictionary detail page
- persistent storage of visibility, order, and `自动展开`
- real integration with bundled and imported dictionary packages
- hidden dictionaries being excluded from practical entry points

It does not cover:

- cloud sync
- multi-level taxonomy
- remote dictionary downloads
- complex smart grouping rules

## Current State

The current app can:

- import a dictionary package into app-managed storage
- parse the active package into `entries`
- show a single active dictionary in the study page

The app cannot yet:

- manage multiple dictionaries as a library
- register bundled dictionaries in the same package system
- persist display order / hidden state / auto-expand
- expose a dictionary detail view
- filter actual usage by visible dictionaries

## Recommended Architecture

Introduce a dictionary-library layer above package storage/catalog.

The package layer remains the source of truth for each dictionary's file layout and base metadata:

- `manifest.json`
- `source/`
- `resources/`
- `cache/`

The new library layer adds user-facing management state:

- display order
- hidden dictionary IDs
- auto-expand dictionary IDs
- selected dictionary ID

This management state is persisted separately from the package manifest so package import and library preferences can evolve independently.

## Storage Model

### Package Storage

Keep the existing package storage roots:

- `.../dictionaries/bundled/<id>/`
- `.../dictionaries/imported/<id>/`

Each package keeps `manifest.json`.

### Library Preferences

Add a new JSON file for persistent management preferences, for example:

- `.../dictionaries/library_preferences.json`

It stores:

- `displayOrder: List<String>`
- `hiddenIds: List<String>`
- `autoExpandIds: List<String>`
- `selectedDictionaryId: String?`

### Bundled Dictionary Registration

Add a bundled dictionary registration step that creates or synchronizes manifest-backed bundled dictionary packages in the same package root layout. Bundled dictionaries therefore become first-class members of the library rather than hardcoded UI rows.

## Domain Model

Add library-focused models:

- `DictionaryLibraryItem`
  - id
  - name
  - type
  - version
  - category
  - entryCount
  - dictionaryAttribute
  - fileSizeLabel / fileSizeBytes
  - isVisible
  - autoExpand
  - sortIndex

- `DictionaryLibraryPreferences`
  - displayOrder
  - hiddenIds
  - autoExpandIds
  - selectedDictionaryId

- `DictionaryLibraryDetail`
  - wraps the visible metadata required by the detail page

## Metadata Strategy

Dictionary detail fields should come from real sources where possible, with stable defaults when missing.

Field strategy:

- `词条数量`
  - use `manifest.entryCount`
- `词典类型`
  - map bundled/imported to:
    - `系统内置词典`
    - `用户自定义词典`
- `文件大小`
  - compute from package directory contents and cache if needed
- `词典属性`
  - default to `本地词典`
- `分类`
  - use manifest field if present, else `默认`
- `词库版本`
  - use manifest field if present, else bundled registry value, else a deterministic fallback such as import date

## UI Design

### Entry Point

Under `我的` page, inside `通用设置`, add:

- `词典库管理`

### Management Page

The management page mirrors the supplied mock:

- top title area
- search box for local filtering only
- `显示的词库` section
- `隐藏的词库` section with visible drop zone even when empty

Each row contains:

- dictionary icon
- dictionary name
- optional badge like `全文`
- chevron for detail
- drag handle

### Detail Page

The detail page includes:

- page title = dictionary name
- switches:
  - `显示该词库`
  - `自动展开`
- `词库信息` section
  - 词库版本
  - 分类
  - 词条数量
  - 词典属性
  - 文件大小
  - 词典类型

## Interaction Rules

- Only the drag handle initiates reorder intent.
- Dragging inside `显示的词库` reorders visible dictionaries.
- Dragging into `隐藏的词库` hides the dictionary.
- Dragging from hidden back to visible restores it.
- Tapping chevron opens the detail page.
- Turning off `显示该词库` in detail hides it immediately.
- Turning on `显示该词库` restores it to the end of the visible order.
- Toggling `自动展开` persists immediately.

## Runtime Behavior

Hidden dictionaries must not only be hidden in management UI. They must also be removed from actual usage entry points.

This applies to:

- dictionary switching UI
- any future dictionary chooser fed by the library layer
- search/dictionary usage entry points that enumerate available libraries

If the currently selected dictionary becomes hidden:

- automatically switch to the next visible dictionary
- if none exist, fall back to a no-visible-dictionaries state

## Persistence Rules

State changes persist immediately:

- reorder
- hide
- show
- auto-expand toggle
- active selection adjustments

The library UI must restore the same ordering and visibility after app restart.

## Testing Strategy

Tests should cover:

- preference serialization
- bundled dictionary registration
- merging package catalog + preferences into library items
- reorder persistence
- hide/show persistence
- detail toggle persistence
- active dictionary fallback when hidden
- settings entry navigation
- management page rendering and filtering
- detail page rendering

## Risks

- bundled dictionary manifests need a deterministic registration source
- current search flow is still centered on a single active dictionary, so “usage filtering” will initially have more visible effect in dictionary selection than in multi-source search
- drag-to-hidden interaction in Flutter needs a deliberate structure to remain testable and predictable

## Recommended Milestone

1. Add library preference persistence and library domain models.
2. Register bundled dictionaries as real package manifests.
3. Build a library repository that merges package metadata and preferences.
4. Add library management UI and detail UI.
5. Apply hidden/selection logic to real usage entry points.
