/// Application-wide constants for Sakura EPUB Reader
library;

/// Default values for the EPUB reader
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  /// Default page transition duration
  static const Duration defaultPageTransitionDuration =
      Duration(milliseconds: 300);

  /// Default animation curve
  static const String defaultAnimationCurve = 'ease-in-out';

  /// Maximum cache size in MB
  static const int maxCacheSizeMB = 100;

  /// Default timeout for network requests
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Supported EPUB versions
  static const List<String> supportedEpubVersions = ['2.0', '3.0', '3.1'];

  /// Default book cover placeholder
  static const String defaultCoverPlaceholder =
      'assets/images/book_placeholder.png';
}

/// File and directory constants
class FileConstants {
  FileConstants._();

  /// EPUB file extension
  static const String epubExtension = '.epub';

  /// Cache directory name
  static const String cacheDirectoryName = 'sakura_epub_cache';

  /// Downloads directory name
  static const String downloadsDirectoryName = 'sakura_epub_downloads';

  /// Maximum file name length
  static const int maxFileNameLength = 255;
}

/// UI Constants
class UIConstants {
  UIConstants._();

  /// Default padding
  static const double defaultPadding = 16.0;

  /// Small padding
  static const double smallPadding = 8.0;

  /// Large padding
  static const double largePadding = 24.0;

  /// Default border radius
  static const double defaultBorderRadius = 12.0;

  /// Default icon size
  static const double defaultIconSize = 24.0;

  /// Minimum tap target size (accessibility)
  static const double minTapTargetSize = 48.0;
}
