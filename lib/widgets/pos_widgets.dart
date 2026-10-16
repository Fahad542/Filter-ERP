import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_arabic_font_fallbacks.dart';
import '../utils/app_button_busy.dart';
import '../models/pos_order_model.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_keyboard_locale.dart';
import '../views/Workshop pos app/More Tab/settings_view_model.dart';
import 'package:provider/provider.dart';
import '../utils/app_formatters.dart';
import '../views/Workshop pos app/Home Screen/pos_view_model.dart' as pvm;
import '../models/create_invoice_model.dart';
import '../models/pos_technician_model.dart'; // Added import for TechnicianCard
import '../models/pos_product_model.dart'; // Added import for ProductCard
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import '../utils/toast_service.dart';
import '../utils/pos_tablet_layout.dart';
import '../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../views/Workshop pos app/Notifications/notifications_view.dart';
import '../views/Workshop pos app/AI Orders/ai_orders_view_model.dart';
import '../views/Workshop pos app/Product Grid/pos_product_grid_view.dart';
import '../views/Workshop pos app/Order Screen/pos_order_review_view.dart';
import '../views/Workshop pos app/Order Screen/pos_orders_hub_dialog.dart';
import '../l10n/app_localizations.dart';
import '../views/Workshop pos app/Department/pos_department_view.dart';
import '../views/Workshop pos app/Technician Assignment/pos_technician_assignment_view.dart';
import '../views/Workshop pos app/Add Customer Screen/pos_add_customer_view.dart';
import '../services/invoice_dialog_launcher.dart';
import '../services/invoice_print_prefetch.dart';
import '../services/thermal_print_isolate_pipeline.dart';
import '../services/network_thermal_printer.dart';
import '../services/thermal_printer_settings.dart';
import '../services/backend_whatsapp_invoice_dispatch.dart';
import '../utils/invoice_preview_capture_pdf.dart';
import 'thermal_printer_wifi_dialog.dart';
import '../l10n/app_localizations.dart';
import '../services/LocalizedApiText.dart';
import '../services/locker_translation_mixin.dart';
import '../utils/plate_transliterator.dart';
import 'cashier_invoice_preview.dart';
import 'thermal_invoice_pdf.dart';
import '../utils/thermal_invoice_totals.dart';
import 'pos_catalog_sync_app_bar_button.dart';
import 'app_bar_live_clock.dart';
import 'pos_shell_rail_layout.dart';

/// When true, hide the app-bar hamburger (shell left menu rail handles drawer).
bool kPosHideDrawerMenuTabletLandscape(BuildContext context) => false;

/// Language toggle — leading (left) side of the POS app bar.
Widget _posAppBarGlobeButton(BuildContext context, bool isTablet) {
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
          width: isTablet ? PosTabletLayout.appBarIconBox : 40,
          height: isTablet ? PosTabletLayout.appBarIconBox : 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/images/global.png',
              width: isTablet ? 26 : 22,
              color: Colors.black,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.language_rounded,
                size: isTablet ? 26 : 22,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Globe + notification on the trailing (right) side (Orders Hub layout).
List<Widget> _posAppBarGlobeAndNotification(
  BuildContext context,
  bool isTablet,
  double gap, {
  bool showNotification = true,
}) {
  return [
    _posAppBarGlobeButton(context, isTablet),
    if (showNotification) ...[
      SizedBox(width: gap),
      ..._posAppBarTrailingNotification(context, isTablet),
    ],
  ];
}

/// Notification bell — trailing (right) side of the POS app bar.
List<Widget> _posAppBarTrailingNotification(
  BuildContext context,
  bool isTablet,
) {
  final unbilled =
      context.select((AiOrdersViewModel vm) => vm.unbilledCount);
  return [
      InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsView(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isTablet ? PosTabletLayout.appBarIconBox : 40,
          height: isTablet ? PosTabletLayout.appBarIconBox : 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/notifications.png',
                width: isTablet ? 26 : 22,
                color: Colors.black,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.notifications_rounded,
                  size: isTablet ? 26 : 22,
                  color: Colors.black,
                ),
              ),
              if (unbilled > 0)
                Positioned(
                  top: isTablet ? 6 : 5,
                  right: isTablet ? 6 : 5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unbilled > 99 ? '99+' : '$unbilled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 9 : 8,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
}

/// Fixed scaffold app-bar slot (matches [build] height exactly).
const double kPosYellowAppBarHeight = 88;

double _posResolveAppBarHeight(BuildContext context, {double? custom}) {
  if (custom != null && custom <= kPosYellowAppBarHeight) return custom;
  return kPosYellowAppBarHeight;
}

/// Status bar top inset (works without [BuildContext] for [PreferredSizeWidget]).
double posStatusBarTopInset() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return 24.0;
  final view = views.first;
  return view.padding.top / view.devicePixelRatio;
}

Size posAppBarPreferredSize({double yellowHeight = kPosYellowAppBarHeight}) =>
    Size.fromHeight(yellowHeight);

/// Total yellow app bar height (left menu rail offset).
double posAppBarTotalHeight(
  BuildContext context, {
  double yellowHeight = kPosYellowAppBarHeight,
}) =>
    yellowHeight;

Widget buildPosYellowAppBarShell({
  required BuildContext context,
  required Widget yellowToolbar,
  double yellowHeight = kPosYellowAppBarHeight,
}) {
  final isTablet = MediaQuery.sizeOf(context).width > 600;
  final bottomRadius = isTablet ? 28.0 : 24.0;

  return ClipRRect(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(bottomRadius),
    ),
    child: ColoredBox(
      color: AppColors.primaryLight,
      child: SizedBox(height: yellowHeight, child: yellowToolbar),
    ),
  );
}

Widget _posAppBarTrailingActions(
  BuildContext context, {
  required bool isTablet,
  required double gap,
  List<Widget>? trailingPrefix,
  bool minimalTrailingActions = false,
  bool globeOnTrailing = false,
  bool includeGlobeOnTrailing = false,
  bool showNotificationIcon = true,
  List<Widget>? extraLeading,
  bool includeClock = true,
}) {
  if (minimalTrailingActions) {
    return const AppBarDateTimeBlock(compact: true, alignStart: false);
  }

  final Widget? clock = includeClock
      ? const AppBarDateTimeBlock(compact: true, alignStart: false)
      : null;

  final ordersHubLayout = globeOnTrailing &&
      trailingPrefix != null &&
      trailingPrefix.isNotEmpty;

  final List<Widget> trailingIcons = minimalTrailingActions
      ? const <Widget>[]
      : (includeGlobeOnTrailing || ordersHubLayout)
          ? _posAppBarGlobeAndNotification(
              context,
              isTablet,
              gap,
              showNotification: showNotificationIcon,
            )
          : showNotificationIcon
              ? _posAppBarTrailingNotification(context, isTablet)
              : const <Widget>[];

  Widget actionRow;
  if (ordersHubLayout) {
    final hubPills = <Widget>[
      if (clock != null) clock,
      ...trailingPrefix!,
      const PosCatalogSyncAppBarButton(padding: EdgeInsets.zero),
    ];
    actionRow = PosAppBarLtrRow(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < hubPills.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          hubPills[i],
        ],
        if (trailingIcons.isNotEmpty) ...[
          SizedBox(width: gap),
          ...trailingIcons,
        ],
      ],
    );
  } else {
    final belowPills = <Widget>[
      if (!minimalTrailingActions)
        const PosCatalogSyncAppBarButton(padding: EdgeInsets.zero),
      ...?trailingPrefix,
    ];
    final stackPills = belowPills.length > 1;

    if (stackPills) {
      actionRow = PosAppBarLtrRow(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PosAppBarTrailingPillsColumn(
            includeClock: includeClock,
            bottomPills: belowPills,
          ),
          if (trailingIcons.isNotEmpty) SizedBox(width: gap),
          if (trailingIcons.isNotEmpty)
            PosAppBarLtrRow(children: trailingIcons),
        ],
      );
    } else {
      actionRow = PosAppBarLtrRow(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (clock != null) ...[
            clock,
            SizedBox(width: gap),
          ],
          for (var i = 0; i < belowPills.length; i++) ...[
            belowPills[i],
            SizedBox(width: gap),
          ],
          if (trailingIcons.isNotEmpty) ...trailingIcons,
        ],
      );
    }
  }

  return PosAppBarLtrRow(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ...?extraLeading,
      if (extraLeading != null && extraLeading.isNotEmpty) SizedBox(width: gap),
      actionRow,
    ],
  );
}

Widget? _posAppBarCashierInfoFromVm(BuildContext context) {
  try {
    final vm = context.watch<pvm.PosViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final branch = vm.branchName.trim();
    return PosAppBarCashierInfoBlock(
      userName: vm.cashierName,
      workshopName: vm.workshopName,
      branchLabel:
          branch.isEmpty ? '' : l10n.posHomeBranchPrefix(branch),
    );
  } catch (_) {
    return null;
  }
}

Widget _posYellowAppBarToolbar({
  required double height,
  required bool isTablet,
  required double gap,
  required Widget? leading,
  required Widget center,
  required Widget trailing,
}) {
  final horizontalPad = isTablet ? 14.0 : 12.0;
  final titleSideReserve = isTablet ? 200.0 : 168.0;

  return SizedBox(
    height: height,
    child: ColoredBox(
      color: AppColors.primaryLight,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: horizontalPad,
          end: horizontalPad,
          top: isTablet ? 16 : 14,
          bottom: isTablet ? 2 : 2,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading,
                      SizedBox(width: gap),
                    ],
                    const Spacer(),
                    trailing,
                  ],
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth - titleSideReserve)
                          .clamp(80.0, constraints.maxWidth),
                    ),
                    child: center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

String _posWidgetDigits(BuildContext context, Object? value) {
  return AppTranslationService.localizeDigitsForLanguage(
    value?.toString() ?? '',
    Localizations.localeOf(context).languageCode,
  );
}

String _posWidgetMoney(
  BuildContext context,
  num amount, {
  bool negative = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  final amt = _posWidgetDigits(context, amount.abs().toStringAsFixed(2));
  final money = l10n.posCommonSarAmount(amt);
  if (!negative) return money;
  return Localizations.localeOf(context).languageCode == 'ar'
      ? '$money-'
      : '-$money';
}

String _orderCardJobProgressLabel(PosOrder order) {
  final activeJobs = order.jobs.where((j) => !j.isCancelledJob).toList();
  final completedActive = activeJobs.where((j) {
    final s = j.status.toLowerCase();
    return s == 'completed' || s == 'invoiced' || s == 'edited';
  }).length;
  return '$completedActive/${activeJobs.length}';
}

bool _orderCardIsCorporateOrder(PosOrder order) =>
    order.isCorporateWalkIn || order.isCorporateBookingOrder;

bool _orderCardShowCorporateLine(PosOrder order) =>
    _orderCardIsCorporateOrder(order) &&
    order.selectedDepartmentNames.isNotEmpty;

// ── Reusable POS Screen AppBar (Back + Title + Global Icon) ──
class PosScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final FontWeight? titleFontWeight;
  final VoidCallback? onBack;
  final bool showBackButton;
  final bool showHamburger;
  final bool showGlobalLeft;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  /// Optional line under [title] (e.g. business date/time).
  final String? subtitle;
  /// When true, only the live clock is shown on the trailing side (store closing
  /// after reconcile — avoids swapping to a different [AppBar] implementation).
  final bool minimalTrailingActions;
  /// Extra widgets after sync, before globe/notification (e.g. Orders Hub printer IP).
  final List<Widget>? trailingPrefix;
  /// When true, keeps globe on the trailing side even on menu-level screens
  /// (e.g. legacy Orders Hub row). Prefer [showBackButton] for inner screens.
  final bool globeOnTrailing;
  /// When true, date/time pill sits beside the hamburger on the leading side
  /// (Orders Hub — SoftPOS / printer stay on the trailing side).
  final bool clockOnLeading;
  /// Hide the notification bell on the trailing side (e.g. on Notifications screen).
  final bool showNotificationIcon;
  /// Cashier name, workshop, and branch on the left (reads [PosViewModel]).
  final bool showCashierInfo;
  /// When true, leading menu button shows close (Orders Hub overlay rail).
  final bool menuOpen;

  const PosScreenAppBar({
    super.key,
    required this.title,
    this.titleFontWeight,
    this.subtitle,
    this.onBack,
    this.showBackButton = true,
    this.showHamburger = true,
    this.showGlobalLeft = false,
    this.onMenuPressed,
    this.actions,
    this.minimalTrailingActions = false,
    this.trailingPrefix,
    this.globeOnTrailing = false,
    this.clockOnLeading = false,
    this.showNotificationIcon = true,
    this.showCashierInfo = false,
    this.menuOpen = false,
  });

  double get _yellowBarHeight => kPosYellowAppBarHeight;

  @override
  Size get preferredSize => posAppBarPreferredSize(yellowHeight: _yellowBarHeight);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final double iconContainerSize = isTablet
        ? PosTabletLayout.appBarIconBox
        : 32;
    final double iconSize = isTablet ? PosTabletLayout.appBarIconGlyph : 16;
    final double appBarActionGap = isTablet ? 8 : 6;
    final shellLeftMenuRail = PosShellRailLayout.hasLeftMenuRail(context);
    final hideDrawerMenu =
        kPosHideDrawerMenuTabletLandscape(context) &&
        !showBackButton &&
        !showGlobalLeft;
    final showMenuLeading = !shellLeftMenuRail &&
        (showHamburger || onMenuPressed != null) &&
        !hideDrawerMenu;

    Widget? leadingMenu;
    if (showBackButton) {
      leadingMenu = IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: isTablet ? PosTabletLayout.appBarBackIcon : 28,
        ),
        onPressed: onBack ?? () => Navigator.pop(context),
      );
    } else if (showMenuLeading) {
      leadingMenu = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMenuPressed ?? PosShellScaffoldRegistry.openDrawer,
        child: Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 9),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryLight.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            menuOpen ? Icons.close_rounded : Icons.menu_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      );
    }

    final cashierInfo = showCashierInfo && !minimalTrailingActions
        ? _posAppBarCashierInfoFromVm(context)
        : null;

    // Menu / drawer screens: globe left. Pushed screens (back): globe right.
    final placeGlobeOnTrailing =
        !showGlobalLeft && (globeOnTrailing || showBackButton);
    final showGlobeLeading =
        !placeGlobeOnTrailing && !minimalTrailingActions;
    final Widget? globeLeading =
        showGlobeLeading ? _posAppBarGlobeButton(context, isTablet) : null;

    final Widget? leadingWidget =
        (leadingMenu != null || globeLeading != null || cashierInfo != null)
            ? (clockOnLeading && leadingMenu != null && cashierInfo == null)
                ? PosAppBarLeadingWithClock(
                    menu: (globeLeading != null)
                        ? PosAppBarLtrRow(
                            children: [
                              globeLeading,
                              SizedBox(width: appBarActionGap),
                              leadingMenu,
                            ],
                          )
                        : leadingMenu,
                    gap: appBarActionGap,
                    includeClock: true,
                  )
                : PosAppBarLeadingCluster(
                    menu: (globeLeading != null || leadingMenu != null)
                        ? PosAppBarLtrRow(
                            children: [
                              if (globeLeading != null) globeLeading,
                              if (globeLeading != null && leadingMenu != null)
                                SizedBox(width: appBarActionGap),
                              if (leadingMenu != null) leadingMenu,
                            ],
                          )
                        : null,
                    cashierInfo: cashierInfo,
                    gap: appBarActionGap,
                  )
            : null;

    final centerWidget = InkWell(
      onTap: shellLeftMenuRail ? null : PosShellScaffoldRegistry.openDrawer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: subtitle == null || subtitle!.trim().isEmpty
            ? Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: titleFontWeight ?? localeFontWeight(context, FontWeight.bold),
                  fontSize: isTablet ? PosTabletLayout.appBarTitleSize : 19,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: titleFontWeight ?? localeFontWeight(context, FontWeight.bold),
                      fontSize:
                          isTablet ? PosTabletLayout.appBarTitleSize : 19,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.65),
                      fontWeight: localeFontWeight(context, FontWeight.w700),
                      fontSize: isTablet ? 11 : 10,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
      ),
    );

    final barHeight = _yellowBarHeight;
    return buildPosYellowAppBarShell(
      context: context,
      yellowHeight: barHeight,
      yellowToolbar: _posYellowAppBarToolbar(
        height: barHeight,
        isTablet: isTablet,
        gap: appBarActionGap,
        leading: leadingWidget,
        center: centerWidget,
        trailing: _posAppBarTrailingActions(
          context,
          isTablet: isTablet,
          gap: appBarActionGap,
          trailingPrefix: trailingPrefix,
          minimalTrailingActions: minimalTrailingActions,
          globeOnTrailing: globeOnTrailing,
          includeGlobeOnTrailing: placeGlobeOnTrailing,
          showNotificationIcon: showNotificationIcon,
          extraLeading: actions,
          includeClock: !clockOnLeading,
        ),
      ),
    );
  }
}

class PosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String? infoTitle;
  final String? infoBranch;
  final String? infoTime;
  final double? customHeight;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final bool showDrawer;
  final bool showGlobalLeft;
  final String? customTitle;

  const PosAppBar({
    super.key,
    this.userName,
    this.infoTitle,
    this.infoBranch,
    this.infoTime,
    this.customHeight,
    this.showBackButton = false,
    this.onMenuPressed,
    this.showDrawer = true,
    this.showGlobalLeft = false,
    this.customTitle,
  });

  double get _yellowToolbarHeight {
    if (customHeight != null && customHeight! <= kPosYellowAppBarHeight) {
      return customHeight!;
    }
    return kPosYellowAppBarHeight;
  }

  @override
  Size get preferredSize => posAppBarPreferredSize(yellowHeight: _yellowToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final double iconContainerSize = isTablet
        ? PosTabletLayout.appBarIconBox
        : 32;
    final double iconSize = isTablet ? PosTabletLayout.appBarIconGlyph : 16;
    final double appBarActionGap = isTablet ? 8 : 6;
    final shellLeftMenuRail = PosShellRailLayout.hasLeftMenuRail(context);
    final hideDrawerMenu =
        showDrawer && kPosHideDrawerMenuTabletLandscape(context);
    final showDrawerLeading =
        showDrawer && !hideDrawerMenu && !shellLeftMenuRail;

    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: isTablet ? PosTabletLayout.appBarBackIcon : 28,
        ),
        onPressed: () => Navigator.maybePop(context),
      );
    } else if (showDrawerLeading) {
      leadingWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMenuPressed ?? PosShellScaffoldRegistry.openDrawer,
        child: Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 9),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryLight.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      );
    }

    final globeLeading = _posAppBarGlobeButton(context, isTablet);
    final Widget? leadingCluster = PosAppBarLeadingCluster(
      menu: PosAppBarLtrRow(
        children: [
          globeLeading,
          if (leadingWidget != null) ...[
            SizedBox(width: appBarActionGap),
            leadingWidget,
          ],
        ],
      ),
      gap: appBarActionGap,
    );

    final centerWidget = InkWell(
      onTap: showDrawer && !showBackButton && !shellLeftMenuRail
          ? PosShellScaffoldRegistry.openDrawer
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: customTitle != null
            ? Text(
                customTitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h2.copyWith(
                  color: Colors.black,
                  fontSize:
                      isTablet ? PosTabletLayout.appBarTitleSize : 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              )
            : SizedBox(
                height: isTablet ? PosTabletLayout.appBarLogoHeight : 28,
                child: Image.asset(
                  'assets/images/icons.png',
                  color: AppColors.secondaryLight,
                  colorBlendMode: BlendMode.srcIn,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.store,
                    color: AppColors.secondaryLight,
                    size: isTablet ? PosTabletLayout.appBarLogoHeight : 28,
                  ),
                ),
              ),
      ),
    );

    final barHeight = _posResolveAppBarHeight(context, custom: customHeight);
    return buildPosYellowAppBarShell(
      context: context,
      yellowHeight: barHeight,
      yellowToolbar: _posYellowAppBarToolbar(
        height: barHeight,
        isTablet: isTablet,
        gap: appBarActionGap,
        leading: leadingCluster,
        center: centerWidget,
        trailing: _posAppBarTrailingActions(
          context,
          isTablet: isTablet,
          gap: appBarActionGap,
        ),
      ),
    );
  }
}

class PosInfoBar extends StatelessWidget {
  final String title;
  final String branch;
  final String? time;

  const PosInfoBar({
    super.key,
    required this.title,
    required this.branch,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.fromLTRB(10, 0, 10, isTablet ? 12 : 8),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: isTablet
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Flexible(child: _buildInfoChip(context, Icons.person, title)),
          const Spacer(),
          Flexible(child: _buildInfoChip(context, null, branch)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData? icon,
    String text, {
    bool isBlack = false,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 6,
        vertical: isTablet ? 6 : 4,
      ), // Reduced horizontal padding on mobile to fit 3 items
      decoration: BoxDecoration(
        color: isBlack
            ? const Color(0xFF212529)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: isBlack
            ? null
            : Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isTablet ? 15 : 11, color: Colors.white),
            SizedBox(width: isTablet ? 8 : 4),
          ],
          Flexible(
            // Use Flexible to prevent overflow if text is long
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isBlack ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 11.5 : 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class UserChip extends StatelessWidget {
  final String name;
  final bool isTablet;

  const UserChip({super.key, required this.name, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: isTablet ? 220 : 140),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 14,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 14 : 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchHistoryData {
  final String vehicle;
  final String plate;
  final String customer;
  final String? phone;
  final String lastVisit;
  final String lastService;
  final bool isCorporate;

  const SearchHistoryData({
    required this.vehicle,
    required this.plate,
    required this.customer,
    this.phone,
    required this.lastVisit,
    required this.lastService,
    required this.isCorporate,
  });
}

class SearchHistoryItem extends StatelessWidget {
  final String vehicle;
  final String plate;
  final String customer;
  final String? phone;
  final String lastVisit;
  final String lastService;
  final String? technicianName;
  final String? orderNumber;
  final bool isCorporate;
  final VoidCallback? onContinue;
  final VoidCallback? onViewHistory;
  final VoidCallback? onPrintInvoice;
  final VoidCallback? onDownloadInvoice;
  final VoidCallback? onSeeInvoiceDetails;
  final VoidCallback? onSalesReturn;
  /// Smaller padding / type (POS home search results).
  final bool compactLayout;
  /// When true, card sizes to content (no [Spacer]) — use in scroll lists.
  final bool shrinkWrap;

  const SearchHistoryItem({
    super.key,
    required this.vehicle,
    required this.plate,
    required this.customer,
    this.phone,
    required this.lastVisit,
    required this.lastService,
    this.technicianName,
    this.orderNumber,
    required this.isCorporate,
    this.onContinue,
    this.onViewHistory,
    this.onPrintInvoice,
    this.onDownloadInvoice,
    this.onSeeInvoiceDetails,
    this.onSalesReturn,
    this.compactLayout = false,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isArabic = langCode == 'ar';
    final d = compactLayout;
    String digits(Object? value) =>
        AppTranslationService.localizeDigitsForLanguage(
          value?.toString() ?? '',
          langCode,
        );
    final localizedPlate = digits(plate);
    final localizedPhone = phone != null ? digits(phone!.trim()) : null;
    final localizedLastVisit = digits(lastVisit);
    final localizedOrderNumber = orderNumber != null
        ? digits(orderNumber)
        : null;
    final plateLine = isArabic
        ? 'اللوحة: $localizedPlate${(localizedPhone != null && localizedPhone.isNotEmpty) ? '  •  $localizedPhone' : ''}'
        : 'Plate: $localizedPlate${(localizedPhone != null && localizedPhone.isNotEmpty) ? '  •  $localizedPhone' : ''}';
    final historyLine = orderNumber != null
        ? (isArabic
              ? '$localizedLastVisit ($lastService)  •  الطلب: #$localizedOrderNumber'
              : '$localizedLastVisit ($lastService)  •  Order: #$localizedOrderNumber')
        : '$localizedLastVisit ($lastService)';
    // Reverting to compact scaling for both mobile and tablet as per user request
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        d ? 12 : 14,
        d ? 8 : 10,
        d ? 12 : 14,
        d ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(d ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(d ? 5 : 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: AppColors.primaryLight,
                  size: d ? 18 : 20,
                ),
              ),
              SizedBox(width: d ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            customer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: localeFontWeight(context, FontWeight.w800),
                              fontSize: d ? 12.5 : 14,
                            ),
                          ),
                        ),
                        if (isCorporate) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: d ? 6 : 8,
                              vertical: d ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(d ? 5 : 6),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              'CORP',
                              style: TextStyle(
                                color: const Color(0xFF1E88E5), // Blue.shade700
                                fontSize: d ? 9 : 10,
                                fontWeight: localeFontWeight(context, FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                        if (onPrintInvoice != null ||
                            onDownloadInvoice != null ||
                            onSeeInvoiceDetails != null) ...[
                          const SizedBox(width: 6),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            offset: const Offset(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'print') {
                                onPrintInvoice?.call();
                              } else if (value == 'download') {
                                onDownloadInvoice?.call();
                              } else if (value == 'details') {
                                onSeeInvoiceDetails?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              if (onSeeInvoiceDetails != null)
                                PopupMenuItem<String>(
                                  value: 'details',
                                  height: 40,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 16,
                                        color: AppColors.secondaryLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isArabic
                                            ? 'عرض الفاتورة'
                                            : 'View Invoice',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: localeFontWeight(
                                            context,
                                            FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (onDownloadInvoice != null)
                                PopupMenuItem<String>(
                                  value: 'download',
                                  height: 40,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chat_outlined,
                                        size: 16,
                                        color: AppColors.secondaryLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isArabic
                                            ? 'إرسال واتساب'
                                            : 'Send WhatsApp',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: localeFontWeight(
                                            context,
                                            FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (onPrintInvoice != null)
                                PopupMenuItem<String>(
                                  value: 'print',
                                  height: 40,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.print_rounded,
                                        size: 16,
                                        color: AppColors.secondaryLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isArabic
                                            ? 'طباعة الفاتورة'
                                            : 'Print Invoice',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: localeFontWeight(
                                            context,
                                            FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            child: Padding(
                              padding: EdgeInsets.all(d ? 5 : 6),
                              child: Icon(
                                Icons.more_vert,
                                color: AppColors.secondaryLight,
                                size: d ? 19 : 22,
                              ),
                            ),
                          ),
                        ] else if (onViewHistory != null) ...[
                          const SizedBox(width: 6),
                          Material(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(d ? 9 : 10),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: onViewHistory,
                              borderRadius: BorderRadius.circular(d ? 9 : 10),
                              child: Padding(
                                padding: EdgeInsets.all(d ? 5 : 6),
                                child: Icon(
                                  Icons.keyboard_arrow_right,
                                  color: AppColors.secondaryLight,
                                  size: d ? 19 : 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (vehicle.trim().isNotEmpty &&
                        vehicle.toLowerCase() != 'no vehicle') ...[
                      SizedBox(height: d ? 2 : 3),
                      Text(
                        vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: d ? 10.5 : 11.5,
                        ),
                      ),
                    ],
                    SizedBox(height: d ? 3 : 4),
                    Text(
                      plateLine,
                      textDirection: isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: d ? 10.5 : 11.5,
                      ),
                    ),
                    if ((technicianName ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: d ? 2 : 3),
                      Text(
                        isArabic
                            ? 'الفني: ${technicianName!.trim()}'
                            : 'Technician: ${technicianName!.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: d ? 10.5 : 11.5,
                        ),
                      ),
                    ],
                    SizedBox(height: d ? 4 : 5),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: d ? 6 : 8,
                        vertical: d ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(d ? 8 : 10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: d ? 12 : 13,
                            color: Colors.amber.shade700,
                          ),
                          SizedBox(width: d ? 4 : 5),
                          Flexible(
                            child: Text(
                              historyLine,
                              textDirection: isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: d ? 9.5 : 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!shrinkWrap) const Spacer(),
          if (shrinkWrap) SizedBox(height: d ? 8 : 10),
          Row(
            children: [
              if (onContinue != null) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.secondaryLight,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: d ? 8 : 10,
                        vertical: d ? 5 : 6,
                      ),
                      minimumSize: Size(0, d ? 30 : 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(d ? 10 : 12),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'متابعة الطلب' : 'Continue Order',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontWeight: localeFontWeight(context, FontWeight.w700),
                        fontSize: d ? 10 : 11,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onSalesReturn ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryLight,
                    foregroundColor: AppColors.onSecondaryLight,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: d ? 5 : 6),
                    minimumSize: Size(0, d ? 30 : 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(d ? 10 : 12),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'مرتجع المبيعات' : 'Sales Return',
                    style: TextStyle(
                      fontWeight: localeFontWeight(context, FontWeight.w700),
                      fontSize: d ? 10 : 11,
                      color: AppColors.onSecondaryLight,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PosBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PosBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
              _buildNavItem(context, 1, Icons.inventory_2_outlined, 'Products'),
              _buildNavItem(context, 2, Icons.receipt_long_outlined, 'Orders'),
              _buildNavItem(context, 3, Icons.store_rounded, 'Store Closing'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? 25 : 22,
              color: isSelected ? AppColors.primaryLight : Colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isTablet ? 11 : 10,
                fontWeight: isSelected ? localeFontWeight(context, FontWeight.w700) : FontWeight.w500,
                color: isSelected ? AppColors.secondaryLight : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PosSearchBar extends StatelessWidget {
  /// Shared Workshop POS search metrics (Orders Hub reference).
  static const double workshopHeightTablet = 36;
  static const double workshopHeightPhone = 38;
  static const double workshopCornerRadius = 10;
  static const double workshopTrailingIconRadius = 8;
  static const double workshopTrailingIconSize = 14;
  static const double workshopTrailingIconPadding = 6;

  static double workshopHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600
          ? workshopHeightTablet
          : workshopHeightPhone;

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextCapitalization textCapitalization;
  /// Tighter padding and typography (e.g. POS home hero).
  final bool compact;
  /// Even smaller metrics when [compact] is true (legacy / home).
  final bool compactTight;
  /// Overrides default corner radius (lower = less rounded).
  final double? cornerRadius;
  /// Overrides yellow search-button corner radius when [cornerRadius] is set.
  final double? trailingIconRadius;
  /// Overrides magnifying-glass size inside the yellow button.
  final double? trailingIconSize;
  /// Overrides padding inside the yellow button.
  final double? trailingIconPadding;

  const PosSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search...',
    this.focusNode,
    this.onTap,
    this.inputFormatters,
    this.autofocus = false,
    this.onSubmitted,
    this.onClear,
    this.textCapitalization = TextCapitalization.none,
    this.compact = false,
    this.compactTight = false,
    this.cornerRadius,
    this.trailingIconRadius,
    this.trailingIconSize,
    this.trailingIconPadding,
  });

  /// Workshop POS standard search field styling.
  const PosSearchBar.workshop({
    super.key,
    this.controller,
    this.onChanged,
    required this.hintText,
    this.focusNode,
    this.onTap,
    this.inputFormatters,
    this.autofocus = false,
    this.onSubmitted,
    this.onClear,
    this.textCapitalization = TextCapitalization.none,
  })  : compact = true,
        compactTight = false,
        cornerRadius = workshopCornerRadius,
        trailingIconRadius = workshopTrailingIconRadius,
        trailingIconSize = workshopTrailingIconSize,
        trailingIconPadding = workshopTrailingIconPadding;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final tight = compact && compactTight;
    final fieldFont = compact
        ? (tight
            ? (isTablet ? 11.0 : 12.0)
            : (isTablet ? 12.0 : 13.0))
        : (isTablet ? 13.0 : 14.0);
    final radius = cornerRadius ??
        (compact ? (tight ? 12.0 : 14.0) : 16.0);
    final iconRadius = trailingIconRadius ??
        (compact ? (tight ? 7.0 : 9.0) : 12.0);
    final hPad = compact
        ? (tight
            ? (isTablet ? 12.0 : 14.0)
            : (isTablet ? 14.0 : 16.0))
        : (isTablet ? 16.0 : 20.0);
    final vPad = compact
        ? (tight
            ? (isTablet ? 7.0 : 8.0)
            : (isTablet ? 9.0 : 10.0))
        : (isTablet ? 12.0 : 14.0);
    final iconPad = trailingIconPadding ??
        (compact ? (tight ? 5.0 : 6.0) : 10.0);
    final iconSize = trailingIconSize ??
        (compact ? (tight ? 13.0 : 14.0) : 18.0);
    final trailingMargin = compact ? 5.0 : 6.0;

    Widget bar({required bool showClear}) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                textCapitalization: textCapitalization,
                hintLocales: appKeyboardHintLocales(context),
                textAlign: TextAlign.left,
                onTap: onTap,
                onSubmitted: onSubmitted,
                style: TextStyle(
                  fontSize: fieldFont,
                  color: const Color(0xFF1E2124),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: fieldFont,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: vPad,
                  ),
                ),
                inputFormatters: inputFormatters ?? [EnglishNumberFormatter()],
                onChanged: onChanged,
              ),
            ),
            GestureDetector(
              onTap: showClear
                  ? () {
                      if (onClear != null) {
                        onClear!();
                      } else {
                        controller?.clear();
                        onChanged?.call('');
                      }
                    }
                  : null,
              child: Container(
                margin: EdgeInsets.only(right: trailingMargin),
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCC247),
                  borderRadius: BorderRadius.circular(iconRadius),
                ),
                child: Icon(
                  showClear ? Icons.close_rounded : Icons.search,
                  color: const Color(0xFF1E2124),
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final c = controller;
    if (c == null) return bar(showClear: false);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => bar(showClear: c.text.trim().isNotEmpty),
    );
  }
}

/// Fixed-height Workshop POS search bar — use this across the POS shell.
class PosWorkshopSearchBar extends StatelessWidget {
  const PosWorkshopSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    required this.hintText,
    this.focusNode,
    this.onTap,
    this.inputFormatters,
    this.autofocus = false,
    this.onSubmitted,
    this.onClear,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PosSearchBar.workshopHeight(context),
      child: PosSearchBar.workshop(
        controller: controller,
        onChanged: onChanged,
        hintText: hintText,
        focusNode: focusNode,
        onTap: onTap,
        inputFormatters: inputFormatters,
        autofocus: autofocus,
        onSubmitted: onSubmitted,
        onClear: onClear,
        textCapitalization: textCapitalization,
      ),
    );
  }
}

class OrderItemCard extends StatefulWidget {
  final PosOrder order;
  final bool isTablet;
  const OrderItemCard({super.key, required this.order, required this.isTablet});

  @override
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  PosOrderJob? _getHighestJobById() {
    if (widget.order.jobs.isEmpty) return null;
    final sorted = List<PosOrderJob>.from(widget.order.jobs);
    sorted.sort(
      (a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0),
    );
    return sorted.last;
  }

  void _openEditOrderFlow(BuildContext context) {
    final posVm = context.read<pvm.PosViewModel>();

    String departmentId = '1';
    String departmentName = 'All';

    if (widget.order.jobs.isNotEmpty) {
      final latestJob = _getHighestJobById()!;
      if (latestJob.department.isNotEmpty) {
        departmentName = latestJob.department;
      }
      if (latestJob.items.isNotEmpty &&
          latestJob.items.first.departmentId.isNotEmpty) {
        departmentId = latestJob.items.first.departmentId;
      }
    }

    if (departmentId == '1' && widget.order.items.isNotEmpty) {
      for (final item in widget.order.items) {
        final itemDepartmentId = item['departmentId']?.toString();
        if (itemDepartmentId != null && itemDepartmentId.isNotEmpty) {
          departmentId = itemDepartmentId;
          final itemDepartmentName = item['departmentName']?.toString();
          if (itemDepartmentName != null && itemDepartmentName.isNotEmpty) {
            departmentName = itemDepartmentName;
          }
          break;
        }
      }
    }

    List<dynamic> preSelectedItems = [];
    if (widget.order.jobs.isNotEmpty) {
      final highestJob = _getHighestJobById()!;
      for (final item in dedupeCashierServiceLinesForPosDisplay(
        highestJob.items,
      )) {
        preSelectedItems.add({
          item.itemType == 'service' ? 'serviceId' : 'productId':
              item.productId,
          'quantity': item.qty,
          'discountType': item.discountType,
          'discountValue': item.discountValue ?? 0.0,
          if (item.unitPrice > 0) 'unitPrice': item.unitPrice,
        });
      }
    } else if (widget.order.items.isNotEmpty) {
      preSelectedItems = widget.order.items;
    }

    posVm.clearCart();
    posVm.setCustomerData(
      name: widget.order.customerName,
      vat: widget.order.customer?.vatNumber ?? '',
      mobile: widget.order.customer?.mobile ?? '',
      vehicleNumber: widget.order.plateNumber,
      vinNumber: widget.order.vehicle?.vin ?? '',
      make: widget.order.vehicle?.make ?? '',
      model: widget.order.vehicle?.model ?? '',
      odometer: widget.order.odometerReading,
      previousOrderId: widget.order.id,
      vehicleYear: widget.order.vehicle?.year ?? '',
      vehicleColor: widget.order.vehicle?.color ?? '',
    );
    posVm.setEditOrderContext(
      departmentId: departmentId,
      preSelectedItems: preSelectedItems,
      order: widget.order,
      completingOrderId: widget.order.jobs.isNotEmpty
          ? _getHighestJobById()!.id
          : widget.order.id,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PosAddCustomerView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInvoiced = widget.order.status.toLowerCase() == 'invoiced';

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isInvoiced
              ? null
              : () {
                  _showOrderDetailsSheet(
                    context,
                    widget.order,
                    widget.isTablet,
                  );
                },
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isTablet ? 10 : 10,
                widget.isTablet ? 7 : 8,
                widget.isTablet ? 10 : 10,
                widget.isTablet ? 6 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Order #${widget.order.id.split('-').last.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: widget.isTablet ? 10 : 8.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.layers_rounded,
                                        size: widget.isTablet ? 13 : 9,
                                        color: const Color(0xFF1E2124),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.order.jobsCount} JOB',
                                        style: TextStyle(
                                          fontSize: widget.isTablet ? 8 : 7.5,
                                          fontWeight: localeFontWeight(context, FontWeight.w700),
                                          color: const Color(0xFF1E2124),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildStatusPill(context, widget.order),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/car icon.png',
                                  width: 16,
                                  height: 16,
                                  color: const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Builder(
                                    builder: (ctx) {
                                      final langCode = Localizations.localeOf(
                                        ctx,
                                      ).languageCode;
                                      final plateRaw = widget.order.plateNumber
                                          .trim();
                                      if (plateRaw.isEmpty) {
                                        return Text(
                                          AppLocalizations.of(
                                            ctx,
                                          )!.posOrdersNoPlate,
                                          style: TextStyle(
                                            fontSize: widget.isTablet ? 12 : 11,
                                            fontWeight: localeFontWeight(context, FontWeight.w700),
                                            color: const Color(0xFF1E2124),
                                            height: 1.1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }
                                      final formatted =
                                          formatVehiclePlateLettersFirst(
                                            plateRaw,
                                          );
                                      final plate = langCode == 'ar'
                                          ? PlateTransliterator.localize(
                                              formatted,
                                              langCode,
                                            )
                                          : formatted;
                                      return Text(
                                        plate,
                                        style: TextStyle(
                                          fontSize: widget.isTablet ? 12 : 11,
                                          fontWeight: localeFontWeight(context, FontWeight.w700),
                                          color: const Color(0xFF1E2124),
                                          height: 1.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                                Builder(
                                  builder: (ctx) {
                                    final langCode = Localizations.localeOf(
                                      ctx,
                                    ).languageCode;
                                    final label = _orderCardJobProgressLabel(
                                      widget.order,
                                    );
                                    return Text(
                                      AppTranslationService.localizeDigitsForLanguage(
                                        label,
                                        langCode,
                                      ),
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 10 : 10,
                                        fontWeight: localeFontWeight(context, FontWeight.w900),
                                        color: const Color(0xFF64748B),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (_orderCardShowCorporateLine(widget.order)) ...[
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 22,
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.posPaymentCorporate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: widget.isTablet ? 9 : 8,
                                    height: 1.1,
                                    fontWeight: localeFontWeight(context, FontWeight.w700),
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (posOrderCanCashierCancel(widget.order))
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => showCashierCancelOrderDialog(
                                context,
                                widget.order.id,
                              ),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: widget.isTablet ? 28 : 26,
                                height: widget.isTablet ? 28 : 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E2124),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: widget.isTablet ? 16 : 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: widget.isTablet ? 6 : 7),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildPremiumDetailItem(
                          widget.order.customerName.isEmpty
                              ? (widget.order.carModel.isNotEmpty
                                    ? widget.order.carModel
                                    : '—')
                              : widget.order.customerName,
                          subtitle:
                              widget.order.carModel.isNotEmpty &&
                                  widget.order.customerName.isNotEmpty
                              ? widget.order.carModel
                              : null,
                          isTablet: widget.isTablet,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: _buildPremiumDetailItem(
                          DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.parse(widget.order.date)),
                          subtitle: 'Odo: ${widget.order.odometerReading} km',
                          crossAxisAlignment: CrossAxisAlignment.end,
                          isTablet: widget.isTablet,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.isTablet ? 4 : 3),
                  if (_orderCardIsCorporateOrder(widget.order) &&
                      widget.order.selectedDepartmentNames.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isTablet ? 10 : 8,
                        vertical: widget.isTablet ? 6 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.posOrdersSelectedDepartments,
                            style: TextStyle(
                              fontSize: widget.isTablet ? 10 : 9,
                              color: const Color(0xFF475569),
                              fontWeight: localeFontWeight(context, FontWeight.w700),
                            ),
                          ),
                          SizedBox(height: widget.isTablet ? 4 : 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.order.selectedDepartmentNames
                                .map(
                                  (name) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 9.5 : 9,
                                        color: const Color(0xFF1E3A8A),
                                        fontWeight: localeFontWeight(context, FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: widget.isTablet ? 4 : 3),
                  ],
                  if (_orderCardIsCorporateOrder(widget.order) &&
                      widget.order.selectedDepartmentNames.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isTablet ? 10 : 8,
                        vertical: widget.isTablet ? 6 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFEF08A)),
                      ),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.posOrdersDeptNotReturnedInPayload,
                        style: TextStyle(
                          fontSize: widget.isTablet ? 10 : 9,
                          color: const Color(0xFF854D0E),
                          fontWeight: localeFontWeight(context, FontWeight.w700),
                        ),
                      ),
                    ),
                    SizedBox(height: widget.isTablet ? 4 : 3),
                  ],
                  Builder(
                    builder: (_) {
                      return Row(
                        children: [
                          Icon(
                            Icons.engineering_rounded,
                            size: widget.isTablet ? 11 : 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.posOrdersTechnicianLabel(
                                widget.order.assignedTechnicianNames
                                        .trim()
                                        .isEmpty
                                    ? AppLocalizations.of(
                                        context,
                                      )!.posOrdersTechnicianNone
                                    : widget.order.assignedTechnicianNames,
                              ),
                              style: TextStyle(
                                fontSize: widget.isTablet ? 8.5 : 8,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: widget.isTablet ? 6 : 7),
                  Builder(
                    builder: (context) {
                      String displayStatus = widget.order.displayJobStatus
                          .toLowerCase();
                      final isCorporateOrder = widget.order.isCorporateWalkIn;
                      final isCorporateUnapproved =
                          isCorporateOrder &&
                          widget.order.isCorporateUnapproved;
                      final isCorporateWaiting =
                          isCorporateOrder &&
                          widget.order.isWaitingCorporateApproval;
                      final isCorporateRejected =
                          isCorporateOrder &&
                          widget.order.isRejectedByCorporate;
                      final canShowCancelOrder = posOrderCanCashierCancel(
                        widget.order,
                      );
                      final canShowOrderDetails =
                          displayStatus != 'completed' &&
                          displayStatus != 'completed by technician' &&
                          displayStatus != 'invoiced' &&
                          displayStatus != 'pending assignment' &&
                          displayStatus != 'cancelled';

                      if (displayStatus == 'completed by technician') {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: widget.isTablet ? 5 : 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer<pvm.PosViewModel>(
                                    builder: (context, posVm, child) {
                                      final isCurrentOrderLoading =
                                          posVm.isInvoiceLoading &&
                                          posVm.loadingOrderId ==
                                              widget.order.id;

                                      return _buildActionButton(context: context,
                                        onPressed: isCurrentOrderLoading
                                            ? null
                                            : () async {
                                                if (context.mounted) {
                                                  // Get department info from items first, then Jobs, then fallback
                                                  String deptName = 'All';
                                                  String deptId = '1';

                                                  bool foundDept = false;

                                                  if (widget
                                                      .order
                                                      .jobs
                                                      .isNotEmpty) {
                                                    final job =
                                                        _getHighestJobById()!;
                                                    if (job
                                                        .department
                                                        .isNotEmpty) {
                                                      deptName = job.department;
                                                    }
                                                    if (job.items.isNotEmpty &&
                                                        job
                                                            .items
                                                            .first
                                                            .departmentId
                                                            .isNotEmpty) {
                                                      deptId = job
                                                          .items
                                                          .first
                                                          .departmentId;
                                                      foundDept = true;
                                                      if (job
                                                          .items
                                                          .first
                                                          .departmentName
                                                          .isNotEmpty) {
                                                        deptName = job
                                                            .items
                                                            .first
                                                            .departmentName;
                                                      }
                                                    }
                                                  }

                                                  if (!foundDept &&
                                                      widget
                                                          .order
                                                          .items
                                                          .isNotEmpty) {
                                                    for (final item
                                                        in widget.order.items) {
                                                      if (item['departmentId'] !=
                                                              null &&
                                                          item['departmentId']
                                                              .toString()
                                                              .isNotEmpty) {
                                                        deptId =
                                                            item['departmentId']
                                                                .toString();
                                                        if (item['departmentName'] !=
                                                            null) {
                                                          deptName =
                                                              item['departmentName']
                                                                  .toString();
                                                        }
                                                        foundDept = true;
                                                        break;
                                                      }
                                                    }
                                                  }

                                                  if (!foundDept &&
                                                      widget
                                                          .order
                                                          .jobs
                                                          .isNotEmpty) {
                                                    try {
                                                      final matchedProduct = posVm
                                                          .allProducts
                                                          .firstWhere(
                                                            (p) =>
                                                                p.departmentName
                                                                        ?.toLowerCase() ==
                                                                    deptName
                                                                        .toLowerCase() &&
                                                                p.departmentId !=
                                                                    null,
                                                          );
                                                      deptId = matchedProduct
                                                          .departmentId!;
                                                    } catch (e) {
                                                      // Ensure valid fallback
                                                    }
                                                  }

                                                  List<dynamic> preSelected =
                                                      [];
                                                  if (widget
                                                      .order
                                                      .jobs
                                                      .isNotEmpty) {
                                                    final highestJob =
                                                        _getHighestJobById()!;
                                                    for (var item
                                                        in highestJob.items) {
                                                      preSelected.add({
                                                        item.itemType ==
                                                                    'service'
                                                                ? 'serviceId'
                                                                : 'productId':
                                                            item.productId,
                                                        'quantity': item.qty,
                                                        'discountType':
                                                            item.discountType,
                                                        'discountValue':
                                                            item.discountValue ??
                                                            0.0,
                                                      });
                                                    }
                                                  } else if (widget
                                                      .order
                                                      .items
                                                      .isNotEmpty) {
                                                    preSelected =
                                                        widget.order.items;
                                                  }
                                                  posVm.clearCart();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => PosProductGridView(
                                                        departmentName:
                                                            deptName,
                                                        departmentId: deptId,
                                                        preSelectedItems:
                                                            preSelected,
                                                        completingOrderId:
                                                            widget
                                                                .order
                                                                .jobs
                                                                .isNotEmpty
                                                            ? widget.order.jobs
                                                                  .reduce(
                                                                    (a, b) =>
                                                                        (int.tryParse(a.id) ??
                                                                                0) >
                                                                            (int.tryParse(b.id) ??
                                                                                0)
                                                                        ? a
                                                                        : b,
                                                                  )
                                                                  .id
                                                            : widget.order.id,
                                                        completingOrder:
                                                            widget.order,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                        isLoading: isCurrentOrderLoading,
                                        icon:
                                            Icons.check_circle_outline_rounded,
                                        label: AppLocalizations.of(
                                          context,
                                        )!.posOrdersMarkComplete,
                                        color: AppColors.secondaryLight,
                                        isSecondary: true,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: widget.isTablet ? 8 : 6),
                                Expanded(
                                  child: _buildActionButton(context: context,
                                    onPressed: () {
                                      _showOrderDetailsSheet(
                                        context,
                                        widget.order,
                                        widget.isTablet,
                                      );
                                    },
                                    icon: Icons.visibility_outlined,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.posDetailsTitle,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      if (displayStatus == 'completed' ||
                          displayStatus == 'invoiced' ||
                          displayStatus.contains('pending') ||
                          isCorporateUnapproved ||
                          isCorporateWaiting ||
                          isCorporateRejected) {
                        final isInvoiced =
                            widget.order.status.toLowerCase() == 'invoiced';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: widget.isTablet ? 4 : 3),
                            if (isCorporateWaiting)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: widget.isTablet ? 8 : 6,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    'Waiting corporate approval',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: localeFontWeight(context, FontWeight.w700),
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            if (isCorporateRejected)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: widget.isTablet ? 8 : 6,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    widget.order.corporateApprovalRejectionReason
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? 'Rejected by corporate: ${widget.order.corporateApprovalRejectionReason!.trim()}'
                                        : 'Rejected by corporate',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: localeFontWeight(context, FontWeight.w700),
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ),
                            if (isCorporateUnapproved)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: widget.isTablet ? 10 : 8,
                                ),
                                child: _buildActionButton(context: context,
                                  onPressed: () => _openEditOrderFlow(context),
                                  icon: Icons.edit_rounded,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.posOrdersEditOrder,
                                  color: AppColors.primaryLight,
                                  labelFontSize: 12,
                                ),
                              ),
                            if ((displayStatus.contains('pending') ||
                                    displayStatus.contains('draft')) &&
                                !isCorporateWaiting &&
                                !isCorporateRejected &&
                                !isCorporateUnapproved)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: widget.isTablet ? 8 : 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(context: context,
                                        onPressed: () {
                                          if (displayStatus ==
                                              'pending assignment') {
                                            _openEditOrderFlow(context);
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) {
                                                final j =
                                                    widget.order.jobs.isNotEmpty
                                                    ? _getHighestJobById()
                                                    : null;
                                                return PosTechnicianAssignmentView(
                                                  jobId:
                                                      j?.id ?? widget.order.id,
                                                  departmentName:
                                                      j?.department ??
                                                      widget
                                                          .order
                                                          .latestJob
                                                          ?.department,
                                                  departmentId: j?.departmentId,
                                                  initialAssignedTechnicians:
                                                      j?.distinctActiveTechnicians ??
                                                      const [],
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        icon: Icons.assignment_ind_rounded,
                                        label:
                                            displayStatus ==
                                                'pending assignment'
                                            ? AppLocalizations.of(
                                                context,
                                              )!.posOrdersEditOrder
                                            : AppLocalizations.of(
                                                context,
                                              )!.posProductForwardTechnician,
                                        color: AppColors.primaryLight,
                                        labelFontSize: 12,
                                      ),
                                    ),
                                    if (canShowCancelOrder) ...[
                                      SizedBox(width: widget.isTablet ? 8 : 6),
                                      Expanded(
                                        child: _buildActionButton(context: context,
                                          onPressed: () =>
                                              showCashierCancelOrderDialog(
                                                context,
                                                widget.order.id,
                                              ),
                                          icon: Icons.cancel_outlined,
                                          label: AppLocalizations.of(
                                            context,
                                          )!.posOrdersCancelOrder,
                                          color: AppColors.secondaryLight,
                                          isSecondary: true,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            if (canShowOrderDetails) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(context: context,
                                      onPressed: () {
                                        _showOrderDetailsSheet(
                                          context,
                                          widget.order,
                                          widget.isTablet,
                                        );
                                      },
                                      icon: Icons.visibility_outlined,
                                      label: AppLocalizations.of(
                                        context,
                                      )!.posDetailsTitle,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (!(displayStatus.contains('pending') ||
                                    displayStatus.contains('draft')) &&
                                !isCorporateWaiting &&
                                !isCorporateRejected &&
                                !isCorporateUnapproved)
                              Row(
                                children: [
                                  Expanded(
                                    child: Consumer<pvm.PosViewModel>(
                                      builder: (context, posVm, child) {
                                        final isCurrentOrderLoading =
                                            posVm.isInvoiceLoading &&
                                            posVm.loadingOrderId ==
                                                widget.order.id;

                                        return _buildActionButton(context: context,
                                          onPressed: posVm.isInvoiceLoading
                                              ? null
                                              : () async {
                                                  if (isInvoiced) {
                                                    // Fetch and show existing invoice
                                                    final response = await posVm
                                                        .fetchInvoiceByOrder(
                                                          widget.order.id,
                                                        );
                                                    if (response != null &&
                                                        response.success &&
                                                        response.invoice !=
                                                            null &&
                                                        context.mounted) {
                                                      final inv =
                                                          invoiceWithMergedCustomerTax(
                                                        response.invoice!,
                                                        widget
                                                            .order
                                                            .customer
                                                            ?.vatNumber,
                                                      );
                                                      await showInvoiceDialogAfterPrintPrefetch(
                                                        context: context,
                                                        invoice: inv,
                                                        paymentMethodText:
                                                            invoiceDialogPaymentMethodText(
                                                          inv,
                                                        ),
                                                        maintenanceChecksFallback:
                                                            widget
                                                                .order
                                                                .maintenanceChecks,
                                                        builder: (ctx) =>
                                                            InvoiceDialog(
                                                          invoice: inv,
                                                          maintenanceChecksFallback:
                                                              widget
                                                                  .order
                                                                  .maintenanceChecks,
                                                        ),
                                                      );
                                                    } else if (response !=
                                                            null &&
                                                        !response.success &&
                                                        context.mounted) {
                                                      ToastService.showError(
                                                        context,
                                                        response.message,
                                                      );
                                                    }
                                                  } else {
                                                    if (!widget
                                                        .order
                                                        .meetsCashierInvoicePrerequisites) {
                                                      ToastService.showError(
                                                        context,
                                                        'Order is not ready for invoicing.',
                                                      );
                                                      return;
                                                    }
                                                    final fresh =
                                                        await posVm
                                                            .loadCashierOrderDetail(
                                                      widget.order.id,
                                                    );
                                                    final reviewOrder =
                                                        fresh ?? widget.order;
                                                    if (context.mounted) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              PosOrderReviewView(
                                                                order:
                                                                    reviewOrder,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                          isLoading: isCurrentOrderLoading,
                                          icon: isInvoiced
                                              ? Icons.receipt_long_rounded
                                              : Icons.auto_awesome_rounded,
                                          label: isInvoiced
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.posOrdersInvoice
                                              : AppLocalizations.of(
                                                  context,
                                                )!.posOrdersGenInvoice,
                                          color: isInvoiced
                                              ? AppColors.secondaryLight
                                              : AppColors.primaryLight,
                                        );
                                      },
                                    ),
                                  ),
                                  if (!isInvoiced)
                                    SizedBox(width: widget.isTablet ? 8 : 6),
                                  if (!isInvoiced)
                                    Expanded(
                                      child: Consumer<pvm.PosViewModel>(
                                        builder: (context, posVm, child) {
                                          return _buildActionButton(context: context,
                                            onPressed: () {
                                              posVm.clearCart();
                                              posVm.setCustomerData(
                                                name: widget.order.customerName,
                                                vat:
                                                    widget
                                                        .order
                                                        .customer
                                                        ?.vatNumber ??
                                                    '',
                                                mobile:
                                                    widget
                                                        .order
                                                        .customer
                                                        ?.mobile ??
                                                    '',
                                                vehicleNumber:
                                                    widget.order.plateNumber,
                                                vinNumber:
                                                    widget.order.vehicle?.vin ??
                                                    '',
                                                make:
                                                    widget
                                                        .order
                                                        .vehicle
                                                        ?.make ??
                                                    '',
                                                model:
                                                    widget
                                                        .order
                                                        .vehicle
                                                        ?.model ??
                                                    '',
                                                odometer: widget
                                                    .order
                                                    .odometerReading,
                                                previousOrderId:
                                                    widget.order.id,
                                                vehicleYear:
                                                    widget
                                                        .order
                                                        .vehicle
                                                        ?.year ??
                                                    '',
                                                vehicleColor:
                                                    widget
                                                        .order
                                                        .vehicle
                                                        ?.color ??
                                                    '',
                                              );
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PosDepartmentView(),
                                                ),
                                              );
                                            },
                                            icon: Icons.add_business_rounded,
                                            label: AppLocalizations.of(
                                              context,
                                            )!.posOrdersAddDept,
                                            color: AppColors.secondaryLight,
                                            isSecondary: true,
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        );
                      }
                      if (canShowCancelOrder) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: widget.isTablet ? 4 : 3),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(context: context,
                                    onPressed: canShowOrderDetails
                                        ? () {
                                            _showOrderDetailsSheet(
                                              context,
                                              widget.order,
                                              widget.isTablet,
                                            );
                                          }
                                        : null,
                                    icon: Icons.visibility_outlined,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.posDetailsTitle,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                SizedBox(width: widget.isTablet ? 8 : 6),
                                Expanded(
                                  child: _buildActionButton(context: context,
                                    onPressed: () =>
                                        showCashierCancelOrderDialog(
                                          context,
                                          widget.order.id,
                                        ),
                                    icon: Icons.cancel_outlined,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.posOrdersCancelOrder,
                                    color: AppColors.secondaryLight,
                                    isSecondary: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the cashier may cancel the whole order (`POST /cashier/order/:id/cancel`).
bool posOrderCanCashierCancel(PosOrder order) {
  final normalizedStatus = order.status.toLowerCase();
  if (normalizedStatus == 'cancelled' ||
      normalizedStatus == 'canceled' ||
      normalizedStatus == 'invoiced') {
    return false;
  }
  if ((order.invoiceNo ?? '').trim().isNotEmpty) return false;
  if (order.isCorporateWalkIn && order.isRejectedByCorporate) {
    return true;
  }
  if (order.isCorporateWalkIn && order.isCorporateUnapproved) {
    return true;
  }
  final badge = order.jobsAggregateBadgeLabel;
  // DRAFT = no jobs yet (shell order) — still cancellable before invoice.
  return badge == 'PENDING' || badge == 'COMPLETED' || badge == 'DRAFT';
}

void showCashierCancelOrderDialog(BuildContext context, String orderId) {
  final l10n = AppLocalizations.of(context)!;
  showPosOrdersCompactConfirmDialog(
    context,
    title: l10n.posOrdersCancelOrderTitle,
    body: l10n.posOrdersCancelOrderBody,
    confirmLabel: l10n.posCommonConfirmCancel,
    onConfirm: () async {
      final vm = context.read<pvm.PosViewModel>();
      return vm.cancelOrder(context, orderId, 'Cancelled by cashier');
    },
  );
}

void _showOrderDetailsSheet(
  BuildContext context,
  PosOrder order,
  bool isTablet,
) {
  Widget buildStatusBadge(String status, {bool isPreviousCompleted = false}) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'invoiced':
      case 'completed by technician':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'pending assignment':
      case 'waiting for technician acception':
      case 'waiting for technician':
      case 'draft':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'in progress':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    String displayStatus = status.replaceAll('_', ' ').toUpperCase();
    if (displayStatus == 'WAITING FOR TECHNICIAN ACCEPTION') {
      displayStatus = 'WAITING FOR TECHNICIAN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LocalizedApiText(
        displayStatus,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: localeFontWeight(context, FontWeight.w800),
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final sortedJobs = List<PosOrderJob>.from(order.jobs)
        ..sort((a, b) {
          final aId = int.tryParse(a.id) ?? -1;
          final bId = int.tryParse(b.id) ?? -1;
          final byNumericId = bId.compareTo(aId); // greatest id first
          if (byNumericId != 0) return byNumericId;
          return b.id.compareTo(a.id);
        });
      final latestId = order.latestJob?.id;

      return Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * (isTablet ? 0.8 : 0.9),
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA), // Soft beautiful light backdrop
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.posDetailsTitle,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: localeFontWeight(context, FontWeight.w800),
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Dark Premium Header Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3036),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.plateNumber.trim().isNotEmpty
                              ? order.plateNumber.toUpperCase()
                              : '—',
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          () {
                            final model =
                                '${order.vehicle?.make ?? ""} ${order.vehicle?.model ?? ""}'
                                    .trim();
                            final cust = order.customerName;
                            if (cust.isNotEmpty) {
                              return model.isEmpty ? cust : '$cust  •  $model';
                            }
                            return model;
                          }(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.posDetailsOrderHash(
                        _posWidgetDigits(
                          context,
                          order.id.split('-').last.toUpperCase(),
                        ),
                      ),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.black87,
                        fontWeight: localeFontWeight(context, FontWeight.bold),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: sortedJobs.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.posReviewNoDeptData,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                      itemCount: sortedJobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final job = sortedJobs[index];
                        final hasItems = job.items.isNotEmpty;
                        final isCompleted =
                            job.status.toLowerCase().contains('completed') &&
                            job.id != latestId;

                        Widget jobCard = Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Department Header Background Fill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(
                                        0.05,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              LocalizedApiText(
                                                job.department,
                                                style: AppTextStyles.bodyLarge
                                                    .copyWith(
                                                      fontWeight:
                                                          localeFontWeight(context, FontWeight.bold),
                                                      color: AppColors
                                                          .secondaryLight,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Job ID: ${job.id}',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        buildStatusBadge(
                                          job.status,
                                          isPreviousCompleted: isCompleted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Items Body
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!hasItems)
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.posDetailsNoItemsInDept,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                              ),
                                            ),
                                          )
                                        else
                                          ...job.items.map((item) {
                                            final isLast =
                                                job.items.last == item;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: isLast ? 0 : 16,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade300,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        LocalizedApiText(
                                                          item.productName,
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .secondaryLight,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .shade100,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.posDetailsQtyLabel(
                                                                  _posWidgetDigits(
                                                                    context,
                                                                    item.qty
                                                                        .toInt(),
                                                                  ),
                                                                ),
                                                                style: AppTextStyles
                                                                    .bodySmall
                                                                    .copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600,
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.posDetailsSarEa(
                                                                _posWidgetDigits(
                                                                  context,
                                                                  item.unitPrice
                                                                      .toStringAsFixed(
                                                                        2,
                                                                      ),
                                                                ),
                                                              ),
                                                              style: AppTextStyles
                                                                  .bodySmall
                                                                  .copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade500,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    _posWidgetMoney(
                                                      context,
                                                      item.lineTotal,
                                                    ),
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                          fontWeight:
                                                              localeFontWeight(context, FontWeight.w800),
                                                          color: AppColors
                                                              .secondaryLight,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),

                                        // Render Technicians if any
                                        if (job
                                            .distinctActiveTechnicians
                                            .isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Divider(
                                              height: 1,
                                              color: Color(0xFFEEEBE6),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.handyman_rounded,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.posOrdersAssignedTechnicians,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      fontWeight:
                                                          localeFontWeight(context, FontWeight.w800),
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ...job.distinctActiveTechnicians.map(
                                            (tech) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primaryLight
                                                          .withOpacity(0.15),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 14,
                                                      color: AppColors
                                                          .primaryLight,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      tech.name,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                localeFontWeight(context, FontWeight.w700),
                                                            color: AppColors
                                                                .secondaryLight,
                                                          ),
                                                    ),
                                                  ),
                                                  Builder(
                                                    builder: (context) {
                                                      final s =
                                                          tech.status
                                                              ?.toLowerCase() ??
                                                          '';
                                                      Color bgColor = Colors
                                                          .orange
                                                          .withOpacity(0.1);
                                                      Color textColor = Colors
                                                          .orange
                                                          .shade700;
                                                      String displayText =
                                                          s.isEmpty
                                                          ? 'PENDING'
                                                          : tech.status!
                                                                .toUpperCase();

                                                      if (displayText ==
                                                          'ACCEPTED_BY_TECHNICIAN') {
                                                        displayText =
                                                            'ACCEPTED';
                                                      } else if (displayText ==
                                                              'IN_PROGRESS' ||
                                                          displayText ==
                                                              'IN PROGRESS') {
                                                        displayText =
                                                            'IN PROGRESS';
                                                      }

                                                      if (s.contains(
                                                            'completed',
                                                          ) ||
                                                          s.contains(
                                                            'accepted',
                                                          )) {
                                                        bgColor = Colors.green
                                                            .withOpacity(0.1);
                                                        textColor = Colors
                                                            .green
                                                            .shade700;
                                                      } else if (s.contains(
                                                        'progress',
                                                      )) {
                                                        bgColor = Colors.purple
                                                            .withOpacity(0.1);
                                                        textColor = Colors
                                                            .purple
                                                            .shade700;
                                                      }

                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: bgColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: LocalizedApiText(
                                                          displayText,
                                                          style: AppTextStyles
                                                              .bodySmall
                                                              .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    textColor,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (latestId == job.id &&
                                !job.status.toLowerCase().contains(
                                  'complete',
                                ) &&
                                !job.status.toLowerCase().contains('invoice'))
                              Positioned(
                                top: -12,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27AE60),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF27AE60,
                                        ).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ACTIVE',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: localeFontWeight(context, FontWeight.w800),
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );

                        return jobCard;
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

void _showCompletionBottomSheet(
  BuildContext context,
  PosOrder order,
  pvm.PosViewModel posVm,
) {
  final isTablet = MediaQuery.of(context).size.width > 600;
  PosOrderJob? highestJob;
  if (order.jobs.isNotEmpty) {
    final sorted = List<PosOrderJob>.from(order.jobs);
    sorted.sort(
      (a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0),
    );
    highestJob = sorted.last;
  }

  // Parse latest job items for display (fallback to order items)
  final List<Map<String, dynamic>> parsedItems = [];
  if (highestJob != null && highestJob.items.isNotEmpty) {
    for (final item in highestJob.items) {
      parsedItems.add({
        'name': item.productName,
        'price': item.unitPrice,
        'qty': item.qty,
      });
    }
  } else if (order.items.isNotEmpty) {
    for (var item in order.items) {
      final priceDynamic = item['price'] ?? item['unitPrice'] ?? 0.0;
      final double price = (priceDynamic as num?)?.toDouble() ?? 0.0;
      parsedItems.add({
        'name': item['productName'] ?? item['name'] ?? 'Item',
        'price': price,
        'qty': item['quantity'] ?? item['qty'] ?? 1,
      });
    }
  }

  final String jobIdForComplete = highestJob != null ? highestJob.id : order.id;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height *
                    (isTablet ? 0.70 : 0.85),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF9F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Customer & Vehicle Card
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      isTablet ? 32 : 14,
                      6,
                      isTablet ? 32 : 14,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 14,
                        vertical: isTablet ? 14 : 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${order.id.split('-').last.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 10,
                                    fontWeight: localeFontWeight(context, FontWeight.w800),
                                    color: const Color(0xFF1E2124),
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              Expanded(
                                child: Text(
                                  order.plateNumber.trim().isNotEmpty
                                      ? order.plateNumber.toUpperCase()
                                      : '—',
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 13,
                                    fontWeight: localeFontWeight(context, FontWeight.w700),
                                    color: const Color(0xFF1E2124),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.statusText.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: isTablet ? 15 : 9,
                                    fontWeight: localeFontWeight(context, FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car_outlined,
                                size: 22,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  () {
                                    final m = order.carModel.trim();
                                    final c = order.customerName;
                                    if (c.isNotEmpty) {
                                      return m.isEmpty ? c : '$m • $c';
                                    }
                                    return m.isEmpty ? '—' : m;
                                  }(),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isTablet ? 17 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.phone_outlined,
                                size: 22,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.customer?.mobile ?? 'N/A',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: isTablet ? 17 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (parsedItems.isNotEmpty) ...[
                    // Order Items Header
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 36 : 18,
                        isTablet ? 24 : 12,
                        isTablet ? 36 : 18,
                        10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Order Items',
                            style: TextStyle(
                              fontWeight: localeFontWeight(context, FontWeight.bold),
                              fontSize: isTablet ? 20 : 14,
                              color: const Color(0xFF1E2124),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${parsedItems.length}',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 11,
                                fontWeight: localeFontWeight(context, FontWeight.w700),
                                color: const Color(0xFF1E2124),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Order Items List
                    Flexible(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 14,
                        ),
                        shrinkWrap: true,
                        itemCount: parsedItems.length,
                        itemBuilder: (context, index) {
                          final item = parsedItems[index];
                          final qty = item['qty'] as num;
                          final price = item['price'] as double;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LocalizedApiText(
                                        item['name'] as String,
                                        style: TextStyle(
                                          fontWeight: localeFontWeight(context, FontWeight.w700),
                                          fontSize: isTablet ? 14 : 12,
                                          color: const Color(0xFF1E2124),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${_posWidgetDigits(context, qty)} × ${_posWidgetMoney(context, price)}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 11 : 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _posWidgetMoney(context, price * qty),
                                  style: TextStyle(
                                    fontWeight: localeFontWeight(context, FontWeight.w800),
                                    fontSize: isTablet ? 14 : 12,
                                    color: const Color(0xFF1E2124),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action Buttons (Confirm only)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 32 : 14,
                      16,
                      isTablet ? 32 : 14,
                      MediaQuery.of(ctx).padding.bottom + 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: isTablet ? 56 : 48,
                            child: Consumer<pvm.PosViewModel>(
                              builder: (context, vm, _) {
                                final busy = vm.isCashierCompletingJob(
                                  jobIdForComplete,
                                );
                                return ElevatedButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          if (order.isCorporateWalkIn &&
                                              !order.isCorporateBookingOrder &&
                                              (order.isCorporateUnapproved ||
                                                  order
                                                      .isWaitingCorporateApproval ||
                                                  order
                                                      .isRejectedByCorporate)) {
                                            if (ctx.mounted) {
                                              ToastService.showError(
                                                ctx,
                                                'Corporate order must be approved before completing jobs.',
                                              );
                                            }
                                            return;
                                          }
                                          try {
                                            final response = await vm
                                                .completeCashierJob(
                                                  jobIdForComplete,
                                                  sourceOrder: order,
                                                );
                                            if (response != null &&
                                                response.success) {
                                              if (ctx.mounted) {
                                                Navigator.of(ctx).pop();
                                                ToastService.showSuccess(
                                                  ctx,
                                                  'Order marked as completed successfully',
                                                );
                                              }
                                            } else {
                                              if (ctx.mounted) {
                                                ToastService.showError(
                                                  ctx,
                                                  response?.message ??
                                                      'Failed to complete job',
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (ctx.mounted) {
                                              ToastService.showError(
                                                ctx,
                                                e.toString(),
                                              );
                                            }
                                          }
                                        },
                                  style: AppButtonBusy.elevatedLocked(
                                    backgroundColor: const Color(0xFFFFC145),
                                    foregroundColor: const Color(0xFF1E2124),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: busy
                                      ? AppButtonBusy.loaderOnFill(
                                          const Color(0xFFFFC145),
                                        )
                                      : Text(
                                          'Confirm Completion',
                                          style: TextStyle(
                                            fontWeight: localeFontWeight(context, FontWeight.w700),
                                            fontSize: isTablet ? 16 : 14,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildStatusPill(BuildContext context, PosOrder order) {
  if (order.jobs.isNotEmpty) {
    final label = order.jobsAggregateBadgeLabel;
    final Color textColor;
    final Color bgColor;
    if (label == 'DRAFT') {
      textColor = const Color(0xFF64748B);
      bgColor = const Color(0xFFF1F5F9);
    } else if (label == 'COMPLETED') {
      textColor = const Color(0xFF15803D);
      bgColor = const Color(0xFFDCFCE7);
    } else {
      textColor = Colors.white;
      bgColor = AppColors.secondaryLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: localeFontWeight(context, FontWeight.w800),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String statusStr = order.displayJobStatus.replaceAll('_', ' ').toUpperCase();

  String status = statusStr.toLowerCase();

  Color textColor = AppColors.secondaryLight;
  Color bgColor = AppColors.primaryLight;

  if (status == 'draft' ||
      status == 'pending' ||
      status.contains('waiting') ||
      status.contains('accepted')) {
    textColor = const Color(0xFFE67E22); // Orange for waiting
    bgColor = const Color(0xFFE67E22).withOpacity(0.15);
  } else if (status == 'in progress' || status == 'ready for invoice') {
    textColor = AppColors.secondaryLight;
    bgColor = const Color(0xFF2D9CDB).withOpacity(0.15);
  } else if (status.contains('completed') ||
      status == 'invoiced' ||
      status == 'delivered') {
    textColor = const Color(0xFF27AE60);
    bgColor = const Color(0xFF27AE60).withOpacity(0.15);
  } else if (status.contains('rejected') || status.contains('cancelled')) {
    textColor = Colors.red.shade700;
    bgColor = Colors.red.withOpacity(0.15);
  } else {
    textColor = Colors.grey.shade700;
    bgColor = Colors.grey.shade200;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      statusStr.replaceAll(' ACCEPTION', ''),
      style: TextStyle(
        color: textColor,
        fontSize: 8,
        fontWeight: localeFontWeight(context, FontWeight.w800),
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget _buildPremiumDetailItem(
  String title, {
  String? subtitle,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  bool isTablet = false,
}) {
  return Column(
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E2124),
          height: 1.15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (subtitle != null) ...[
        SizedBox(height: isTablet ? 3 : 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isTablet ? 10 : 9,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade400,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ],
  );
}

Widget _buildActionButton({
  required BuildContext context,
  required VoidCallback? onPressed,
  required IconData icon,
  required String label,
  required Color color,
  bool isLoading = false,
  bool isSecondary = false,
  double labelFontSize = 11,
}) {
  Color bgColor = color;
  Color textColor = Colors.white;

  if (isSecondary && color == AppColors.secondaryLight) {
    bgColor = AppColors.secondaryLight;
    textColor = Colors.white;
  } else if (color == const Color(0xFF27AE60)) {
    bgColor = const Color(0xFF27AE60);
    textColor = Colors.white;
  } else if (color == AppColors.primaryLight && !isSecondary) {
    bgColor = AppColors.primaryLight;
    textColor = AppColors.secondaryLight;
  }

  return SizedBox(
    height: 28,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: AppButtonBusy.elevatedLocked(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? AppButtonBusy.loaderOnFill(bgColor)
          : Text(
              label,
              style: TextStyle(
                fontWeight: localeFontWeight(context, FontWeight.w700),
                fontSize: labelFontSize,
                color: textColor,
              ),
            ),
    ),
  );
}

void _showCommissionPopup(BuildContext context, dynamic commissionData) {
  if (commissionData == null) {
    ToastService.showSuccess(context, 'Job approved successfully!');
    return;
  }

  final String techName = commissionData.technicianName;
  final double amount = commissionData.commissionAmount;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF27AE60),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.posJobApproved,
              style: TextStyle(
                fontSize: 22,
                fontWeight: localeFontWeight(context, FontWeight.w900),
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.posJobTechnicianCommissionLogged,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.posJobTechnicianLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: localeFontWeight(context, FontWeight.w800),
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        techName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: localeFontWeight(context, FontWeight.w700),
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.posJobCommissionLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: localeFontWeight(context, FontWeight.w800),
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _posWidgetMoney(context, amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: localeFontWeight(context, FontWeight.w900),
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(fontWeight: localeFontWeight(context, FontWeight.w700), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fire-and-forget thermal print runner. Caller has already closed the invoice
/// dialog and navigated away — toasts are surfaced via the root
/// [ToastService.scaffoldMessengerKey] so they appear on whatever screen the
/// user is currently on.
Future<void> _thermalPrintInvoiceInBackground({
  required BuildContext toastContext,
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  List<int>? cachedEscPosBytes,
  String successMessage = 'Receipt sent to printer.',
  String failurePrefix = 'Print failed',
}) async {
  BuildContext resolveToastCtx() {
    if (toastContext.mounted) return toastContext;
    return ToastService.scaffoldMessengerKey.currentContext ?? toastContext;
  }

  try {
    List<int> bytes;
    if (cachedEscPosBytes != null && cachedEscPosBytes.isNotEmpty) {
      bytes = cachedEscPosBytes;
    } else {
      // Preferred path: full ESC/POS payload was already pre-rendered while
      // the dialog was open. Awaiting this is a no-op when ready, so Print
      // tap → TCP send only (no UI-isolate raster work after navigation,
      // no ANR popup).
      final pendingEscPos =
          InvoicePrintPrefetch.escPosFutureFor(invoice.id);
      if (pendingEscPos != null) {
        try {
          bytes = await pendingEscPos;
          InvoicePrintPrefetch.discard(invoice.id);
        } catch (_) {
          // Prefetch failed — fall through to a fresh build.
          InvoicePrintPrefetch.discard(invoice.id);
          bytes = await prepareInvoiceEscPosBytesOffUi(
            invoice: invoice,
            paymentMethodText: paymentMethodText,
            maintenanceChecksFallback: maintenanceChecksFallback,
          );
        }
      } else {
        // Defensive fallback: prefetch never started or was already consumed.
        // Reuse a prefetched PDF if one exists to skip the heaviest step.
        Uint8List? prefetchedPdf;
        final pendingPdf = InvoicePrintPrefetch.pdfFutureFor(invoice.id);
        if (pendingPdf != null) {
          try {
            prefetchedPdf = await pendingPdf;
          } catch (_) {
            prefetchedPdf = null;
          }
          InvoicePrintPrefetch.discard(invoice.id);
        }
        bytes = await prepareInvoiceEscPosBytesOffUi(
          invoice: invoice,
          paymentMethodText: paymentMethodText,
          maintenanceChecksFallback: maintenanceChecksFallback,
          prefetchedPdfBytes: prefetchedPdf,
        );
      }
    }
    final cfg = await ThermalPrinterSettings.load();
    await sendEscPosBytesToTcpPrinter(
      host: cfg.host,
      port: cfg.port,
      bytes: bytes,
    );
    final ctx = resolveToastCtx();
    if (ctx.mounted) {
      ToastService.showSuccess(ctx, successMessage);
    }
  } catch (e) {
    final ctx = resolveToastCtx();
    if (ctx.mounted) {
      ToastService.showError(ctx, '$failurePrefix: $e');
    }
  }
}

/// Fire-and-forget WhatsApp invoice send. The bilingual A4 PDF is built on
/// the NestJS backend (Puppeteer) and dispatched to Bevatel server-side, so
/// the cashier device only does a short authenticated POST and surfaces a
/// root toast on success / failure.
Future<void> _sendInvoiceWhatsAppInBackground({
  required BuildContext toastContext,
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  required Uint8List? rasterPdf,
}) async {
  rasterPdf; // legacy parity — backend builds its own PDF, raster ignored.
  BuildContext resolveToastCtx() {
    if (toastContext.mounted) return toastContext;
    return ToastService.scaffoldMessengerKey.currentContext ?? toastContext;
  }

  try {
    await BackendWhatsAppInvoiceDispatch.send(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecks: maintenanceChecksFallback,
    );
    final ctx = resolveToastCtx();
    if (ctx.mounted) {
      ToastService.showSuccess(ctx, 'Invoice queued for WhatsApp.');
    }
  } catch (e) {
    final ctx = resolveToastCtx();
    if (ctx.mounted) {
      ToastService.showError(ctx, 'WhatsApp send failed: $e');
    }
  }
}

class _InvoiceThermalActionBar extends StatefulWidget {
  final Invoice invoice;
  final String paymentMethodText;
  final GlobalKey previewCaptureKey;
  final VoidCallback? onDone;
  final List<bool>? maintenanceChecksFallback;

  const _InvoiceThermalActionBar({
    required this.invoice,
    required this.paymentMethodText,
    required this.previewCaptureKey,
    this.onDone,
    this.maintenanceChecksFallback,
  });

  @override
  State<_InvoiceThermalActionBar> createState() =>
      _InvoiceThermalActionBarState();
}

class _InvoiceThermalActionBarState extends State<_InvoiceThermalActionBar> {
  bool _doneBusy = false;
  List<int>? _cachedEscPosBytes;
  Uint8List? _cachedWhatsAppPdfBytes;
  Future<Uint8List?>? _whatsAppPdfFuture;

  @override
  void initState() {
    super.initState();
    // Pre-build thermal PDF on a background isolate (Arabic fonts). Raster runs on Print tap.
    startInvoiceThermalPrintPrefetch(
      invoice: widget.invoice,
      paymentMethodText: widget.paymentMethodText,
      maintenanceChecksFallback: widget.maintenanceChecksFallback,
    );
  }

  /// Colourful on-screen invoice preview → PDF (pre-optimization WhatsApp path).
  void _startWhatsAppPdfWarmup() {
    _whatsAppPdfFuture ??= InvoicePreviewCapturePdf.repaintBoundaryKeyToPdf(
      repaintBoundaryKey: widget.previewCaptureKey,
      context: context,
      compactForMessaging: true,
    ).then((bytes) {
      if (bytes != null && bytes.isNotEmpty) {
        _cachedWhatsAppPdfBytes = bytes;
      }
      return bytes;
    }).catchError((Object _) => null);
  }

  Future<Uint8List?> _captureWhatsAppPdf() {
    return InvoicePreviewCapturePdf.repaintBoundaryKeyToPdf(
      repaintBoundaryKey: widget.previewCaptureKey,
      context: context,
      compactForMessaging: true,
    );
  }

  Future<Uint8List?> _resolveWhatsAppPdf() async {
    if (_cachedWhatsAppPdfBytes != null &&
        _cachedWhatsAppPdfBytes!.isNotEmpty) {
      return _cachedWhatsAppPdfBytes;
    }

    final pending = _whatsAppPdfFuture;
    if (pending != null) {
      final captured = await pending.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Invoice preview capture timed out. Scroll the invoice and try again.',
          );
        },
      );
      if (captured != null && captured.isNotEmpty) {
        _cachedWhatsAppPdfBytes = captured;
        return captured;
      }
    }

    await WidgetsBinding.instance.endOfFrame;
    final captured = await _captureWhatsAppPdf();
    if (captured != null && captured.isNotEmpty) {
      _cachedWhatsAppPdfBytes = captured;
      _whatsAppPdfFuture = Future.value(captured);
      return captured;
    }

    return null;
  }

  Future<List<int>> _resolveEscPosBytes({bool forceRebuild = false}) async {
    if (!forceRebuild &&
        _cachedEscPosBytes != null &&
        _cachedEscPosBytes!.isNotEmpty) {
      return _cachedEscPosBytes!;
    }

    if (!forceRebuild) {
      // Fast path: prefetch already produced the full ESC/POS payload.
      final pendingEscPos =
          InvoicePrintPrefetch.escPosFutureFor(widget.invoice.id);
      if (pendingEscPos != null) {
        try {
          final bytes = await pendingEscPos;
          InvoicePrintPrefetch.discard(widget.invoice.id);
          _cachedEscPosBytes = bytes;
          return bytes;
        } catch (_) {
          InvoicePrintPrefetch.discard(widget.invoice.id);
          // Fall through to a fresh build below.
        }
      }
    }

    Uint8List? prefetchedPdf;
    if (!forceRebuild) {
      final pending = InvoicePrintPrefetch.pdfFutureFor(widget.invoice.id);
      if (pending != null) {
        try {
          prefetchedPdf = await pending;
        } catch (_) {
          prefetchedPdf = null;
        }
        InvoicePrintPrefetch.discard(widget.invoice.id);
      }
    }

    final bytes = await prepareInvoiceEscPosBytesOffUi(
      invoice: widget.invoice,
      paymentMethodText: widget.paymentMethodText,
      maintenanceChecksFallback: widget.maintenanceChecksFallback,
      prefetchedPdfBytes: prefetchedPdf,
    );
    _cachedEscPosBytes = bytes;
    return bytes;
  }

  Future<void> _openThermalSettings() async {
    final ok = await showThermalPrinterWifiDialog(context);
    if (!mounted) return;
    if (ok) {
      ToastService.showSuccess(context, 'save successfully');
    }
  }

  /// Fire-and-forget: tap → close dialog + redirect → thermal print runs in
  /// background. Toast on success / failure via root [ScaffoldMessenger] (survives
  /// navigation). UI never freezes on Print tap.
  Future<void> _sendToThermalPrinter() async {
    if (_doneBusy) return;
    final toastCtx = ToastService.scaffoldMessengerKey.currentContext;
    final cachedPrint = _cachedEscPosBytes;
    Navigator.of(context, rootNavigator: true).pop();
    widget.onDone?.call();
    unawaited(
      _thermalPrintInvoiceInBackground(
        toastContext: toastCtx ?? context,
        invoice: widget.invoice,
        paymentMethodText: widget.paymentMethodText,
        maintenanceChecksFallback: widget.maintenanceChecksFallback,
        cachedEscPosBytes: cachedPrint,
        successMessage: 'Receipt sent to printer.',
        failurePrefix: 'Print failed',
      ),
    );
  }

  /// Fire-and-forget: capture preview PDF, close dialog, send via WhatsApp.
  /// Print is a separate button — this path does not thermal-print.
  Future<void> _onWhatsAppPressed() async {
    if (!mounted || _doneBusy) return;
    setState(() => _doneBusy = true);
    await WidgetsBinding.instance.endOfFrame;

    Uint8List? colourPdf;
    try {
      colourPdf = await _resolveWhatsAppPdf();
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          'Could not capture invoice preview: $e',
        );
        setState(() => _doneBusy = false);
      }
      return;
    }
    if (!mounted) return;

    final toastCtx = ToastService.scaffoldMessengerKey.currentContext ?? context;
    Navigator.of(context, rootNavigator: true).pop();
    widget.onDone?.call();

    unawaited(
      _sendInvoiceWhatsAppInBackground(
        toastContext: toastCtx,
        invoice: widget.invoice,
        paymentMethodText: widget.paymentMethodText,
        maintenanceChecksFallback: widget.maintenanceChecksFallback,
        rasterPdf: colourPdf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idle = !_doneBusy;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final whatsAppLabel = isAr ? 'إرسال واتساب' : 'Send WhatsApp';
    final printLabel = isAr ? 'طباعة' : 'Print';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Tooltip(
              message:
                  'Download invoice PDF and send on WhatsApp (Bevatel), then close.',
              child: ElevatedButton(
                onPressed: idle ? _onWhatsAppPressed : null,
                style: AppButtonBusy.elevatedLocked(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _doneBusy
                    ? AppButtonBusy.loaderOnFill(AppColors.primaryLight)
                    : Text(
                        whatsAppLabel,
                        style: TextStyle(
                          fontWeight: localeFontWeight(context, FontWeight.w900),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message:
                  'Tap: print to Wi‑Fi thermal printer. Long‑press: IP / port.',
              child: GestureDetector(
                onLongPress: idle ? _openThermalSettings : null,
                child: ElevatedButton(
                  onPressed: idle ? _sendToThermalPrinter : null,
                  style: AppButtonBusy.elevatedLocked(
                    backgroundColor: const Color(0xFF2E3237),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    printLabel,
                    style: TextStyle(
                      fontWeight: localeFontWeight(context, FontWeight.w900),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback? onDone;
  final String? requestedPaymentMethod;
  final List<bool>? maintenanceChecksFallback;
  /// View-only: invoice layout with current and next oil-change readings, no send/print.
  final bool readOnly;

  const InvoiceDialog({
    super.key,
    required this.invoice,
    this.onDone,
    this.requestedPaymentMethod,
    this.maintenanceChecksFallback,
    this.readOnly = false,
  });

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  final GlobalKey _previewCaptureKey = GlobalKey();
  late final String _paymentMethodText;
  late final ThermalInvoiceTotals _paymentTotals;

  @override
  void initState() {
    super.initState();
    _paymentTotals = computeThermalInvoiceTotals(widget.invoice);
    _paymentMethodText = widget.invoice.payments.isNotEmpty
        ? thermalInvoicePaymentBreakdownSummary(
            widget.invoice,
            fallbackTotal: _paymentTotals.totalInvoiceAmount,
          )
        : (widget.invoice.paymentMethod ??
              widget.requestedPaymentMethod ??
              'Unpaid');
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodText = _paymentMethodText;
    final phone = !PosTabletLayout.isTablet(context);
    final mq = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final shellMaxW = phone ? mq.width : (mq.width * 0.94).clamp(320.0, 860.0);
    final shellMaxH = phone ? mq.height * 0.94 : mq.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(
        phone ? 8 : 20,
        (phone ? 8 : 16) + safe.top,
        phone ? 8 : 20,
        (phone ? 8 : 16) + safe.bottom,
      ),
      child: SizedBox(
        width: shellMaxW,
        child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: shellMaxH,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        phone ? 10 : 8,
                        phone ? 10 : 8,
                        phone ? 10 : 8,
                        0,
                      ),
                      child: RepaintBoundary(
                        key: _previewCaptureKey,
                        child: CashierInvoicePreview(
                          invoice: widget.invoice,
                          paymentMethodText: paymentMethodText,
                          maintenanceChecksFallback:
                              widget.maintenanceChecksFallback,
                          compactMobile: phone,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.readOnly)
                    _InvoiceThermalActionBar(
                      invoice: widget.invoice,
                      paymentMethodText: paymentMethodText,
                      previewCaptureKey: _previewCaptureKey,
                      onDone: widget.onDone,
                      maintenanceChecksFallback: widget.maintenanceChecksFallback,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: phone ? 0 : -12,
            right: phone ? 0 : -8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.close_rounded,
                    color: const Color(0xFF1E2124),
                    size: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

bool _techCanToggleWorkshop(PosTechnician tech) {
  final t = tech.technicianType.toLowerCase();
  if (t.isEmpty) return true;
  return t == 'workshop' || t == 'both';
}

bool _techCanToggleOnCall(PosTechnician tech) {
  final t = tech.technicianType.toLowerCase();
  if (t.isEmpty) return true;
  return t == 'on_call' || t == 'both';
}

class _CashierDutyToggle extends StatelessWidget {
  final String label;
  final bool isTablet;
  final bool compact;
  final bool enabled;
  final bool value;
  final bool busy;
  final bool technicianOnline;

  /// False when this duty row does not apply (e.g. on-call row for workshop-only tech).
  final bool roleAllowsDuty;
  final ValueChanged<bool>? onChanged;

  const _CashierDutyToggle({
    required this.label,
    required this.isTablet,
    required this.compact,
    required this.enabled,
    required this.value,
    required this.busy,
    required this.technicianOnline,
    required this.roleAllowsDuty,
    required this.onChanged,
  });

  String _statusCaption(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!roleAllowsDuty) {
      return isArabic ? 'غير قابل للتطبيق' : 'Not applicable';
    }
    if (!technicianOnline) {
      return isArabic
          ? 'غير متاح أثناء عدم الاتصال'
          : 'Unavailable while offline';
    }
    if (value) return isArabic ? 'نشط' : 'Active';
    return isArabic ? 'غير متاح' : 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    final toggleWidth = isTablet ? 46.0 : (compact ? 40.0 : 42.0);
    final toggleHeight = compact ? 24.0 : 27.0;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 26 : 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 9.5 : 8.5,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? const Color(0xFF475569)
                        : Colors.grey.shade400,
                  ),
                ),
                Text(
                  _statusCaption(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 8.0 : 7.5,
                    fontWeight: FontWeight.w600,
                    color: !roleAllowsDuty
                        ? Colors.grey.shade400
                        : (!technicianOnline
                              ? Colors.grey.shade500
                              : (value
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600)),
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            SizedBox(
              width: compact ? 32 : 36,
              child: Center(
                child: SizedBox(
                  width: compact ? 18 : 20,
                  height: compact ? 18 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: toggleWidth,
              height: toggleHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  thumbColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey.shade400;
                    }
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return Colors.grey.shade200;
                  }),
                  trackColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey.shade300;
                    }
                    if (states.contains(MaterialState.selected)) {
                      return Colors.green.shade600;
                    }
                    return Colors.grey.shade500;
                  }),
                  trackOutlineColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Material switch with white thumb and primary track when on (POS checkout dialogs).
class PosPrimaryToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const PosPrimaryToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade400;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade300;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight;
        }
        return Colors.grey.shade400;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

class TechnicianCard extends StatelessWidget {
  final PosTechnician tech;
  final bool compact;

  /// When true (e.g. POS Technicians tab), shows online/offline switch.
  final bool showPresenceToggle;
  final bool presenceBusy;
  final ValueChanged<bool>? onPresenceChanged;

  /// Cashier: workshop / on-call duty toggles (can show together with [showPresenceToggle]).
  final bool showDutyToggles;
  final bool dutyBusy;
  final ValueChanged<bool>? onWorkshopDutyChanged;
  final ValueChanged<bool>? onOnCallDutyChanged;

  const TechnicianCard({
    super.key,
    required this.tech,
    this.compact = false,
    this.showPresenceToggle = false,
    this.presenceBusy = false,
    this.onPresenceChanged,
    this.showDutyToggles = false,
    this.dutyBusy = false,
    this.onWorkshopDutyChanged,
    this.onOnCallDutyChanged,
  });

  Color _cashierPresenceDotColor(PosTechnician tech) {
    if (!tech.isOnline) return Colors.grey.shade500;
    final dm = _effectiveDutyModeForCard(tech);
    if (dm == 'workshop') return Colors.green.shade600;
    if (dm == 'on_call') return Colors.deepOrange.shade600;
    return Colors.grey.shade600;
  }

  String _effectiveDutyModeForCard(PosTechnician tech) {
    var dm = tech.dutyMode?.toLowerCase().trim() ?? '';
    if (dm.isNotEmpty) return dm;
    if (tech.workshopDuty) return 'workshop';
    if (tech.onCallDuty) return 'on_call';
    return 'inactive';
  }

  /// Workshop → active floor; on-call only → **On call**; otherwise **Not available** (still not cashier-offline).
  String _cashierPresenceHeadline(PosTechnician tech) {
    if (!tech.isOnline) {
      return 'Last seen: ${tech.formattedLastSeen}';
    }
    final dm = _effectiveDutyModeForCard(tech);
    if (dm == 'workshop') {
      return 'Online now';
    }
    if (dm == 'on_call') {
      return 'On call';
    }
    return 'Not available';
  }

  Color _cashierPresenceHeadlineColor(PosTechnician tech) {
    if (!tech.isOnline) return Colors.grey.shade600;
    final dm = _effectiveDutyModeForCard(tech);
    if (dm == 'workshop') {
      return Colors.green.shade700;
    }
    if (dm == 'on_call') {
      return Colors.deepOrange.shade800;
    }
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final presenceDotColor = _cashierPresenceDotColor(tech);
    final hasDepartment = tech.departments.isNotEmpty;
    final departmentText = hasDepartment
        ? tech.departments
              .map((d) => d.name)
              .where((e) => e.isNotEmpty)
              .join(', ')
        : l10n.posTechCardNoDepartment;
    final dmForHeadline = _effectiveDutyModeForCard(tech);
    final presenceHeadline = !tech.isOnline
        ? l10n.posTechCardLastSeen(
            AppTranslationService.localizeDigitsForLanguage(
              tech.formattedLastSeen,
              langCode,
            ),
          )
        : dmForHeadline == 'workshop'
        ? l10n.posTechCardOnlineNow
        : dmForHeadline == 'on_call'
        ? l10n.posTechCardOnCall
        : l10n.posTechCardNotAvailable;
    final presenceHeadlineColor = _cashierPresenceHeadlineColor(tech);
    final slotsFull = tech.totalSlots > 0 && tech.slotsUsed >= tech.totalSlots;
    final slotsLabel = AppTranslationService.localizeDigitsForLanguage(
      l10n.posTechCardSlots(tech.slotsUsed, tech.totalSlots),
      langCode,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 9 : 7,
        vertical: isTablet ? 6 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isTablet ? 42 : 34,
                height: isTablet ? 42 : 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person,
                  size: isTablet ? 21 : 17,
                  color: AppColors.onPrimaryLight,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: isTablet ? 11 : 9,
                  height: isTablet ? 11 : 9,
                  decoration: BoxDecoration(
                    color: presenceDotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        presenceHeadline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 10.0 : 9.0,
                          fontWeight: FontWeight.w600,
                          color: presenceHeadlineColor,
                        ),
                      ),
                    ),
                    if (showPresenceToggle && onPresenceChanged != null)
                      SizedBox(
                        height: compact ? 30 : 34,
                        width: presenceBusy ? (compact ? 36 : 40) : null,
                        child: presenceBusy
                            ? Center(
                                child: SizedBox(
                                  width: compact ? 20 : 22,
                                  height: compact ? 20 : 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Switch(
                                  value: tech.isOnline,
                                  onChanged: onPresenceChanged,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  thumbColor: MaterialStateProperty.resolveWith(
                                    (states) {
                                      if (states.contains(
                                        MaterialState.disabled,
                                      )) {
                                        return Colors.grey.shade400;
                                      }
                                      if (states.contains(
                                        MaterialState.selected,
                                      )) {
                                        return Colors.white;
                                      }
                                      return Colors.grey.shade200;
                                    },
                                  ),
                                  trackColor: MaterialStateProperty.resolveWith(
                                    (states) {
                                      if (states.contains(
                                        MaterialState.disabled,
                                      )) {
                                        return Colors.grey.shade300;
                                      }
                                      if (states.contains(
                                        MaterialState.selected,
                                      )) {
                                        return Colors.green.shade600;
                                      }
                                      return Colors.grey.shade500;
                                    },
                                  ),
                                  trackOutlineColor: MaterialStateProperty.all(
                                    Colors.transparent,
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
                SizedBox(height: isTablet ? 4 : 2),
                LocalizedApiText(
                  tech.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 13.5 : 11,
                    fontWeight: localeFontWeight(context, FontWeight.w800),
                    color: const Color(0xFF1E2124),
                  ),
                ),
                if (!compact) ...[
                  SizedBox(height: isTablet ? 4 : 2),
                  Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: isTablet ? 14 : 10,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: hasDepartment
                            ? LocalizedApiText(
                                departmentText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 9.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              )
                            : Text(
                                departmentText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 9.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 3 : 2),
                ] else
                  SizedBox(height: isTablet ? 3 : 2),
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      size: isTablet ? 14 : 10,
                      color: slotsFull
                          ? Colors.red.shade400
                          : Colors.green.shade600,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        slotsLabel,
                        style: TextStyle(
                          fontSize: isTablet ? 10.0 : 9.0,
                          fontWeight: localeFontWeight(context, FontWeight.w700),
                          color: slotsFull
                              ? Colors.red.shade500
                              : Colors.green.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (showDutyToggles &&
                    (onWorkshopDutyChanged != null ||
                        onOnCallDutyChanged != null)) ...[
                  SizedBox(height: isTablet ? 4 : 3),
                  _CashierDutyToggle(
                    label: l10n.posTechCardWorkshopDuty,
                    isTablet: isTablet,
                    compact: compact,
                    enabled: _techCanToggleWorkshop(tech) && tech.isOnline,
                    value: tech.workshopDuty,
                    busy: dutyBusy,
                    technicianOnline: tech.isOnline,
                    roleAllowsDuty: _techCanToggleWorkshop(tech),
                    onChanged: onWorkshopDutyChanged,
                  ),
                  SizedBox(height: isTablet ? 3 : 2),
                  _CashierDutyToggle(
                    label: l10n.posTechCardOnCallDuty,
                    isTablet: isTablet,
                    compact: compact,
                    enabled: _techCanToggleOnCall(tech) && tech.isOnline,
                    value: tech.onCallDuty,
                    busy: dutyBusy,
                    technicianOnline: tech.isOnline,
                    roleAllowsDuty: _techCanToggleOnCall(tech),
                    onChanged: onOnCallDutyChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 95,
      height: height ?? 85, // Use provided height or fallback
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon removed as per request
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 20,
                    fontWeight: localeFontWeight(context, FontWeight.w700),
                    color: textColor ?? AppColors.secondaryLight,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PosWorkshopSearchBar(
      hintText: 'Search item or service',
      onChanged: (val) => context.read<pvm.PosViewModel>().setSearchQuery(val),
    );
  }
}

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<pvm.PosViewModel>(
      builder: (context, vm, child) {
        final categories = vm.uniqueCategories;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = vm.selectedCategory == cat;
              return GestureDetector(
                onTap: () => vm.setCategory(cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFCC247) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFCC247)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? const Color(0xFF1E2124)
                          : Colors.grey.shade500,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final PosProduct product;
  const ProductCard({super.key, required this.product});

  Color _getStockColor(int stock) {
    if (stock >= 30) return const Color(0xFF27AE60); // Green
    if (stock >= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final stockColor = _getStockColor(product.stock);
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E2124),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: stockColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (product.subtitle.isNotEmpty)
                Expanded(
                  child: Text(
                    product.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'SAR ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E2124),
                ),
              ),
              Text(
                currencyFormat.format(product.price * 1.15), // Price incl. VAT
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2124),
                ),
              ),
              Text(
                ' (Inc. VAT)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DottedContainer extends StatelessWidget {
  final Widget child;
  const DottedContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: CustomPaint(painter: DottedPainter(), child: child),
    );
  }
}

class DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 3;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
      );

    for (var i = 0; i < path.computeMetrics().length; i++) {
      final metric = path.computeMetrics().elementAt(i);
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
