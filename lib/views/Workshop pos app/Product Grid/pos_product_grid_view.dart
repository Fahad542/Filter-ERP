import 'dart:async';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../utils/toast_service.dart';
import '../../../models/pos_product_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_arabic_font_fallbacks.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../services/session_service.dart';
import '../Home Screen/pos_view_model.dart';
import '../Navbar/pos_shell.dart';
import '../Order Screen/pos_orders_hub_dialog.dart';
import '../Promo/promo_code_dialog.dart';
import '../Promo/promo_view_model.dart';
import '../../../models/pos_order_model.dart';
import '../Technician Assignment/pos_technician_assignment_view.dart';
import '../Department/department_view_model.dart';
import '../Department/pos_department_view.dart';
import 'product_grid_view_model.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';

/// Same typography as order list empty state ([PosOrdersView] `_OrdersEmptyStateBody`).
TextStyle _posCatalogEmptyMessageTextStyle(BuildContext context) => TextStyle(
  fontSize: 17,
  fontWeight: localeFontWeight(context, FontWeight.w700),
  color: Colors.grey.shade500,
  height: 1.35,
);

String? _cleanProductArabicName(Object? value) {
  final v = value?.toString().trim();
  if (v == null || v.isEmpty || v.toLowerCase() == 'null') return null;
  return v;
}

Widget _productTitleText(
  BuildContext context,
  PosProduct product, {
  TextStyle? style,
  int? maxLines,
  TextOverflow? overflow,
  TextAlign? textAlign,
}) {
  final langCode = Localizations.localeOf(context).languageCode;
  final backendArabic = langCode == 'ar'
      ? _cleanProductArabicName(product.productNameArabic)
      : null;

  if (backendArabic != null) {
    return Text(
      backendArabic,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  return LocalizedApiText(
    product.name,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
  );
}


String _localizedStockLabel(BuildContext context, PosProduct product) {
  final l10n = AppLocalizations.of(context)!;
  if (product.isInfiniteQty) return l10n.posProductStockInfinite;
  final langCode = Localizations.localeOf(context).languageCode;
  if (langCode != 'ar') return product.stockLabel;
  if (product.isService) return 'خدمة';
  if (product.stock > 5) {
    return 'متوفر (${AppTranslationService.localizeDigitsForLanguage(product.stock.toString(), langCode)})';
  }
  if (product.stock > 0) {
    return 'منخفض (${AppTranslationService.localizeDigitsForLanguage(product.stock.toString(), langCode)})';
  }
  return 'غير متوفر';
}

/// Catalog search: English + Arabic titles (department filter is applied separately).
bool _posProductMatchesCatalogSearch(PosProduct product, String queryLower) {
  if (queryLower.isEmpty) return true;
  if (product.name.toLowerCase().contains(queryLower)) return true;
  final ar = product.productNameArabic?.trim().toLowerCase() ?? '';
  return ar.isNotEmpty && ar.contains(queryLower);
}

class _LoadMoreProductsTile extends StatelessWidget {
  final bool isTablet;
  final int remainingCount;
  final VoidCallback onPressed;

  const _LoadMoreProductsTile({
    required this.isTablet,
    required this.remainingCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = remainingCount > ProductGridViewModel.productPageSize
        ? '+${ProductGridViewModel.productPageSize}'
        : '+$remainingCount';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 14,
            vertical: isTablet ? 18 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.expand_more_rounded, color: AppColors.secondaryLight),
              const SizedBox(width: 8),
              Text(
                'Load More $label',
                style: TextStyle(
                  fontWeight: localeFontWeight(context, FontWeight.w800),
                  fontSize: isTablet ? 14 : 13,
                  color: AppColors.secondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PosProductGridView extends StatefulWidget {
  final String? departmentName;
  final String? departmentId;
  final List<String>? selectedDepartmentIds;
  final List<String>? selectedDepartmentNames;
  final List<dynamic>? preSelectedItems;
  final String? completingOrderId;
  final PosOrder? completingOrder;
  final bool isReadOnly;
  final bool showBackButton;
  final bool isMainTab;

  /// Opened from [PosOrdersView] overlay — no app bar; parent dialog has close (×).
  final bool embeddedInOrdersHubDialog;

  /// When this screen sits inside another [Scaffold] (e.g. [PosShell]), the outer
  /// scaffold already resizes for the keyboard; keeping this `true` double-counts
  /// [MediaQuery.viewInsets] and can collapse the catalog to a blank strip.
  final bool resizeForKeyboard;

  const PosProductGridView({
    super.key,
    this.departmentName,
    this.departmentId,
    this.selectedDepartmentIds,
    this.selectedDepartmentNames,
    this.preSelectedItems,
    this.completingOrderId,
    this.completingOrder,
    this.isReadOnly = false,
    this.showBackButton = true,
    this.isMainTab = false,
    this.embeddedInOrdersHubDialog = false,
    this.resizeForKeyboard = true,
  });

  @override
  State<PosProductGridView> createState() => _PosProductGridViewState();
}

class _PosProductGridViewState extends State<PosProductGridView> {
  bool get _inOrdersHubDialog => widget.embeddedInOrdersHubDialog;

  /// Shell Inventory tab ([isMainTab]) and orders-hub overlay use tighter catalog chrome.
  bool get _tightCatalogChrome => _inOrdersHubDialog || widget.isMainTab;

  // All state moved to ProductGridViewModel and PosViewModel
  String? _activeDepartmentTabId;
  late final bool _isDepartmentSelectionMode;
  late List<String> _departmentIds;

  /// Translated version of [widget.departmentName] for the AppBar title.
  /// Populated asynchronously; starts as the raw name to avoid flicker.
  String? _translatedDeptName;

  /// Cached for [dispose] — do not call [context.read] after the element is deactivated.
  PosViewModel? _posVmRef;
  ProductGridViewModel? _gridVmRef;

  List<String> _resolveInitialDepartmentIds() {
    final ids = (widget.selectedDepartmentIds ?? const [])
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (ids.isNotEmpty) return ids;
    if (widget.departmentId != null && widget.departmentId!.trim().isNotEmpty) {
      return [widget.departmentId!];
    }
    return const [];
  }

  List<String> get _selectedDepartmentIds => _departmentIds;

  Map<String, String> get _selectedDepartmentNameById {
    final map = <String, String>{};
    final ids = widget.selectedDepartmentIds ?? const <String>[];
    final names = widget.selectedDepartmentNames ?? const <String>[];
    final count = ids.length < names.length ? ids.length : names.length;
    for (var i = 0; i < count; i++) {
      final id = ids[i];
      if (id.trim().isEmpty) continue;
      map[id] = names[i];
    }
    if (widget.departmentId != null &&
        widget.departmentId!.trim().isNotEmpty &&
        widget.departmentName != null &&
        widget.departmentName!.trim().isNotEmpty) {
      map.putIfAbsent(widget.departmentId!, () => widget.departmentName!);
    }
    return map;
  }

  bool get _hasMultiSelectedDepartments => _selectedDepartmentIds.length > 1;

  String? _resolvePromoContextDeptId() {
    final activeDeptId = _isDepartmentSelectionMode ? _activeDepartmentTabId : null;
    return activeDeptId ??
        (widget.departmentId != null &&
                widget.departmentId!.trim().isNotEmpty &&
                widget.departmentId != 'All'
            ? widget.departmentId!.trim()
            : null);
  }

  Future<bool> _confirmBackNavigation() async {
    return true;
  }

  List<JobTechnician> _initialAssignedForWalkInTechnicianScreen() {
    final o = widget.completingOrder;
    final jid = widget.completingOrderId?.trim();
    if (o == null || jid == null || jid.isEmpty) return const [];
    for (final j in o.jobs) {
      if (j.id == jid) return j.distinctActiveTechnicians;
    }
    return const [];
  }

  void _openTechniciansPage() {
    final vm = context.read<PosViewModel>();

    String deptId = widget.departmentId?.trim() ?? '';
    String? deptName = widget.departmentName;
    if (deptId.isEmpty) {
      final cart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
      if (cart.isNotEmpty) {
        final p = cart.first.product;
        deptId = (p.departmentId ?? '').trim();
        final dn = (p.departmentName ?? '').trim();
        if (dn.isNotEmpty) deptName = dn;
      }
      if (deptId.isEmpty && vm.products.isNotEmpty) {
        final p = vm.products.first;
        deptId = (p.departmentId ?? '').trim();
        if ((deptName ?? '').trim().isEmpty) {
          final dn = (p.departmentName ?? '').trim();
          if (dn.isNotEmpty) deptName = dn;
        }
      }
      if (deptId.isEmpty) deptId = '1';
    }

    String jobId = '';
    List<JobTechnician> initial = const [];
    bool isWalkIn = true;

    final completingId = widget.completingOrderId?.trim();
    final completingOrder = widget.completingOrder;
    if (completingOrder != null &&
        completingId != null &&
        completingId.isNotEmpty) {
      PosOrderJob? job;
      for (final j in completingOrder.jobs) {
        if (j.id == completingId) {
          job = j;
          break;
        }
      }
      if (job != null && job.id.trim().isNotEmpty) {
        jobId = job.id.trim();
        initial = job.distinctActiveTechnicians;
        isWalkIn = false;
      } else {
        initial = _initialAssignedForWalkInTechnicianScreen();
      }
    } else {
      final placed = vm.jobIdForPlacedDepartment(deptId);
      if (placed != null && placed.trim().isNotEmpty) {
        jobId = placed.trim();
        isWalkIn = false;
        final sel = vm.selectedOrder;
        if (sel != null) {
          for (final j in sel.jobs) {
            if (j.id == jobId) {
              initial = j.distinctActiveTechnicians;
              break;
            }
          }
        }
      } else {
        final cur = vm.currentJobId?.trim() ?? '';
        if (cur.isNotEmpty) {
          jobId = cur;
          isWalkIn = false;
          final sel = vm.selectedOrder;
          if (sel != null) {
            for (final j in sel.jobs) {
              if (j.id == jobId) {
                initial = j.distinctActiveTechnicians;
                break;
              }
            }
          }
        }
      }
    }

    final assignmentView = PosTechnicianAssignmentView(
      jobId: jobId,
      departmentName: deptName,
      departmentId: deptId,
      isWalkIn: isWalkIn,
      initialAssignedTechnicians: initial,
      embeddedInOrdersHubDialog: widget.embeddedInOrdersHubDialog,
    );
    if (widget.embeddedInOrdersHubDialog) {
      final l10n = AppLocalizations.of(context)!;
      showPosOrdersHubDialog(
        context: context,
        title: l10n.posNavTechnicians,
        variant: PosOrdersHubDialogVariant.assignTechnician,
        child: assignmentView,
      );
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => assignmentView),
      );
    }
  }

  Widget _buildAddTechnicianButton(bool isTablet) {
    final hub = _inOrdersHubDialog;
    final child = Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(hub ? 10 : 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openTechniciansPage,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? (hub ? 10 : 12) : 8,
            vertical: isTablet ? (hub ? 7 : 10) : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.onPrimaryLight,
                size: isTablet ? (hub ? 16 : 18) : 16,
              ),
              if (isTablet) ...[
                SizedBox(width: hub ? 5 : 6),
                Text(
                  AppLocalizations.of(context)!.posProductAddTechnician,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onPrimaryLight,
                    fontWeight: localeFontWeight(context, FontWeight.w800),
                    fontSize: hub ? 10.5 : 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (isTablet) return child;
    return Tooltip(message: AppLocalizations.of(context)!.posProductAddTechnician, child: child);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _posVmRef = context.read<PosViewModel>();
    _gridVmRef = context.read<ProductGridViewModel>();
    _updateTranslatedDeptName();
  }

  /// Translates [widget.departmentName] asynchronously and stores the result
  /// in [_translatedDeptName] so the AppBar title shows the localized string.
  void _updateTranslatedDeptName() {
    final raw = widget.departmentName;
    if (raw == null || raw.trim().isEmpty || raw.trim().toLowerCase() == 'all') {
      return;
    }
    final langCode = Localizations.localeOf(context).languageCode;
    // Show raw immediately, then replace with translation when ready.
    if (_translatedDeptName == null) {
      setState(() => _translatedDeptName = raw);
    }
    LocalizedApiText.resolve(raw, langCode).then((translated) {
      if (mounted && translated != _translatedDeptName) {
        setState(() => _translatedDeptName = translated);
      }
    });
  }

  Future<void> _loadCatalogForDepartment(
    PosViewModel vm, {
    required String? departmentId,
    PosOrder? completingOrder,
    bool forceRefresh = false,
  }) async {
    final deptId = departmentId?.trim();
    final isCorpOrder = completingOrder != null &&
        (completingOrder.isCorporateWalkIn ||
            completingOrder.isCorporateBookingOrder);

    if (isCorpOrder && deptId != null && deptId.isNotEmpty) {
      await vm.prepareCorporateJobProductCatalog(
        order: completingOrder,
        departmentId: deptId,
        departmentName: widget.departmentName,
        corporateBookingId: completingOrder.corporateOrderId,
        forceRefresh: forceRefresh,
      );
      return;
    }

    await vm.fetchProducts(
      departmentId: deptId,
      departmentName: widget.departmentName,
      forceRefresh: forceRefresh || isCorpOrder,
    );
  }

  @override
  void initState() {
    super.initState();
    _isDepartmentSelectionMode =
    (widget.selectedDepartmentIds?.isNotEmpty ?? false);
    _departmentIds = List<String>.from(_resolveInitialDepartmentIds());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<PosViewModel>();
      vm.setPromoContextDepartment(
        _isDepartmentSelectionMode ? _activeDepartmentTabId : null,
        isMainTab: widget.isMainTab,
      );

      // Editing an order that may carry a promo: warm the promo catalog cache
      // so removing a promo-critical item can warn before dropping the promo.
      if (vm.editingOrder != null && vm.editingOrderAppliedPromo() != null) {
        unawaited(context.read<PromoViewModel>().fetchAvailablePromos());
      }

      // Reset product type filters so returning to grid shows all items by default
      vm.setProductType('All');
      final gridVm = context.read<ProductGridViewModel>();
      gridVm.clearSearch();
      gridVm.setSubCategory('All');

      // Set the department from widget parameter if provided
      if (widget.departmentName != null && widget.departmentName != 'All') {
        gridVm.setDepartment(widget.departmentName!);
      }

      final completingOrder = widget.completingOrder;
      final isCorpOrder = completingOrder != null &&
          (completingOrder.isCorporateWalkIn ||
              completingOrder.isCorporateBookingOrder);

      if (_isDepartmentSelectionMode && _selectedDepartmentIds.isNotEmpty) {
        final d = _selectedDepartmentIds.first.trim();
        _activeDepartmentTabId = d;
        vm.setPromoContextDepartment(
          _activeDepartmentTabId,
          isMainTab: widget.isMainTab,
        );
        await _loadCatalogForDepartment(
          vm,
          departmentId: d,
          completingOrder: completingOrder,
          forceRefresh: isCorpOrder,
        );
      } else if (widget.showBackButton && widget.departmentId != null && widget.departmentId != 'All') {
        final d = widget.departmentId!.trim();
        _activeDepartmentTabId = widget.departmentId;
        vm.setPromoContextDepartment(
          _activeDepartmentTabId,
          isMainTab: widget.isMainTab,
        );
        await _loadCatalogForDepartment(
          vm,
          departmentId: widget.departmentId,
          completingOrder: completingOrder,
          forceRefresh: isCorpOrder,
        );
      } else if (widget.showBackButton && vm.allProducts.isEmpty) {
        _activeDepartmentTabId = null;
        vm.setPromoContextDepartment(null, isMainTab: widget.isMainTab);
        await vm.fetchProducts(departmentName: widget.departmentName);
      }

      // Always default to 'All' category when opening the grid to show all available options
      _onCategorySelected(vm, 'All');

      if (!widget.isMainTab && widget.preSelectedItems != null && widget.preSelectedItems!.isNotEmpty) {
        // Clear cart first so we don't duplicate when repeatedly entering the screen
        vm.clearCart(isMainTab: false);

        final allProducts = vm.allProducts; // Use unfiltered list to guarantee both products and services are found
        for (final item in widget.preSelectedItems!) {
          try
          {
            final productId = item['productId']?.toString();
            final serviceId = item['serviceId']?.toString();
            final fallbackId = item['id']?.toString();
            final lookupId = productId ?? serviceId ?? fallbackId;
            final qtyRaw = item['quantity'] ?? item['qty'] ?? 1;
            final double qty = (qtyRaw is num) ? qtyRaw.toDouble() : double.tryParse(qtyRaw.toString()) ?? 1.0;

            if (lookupId != null && lookupId.isNotEmpty) {
              final bool? mustBeService = serviceId != null && serviceId.isNotEmpty
                  ? true
                  : (productId != null && productId.isNotEmpty ? false : null);

              final product = allProducts.firstWhere((p) {
                final idMatches = p.id == lookupId;
                if (!idMatches) return false;
                if (mustBeService == null) return true;
                return p.isServiceType == mustBeService;
              });
              vm.addToCart(product);

              if (qty != 1.0) {
                vm.setSpecificQuantity(product, qty);
              }

              // Load previously applied API discounts into the POS Cart item
              final discountTypeStr = item['discountType']?.toString();
              final discountValStr = item['discountValue']?.toString() ?? '0';
              final discountValue = double.tryParse(discountValStr) ?? 0.0;

              if (discountValue > 0 && discountTypeStr != null && discountTypeStr.isNotEmpty) {
                vm.setIndividualDiscount(product, discountValue, discountTypeStr == 'percent');
              }

              final upRaw = item['unitPrice'];
              if (upRaw != null) {
                final u = (upRaw is num)
                    ? upRaw.toDouble()
                    : double.tryParse(upRaw.toString());
                if (u != null && u > 0) {
                  if (product.isPriceEditable) {
                    vm.setServiceUnitPrice(product, u, isMainTab: false);
                  } else {
                    vm.setLineUnitPrice(product, u, isMainTab: false);
                  }
                }
              }
            }
          } catch (_)
          {
            // Product not found, ignore
          }
        }
        if (vm.shouldUseCorporateQuotedCatalog) {
          vm.applyCorporateQuotedPricesToActiveCart(isMainTab: widget.isMainTab);
        }
      }

      // Hydrate global + promo from saved order/job when reopening.
      if (widget.completingOrder != null) {
        PosOrderJob? targetJob;
        if (widget.completingOrderId != null && widget.completingOrder!.jobs.isNotEmpty) {
          try {
            targetJob = widget.completingOrder!.jobs.firstWhere((j) => j.id == widget.completingOrderId);
          } catch (_) {}
        }

        final globalType = targetJob?.totalDiscountType ?? widget.completingOrder!.totalDiscountType;
        final globalValue = (targetJob != null && targetJob.totalDiscountValue > 0)
            ? targetJob.totalDiscountValue
            : (widget.completingOrder!.totalDiscountValue ?? 0.0);

        if (globalValue > 0 && globalType != null && globalType.isNotEmpty) {
          vm.setGlobalDiscount(globalValue, globalType == 'percent');
        }

        vm.hydratePromoFromSavedOrder(
          order: widget.completingOrder!,
          job: targetJob,
          isMainTab: widget.isMainTab,
        );
        if (context.mounted) {
          final promoVm = context.read<PromoViewModel>();
          final hydrateRevision = vm.promoRevision;
          final promoDeptId = _resolvePromoContextDeptId();
          final hydratePromoCode = vm
              .getActivePromoCode(widget.isMainTab, departmentId: promoDeptId)
              .trim();
          if (hydratePromoCode.isNotEmpty) {
            promoVm.promoController.text = hydratePromoCode;
            final promoId =
                targetJob?.promoCodeId ?? widget.completingOrder!.promoCodeId;
            promoVm.applyHydratedPromoEligibilityFromCache(
              vm,
              code: hydratePromoCode,
              promoCodeId: promoId,
              isMainTab: widget.isMainTab,
            );
            unawaited(() async {
              await promoVm.ensurePromoCatalogLoaded();
              if (!context.mounted) return;
              if (vm.promoRevision != hydrateRevision) return;
              final currentCode = vm
                  .getActivePromoCode(widget.isMainTab, departmentId: promoDeptId)
                  .trim();
              if (currentCode != hydratePromoCode) return;
              promoVm.applyHydratedPromoEligibilityFromCache(
                vm,
                code: hydratePromoCode,
                promoCodeId: promoId,
                isMainTab: widget.isMainTab,
              );
            }());
          }
        }
      } else {
        final cart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
        if (cart.isEmpty && vm.hasActivePromo(widget.isMainTab) && context.mounted) {
          context.read<PromoViewModel>().removeAppliedPromo(
                vm,
                isMainTab: widget.isMainTab,
              );
        }
      }

      vm.refreshGlobalDiscountFieldText(widget.isMainTab);
    });
  }

  @override
  void dispose() {
    _posVmRef?.setPromoContextDepartment(
      null,
      isMainTab: widget.isMainTab,
    );
    _gridVmRef?.clearSearch(notify: false);
    super.dispose();
  }

  // Mock departments - REMOVED
  // final List<Map<String, dynamic>> _departments = [
  //   {'name': 'Oil Change', 'icon': Icons.oil_barrel_outlined},
  //   {'name': 'Car Wash', 'icon': Icons.local_car_wash_outlined},
  //   {'name': 'Repair', 'icon': Icons.build_outlined},
  //   {'name': 'Tyre Service', 'icon': Icons.tire_repair_outlined},
  //   {'name': 'AC Service', 'icon': Icons.ac_unit_outlined},
  //   {'name': 'Detailing', 'icon': Icons.auto_awesome_outlined},
  //   {'name': 'Battery', 'icon': Icons.battery_charging_full_outlined},
  // ];

  // Mock products per department - REMOVED
  // final Map<String, List<PosProduct>> _departmentProducts = {
  //   'Oil Change': [
  //     const PosProduct(name: 'Engine Oil 5W-30', category: 'Oils', price: 85, stock: 24, unit: 'Litre'),
  //     const PosProduct(name: 'Engine Oil 10W-40', category: 'Oils', price: 65, stock: 18, unit: 'Litre'),
  //     const PosProduct(name: 'Synthetic Oil 0W-20', category: 'Oils', price: 120, stock: 8, unit: 'Litre'),
  //     const PosProduct(name: 'Oil Filter', category: 'Filters', price: 35, stock: 30, unit: 'Piece'),
  //     const PosProduct(name: 'Air Filter', category: 'Filters', price: 45, stock: 3, reorderLevel: 5, unit: 'Piece'),
  //     const PosProduct(name: 'Cabin Filter', category: 'Filters', price: 55, stock: 0, unit: 'Piece'),
  //     const PosProduct(name: 'Drain Plug Gasket', category: 'Parts', price: 8, stock: 50, unit: 'Piece'),
  //     const PosProduct(name: 'Oil Change - Standard', category: 'Labour', price: 50, isService: true),
  //     const PosProduct(name: 'Oil Change - Full Synthetic', category: 'Labour', price: 80, isService: true),
  //     const PosProduct(name: 'Engine Flush', category: 'Labour', price: 60, isService: true),
  //   ],
  //   'Car Wash': [
  //     const PosProduct(name: 'Basic Exterior Wash', category: 'Wash', price: 35, isService: true),
  //     const PosProduct(name: 'Full Interior + Exterior', category: 'Wash', price: 75, isService: true),
  //     const PosProduct(name: 'Premium Detailing Wash', category: 'Wash', price: 150, isService: true),
  //     const PosProduct(name: 'Car Shampoo', category: 'Consumables', price: 25, stock: 15, unit: 'Bottle'),
  //     const PosProduct(name: 'Wax Polish', category: 'Consumables', price: 40, stock: 8, unit: 'Bottle'),
  //     const PosProduct(name: 'Air Freshener', category: 'Extras', price: 15, stock: 40, unit: 'Piece'),
  //   ],
  //   'Repair': [
  //     const PosProduct(name: 'Brake Pad Set (Front)', category: 'Brakes', price: 180, stock: 6, unit: 'Set'),
  //     const PosProduct(name: 'Brake Pad Set (Rear)', category: 'Brakes', price: 160, stock: 4, unit: 'Set'),
  //     const PosProduct(name: 'Brake Disc (Front)', category: 'Brakes', price: 250, stock: 2, reorderLevel: 3, unit: 'Piece'),
  //     const PosProduct(name: 'Spark Plug Set', category: 'Engine', price: 120, stock: 10, unit: 'Set'),
  //     const PosProduct(name: 'Belt Tensioner', category: 'Engine', price: 95, stock: 3, reorderLevel: 5, unit: 'Piece'),
  //     const PosProduct(name: 'Diagnostic Scan', category: 'Labour', price: 100, isService: true),
  //     const PosProduct(name: 'Brake Service Labour', category: 'Labour', price: 120, isService: true),
  //   ],
  // };

  List<PosProduct> get _currentProducts {
    final vm = Provider.of<PosViewModel>(context);
    final prods = vm.products;
    if (widget.departmentId != null && widget.departmentId != 'All') {
      return prods.where((p) => p.departmentId == widget.departmentId).toList();
    }
    return prods;
  }

  /// Catalog lines scoped to the active department (for tab counts).
  List<PosProduct> _departmentScopedCatalog(
    PosViewModel vm,
    ProductGridViewModel gridVm,
  ) {
    var list = vm.allProducts.toList();
    if (_hasMultiSelectedDepartments) {
      list = list
          .where(
            (p) =>
                _activeDepartmentTabId == null ||
                p.departmentId == _activeDepartmentTabId,
          )
          .toList();
    } else if (widget.departmentId != null && widget.departmentId != 'All') {
      list = list.where((p) => p.departmentId == widget.departmentId).toList();
    } else {
      list = list
          .where(
            (p) =>
                gridVm.selectedDepartment == 'All' ||
                p.departmentName == gridVm.selectedDepartment,
          )
          .toList();
    }
    return list;
  }

  List<PosProduct> _catalogSourceForCategoryTabs(
    PosViewModel vm,
    ProductGridViewModel gridVm,
  ) {
    if (vm.selectedProductType != 'All') {
      final isService = vm.selectedProductType == 'Services';
      return _departmentScopedCatalog(vm, gridVm)
          .where((p) => p.isServiceType == isService)
          .toList();
    }
    return _departmentScopedCatalog(vm, gridVm);
  }

  List<String> get _categories {
    final prods = Provider.of<PosViewModel>(context).allProducts;
    Iterable<PosProduct> filtered = prods;
    if (widget.departmentId != null && widget.departmentId != 'All') {
      filtered = filtered.where((p) => p.departmentId == widget.departmentId);
    }

    final vm = Provider.of<PosViewModel>(context);
    filtered = filtered.where((p) {
      if (vm.selectedProductType == 'All') return true;
      return vm.selectedProductType == 'Products' ? !p.isService : p.isService;
    });

    final cats = filtered.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  double get _subtotal => Provider.of<PosViewModel>(context).getSubtotalExclVat(widget.isMainTab);
  double get _totalVat => Provider.of<PosViewModel>(context).getTotalTaxValue(widget.isMainTab);

  double get _discountAmount {
    final vm = Provider.of<PosViewModel>(context);
    return vm.getTotalIndividualDiscount(widget.isMainTab) + vm.getTotalGlobalDiscountValue(widget.isMainTab);
  }

  double get _grandTotal {
    final vm = Provider.of<PosViewModel>(context);
    return vm.getTotalAmountValue(widget.isMainTab);
  }

  void _addToCart(PosProduct product) {
    final error = context.read<PosViewModel>().addToCart(product, isMainTab: widget.isMainTab);
    if (error != null) {
      ToastService.showError(context, error);
    }
  }

  void _updateQty(PosProduct product, double delta) async {
    final vm = context.read<PosViewModel>();
    final cartQty = _cartQtyForProduct(vm, product);
    if (cartQty + delta <= 0) {
      await _confirmAndRemoveCartItem(context, product);
      _consumePendingPopupCloseAfterPromoRemoval();
      return;
    }
    if (!mounted) return;
    final error = vm.updateQuantity(product, delta, isMainTab: widget.isMainTab);
    if (error != null) {
      ToastService.showError(context, error);
    }
  }

  /// Order promo (stored on the jobs) that stops applying if [product] is
  /// removed from the dept cart being edited. Evaluated order-wide: other
  /// jobs' lines + this dept's cart minus the item (matters for
  /// "all selected items required" promos spanning departments).
  String? _orderPromoInvalidatedIfItemRemoved(
    PosViewModel vm,
    PosProduct product,
  ) {
    if (widget.isMainTab) return null;
    if (vm.editingOrder == null) return null;
    final promoRef = vm.editingOrderAppliedPromo();
    if (promoRef == null) return null;
    final eligibility =
        context.read<PromoViewModel>().resolveOrderSummaryPromoEligibility(
              promoCode: promoRef.code,
              promoCodeId: promoRef.id.isNotEmpty ? promoRef.id : null,
            );
    if (eligibility == null || !eligibility.isKnown) return null;
    // Only items that belong to the promo (selected ids/categories or an
    // "all" scope) can break it — everything else removes silently.
    if (!eligibility.isProductPartOfPromo(
      productId: product.id,
      isService: product.isService,
      categoryId: product.categoryId,
    )) {
      return null;
    }
    final before = vm.editingOrderCartSnapshot();
    final after = vm.editingOrderCartSnapshot(excludeProduct: product);
    if (before == null || after == null) return null;
    // Warn only when the removal itself breaks the promo — if it is already
    // broken (or survives), removing this item changes nothing promo-wise.
    if (!eligibility.canApplyToCart(before)) return null;
    if (eligibility.canApplyToCart(after)) return null;
    return promoRef.code.isNotEmpty ? promoRef.code : 'promo';
  }

  /// Set when "Remove item & promo" also saved the edited order — callers pop
  /// the dept products popup afterwards (same as pressing Save). Deferred to
  /// the call sites because one of them still has a bottom sheet on top.
  bool _pendingPopupCloseAfterPromoRemoval = false;

  void _consumePendingPopupCloseAfterPromoRemoval() {
    if (!_pendingPopupCloseAfterPromoRemoval) return;
    _pendingPopupCloseAfterPromoRemoval = false;
    if (!mounted || !widget.embeddedInOrdersHubDialog) return;
    Navigator.of(context).pop();
  }

  Future<bool> _confirmAndRemoveCartItem(
    BuildContext context,
    PosProduct product,
  ) async {
    if (widget.isReadOnly) return false;

    final vm = context.read<PosViewModel>();
    final invalidatedCodes = vm.promoCodesInvalidatedIfItemRemoved(
      product,
      isMainTab: widget.isMainTab,
    );
    final orderPromoInvalidated =
        _orderPromoInvalidatedIfItemRemoved(vm, product);

    if (invalidatedCodes.isEmpty && orderPromoInvalidated == null) {
      vm.removeFromCart(product, isMainTab: widget.isMainTab);
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    final itemName = product.name.trim().isNotEmpty ? product.name.trim() : product.id;
    final promoCode = {
      ...invalidatedCodes,
      if (orderPromoInvalidated != null) orderPromoInvalidated,
    }.join(', ');

    // Whichever detection path opened the dialog, the promo the user was
    // warned about must actually be dropped from the order's jobs — the local
    // cart promo state alone does not reach the server.
    final orderCarriesPromo =
        !widget.isMainTab && vm.editingOrderAppliedPromo() != null;
    final isEditingSavedOrder = !widget.isMainTab &&
        vm.editingOrder != null &&
        (vm.editingCompletingOrderId ?? '').trim().isNotEmpty;

    final confirmed = await showPosLogoutStyleConfirmDialog(
      context,
      title: l10n.posPromoRemoveItemConfirmTitle,
      body: l10n.posPromoRemoveItemConfirmBody(itemName, promoCode),
      confirmLabel: l10n.posPromoRemoveItemConfirmAction,
      cancelLabel: l10n.promoDeleteCancel,
      onConfirm: () async {
        // Clear the order promo server-side first: if it fails the dialog
        // stays open (nothing changed) and the user can retry or cancel.
        if (orderCarriesPromo) {
          final order = vm.editingOrder;
          if (order != null) {
            final removed = await vm.removePromoCodeFromOrder(order);
            if (!removed) {
              if (mounted) {
                final isAr =
                    Localizations.localeOf(context).languageCode == 'ar';
                ToastService.showError(
                  context,
                  vm.errorMessage ??
                      (isAr
                          ? 'تعذر إزالة كود الخصم'
                          : 'Failed to remove promo code'),
                );
              }
              return false;
            }
          }
        }
        vm.removeFromCart(
          product,
          isMainTab: widget.isMainTab,
          andClearPromo: invalidatedCodes.isNotEmpty,
        );
        // Persist the item removal to the order right away (same as pressing
        // Save) so the Order Summary reflects both the removed item and the
        // removed promo without an extra manual save.
        if (isEditingSavedOrder && mounted) {
          final saved = await vm.submitEditOrder(
            _resolveDepartmentIdsForSave(vm),
            context,
            forInvoicePanelSave: true,
          );
          if (saved) _pendingPopupCloseAfterPromoRemoval = true;
        }
        if (mounted) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          ToastService.showSuccess(
            context,
            isAr ? 'تمت إزالة كود الخصم' : 'Promo code removed',
            messageOnly: true,
          );
        }
        return true;
      },
    );

    return confirmed == true;
  }

  /// Card tap: products / qty-ON services increment; **qty-OFF services toggle**
  /// (add, or remove when already ×1).
  void _onCatalogCardTap(PosProduct product, double cartQty) {
    if (widget.isReadOnly) return;
    if (product.isServiceQtyLocked) {
      if (cartQty >= 1) {
        _updateQty(product, -1);
      } else {
        _addToCart(product);
      }
      return;
    }
    if (!_canIncrementProduct(product, cartQty)) return;
    _addToCart(product);
  }

  /// + button / card tap: block out-of-stock products and qty-OFF services at qty 1.
  bool _canIncrementProduct(PosProduct product, double cartQty) {
    if (widget.isReadOnly) return false;
    if (product.isOutOfStockForPos) return false;
    if (product.isServiceQtyLocked && cartQty >= 1) return false;
    if (product.cartQtyExceedsStock(cartQty + 1)) return false;
    return true;
  }

  double _cartQtyForProduct(PosViewModel vm, PosProduct product) {
    final activeCart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
    final idx = activeCart.indexWhere(
          (i) =>
      i.product.id == product.id &&
          i.product.isServiceType == product.isServiceType &&
          (i.product.departmentId ?? '') == (product.departmentId ?? ''),
    );
    if (idx < 0) return 0;
    return activeCart[idx].quantity;
  }

  /// Line total excl. VAT after order-level discount + promo (matches live invoice panel).
  double _cartLinePayableExclVat(PosViewModel vm, CartItem item) {
    final fullCart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
    final activeDeptId = _isDepartmentSelectionMode ? _activeDepartmentTabId : null;
    final promoContextDeptId = activeDeptId ??
        (widget.departmentId != null &&
                widget.departmentId!.trim().isNotEmpty &&
                widget.departmentId != 'All'
            ? widget.departmentId!.trim()
            : null);
    final activeCart = activeDeptId == null
        ? fullCart
        : fullCart
            .where((i) => (i.product.departmentId ?? '') == activeDeptId)
            .toList();
    if (!activeCart.any((i) => identical(i, item) ||
        (i.product.id == item.product.id &&
            i.product.isServiceType == item.product.isServiceType &&
            (i.product.departmentId ?? '') == (item.product.departmentId ?? '')))) {
      return item.totalPriceExclVat;
    }

    final afterItemDiscount = activeCart.fold<double>(
      0.0,
      (s, i) => s + i.totalPriceExclVat,
    ).clamp(0, double.infinity).toDouble();

    final allAfterItemDiscount = fullCart.fold<double>(
      0.0,
      (s, i) => s + i.totalPriceExclVat,
    ).clamp(0, double.infinity).toDouble();
    final globalDiscountAll = vm.getTotalGlobalDiscountValue(widget.isMainTab);
    final globalRatio =
        allAfterItemDiscount <= 0 ? 0.0 : (afterItemDiscount / allAfterItemDiscount);
    final globalDiscount = (globalDiscountAll * globalRatio)
        .clamp(0, afterItemDiscount)
        .toDouble();
    final afterGlobal = (afterItemDiscount - globalDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    final afterGlobalAll = vm.getPriceAfterJobDiscount(widget.isMainTab);
    final isInvoiceLevelPromo = vm.shouldShowPromoSummaryRows(
      widget.isMainTab,
      departmentId: promoContextDeptId,
    );
    final promoDiscountAll = isInvoiceLevelPromo
        ? 0.0
        : vm.getTotalPromoDiscountValue(
            widget.isMainTab,
            departmentId: promoContextDeptId,
          );
    final promoRatio = afterGlobalAll <= 0 ? 0.0 : (afterGlobal / afterGlobalAll);
    final fallbackPromoDiscount = (promoDiscountAll * promoRatio)
        .clamp(0, afterGlobal)
        .toDouble();
    final promoDiscount = isInvoiceLevelPromo
        ? 0.0
        : (activeDeptId == null
            ? fallbackPromoDiscount
            : vm.getPromoDiscountForBase(
                afterGlobal,
                isMainTab: widget.isMainTab,
                departmentId: activeDeptId,
              ));
    final taxable = (afterGlobal - promoDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    if (globalDiscount <= 0.0001 &&
        promoDiscount <= 0.0001 &&
        promoDiscountAll <= 0.0001) {
      return item.totalPriceExclVat;
    }
    if (afterItemDiscount <= 0.0001) return 0;
    return taxable * (item.totalPriceExclVat / afterItemDiscount);
  }

  Future<void> _applyDialogQuantity(
      BuildContext sheetContext,
      PosProduct product,
      String rawText,
      ) async {
    final rawFull =
    EnglishNumberFormatter.convert(rawText.trim()).replaceAll(',', '.');
    if (rawFull == '.' || rawFull == '-') {
      ToastService.showError(
        sheetContext,
        AppLocalizations.of(sheetContext)!.posProductInvalidQuantity,
      );
      return;
    }

    var raw = rawFull;
    if (raw.isEmpty) {
      raw = '0';
    } else if (RegExp(r'^\d+\.$').hasMatch(raw)) {
      raw = '${raw}0';
    }
    var qty = double.tryParse(raw) ?? 0;
    if (product.isServiceQtyLocked && qty > 1) qty = 1;

    final vm = context.read<PosViewModel>();
    if (qty <= 0) {
      final removed = await _confirmAndRemoveCartItem(sheetContext, product);
      if (!sheetContext.mounted) return;
      if (!removed) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(sheetContext).pop();
      // Sheet is closed now — safe to also close the dept products popup when
      // the removal auto-saved the order.
      _consumePendingPopupCloseAfterPromoRemoval();
      return;
    }

    final err = vm.setSpecificQuantity(
      product,
      qty,
      isMainTab: widget.isMainTab,
    );
    if (!sheetContext.mounted) return;
    if (err != null) {
      ToastService.showError(sheetContext, err);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(sheetContext).pop();
  }

  Future<void> _showProductQuantityEditorDialog(PosProduct product) async {
    if (widget.isReadOnly) return;
    // Qty-OFF services stay locked at 1 — no quantity text field.
    if (product.isServiceQtyLocked) return;
    if (product.isOutOfStockForPos) return;

    final vm = context.read<PosViewModel>();
    final initial = _cartQtyForProduct(vm, product);
    // Services always use whole units even if catalog flag were ever true.
    final allowDecimal = product.allowDecimalQty && !product.isService;

    final controller = TextEditingController(
      text: _formatGridQuantityLabel(product, initial),
    );

    await _showPosGridFormBottomSheet(
      context: context,
      title: _productTitleText(
        context,
        product,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyles.h2.copyWith(fontSize: 20),
      ),
      fieldBuilder: (sheetContext, loc) => TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.numberWithOptions(
          decimal: allowDecimal,
        ),
        inputFormatters: [
          EnglishNumberFormatter(),
          if (allowDecimal)
            const DecimalQtyTextInputFormatter(maxFractionDigits: 2)
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: _posGridFormDialogInputDecoration(
          sheetContext,
          loc.posProductQuantity,
        ),
        onSubmitted: (_) => _applyDialogQuantity(
          sheetContext,
          product,
          controller.text,
        ),
      ),
      cancelLabel: AppLocalizations.of(context)!.posOrdersCancelBtn,
      confirmLabel: AppLocalizations.of(context)!.lockerApplyFilter,
      onCancel: (sheetContext) => Navigator.of(sheetContext).pop(),
      onConfirm: (sheetContext) => _applyDialogQuantity(
        sheetContext,
        product,
        controller.text,
      ),
    );

    _disposePosGridFormControllerAfterSheet(controller);
  }

  bool _canShowEditableUnitPriceDialog(PosProduct product) {
    if (widget.isReadOnly) return false;
    return product.isPriceEditable;
  }

  Widget _buildEditablePriceEditTap(
    PosProduct product, {
    double iconSize = 16,
  }) {
    return GestureDetector(
      onTap: () => _showEditableUnitPriceDialog(product),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          Icons.edit_outlined,
          size: iconSize,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  CartItem? _cartLineForProduct(PosViewModel vm, PosProduct product) {
    final activeCart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
    for (final i in activeCart) {
      if (i.product.id == product.id &&
          i.product.isServiceType == product.isServiceType &&
          (i.product.departmentId ?? '') == (product.departmentId ?? '')) {
        return i;
      }
    }
    return null;
  }

  double _displayUnitPriceForProduct(PosViewModel vm, PosProduct product) {
    final line = _cartLineForProduct(vm, product);
    if (line != null) return line.effectiveUnitPrice;
    return vm.catalogDisplayPriceFor(product);
  }

  String _initialServicePriceFieldText(double price) {
    if (price <= 0) return '';
    final r = (price * 100).round() / 100.0;
    if (r % 1 == 0) return r.toInt().toString();
    var s = r.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  void _applyInvoiceScopedUnitPrice(
    BuildContext sheetContext,
    PosProduct product,
    String rawText,
  ) {
    final loc = AppLocalizations.of(sheetContext)!;
    final normalized = EnglishNumberFormatter.convert(rawText.trim())
        .replaceAll(',', '.');
    if (normalized.isEmpty || normalized == '.' || normalized == '-') {
      ToastService.showError(sheetContext, loc.posProductEditServicePriceInvalid);
      return;
    }
    var raw = normalized;
    if (RegExp(r'^\d+\.$').hasMatch(raw)) {
      raw = '${raw}0';
    }
    final p = double.tryParse(raw);
    if (p == null || p < 0 || !p.isFinite) {
      ToastService.showError(sheetContext, loc.posProductEditServicePriceInvalid);
      return;
    }
    if (p <= 0) {
      ToastService.showError(sheetContext, loc.posProductEditServicePriceInvalid);
      return;
    }
    final priceErr = product.validateEditableUnitPrice(p);
    if (priceErr == 'below_min') {
      ToastService.showError(
        sheetContext,
        'Price cannot be below SAR ${product.minEditablePriceVatInclusive.toStringAsFixed(2)} for this product.',
      );
      return;
    }
    final vm = context.read<PosViewModel>();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(sheetContext).pop();
    vm.applyLocalEditableServiceUnitPrice(
      product,
      p,
      isMainTab: widget.isMainTab,
    );
    if (!context.mounted) return;
    ToastService.showSuccess(context, loc.posProductEditServicePriceSuccess);
  }

  Future<void> _showEditableUnitPriceDialog(PosProduct product) async {
    if (widget.isReadOnly) return;
    if (!_canShowEditableUnitPriceDialog(product)) return;

    final vm = context.read<PosViewModel>();
    final controller = TextEditingController(
      text: _initialServicePriceFieldText(_displayUnitPriceForProduct(vm, product)),
    );

    await _showPosGridFormBottomSheet(
      context: context,
      title: Text(
        AppLocalizations.of(context)!.posProductEditServicePriceTitle,
        textAlign: TextAlign.center,
        style: AppTextStyles.h2.copyWith(fontSize: 20),
      ),
      fieldBuilder: (sheetContext, loc) => TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          EnglishNumberFormatter(),
          const DecimalQtyTextInputFormatter(maxFractionDigits: 2),
        ],
        decoration: _posGridFormDialogInputDecoration(
          sheetContext,
          loc.posProductEditServicePriceHint,
        ),
        onSubmitted: (_) => _applyInvoiceScopedUnitPrice(
          sheetContext,
          product,
          controller.text,
        ),
      ),
      cancelLabel: AppLocalizations.of(context)!.posOrdersCancelBtn,
      confirmLabel: AppLocalizations.of(context)!.posProductEditServicePriceSave,
      onCancel: (sheetContext) => Navigator.of(sheetContext).pop(),
      onConfirm: (sheetContext) => _applyInvoiceScopedUnitPrice(
        sheetContext,
        product,
        controller.text,
      ),
    );

    _disposePosGridFormControllerAfterSheet(controller);
  }

  void _onCategorySelected(PosViewModel vm, String cat) {
    vm.setCategory(cat);
    context.read<ProductGridViewModel>().setSubCategory('All');
  }

  List<String> _resolveDepartmentIdsForSave(PosViewModel vm) {
    final fromWidget = (widget.selectedDepartmentIds ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (fromWidget.isNotEmpty) return fromWidget;
    final single = widget.departmentId?.trim() ?? '';
    if (single.isNotEmpty && single != 'All') return [single];
    final seen = <String>{};
    for (final i in vm.cartItems) {
      final d = i.product.departmentId;
      if (d != null && d.isNotEmpty) seen.add(d);
    }
    if (seen.isNotEmpty) return seen.toList();
    if (_currentProducts.isNotEmpty) {
      final d = _currentProducts.first.departmentId;
      if (d != null && d.isNotEmpty) return [d];
    }
    if (vm.products.isNotEmpty) {
      final d = vm.products.first.departmentId;
      if (d != null && d.isNotEmpty) return [d];
    }
    return const ['1'];
  }

  Future<void> _saveInvoiceFromPanel(BuildContext context) async {
    final vm = context.read<PosViewModel>();
    if (vm.isLoading || vm.isInvoicePanelSaveBusy) return;
    if (widget.isMainTab || widget.isReadOnly) return;

    final deptIds = _resolveDepartmentIdsForSave(vm);
    final isEdit = vm.editingOrder != null &&
        vm.editingCompletingOrderId != null &&
        vm.editingCompletingOrderId!.trim().isNotEmpty;

    bool ok = false;
    if (isEdit) {
      ok = await vm.submitEditOrder(
        deptIds,
        context,
        forInvoicePanelSave: true,
      );
    } else {
      final keepDraftContext = vm.corporateAccountId != null &&
          (vm.walkInDraftOrderId?.trim().isNotEmpty ?? false);
      ok = await vm.submitWalkInOrder(
        deptIds,
        context,
        clearCustomerOnSuccess: !keepDraftContext,
        forInvoicePanelSave: true,
      );
      if (ok) {
        if (!context.mounted) return;
        await vm.refreshOrdersAfterPlacement();
      }
    }
    if (!context.mounted) return;
    if (ok && widget.embeddedInOrdersHubDialog) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final vm = context.watch<PosViewModel>();
    final catalogLoading =
        (vm.isLoading || vm.corporateCatalogLoading) &&
        !vm.isInvoicePanelSaveBusy;

    return WillPopScope(
      onWillPop: _confirmBackNavigation,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: PosTabletLayout.textScaler(context),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: widget.resizeForKeyboard,
          backgroundColor: const Color(0xFFF5F3F0),
          appBar: widget.embeddedInOrdersHubDialog
              ? null
              : PosScreenAppBar(
                  title: (widget.departmentName != null &&
                          widget.departmentName!.trim().isNotEmpty &&
                          widget.departmentName!.trim().toLowerCase() != 'all')
                      ? (_translatedDeptName ?? widget.departmentName!)
                      : AppLocalizations.of(context)!.posProductInventory,
                  showBackButton: widget.showBackButton,
                  showGlobalLeft: false,
                  showHamburger: !widget.showBackButton,
                  onBack: () async {
                    final canPop = await _confirmBackNavigation();
                    if (canPop && mounted) Navigator.pop(context);
                  },
                ),
          body: Stack(
            children: [
              Positioned.fill(
                child: wrapPosShellRailBody(
                  context,
                  isTablet
                      ? _buildTabletSplitLayout(vm)
                      : _buildProductSection(false),
                ),
              ),
              if (catalogLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: _ProductGridLoadingShimmer(isTablet: isTablet),
                  ),
                ),
            ],
          ),
          // ─── Bottom Bar (Cart Summary) ───
          bottomNavigationBar: (isTablet || vm.getCartCount(widget.isMainTab) == 0 || widget.isReadOnly)
              ? const SizedBox.shrink()
              : Container(
            padding: EdgeInsets.fromLTRB(isTablet ? 18 : 16, 12, isTablet ? 18 : 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cart count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: isTablet ? 20 : 17, color: const Color(0xFF1E2124)),
                      const SizedBox(width: 8),
                      Text(
                        '${context.watch<PosViewModel>().getCartCount(widget.isMainTab)} ${AppLocalizations.of(context)!.posProductItems}',
                        style: TextStyle(fontSize: isTablet ? 14 : 12, fontWeight: localeFontWeight(context, FontWeight.w700), color: const Color(0xFF1E2124)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                // Grand total
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.posProductGrandTotal, style: TextStyle(fontSize: isTablet ? 12 : 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text(
                        _posGridMoney(context, context.watch<PosViewModel>().getTotalAmountValue(widget.isMainTab)),
                        style: TextStyle(fontSize: isTablet ? 19 : 18, fontWeight: localeFontWeight(context, FontWeight.w800), color: const Color(0xFF1E2124)),
                      ),
                    ],
                  ),
                ),
                // View Invoice button
                SizedBox(
                  height: isTablet ? 48 : 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final isLandscape =
                          MediaQuery.of(context).orientation ==
                              Orientation.landscape;
                      // Landscape tablets use compact sheet typography so order list stays visible.
                      final useTabletSizing = isTablet && !isLandscape;
                      _showInvoiceBottomSheet(context, useTabletSizing);
                    },
                    icon: Icon(Icons.receipt_long_outlined, size: isTablet ? 20 : 18),
                    label: Text(AppLocalizations.of(context)!.posProductViewInvoice, style: TextStyle(fontWeight: localeFontWeight(context, FontWeight.w700), fontSize: isTablet ? 14 : 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC145),
                      foregroundColor: const Color(0xFF1E2124),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletSplitLayout(PosViewModel vm) {
    // Row intrinsic height ignores Expanded children; without an explicit height the
    // row stays short and the invoice column leaves empty space at the bottom.
    return LayoutBuilder(
      builder: (context, constraints) {
        final invoiceWidth = _tightCatalogChrome ? 340.0 : 360.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(0, 0, _tightCatalogChrome ? 8 : 14, 0),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: vm.allProducts.isEmpty
                ? _buildEmptyState(vm)
                : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildProductSection(true),
                ),
                SizedBox(width: _tightCatalogChrome ? 8 : 12),
                SizedBox(
                  width: invoiceWidth,
                  child: _buildLiveInvoicePanel(vm),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveInvoicePanel(PosViewModel vm) {
    final fullCart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
    final activeDeptId = _isDepartmentSelectionMode ? _activeDepartmentTabId : null;
    final promoContextDeptId = _resolvePromoContextDeptId();
    final activeCart = (activeDeptId == null)
        ? fullCart
        : fullCart
        .where((i) => (i.product.departmentId ?? '') == activeDeptId)
        .toList();

    final isInvoiceLevelPromo = vm.shouldShowPromoSummaryRows(
      widget.isMainTab,
      departmentId: promoContextDeptId,
    );
    // Invoice-level promo belongs on Order Summary only — department
    // totals stay pre-promo so they match the hub job card.
    const showPromoSummaryRows = false;
    final gross = vm.getDisplayGrossExclVat(
      widget.isMainTab,
      items: activeCart,
      departmentId: promoContextDeptId,
    );
    final itemDiscount = activeCart.fold<double>(0.0, (s, i) => s + i.actualDiscountAmount);
    final afterItemDiscount = (gross - itemDiscount).clamp(0, double.infinity).toDouble();
    final rawAfterItemExclVat = activeCart.fold<double>(
      0.0,
      (s, i) => s + i.totalPriceExclVat,
    );

    // Allocate order-level discounts proportionally so each department shows its own live invoice.
    final allAfterItemDiscount = fullCart.fold<double>(
      0.0,
          (s, i) => s + i.totalPriceExclVat,
    ).clamp(0, double.infinity).toDouble();
    final globalDiscountAll = vm.getTotalGlobalDiscountValue(widget.isMainTab);
    final globalRatio = allAfterItemDiscount <= 0 ? 0.0 : (afterItemDiscount / allAfterItemDiscount);
    final globalDiscount = (globalDiscountAll * globalRatio)
        .clamp(0, afterItemDiscount)
        .toDouble();
    final afterGlobal = (afterItemDiscount - globalDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    final afterGlobalAll = vm.getPriceAfterJobDiscount(widget.isMainTab);
    final promoDiscountAll = isInvoiceLevelPromo
        ? 0.0
        : vm.getTotalPromoDiscountValue(
            widget.isMainTab,
            departmentId: promoContextDeptId,
          );
    final promoRatio = afterGlobalAll <= 0 ? 0.0 : (afterGlobal / afterGlobalAll);
    final fallbackPromoDiscount = (promoDiscountAll * promoRatio)
        .clamp(0, afterGlobal)
        .toDouble();
    final promoDiscount = isInvoiceLevelPromo
        ? 0.0
        : (activeDeptId == null
            ? fallbackPromoDiscount
            : vm.getPromoDiscountForBase(
                afterGlobal,
                isMainTab: widget.isMainTab,
                departmentId: activeDeptId,
              ));
    // Rules 1/2: promo is already baked into [gross]; do not subtract twice.
    final taxable = showPromoSummaryRows
        ? (afterGlobal - promoDiscount).clamp(0, double.infinity).toDouble()
        : afterGlobal;
    final hasOrderLevelDiscount =
        globalDiscountAll > 0.0001 || promoDiscountAll > 0.0001;
    // Rules 1/2 bake the promo into [gross], so [promoDiscount] (derived from the
    // baked base) is ~0 here; recover the real promo amount from the pre-promo
    // base so VAT is charged on the final taxable, not the raw amount.
    final promoDiscountForVat = showPromoSummaryRows
        ? promoDiscount
        : ((rawAfterItemExclVat - globalDiscount)
                    .clamp(0, double.infinity)
                    .toDouble() -
                taxable)
            .clamp(0, double.infinity)
            .toDouble();
    final vat = hasOrderLevelDiscount
        ? vm.computeOrderLevelVat(
            isMainTab: widget.isMainTab,
            afterItemExclVat: rawAfterItemExclVat,
            globalDiscount: globalDiscount,
            promoDiscount: promoDiscountForVat,
            departmentId: activeDeptId,
          )
        : activeCart.fold<double>(0.0, (s, i) => s + i.lineVatAmount);
    final total = taxable + vat;

    final hub = _inOrdersHubDialog;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: w,
            maxWidth: w,
            minHeight: h.isFinite ? h : 0,
            maxHeight: h.isFinite ? h : double.infinity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(hub ? 12 : 14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hub ? 8 : 14,
                    hub ? 6 : 12,
                    hub ? 8 : 14,
                    hub ? 6 : 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.posProductOrderItems,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: localeFontWeight(context, FontWeight.w800),
                            fontSize: _inOrdersHubDialog ? 13 : null,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: hub ? 6 : 8,
                          vertical: hub ? 1 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(hub ? 6 : 8),
                        ),
                        child: Text(
                          '${activeCart.length}',
                          style: TextStyle(
                            fontSize: hub ? 10 : 11,
                            fontWeight: localeFontWeight(context, FontWeight.w700),
                            color: const Color(0xFF1E2124),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: hub ? 1 : 5,
                        child: activeCart.isEmpty
                            ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.posProductNoItemsInInvoice,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                            : ListView(
                          primary: false,
                          padding: EdgeInsets.fromLTRB(
                            hub ? 8 : 12,
                            hub ? 5 : 8,
                            hub ? 8 : 12,
                            hub ? 5 : 8,
                          ),
                          children: [
                            for (var i = 0; i < activeCart.length; i++) ...[
                              _buildCartItem(activeCart[i], false),
                              if (i != activeCart.length - 1)
                                SizedBox(height: hub ? 5 : 8),
                            ],
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      if (hub)
                        // Totals pinned at the bottom: not a flex child, so the
                        // items list above absorbs all leftover space. Height is
                        // capped for tiny screens (internal scroll as fallback).
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: h.isFinite ? h * 0.62 : double.infinity,
                          ),
                          child: SingleChildScrollView(
                            primary: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _buildInvoiceTotalsChildren(
                                  context: context,
                                  vm: vm,
                                  hub: hub,
                                  activeCart: activeCart,
                                  promoContextDeptId: promoContextDeptId,
                                  showPromoSummaryRows: showPromoSummaryRows,
                                  hideInvoiceLevelPromo: isInvoiceLevelPromo,
                                  gross: gross,
                                  itemDiscount: itemDiscount,
                                  afterItemDiscount: afterItemDiscount,
                                  globalDiscount: globalDiscount,
                                  afterGlobal: afterGlobal,
                                  promoDiscount: promoDiscount,
                                  taxable: taxable,
                                  vat: vat,
                                  total: total,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        // Totals pinned at the bottom with their natural height;
                        // the items list above absorbs leftover space. Capped for
                        // small screens (internal scroll as fallback).
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: h.isFinite ? h * 0.62 : double.infinity,
                          ),
                          child: SingleChildScrollView(
                            primary: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                10 + MediaQuery.viewPaddingOf(context).bottom,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _buildInvoiceTotalsChildren(
                                  context: context,
                                  vm: vm,
                                  hub: hub,
                                  activeCart: activeCart,
                                  promoContextDeptId: promoContextDeptId,
                                  showPromoSummaryRows: showPromoSummaryRows,
                                  hideInvoiceLevelPromo: isInvoiceLevelPromo,
                                  gross: gross,
                                  itemDiscount: itemDiscount,
                                  afterItemDiscount: afterItemDiscount,
                                  globalDiscount: globalDiscount,
                                  afterGlobal: afterGlobal,
                                  promoDiscount: promoDiscount,
                                  taxable: taxable,
                                  vat: vat,
                                  total: total,
                                ),
                              ),
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
  }

  List<Widget> _buildInvoiceTotalsChildren({
    required BuildContext context,
    required PosViewModel vm,
    required bool hub,
    required List<CartItem> activeCart,
    required String? promoContextDeptId,
    required bool showPromoSummaryRows,
    required bool hideInvoiceLevelPromo,
    required double gross,
    required double itemDiscount,
    required double afterItemDiscount,
    required double globalDiscount,
    required double afterGlobal,
    required double promoDiscount,
    required double taxable,
    required double vat,
    required double total,
  }) {
    return [
                                _buildTotalRow(
                                  AppLocalizations.of(context)!.posProductGrossExclVat,
                                  _posGridMoney(context, gross),
                                  false,
                                ),
                                const SizedBox(height: 6),
                                _buildTotalRow(
                                  AppLocalizations.of(context)!.posProductLineDiscount,
                                  _posGridMoney(context, itemDiscount, negative: true),
                                  false,
                                  color: itemDiscount > 0 ? Colors.green : Colors.grey.shade600,
                                ),
                                const SizedBox(height: 6),
                                _buildTotalRow(
                                  AppLocalizations.of(context)!.posProductPriceAfterLineDiscount,
                                  _posGridMoney(context, afterItemDiscount),
                                  false,
                                ),
                                const SizedBox(height: 8),
                                _buildInteractiveTotalDiscountRow(context, vm, false),
                                const SizedBox(height: 6),
                                if (globalDiscount > 0) ...[
                                  _buildTotalRow(
                                    AppLocalizations.of(context)!.posProductTotalDiscountApplied,
                                    _posGridMoney(context, globalDiscount, negative: true),
                                    false,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                _buildTotalRow(
                                  AppLocalizations.of(context)!.posProductPriceAfterTotalDiscount,
                                  _posGridMoney(
                                    context,
                                    showPromoSummaryRows ? afterGlobal : taxable,
                                  ),
                                  false,
                                ),
                                const SizedBox(height: 6),
                                if (!hideInvoiceLevelPromo) ...[
                                  _buildAppliedPromoBanner(
                                    vm: vm,
                                    promoContextDeptId: promoContextDeptId,
                                    isTablet: false,
                                    cartEmpty: activeCart.isEmpty,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 7),
                                ],
                                if (showPromoSummaryRows && promoDiscount > 0) ...[
                                  _buildTotalRow(
                                    AppLocalizations.of(context)!.posProductPromoDiscount,
                                    _posGridMoney(context, promoDiscount, negative: true),
                                    false,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (showPromoSummaryRows)
                                  _buildTotalRow(
                                    AppLocalizations.of(context)!.posProductPriceAfterPromo,
                                    _posGridMoney(context, taxable),
                                    false,
                                  ),
                                const SizedBox(height: 6),
                                _buildTotalRow(
                                  AppLocalizations.of(context)!.posProductVat15,
                                  _posGridMoney(context, vat),
                                  false,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.posProductTotal,
                                      style: TextStyle(fontWeight: localeFontWeight(context, FontWeight.w800), fontSize: 14),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _posGridMoney(context, total),
                                      style: TextStyle(
                                        fontWeight: localeFontWeight(context, FontWeight.w800),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!widget.isReadOnly && !widget.isMainTab) ...[
                                  SizedBox(height: hub ? 8 : 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: hub ? 36 : 40,
                                    child: Consumer<PosViewModel>(
                                      builder: (context, vm, _) {
                                        final saving = vm.isInvoicePanelSaveBusy;
                                        return ElevatedButton(
                                          onPressed: saving ? null : () => _saveInvoiceFromPanel(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.secondaryLight,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: AppColors.secondaryLight,
                                            disabledForegroundColor: Colors.white,
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(hub ? 10 : 12),
                                            ),
                                          ),
                                          child: saving
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                            AppLocalizations.of(context)!.posProductSave,
                                            style: TextStyle(
                                              fontWeight: localeFontWeight(context, FontWeight.w800),
                                              fontSize: hub ? 12 : 13,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
      SizedBox(height: hub ? 2 : 10),
    ];
  }

  // ── Invoice Bottom Sheet ──
  void _showInvoiceBottomSheet(BuildContext context, bool isTablet) {
    bool isSavingDraft = false;
    bool isForwarding = false;
    final actualIsTablet = MediaQuery.of(context).size.width > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: actualIsTablet ? 16 : 14,
                  vertical: actualIsTablet ? 12 : 24,
                ),
                backgroundColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height *
                        (actualIsTablet ? 0.90 : 0.80),
                    width: actualIsTablet
                        ? (MediaQuery.of(ctx).size.width - 32)
                        : (MediaQuery.of(ctx).size.width - 28),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBF9F6),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          MediaQuery.of(context).orientation == Orientation.landscape
                              ? 1.12
                              : 1.14,
                        ),
                      ),
                      child: Column(
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
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 12),
                            child: Row(
                              children: [
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                  iconSize: isTablet ? 24 : 20,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Customer & Vehicle Card ──
                          Builder(
                              builder: (context) {
                                final vm = context.read<PosViewModel>();
                                String orderIdText = '#NEW-ORDER';
                                if (widget.completingOrder?.id != null && widget.completingOrder!.id.isNotEmpty) {
                                  orderIdText = '#${widget.completingOrder!.id.length > 8 ? widget.completingOrder!.id.substring(0, 8) : widget.completingOrder!.id}';
                                }

                                String custName = vm.customerName.isNotEmpty
                                    ? vm.customerName
                                    : (widget.completingOrder?.customerName ?? '');
                                if (custName.isEmpty) custName = AppLocalizations.of(context)!.posProductWalkInCustomer;

                                String make = vm.make.isNotEmpty
                                    ? vm.make
                                    : (widget.completingOrder?.vehicle?.make ?? '');
                                String model = vm.model.isNotEmpty
                                    ? vm.model
                                    : (widget.completingOrder?.vehicle?.model ?? '');
                                String plate = vm.vehicleNumber.isNotEmpty
                                    ? vm.vehicleNumber
                                    : (widget.completingOrder?.plateNumber ?? '');
                                String vehicleText = [make, model].where((s) => s.isNotEmpty).join(' ');
                                if (plate.isNotEmpty) {
                                  vehicleText = vehicleText.isNotEmpty ? '$vehicleText • $plate' : plate;
                                }
                                if (vehicleText.trim().isEmpty || vehicleText == '•') vehicleText = AppLocalizations.of(context)!.posProductNoVehicleDetails;

                                String phoneText = vm.mobile.isNotEmpty
                                    ? vm.mobile
                                    : (widget.completingOrder?.customer?.mobile ?? '');
                                if (phoneText.isEmpty) phoneText = AppLocalizations.of(context)!.posProductNoPhone;

                                String statusText = widget.completingOrder?.statusText ?? AppLocalizations.of(context)!.posProductDraft;
                                Color statusColor = widget.completingOrder?.statusColor ?? Colors.blue;

                                return Container(
                                  margin: EdgeInsets.fromLTRB(isTablet ? 32 : 14, 6, isTablet ? 32 : 14, 0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 14, vertical: isTablet ? 14 : 12),
                                    child: Column(
                                      children: [
                                        // ID + Name + Status
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F4F6),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                orderIdText,
                                                style: TextStyle(fontSize: isLandscape ? (isTablet ? 18 : 12) : (isTablet ? 16 : 10), fontWeight: localeFontWeight(context, FontWeight.w800), color: const Color(0xFF1E2124)),
                                              ),
                                            ),
                                            SizedBox(width: isTablet ? 8 : 6),
                                            Expanded(
                                              child: Text(
                                                custName,
                                                style: TextStyle(fontSize: isLandscape ? (isTablet ? 24 : 15) : (isTablet ? 22 : 13), fontWeight: localeFontWeight(context, FontWeight.w700), color: const Color(0xFF1E2124)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: isLandscape ? (isTablet ? 18 : 12) : (isTablet ? 17 : 11), fontWeight: localeFontWeight(context, FontWeight.w700))),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isTablet ? 12 : 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.directions_car_outlined, size: 22, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(vehicleText,
                                                  style: TextStyle(color: Colors.grey, fontSize: isTablet ? 17 : 10, fontWeight: FontWeight.w500),
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.phone_outlined, size: 22, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(phoneText, style: TextStyle(color: Colors.grey, fontSize: isTablet ? 19 : 12, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                          ),

                          // ── Order Items Header ──
                          Padding(
                            padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, isTablet ? 10 : 10, isTablet ? 24 : 16, isTablet ? 6 : 8),
                            child: Row(
                              children: [
                                Text(AppLocalizations.of(context)!.posProductOrderItems, style: TextStyle(fontWeight: localeFontWeight(context, FontWeight.bold), fontSize: isTablet ? 20 : 14, color: const Color(0xFF1E2124))),
                                const Spacer(),
                                Consumer<PosViewModel>(
                                  builder: (context, vm, _) {
                                    final c = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
                                    if (c.isEmpty) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                                      child: Text(
                                        '${c.length}',
                                        style: TextStyle(fontSize: isTablet ? 16 : 11, fontWeight: localeFontWeight(context, FontWeight.w700), color: const Color(0xFF1E2124)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // ── Cart Items ──
                          Expanded(
                            child: Consumer<PosViewModel>(
                              builder: (context, vm, child) {
                                final activeCart = widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
                                final isLandscape =
                                    MediaQuery.of(context).orientation ==
                                        Orientation.landscape;
                                final cartTwoCols =
                                    MediaQuery.sizeOf(context).width > 600 ||
                                        isLandscape;

                                return activeCart.isEmpty
                                    ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text(AppLocalizations.of(context)!.posProductNoItemsAdded, style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
                                    ],
                                  ),
                                )
                                    : (!isTablet && !isLandscape)
                                    ? ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                                  itemCount: activeCart.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return _buildCartItem(activeCart[index], isTablet);
                                  },
                                )
                                    : cartTwoCols
                                    ? LayoutBuilder(
                                  builder: (context, constraints) {
                                    final hPad = isTablet ? 16.0 : 12.0;
                                    final gap = isTablet ? 5.0 : 8.0;
                                    final contentW =
                                        constraints.maxWidth - 2 * hPad;
                                    final cellW = (contentW - gap) / 2;
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.fromLTRB(
                                        hPad,
                                        isTablet ? 0 : 2,
                                        hPad,
                                        isTablet ? 4 : 8,
                                      ),
                                      child: Wrap(
                                        spacing: gap,
                                        runSpacing: gap,
                                        children: [
                                          for (final item in activeCart)
                                            SizedBox(
                                              width: cellW,
                                              child: _buildCartItem(
                                                item,
                                                isTablet,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                                    : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    2,
                                    12,
                                    8,
                                  ),
                                  itemCount: activeCart.length,
                                  separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return _buildCartItem(
                                      activeCart[index],
                                      isTablet,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          // ── Totals ──
                          Consumer<PosViewModel>(
                              builder: (context, vm, child) {
                                final sheetActiveDeptId = _isDepartmentSelectionMode
                                    ? _activeDepartmentTabId
                                    : null;
                                final sheetPromoContextDeptId = sheetActiveDeptId ??
                                    (widget.departmentId != null &&
                                        widget.departmentId!.trim().isNotEmpty &&
                                        widget.departmentId != 'All'
                                        ? widget.departmentId!.trim()
                                        : null);
                                final isInvoiceLevelPromo = vm.shouldShowPromoSummaryRows(
                                  widget.isMainTab,
                                  departmentId: sheetPromoContextDeptId,
                                );
                                const showPromoSummaryRows = false;
                                final sheetAfterJob = vm.getPriceAfterJobDiscount(
                                  widget.isMainTab,
                                );
                                final sheetVat = isInvoiceLevelPromo
                                    ? vm.computeOrderLevelVat(
                                        isMainTab: widget.isMainTab,
                                        afterItemExclVat: vm
                                            .getPriceAfterItemDiscounts(
                                          widget.isMainTab,
                                        ),
                                        globalDiscount: vm
                                            .getTotalGlobalDiscountValue(
                                          widget.isMainTab,
                                        ),
                                        promoDiscount: 0,
                                        departmentId: sheetPromoContextDeptId,
                                      )
                                    : vm.getTotalTaxValue(widget.isMainTab);
                                final sheetTotal = isInvoiceLevelPromo
                                    ? sheetAfterJob + sheetVat
                                    : vm.getTotalAmountValue(widget.isMainTab);
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 14),
                                  padding: EdgeInsets.all(isTablet ? 24 : 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildTotalRow(
                                        AppLocalizations.of(context)!.posProductGrossExclVat,
                                        _posGridMoney(
                                          context,
                                          vm.getDisplayGrossExclVat(
                                            widget.isMainTab,
                                            departmentId: sheetPromoContextDeptId,
                                          ),
                                        ),
                                        isTablet,
                                      ),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      _buildTotalRow(
                                        AppLocalizations.of(context)!.posProductLineDiscount,
                                        _posGridMoney(context, vm.getTotalIndividualDiscount(widget.isMainTab), negative: true),
                                        isTablet,
                                        color: vm.getTotalIndividualDiscount(widget.isMainTab) > 0
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      _buildTotalRow(
                                        AppLocalizations.of(context)!.posProductPriceAfterLineDiscount,
                                        _posGridMoney(context, vm.getPriceAfterItemDiscounts(widget.isMainTab)),
                                        isTablet,
                                      ),
                                      SizedBox(height: isTablet ? 10 : 8),
                                      _buildInteractiveTotalDiscountRow(context, vm, isTablet),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      if (vm.getTotalGlobalDiscountValue(widget.isMainTab) > 0) ...[
                                        _buildTotalRow(
                                          AppLocalizations.of(context)!.posProductTotalDiscountApplied,
                                          _posGridMoney(context, vm.getTotalGlobalDiscountValue(widget.isMainTab), negative: true),
                                          isTablet,
                                          color: Colors.green,
                                        ),
                                        SizedBox(height: isTablet ? 8 : 6),
                                      ],
                                      _buildTotalRow(
                                        AppLocalizations.of(context)!.posProductPriceAfterTotalDiscount,
                                        _posGridMoney(
                                          context,
                                          sheetAfterJob,
                                        ),
                                        isTablet,
                                      ),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      if (!isInvoiceLevelPromo) ...[
                                        _buildAppliedPromoBanner(
                                          vm: vm,
                                          promoContextDeptId: sheetPromoContextDeptId,
                                          isTablet: isTablet,
                                          cartEmpty: false,
                                          isLandscape: isLandscape,
                                        ),
                                        SizedBox(height: isTablet ? 10 : 8),
                                        if (showPromoSummaryRows &&
                                            vm.getTotalPromoDiscountValue(
                                              widget.isMainTab,
                                              departmentId: sheetPromoContextDeptId,
                                            ) >
                                                0) ...[
                                          _buildTotalRow(
                                            AppLocalizations.of(context)!.posProductPromoDiscount,
                                            _posGridMoney(
                                              context,
                                              vm.getTotalPromoDiscountValue(
                                                widget.isMainTab,
                                                departmentId: sheetPromoContextDeptId,
                                              ),
                                              negative: true,
                                            ),
                                            isTablet,
                                            color: Colors.green,
                                          ),
                                          SizedBox(height: isTablet ? 8 : 6),
                                        ],
                                        if (showPromoSummaryRows)
                                          _buildTotalRow(
                                            AppLocalizations.of(context)!.posProductPriceAfterPromo,
                                            _posGridMoney(context, vm.getTotalTaxableAmountValue(widget.isMainTab)),
                                            isTablet,
                                          ),
                                      ],
                                      Divider(height: 1, color: Colors.grey.shade200),
                                      SizedBox(height: isTablet ? 10 : 8),
                                      _buildTotalRow(
                                        AppLocalizations.of(context)!.posProductVat15,
                                        _posGridMoney(context, sheetVat),
                                        isTablet,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: isTablet ? 10 : 8),
                                      Row(
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!.posProductTotalAmount,
                                            style: TextStyle(
                                              fontWeight: localeFontWeight(context, FontWeight.w800),
                                              fontSize: isLandscape
                                                  ? (isTablet ? 27 : 17)
                                                  : (isTablet ? 24 : 14),
                                              color: const Color(0xFF1E2124),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _posGridMoney(context, sheetTotal),
                                            style: TextStyle(
                                              fontWeight: localeFontWeight(context, FontWeight.w800),
                                              fontSize: isLandscape
                                                  ? (isTablet ? 27 : 17)
                                                  : (isTablet ? 24 : 14),
                                              color: const Color(0xFF1E2124),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                          ),

                          SizedBox(height: isTablet ? 10 : 8),

                          // ── Action Buttons ──
                          Padding(
                            padding: EdgeInsets.fromLTRB(isTablet ? 32 : 14, 0, isTablet ? 32 : 14, MediaQuery.of(context).padding.bottom + 20),
                            child: (widget.completingOrderId != null &&
                                !(widget.completingOrder?.statusText
                                    .toLowerCase()
                                    .contains(AppLocalizations.of(context)!.posProductPendingAssignment) ??
                                    false))
                                ? SizedBox(
                              width: double.infinity,
                              height: isTablet ? 60 : 48,
                              child: Consumer<PosViewModel>(
                                builder: (context, vm, child) {
                                  var jobId = widget.completingOrderId!;
                                  if (widget.completingOrder != null &&
                                      widget.completingOrder!.jobs.isNotEmpty) {
                                    jobId = widget.completingOrder!.latestJob!.id;
                                  }
                                  final completing = vm.isCashierCompletingJob(jobId);
                                  return ElevatedButton(
                                    onPressed: completing
                                        ? null
                                        : () async {
                                      final response = await vm.completeCashierJob(
                                        jobId,
                                        isMainTab: widget.isMainTab,
                                      );
                                      if (response != null && response.success && context.mounted) {
                                        if (widget.embeddedInOrdersHubDialog) {
                                          Navigator.of(context).pop();
                                        } else {
                                          navigateToPosShellOrdersTab(context);
                                        }
                                        ToastService.showSuccess(context, AppLocalizations.of(context)!.posProductOrderCompletedSuccess);
                                      } else {
                                        if (context.mounted) {
                                          ToastService.showError(context, response?.message ?? AppLocalizations.of(context)!.posProductFailedCompleteJob);
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryLight,
                                      foregroundColor: const Color(0xFF1E2124),
                                      disabledBackgroundColor: AppColors.primaryLight,
                                      disabledForegroundColor: const Color(0xFF1E2124),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: completing
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E2124)),
                                            ),
                                          )
                                        : Text(
                                      AppLocalizations.of(context)!.posProductMarkComplete,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: isTablet ? 18 : 15),
                                    ),
                                  );
                                },
                              ),
                            )
                                : Column(
                              children: [
                                if (!widget.isMainTab)
                                  Row(
                                    children: [
                                      if (widget.completingOrderId == null) ...[
                                        Expanded(
                                          child: SizedBox(
                                            height: isLandscape
                                                ? (isTablet ? 64 : 50)
                                                : (isTablet ? 60 : 44),
                                            child: Consumer<PosViewModel>(
                                              builder: (context, vm, child) {
                                                return ElevatedButton(
                                                  onPressed: vm.isLoading || isForwarding || isSavingDraft
                                                      ? null
                                                      : () async {
                                                    setSheetState(() => isSavingDraft = true);
                                                    String finalDeptId = '1';
                                                    if (widget.departmentId != null) {
                                                      finalDeptId = widget.departmentId!;
                                                    } else {
                                                      if (_currentProducts.isNotEmpty) {
                                                        finalDeptId = _currentProducts.first.departmentId ?? '1';
                                                      } else if (vm.products.isNotEmpty) {
                                                        finalDeptId = vm.products.first.departmentId ?? '1';
                                                      }
                                                    }
                                                    final keepDraftContext = vm.corporateAccountId != null &&
                                                        (vm.walkInDraftOrderId?.trim().isNotEmpty ?? false);
                                                    final success = await vm.submitWalkInOrder(
                                                      [finalDeptId],
                                                      context,
                                                      clearCustomerOnSuccess: !keepDraftContext,
                                                      forInvoicePanelSave: true,
                                                    );
                                                    if (success && context.mounted) {
                                                      await vm.refreshOrdersAfterPlacement();
                                                      if (widget.embeddedInOrdersHubDialog) {
                                                        Navigator.of(context).pop();
                                                      } else {
                                                        navigateToPosShellOrdersTab(context);
                                                      }
                                                    }
                                                    if (mounted) {
                                                      setSheetState(() => isSavingDraft = false);
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.secondaryLight,
                                                    foregroundColor: Colors.white,
                                                    disabledBackgroundColor: AppColors.secondaryLight,
                                                    disabledForegroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  child: isSavingDraft
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                          ),
                                                        )
                                                      : Text(
                                                    AppLocalizations.of(context)!.posProductSaveDraft,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: isLandscape
                                                          ? (isTablet ? 18 : 13)
                                                          : (isTablet ? 16 : 11),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                      ],
                                      Expanded(
                                        child: SizedBox(
                                          height: isLandscape
                                              ? (isTablet ? 64 : 50)
                                              : (isTablet ? 60 : 44),
                                          child: Consumer<PosViewModel>(
                                            builder: (context, vm, child) {
                                              return ElevatedButton(
                                                onPressed: vm.isLoading || isSavingDraft
                                                    ? null
                                                    : () {
                                                  String finalDeptId = '1'; // Default fallback
                                                  if (widget.departmentId != null) {
                                                    finalDeptId = widget.departmentId!;
                                                  } else {
                                                    if (_currentProducts.isNotEmpty) {
                                                      finalDeptId = _currentProducts.first.departmentId ?? '1';
                                                    } else if (vm.products.isNotEmpty) {
                                                      finalDeptId = vm.products.first.departmentId ?? '1';
                                                    }
                                                  }
                                                  // Navigate directly — walk-in API called on "Assign to Technician"
                                                  Navigator.of(ctx).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => PosTechnicianAssignmentView(
                                                        jobId: '',
                                                        departmentName: widget.departmentName,
                                                        departmentId: finalDeptId,
                                                        isWalkIn: true,
                                                        initialAssignedTechnicians:
                                                        _initialAssignedForWalkInTechnicianScreen(),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFFFC145),
                                                  foregroundColor: const Color(0xFF1E2124),
                                                  disabledBackgroundColor: const Color(0xFFFFC145),
                                                  disabledForegroundColor: const Color(0xFF1E2124),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: isForwarding
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E2124)),
                                                        ),
                                                      )
                                                    : Text(
                                                  AppLocalizations.of(context)!.posProductForwardTechnician,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: isLandscape
                                                        ? (isTablet ? 18 : 13)
                                                        : (isTablet ? 16 : 11),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ));
          },
        );
      },
    );
  }

  // ── Product Section (shared by tablet & mobile) ──

  /// Fixed strip: search + tabs + chips. Only the grid/list below scrolls.
  Widget _buildProductCatalogHeader({
    required bool isTablet,
    required PosViewModel vm,
    required ProductGridViewModel gridVm,
  }) {
    if (vm.allProducts.isEmpty) return const SizedBox.shrink();
    final hub = _inOrdersHubDialog;
    final tight = _tightCatalogChrome;
    final isSearchActive = gridVm.searchQuery.trim().isNotEmpty;
    // Orders Hub popup: while searching, show catalog grid directly under search.
    final hideTabsForSearch = hub && isSearchActive;
    final hPad = isTablet ? (hub ? 14.0 : (tight ? 18.0 : 22.0)) : 12.0;
    final topPad = isTablet ? (hub ? 10.0 : (tight ? 12.0 : 16.0)) : 12.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PosWorkshopSearchBar(
                  controller: gridVm.searchController,
                  onChanged: (v) {
                    gridVm.setSearchQuery(v);
                    // While searching, show both products and services in this department.
                    if (v.trim().isNotEmpty) {
                      vm.setProductType('All');
                    }
                  },
                  hintText: AppLocalizations.of(context)!.posProductSearchHint,
                ),
              ),
              if (!widget.isMainTab) ...[
                SizedBox(width: isTablet ? (hub ? 8 : 12) : 8),
                _buildAddTechnicianButton(isTablet),
              ],
            ],
          ),
        ),
        if (_isDepartmentSelectionMode && !hideTabsForSearch)
          _buildDepartmentTabs(isTablet, vm, gridVm),
        if (!hideTabsForSearch) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              isTablet ? (hub ? 8 : (tight ? 10 : 14)) : 16,
              hPad,
              isTablet ? (hub ? 4 : (tight ? 5 : 6)) : 8,
            ),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                final scoped = _departmentScopedCatalog(vm, gridVm);
                return PosSegmentedListTabs(
                  layout: PosSegmentedTabLayout.expanded,
                  containerColor: Colors.white,
                  unselectedTabColor: Colors.white,
                  tabs: [
                    PosSegmentedTab(
                      id: 'All',
                      label: l10n.posCommonAll,
                      count: scoped.length,
                    ),
                    PosSegmentedTab(
                      id: 'Products',
                      label: l10n.posProductProductsTitle,
                      count: scoped.where((p) => !p.isServiceType).length,
                    ),
                    PosSegmentedTab(
                      id: 'Services',
                      label: l10n.posProductServicesTitle,
                      count: scoped.where((p) => p.isServiceType).length,
                    ),
                  ],
                  selectedId: vm.selectedProductType,
                  onSelected: (id) {
                    vm.setProductType(id);
                    gridVm.setCategory('All');
                  },
                );
              },
            ),
          ),
          _buildSubCategoryChips(isTablet, vm, gridVm),
        ],
        SizedBox(
          height: hideTabsForSearch
              ? (isTablet ? 4 : 6)
              : (isTablet ? (hub ? 6 : (tight ? 8 : 10)) : 8),
        ),
      ],
    );
  }

  Widget _buildProductSection(bool isTablet) {
    final gridVm = context.watch<ProductGridViewModel>();
    final vm = Provider.of<PosViewModel>(context);
    final selectedDeptIds = _selectedDepartmentIds;
    final allowedDeptSet = selectedDeptIds.toSet();
    final allowedDeptNames = (widget.selectedDepartmentNames ?? [])
        .map((n) => n.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    final hasDeptRestriction = allowedDeptSet.isNotEmpty;
    if (_isDepartmentSelectionMode && selectedDeptIds.isEmpty) {
      return _buildNoDepartmentState(isTablet);
    }

    final scopedCorpCatalog = vm.isCorporateCatalogDepartmentScoped;

    bool matchesDepartmentScope(PosProduct product) {
      if (scopedCorpCatalog) {
        // Catalog already loaded for this job department in corporate flow.
        return true;
      }
      final productDeptIdNorm = (product.departmentId ?? '').trim();
      final productDeptNameNorm =
          (product.departmentName ?? '').trim().toLowerCase();
      if (hasDeptRestriction && !allowedDeptSet.contains(productDeptIdNorm)) {
        if (vm.shouldUseCorporateQuotedCatalog &&
            productDeptIdNorm.isEmpty &&
            allowedDeptNames.contains(productDeptNameNorm)) {
          // Corporate catalog lines may omit departmentId — match by name.
        } else if (vm.shouldUseCorporateQuotedCatalog &&
            allowedDeptNames.isNotEmpty &&
            allowedDeptNames.contains(productDeptNameNorm)) {
          // Id mismatch between order job and quotation line — still show by name.
        } else if (vm.shouldUseCorporateQuotedCatalog &&
            allowedDeptNames.isNotEmpty) {
          for (final allowed in allowedDeptNames) {
            if (productDeptNameNorm.contains(allowed) ||
                allowed.contains(productDeptNameNorm)) {
              return true;
            }
          }
          return false;
        } else {
          return false;
        }
      }
      if (_isDepartmentSelectionMode) {
        if (_activeDepartmentTabId == null) return true;
        if (productDeptIdNorm == _activeDepartmentTabId!.trim()) return true;
        if (vm.shouldUseCorporateQuotedCatalog) {
          if (productDeptIdNorm.isEmpty &&
              allowedDeptNames.contains(productDeptNameNorm)) {
            return true;
          }
          if (allowedDeptNames.contains(productDeptNameNorm)) return true;
          for (final allowed in allowedDeptNames) {
            if (productDeptNameNorm.contains(allowed) ||
                allowed.contains(productDeptNameNorm)) {
              return true;
            }
          }
        }
        return false;
      }
      final wid = widget.departmentId?.trim() ?? '';
      if (wid.isNotEmpty && wid.toLowerCase() != 'all') {
        if (productDeptIdNorm == wid) return true;
        if (vm.shouldUseCorporateQuotedCatalog) {
          final tabName = (widget.departmentName ?? '').trim().toLowerCase();
          if (tabName.isNotEmpty &&
              (productDeptNameNorm == tabName ||
                  productDeptNameNorm.contains(tabName) ||
                  tabName.contains(productDeptNameNorm))) {
            return true;
          }
        }
        return false;
      }
      if (hasDeptRestriction) return true;
      final selectedDept = gridVm.selectedDepartment.trim().toLowerCase();
      final productDept = (product.departmentName ?? '').trim().toLowerCase();
      return selectedDept == 'all' || productDept == selectedDept;
    }

    List<PosProduct> filterCatalogList(
      List<PosProduct> source, {
      bool skipDept = false,
    }) {
      return source.where((product) {
        final qRaw = gridVm.searchQuery.trim();
        if (qRaw.isEmpty && vm.selectedProductType != 'All') {
          final isService = vm.selectedProductType == 'Services';
          if (product.isServiceType != isService) return false;
        }
        final qLower = qRaw.toLowerCase();
        final matchesCategory = qRaw.isNotEmpty
            ? true
            : (gridVm.selectedCategory == 'All' ||
                product.category == gridVm.selectedCategory);
        final matchesSearch = _posProductMatchesCatalogSearch(product, qLower);
        final matchesDept =
            skipDept || matchesDepartmentScope(product);
        return matchesDept && matchesCategory && matchesSearch;
      }).toList();
    }

    var filteredProducts = filterCatalogList(vm.allProducts);
    if (filteredProducts.isEmpty &&
        vm.allProducts.isNotEmpty &&
        vm.shouldUseCorporateQuotedCatalog) {
      filteredProducts = filterCatalogList(vm.allProducts, skipDept: true);
    }

    filteredProducts.sort((a, b) {
      final deptA = a.departmentName ?? 'ZZZ';
      final deptB = b.departmentName ?? 'ZZZ';
      if (deptA != deptB) return deptA.compareTo(deptB);
      return a.name.compareTo(b.name);
    });

    if (vm.allProducts.isEmpty) {
      return _buildEmptyState(vm);
    }

    final visibleProducts = filteredProducts
        .take(gridVm.visibleProductLimit)
        .toList(growable: false);
    final langCode = Localizations.localeOf(context).languageCode;
    if (langCode == 'ar') {
      LocalizedApiText.precache(
        visibleProducts
            .where((p) => _cleanProductArabicName(p.productNameArabic) == null)
            .map((p) => p.name),
        langCode,
      );
    }
    final hasLocalMore = visibleProducts.length < filteredProducts.length;

    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;

    final header = _buildProductCatalogHeader(
      isTablet: isTablet,
      vm: vm,
      gridVm: gridVm,
    );

    Future<void> refreshProducts() async {
      gridVm.resetVisibleProducts(notify: false);
      final deptId = _activeDepartmentTabId ??
          ((widget.departmentId != null && widget.departmentId != 'All')
              ? widget.departmentId
              : null);
      final vm = context.read<PosViewModel>();
      final order = widget.completingOrder;
      final isCorpOrder = order != null &&
          (order.isCorporateWalkIn || order.isCorporateBookingOrder);
      if (isCorpOrder && order != null && deptId != null && deptId.trim().isNotEmpty) {
        await vm.prepareCorporateJobProductCatalog(
          order: order,
          departmentId: deptId.trim(),
          departmentName: widget.departmentName,
          corporateBookingId: order.corporateOrderId,
          forceRefresh: true,
        );
      } else {
        await vm.fetchProducts(
          departmentId: deptId,
          departmentName: widget.departmentName,
          forceRefresh: isCorpOrder || vm.shouldUseCorporateQuotedCatalog,
        );
      }
    }

    Widget productCardFor(PosProduct product, bool tabletCard) {
      return Consumer<PosViewModel>(
        builder: (context, vm, child) {
          final activeCart =
              widget.isMainTab ? vm.mainTabCartItems : vm.cartItems;
          final cartItemIndex = activeCart.indexWhere(
            (i) =>
                i.product.id == product.id &&
                i.product.isServiceType == product.isServiceType &&
                (i.product.departmentId ?? '') ==
                    (product.departmentId ?? ''),
          );
          final qty = cartItemIndex != -1
              ? activeCart[cartItemIndex].quantity
              : 0.0;
          return _buildProductCard(product, qty, tabletCard);
        },
      );
    }

    final Widget listPane;
    if (filteredProducts.isEmpty) {
      listPane = ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Text(
            AppLocalizations.of(context)!.posProductNoProductsMatch,
            textAlign: TextAlign.center,
            style: _posCatalogEmptyMessageTextStyle(context),
          ),
        ],
      );
    } else if (isTablet) {
      final hub = _inOrdersHubDialog;
      final tight = _tightCatalogChrome;
      listPane = GridView.builder(
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.fromLTRB(
          hub ? 12 : (tight ? 18 : 22),
          6,
          hub ? 12 : (tight ? 18 : 22),
          hub ? 72 : (tight ? 88 : 100),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isPortrait ? 2 : (hub ? 4 : 3),
          mainAxisExtent: hub ? 134 : (tight ? 146 : 158),
          crossAxisSpacing: hub ? 10 : (tight ? 10 : 12),
          mainAxisSpacing: hub ? 10 : (tight ? 10 : 12),
        ),
        itemCount: visibleProducts.length + (hasLocalMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= visibleProducts.length) {
            return _LoadMoreProductsTile(
              isTablet: true,
              remainingCount: filteredProducts.length - visibleProducts.length,
              onPressed: gridVm.loadMoreProducts,
            );
          }
          return productCardFor(visibleProducts[index], true);
        },
      );
    } else {
      listPane = ListView.separated(
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: visibleProducts.length + (hasLocalMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index >= visibleProducts.length) {
            return _LoadMoreProductsTile(
              isTablet: false,
              remainingCount: filteredProducts.length - visibleProducts.length,
              onPressed: gridVm.loadMoreProducts,
            );
          }
          return productCardFor(visibleProducts[index], false);
        },
      );
    }

    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryLight,
              onRefresh: refreshProducts,
              child: listPane,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryChips(bool isTablet, PosViewModel vm, ProductGridViewModel gridVm) {
    final hub = _inOrdersHubDialog;
    final tight = _tightCatalogChrome;
    return Consumer<PosViewModel>(
      builder: (context, vm, child) {
        final sourceProducts = _catalogSourceForCategoryTabs(vm, gridVm);

        Set<String> subCatsSet = {};
        for (var p in sourceProducts) {
          final catName = p.category;
          if (catName.isNotEmpty) subCatsSet.add(catName);
        }

        final subCats = subCatsSet.toList();
        subCats.sort();
        if (subCats.isEmpty && sourceProducts.isEmpty) return const SizedBox.shrink();

        final displaySubCats = ['All', ...subCats];
        final l10n = AppLocalizations.of(context)!;
        return PosSegmentedListTabs(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? (hub ? 12 : (tight ? 18 : 22)) : 12,
            vertical: hub ? 4 : (tight ? 5 : 6),
          ),
          containerColor: Colors.white,
          unselectedTabColor: Colors.white,
          selectedTabColor: AppColors.secondaryLight,
          selectedLabelColor: AppColors.onSecondaryLight,
          tabs: [
            for (final subCat in displaySubCats)
              PosSegmentedTab(
                id: subCat,
                label: subCat == 'All' ? l10n.posCommonAll : subCat,
                count: subCat == 'All'
                    ? sourceProducts.length
                    : sourceProducts
                        .where((p) => p.category == subCat)
                        .length,
              ),
          ],
          selectedId: gridVm.selectedCategory,
          onSelected: gridVm.setCategory,
        );
      },
    );
  }

  Widget _buildDepartmentTabs(
      bool isTablet,
      PosViewModel vm,
      ProductGridViewModel gridVm,
      ) {
    return const SizedBox.shrink();
  }

  Widget _buildNoDepartmentState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.posProductDepartmentNotFound,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: localeFontWeight(context, FontWeight.w700),
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: isTablet ? 48 : 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PosDepartmentView()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.posProductAddDepartment),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PosViewModel vm) {
    return ColoredBox(
      color: const Color(0xFFFBFBFD),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              vm.allProducts.isEmpty
                  ? (vm.shouldUseCorporateQuotedCatalog
                      ? 'No products loaded. Tap Sync data to download the branch catalog — corporate quoted prices apply from the order when available.'
                      : AppLocalizations.of(context)!.posCatalogSyncEmptyHint)
                  : (vm.selectedProductType == 'Services'
                      ? AppLocalizations.of(context)!.posProductNoServicesFound
                      : AppLocalizations.of(context)!
                          .posProductNoProductsFound),
              textAlign: TextAlign.center,
              style: _posCatalogEmptyMessageTextStyle(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    PosProduct product,
    double cartQty,
    bool isTablet,
  ) {
    final outOfStock = product.isOutOfStockForPos;
    if (!isTablet) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isReadOnly
              ? null
              : (product.isServiceQtyLocked ||
                      _canIncrementProduct(product, cartQty))
                  ? () => _onCatalogCardTap(product, cartQty)
                  : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: (cartQty > 0 && !widget.isReadOnly)
                  ? Border.all(color: AppColors.primaryLight, width: 2)
                  : Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: cartQty > 0 && !widget.isReadOnly ? 44 : 0,
                                    ),
                                    child: _productTitleText(
                                      context,
                                      product,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: localeFontWeight(context, FontWeight.w700),
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (product.unit != null && product.unit!.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.posProductUnitPrefix} ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Flexible(
                                    child: LocalizedApiText(
                                      product.unit!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: product.stockColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _localizedStockLabel(context, product),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: product.stockColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cartQty > 0 && !widget.isReadOnly)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _posGridQtyX(context, product, cartQty),
                                style: TextStyle(fontSize: 10, fontWeight: localeFontWeight(context, FontWeight.w900), color: AppColors.secondaryLight),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _posGridMoney(
                                context,
                                _displayUnitPriceForProduct(
                                  context.read<PosViewModel>(),
                                  product,
                                ),
                              ),
                              textAlign: TextAlign.end,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: localeFontWeight(context, FontWeight.w800),
                                fontSize: _inOrdersHubDialog ? 12 : 14,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ),
                          if (_canShowEditableUnitPriceDialog(product))
                            _buildEditablePriceEditTap(
                              product,
                              iconSize: _inOrdersHubDialog ? 14 : 16,
                            ),
                        ],
                      ),
                      if (!widget.isReadOnly &&
                          (!product.isService || product.allowsServiceQty)) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildQtyButton(Icons.remove, isTablet, onTap: cartQty > 0
                                ? () => _updateQty(product, -1)
                                : null),
                            _GridQuantityTapChip(
                              product: product,
                              cartQty: cartQty,
                              isTablet: isTablet,
                              outOfStock: outOfStock,
                              onOpenEditor: () =>
                                  _showProductQuantityEditorDialog(product),
                            ),
                            _buildQtyButton(
                              Icons.add,
                              isTablet,
                              onTap: _canIncrementProduct(product, cartQty)
                                  ? () => _addToCart(product)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tablet View (Grid Item)
    final hub = _inOrdersHubDialog;
    final tight = _tightCatalogChrome;
    final cardRadius = hub ? 12.0 : (tight ? 12.0 : 14.0);
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isReadOnly
                ? null
                : (product.isServiceQtyLocked ||
                        _canIncrementProduct(product, cartQty))
                    ? () => _onCatalogCardTap(product, cartQty)
                    : null,
            borderRadius: BorderRadius.circular(cardRadius),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cardRadius),
                border: (cartQty > 0 && !widget.isReadOnly)
                    ? Border.all(color: AppColors.primaryLight, width: 2)
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hub ? 7 : (tight ? 8 : 9),
                  hub ? 6 : (tight ? 7 : 8),
                  hub ? 7 : (tight ? 8 : 9),
                  hub ? 6 : (tight ? 7 : 8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _productTitleText(
                                context,
                                product,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: localeFontWeight(context, FontWeight.w700),
                                  fontSize: hub ? 12 : (tight ? 13 : 14),
                                  height: 1.12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (product.unit != null && product.unit!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: hub ? 2 : 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.posProductUnitPrefix} ',
                                    style: TextStyle(
                                      fontSize: hub ? 10 : 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                    ),
                                  ),
                                  Flexible(
                                    child: LocalizedApiText(
                                      product.unit!,
                                      style: TextStyle(
                                        fontSize: hub ? 10 : 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                        height: 1.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.only(top: hub ? 2 : 3),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: hub ? 4 : 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: product.stockColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _localizedStockLabel(context, product),
                                style: TextStyle(
                                  fontSize: hub ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                  color: product.stockColor,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: hub ? 3 : 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _posGridMoney(
                                      context,
                                      _displayUnitPriceForProduct(
                                        context.read<PosViewModel>(),
                                        product,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: localeFontWeight(context, FontWeight.w800),
                                      fontSize: hub ? 13 : (tight ? 15 : 17),
                                      height: 1.0,
                                      color: AppColors.secondaryLight,
                                    ),
                                  ),
                                ),
                                if (_canShowEditableUnitPriceDialog(product))
                                  _buildEditablePriceEditTap(
                                    product,
                                    iconSize: hub ? 14 : 16,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isReadOnly &&
                        (!product.isService || product.allowsServiceQty)) ...[
                      SizedBox(height: hub ? 4 : 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQtyButton(Icons.remove, true, onTap: cartQty > 0
                              ? () => _updateQty(product, -1)
                              : null),
                          _GridQuantityTapChip(
                            product: product,
                            cartQty: cartQty,
                            isTablet: true,
                            outOfStock: outOfStock,
                            onOpenEditor: () =>
                                _showProductQuantityEditorDialog(product),
                          ),
                          _buildQtyButton(
                            Icons.add,
                            true,
                            onTap: _canIncrementProduct(product, cartQty)
                                ? () => _addToCart(product)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (cartQty > 0 && !widget.isReadOnly)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _posGridQtyX(context, product, cartQty),
                style: TextStyle(fontSize: 10, fontWeight: localeFontWeight(context, FontWeight.w900), color: AppColors.secondaryLight),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQtyButton(IconData icon, bool isTablet, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isTablet ? 28 : 28,
        height: isTablet ? 28 : 28,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.secondaryLight : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: isTablet ? 14 : 14, color: onTap != null ? Colors.white : Colors.grey),
      ),
    );
  }

  Widget _buildAppliedPromoBanner({
    required PosViewModel vm,
    required String? promoContextDeptId,
    required bool isTablet,
    required bool cartEmpty,
    bool compact = false,
    bool isLandscape = false,
  }) {
    final promoCode = vm
        .getActivePromoCode(widget.isMainTab, departmentId: promoContextDeptId)
        .trim();
    final hasPromo = promoCode.isNotEmpty;
    if (cartEmpty) {
      return const SizedBox.shrink();
    }
    // Department carts no longer manage promos — promo codes are applied from
    // the Order Summary panel. The walk-in main tab keeps its banner because
    // it has no summary step.
    if (promoContextDeptId != null) {
      return const SizedBox.shrink();
    }
    final discountLabel = vm.getActivePromoDiscountLabel(
      widget.isMainTab,
      departmentId: promoContextDeptId,
    );
    final appliesToLabel = vm.getActivePromoAppliesToLabel(
      widget.isMainTab,
      departmentId: promoContextDeptId,
    );
    final loc = AppLocalizations.of(context)!;
    final titleFontSize = compact
        ? 11.0
        : (isTablet ? (isLandscape ? 15.0 : 17.0) : 12.0);
    final detailFontSize = compact
        ? 9.5
        : (isTablet ? (isLandscape ? 12.0 : 13.0) : 10.5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : (isTablet ? 8 : 6),
        vertical: compact ? 4 : (isLandscape ? (isTablet ? 4 : 3) : (isTablet ? 5 : 4)),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: const Color(0xFFFFC145).withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: compact ? 14 : (isTablet ? 18 : 15),
            color: Colors.amber.shade700,
          ),
          SizedBox(width: compact ? 4 : (isTablet ? 8 : 6)),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: cartEmpty
                    ? null
                    : () {
                        vm.setPromoContextDepartment(
                          promoContextDeptId,
                          isMainTab: widget.isMainTab,
                        );
                        PromoCodeDialog.show(
                          context,
                          isMainTab: widget.isMainTab,
                          departmentId: promoContextDeptId,
                        );
                      },
                borderRadius: BorderRadius.circular(compact ? 6 : 8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 3 : 4,
                    vertical: compact ? 2 : (isTablet ? 4 : 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPromo
                            ? '${loc.posProductPromoPrefix} $promoCode'
                            : loc.posProductAddPromoCode,
                        style: TextStyle(
                          color: hasPromo && !compact
                              ? Colors.green.shade700
                              : const Color(0xFF1E2124),
                          fontWeight: localeFontWeight(context, FontWeight.w700),
                          fontSize: titleFontSize,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasPromo && discountLabel != null) ...[
                        SizedBox(height: compact ? 2 : 3),
                        Text(
                          discountLabel,
                          style: TextStyle(
                            fontSize: detailFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (hasPromo && appliesToLabel != null) ...[
                        SizedBox(height: compact ? 1 : 2),
                        Text(
                          appliesToLabel,
                          style: TextStyle(
                            fontSize: detailFontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            height: 1.15,
                          ),
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasPromo)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: compact ? 24 : (isTablet ? 32 : 28),
                minHeight: compact ? 24 : (isTablet ? 32 : 28),
              ),
              icon: compact
                  ? Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.close_rounded,
                      size: isTablet ? 22 : 18,
                      color: Colors.red,
                    ),
              onPressed: () {
                context.read<PromoViewModel>().removeAppliedPromo(
                  vm,
                  isMainTab: widget.isMainTab,
                  departmentId: promoContextDeptId,
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Cart Item ──
  /// Right column: line total excl. VAT (line discount + optional promo share).
  Widget _buildCartLineExclVatPriceBlock(
    CartItem item, {
    required bool isTablet,
    double promoDiscount = 0,
  }) {
    final hub = _inOrdersHubDialog;
    final hasLineDisc = item.actualDiscountAmount > 0;
    final lineTotal = item.totalPriceExclVat;
    final hasPromo = promoDiscount > 0.0001;
    final payableExclVat =
        (lineTotal - promoDiscount).clamp(0, lineTotal).toDouble();
    final showGrossStrike = hasLineDisc || hasPromo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGrossStrike) ...[
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              _posGridMoney(context, hasPromo ? lineTotal : item.lineSubtotalExclVat),
              style: TextStyle(
                fontSize: isTablet ? 14 : (hub ? 9.5 : 11),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey.shade600,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 4 : (hub ? 1 : 2)),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Text(
            _posGridMoney(context, hasPromo ? payableExclVat : lineTotal),
            style: TextStyle(
              fontSize: isTablet ? 18 : (hub ? 11 : 13),
              fontWeight: localeFontWeight(context, FontWeight.w800),
              color: hasPromo ? const Color(0xFF2E7D32) : const Color(0xFF1E2124),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemPromoBadge({
    required String promoCode,
    required double linePromoDiscount,
    required bool isTablet,
  }) {
    final hub = _inOrdersHubDialog;
    return Container(
      margin: EdgeInsets.only(top: isTablet ? 6 : (hub ? 3 : 4)),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : (hub ? 5 : 6),
        vertical: isTablet ? 4 : (hub ? 2 : 3),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(isTablet ? 6 : 5),
        border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: isTablet ? 12 : (hub ? 9 : 10),
            color: const Color(0xFF2E7D32),
          ),
          SizedBox(width: isTablet ? 4 : 3),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.posProductPromoLabel(promoCode),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isTablet ? 11 : (hub ? 8.5 : 9.5),
                fontWeight: localeFontWeight(context, FontWeight.w700),
                color: const Color(0xFF1B5E20),
              ),
            ),
          ),
          if (linePromoDiscount > 0.0001) ...[
            SizedBox(width: isTablet ? 6 : 4),
            Text(
              _posGridMoney(context, linePromoDiscount, negative: true),
              style: TextStyle(
                fontSize: isTablet ? 11 : (hub ? 8.5 : 9.5),
                fontWeight: localeFontWeight(context, FontWeight.w800),
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, bool isTablet) {
    final hub = _inOrdersHubDialog;
    final vm = context.watch<PosViewModel>();
    final promoDeptId = _resolvePromoContextDeptId();
    final promoCode = vm.getActivePromoCode(
      widget.isMainTab,
      departmentId: promoDeptId,
    ).trim();
    final promoEligible = vm.isCartItemPromoEligible(
      item,
      widget.isMainTab,
      departmentId: promoDeptId,
    );
    final linePromoDiscount = vm.getCartItemPromoDiscount(
      item,
      widget.isMainTab,
      departmentId: promoDeptId,
    );
    final showLinePromoPriceCut = vm.shouldShowLineItemPromoPriceCut(
      widget.isMainTab,
      departmentId: promoDeptId,
    );
    // Badge only on lines that actually match promo scope (category/product rules).
    final showPromoBadge = promoCode.isNotEmpty && promoEligible;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.only(
            left: isTablet ? 14 : (hub ? 9 : 12),
            right: isTablet ? 44 : (hub ? 32 : 38),
            top: isTablet ? 12 : (hub ? 7 : 10),
            bottom: isTablet ? 12 : (hub ? 7 : 12),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 13 : (hub ? 10 : 14)),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
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
                        _productTitleText(
                            context,
                            item.product,
                            style: TextStyle(
                              fontSize: isTablet ? 17 : (hub ? 11 : 13),
                              fontWeight: localeFontWeight(context, FontWeight.w700),
                              color: const Color(0xFF1E2124),
                              height: isTablet ? 1.2 : 1.12,
                            ),
                            maxLines: isTablet ? 2 : (hub ? 2 : 1),
                            overflow: TextOverflow.ellipsis),
                        if (showPromoBadge)
                          _buildCartItemPromoBadge(
                            promoCode: promoCode,
                            linePromoDiscount: linePromoDiscount,
                            isTablet: isTablet,
                          ),
                        SizedBox(height: isTablet ? 8 : (hub ? 4 : 6)),
                        if (item.product.isPriceEditable)
                          _EditableUnitPriceRow(
                            item: item,
                            isMainTab: widget.isMainTab,
                            isTablet: isTablet,
                          )
                        else
                          _buildCartLineQtyPriceBadge(
                            context: context,
                            item: item,
                            isTablet: isTablet,
                          ),
                      ],
                    ),
                  ),

                  if (isTablet) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCartLineExclVatPriceBlock(
                          item,
                          isTablet: true,
                          promoDiscount:
                              showLinePromoPriceCut ? linePromoDiscount : 0,
                        ),
                        SizedBox(
                          height: item.actualDiscountAmount > 0 ? 8 : 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.posProductDiscountAbbrev,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              height: 28,
                              child: TextFormField(
                                key: ValueKey(
                                  'ind_disc_${item.product.id}_${item.isDiscountPercent}',
                                ),
                                initialValue: item.discount > 0
                                    ? (item.discount % 1 == 0
                                    ? item.discount.toInt().toString()
                                    : item.discount.toString())
                                    : '',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (val) {
                                  final discount = double.tryParse(val) ?? 0.0;
                                  context.read<PosViewModel>().setIndividualDiscount(
                                    item.product,
                                    discount,
                                    item.isDiscountPercent,
                                    isMainTab: widget.isMainTab,
                                  );
                                },
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                context.read<PosViewModel>().setIndividualDiscount(
                                  item.product,
                                  item.discount,
                                  !item.isDiscountPercent,
                                  isMainTab: widget.isMainTab,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC145)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  item.isDiscountPercent ? '%' : _posGridCurrencyLabel(context),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: localeFontWeight(context, FontWeight.w700),
                                    color: Color(0xFF1E2124),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Price + discount on the right for mobile (compact row)
                  if (!isTablet) ...[
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCartLineExclVatPriceBlock(
                          item,
                          isTablet: false,
                          promoDiscount:
                              showLinePromoPriceCut ? linePromoDiscount : 0,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.posProductDiscountShort,
                              style: TextStyle(
                                fontSize: hub ? 9 : 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            SizedBox(width: hub ? 2 : 3),
                            SizedBox(
                              width: hub ? 34 : 38,
                              height: hub ? 16 : 18,
                              child: TextFormField(
                                key: ValueKey('ind_disc_${item.product.id}_${item.isDiscountPercent}'),
                                initialValue: item.discount > 0
                                    ? (item.discount % 1 == 0 ? item.discount.toInt().toString() : item.discount.toString())
                                    : '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) {
                                  final discount = double.tryParse(val) ?? 0.0;
                                  context.read<PosViewModel>().setIndividualDiscount(item.product, discount, item.isDiscountPercent, isMainTab: widget.isMainTab);
                                },
                                style: TextStyle(fontSize: hub ? 9 : 10),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  hintText: '0',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(width: hub ? 2 : 3),
                            GestureDetector(
                              onTap: () => context.read<PosViewModel>().setIndividualDiscount(item.product, item.discount, !item.isDiscountPercent, isMainTab: widget.isMainTab),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hub ? 3 : 4,
                                  vertical: hub ? 1 : 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC145).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.isDiscountPercent ? '%' : _posGridCurrencyLabel(context),
                                  style: TextStyle(
                                    fontSize: hub ? 9 : 10,
                                    fontWeight: localeFontWeight(context, FontWeight.w700),
                                    color: const Color(0xFF1E2124),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: isTablet ? 8 : (hub ? 5 : 8),
          right: isTablet ? 8 : (hub ? 5 : 8),
          child: GestureDetector(
            onTap: () {
              unawaited(() async {
                await _confirmAndRemoveCartItem(context, item.product);
                _consumePendingPopupCloseAfterPromoRemoval();
              }());
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.all(isTablet ? 6 : (hub ? 4 : 6)),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(hub ? 6 : 8),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                size: isTablet ? 17 : (hub ? 13 : 15),
                color: Colors.red.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──
  Widget _buildInteractiveTotalDiscountRow(
      BuildContext context,
      PosViewModel vm,
      bool isTablet,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.posOrdersTotalDiscount,
            style: TextStyle(
              fontSize: isTablet ? 18 : 10,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: isTablet ? 80 : 56,
          height: isTablet ? 28 : 26,
          child: TextField(
            controller: vm.globalDiscountTextController(widget.isMainTab),
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,+\s]')),
            ],
            onChanged: (val) {
              final discount = _parseCombinedDiscountInput(val);
              context.read<PosViewModel>().setGlobalDiscount(
                discount,
                vm.getActiveIsGlobalDiscountPercent(widget.isMainTab),
                isMainTab: widget.isMainTab,
              );
            },
            style: TextStyle(
              fontSize: isTablet ? 14 : 11,
              color: Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.green.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.green.shade400),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            context.read<PosViewModel>().setGlobalDiscount(
              vm.getActiveGlobalDiscount(widget.isMainTab),
              !vm.getActiveIsGlobalDiscountPercent(widget.isMainTab),
              isMainTab: widget.isMainTab,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 8 : 6,
              vertical: isTablet ? 4 : 3,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              vm.getActiveIsGlobalDiscountPercent(widget.isMainTab) ? '%' : _posGridCurrencyLabel(context),
              style: TextStyle(
                fontSize: isTablet ? 12 : 9,
                fontWeight: localeFontWeight(context, FontWeight.w700),
                color: Colors.green.shade800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, bool isTablet, {Color? color}) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: isTablet ? 18 : 10, color: color ?? Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: isTablet ? 18 : 10, fontWeight: FontWeight.w600, color: color ?? AppColors.secondaryLight)),
      ],
    );
  }

  double _parseCombinedDiscountInput(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) return 0.0;

    final parts = normalized
        .split(RegExp(r'[+,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    double total = 0.0;
    for (final part in parts) {
      total += double.tryParse(part) ?? 0.0;
    }
    return total;
  }

}


String _posGridLocalizeDigits(BuildContext context, String value) {
  return AppTranslationService.localizeDigitsForLanguage(
    value,
    Localizations.localeOf(context).languageCode,
  );
}

String _posGridCurrencyLabel(BuildContext context) {
  return AppLocalizations.of(context)!.posCommonSar;
}

String _posGridMoney(BuildContext context, double value, {bool negative = false}) {
  final amount = _posGridLocalizeDigits(context, value.abs().toStringAsFixed(2));
  final formatted = AppLocalizations.of(context)!.posCommonSarAmount(amount);
  return negative || value < 0 ? '- $formatted' : formatted;
}

String _posGridQuantityDisplay(BuildContext context, PosProduct product, double qty) {
  return _posGridLocalizeDigits(context, _formatGridQuantityLabel(product, qty));
}

String _posGridQtyX(BuildContext context, PosProduct product, double qty) {
  return AppLocalizations.of(context)!.posCommonQtyX(
    _posGridQuantityDisplay(context, product, qty),
  );
}

InputDecoration _posGridFormDialogInputDecoration(BuildContext context, String labelText) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Grid badge + inline qty field (respects [PosProduct.allowDecimalQty]).
String _formatGridQuantityLabel(PosProduct product, double q) {
  if (product.isInfiniteQty && q <= 0) return '∞';
  if (q <= 0) return '0';
  if (!product.allowDecimalQty) {
    return (q % 1 == 0) ? q.toInt().toString() : q.round().toString();
  }
  final rounded = (q * 100).round() / 100.0;
  if (rounded % 1 == 0) return rounded.toInt().toString();
  var s = rounded.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Tappable quantity on grid cards; opens a dialog so typing happens in the overlay
/// (keeps header fixed and avoids inline keyboard layout issues).
class _GridQuantityTapChip extends StatelessWidget {
  final PosProduct product;
  final double cartQty;
  final bool isTablet;
  final bool outOfStock;
  /// When false, quantity is display-only — no dialog / text field.
  final bool enableQuantityEditor;
  final VoidCallback onOpenEditor;

  const _GridQuantityTapChip({
    required this.product,
    required this.cartQty,
    required this.isTablet,
    required this.outOfStock,
    this.enableQuantityEditor = true,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = outOfStock;
    final label = _posGridQuantityDisplay(context, product, cartQty);
    final r = BorderRadius.circular(isTablet ? 7 : 6);

    final core = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade200 : Colors.grey.shade50,
        borderRadius: r,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.w600,
          color: disabled ? Colors.grey.shade600 : const Color(0xFF1E2124),
        ),
      ),
    );

    final tappable = enableQuantityEditor && !disabled;

    if (isTablet) {
      return Expanded(
        child: SizedBox(
          height: 28,
          child: tappable
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: r,
                    onTap: onOpenEditor,
                    child: core,
                  ),
                )
              : core,
        ),
      );
    }
    return SizedBox(
      height: 24,
      width: 40,
      child: tappable
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: r,
                onTap: onOpenEditor,
                child: core,
              ),
            )
          : core,
    );
  }
}

EdgeInsets _cartQtyPriceRowPadding(bool isTablet) => EdgeInsets.symmetric(
      horizontal: isTablet ? 9 : 6,
      vertical: isTablet ? 5 : 4,
    );

BoxDecoration _cartQtyPriceRowDecoration() => BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(6),
    );

double _cartQtyPriceRowFontSize(bool isTablet) => isTablet ? 13 : 11;

TextStyle _cartQtyPriceMutedStyle(bool isTablet) => TextStyle(
      fontSize: _cartQtyPriceRowFontSize(isTablet),
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
      height: 1.0,
    );

TextStyle _cartQtyPriceValueStyle(BuildContext context, bool isTablet) => TextStyle(
      fontSize: _cartQtyPriceRowFontSize(isTablet),
      fontWeight: localeFontWeight(context, FontWeight.w700),
      color: const Color(0xFF1E2124),
      height: 1.0,
    );

String _cartQtyPriceAmountDisplay(BuildContext context, double value) {
  return _posGridLocalizeDigits(context, value.toStringAsFixed(2));
}

Widget _buildCartLineQtyPriceBadge({
  required BuildContext context,
  required CartItem item,
  required bool isTablet,
}) {
  final qtyLabel =
      _posGridQuantityDisplay(context, item.product, item.quantity);
  final priceAmount =
      _cartQtyPriceAmountDisplay(context, item.effectiveUnitPrice);

  return Container(
    padding: _cartQtyPriceRowPadding(isTablet),
    decoration: _cartQtyPriceRowDecoration(),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(qtyLabel, style: _cartQtyPriceMutedStyle(isTablet)),
        Text(
          ' × ${_posGridCurrencyLabel(context)} ',
          style: _cartQtyPriceMutedStyle(isTablet),
        ),
        Text(priceAmount, style: _cartQtyPriceValueStyle(context, isTablet)),
      ],
    ),
  );
}

/// Unit price editor for price-editable catalog lines in the cart (stable [TextEditingController]).
class _EditableUnitPriceRow extends StatefulWidget {
  final CartItem item;
  final bool isMainTab;
  final bool isTablet;

  const _EditableUnitPriceRow({
    required this.item,
    required this.isMainTab,
    required this.isTablet,
  });

  @override
  State<_EditableUnitPriceRow> createState() =>
      _EditableUnitPriceRowState();
}

class _EditableUnitPriceRowState extends State<_EditableUnitPriceRow> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  double? _parseUnitPriceField(String raw) {
    final normalized = EnglishNumberFormatter.convert(raw.trim())
        .replaceAll(',', '.');
    if (normalized.isEmpty || normalized == '.' || normalized == '-') {
      return null;
    }
    var text = normalized;
    if (RegExp(r'^\d+\.$').hasMatch(text)) {
      text = '${text}0';
    }
    final p = double.tryParse(text);
    if (p == null || !p.isFinite || p <= 0) return null;
    return p;
  }

  void _commitUnitPriceToModel() {
    final p = _parseUnitPriceField(_controller.text);
    if (p != null) {
      final err = widget.item.product.validateEditableUnitPrice(p);
      if (err == 'below_min') {
        if (mounted) {
          ToastService.showError(
            context,
            'Price cannot be below SAR ${widget.item.product.minEditablePriceVatInclusive.toStringAsFixed(2)} for this product.',
          );
        }
        _syncControllerFromModelIfNeeded();
        return;
      }
    }
    context.read<PosViewModel>().setServiceUnitPrice(
      widget.item.product,
      p,
      isMainTab: widget.isMainTab,
    );
  }

  void _syncControllerFromModelIfNeeded() {
    final next = widget.item.effectiveUnitPrice;
    final raw = EnglishNumberFormatter.convert(_controller.text.trim())
        .replaceAll(',', '.');
    final fromField = double.tryParse(raw);
    final matches =
        fromField != null && (fromField - next).abs() < 0.005;
    if (!matches) {
      final s = next.toStringAsFixed(2);
      if (_controller.text != s) {
        _controller.text = s;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final u = widget.item.effectiveUnitPrice;
    _controller = TextEditingController(
      text: u > 0 ? u.toStringAsFixed(2) : '',
    );
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitUnitPriceToModel();
        _syncControllerFromModelIfNeeded();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableUnitPriceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final productChanged = oldWidget.item.product.id != widget.item.product.id ||
        oldWidget.item.product.isServiceType != widget.item.product.isServiceType ||
        (oldWidget.item.product.departmentId ?? '') !=
            (widget.item.product.departmentId ?? '');
    if (productChanged) {
      final u = widget.item.effectiveUnitPrice;
      _controller.text = u > 0 ? u.toStringAsFixed(2) : '';
      return;
    }
    // [oldWidget.item] and [widget.item] are often the same [CartItem] instance;
    // comparing serviceUnitPrice on them misses updates (e.g. price set via dialog).
    if (!_focusNode.hasFocus) {
      _syncControllerFromModelIfNeeded();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _cartQtyPriceRowPadding(widget.isTablet),
      decoration: _cartQtyPriceRowDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _posGridQuantityDisplay(
              context,
              widget.item.product,
              widget.item.quantity,
            ),
            style: _cartQtyPriceMutedStyle(widget.isTablet),
          ),
          Text(
            ' × ${_posGridCurrencyLabel(context)} ',
            style: _cartQtyPriceMutedStyle(widget.isTablet),
          ),
          SizedBox(
            width: widget.isTablet ? 76 : 64,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: _cartQtyPriceValueStyle(context, widget.isTablet),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                border: InputBorder.none,
                hintText: AppLocalizations.of(context)!.posProductEditServicePriceHint,
              ),
              onChanged: (v) {
                final p = _parseUnitPriceField(v);
                if (p != null) {
                  final err = widget.item.product.validateEditableUnitPrice(p);
                  if (err == 'below_min') {
                    ToastService.showError(
                      context,
                      'Price cannot be below SAR ${widget.item.product.minEditablePriceVatInclusive.toStringAsFixed(2)} for this product.',
                    );
                    _syncControllerFromModelIfNeeded();
                    return;
                  }
                  context.read<PosViewModel>().setServiceUnitPrice(
                    widget.item.product,
                    p,
                    isMainTab: widget.isMainTab,
                  );
                } else if (v.trim().isEmpty) {
                  context.read<PosViewModel>().setServiceUnitPrice(
                    widget.item.product,
                    null,
                    isMainTab: widget.isMainTab,
                  );
                }
              },
              onEditingComplete: _commitUnitPriceToModel,
            ),
          ),
        ],
      ),
    );
  }
}

/// After [showModalBottomSheet] completes, the route may still animate out.
void _disposePosGridFormControllerAfterSheet(TextEditingController controller) {
  void disposeController() {
    controller.dispose();
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) => disposeController());
  });
}

/// Bottom sheet (not [Dialog]) — stable inside hub overlay + keyboard on Android.
Future<void> _showPosGridFormBottomSheet({
  required BuildContext context,
  required Widget title,
  required Widget Function(BuildContext sheetContext, AppLocalizations loc)
      fieldBuilder,
  required String cancelLabel,
  required String confirmLabel,
  required void Function(BuildContext sheetContext) onCancel,
  required void Function(BuildContext sheetContext) onConfirm,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final loc = AppLocalizations.of(sheetContext)!;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: _PosGridFormSheetPanel(
          title: title,
          field: fieldBuilder(sheetContext, loc),
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          onCancel: () => onCancel(sheetContext),
          onConfirm: () => onConfirm(sheetContext),
        ),
      );
    },
  );
}

class _PosGridFormSheetPanel extends StatelessWidget {
  final Widget title;
  final Widget field;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _PosGridFormSheetPanel({
    required this.title,
    required this.field,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            title,
            const SizedBox(height: 16),
            field,
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancel,
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
                      cancelLabel,
                      style: TextStyle(
                        fontWeight: localeFontWeight(context, FontWeight.w900),
                        letterSpacing: 0.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
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
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        fontWeight: localeFontWeight(context, FontWeight.w900),
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

class _ProductGridLoadingShimmer extends StatelessWidget {
  const _ProductGridLoadingShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isTablet ? 3 : 2;
    final itemCount = isTablet ? 9 : 6;
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16,
            isTablet ? 20 : 16,
            isTablet ? 24 : 16,
            12,
          ),
          sliver: SliverToBoxAdapter(
            child: PosShimmer(
              child: Row(
                children: [
                  const Expanded(
                    child: PosShimmerLine(
                      width: double.infinity,
                      height: 42,
                      radius: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  PosShimmerBox(
                    width: isTablet ? 140 : 96,
                    height: 42,
                    radius: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16,
            0,
            isTablet ? 24 : 16,
            isTablet ? 24 : 16,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isTablet ? 1.3 : 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const _ProductGridSkeletonCard(),
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductGridSkeletonCard extends StatelessWidget {
  const _ProductGridSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: const PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PosShimmerCircle(size: 42),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosShimmerLine(width: double.infinity, height: 13),
                      SizedBox(height: 8),
                      PosShimmerLine(width: 110, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            Spacer(),
            PosShimmerLine(width: double.infinity, height: 12),
            SizedBox(height: 10),
            Row(
              children: [
                PosShimmerBox(width: 82, height: 30, radius: 10),
                Spacer(),
                PosShimmerBox(width: 64, height: 30, radius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
