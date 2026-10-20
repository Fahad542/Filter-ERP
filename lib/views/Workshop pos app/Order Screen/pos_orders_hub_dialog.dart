import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../Product Grid/product_grid_view_model.dart';
import '../../../widgets/pos_catalog_sync_app_bar_button.dart';

/// Logout-style YES/NO confirm — white card, yellow primary action, outlined cancel.
///
/// When [onConfirm] is set, Remove runs that future with a loader on the
/// button and only closes the dialog when it returns `true`.
Future<bool> showPosLogoutStyleConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  /// When true, Cancel is a filled secondary (dark) button instead of outlined.
  bool cancelUsesSecondaryFill = false,
  Future<bool> Function()? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: onConfirm == null,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => _PosLogoutStyleConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      cancelUsesSecondaryFill: cancelUsesSecondaryFill,
      onConfirm: onConfirm,
    ),
  ).then((value) => value ?? false);
}

class _PosLogoutStyleConfirmDialog extends StatefulWidget {
  const _PosLogoutStyleConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.cancelLabel,
    this.cancelUsesSecondaryFill = false,
    this.onConfirm,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String? cancelLabel;
  final bool cancelUsesSecondaryFill;
  final Future<bool> Function()? onConfirm;

  @override
  State<_PosLogoutStyleConfirmDialog> createState() =>
      _PosLogoutStyleConfirmDialogState();
}

class _PosLogoutStyleConfirmDialogState
    extends State<_PosLogoutStyleConfirmDialog> {
  bool _isBusy = false;

  Future<void> _handleConfirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final success = await onConfirm();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isBusy = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isBusy,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: widget.cancelUsesSecondaryFill
                        ? ElevatedButton(
                            onPressed: _isBusy
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryLight,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.cancelLabel ?? l10n.promoDeleteCancel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: _isBusy
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              widget.cancelLabel ?? l10n.promoDeleteCancel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _handleConfirm,
                      style: AppButtonBusy.elevatedLocked(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isBusy
                          ? AppButtonBusy.loaderOnFill(
                              AppColors.primaryLight,
                              size: 20,
                            )
                          : Text(
                              widget.confirmLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                    ),
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

/// Compact YES/NO confirm sheet — same UI as cancel job on Orders Hub job cards.
Future<void> showPosOrdersCompactConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required Future<bool> Function() onConfirm,
  String? cancelLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PosOrdersCompactConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
    ),
  );
}

class _PosOrdersCompactConfirmDialog extends StatefulWidget {
  const _PosOrdersCompactConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String? cancelLabel;
  final Future<bool> Function() onConfirm;

  @override
  State<_PosOrdersCompactConfirmDialog> createState() =>
      _PosOrdersCompactConfirmDialogState();
}

class _PosOrdersCompactConfirmDialogState
    extends State<_PosOrdersCompactConfirmDialog> {
  bool _isBusy = false;

  Future<void> _handleConfirm() async {
    setState(() => _isBusy = true);
    try {
      final success = await widget.onConfirm();
      if (mounted && success) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noLabel = widget.cancelLabel ?? l10n.posOrdersNoBtn;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              widget.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.secondaryLight,
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      noLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _handleConfirm,
                    style: AppButtonBusy.elevatedLocked(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.onPrimaryLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _isBusy
                        ? AppButtonBusy.loaderOnFill(
                            AppColors.primaryLight,
                            size: 20,
                          )
                        : Text(
                            widget.confirmLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Same horizontal/vertical insets as Products & Services hub overlay.
EdgeInsets posOrdersHubDialogInsets(Size size) {
  final isTablet = size.width > 600;
  final horizontalInset = isTablet ? 0.04 : 0.06;
  final verticalInset = isTablet ? 0.05 : 0.07;
  return EdgeInsets.symmetric(
    horizontal: size.width * horizontalInset,
    vertical: size.height * verticalInset,
  );
}

/// Primary header with centered title and rounded bottom corners (hub / checkout / maintenance).
class PosPrimaryDialogHeader extends StatelessWidget {
  const PosPrimaryDialogHeader({
    super.key,
    required this.title,
    required this.isTablet,
    this.onClose,
    this.showCatalogSync = false,
    this.catalogSyncDepartmentId,
    this.roundBottom = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  final String title;
  final bool isTablet;
  final VoidCallback? onClose;
  final bool showCatalogSync;
  final String? catalogSyncDepartmentId;
  /// When false, yellow header has square bottom edge (no curve into body).
  final bool roundBottom;
  /// Defaults to [AppColors.primaryLight]. Use transparent for flush dialogs.
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  static const headerBottomRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final bottomR = roundBottom ? headerBottomRadius : 0.0;
    final bg = backgroundColor ?? AppColors.primaryLight;
    final fg = foregroundColor ?? AppColors.onPrimaryLight;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomR),
          bottomRight: Radius.circular(bottomR),
        ),
      ),
      padding: padding ??
          EdgeInsetsDirectional.fromSTEB(
            isTablet ? 8 : 6,
            isTablet ? 7 : 5,
            isTablet ? 0 : 0,
            isTablet ? 7 : 5,
          ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: showCatalogSync
                  ? (isTablet ? 112 : 96)
                  : (onClose != null ? 36 : 12),
            ),
            child: LocalizedApiText(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: fg,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (showCatalogSync || onClose != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCatalogSync)
                    PosCatalogSyncAppBarButton(
                      catalogDepartmentId: catalogSyncDepartmentId,
                    ),
                  if (onClose != null)
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: fg,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: onClose,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Alias used by checkout dialogs.
typedef PosCheckoutDialogHeader = PosPrimaryDialogHeader;

/// Layout preset for hub overlays opened from [PosOrdersView].
enum PosOrdersHubDialogVariant {
  /// Wider catalog dialog; slightly shorter than default.
  productsAndServices,

  /// Assign technician overlay (same size as [productsAndServices]).
  assignTechnician,
}

/// Large overlay for Products & Services / Assign Technicians from [PosOrdersView]
/// so the order list and summary stay visible behind the dialog.
Future<T?> showPosOrdersHubDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  PosOrdersHubDialogVariant variant = PosOrdersHubDialogVariant.productsAndServices,
  String? catalogSyncDepartmentId,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final isTablet = size.width > 600;
      // Same width for both hub overlays; height differs by variant.
      final hubInsets = posOrdersHubDialogInsets(size);
      final bodyPadding = EdgeInsets.fromLTRB(
        isTablet ? 8 : 6,
        isTablet ? 8 : 6,
        isTablet ? 8 : 6,
        isTablet ? 8 : 6,
      );
      return Dialog(
        insetPadding: hubInsets,
        backgroundColor: const Color(0xFFFBF9F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosPrimaryDialogHeader(
              title: title,
              isTablet: isTablet,
              showCatalogSync:
                  variant == PosOrdersHubDialogVariant.productsAndServices,
              catalogSyncDepartmentId: catalogSyncDepartmentId,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
            Expanded(
              child: Padding(
                padding: bodyPadding,
                child: child,
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    if (context.mounted) {
      context.read<ProductGridViewModel>().clearSearch();
    }
  });
}

/// Select all / clear all actions for maintenance checklist dialogs.
class PosMaintenanceChecklistBulkActions extends StatelessWidget {
  final bool disabled;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  const PosMaintenanceChecklistBulkActions({
    super.key,
    required this.disabled,
    required this.onSelectAll,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 11,
      color: disabled ? Colors.grey.shade500 : AppColors.secondaryLight,
    );
    final clearLabelStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 11,
      color: disabled ? Colors.grey.shade400 : AppColors.secondaryLight,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: disabled ? null : onSelectAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: disabled
                ? Colors.grey.shade200
                : AppColors.primaryLight,
            foregroundColor: AppColors.secondaryLight,
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade500,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.posOrdersChecklistSelectAll, style: labelStyle),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: disabled ? null : onClearAll,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondaryLight,
            disabledForegroundColor: Colors.grey.shade400,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: disabled ? Colors.grey.shade300 : Colors.blueGrey.shade400,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.posOrdersChecklistClearAll, style: clearLabelStyle),
        ),
      ],
    );
  }
}
