/// EPUB Reader configuration
library;

import 'package:flutter/material.dart';

/// Configuration class for EPUB reader behavior
class EpubConfig {
  /// Enable page flip animations
  final bool enablePageFlipAnimation;

  /// Enable haptic feedback
  final bool enableHapticFeedback;

  /// Enable auto-save progress
  final bool enableAutoSaveProgress;

  /// Auto-save interval in seconds
  final int autoSaveIntervalSeconds;

  /// Enable text selection
  final bool enableTextSelection;

  /// Enable image zoom
  final bool enableImageZoom;

  /// Default accent color
  final Color defaultAccentColor;

  /// Enable chapter preloading
  final bool enableChapterPreloading;

  /// Number of chapters to preload
  final int preloadChapterCount;

  /// Enable reading statistics
  final bool enableReadingStats;

  /// Enable night mode auto-switch
  final bool enableAutoNightMode;

  /// Night mode start time (24-hour format)
  final TimeOfDay nightModeStartTime;

  /// Night mode end time (24-hour format)
  final TimeOfDay nightModeEndTime;

  const EpubConfig({
    this.enablePageFlipAnimation = true,
    this.enableHapticFeedback = true,
    this.enableAutoSaveProgress = true,
    this.autoSaveIntervalSeconds = 5,
    this.enableTextSelection = true,
    this.enableImageZoom = true,
    this.defaultAccentColor = Colors.indigoAccent,
    this.enableChapterPreloading = true,
    this.preloadChapterCount = 2,
    this.enableReadingStats = true,
    this.enableAutoNightMode = false,
    this.nightModeStartTime = const TimeOfDay(hour: 20, minute: 0),
    this.nightModeEndTime = const TimeOfDay(hour: 7, minute: 0),
  });

  /// Create a copy with modified values
  EpubConfig copyWith({
    bool? enablePageFlipAnimation,
    bool? enableHapticFeedback,
    bool? enableAutoSaveProgress,
    int? autoSaveIntervalSeconds,
    bool? enableTextSelection,
    bool? enableImageZoom,
    Color? defaultAccentColor,
    bool? enableChapterPreloading,
    int? preloadChapterCount,
    bool? enableReadingStats,
    bool? enableAutoNightMode,
    TimeOfDay? nightModeStartTime,
    TimeOfDay? nightModeEndTime,
  }) {
    return EpubConfig(
      enablePageFlipAnimation:
          enablePageFlipAnimation ?? this.enablePageFlipAnimation,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableAutoSaveProgress:
          enableAutoSaveProgress ?? this.enableAutoSaveProgress,
      autoSaveIntervalSeconds:
          autoSaveIntervalSeconds ?? this.autoSaveIntervalSeconds,
      enableTextSelection: enableTextSelection ?? this.enableTextSelection,
      enableImageZoom: enableImageZoom ?? this.enableImageZoom,
      defaultAccentColor: defaultAccentColor ?? this.defaultAccentColor,
      enableChapterPreloading:
          enableChapterPreloading ?? this.enableChapterPreloading,
      preloadChapterCount: preloadChapterCount ?? this.preloadChapterCount,
      enableReadingStats: enableReadingStats ?? this.enableReadingStats,
      enableAutoNightMode: enableAutoNightMode ?? this.enableAutoNightMode,
      nightModeStartTime: nightModeStartTime ?? this.nightModeStartTime,
      nightModeEndTime: nightModeEndTime ?? this.nightModeEndTime,
    );
  }
}
