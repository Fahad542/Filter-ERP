import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/network/base_api_service.dart';
import '../l10n/app_localizations.dart';
import '../services/catalog_sync_service.dart';
import '../utils/app_colors.dart';
import 'app_bar_live_clock.dart';
import '../utils/pos_tablet_layout.dart';
import '../utils/toast_service.dart';
import '../views/Workshop pos app/Department/department_view_model.dart';
import '../views/Workshop pos app/Home Screen/pos_view_model.dart';
import '../views/Workshop pos app/Product Grid/product_grid_view_model.dart';
import '../views/Workshop pos app/Takeaway/takeaway_view_model.dart';

/// Catalog sync — same pill UI in the drawer menu and POS app bars.
class PosCatalogSyncButton extends StatelessWidget {
  const PosCatalogSyncButton({
    super.key,
    this.forDrawer = false,
    this.catalogDepartmentId,
  });

  /// Full-width pill for the side drawer (dark background).
  final bool forDrawer;

  /// When set (e.g. Products & Services hub dialog), reload this department after sync.
  final String? catalogDepartmentId;

  static String? _resolveRefreshDepartmentId(
    PosViewModel posVm, {
    String? explicitDepartmentId,
  }) {
    final explicit = explicitDepartmentId?.trim();
    if (explicit != null &&
        explicit.isNotEmpty &&
        explicit.toLowerCase() != 'all') {
      return explicit;
    }
    final edit = posVm.editDepartmentId?.trim();
    if (edit != null && edit.isNotEmpty) return edit;
    final last = posVm.lastFetchedDepartmentId?.trim();
    if (last != null && last.isNotEmpty) return last;
    return null;
  }

  static void _resetProductGridPaging(BuildContext context) {
    try {
      context.read<ProductGridViewModel>().resetVisibleProducts();
    } catch (_) {
      // Product grid not mounted (e.g. sync from shell app bar only).
    }
  }

  static Future<CatalogSyncResult?> syncCatalog(
    BuildContext context, {
    String? catalogDepartmentId,
    bool showToast = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final catalogSync = context.read<CatalogSyncService>();
    if (catalogSync.isSyncing) return null;

    final deptVm = context.read<DepartmentViewModel>();
    final posVm = context.read<PosViewModel>();
    final takeawayVm = context.read<TakeawayViewModel>();
    final refreshDepartmentId = _resolveRefreshDepartmentId(
      posVm,
      explicitDepartmentId: catalogDepartmentId,
    );

    final result = await deptVm.syncCatalogFromApi();
    if (!context.mounted) return result;

    if (result.success) {
      if (posVm.shouldUseCorporateQuotedCatalog) {
        final corpId = posVm.activeCorporateAccountId;
        if (corpId != null && corpId.isNotEmpty) {
          await posVm.loadCorporateProductsCatalog(
            corpId,
            forceRefresh: true,
            departmentId: refreshDepartmentId,
          );
        }
      } else {
        await posVm.fetchProducts(departmentId: refreshDepartmentId);
      }
      if (!context.mounted) return result;
      _resetProductGridPaging(context);
      unawaited(takeawayVm.loadCatalog());
      if (showToast) {
        ToastService.showSuccess(context, l10n.posCatalogSyncSuccess);
      }
    } else if (showToast) {
      ToastService.showError(
        context,
        result.message.isNotEmpty
            ? result.message
            : l10n.posCatalogSyncFailed,
      );
    }
    return result;
  }

  /// True after the first post-login catalog sync this cashier session.
  static bool _postLoginCatalogSyncDone = false;

  /// Call on cashier logout so the next login runs [syncCatalogAfterLogin] again.
  static void resetPostLoginCatalogSync() {
    _postLoginCatalogSyncDone = false;
  }

  /// Runs after cashier login / first POS shell open (silent; no success toast).
  static Future<void> syncCatalogAfterLogin(BuildContext context) {
    if (_postLoginCatalogSyncDone) return Future.value();
    _postLoginCatalogSyncDone = true;
    return BaseApiService.runWithoutUnauthorizedLogout(() async {
      if (!context.mounted) return;
      await syncCatalog(context, showToast: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final compact = PosTabletLayout.compactLandscapeChrome(context);
    final l10n = AppLocalizations.of(context)!;
    final catalogSync = context.read<CatalogSyncService>();
    final deptVm = context.read<DepartmentViewModel>();
    final posVm = context.read<PosViewModel>();

    return ListenableBuilder(
      listenable: Listenable.merge([catalogSync, deptVm, posVm]),
      builder: (context, _) {
        final isSyncing = catalogSync.isSyncing ||
            deptVm.isSyncing ||
            posVm.isCatalogSyncing ||
            posVm.corporateCatalogLoading;
        return _buildPill(
          context: context,
          isTablet: isTablet,
          compact: compact,
          l10n: l10n,
          isSyncing: isSyncing,
        );
      },
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required bool isTablet,
    required bool compact,
    required AppLocalizations l10n,
    required bool isSyncing,
  }) {

    final appBarPill = !forDrawer;
    final borderRadius = forDrawer
        ? (compact ? 12.0 : (isTablet ? 12.0 : 10.0))
        : PosAppBarCompactPillMetrics.borderRadius(isTablet);
    final inkRadius = forDrawer
        ? (compact ? 10.0 : (isTablet ? 12.0 : 10.0))
        : (isTablet ? 7.0 : 6.0);
    final iconSize = forDrawer
        ? 18.0
        : PosAppBarCompactPillMetrics.timeFontSize(isTablet);
    final spinnerSize = forDrawer
        ? (compact ? 14.0 : 16.0)
        : iconSize;
    final isArabic = PosAppBarCompactPillMetrics.isArabicLocale(
      Localizations.localeOf(context).languageCode,
    );
    final fontSize = forDrawer
        ? (compact ? 12.5 : (isTablet ? 13.0 : 12.0))
        : PosAppBarCompactPillMetrics.dateFontSize(isTablet, isArabic: isArabic);
    final horizontalPadding = forDrawer
        ? 12.0
        : PosAppBarCompactPillMetrics.horizontalPad(isTablet);
    final verticalPadding = forDrawer
        ? (compact ? 10.0 : (isTablet ? 10.0 : 9.0))
        : PosAppBarCompactPillMetrics.singleLineVerticalPad(isTablet);
    final appBarPillHeight = appBarPill
        ? PosAppBarCompactPillMetrics.singleLineOuterHeight(
            isTablet,
            isArabic: isArabic,
          )
        : null;
    final labelGap = forDrawer ? 10.0 : 6.0;

    final pill = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSyncing
            ? null
            : () => syncCatalog(
                  context,
                  catalogDepartmentId: catalogDepartmentId,
                ),
        borderRadius: BorderRadius.circular(inkRadius),
        child: Container(
          width: forDrawer ? double.infinity : null,
          height: appBarPillHeight,
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: forDrawer
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: forDrawer
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.secondaryLight,
            ),
          ),
          child: Row(
            mainAxisSize: forDrawer ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (isSyncing)
                SizedBox(
                  width: spinnerSize,
                  height: spinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: forDrawer ? AppColors.primaryLight : Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.sync_rounded,
                  size: iconSize,
                  color: forDrawer ? AppColors.primaryLight : Colors.white,
                ),
              SizedBox(width: labelGap),
              if (forDrawer)
                Expanded(
                  child: Text(
                    isSyncing ? l10n.posCatalogSyncing : l10n.posCatalogSyncData,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior:
                        PosAppBarCompactPillMetrics.compactTextHeightBehavior,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                      height: 1.0,
                    ),
                  ),
                )
              else
                Text(
                  isSyncing ? l10n.posCatalogSyncing : l10n.posCatalogSyncData,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textHeightBehavior:
                      PosAppBarCompactPillMetrics.compactTextHeightBehavior,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return pill;
  }
}

/// App bar placement — same pill as the drawer, compact width.
class PosCatalogSyncAppBarButton extends StatelessWidget {
  const PosCatalogSyncAppBarButton({
    super.key,
    this.catalogDepartmentId,
    this.padding,
  });

  final String? catalogDepartmentId;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return Padding(
      padding: padding ?? EdgeInsets.only(right: isTablet ? 4 : 3),
      child: PosCatalogSyncButton(
        catalogDepartmentId: catalogDepartmentId,
      ),
    );
  }
}
