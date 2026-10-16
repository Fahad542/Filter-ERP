import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/owner_data_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';
import '../owner_shell.dart';
import 'owner_branch_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OwnerAppBar — Workshop Owner yellow app bar (shorter than POS cashier).
// ─────────────────────────────────────────────────────────────────────────────

/// Workshop Owner app bar content height (below status bar).
/// Tall enough for title + global branch picker line under it.
const double kOwnerYellowAppBarHeight = 84;

class OwnerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title; // String or Widget
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onBackPressed;
  final bool showDrawer;
  final bool showBackButton;
  final bool showNotification;
  final bool showGlobalLeft;
  @Deprecated('Clock removed from owner app bar; ignored.')
  final bool showClock;
  final double? height;
  /// White date/time chips that straddle the yellow header bottom edge
  /// (same pattern as the technician dashboard).
  final Widget? bottomOverlap;

  /// Extra preferred-size height reserved when [bottomOverlap] is set
  /// (chip height that hangs below the yellow edge).
  static const double filterOverlap = 46.0;

  /// Extra yellow height above the date chips so they don't sit flush
  /// under the title / action icons.
  static const double filterHeaderExtra = 12.0;

  const OwnerAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.onBackPressed,
    this.showDrawer = true,
    this.showBackButton = false,
    this.showNotification = false,
    this.showGlobalLeft = false,
    this.showClock = false,
    this.height,
    this.bottomOverlap,
  });

  double get _barHeight => height ?? kOwnerYellowAppBarHeight;

  @override
  Size get preferredSize {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final topInset = views.isEmpty
        ? 0.0
        : views.first.padding.top / views.first.devicePixelRatio;
    final overlap = bottomOverlap != null
        ? filterOverlap + filterHeaderExtra
        : 0.0;
    return Size.fromHeight(_barHeight + topInset + overlap);
  }

  void _openDrawer(BuildContext context) {
    final open = onMenuPressed ??
        () => OwnerShellState.scaffoldKey.currentState?.openDrawer();
    open();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final gap = isTablet ? 8.0 : 6.0;
    final iconBox = isTablet ? 38.0 : 32.0;
    final iconGlyph = isTablet ? 19.0 : 17.0;
    final actionIconSize = isTablet ? 36.0 : 34.0;
    final topInset = MediaQuery.paddingOf(context).top;
    final yellowExtra = bottomOverlap != null ? filterHeaderExtra : 0.0;
    final headerH = topInset + _barHeight + yellowExtra;
    final totalH = preferredSize.height;

    Widget? leading;
    if (showBackButton) {
      leading = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: actionIconSize,
            height: actionIconSize,
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.black,
              size: isTablet ? 26 : 24,
            ),
          ),
        ),
      );
    } else if (showDrawer) {
      leading = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDrawer(context),
        child: Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(isTablet ? 9 : 8),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryLight.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.menu_rounded, color: Colors.white, size: iconGlyph),
        ),
      );
    }

    final leadingCluster = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGlobalLeft) ...[
          _globeButton(context, isTablet, actionIconSize),
          if (leading != null) SizedBox(width: gap),
        ],
        if (leading != null) leading,
      ],
    );

    // String titles automatically get the global branch picker under them.
    final Widget center = title is String
        ? OwnerDashboardTitle(subtitle: title as String)
        : title as Widget;

    final trailingChildren = <Widget>[
      if (!showGlobalLeft) _globeButton(context, isTablet, actionIconSize),
      if (showNotification) _notificationButton(context, isTablet, actionIconSize),
      if (actions != null) ...actions!,
    ];

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < trailingChildren.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          trailingChildren[i],
        ],
      ],
    );

    final bottomRadius = isTablet ? 22.0 : 20.0;
    final sideSlotWidth = isTablet ? 96.0 : 78.0;

    final yellowHeader = ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(bottomRadius),
      ),
      child: ColoredBox(
        color: AppColors.primaryLight,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: _barHeight + yellowExtra,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: isTablet ? 12 : 10,
                end: isTablet ? 12 : 10,
                // Leave room above the overlapping date chips.
                bottom: yellowExtra > 0
                    ? yellowExtra + (isTablet ? 2 : 4)
                    : (isTablet ? 4 : 6),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: _barHeight - (isTablet ? 4 : 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: sideSlotWidth,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: leadingCluster,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: center,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: sideSlotWidth,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: trailing,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (bottomOverlap == null) return yellowHeader;

    return SizedBox(
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerH,
            child: yellowHeader,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: bottomOverlap!,
          ),
        ],
      ),
    );
  }

  Widget _globeButton(BuildContext context, bool isTablet, double size) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        return InkWell(
          onTap: () {
            final newLocale = settings.locale.languageCode == 'en'
                ? const Locale('ar')
                : const Locale('en');
            settings.updateLocale(newLocale);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/global.png',
                width: isTablet ? 22 : 20,
                color: Colors.black,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.language_rounded,
                  size: isTablet ? 22 : 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _notificationButton(BuildContext context, bool isTablet, double size) {
    return InkWell(
      onTap: onNotificationPressed ?? () => OwnerShell.goToNotifications(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/notifications.png',
              width: isTablet ? 22 : 20,
              color: Colors.black,
              errorBuilder: (_, __, ___) => Icon(
                Icons.notifications_rounded,
                size: isTablet ? 22 : 20,
                color: Colors.black,
              ),
            ),
            Positioned(
              top: isTablet ? 7 : 6,
              right: isTablet ? 7 : 6,
              child: Container(
                width: isTablet ? 8 : 7,
                height: isTablet ? 8 : 7,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerDashboardTitle extends StatelessWidget {
  final String subtitle;

  /// When true (default), shows the global branch under the title and opens
  /// the shared branch bottom sheet on tap.
  final bool showBranchPicker;

  const OwnerDashboardTitle({
    super.key,
    required this.subtitle,
    this.showBranchPicker = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = Text(
      isArabic ? subtitle : subtitle.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isTablet ? 17 : 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.1,
      ),
    );

    if (!showBranchPicker) return title;

    return Consumer<OwnerDataService>(
      builder: (context, data, _) {
        final l10n = AppLocalizations.of(context);
        final branchLabel = data.selectedBranch != null
            ? (data.selectedBranch!.translatedName ??
                data.selectedBranch!.name)
            : (l10n?.dashboardAllBranches ?? 'All Branches');

        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              title,
              const SizedBox(height: 5),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showOwnerBranchPickerSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    branchLabel,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isTablet ? 15 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryLight
                                          .withValues(alpha: 0.85),
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 2 : 1),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: isTablet ? 21 : 19,
                                  color: AppColors.secondaryLight
                                      .withValues(alpha: 0.85),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tappable app-bar title for branch selection (opens branch bottom sheet).
class OwnerBranchPickerTitle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OwnerBranchPickerTitle({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 4 : 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.secondaryLight,
                size: isTablet ? 22 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
