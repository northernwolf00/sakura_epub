/// Storage key constants for Sakura EPUB Reader
/// Used for GetStorage and Isar database keys
library;

/// GetStorage keys for user preferences
class StorageKeys {
  StorageKeys._();

  /// Theme preference key
  static const String theme = 'sakura_epub_theme';

  /// Font family preference key
  static const String fontFamily = 'sakura_epub_font_family';

  /// Font size preference key
  static const String fontSize = 'sakura_epub_font_size';

  /// Line height preference key
  static const String lineHeight = 'sakura_epub_line_height';

  /// Letter spacing preference key
  static const String letterSpacing = 'sakura_epub_letter_spacing';

  /// Brightness preference key
  static const String brightness = 'sakura_epub_brightness';

  /// Auto-brightness preference key
  static const String autoBrightness = 'sakura_epub_auto_brightness';

  /// Locale preference key
  static const String locale = 'sakura_epub_locale';

  /// Last opened book key
  static const String lastOpenedBook = 'sakura_epub_last_opened_book';

  /// Reading statistics key
  static const String readingStats = 'sakura_epub_reading_stats';

  /// Page counts cache key prefix
  static String bookPageCounts(String bookId) => 'book_${bookId}_page_counts';

  /// Chapter cache key prefix
  static String bookChapterCache(String bookId) => 'book_${bookId}_chapters';

  /// Book metadata cache key prefix
  static String bookMetadata(String bookId) => 'book_${bookId}_metadata';
}

/// Isar collection names
class IsarCollections {
  IsarCollections._();

  /// Book progress collection
  static const String bookProgress = 'BookProgress';

  /// Bookmarks collection
  static const String bookmarks = 'Bookmarks';

  /// Highlights collection
  static const String highlights = 'Highlights';

  /// Notes collection
  static const String notes = 'Notes';

  /// Reading statistics collection
  static const String readingStats = 'ReadingStats';
}
