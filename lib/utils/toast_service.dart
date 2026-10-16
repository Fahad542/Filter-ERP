import 'dart:async';
import 'package:flutter/material.dart';

import '../services/locker_translation_mixin.dart';
import 'app_navigation.dart';

/// Toasts via a managed [OverlayEntry] on the **same** [Navigator] [Overlay] that
/// hosts [showDialog] routes — so the banner paints **above** modals. Prefer the
/// caller [BuildContext] (still mounted) for lookup: [scaffoldMessengerKey] sits
/// **above** [Navigator] and has **no** [Overlay] ancestor, so using only that
/// context falls back to [SnackBar] and draws **behind** dialogs.
class ToastService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Max toast width as a fraction of screen width on tablet/desktop.
  static const double _maxWidthFraction = 0.46;
  static const double _horizontalInset = 22;
  static const double _mobileBreakpoint = 600;
  static const Duration _displayDuration = Duration(milliseconds: 2000);

  static OverlayEntry? _overlayEntry;
  static Timer? _overlayTimer;
  static int _overlayGen = 0;

  static void showSuccess(
    BuildContext context,
    String message, {
    bool messageOnly = false,
    String? title,
  }) {
    _show(
      context,
      message,
      title ?? 'Success',
      Colors.green.shade800,
      messageOnly: messageOnly,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _show(context, message, title ?? 'Error', const Color(0xFFB71C1C));
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _show(context, message, title ?? 'Info', Colors.blue.shade800);
  }

  static List<Widget> _toastContentWidgets(
    String message,
    String title,
    Color titleColor, {
    required bool messageOnly,
  }) {
    if (messageOnly) {
      return [
        Text(
          message,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ];
    }
    return [
      Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        message,
        style: const TextStyle(
          color: Color(0xFF23262D),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ];
  }

  static void _showSnackBarFallback(
    BuildContext layoutCtx,
    String message,
    String title,
    Color titleColor, {
    required bool messageOnly,
  }) {
    // [SnackBarBehavior.floating] with large top margins overflows the snack-bar
    // slot on [PosShell] (body + bottomNavigationBar). Fixed behavior is safe.
    final bar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _toastContentWidgets(message, title, titleColor,
            messageOnly: messageOnly),
      ),
      backgroundColor: const Color(0xFFFFF9E7),
      elevation: 8,
      behavior: SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: _displayDuration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      dismissDirection: DismissDirection.down,
    );

    final root = scaffoldMessengerKey.currentState;
    if (root != null) {
      root.clearSnackBars();
      root.showSnackBar(bar);
      return;
    }
    final local = ScaffoldMessenger.maybeOf(layoutCtx);
    local?.clearSnackBars();
    local?.showSnackBar(bar);
  }

  /// Overlay that hosts modal routes for this [context] (nearest navigator first).
  static OverlayState? _navigatorOverlay(BuildContext ctx) {
    return Navigator.maybeOf(ctx, rootNavigator: false)?.overlay ??
        Navigator.maybeOf(ctx, rootNavigator: true)?.overlay ??
        Overlay.maybeOf(ctx) ??
        AppNavigation.navigatorKey?.currentState?.overlay;
  }

  static String _syncToastText(BuildContext layoutCtx, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    final langCode = Localizations.localeOf(layoutCtx).languageCode;
    if (langCode != 'ar') {
      return AppTranslationService.localizeDigitsForLanguage(text, langCode);
    }
    return AppTranslationService.syncStatusOrRawForLanguage(text, langCode);
  }

  static void _insertRootOverlayBanner(
    BuildContext layoutCtx,
    String message,
    String title,
    Color titleColor, {
    required bool messageOnly,
  }) {
    final overlay = _navigatorOverlay(layoutCtx);
    if (overlay == null || !overlay.mounted) {
      _showSnackBarFallback(
        layoutCtx,
        message,
        title,
        titleColor,
        messageOnly: messageOnly,
      );
      return;
    }

    _overlayTimer?.cancel();
    final previous = _overlayEntry;
    _overlayEntry = null;
    previous?.remove();

    final gen = ++_overlayGen;
    final topPad = MediaQuery.paddingOf(layoutCtx).top;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final screenW = MediaQuery.sizeOf(ctx).width;
        final isMobile = screenW <= _mobileBreakpoint;
        final toastW = isMobile
            ? screenW - (_horizontalInset * 2)
            : screenW * _maxWidthFraction;

        final toastCard = Material(
          elevation: 16,
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFFFF9E7),
          shadowColor: Colors.black38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _toastContentWidgets(
                message,
                title,
                titleColor,
                messageOnly: messageOnly,
              ),
            ),
          ),
        );

        if (isMobile) {
          return Positioned(
            top: topPad + 10,
            left: _horizontalInset,
            right: _horizontalInset,
            child: toastCard,
          );
        }

        return Positioned(
          top: topPad + 10,
          right: _horizontalInset,
          width: toastW,
          child: toastCard,
        );
      },
    );

    _overlayEntry = entry;
    overlay.insert(entry);

    _overlayTimer = Timer(_displayDuration, () {
      if (gen != _overlayGen) return;
      entry.remove();
      if (_overlayEntry == entry) _overlayEntry = null;
    });
  }


  static Future<String> _localizedToastText(
    BuildContext layoutCtx,
    String text,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final langCode = Localizations.localeOf(layoutCtx).languageCode;

    // Keep English exactly as supplied. For Arabic, use the same app-wide
    // dynamic translation service used by API/database text so existing toast
    // calls do not need to be changed screen-by-screen.
    if (langCode != 'ar') {
      return AppTranslationService.localizeDigitsForLanguage(text, langCode);
    }

    try {
      return await AppTranslationService.localizedDynamicValueForLanguage(
        text,
        langCode,
      );
    } catch (_) {
      // Never block toast rendering because translation failed.
      return AppTranslationService.localizeDigitsForLanguage(text, langCode);
    }
  }

  static Future<({String message, String title})> _localizedToastPayload(
    BuildContext layoutCtx, {
    required String message,
    required String title,
  }) async {
    final localizedTitle = await _localizedToastText(layoutCtx, title);
    final localizedMessage = await _localizedToastText(layoutCtx, message);
    return (message: localizedMessage, title: localizedTitle);
  }

  static void _upgradeArabicToastIfNeeded(
    BuildContext layoutCtx,
    String message,
    String title,
    Color titleColor, {
    required bool messageOnly,
    required String initialMessage,
    required String initialTitle,
  }) {
    final langCode = Localizations.localeOf(layoutCtx).languageCode;
    if (langCode != 'ar') return;

    _localizedToastPayload(
      layoutCtx,
      message: message,
      title: title,
    ).then((localized) {
      if (!layoutCtx.mounted) return;
      if (localized.message == initialMessage &&
          localized.title == initialTitle) {
        return;
      }
      _insertRootOverlayBanner(
        layoutCtx,
        localized.message,
        localized.title,
        titleColor,
        messageOnly: messageOnly,
      );
    }).catchError((_) {});
  }

  static void _show(
    BuildContext context,
    String message,
    String title,
    Color titleColor, {
    bool messageOnly = false,
  }) {
    void present() {
      final layoutCtx =
          (context.mounted ? context : null) ??
              scaffoldMessengerKey.currentContext;
      if (layoutCtx == null) return;

      final initialMessage = _syncToastText(layoutCtx, message);
      final initialTitle = _syncToastText(layoutCtx, title);

      _insertRootOverlayBanner(
        layoutCtx,
        initialMessage,
        initialTitle,
        titleColor,
        messageOnly: messageOnly,
      );

      _upgradeArabicToastIfNeeded(
        layoutCtx,
        message,
        title,
        titleColor,
        messageOnly: messageOnly,
        initialMessage: initialMessage,
        initialTitle: initialTitle,
      );
    }

    // One frame lets dialog transitions settle; no extra waits for translation.
    WidgetsBinding.instance.addPostFrameCallback((_) => present());
  }
}
