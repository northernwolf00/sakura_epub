import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:iconly/iconly.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SakuraApp());
}

// ── Theme data ──────────────────────────────────────────────────────────────

class _ThemeOption {
  final EpubThemeType type;
  final String label;
  final Color bg;
  final Color fg;
  final Color swatch;
  final Color accent;

  const _ThemeOption({
    required this.type,
    required this.label,
    required this.bg,
    required this.fg,
    required this.swatch,
    required this.accent,
  });
}

const _themes = [
  _ThemeOption(
    type: EpubThemeType.light,
    label: 'Light',
    bg: Color(0xffffffff),
    fg: Color(0xff1a1a1a),
    swatch: Color(0xfff5f5f5),
    accent: Color(0xffE5989B),
  ),
  _ThemeOption(
    type: EpubThemeType.sepia,
    label: 'Sepia',
    bg: Color(0xfff4ecd8),
    fg: Color(0xff5b4636),
    swatch: Color(0xfff4ecd8),
    accent: Color(0xffB5838D),
  ),
  _ThemeOption(
    type: EpubThemeType.tan,
    label: 'Tan',
    bg: Color(0xffdfd4b8),
    fg: Color(0xff3e3025),
    swatch: Color(0xffdfd4b8),
    accent: Color(0xff6D6875),
  ),
  _ThemeOption(
    type: EpubThemeType.mint,
    label: 'Mint',
    bg: Color(0xffe8f5e9),
    fg: Color(0xff2d3e2d),
    swatch: Color(0xffe8f5e9),
    accent: Color(0xff4A6D4A),
  ),
  _ThemeOption(
    type: EpubThemeType.grey,
    label: 'Grey',
    bg: Color(0xff333333),
    fg: Color(0xffcccccc),
    swatch: Color(0xff444444),
    accent: Color(0xffE5989B),
  ),
  _ThemeOption(
    type: EpubThemeType.dark,
    label: 'Dark',
    bg: Color(0xff121212),
    fg: Color(0xffe0e0e0),
    swatch: Color(0xff1e1e1e),
    accent: Color(0xffB5838D),
  ),
];

_ThemeOption _optionFor(EpubThemeType t) =>
    _themes.firstWhere((o) => o.type == t, orElse: () => _themes.first);
const _fonts = [
  'SFPro',
  'NewYork',
  'Gilroy',
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

EpubTheme _epubThemeFor(EpubThemeType t, String font) {
  final customCss = {
    'body': {
      'font-family': "'$font', sans-serif !important",
    },
  };

  switch (t) {
    case EpubThemeType.dark:
      return EpubTheme.dark()..customCss = customCss;
    case EpubThemeType.sepia:
      return EpubTheme.sepia()..customCss = customCss;
    case EpubThemeType.tan:
      return EpubTheme.tan()..customCss = customCss;
    case EpubThemeType.grey:
      return EpubTheme.grey()..customCss = customCss;
    case EpubThemeType.mint:
      return EpubTheme.mint()..customCss = customCss;
    default:
      return EpubTheme.light()..customCss = customCss;
  }
}

// ── App root ─────────────────────────────────────────────────────────────────

class SakuraApp extends StatefulWidget {
  const SakuraApp({super.key});

  @override
  State<SakuraApp> createState() => _SakuraAppState();
}

class _SakuraAppState extends State<SakuraApp> {
  EpubThemeType _themeType = EpubThemeType.light;
  String _fontFamily = 'SFPro';

  void _onSettingsChanged(EpubThemeType t, String f) {
    setState(() {
      _themeType = t;
      _fontFamily = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final opt = _optionFor(_themeType);
    final isDark =
        _themeType == EpubThemeType.dark || _themeType == EpubThemeType.grey;

    return MaterialApp(
      title: 'Sakura Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: opt.accent,
          brightness: isDark ? Brightness.dark : Brightness.light,
          surface: isDark ? const Color(0xff1c1c1e) : Colors.white,
        ),
        fontFamily: _fontFamily,
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: opt.accent.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      home: ReaderPage(
        themeType: _themeType,
        fontFamily: _fontFamily,
        onSettingsChanged: _onSettingsChanged,
      ),
    );
  }
}

// ── Reader page ───────────────────────────────────────────────────────────────

class ReaderPage extends StatefulWidget {
  final EpubThemeType themeType;
  final String fontFamily;
  final void Function(EpubThemeType, String) onSettingsChanged;

  const ReaderPage({
    super.key,
    required this.themeType,
    required this.fontFamily,
    required this.onSettingsChanged,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    with SingleTickerProviderStateMixin {
  final EpubController _ctrl = EpubController();
  final EpubSource _src =
      EpubSource.fromAsset('assets/herbert-old-rambling-house.epub');

  // State
  bool _loaded = false;
  bool _barsVisible = true;
  List<EpubChapter> _chapters = [];
  EpubLocation? _location;
  double _fontSize = 18;
  String _selectedText = '';
  String _selectedCfi = '';

  late final AnimationController _barAnim;
  late final Animation<double> _barFade;

  @override
  void initState() {
    super.initState();
    _barAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _barFade = CurvedAnimation(parent: _barAnim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _barAnim.dispose();
    super.dispose();
  }

  _ThemeOption get _opt => _optionFor(widget.themeType);
  bool get _isDark =>
      widget.themeType == EpubThemeType.dark ||
      widget.themeType == EpubThemeType.grey;

  void _toggleBars() {
    if (_barsVisible) {
      _barAnim.reverse().then((_) => setState(() => _barsVisible = false));
    } else {
      setState(() => _barsVisible = true);
      _barAnim.forward();
    }
  }

  void _switchTheme(EpubThemeType t) {
    widget.onSettingsChanged(t, widget.fontFamily);
    _ctrl.updateTheme(theme: _epubThemeFor(t, widget.fontFamily));
  }

  void _changeFontSize(double v) {
    setState(() => _fontSize = v);
    _ctrl.setFontSize(fontSize: v);
  }

  void _changeFont(String font) {
    widget.onSettingsChanged(widget.themeType, font);
    _ctrl.updateTheme(theme: _epubThemeFor(widget.themeType, font));
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(
        themeType: widget.themeType,
        fontSize: _fontSize,
        fontFamily: widget.fontFamily,
        onTheme: _switchTheme,
        onFontSize: _changeFontSize,
        onFont: _changeFont,
        isDark: _isDark,
      ),
    );
  }

  void _openChapters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChapterSheet(
        chapters: _chapters,
        isDark: _isDark,
        onTap: (href) {
          Navigator.pop(context);
          _ctrl.display(cfi: href);
        },
      ),
    );
  }

  void _showSearch() async {
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(isDark: _isDark),
    );
    if (query == null || query.isEmpty || !_loaded) return;

    final results = await _ctrl.search(query: query);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchResultsSheet(
        query: query,
        results: results,
        isDark: _isDark,
        onTap: (cfi) {
          Navigator.pop(context);
          _ctrl.display(cfi: cfi);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opt = _opt;
    final bgColor = opt.bg;
    final fgColor = opt.fg;
    final overlayBg = _isDark
        ? Colors.black.withOpacity(0.75)
        : Colors.white.withOpacity(0.88);
    final overlayFg = _isDark ? Colors.white : const Color(0xff1a1a1a);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              // ── EPUB viewer (full screen) ──────────────────────────────────
              Positioned.fill(
                child: EpubViewer(
                  epubController: _ctrl,
                  epubSource: _src,
                  displaySettings: EpubDisplaySettings(
                    fontSize: _fontSize.toInt(),
                    flow: EpubFlow.paginated,
                    spread: EpubSpread.none,
                    snap: true,
                    allowScriptedContent: true,
                    theme: _epubThemeFor(widget.themeType, widget.fontFamily),
                  ),
                  onEpubLoaded: () => setState(() => _loaded = true),
                  onChaptersLoaded: (ch) => setState(() => _chapters = ch),
                  onRelocated: (loc) => setState(() => _location = loc),
                  onTextSelected: (sel) => setState(() {
                    _selectedText = sel.selectedText;
                    _selectedCfi = sel.selectionCfi;
                  }),
                  onDeselection: () => setState(() {
                    _selectedText = '';
                    _selectedCfi = '';
                  }),
                  onTouchUp: (x, y) {
                    if (_loaded) _toggleBars();
                  },
                ),
              ),

              // ── Loading overlay ────────────────────────────────────────────
              if (!_loaded)
                Positioned.fill(
                  child: _LoadingOverlay(bgColor: bgColor, fgColor: fgColor),
                ),

              // ── Top bar ────────────────────────────────────────────────────
              if (_loaded && _barsVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _barFade,
                    child: _TopBar(
                      overlayBg: overlayBg,
                      overlayFg: overlayFg,
                      isDark: _isDark,
                      hasChapters: _chapters.isNotEmpty,
                      onChapters: _openChapters,
                      onSearch: _showSearch,
                      onSettings: _openSettings,
                    ),
                  ),
                ),

              // ── Selection toolbar ──────────────────────────────────────────
              if (_selectedText.isNotEmpty && _loaded)
                Positioned(
                  bottom: 90,
                  left: 16,
                  right: 16,
                  child: _SelectionBar(
                    text: _selectedText,
                    overlayBg: overlayBg,
                    overlayFg: overlayFg,
                    onHighlight: () {
                      _ctrl.addHighlight(
                        cfi: _selectedCfi,
                        color: Theme.of(context).colorScheme.primary,
                        opacity: 0.45,
                      );
                      _ctrl.clearSelection();
                      setState(() {
                        _selectedText = '';
                        _selectedCfi = '';
                      });
                    },
                    onClear: () {
                      _ctrl.clearSelection();
                      setState(() {
                        _selectedText = '';
                        _selectedCfi = '';
                      });
                    },
                  ),
                ),

              // ── Bottom bar ─────────────────────────────────────────────────
              if (_loaded && _barsVisible)
                Positioned(
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                  left: 20,
                  right: 20,
                  child: FadeTransition(
                    opacity: _barFade,
                    child: ScaleTransition(
                      scale: _barFade,
                      child: _BottomBar(
                        overlayBg: overlayBg,
                        overlayFg: overlayFg,
                        isDark: _isDark,
                        location: _location,
                        onPrev: () => _ctrl.prev(),
                        onNext: () => _ctrl.next(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading overlay ───────────────────────────────────────────────────────────

class _LoadingOverlay extends StatefulWidget {
  final Color bgColor;
  final Color fgColor;

  const _LoadingOverlay({required this.bgColor, required this.fgColor});

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_pulse.value * 0.4),
                  child: Transform.scale(
                    scale: 0.95 + (_pulse.value * 0.1),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.fgColor.withOpacity(0.04),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.fgColor.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  IconlyLight.document,
                  size: 52,
                  color: widget.fgColor.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: widget.fgColor.withOpacity(0.06),
                color: widget.fgColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Opening your book…',
              style: TextStyle(
                color: widget.fgColor.withOpacity(0.4),
                fontSize: 14,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Color overlayBg;
  final Color overlayFg;
  final bool isDark;
  final bool hasChapters;
  final VoidCallback onChapters;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  const _TopBar({
    required this.overlayBg,
    required this.overlayFg,
    required this.isDark,
    required this.hasChapters,
    required this.onChapters,
    required this.onSearch,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: overlayBg,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            bottom: 8,
            left: 8,
            right: 8,
          ),
          child: Row(
            children: [
              const Spacer(),
              if (hasChapters)
                _BarButton(
                  icon: IconlyLight.category,
                  color: overlayFg,
                  onTap: onChapters,
                ),
              _BarButton(
                icon: IconlyLight.search,
                color: overlayFg,
                onTap: onSearch,
              ),
              _BarButton(
                icon: IconlyLight.setting,
                color: overlayFg,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Color overlayBg;
  final Color overlayFg;
  final bool isDark;
  final EpubLocation? location;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _BottomBar({
    required this.overlayBg,
    required this.overlayFg,
    required this.isDark,
    required this.location,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = location?.progress ?? 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: overlayBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: overlayFg.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress track
              Row(
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      color: overlayFg.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: overlayFg.withOpacity(0.08),
                        color: overlayFg.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Navigation row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(
                    icon: IconlyLight.arrow_left,
                    label: 'Previous',
                    fgColor: overlayFg,
                    onTap: onPrev,
                  ),
                  _NavButton(
                    icon: IconlyLight.arrow_right,
                    label: 'Next',
                    fgColor: overlayFg,
                    onTap: onNext,
                    iconRight: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Selection bar ─────────────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  final String text;
  final Color overlayBg;
  final Color overlayFg;
  final VoidCallback onHighlight;
  final VoidCallback onClear;

  const _SelectionBar({
    required this.text,
    required this.overlayBg,
    required this.overlayFg,
    required this.onHighlight,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: overlayBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: overlayFg.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: overlayFg.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyLight.edit,
                  size: 16,
                  color: overlayFg.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"$text"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: overlayFg.withOpacity(0.8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _PillButton(
                label: 'Highlight',
                bgColor: Theme.of(context).colorScheme.primary,
                fgColor: Colors.white,
                onTap: onHighlight,
              ),
              const SizedBox(width: 8),
              _BarButton(
                icon: IconlyLight.close_square,
                color: overlayFg.withOpacity(0.5),
                onTap: onClear,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings bottom sheet ─────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  final EpubThemeType themeType;
  final double fontSize;
  final String fontFamily;
  final ValueChanged<EpubThemeType> onTheme;
  final ValueChanged<double> onFontSize;
  final ValueChanged<String> onFont;
  final bool isDark;

  const _SettingsSheet({
    required this.themeType,
    required this.fontSize,
    required this.fontFamily,
    required this.onTheme,
    required this.onFontSize,
    required this.onFont,
    required this.isDark,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late double _fs;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _fs = widget.fontSize;
  }

  Future<void> _handleAction(VoidCallback action) async {
    if (_isApplying) return;
    setState(() => _isApplying = true);
    action();
    // Simulate application time (JS theme injection / layout sync)
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isApplying = false);
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = widget.isDark ? const Color(0xff1c1c1e) : Colors.white;
    final labelColor =
        widget.isDark ? Colors.white.withOpacity(0.5) : const Color(0xff6D6875);
    final titleColor = widget.isDark ? Colors.white : const Color(0xff1a1a1a);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
        top: 0,
        left: 28,
        right: 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loader
          SizedBox(
            height: 3,
            child: _isApplying
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: accentColor.withOpacity(0.05),
                      color: accentColor,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            children: [
              Icon(IconlyLight.setting, color: accentColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_isApplying)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Applying changes...',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Theme label
          Text(
            'COLOR THEME',
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Theme swatches
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _themes.map((opt) {
                final selected = widget.themeType == opt.type;
                return GestureDetector(
                  onTap: () => _handleAction(() => widget.onTheme(opt.type)),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isApplying && !selected ? 0.3 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: opt.swatch,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? accentColor
                                    : labelColor.withOpacity(0.1),
                                width: selected ? 3 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? Icon(
                                    IconlyLight.tick_square,
                                    size: 22,
                                    color: opt.fg.withOpacity(0.8),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            opt.label,
                            style: TextStyle(
                              color: selected ? titleColor : labelColor,
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Typography Section
          Row(
            children: [
              Text(
                'TYPOGRAPHY',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.fontFamily,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Font family picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _fonts.map((f) {
                final selected = widget.fontFamily == f;
                return GestureDetector(
                  onTap: () => _handleAction(() => widget.onFont(f)),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isApplying && !selected ? 0.3 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor
                            : labelColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? accentColor
                              : labelColor.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontFamily: f,
                          color: selected ? Colors.white : titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),

          // Font size section
          Row(
            children: [
              Text(
                'SIZE',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_fs.toInt()}px',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(IconlyLight.document, size: 16, color: labelColor),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: accentColor.withOpacity(0.1),
                    thumbColor: Colors.white,
                    overlayColor: accentColor.withOpacity(0.12),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 4,
                      pressedElevation: 6,
                    ),
                  ),
                  child: Slider(
                    value: _fs,
                    min: 12,
                    max: 28,
                    divisions: 16,
                    onChanged: (v) {
                      setState(() => _fs = v);
                      widget.onFontSize(v);
                    },
                  ),
                ),
              ),
              Icon(IconlyLight.document, size: 24, color: labelColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chapter sheet ─────────────────────────────────────────────────────────────

class _ChapterSheet extends StatelessWidget {
  final List<EpubChapter> chapters;
  final bool isDark;
  final void Function(String href) onTap;

  const _ChapterSheet({
    required this.chapters,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? const Color(0xff1c1c1e) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xff1a1a1a);
    final labelColor =
        isDark ? Colors.white.withOpacity(0.5) : const Color(0xff6D6875);
    final divColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);
    final accentColor = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Icon(IconlyLight.category, color: accentColor, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Chapters',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${chapters.length}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: divColor),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                itemCount: chapters.length,
                itemBuilder: (_, i) {
                  final ch = chapters[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 4,
                    ),
                    title: Text(
                      ch.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Chapter ${i + 1}',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      IconlyLight.arrow_right_2,
                      color: labelColor.withOpacity(0.4),
                      size: 20,
                    ),
                    onTap: () => onTap(ch.href),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search sheet ──────────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final bool isDark;
  const _SearchSheet({required this.isDark});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = widget.isDark ? const Color(0xff1c1c1e) : Colors.white;
    final titleColor = widget.isDark ? Colors.white : const Color(0xff1a1a1a);
    final hintColor = widget.isDark ? Colors.white30 : Colors.black38;
    final fieldBg = widget.isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: hintColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(IconlyLight.search, color: accentColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Search in Book',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: titleColor.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search for phrases, characters…',
                  hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                  prefixIcon: Icon(
                    IconlyLight.search,
                    color: titleColor.withOpacity(0.2),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(context, v),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _PillButton(
                label: 'Start Search',
                bgColor: accentColor,
                fgColor: Colors.white,
                onTap: () => Navigator.pop(context, _ctrl.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search results sheet ──────────────────────────────────────────────────────

class _SearchResultsSheet extends StatelessWidget {
  final String query;
  final List<EpubSearchResult> results;
  final bool isDark;
  final void Function(String cfi) onTap;

  const _SearchResultsSheet({
    required this.query,
    required this.results,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? const Color(0xff1c1c1e) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xff1a1a1a);
    final labelColor = isDark ? Colors.white60 : const Color(0xff888888);
    final divColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);
    final accentColor = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Icon(IconlyLight.document, color: accentColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Results for "$query"',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${results.length}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: divColor),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(IconlyLight.info_square,
                              size: 48, color: labelColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No matches found',
                            style: TextStyle(
                                color: labelColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: MediaQuery.of(context).padding.bottom + 24,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: divColor),
                      itemBuilder: (_, i) {
                        final res = results[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 8,
                          ),
                          title: Text(
                            res.excerpt,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          trailing: Icon(
                            IconlyLight.arrow_right_2,
                            color: labelColor.withOpacity(0.4),
                            size: 18,
                          ),
                          onTap: () => onTap(res.cfi),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _BarButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(widget.icon, color: widget.color.withOpacity(0.9), size: 22),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color fgColor;
  final VoidCallback onTap;
  final bool iconRight;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.fgColor,
    required this.onTap,
    this.iconRight = false,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.fgColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.iconRight
                ? [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.fgColor.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(widget.icon,
                        color: widget.fgColor.withOpacity(0.8), size: 18),
                  ]
                : [
                    Icon(widget.icon,
                        color: widget.fgColor.withOpacity(0.8), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.fgColor.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: widget.bgColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
