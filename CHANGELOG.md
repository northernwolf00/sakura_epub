# Changelog

All notable changes to **sakura_epub** will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] — 2026-04-07

### Added
- **`EpubViewer` widget** — full-featured EPUB rendering via embedded WebView (epub.js + flutter_inappwebview)
- **`EpubController`** — programmatic control of the viewer
  - `next()` / `prev()` — page navigation
  - `display(cfi)` — jump to CFI string, XPath/XPointer, or chapter href
  - `toProgressPercentage(double)` — seek by percentage (0.0–1.0)
  - `moveToFirstPage()` / `moveToLastPage()`
  - `getCurrentLocation()` — returns current `EpubLocation` with CFI + progress
  - `getChapters()` / `parseChapters()` — chapter list access
  - `getMetadata()` — returns `EpubMetadata` (title, author, etc.)
  - `search(query)` — full-text search returning `List<EpubSearchResult>`
  - `addHighlight(cfi, color, opacity)` — add colour highlight annotation
  - `addUnderline(cfi)` — add underline annotation
  - `removeHighlight(cfi)` / `removeUnderline(cfi)` — remove annotations
  - `clearSelection()` — clear active text selection
  - `extractText(startCfi, endCfi)` — extract text from CFI range
  - `extractCurrentPageText()` — extract visible page text
  - `getRectFromCfi(cfiRange)` — get bounding rect for a CFI range
  - `setFontSize(fontSize)` — live font-size adjustment
  - `setFlow(flow)` — switch between `paginated` and `scrolled`
  - `setSpread(spread)` — control page spread
  - `setManager(manager)` — set epub.js manager
  - `updateTheme(theme)` — live theme switching
- **`EpubSource`** — flexible book loading
  - `EpubSource.fromFile(File)` — local file system
  - `EpubSource.fromUrl(String, {headers})` — remote URL with optional headers
  - `EpubSource.fromAsset(String)` — Flutter asset bundle
- **`EpubDisplaySettings`** — initial reader configuration
  - `fontSize`, `flow`, `spread`, `snap`, `manager`, `defaultDirection`
  - `allowScriptedContent` — opt-in EPUB scripting support
  - `useSnapAnimationAndroid` — snap animation toggle (Android)
  - `theme` — initial `EpubTheme`
- **`EpubTheme`** — six built-in themes with factory constructors
  - `EpubTheme.light()`, `dark()`, `sepia()`, `tan()`, `grey()`, `mint()`
  - `EpubTheme.custom(backgroundDecoration, foregroundColor, customCss)`
  - Background color is correctly extracted from `BoxDecoration` and applied to epub.js content
- **`EpubLocation`** — position model (`startCfi`, `endCfi`, `startXpath`, `endXpath`, `progress`)
- **`EpubChapter`** — chapter model (`title`, `href`, `subitems`)
- **`EpubSearchResult`** — search result model (`cfi`, `excerpt`)
- **`EpubTextSelection`** — selection model (`selectedText`, `selectionCfi`, `selectionXpath`)
- **`EpubTextExtractRes`** — text extraction model (`text`, `cfiRange`, `xpathRange`)
- **`EpubMetadata`** — book metadata model
- **Callbacks on `EpubViewer`**
  - `onEpubLoaded` — fires when book is rendered and ready
  - `onLocationLoaded` — fires when location map is generated (progress available)
  - `onChaptersLoaded(List<EpubChapter>)` — fires when chapter list is parsed
  - `onRelocated(EpubLocation)` — fires on every page change
  - `onTextSelected(EpubTextSelection)` — fires on text selection
  - `onSelection(text, cfi, selectionRect, viewRect)` — fires with WebView-relative coordinates
  - `onSelectionChanging` — fires while user drags selection handles
  - `onDeselection` — fires when selection is cleared
  - `onAnnotationClicked(cfi, rect)` — fires when user taps a highlight or underline
  - `onInitialPositionLoading(type)` — fires when restoring saved position
  - `onInitialPositionLoaded` — fires when position restore is complete
  - `onTouchDown(x, y)` / `onTouchUp(x, y)` — normalized touch coordinates
- **Initial position restore** — `initialCfi` and `initialXPath` parameters
- **`clearSelectionOnPageChange`** — auto-clear selection on navigation (default `true`)
- **`selectAnnotationRange`** — auto-select text when annotation is clicked
- **`suppressNativeContextMenu`** — hide the native long-press context menu
- **`selectionContextMenu`** — custom `ContextMenu` for text selection
- **Base64 EPUB loading** — large files are base64-encoded before passing to the WebView, reducing the JavaScript string size by ~55% compared to byte-array serialisation
- **Bundled reader fonts** — 16 font families available for app-level use
  - New York, Gilroy, SF Pro, Alegreya, Amazon Ember, Atkinson Hyperlegible, Bitter Pro, Bookerly, Droid Sans, EB Garamond, Gentium Book Plus, Halant, IBM Plex Sans, Linux Libertine, Literata, Lora, Ubuntu
- **epub.js** bundled at `lib/assets/webpage/` — no CDN dependency, works offline

### Fixed
- Asset path corrected from `packages/flutter_epub_viewer/...` to `packages/sakura_epub/...`
- Font declarations in `pubspec.yaml` updated from non-existent `assets/fonts/` to correct `lib/assets/fonts/`
- `backgroundColor` is now properly extracted from `EpubTheme.backgroundDecoration` and forwarded to epub.js `updateTheme()` — fixes black screen on dark-background themes
- `updateTheme()` on `EpubController` now also passes background color correctly

---

## [0.0.1] — 2026-04-06

### Added
- Initial project scaffold
- Basic EPUB viewer shell with flutter_inappwebview
- epub.js integration
