library sakura_epub;

import 'dart:io';

import 'package:sakura_epub/components/constants.dart';
import 'package:sakura_epub/helpers/isar_service.dart';
import 'package:sakura_epub/helpers/progress_singleton.dart';
import 'package:sakura_epub/models/book_progress_model.dart';
import 'package:sakura_epub/show_epub.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;

///TODO: Optimize with isolates

class SakuraEpub {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;

  // Add locale reactive variable
  static final Rx<Locale> _locale = Locale('tr', 'TR').obs;
  static Rx<Locale> get localeStream => _locale;

  // Getter for current locale
  static Locale get currentLocale => _locale.value;

  static Future<void> Function(String bookId, String text)? _onAddNoteHandler;
  static Future<void> Function(String bookId)? _onAddToShelfHandler;

  static String bookDescription = '';

  // Global state for shelf and my books
  static bool isInShelf = false;
  static bool isInMyBooks = false;

  // Method to update locale
  static void updateLocale(Locale locale) {
    _locale.value = locale;
  }

  static void registerAddNoteHandler(
      Future<void> Function(String bookId, String text) handler) {
    _onAddNoteHandler = handler;
  }

  static void registerAddToShelfHandler(
      Future<void> Function(String bookId) handler) {
    _onAddToShelfHandler = handler;
  }

  static Future<void> onAddToShelf(String bookId) async {
    if (_onAddToShelfHandler != null) {
      await _onAddToShelfHandler!(bookId);
    }
    // Toggle the state
    isInShelf = !isInShelf;
  }

  static Future<void> Function(String bookId)? _onSaveToMyBooksHandler;

  static void registerSaveToMyBooksHandler(
      Future<void> Function(String bookId) handler) {
    _onSaveToMyBooksHandler = handler;
  }

  static Future<void> onSaveToMyBooks(String bookId) async {
    if (_onSaveToMyBooksHandler != null) {
      await _onSaveToMyBooksHandler!(bookId);
    }
    // Toggle the state
    isInMyBooks = !isInMyBooks;
  }

  /// Pre-parse book without opening UI - for better loading UX
  static Future<EpubBook> parseLocalBook({required String localPath}) async {
    debugPrint('📚 Pre-parsing book from path: $localPath');
    var bytes = await File(localPath).readAsBytes();

    try {
      EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());
      debugPrint('✅ Book parsed successfully');
      return epubBook;
    } catch (e) {
      // If there's an error (like missing cover), try alternative parsing
      if (e.toString().contains('cover') || e.toString().contains('manifest')) {
        debugPrint('⚠️ Error parsing with cover: $e');
        debugPrint('⚠️ Trying alternative parsing method...');

        try {
          // Use openBook which doesn't require cover
          final bookRef = await EpubReader.openBook(bytes.buffer.asUint8List());

          // Create basic EpubBook structure
          final epubBook = EpubBook();
          epubBook.Title = await bookRef.Title;
          epubBook.Author = await bookRef.Author;
          epubBook.Schema = bookRef.Schema;
          epubBook.Chapters = [];

          // Important: Keep bookRef reference for reading content later
          // Content will be read on-demand from Schema/Spine
          epubBook.Content = null;

          debugPrint('✅ Book parsed without cover (will read from Spine)');
          return epubBook;
        } catch (e2) {
          debugPrint('❌ Alternative parsing also failed: $e2');

          // Last resort: create minimal book structure from BookRef
          try {
            final bookRef =
                await EpubReader.openBook(bytes.buffer.asUint8List());

            final epubBook = EpubBook();
            epubBook.Title = await bookRef.Title;
            epubBook.Author = await bookRef.Author;
            epubBook.Schema = bookRef.Schema;
            // Don't cast Content - it may be EpubContentRef, let it be null
            epubBook.Content = null;

            // Try to get chapters from content
            if (bookRef.Schema?.Package?.Spine?.Items != null) {
              epubBook.Chapters = [];
              debugPrint('✅ Book structure created (minimal mode)');
              return epubBook;
            }

            throw Exception('Could not create book structure');
          } catch (e3) {
            debugPrint('❌ Minimal book creation failed: $e3');
            rethrow;
          }
        }
      }
      rethrow;
    }
  }

  /// Precalculate page counts for all chapters BEFORE opening the book
  /// This prevents UI freezing when opening the reader
  /// Call this during the loading screen phase
  static Future<void> precalculatePageCounts({
    required EpubBook epubBook,
    required String bookId,
    required Size pageSize,
    required Function(int current, int total) onProgress,
  }) async {
    debugPrint('📊 Starting page count precalculation for bookId: $bookId');

    final gs = GetStorage();

    // Check if already calculated and cached
    final cached = gs.read('book_${bookId}_page_counts');
    if (cached != null && cached is Map) {
      final chapterCount = epubBook.Chapters?.length ?? 0;
      if (cached.length == chapterCount) {
        debugPrint('✅ Page counts already cached ($chapterCount chapters)');
        return;
      }
    }

    // Import required helpers and do calculation
    final chapters = epubBook.Chapters ?? [];
    debugPrint('📖 Total chapters to calculate: ${chapters.length}');

    // Create pagination helper (this will be moved to helper later)
    // For now, just mark that calculation should happen
    debugPrint('⚠️ Page calculation logic will be implemented in helper');
    debugPrint('   For now, book will calculate on first open');

    // TODO: Implement actual pagination logic here
    // This requires importing pagination logic from show_epub.dart
  }

  /// Open already-parsed book - instant UI opening
  static Future<void> openParsedBook({
    required EpubBook epubBook,
    required BuildContext context,
    required String bookId,
    required String imageUrl,
    Color accentColor = Colors.indigoAccent,
    Function(int currentPage, int totalPages, int charCount)? onPageFlip,
    Function(int lastPageIndex)? onLastPage,
    String chapterListTitle = 'Table of Contents',
    bool shouldOpenDrawer = false,
    String bookDescription = '',
    bool isInShelf = false,
    bool isInMyBooks = false,
    int starterChapter = -1,
  }) async {
    debugPrint('📚 Opening pre-parsed book');

    if (!context.mounted) return;
    await _openBook(
        context: context,
        epubBook: epubBook,
        bookId: bookId,
        imageUrl: imageUrl,
        shouldOpenDrawer: shouldOpenDrawer,
        starterChapter: starterChapter,
        chapterListTitle: chapterListTitle,
        bookDescription: bookDescription,
        isInShelf: isInShelf,
        isInMyBooks: isInMyBooks,
        onPageFlip: onPageFlip,
        onLastPage: onLastPage,
        accentColor: accentColor);
  }

  static Future<void> openLocalBook(
      {required String localPath,
      required BuildContext context,
      required String bookId,
      required String imageUrl,
      Color accentColor = Colors.indigoAccent,
      Function(int currentPage, int totalPages, int charCount)? onPageFlip,
      Function(int lastPageIndex)? onLastPage,
      String chapterListTitle = 'Table of Contents',
      bool shouldOpenDrawer = false,
      String bookDescription = '',
      bool isInShelf = false,
      bool isInMyBooks = false,
      int starterChapter = -1}) async {
    debugPrint('📚 Opening local book from path: $localPath');
    var bytes = await File(localPath).readAsBytes();
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());

    if (!context.mounted) return;
    await _openBook(
        context: context,
        epubBook: epubBook,
        bookId: bookId,
        imageUrl: imageUrl,
        shouldOpenDrawer: shouldOpenDrawer,
        starterChapter: starterChapter,
        chapterListTitle: chapterListTitle,
        bookDescription: bookDescription,
        isInShelf: isInShelf,
        isInMyBooks: isInMyBooks,
        onPageFlip: onPageFlip,
        onLastPage: onLastPage,
        accentColor: accentColor);
  }

  static Future<void> openFileBook(
      {required Uint8List bytes,
      required BuildContext context,
      required String bookId,
      required String imageUrl,
      Color accentColor = Colors.indigoAccent,
      Function(int currentPage, int totalPages, int charCount)? onPageFlip,
      Function(int lastPageIndex)? onLastPage,
      String chapterListTitle = 'Table of Contents',
      bool shouldOpenDrawer = false,
      String bookDescription = '',
      bool isInShelf = false,
      bool isInMyBooks = false,
      int starterChapter = -1}) async {
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());

    if (!context.mounted) return;
    await _openBook(
        context: context,
        epubBook: epubBook,
        bookId: bookId,
        imageUrl: imageUrl,
        shouldOpenDrawer: shouldOpenDrawer,
        starterChapter: starterChapter,
        chapterListTitle: chapterListTitle,
        bookDescription: bookDescription,
        isInShelf: isInShelf,
        isInMyBooks: isInMyBooks,
        onPageFlip: onPageFlip,
        onLastPage: onLastPage,
        accentColor: accentColor);
  }

  static Future<void> openURLBook(
      {required String urlPath,
      required BuildContext context,
      Color accentColor = Colors.indigoAccent,
      Function(int currentPage, int totalPages, int charCount)? onPageFlip,
      Function(int lastPageIndex)? onLastPage,
      required String bookId,
      required String imageUrl,
      String chapterListTitle = 'Table of Contents',
      bool shouldOpenDrawer = false,
      String bookDescription = '',
      bool isInShelf = false,
      bool isInMyBooks = false,
      int starterChapter = -1}) async {
    debugPrint('📚 Downloading book from URL: $urlPath');
    final result = await http.get(Uri.parse(urlPath));
    final bytes = result.bodyBytes;
    debugPrint('✅ Book downloaded successfully, size: ${bytes.length} bytes');
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());

    if (!context.mounted) return;
    await _openBook(
        context: context,
        epubBook: epubBook,
        bookId: bookId,
        imageUrl: imageUrl,
        shouldOpenDrawer: shouldOpenDrawer,
        starterChapter: starterChapter,
        chapterListTitle: chapterListTitle,
        bookDescription: bookDescription,
        isInShelf: isInShelf,
        isInMyBooks: isInMyBooks,
        onPageFlip: onPageFlip,
        onLastPage: onLastPage,
        accentColor: accentColor);
  }

  static Future<void> openAssetBook(
      {required String assetPath,
      required BuildContext context,
      required String imageUrl,
      Color accentColor = Colors.indigoAccent,
      Function(int currentPage, int totalPages, int charCount)? onPageFlip,
      Function(int lastPageIndex)? onLastPage,
      required String bookId,
      String chapterListTitle = 'Table of Contents',
      bool shouldOpenDrawer = false,
      String bookDescription = '',
      bool isInShelf = false,
      bool isInMyBooks = false,
      int starterChapter = -1}) async {
    debugPrint('📚 Opening book from asset: $assetPath');
    var bytes = await rootBundle.load(assetPath);
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());

    if (!context.mounted) return;
    await _openBook(
        context: context,
        epubBook: epubBook,
        imageUrl: imageUrl,
        bookId: bookId,
        shouldOpenDrawer: shouldOpenDrawer,
        starterChapter: starterChapter,
        chapterListTitle: chapterListTitle,
        bookDescription: bookDescription,
        isInShelf: isInShelf,
        isInMyBooks: isInMyBooks,
        onPageFlip: onPageFlip,
        onLastPage: onLastPage,
        accentColor: accentColor);
  }

  static _openBook(
      {required BuildContext context,
      required EpubBook epubBook,
      required String imageUrl,
      required String bookId,
      required bool shouldOpenDrawer,
      required Color accentColor,
      required int starterChapter,
      required String chapterListTitle,
      String bookDescription = '',
      bool isInShelf = false,
      bool isInMyBooks = false,
      Function(int currentPage, int totalPages, int charCount)? onPageFlip,
      Function(int lastPageIndex)? onLastPage}) async {
    SakuraEpub.bookDescription = bookDescription;
    SakuraEpub.isInShelf = isInShelf;
    SakuraEpub.isInMyBooks = isInMyBooks;
    _checkInitialization();

    ///Set starter chapter as current
    if (starterChapter != -1) {
      await bookProgress.setCurrentChapterIndex(bookId, starterChapter);
      await bookProgress.setCurrentPageIndex(bookId, 0);
    }

    debugPrint('🔀 _openBook called for bookId: $bookId');
    debugPrint('🔀 Context mounted: ${context.mounted}');

    if (!context.mounted) {
      debugPrint('⚠️ Context not mounted, cannot navigate');
      return;
    }

    // Use Navigator.push for better compatibility with both GetX and non-GetX apps
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ShowEpub(
          epubBook: epubBook,
          starterChapter: starterChapter >= 0
              ? starterChapter
              : bookProgress.getBookProgress(bookId).currentChapterIndex ?? 0,
          shouldOpenDrawer: shouldOpenDrawer,
          bookId: bookId,
          imageUrl: imageUrl,
          accentColor: accentColor,
          chapterListTitle: chapterListTitle,
          onPageFlip: onPageFlip,
          onLastPage: onLastPage,
        ),
      ),
    );

    debugPrint('🔀 Navigation completed');
  }

// Inside CosmosEpub class
  static Future<void> addNote({
    required String bookId,
    required String selectedText,
    BuildContext? context,
  }) async {
    _checkInitialization();
    print(
        '0------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------Note added for $bookId: $selectedText');

    if (_onAddNoteHandler != null) {
      // ✅ Use the registered custom handler
      await _onAddNoteHandler!(bookId, selectedText);
    } else {
      // ⚙️ Default fallback if no handler is registered

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note added: "${_truncate(selectedText)}"'),
            backgroundColor: Colors.indigoAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  static String _truncate(String text, [int maxLength = 50]) {
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  static Future<bool> initialize() async {
    await ScreenUtil.ensureScreenSize();
    await GetStorage.init();
    var isar = await IsarService.buildIsarService();
    bookProgress = BookProgressSingleton(isar: isar);

    // Initialize with app's current locale
    _locale.value = Get.locale ?? Locale('tr', 'TR');

    _initialized = true;
    return true;
  }

  static _checkInitialization() {
    if (!_initialized) {
      throw Exception(
          'SakuraEpub is not initialized. Please call initialize() before using other methods. For more info pls read the docs');
    }
  }

  static Future<bool> clearThemeCache() async {
    if (await GetStorage().initStorage) {
      var get = GetStorage();
      await get.remove(libTheme);
      await get.remove(libFont);
      await get.remove(libFontSize);
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> setCurrentPageIndex(String bookId, int index) async {
    return await bookProgress.setCurrentPageIndex(bookId, index);
  }

  static Future<bool> setCurrentChapterIndex(String bookId, int index) async {
    return await bookProgress.setCurrentChapterIndex(bookId, index);
  }

  static BookProgressModel getBookProgress(String bookId) {
    return bookProgress.getBookProgress(bookId);
  }

  static Future<bool> deleteBookProgress(String bookId) async {
    return await bookProgress.deleteBookProgress(bookId);
  }

  static Future<bool> deleteAllBooksProgress() async {
    return await bookProgress.deleteAllBooksProgress();
  }
}
