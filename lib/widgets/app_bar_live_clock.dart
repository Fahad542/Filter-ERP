import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/locker_translation_mixin.dart';
import '../utils/app_colors.dart';
import '../utils/business_timezone.dart';

/// Light yellow pill background (date/time, printer IP, cashier info).
const Color kPosAppBarPillFill = Color(0xFFFFF9D6);

/// @deprecated Use [kPosAppBarPillFill].
const Color kAppBarDateTimePillFill = kPosAppBarPillFill;

/// Compact app bar pills (date/time, sync, printer IP) share the same outer height.
abstract final class PosAppBarCompactPillMetrics {
  static const double borderWidth = 1.0;

  static bool isArabicLocale(String languageCode) => languageCode == 'ar';

  static double verticalPad(bool isTablet, {bool isArabic = false}) =>
      isTablet ? (isArabic ? 4.0 : 5.0) : (isArabic ? 3.0 : 4.0);

  static double horizontalPad(bool isTablet) => isTablet ? 9.0 : 8.0;

  static double lineGap(bool isTablet, {bool isArabic = false}) =>
      isTablet ? (isArabic ? 2.0 : 3.0) : (isArabic ? 1.5 : 2.0);

  static double dateFontSize(bool isTablet, {bool isArabic = false}) {
    final base = isTablet ? 10.5 : 9.5;
    return isArabic ? base - 0.45 : base;
  }

  static double timeFontSize(bool isTablet, {bool isArabic = false}) {
    final base = isTablet ? 12.0 : 10.5;
    return isArabic ? base - 0.35 : base;
  }

  static double dateLineHeight(bool isTablet, {bool isArabic = false}) =>
      isArabic ? 1.12 : 1.18;

  static double timeLineHeight(bool isTablet, {bool isArabic = false}) =>
      isArabic ? 1.14 : 1.2;

  /// Tall enough for bold digits + descenders (avoids bottom clip in pills).
  static double lineBoxFor(double fontSize) => fontSize * 1.28 + 2.0;

  static double dateLineBox(bool isTablet, {bool isArabic = false}) =>
      lineBoxFor(dateFontSize(isTablet, isArabic: isArabic));

  static double timeLineBox(bool isTablet, {bool isArabic = false}) =>
      lineBoxFor(timeFontSize(isTablet, isArabic: isArabic));

  static double contentHeight(bool isTablet, {bool isArabic = false}) =>
      dateLineBox(isTablet, isArabic: isArabic) +
      lineGap(isTablet, isArabic: isArabic) +
      timeLineBox(isTablet, isArabic: isArabic);

  static double outerHeight(bool isTablet, {bool isArabic = false}) =>
      2 * verticalPad(isTablet, isArabic: isArabic) +
      2 * borderWidth +
      contentHeight(isTablet, isArabic: isArabic) +
      (isArabic ? 8.0 : 5.0);

  static double singleLineOuterHeight(bool isTablet, {bool isArabic = false}) {
    final font = singleLineFontSize(isTablet, isArabic: isArabic);
    final v = singleLineVerticalPad(isTablet);
    return 2 * v + font * 1.25 + 2.0;
  }

  static double singleLineFontSize(bool isTablet, {bool isArabic = false}) {
    final base = isTablet ? 11.5 : 10.5;
    return isArabic ? base - 0.35 : base;
  }

  static double singleLineVerticalPad(bool isTablet) => isTablet ? 7.0 : 6.0;

  static double singleLineHorizontalPad(bool isTablet) => isTablet ? 14.0 : 12.0;

  /// Stadium pill (fully rounded ends).
  static double singleLineBorderRadius(bool isTablet) => isTablet ? 16.0 : 14.0;

  static double toolbarHeight(bool isTablet, {bool isArabic = false}) {
    final pill = outerHeight(isTablet, isArabic: isArabic);
    final needed = pill + 14;
    const floor = 58.0;
    return needed > floor ? needed : floor;
  }

  static const TextHeightBehavior compactTextHeightBehavior =
      TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  static double borderRadius(bool isTablet) => isTablet ? 6.0 : 5.0;
}

/// Live KSA wall clock for POS app bar subtitle + trailing pill (same string).
String formatPosAppBarDateTimeLine(String locale) {
  final wall = BusinessTimezone.nowWall();
  final dateRaw = DateFormat('dd MMM yyyy', locale).format(wall);
  final timeRaw = DateFormat('hh:mm a', locale).format(wall);
  final date =
      AppTranslationService.localizeDigitsForLanguage(dateRaw, locale);
  final time =
      AppTranslationService.localizeDigitsForLanguage(timeRaw, locale);
  return '$date · $time';
}

/// Shared stadium pill for single-line app bar chips (date, printer IP, …).
class PosAppBarSingleLinePill extends StatelessWidget {
  const PosAppBarSingleLinePill({
    super.key,
    required this.text,
    this.onTap,
    this.alignStart = false,
    this.maxWidth,
    this.trailingIcon,
    this.trailingIconColor,
  });

  final String text;
  final VoidCallback? onTap;
  final bool alignStart;
  final double? maxWidth;
  final IconData? trailingIcon;
  final Color? trailingIconColor;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = PosAppBarCompactPillMetrics.isArabicLocale(locale);
    final fontSize =
        PosAppBarCompactPillMetrics.singleLineFontSize(isTablet, isArabic: isArabic);
    final hPad = PosAppBarCompactPillMetrics.singleLineHorizontalPad(isTablet);
    final vPad = PosAppBarCompactPillMetrics.singleLineVerticalPad(isTablet);
    final pillRadius =
        PosAppBarCompactPillMetrics.singleLineBorderRadius(isTablet);

    final pill = Container(
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: kPosAppBarPillFill,
        borderRadius: BorderRadius.circular(pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: alignStart ? TextAlign.start : TextAlign.center,
              textHeightBehavior:
                  PosAppBarCompactPillMetrics.compactTextHeightBehavior,
              style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                height: 1.2,
                letterSpacing: 0.15,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: isTablet ? 6 : 5),
            Icon(
              trailingIcon,
              size: fontSize * 1.15,
              color: trailingIconColor ??
                  AppColors.secondaryLight.withValues(alpha: 0.88),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(pillRadius),
        child: pill,
      ),
    );
  }
}

/// Plain date/time in the system status bar row (no pill).
class PosStatusBarDateText extends StatefulWidget {
  const PosStatusBarDateText({super.key});

  @override
  State<PosStatusBarDateText> createState() => _PosStatusBarDateTextState();
}

class _PosStatusBarDateTextState extends State<PosStatusBarDateText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return Text(
      formatPosAppBarDateTimeLine(locale),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(0xFF1A1A1A),
        fontWeight: FontWeight.w600,
        fontSize: isTablet ? 12.0 : 11.0,
        height: 1.0,
        letterSpacing: 0.1,
      ),
    );
  }
}

/// Date + time pill for POS app bars (light-yellow decoration).
class AppBarDateTimeBlock extends StatefulWidget {
  const AppBarDateTimeBlock({
    super.key,
    this.compact = false,
    this.alignStart = false,
  });

  final bool compact;
  final bool alignStart;

  @override
  State<AppBarDateTimeBlock> createState() => _AppBarDateTimeBlockState();
}

class _AppBarDateTimeBlockState extends State<AppBarDateTimeBlock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return PosAppBarSingleLinePill(
      text: formatPosAppBarDateTimeLine(locale),
      alignStart: widget.alignStart,
    );
  }
}

Widget PosAppBarCompactPillTextLine({
  required String text,
  required double fontSize,
  required double lineHeight,
  required double? lineBox,
  bool alignStart = true,
  bool center = false,
  required Color color,
  required FontWeight fontWeight,
  double letterSpacing = 0.1,
}) {
  final textAlign =
      center ? TextAlign.center : (alignStart ? TextAlign.start : TextAlign.end);

  final textWidget = Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    textHeightBehavior: PosAppBarCompactPillMetrics.compactTextHeightBehavior,
    textAlign: textAlign,
    style: TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: lineHeight,
      letterSpacing: letterSpacing,
    ),
  );

  if (lineBox == null) return textWidget;

  return SizedBox(
    height: lineBox,
    child: Align(
      alignment: Alignment.center,
      child: textWidget,
    ),
  );
}

/// Leading slot: optional [menu] (hamburger / back / globe) and optional date/time.
class PosAppBarLeadingWithClock extends StatelessWidget {
  const PosAppBarLeadingWithClock({
    super.key,
    this.menu,
    this.gap,
    this.includeClock = false,
  });

  final Widget? menu;
  final double? gap;
  final bool includeClock;

  static double leadingWidth(
    bool isTablet, {
    required bool hasMenu,
    bool includesClock = false,
  }) {
    final pad = 14.0;
    final menuW = isTablet ? 48.0 : 40.0;
    final clockW = isTablet ? 168.0 : 148.0;
    final g = isTablet ? 8.0 : 6.0;
    const tail = 10.0;
    var w = pad + tail;
    if (hasMenu) w += menuW;
    if (includesClock && hasMenu) w += g + clockW;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final g = gap ?? (isTablet ? 8.0 : 6.0);

    return PosAppBarLtrRow(
      children: [
        if (menu != null) menu!,
        if (includeClock && menu != null) SizedBox(width: g),
        if (includeClock)
          const AppBarDateTimeBlock(compact: true, alignStart: false),
      ],
    );
  }
}

/// App bar action row — mirrors with locale (LTR / RTL).
class PosAppBarLtrRow extends StatelessWidget {
  const PosAppBarLtrRow({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Cashier / workshop / branch — left corner of the POS app bar.
class PosAppBarCashierInfoBlock extends StatelessWidget {
  const PosAppBarCashierInfoBlock({
    super.key,
    required this.userName,
    required this.workshopName,
    required this.branchLabel,
  });

  final String userName;
  final String workshopName;
  final String branchLabel;

  bool get _hasContent =>
      userName.trim().isNotEmpty ||
      workshopName.trim().isNotEmpty ||
      branchLabel.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final nameSize = isTablet ? 14.0 : 12.5;
    final workshopSize = isTablet ? 10.5 : 9.5;
    final branchSize = isTablet ? 10.0 : 9.0;

    Widget line(String text, TextStyle style) {
      if (text.trim().isEmpty) return const SizedBox.shrink();
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        style: style,
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: isTablet ? 220 : 168),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 11 : 9,
        vertical: isTablet ? 7 : 6,
      ),
      decoration: BoxDecoration(
        color: kPosAppBarPillFill,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(
            userName,
            TextStyle(
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w800,
              fontSize: nameSize,
              height: 1.1,
              letterSpacing: 0.1,
            ),
          ),
          if (workshopName.trim().isNotEmpty) const SizedBox(height: 2),
          line(
            workshopName,
            TextStyle(
              color: Colors.black.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              fontSize: workshopSize,
              height: 1.1,
              letterSpacing: 0.2,
            ),
          ),
          if (branchLabel.trim().isNotEmpty) const SizedBox(height: 2),
          line(
            branchLabel,
            TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              fontSize: branchSize,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Leading slot: optional menu/back + cashier info pill.
class PosAppBarLeadingCluster extends StatelessWidget {
  const PosAppBarLeadingCluster({
    super.key,
    this.menu,
    this.cashierInfo,
    this.gap,
  });

  final Widget? menu;
  final Widget? cashierInfo;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    if (menu == null && cashierInfo == null) return const SizedBox.shrink();

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final g = gap ?? (isTablet ? 8.0 : 6.0);

    return PosAppBarLtrRow(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (menu != null) menu!,
        if (menu != null && cashierInfo != null) SizedBox(width: g),
        if (cashierInfo != null) cashierInfo!,
      ],
    );
  }
}

/// Stacked trailing column: date/time on top, then sync / printer pills below.
class PosAppBarTrailingPillsColumn extends StatelessWidget {
  const PosAppBarTrailingPillsColumn({
    super.key,
    required this.bottomPills,
    this.includeClock = false,
    this.compact = true,
    this.gap,
  });

  final List<Widget> bottomPills;
  final bool includeClock;
  final bool compact;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final pillGap = gap ?? (isTablet ? 4.0 : 3.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (includeClock)
          const AppBarDateTimeBlock(compact: true, alignStart: false),
        for (var i = 0; i < bottomPills.length; i++) ...[
          if (includeClock || i > 0) SizedBox(height: pillGap),
          bottomPills[i],
        ],
      ],
    );
  }
}

/// Trailing app bar: date/time pill + action icons (same row).
class PosAppBarTrailingCluster extends StatelessWidget {
  const PosAppBarTrailingCluster({
    super.key,
    this.compact = false,
    this.clockOnly = false,
    this.includeClock = true,
    this.belowClock = const [],
  });

  final bool compact;
  final bool clockOnly;
  final bool includeClock;
  final List<Widget> belowClock;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final gap = isTablet ? 10.0 : 8.0;
    final icons = belowClock;

    if (!includeClock) {
      if (clockOnly || icons.isEmpty) return const SizedBox.shrink();
      return PosAppBarLtrRow(children: icons);
    }

    return PosAppBarLtrRow(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBarDateTimeBlock(compact: compact, alignStart: false),
        if (!clockOnly && icons.isNotEmpty) ...[
          SizedBox(width: gap),
          ...icons,
        ],
      ],
    );
  }
}

/// @deprecated Use [AppBarDateTimeBlock].
typedef AppBarLiveClock = AppBarDateTimeBlock;

List<Widget> filterAppBarActions({
  List<Widget>? leading,
  List<Widget>? belowClock,
  bool clockOnly = false,
  bool includeClock = true,
}) =>
    [
      ...?leading,
      if (leading != null && leading.isNotEmpty) const SizedBox(width: 8),
      PosAppBarTrailingCluster(
        clockOnly: clockOnly || (belowClock == null || belowClock.isEmpty),
        includeClock: includeClock,
        belowClock: belowClock ?? const [],
      ),
    ];
