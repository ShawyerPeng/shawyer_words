# Dictionary Package Import Design

**Date:** 2026-03-16

## Goal

Upgrade dictionary import from a single-`MDX` file flow to a package-based flow that supports:

- directory import
- archive import
- `MDX`
- `MDD`
- companion `js`, `css`, and other resource files

Imported dictionaries must be copied into app-managed storage so they remain usable after the user deletes the original source.

## Product Scope

The new import flow should support two dictionary sources:

- bundled dictionaries shipped with the app
- imported custom dictionaries added by the user

Both kinds of dictionaries should be managed through the same internal model, while remaining clearly separated in storage and in the UI.

## Storage Model

The app should no longer treat a dictionary as a single `.mdx` path. It should treat each dictionary as a package with its own isolated root directory.

Recommended structure:

- `app-data/dictionaries/bundled/<dictionary-id>/`
- `app-data/dictionaries/imported/<dictionary-id>/`

Each dictionary directory contains:

- `manifest.json`
- `source/`
- `resources/`
- `cache/`

`source/` stores:

- one primary `MDX`
- zero or more `MDD`
- any original source files that should remain attached to the package

`resources/` stores extracted or copied companion files such as:

- images
- audio
- `css`
- `js`
- other dictionary assets

`cache/` is reserved for indexes or processed metadata generated later.

## Domain Model

Introduce a package-level dictionary model rather than a single file-path import model.

Key concepts:

- `DictionaryPackage`
  - package identity and display name
  - type: `bundled` or `imported`
  - root path
  - primary `MDX` path
  - `MDD` paths
  - resource paths or resource root
  - import timestamp
  - status and entry count

- `DictionaryManifest`
  - persisted JSON file inside each package directory
  - records all package paths and metadata needed after restart

- `DictionaryCatalog`
  - enumerates available packages
  - distinguishes bundled vs imported packages
  - tracks the active dictionary package

## Import Flow

Import should use a staging directory and only publish a package when validation succeeds.

Recommended flow:

1. User selects a directory or archive.
2. App creates a temporary staging directory.
3. If the source is a directory, copy it into staging.
4. If the source is an archive, extract it into staging.
5. Scan the staged content for dictionary files and resources.
6. Validate that at least one primary `MDX` exists.
7. Build the normalized package layout:
   - `source/`
   - `resources/`
   - `cache/`
8. Generate `manifest.json`.
9. Perform a minimal parse/readability check against the chosen `MDX`.
10. Atomically move the staged package into the final app-managed dictionary directory.
11. Register the package in the dictionary catalog and optionally set it active.

## Validation Rules

Required:

- at least one readable `MDX`
- deterministic selection of the primary `MDX`
- clean package manifest

Supported but non-fatal:

- missing `MDD`
- missing `css`/`js`
- partial resource sets

Failure rules:

- no `MDX` found: fail import
- multiple ambiguous `MDX` files: fail import with a clear message
- parse check fails: fail import and clean staging

## Management Rules

Bundled and imported dictionaries must remain isolated.

Rules:

- bundled packages are read-only from the app’s perspective
- imported packages can be deleted and replaced
- deleting one imported package must not affect others
- all imported packages live under app-owned storage
- original external files are never required after import completes

## UI Changes

The dictionary import UI should stop describing the feature as “Import MDX Dictionary”.

It should instead describe package import, for example:

- import a dictionary folder
- import a dictionary archive
- supports `MDX`, `MDD`, and resource files

Future UI should also expose:

- dictionary package list
- bundled vs imported distinction
- active package selection
- delete imported package

## Architecture Recommendation

Use a filesystem-first approach with per-package `manifest.json` files.

Why:

- fits the current project scale
- keeps debugging straightforward
- matches the requirement for file isolation
- avoids introducing a heavy database layer too early

## Testing Strategy

Test the feature in layers:

- storage tests for package directory creation and manifest writing
- import tests for directory and archive handling
- failure tests for staging cleanup and invalid package rejection
- parser integration tests for package-based `MDX` selection
- controller/UI tests for import success, package listing, package switching, and deletion

## Risks

- iOS file-picker capabilities for selecting directories or archives may require platform-specific work
- archive extraction support may require an additional dependency or platform bridge
- some real-world dictionaries have inconsistent layouts and ambiguous primary `MDX` files

## Recommended Milestone

1. Introduce package storage and catalog abstractions.
2. Add directory/archive import into isolated app-managed storage.
3. Move parsing from single-file import to package import.
4. Update UI copy and import entry points.
5. Add bundled/imported package management.
