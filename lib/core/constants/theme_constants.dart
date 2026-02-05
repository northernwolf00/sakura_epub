/// Theme-related constants for Sakura EPUB Reader
library;

import 'package:flutter/material.dart';

/// Reading theme presets
class ThemeConstants {
  ThemeConstants._();

  /// Available reading themes
  static const List<String> availableThemes = [
    'light',
    'dark',
    'sepia',
    'night',
    'custom',
  ];

  /// Default theme
  static const String defaultTheme = 'light';

  /// Theme background colors
  static const Map<String, Color> themeBackgrounds = {
    'light': Color(0xFFFFFFFF),
    'dark': Color(0xFF1E1E1E),
    'sepia': Color(0xFFF4ECD8),
    'night': Color(0xFF000000),
  };

  /// Theme text colors
  static const Map<String, Color> themeTextColors = {
    'light': Color(0xFF000000),
    'dark': Color(0xFFE0E0E0),
    'sepia': Color(0xFF5F4B32),
    'night': Color(0xFFB0B0B0),
  };
}

/// Font constants
class FontConstants {
  FontConstants._();

  /// Available fonts
  static const List<String> availableFonts = [
    'NewYork',
    'Gilroy',
    'SFPro',
    'Alegreya',
    'Amazon Ember',
    'Atkinson Hyperlegible',
    'Bitter Pro',
    'Bookerly',
    'Droid Sans',
    'EB Garamond',
    'Gentium Book Plus',
    'Halant',
    'IBM Plex Sans',
    'LinLibertine',
    'Literata',
    'Lora',
    'Ubuntu',
  ];

  /// Default font family
  static const String defaultFont = 'Bookerly';

  /// Font size range
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultFontSize = 18.0;

  /// Line height range
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.0;
  static const double defaultLineHeight = 1.6;

  /// Letter spacing range
  static const double minLetterSpacing = -0.5;
  static const double maxLetterSpacing = 2.0;
  static const double defaultLetterSpacing = 0.0;
}
