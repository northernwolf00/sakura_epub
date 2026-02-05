/// Text manipulation utilities for Sakura EPUB Reader
library;

class TextUtils {
  TextUtils._();

  /// Truncate text to a maximum length
  static String truncate(String text,
      {int maxLength = 50, String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$ellipsis';
  }

  /// Remove HTML tags from text
  static String stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Count words in text
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Estimate reading time in minutes
  static int estimateReadingTime(String text, {int wordsPerMinute = 200}) {
    final wordCount = countWords(text);
    return (wordCount / wordsPerMinute).ceil();
  }

  /// Clean whitespace from text
  static String cleanWhitespace(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Capitalize first letter of each word
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Extract first N characters as preview
  static String getPreview(String text, {int length = 100}) {
    final cleaned = cleanWhitespace(stripHtmlTags(text));
    return truncate(cleaned, maxLength: length);
  }

  /// Check if text contains only whitespace
  static bool isWhitespace(String text) {
    return text.trim().isEmpty;
  }

  /// Normalize line breaks
  static String normalizeLineBreaks(String text) {
    return text.replaceAll(RegExp(r'\r\n|\r'), '\n');
  }
}
