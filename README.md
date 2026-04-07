# sakura_epub

A powerful, feature-rich Flutter package for rendering EPUB books inside your app. Built on [epub.js](https://github.com/futurepress/epub.js/) and [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview), it gives you a complete in-app reading experience with a clean Dart API.

---

## Features

- **Full EPUB 2 & 3 support** — rendered natively via epub.js (no server required)
- **Flexible book sources** — load from local file, Flutter asset, or remote URL
- **Programmatic navigation** — next/prev, jump to CFI / XPath / chapter href, seek by percentage
- **Annotations** — add/remove highlights and underlines by CFI range
- **Full-text search** — returns a list of results with excerpts and CFI locations
- **Text selection callbacks** — with WebView-relative bounding rectangles
- **Live settings** — font size, theme, flow (paginated/scrolled), and spread changeable at runtime
- **Six built-in themes** — Light, Dark, Sepia, Tan, Grey, Mint (+ fully custom)
- **16 bundled reader fonts** — including Bookerly, Literata, Lora, New York, and more
- **Offline** — epub.js is bundled; no CDN dependency
- **Initial position restore** — resume reading from a saved CFI or XPath
- **Scripted content** — opt-in support for EPUB scripting

---

## Platform support

| Android | iOS | macOS | Web | Linux | Windows |
|:-------:|:---:|:-----:|:---:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sakura_epub: ^0.1.0
```

Then run:

```sh
flutter pub get
```

### Android setup

In `android/app/build.gradle` set `minSdk` to **21** or higher:

```gradle
android {
    defaultConfig {
        minSdk 21
    }
}
```

### iOS setup

In `ios/Podfile` set the platform to **12.0** or higher:

```ruby
platform :ios, '12.0'
```

---

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:sakura_epub/sakura_epub.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final EpubController _controller = EpubController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpubViewer(
        epubController: _controller,
        epubSource: EpubSource.fromAsset('assets/my_book.epub'),
        displaySettings: EpubDisplaySettings(
          fontSize: 18,
          theme: EpubTheme.sepia(),
          flow: EpubFlow.paginated,
          snap: true,
        ),
        onEpubLoaded: () => debugPrint('Book ready'),
        onRelocated: (loc) => debugPrint('Progress: ${loc.progress}'),
        onTextSelected: (sel) => debugPrint('Selected: ${sel.selectedText}'),
      ),
    );
  }
}
```

---

## Loading books

### From a Flutter asset

```dart
// pubspec.yaml: assets: [assets/my_book.epub]
EpubSource.fromAsset('assets/my_book.epub')
```

### From a local file

```dart
import 'dart:io';

final file = File('/storage/emulated/0/Download/my_book.epub');
EpubSource.fromFile(file)
```

### From a URL

```dart
EpubSource.fromUrl(
  'https://example.com/books/my_book.epub',
  headers: {'Authorization': 'Bearer $token'},
)
```

---

## EpubController

Create one controller per `EpubViewer`. Call its methods after `onEpubLoaded` fires.

### Navigation

```dart
_controller.next();           // next page
_controller.prev();           // previous page

_controller.display(cfi: 'epubcfi(/6/4[chap01]!/4/2/1:0)'); // by CFI
_controller.display(cfi: '/html/body/p[3]');                  // by XPath
_controller.display(cfi: 'chapter_001.xhtml');                // by chapter href

_controller.toProgressPercentage(0.42); // seek to 42 %
_controller.moveToFirstPage();
_controller.moveToLastPage();
```

### Location

```dart
final EpubLocation loc = await _controller.getCurrentLocation();
print(loc.progress);   // 0.0 – 1.0
print(loc.startCfi);
print(loc.startXpath);
```

### Chapters

```dart
// Available immediately after onChaptersLoaded callback
final List<EpubChapter> chapters = _controller.getChapters();

// Or fetch asynchronously at any time
final chapters = await _controller.parseChapters();

for (final ch in chapters) {
  print('${ch.title} → ${ch.href}');
}
```

### Metadata

```dart
final EpubMetadata meta = await _controller.getMetadata();
print(meta.title);
print(meta.creator);
```

### Search

```dart
final List<EpubSearchResult> results =
    await _controller.search(query: 'white rabbit');

for (final r in results) {
  print(r.excerpt);
  _controller.display(cfi: r.cfi); // jump to result
}
```

### Annotations

```dart
// Add a yellow highlight
_controller.addHighlight(
  cfi: selectionCfi,
  color: Colors.yellow,
  opacity: 0.4,
);

// Add an underline
_controller.addUnderline(cfi: selectionCfi);

// Remove
_controller.removeHighlight(cfi: selectionCfi);
_controller.removeUnderline(cfi: selectionCfi);

// Clear active text selection
_controller.clearSelection();
```

### Text extraction

```dart
// Current visible page
final EpubTextExtractRes page = await _controller.extractCurrentPageText();
print(page.text);

// Specific CFI range
final res = await _controller.extractText(
  startCfi: startCfi,
  endCfi: endCfi,
);
```

### Live appearance changes

```dart
_controller.setFontSize(fontSize: 20);
_controller.updateTheme(theme: EpubTheme.dark());
_controller.setFlow(flow: EpubFlow.scrolled);
_controller.setSpread(spread: EpubSpread.none);
```

---

## EpubDisplaySettings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fontSize` | `int` | `15` | Initial font size in px |
| `flow` | `EpubFlow` | `paginated` | `paginated` or `scrolled` |
| `spread` | `EpubSpread` | `auto` | `none`, `always`, `auto` |
| `snap` | `bool` | `true` | Enable swipe between pages |
| `manager` | `EpubManager` | `continuous` | epub.js manager |
| `defaultDirection` | `EpubDefaultDirection` | `ltr` | `ltr` or `rtl` |
| `allowScriptedContent` | `bool` | `false` | Allow EPUB scripts |
| `useSnapAnimationAndroid` | `bool` | `false` | Snap animation on Android |
| `theme` | `EpubTheme?` | `null` | Initial theme |

---

## Themes

Six ready-made themes:

```dart
EpubTheme.light()   // white background, black text
EpubTheme.dark()    // #121212 background, white text
EpubTheme.sepia()   // warm cream background
EpubTheme.tan()     // darker brownish background
EpubTheme.grey()    // dark grey background
EpubTheme.mint()    // soft green background
```

Custom theme:

```dart
EpubTheme.custom(
  backgroundDecoration: const BoxDecoration(color: Color(0xff1a1a2e)),
  foregroundColor: const Color(0xffe0e0e0),
  customCss: {
    'body': {'font-family': 'Georgia, serif', 'line-height': '1.8'},
    'p':    {'margin-bottom': '1em'},
  },
)
```

---

## EpubViewer callbacks

```dart
EpubViewer(
  epubController: _controller,
  epubSource: _source,

  // Position
  initialCfi: savedCfi,          // restore reading position from CFI
  initialXPath: savedXPath,      // restore from XPath/XPointer

  // Lifecycle
  onEpubLoaded: () { },
  onLocationLoaded: () { },      // progress values are now accurate
  onChaptersLoaded: (chapters) { },
  onRelocated: (location) { },

  // Position restore
  onInitialPositionLoading: (type) { },   // 'cfi' or 'xpath'
  onInitialPositionLoaded: () { },

  // Text selection
  onTextSelected: (EpubTextSelection sel) { },
  onSelection: (text, cfi, selectionRect, viewRect) { },
  onSelectionChanging: () { },   // hide custom UI while handles are dragged
  onDeselection: () { },

  // Annotations
  onAnnotationClicked: (cfi, rect) { },

  // Touch
  onTouchDown: (x, y) { },      // normalised 0.0 – 1.0
  onTouchUp: (x, y) { },

  // Behaviour flags
  suppressNativeContextMenu: true,
  clearSelectionOnPageChange: true,
  selectAnnotationRange: true,
)
```

---

## Bundled fonts

These font families are available for use in your Flutter app (declare `fontFamily:` in `TextStyle`):

| Family | File |
|--------|------|
| New York | `NewYork.ttf` |
| Gilroy | `Gilroy-Medium.ttf` |
| SF Pro | `SF-Pro.ttf` |
| Alegreya | `Alegreya.ttf` |
| Amazon Ember | `Amazon-Ember-Regular.ttf` |
| Atkinson Hyperlegible | `AtkinsonHyperlegible-Regular.ttf` |
| Bitter Pro | `BitterPro-Regular.ttf` |
| Bookerly | `Bookerly.ttf` |
| Droid Sans | `DroidSans.ttf` |
| EB Garamond | `EBGaramond-Var.ttf` |
| Gentium Book Plus | `GentiumBookPlus-Regular.ttf` |
| Halant | `Halant-Regular.ttf` |
| IBM Plex Sans | `IBMPlexSans-Regular.ttf` |
| Linux Libertine | `LinLibertine-Regular.ttf` |
| Literata | `Literata-Var.ttf` |
| Lora | `Lora-Var.ttf` |
| Ubuntu | `Ubuntu-Var.ttf` |

---

## Example app

A full example is in the [`example/`](example/) directory. It demonstrates:

- Immersive full-screen reader with tap-to-reveal controls
- Six theme swatches with live switching
- Font-size slider
- Chapter list bottom sheet
- Full-text search with result navigation
- Highlight annotation from text selection

Run it:

```sh
cd example
flutter pub get
flutter run
```

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a pull request

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) | WebView host |
| [http](https://pub.dev/packages/http) | URL-based EPUB downloading |
| [json_annotation](https://pub.dev/packages/json_annotation) | Model serialisation |

---

## License

[MIT](LICENSE) © 2026 northernwolf00
