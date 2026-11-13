# Standalone Geogram integration

This branch retains the merge into BrunoLevy/ImGuiColorTextEdit_geogram `master`
(`062408b`) and now merges goossens `master` (`9f812a0`). Both histories are
preserved without rebasing. ALT packaging stays on a separate branch.

## Editor core

The editor no longer contains Geogram-specific callbacks, cursor helpers,
UI state or preprocessor conditions. The historical tab-rendering implementation
was also removed: upstream now provides `SetShortTabsEnabled()` and
`IsShortTabsEnabled()` on both editor and diff widgets.

The remaining core differences retain Bruno's Emscripten cursor-member names,
Apple macro guard and transaction-parameter warning fixes, plus independent
shared-library exports through `TEXTEDITOR_API`.

## Application integration

The companion Geogram branch handles its F5 application shortcut next to
`Render()`, restricted to the focused editor window. It uses `SetCursor(DocPos)`
and `LookupLanguage("Lua")`; unused legacy helpers and action notifications are
not carried into the library.

Other integrations can use the general upstream interfaces:

| Requirement | Upstream interface |
| --- | --- |
| Detailed changes, including undo/redo | `SetTransactionCallback()` |
| Aggregated changes with optional delay | `SetChangeCallback()` |
| Hover tooltips | `SetTextHoverCallback()` |
| Language-specific completion context | `GetContext(DocPos, predicate)` |
| Find/replace button labels | `SetFindCloseButtonLabel()` and the other label setters |
| Transactional replacement or insertion | `ReplaceAllText()`, `ReplaceSectionText()`, `InsertSectionText()` |
| Cursor and selection access | `SetCursor()`, `GetMainCursorSelection()`, `GetCursorText()` |

`SetText()` resets the document and undo state without creating a transaction;
use the transactional APIs when a transaction notification is needed. Host
applications own their keyboard shortcuts, fonts, icons and action handlers.
No Geogram headers or symbols are required by the editor.

## Building

Provide an existing `imgui` / `imgui::imgui` target or an installed `imgui`
CMake package. The editor requires C++17 and the same ImGui configuration as its
consumers. `BUILD_SHARED_LIBS` defaults to `ON`; `BUILD_TESTING` defaults to `OFF`.
Enable `BUILD_TESTING` and run CTest for the native upstream-API regression checks.
Installed consumers use `find_package(ImGuiColorTextEdit CONFIG REQUIRED)` and
link `ImGuiColorTextEdit::ImGuiColorTextEdit`. There are no fork-specific feature
options or public feature macros to synchronize between library and consumers.
