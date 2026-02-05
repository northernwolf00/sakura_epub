/// Sakura EPUB - Public API Exports
/// This file consolidates all public exports for the package
library sakura_epub;

// Core exports
export 'core/constants/app_constants.dart';
export 'core/constants/theme_constants.dart';
export 'core/constants/storage_keys.dart';
export 'core/config/epub_config.dart';
export 'core/utils/text_utils.dart';
export 'core/utils/file_utils.dart';

// Model exports
export 'models/book_progress_model.dart';
// export 'models/chapter_model.dart';
// export 'models/bookmark_model.dart';
// export 'models/highlight_model.dart';
// export 'models/note_model.dart';
// export 'models/reader_settings_model.dart';

// Service exports (only public interfaces)
export 'services/storage/isar_service.dart';
// export 'services/epub/epub_parser_service.dart';
// export 'services/progress/progress_service.dart';

// Controller exports (for advanced usage)
// export 'controllers/reader_controller.dart';
// export 'controllers/theme_controller.dart';

// Main API
export 'sakura_epub.dart' show SakuraEpub;

/// Note: Commented exports are placeholders for future implementation
/// Uncomment as you create the corresponding files
