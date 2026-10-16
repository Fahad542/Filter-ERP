import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;
import 'dart:ui';
import '../../../utils/app_colors.dart';
import '../../../utils/app_arabic_font_fallbacks.dart';
import '../../../utils/app_button_busy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/plate_transliterator.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/invoice_maintenance_checklist.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../Home Screen/pos_view_model.dart';
import '../Add Customer Screen/pos_add_customer_view.dart';
import '../Department/department_view_model.dart';
import '../Department/pos_department_view.dart';
import '../Product Grid/pos_product_grid_view.dart';
import '../Technician Assignment/pos_technician_assignment_view.dart';
import 'pos_orders_hub_dialog.dart';
import '../../../models/create_invoice_model.dart';
import '../../../models/pos_order_model.dart';
import '../../../models/pos_product_model.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../services/cashier_open_session_guard.dart';
import '../../../services/session_service.dart';
import '../../../services/invoice_auto_dispatch.dart';
import '../../../services/invoice_dialog_launcher.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../utils/pos_shell_scaffold.dart';
import '../../../widgets/thermal_printer_wifi_dialog.dart';
import '../../../widgets/softpos_settings_dialog.dart';
import '../../../services/softpos_access_service.dart';
import '../../../services/softpos_bridge.dart';
import '../../../services/softpos_invoice_flow.dart';
import '../../../services/softpos_connection_guard.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../models/pos_payment_method.dart';
import '../../../models/order_payment_method_draft.dart';
import 'pos_orders_checkout_dialog.dart';
import '../Promo/promo_view_model.dart';
import '../Promo/promo_code_dialog.dart';
import '../Promo/referral_code_dialog.dart';
import '../Promo/promo_promotion_card.dart';
import '../../../utils/promo_eligibility.dart';
import '../../../models/promo_code_model.dart';

/// Non-cancelled orders for the hub list. Do not hide walk-in shells with no jobs yet
/// ([jobsAggregateBadgeLabel] == DRAFT) — those are valid in-progress orders.
bool _orderIsListableForOrdersList(PosOrder o) {
  final status = o.status.toLowerCase();
  if (status == 'cancelled' || status == 'canceled') return false;
  return true;
}

List<PosOrder> _ordersHubListable(PosViewModel vm) =>
    vm.orders.where(_orderIsListableForOrdersList).toList();

List<PosOrder> _ordersHubAfterSearch(PosViewModel vm) {
  final base = _ordersHubListable(vm);
  if (vm.orderSearchQuery.trim().isEmpty) return base;
  return base.where(vm.orderMatchesHubSearch).toList();
}

bool _ordersHubHasActiveSearch(PosViewModel vm) =>
    vm.orderSearchQuery.trim().isNotEmpty;

/// Full-screen "No orders" only when the cashier orders API returned zero orders.
bool _shouldShowOrdersHubFullEmptyState(PosViewModel vm) =>
    vm.ordersApiFetchCompleted && !vm.hasCashierOrdersFromApi;

/// Fixed width of the ORDER SUMMARY column (Orders Hub landscape). Slightly under the old 392px so department cards get more room.
const double _kPosOrdersHubSummaryColumnWidth = 332.0;

/// Matches [WalkInInvoiceDetailsDialog] / Final Review: walk-in PATCH allowed (not cashier corporate-quote lockout).
bool _ordersWalkInBillingEditable(PosOrder order) =>
    !(order.isCorporateWalkIn && !order.isCorporateBookingOrder);

/// Payroll retail walk-in — hide "Select payment" (same toggle as Invoice details branch employee customer).
bool _ordersIsRetailWalkInBranchEmployee(PosViewModel vm, PosOrder order) {
  if (!vm.isStandardWalkInOrderForBilling(order)) return false;
  if (!_ordersWalkInBillingEditable(order)) return false;
  final snap = vm.walkInBillingSnapshotForOrder(order.id);
  if (snap?.billingCustomerIsEmployee == true) return true;
  return order.customer?.isCustomerEmployee == true;
}


String _ordersTranslatedStatusLabel(BuildContext context, String statusRaw) {
  final l10n = AppLocalizations.of(context)!;
  var s = statusRaw.trim().toLowerCase().replaceAll(' ', '_');
  if (s == 'complete') s = 'completed';
  if (s == 'job_edited') s = 'edited';
  if (s == 'canceled') s = 'cancelled';
  if (s == 'rejected_by_corporate' || s.contains('rejected')) {
    return l10n.posOrdersStatusRejected;
  }
  switch (s) {
    case 'cancelled':
      return l10n.posOrdersStatusCancelled;
    case 'completed':
    case 'invoiced':
      return l10n.posOrdersStatusComplete;
    case 'paid':
      return l10n.billingStatusPaid.toUpperCase();
    case 'edited':
      return l10n.posOrdersStatusEdited;
    case 'in_progress':
    case 'inprogress':
      return l10n.posOrdersStatusInProgress;
    case 'unapproved':
      return l10n.posOrdersStatusUnapproved;
    case 'waiting_approval':
    case 'waiting_corporate_approval':
      return l10n.posOrdersStatusWaitingApproval;
    case 'corp_approved':
    case 'corporate_approved':
      return l10n.posOrdersStatusCorpApproved;
    case 'draft':
      return l10n.posOrdersStatusDraft;
    default:
      return l10n.posOrdersStatusPending;
  }
}


String _ordersProductNameForLocale(BuildContext context, PosOrderJobItem item) {
  final lang = Localizations.localeOf(context).languageCode;
  final ar = item.productNameArabic.trim();
  if (lang == 'ar' && ar.isNotEmpty) return ar;
  final en = item.productName.trim();
  return en.isNotEmpty ? en : item.productId;
}

String? _ordersBranchEmployeeIdForPayroll(PosViewModel vm, PosOrder order) {
  final snap = vm.walkInBillingSnapshotForOrder(order.id);
  final a = snap?.billingEmployeeId?.trim();
  if (a != null && a.isNotEmpty) return a;
  final b = order.customer?.branchEmployeeId?.trim();
  return b != null && b.isNotEmpty ? b : null;
}

bool _ordersRetailEmployeeInvoiceReady(PosViewModel vm, PosOrder order) {
  if (!_ordersIsRetailWalkInBranchEmployee(vm, order)) return false;
  final id = _ordersBranchEmployeeIdForPayroll(vm, order);
  return id != null && id.isNotEmpty;
}

/// Same 6 bilingual rows as the printable invoice / Final Review checklist.
/// **Save** calls `PATCH /cashier/order/:id/maintenance-checklist` then refreshes orders.
Future<void> _showOrdersMaintenanceChecklistDialog(
    BuildContext context,
    PosOrder order,
    ) async {
  final mc = order.maintenanceChecks;
  final checks = (mc != null &&
      mc.length == InvoiceMaintenanceChecklist.rows.length)
      ? List<bool>.from(mc)
      : List<bool>.filled(InvoiceMaintenanceChecklist.rows.length, false);

  final savingRef = <bool>[false];

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setModalState) {
        Future<void> save() async {
          if (savingRef[0]) return;
          final session =
          Provider.of<SessionService>(context, listen: false);
          final repo = Provider.of<PosRepository>(context, listen: false);
          final vm = Provider.of<PosViewModel>(context, listen: false);
          savingRef[0] = true;
          setModalState(() {});
          final token = await session.getToken(role: 'cashier');
          if (!context.mounted || token == null) {
            savingRef[0] = false;
            if (ctx.mounted) setModalState(() {});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.posOrdersPleaseSignInAgain)),
              );
            }
            return;
          }
          try {
            final res = await repo.patchOrderMaintenanceChecklist(
              orderId: order.id,
              checks: List<bool>.from(checks),
              token: token,
            );
            await vm.refreshOrderInHubAfterMutation(
              order.id,
              apiResponse: res,
            );
            if (!context.mounted) return;
            savingRef[0] = false;
            if (ctx.mounted) setModalState(() {});
            Navigator.of(dialogContext).pop();
            ToastService.showSuccess(
              context,
              AppLocalizations.of(context)!.posOrdersChecklistSaved,
            );
          } catch (e) {
            savingRef[0] = false;
            if (ctx.mounted) setModalState(() {});
            if (!context.mounted) return;
            ToastService.showError(
              context,
              e.toString().replaceFirst('Exception: ', ''),
            );
          }
        }

        final l10n = AppLocalizations.of(context)!;
        final size = MediaQuery.sizeOf(dialogContext);
        final isTablet = size.width > 600;
        final hubInsets = posOrdersHubDialogInsets(size);

        return Dialog(
          insetPadding: hubInsets,
          backgroundColor: const Color(0xFFFBF9F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size.height - hubInsets.vertical,
              maxWidth: 560,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosPrimaryDialogHeader(
                  title: l10n.posOrdersMaintenanceChecklistTitle,
                  isTablet: isTablet,
                  onClose: savingRef[0]
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 16 : 12,
                      isTablet ? 12 : 10,
                      isTablet ? 16 : 12,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.posOrdersMaintenanceChecklistDescription,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PosMaintenanceChecklistBulkActions(
                          disabled: savingRef[0],
                          onSelectAll: () {
                            setModalState(() {
                              for (var i = 0; i < checks.length; i++) {
                                checks[i] = true;
                              }
                            });
                          },
                          onClearAll: () {
                            setModalState(() {
                              for (var i = 0; i < checks.length; i++) {
                                checks[i] = false;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 4),
                        for (var i = 0;
                            i < InvoiceMaintenanceChecklist.rows.length;
                            i++)
                          CheckboxListTile(
                            value: checks[i],
                            onChanged: savingRef[0]
                                ? null
                                : (v) {
                                    setModalState(() => checks[i] = v ?? false);
                                  },
                            title: Text(
                              (Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? InvoiceMaintenanceChecklist.rows[i].ar
                                  : InvoiceMaintenanceChecklist.rows[i].en),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              InvoiceMaintenanceChecklist.rows[i].ar,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 14 : 12,
                    8,
                    isTablet ? 14 : 12,
                    isTablet ? 12 : 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: savingRef[0]
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        style: AppButtonBusy.elevatedLocked(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.posCommonCancel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: savingRef[0] ? null : save,
                        style: AppButtonBusy.filledLocked(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.onPrimaryLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (savingRef[0]) ...[
                              AppButtonBusy.loaderOnFill(
                                AppColors.primaryLight,
                                size: 20,
                                strokeWidth: 2,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              l10n.posCommonSave,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
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
    ),
  );
}

/// Detail panel when this tab has no orders but other tabs do.
String _ordersTabDetailEmptyMessage(AppLocalizations l10n, String tab) {
  switch (tab) {
    case 'Pending':
      return l10n.posOrdersNoPendingOrders;
    case 'Completed':
      return l10n.posOrdersNoCompletedOrders;
    case 'All':
    default:
      return l10n.posOrdersNoOrdersFound;
  }
}

/// Approximate list row height (tile + separator) for fallback scroll positioning.
const double _kOrdersHubListTileStride = 92;

/// Scrolls the Orders Hub list to [vm.hubScrollToOrderId] after placement / refresh.
class _OrdersHubScrollHandle {
  int lastSerial = 0;
  GlobalKey? targetKey;

  void onViewModelTick(
    PosViewModel vm,
    List<PosOrder> visibleOrders,
    ScrollController controller,
  ) {
    if (vm.hubScrollRequestSerial == lastSerial) return;
    lastSerial = vm.hubScrollRequestSerial;
    final orderId = vm.hubScrollToOrderId?.trim();
    if (orderId == null || orderId.isEmpty) return;
    targetKey = GlobalKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToOrder(orderId, visibleOrders, controller);
    });
  }

  void _scrollToOrder(
    String orderId,
    List<PosOrder> visibleOrders,
    ScrollController controller,
  ) {
    final ctx = targetKey?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.72,
      );
      return;
    }
    if (!controller.hasClients) return;
    final max = controller.position.maxScrollExtent;
    final index =
        visibleOrders.indexWhere((o) => o.id.trim() == orderId.trim());
    final target = index < 0
        ? max
        : (index * _kOrdersHubListTileStride).clamp(0.0, max);
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  GlobalKey? keyForOrderId(String orderId, PosViewModel vm) {
    final target = vm.hubScrollToOrderId?.trim();
    if (target == null || target.isEmpty || orderId.trim() != target) {
      return null;
    }
    return targetKey ??= GlobalKey();
  }
}

/// Fetches the next (older) page when the hub list is scrolled near the top.
///
/// The hub renders oldest → newest and the backend serves newest-first pages,
/// so every page after the first is *prepended*. The scroll offset is bumped by
/// however much the list grew above the viewport, otherwise the rows under the
/// cashier's finger would jump away as older orders arrive.
void _ordersLoadMoreWhenNearTop(
  PosViewModel vm,
  ScrollNotification notification,
  ScrollController controller,
) {
  if (notification.depth != 0) return;
  final metrics = notification.metrics;
  if (metrics.axis != Axis.vertical) return;
  if (!vm.ordersHasMore || vm.isLoadingMoreOrders) return;
  if (metrics.pixels > metrics.minScrollExtent + 180) return;

  final extentBefore = metrics.maxScrollExtent;
  unawaited(
    vm.loadMoreOrders().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.hasClients) return;
        final position = controller.position;
        final grew = position.maxScrollExtent - extentBefore;
        if (grew <= 0) return;
        controller.jumpTo(
          (controller.offset + grew)
              .clamp(position.minScrollExtent, position.maxScrollExtent),
        );
      });
    }),
  );
}

class _OrdersPaginationLoader extends StatelessWidget {
  const _OrdersPaginationLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }
}

class PosOrdersView extends StatefulWidget {
  const PosOrdersView({super.key});

  @override
  State<PosOrdersView> createState() => _PosOrdersViewState();
}

class _PosOrdersViewState extends State<PosOrdersView> {
  final ScrollController _mobileOrderListScrollController = ScrollController();
  final _OrdersHubScrollHandle _mobileOrdersHubScroll = _OrdersHubScrollHandle();

  @override
  void dispose() {
    _mobileOrderListScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        CashierOpenSessionGuard.instance.ensureOpenOrSignOut(context: context),
      );
      unawaited(context.read<PromoViewModel>().ensurePromoCatalogLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 900; // Master-Detail only on tablets/desktops
    final vm = context.watch<PosViewModel>();
    final showOrdersLoader = !vm.ordersApiFetchCompleted ||
        (vm.isLoading && !vm.hasCashierOrdersFromApi);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: PreferredSize(
        preferredSize: posAppBarPreferredSize(),
        child: ListenableBuilder(
          listenable: PosShellScaffoldRegistry.ordersSideMenuOpen,
          builder: (context, _) => PosScreenAppBar(
            title: AppLocalizations.of(context)!.posOrdersHubTitle,
            showBackButton: false,
            showHamburger: true,
            menuOpen: PosShellScaffoldRegistry.isOrdersSideMenuOpen,
            onMenuPressed: PosShellScaffoldRegistry.toggleOrdersSideMenu,
            globeOnTrailing: true,
            clockOnLeading: true,
            trailingPrefix: [
              ListenableBuilder(
                listenable: SoftPosAccessService.instance,
                builder: (context, _) {
                  if (!isSoftPosUiEnabled) return const SizedBox.shrink();
                  return const OrdersHubSoftPosAppBarAction();
                },
              ),
              const OrdersHubThermalPrinterAppBarAction(),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          wrapPosShellRailBody(
            context,
            isTablet ? _OrdersTabletLayout(vm: vm) : _buildMobileView(vm),
          ),
          if (vm.isOrdersScreenRefreshing)
            Positioned.fill(
              child: AbsorbPointer(
                child: wrapPosShellRailBody(
                  context,
                  ClipRect(
                    child: _OrdersHubShimmerOverlay(
                      isTablet: isTablet,
                      translucent: false,
                    ),
                  ),
                ),
              ),
            ),
          if (showOrdersLoader)
            Positioned.fill(
              child: AbsorbPointer(
                child: wrapPosShellRailBody(
                  context,
                  ClipRect(
                    child: _OrdersHubShimmerOverlay(isTablet: isTablet),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileView(PosViewModel vm) {
    Future<void> onRefresh() => vm.refreshOrdersScreen();
    final fetchError = vm.ordersFetchError;
    final showFetchError =
        fetchError != null && vm.ordersApiFetchCompleted;

    if (_shouldShowOrdersHubFullEmptyState(vm)) {
      if (showFetchError) {
        return ColoredBox(
          color: const Color(0xFFFBFBFD),
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: onRefresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: _OrdersFetchErrorStateBody(
                        message: fetchError,
                        onRetry: vm.refreshOrdersScreen,
                        onDismiss: vm.dismissOrdersFetchError,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
      return ColoredBox(
        color: const Color(0xFFFBFBFD),
        child: RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: onRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: _OrdersEmptyStateBody(title: AppLocalizations.of(context)!.posOrdersNoOrdersFound),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    final visibleOrders = _ordersHubAfterSearch(vm);
    _mobileOrdersHubScroll.onViewModelTick(
      vm,
      visibleOrders,
      _mobileOrderListScrollController,
    );
    return Column(
      children: [
        if (showFetchError)
          _OrdersFetchErrorBanner(
            message: fetchError,
            onRetry: vm.refreshOrdersScreen,
            onDismiss: vm.dismissOrdersFetchError,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: PosWorkshopSearchBar(
                  hintText: AppLocalizations.of(context)!.posOrdersSearchHint,
                  onChanged: (val) => vm.setOrderSearchQuery(val),
                ),
              ),
              const SizedBox(width: 8),
              _OrdersNewOrderButton(),
            ],
          ),
        ),
        Expanded(
          child: visibleOrders.isEmpty && _ordersHubHasActiveSearch(vm)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      AppLocalizations.of(context)!.posOrdersSearchNoMatch,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        height: 1.35,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryLight,
                  onRefresh: onRefresh,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      _ordersLoadMoreWhenNearTop(
                        vm,
                        notification,
                        _mobileOrderListScrollController,
                      );
                      return false;
                    },
                    child: ListView.separated(
                      controller: _mobileOrderListScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      itemCount: visibleOrders.length +
                          (vm.isLoadingMoreOrders ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        // Older pages prepend, so the spinner leads the list.
                        if (vm.isLoadingMoreOrders) {
                          if (index == 0) return const _OrdersPaginationLoader();
                          index -= 1;
                        }
                        final order = visibleOrders[index];
                        final scrollKey =
                            _mobileOrdersHubScroll.keyForOrderId(order.id, vm);
                        return KeyedSubtree(
                          key: scrollKey,
                          child: OrderItemCard(order: order, isTablet: false),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}



class _OrdersHubShimmerOverlay extends StatefulWidget {
  final bool isTablet;
  final bool translucent;

  const _OrdersHubShimmerOverlay({
    required this.isTablet,
    this.translucent = false,
  });

  @override
  State<_OrdersHubShimmerOverlay> createState() => _OrdersHubShimmerOverlayState();
}

class _OrdersHubShimmerOverlayState extends State<_OrdersHubShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: widget.translucent ? 0.82 : 1),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final p = _controller.value;
            return widget.isTablet
                ? _OrdersTabletShimmer(progress: p)
                : _OrdersMobileShimmer(progress: p);
          },
        ),
      ),
    );
  }
}

class _OrdersMobileShimmer extends StatelessWidget {
  final double progress;

  const _OrdersMobileShimmer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: _OrdersShimmerBox(progress: progress, height: 42, radius: 12)),
              const SizedBox(width: 10),
              _OrdersShimmerBox(progress: progress, width: 104, height: 42, radius: 10),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => _OrdersListCardShimmer(progress: progress, compact: false),
          ),
        ),
      ],
    );
  }
}

class _OrdersTabletShimmer extends StatelessWidget {
  final double progress;

  const _OrdersTabletShimmer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(child: _OrdersShimmerBox(progress: progress, height: 44, radius: 12)),
                    const SizedBox(width: 12),
                    _OrdersShimmerBox(progress: progress, width: 108, height: 40, radius: 10),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 20, 10),
                child: Row(
                  children: [
                    _OrdersShimmerBox(progress: progress, width: 72, height: 32, radius: 18),
                    const SizedBox(width: 12),
                    _OrdersShimmerBox(progress: progress, width: 92, height: 32, radius: 18),
                    const SizedBox(width: 12),
                    _OrdersShimmerBox(progress: progress, width: 112, height: 32, radius: 18),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8ECF3)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 188,
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                        itemCount: 8,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, __) => _OrdersListCardShimmer(progress: progress, compact: true),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFE8ECF3)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.85,
                          ),
                          itemCount: 4,
                          itemBuilder: (_, __) => _OrdersJobCardShimmer(progress: progress),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE8ECF3)),
        SizedBox(
          width: _kPosOrdersHubSummaryColumnWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
            child: _OrdersSummaryShimmer(progress: progress),
          ),
        ),
      ],
    );
  }
}

class _OrdersListCardShimmer extends StatelessWidget {
  final double progress;
  final bool compact;

  const _OrdersListCardShimmer({required this.progress, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OrdersShimmerBox(progress: progress, width: compact ? 34 : 40, height: compact ? 34 : 40, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrdersShimmerBox(progress: progress, height: 11, radius: 6),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.72,
                      child: _OrdersShimmerBox(progress: progress, height: 10, radius: 6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          _OrdersShimmerBox(progress: progress, height: compact ? 22 : 28, radius: 8),
        ],
      ),
    );
  }
}

class _OrdersJobCardShimmer extends StatelessWidget {
  final double progress;

  const _OrdersJobCardShimmer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final veryTight = maxH.isFinite && maxH < 155;
        final tight = maxH.isFinite && maxH < 180;

        final pad = veryTight ? 8.0 : (tight ? 10.0 : 12.0);
        final icon = veryTight ? 28.0 : (tight ? 30.0 : 34.0);
        final line = veryTight ? 10.0 : (tight ? 11.0 : 13.0);
        final chip = veryTight ? 22.0 : (tight ? 24.0 : 30.0);
        final button = veryTight ? 26.0 : (tight ? 28.0 : 34.0);
        final gapLarge = veryTight ? 6.0 : (tight ? 8.0 : 12.0);
        final gapSmall = veryTight ? 5.0 : (tight ? 6.0 : 8.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _OrdersShimmerBox(
                      progress: progress,
                      width: icon,
                      height: icon,
                      radius: 12,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OrdersShimmerBox(
                        progress: progress,
                        height: line,
                        radius: 7,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gapLarge),
                _OrdersShimmerBox(progress: progress, height: chip, radius: 10),
                SizedBox(height: gapSmall),
                _OrdersShimmerBox(progress: progress, height: chip, radius: 10),
                const Expanded(child: SizedBox.shrink()),
                Row(
                  children: [
                    Expanded(
                      child: _OrdersShimmerBox(
                        progress: progress,
                        height: button,
                        radius: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OrdersShimmerBox(
                        progress: progress,
                        height: button,
                        radius: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersSummaryShimmer extends StatelessWidget {
  final double progress;

  const _OrdersSummaryShimmer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrdersShimmerBox(progress: progress, width: 160, height: 16, radius: 8),
          const SizedBox(height: 14),
          for (var i = 0; i < 7; i++) ...[
            Row(
              children: [
                Expanded(child: _OrdersShimmerBox(progress: progress, height: 12, radius: 6)),
                const SizedBox(width: 18),
                _OrdersShimmerBox(progress: progress, width: 82, height: 12, radius: 6),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const Spacer(),
          _OrdersShimmerBox(progress: progress, height: 42, radius: 12),
          const SizedBox(height: 10),
          _OrdersShimmerBox(progress: progress, height: 42, radius: 12),
        ],
      ),
    );
  }
}

class _OrdersInlineShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _OrdersInlineShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_OrdersInlineShimmerBox> createState() => _OrdersInlineShimmerBoxState();
}

class _OrdersInlineShimmerBoxState extends State<_OrdersInlineShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => _OrdersShimmerBox(
          progress: _controller.value,
          width: widget.width,
          height: widget.height,
          radius: widget.radius,
        ),
      ),
    );
  }
}

class _OrdersShimmerBox extends StatelessWidget {
  final double progress;
  final double? width;
  final double height;
  final double radius;

  const _OrdersShimmerBox({
    required this.progress,
    this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth.isFinite ? constraints.maxWidth : (width ?? 160);
            final shineW = math.max(42.0, w * 0.34);
            final left = (w + shineW) * progress - shineW;
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFE9EEF5)),
                Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: shineW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.62),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tablet: search + tabs on top; vertical order list in the first column (beside shell rail), then
/// job detail and draft totals.
class _OrdersTabletLayout extends StatefulWidget {
  final PosViewModel vm;
  const _OrdersTabletLayout({required this.vm});

  @override
  State<_OrdersTabletLayout> createState() => _OrdersTabletLayoutState();
}

class _OrdersTabletLayoutState extends State<_OrdersTabletLayout> {
  String _selectedTab = 'All';
  final ScrollController _orderListScrollController = ScrollController();
  final _OrdersHubScrollHandle _ordersHubScroll = _OrdersHubScrollHandle();

  static const double _kOrderListColumnWidth = 188;
  static const double _kOrdersHubSearchBarWidth = 188;
  static const double _kOrdersHubTabsWidth = 400;

  @override
  void dispose() {
    _orderListScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.vm.ordersListTab;
  }

  void _setSelectedTab(String title) {
    if (_selectedTab == title) return;
    setState(() => _selectedTab = title);
    widget.vm.setOrdersListTab(title);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final l10n = AppLocalizations.of(context)!;
    // Stay on All after mark-complete / invoice (VM calls setOrdersListTab('All')).
    if (_selectedTab != vm.ordersListTab) {
      _selectedTab = vm.ordersListTab;
    }

    final listableOrders = _ordersHubListable(vm);
    final searchVisibleOrders = _ordersHubAfterSearch(vm);
    int pendingCount = 0;
    int completedCount = 0;
    for (final order in listableOrders) {
      if (order.jobsAggregateBadgeLabel == 'COMPLETED') {
        completedCount++;
      } else {
        pendingCount++;
      }
    }

    final filteredOrders = searchVisibleOrders.where((order) {
      if (_selectedTab == 'All') return true;
      final isCompleted = order.jobsAggregateBadgeLabel == 'COMPLETED';
      if (_selectedTab == 'Pending') {
        return !isCompleted;
      } else {
        return isCompleted;
      }
    }).toList();

    _ordersHubScroll.onViewModelTick(
      vm,
      filteredOrders,
      _orderListScrollController,
    );

    final fetchError = vm.ordersFetchError;
    final showFetchError =
        fetchError != null && vm.ordersApiFetchCompleted;

    if (_shouldShowOrdersHubFullEmptyState(vm)) {
      if (showFetchError) {
        return ColoredBox(
          color: const Color(0xFFFBFBFD),
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: () => widget.vm.refreshOrdersScreen(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: _OrdersFetchErrorStateBody(
                          message: fetchError,
                          onRetry: widget.vm.refreshOrdersScreen,
                          onDismiss: widget.vm.dismissOrdersFetchError,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
      return ColoredBox(
        color: const Color(0xFFFBFBFD),
        child: RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: () => widget.vm.refreshOrdersScreen(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: _OrdersEmptyStateBody(
                        title: AppLocalizations.of(context)!.posOrdersNoOrdersFound,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    final selectedInFilter = vm.selectedOrder != null &&
        filteredOrders.any((o) => o.id == vm.selectedOrder!.id);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showFetchError)
                _OrdersFetchErrorBanner(
                  message: fetchError,
                  onRetry: widget.vm.refreshOrdersScreen,
                  onDismiss: widget.vm.dismissOrdersFetchError,
                  padding: const EdgeInsets.fromLTRB(6, 8, 14, 0),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: _kOrdersHubSearchBarWidth,
                      child: PosWorkshopSearchBar(
                        hintText: AppLocalizations.of(context)!
                            .posOrdersSearchPlateNameId,
                        onChanged: (val) => vm.setOrderSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: _kOrdersHubTabsWidth,
                      child: PosSegmentedListTabs(
                        padding: EdgeInsets.zero,
                        layout: PosSegmentedTabLayout.expanded,
                        containerColor: Colors.white,
                        unselectedTabColor: Colors.white,
                        tabs: [
                          PosSegmentedTab(
                            id: 'All',
                            label: l10n.posOrdersTabAll,
                            count: listableOrders.length,
                          ),
                          PosSegmentedTab(
                            id: 'Pending',
                            label: l10n.posOrdersTabPending,
                            count: pendingCount,
                          ),
                          PosSegmentedTab(
                            id: 'Completed',
                            label: l10n.posOrdersTabCompleted,
                            count: completedCount,
                          ),
                        ],
                        selectedId: _selectedTab,
                        onSelected: _setSelectedTab,
                      ),
                    ),
                    const Spacer(),
                    _OrdersNewOrderButton(),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8ECF3)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: SizedBox(
                        width: _kOrderListColumnWidth,
                        child: ColoredBox(
                          color: Colors.white,
                          child: filteredOrders.isEmpty &&
                                  _ordersHubHasActiveSearch(vm)
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      l10n.posOrdersSearchNoMatch,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  color: AppColors.primaryLight,
                                  onRefresh: () =>
                                      widget.vm.refreshOrdersScreen(),
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      _ordersLoadMoreWhenNearTop(
                                        widget.vm,
                                        notification,
                                        _orderListScrollController,
                                      );
                                      return false;
                                    },
                                    child: ListView.separated(
                                      controller: _orderListScrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        6,
                                        10,
                                        14,
                                      ),
                                      itemCount: filteredOrders.length +
                                          (widget.vm.isLoadingMoreOrders
                                              ? 1
                                              : 0),
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        // Older pages prepend, so the spinner
                                        // leads the list.
                                        if (widget.vm.isLoadingMoreOrders) {
                                          if (index == 0) {
                                            return const _OrdersPaginationLoader();
                                          }
                                          index -= 1;
                                        }
                                        final listOrder = filteredOrders[index];
                                        final order =
                                            (vm.selectedOrder?.id.trim() ==
                                                    listOrder.id.trim())
                                                ? vm.selectedOrder!
                                                : listOrder;
                                        final isSelected =
                                            vm.selectedOrder?.id == order.id;
                                        final scrollKey =
                                            _ordersHubScroll.keyForOrderId(
                                          order.id,
                                          vm,
                                        );
                                        return KeyedSubtree(
                                          key: scrollKey,
                                          child: _HorizontalOrderTile(
                                            order: order,
                                            isSelected: isSelected,
                                            fullWidth: true,
                                            onTap: () =>
                                                vm.selectOrder(listOrder),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const VerticalDivider(
                        width: 1, color: Color(0xFFE8ECF3)),
                    Expanded(
                      flex: 3,
                      child: ColoredBox(
                        color: Colors.white,
                        child: _OrderDetailPanel(
                          vm: vm,
                          filteredOrders: filteredOrders,
                          selectedTab: _selectedTab,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE8ECF3)),
        SizedBox(
          width: _kPosOrdersHubSummaryColumnWidth,
          child: ColoredBox(
            color: const Color(0xFFFBFBFD),
            child: !selectedInFilter
                ? const SizedBox.expand()
                : Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              child: _OrderSummaryPanel(vm: vm),
            ),
          ),
        ),
      ],
    );
  }
}

/// SoftPOS / prepaid status — only shown after payment (no UNPAID banner).
class _OrdersPaymentStatusBanner extends StatelessWidget {
  final PosOrder order;
  final double grandTotal;
  const _OrdersPaymentStatusBanner({
    required this.order,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    if (!order.isPosPrepaid) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final amount = order.posPrepaidAmount ?? grandTotal;
    final method = order.prepaidPaymentMethodLabel.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF2E7D32),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.billingStatusPaid.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.3,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method.isNotEmpty
                      ? '${l10n.posOrdersPaidAmount(amount.toStringAsFixed(2))} · ${l10n.posOrdersPaidVia(method)}'
                      : l10n.posOrdersPaidAmount(amount.toStringAsFixed(2)),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit customer + maintenance checklist (same row in order summary footer).
class _OrdersHeaderCustomerPaymentRow extends StatelessWidget {
  final PosViewModel vm;
  final PosOrder order;
  final bool showPaymentMethodButton;
  final bool paymentSelectionLocked;
  const _OrdersHeaderCustomerPaymentRow({
    required this.vm,
    required this.order,
    required this.showPaymentMethodButton,
    this.paymentSelectionLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PosViewModel>(
      builder: (context, posVm, _) => _buildContent(context, posVm),
    );
  }

  Widget _buildContent(BuildContext context, PosViewModel posVm) {
    final order = _liveOrderForHubRow(posVm);
    final enabled = order != null;
    final invoicingThisOrder =
        order != null && posVm.isInvoicingOrder(order.id);
    final isRejectedCorporateOrder = order != null &&
        order.isCorporateWalkIn &&
        order.isRejectedByCorporate;
    // Only block payment for corporate **walk-in** while waiting on corporate approval
    // (or rejected). Corporate bookings and post-approval walk-in behave like normal checkout.
    final corporateBillingLocked = order != null &&
        order.isCorporateWalkIn &&
        !order.isCorporateBookingOrder &&
        (order.isCorporateUnapproved ||
            order.isWaitingCorporateApproval ||
            order.isRejectedByCorporate);

    Future<void> openCheckoutDetails() async {
      if (order == null || invoicingThisOrder) return;
      final lockPayment = paymentSelectionLocked || order.isPosPrepaid;
      final saved = await applyOrdersCheckoutDetailsDialog(
        context: context,
        order: order,
        posVm: posVm,
        showPaymentSection: showPaymentMethodButton,
        paymentSelectionLocked: lockPayment,
      );
      if (!context.mounted || !saved) return;
      ToastService.showSuccess(
        context,
        lockPayment || !showPaymentMethodButton
            ? AppLocalizations.of(context)!.posOrdersCustomerDetailsSaved
            : AppLocalizations.of(context)!.posOrdersCheckoutSaved,
      );
    }

    final canOpen = enabled &&
        !invoicingThisOrder &&
        !isRejectedCorporateOrder &&
        (!showPaymentMethodButton || !corporateBillingLocked);

    final checklistEnabled = !posVm.isLoading && !invoicingThisOrder;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: canOpen ? openCheckoutDetails : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.onPrimaryLight,
                disabledBackgroundColor: const Color(0xFFE8ECF3),
                disabledForegroundColor: const Color(0xFF94A3B8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.posOrdersEditCustomerDetails,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: AppColors.onPrimaryLight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: checklistEnabled
                  ? () => _showOrdersMaintenanceChecklistDialog(context, order)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryLight,
                side: BorderSide(color: Colors.blueGrey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.posOrdersChecklistOptional,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PosOrder _liveOrderForHubRow(PosViewModel posVm) {
    final id = order.id.trim();
    if (id.isEmpty) return order;
    if (posVm.selectedOrder?.id.trim() == id) return posVm.selectedOrder!;
    for (final o in posVm.orders) {
      if (o.id.trim() == id) return o;
    }
    return order;
  }
}

/// Centered title + [New Order] for empty order list (tablet + mobile).
class _OrdersEmptyStateBody extends StatelessWidget {
  final String title;

  _OrdersEmptyStateBody({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          _OrdersNewOrderButton(),
        ],
      ),
    );
  }
}

/// Full-screen empty state when GET /cashier/orders fails.
class _OrdersFetchErrorStateBody extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;

  const _OrdersFetchErrorStateBody({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          _OrdersFetchErrorBanner(
            message: message,
            onRetry: onRetry,
            onDismiss: onDismiss,
            padding: EdgeInsets.zero,
            showRetryButton: true,
          ),
          const SizedBox(height: 20),
          _OrdersNewOrderButton(),
        ],
      ),
    );
  }
}

class _OrdersFetchErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;
  final EdgeInsetsGeometry padding;
  final bool showRetryButton;

  const _OrdersFetchErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.showRetryButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade800,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedApiText(
                    message,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.red.shade800,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (showRetryButton) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(onRetry()),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Colors.red.shade800,
                  ),
                  label: Text(
                    l10n.posOrdersRefreshOrders,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrdersNewOrderButton extends StatelessWidget {
  _OrdersNewOrderButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCC247),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          final vm = context.read<PosViewModel>();
          vm.clearCustomerData();
          vm.clearEditOrderContext();
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const PosAddCustomerView(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFCC247).withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Color(0xFF23262D), size: 16),
              const SizedBox(width: 5),
              Text(
                AppLocalizations.of(context)!.posOrdersNewOrder,
                style: TextStyle(
                  color: Color(0xFF23262D),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Job status chip — same look in department cards and ORDER SUMMARY.
Widget posOrdersJobStatusBadge(BuildContext context, String statusRaw) {
  var s = statusRaw.toLowerCase().replaceAll(' ', '_');
  if (s == 'complete') s = 'completed';
  if (s == 'job_edited') s = 'edited';
  final isRejected =
      s == 'rejected_by_corporate' ||
          s == 'rejected' ||
          statusRaw.toLowerCase().contains('rejected');
  final isComplete = s == 'completed' || s == 'invoiced';
  final isEdited = s == 'edited';
  final isCancelled = s == 'cancelled' || s == 'canceled';
  final isInProgress =
      s == 'in_progress' || s == 'inprogress' || statusRaw.toLowerCase() == 'in progress';

  late Color fg;
  late Color bg;
  late Color border;
  late String label;

  if (isRejected) {
    fg = Colors.white;
    bg = const Color(0xFFD32F2F);
    border = const Color(0xFFB71C1C);
    label = 'REJECTED';
  } else if (isCancelled) {
    fg = Colors.white;
    bg = const Color(0xFFD32F2F);
    border = const Color(0xFFB71C1C);
    label = 'CANCELLED';
  } else if (isComplete) {
    fg = Colors.white;
    bg = const Color(0xFF4CAF50);
    border = const Color(0xFF388E3C);
    label = 'COMPLETE';
  } else if (isEdited) {
    fg = Colors.white;
    bg = const Color(0xFF4CAF50);
    border = const Color(0xFF388E3C);
    label = 'EDITED';
  } else if (isInProgress) {
    fg = Colors.white;
    bg = AppColors.primaryLight;
    border = const Color(0xFFE6B03A);
    label = 'IN PROGRESS';
  } else {
    fg = Colors.white;
    bg = const Color(0xFFFF9800);
    border = const Color(0xFFF57C00);
    label = 'PENDING';
  }

  final textStyle = TextStyle(
    fontSize: 8.5,
    fontWeight: FontWeight.w800,
    color: fg,
    letterSpacing: 0.45,
  );

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: border),
    ),
    child: Text(_ordersTranslatedStatusLabel(context, label), style: textStyle),
  );
}

/// Same in-progress rule as [posOrdersJobStatusBadge]; [statusRaw] is trimmed so detection matches the chip.
bool _posOrdersStatusIsInProgress(String statusRaw) {
  final t = statusRaw.trim();
  var s = t.toLowerCase().replaceAll(' ', '_');
  if (s == 'complete') s = 'completed';
  if (s == 'job_edited') s = 'edited';
  return s == 'in_progress' ||
      s == 'inprogress' ||
      t.toLowerCase() == 'in progress';
}

class _OrderDetailPanel extends StatelessWidget {
  final PosViewModel vm;
  final List<PosOrder> filteredOrders;
  final String selectedTab;

  const _OrderDetailPanel({
    required this.vm,
    required this.filteredOrders,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context) {
    final hasListable = _ordersHubListable(vm).isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    if (filteredOrders.isEmpty && hasListable) {
      final emptyMessage = _ordersHubHasActiveSearch(vm)
          ? l10n.posOrdersSearchNoMatch
          : _ordersTabDetailEmptyMessage(l10n, selectedTab);
      return ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }

    final sel = vm.selectedOrder;
    final order = sel != null &&
        filteredOrders.any((o) => o.id == sel.id)
        ? sel
        : null;

    return Column(
      children: [
        if (order == null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assignment_rounded, size: 64, color: Colors.grey.shade200),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.posOrdersNoOrderSelected,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.posOrdersSelectFromList,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const pad = EdgeInsets.fromLTRB(18, 10, 18, 18);
                const crossSpacing = 12.0;
                const runSpacing = 12.0;
                final innerW = constraints.maxWidth - pad.horizontal;
                final tileW = (innerW - crossSpacing) / 2;
                final showAdd = _canAddDepartmentToOrder(order);
                final hasRealJobs =
                order.jobs.any((j) => !j.isCancelledJob);
                final showCorporateProposalCards = order.isCorporateWalkIn &&
                    !hasRealJobs &&
                    order.selectedDepartmentNames.isNotEmpty;

                final items = [
                  for (final j in order.jobs.where((j) => !j.isCancelledJob))
                    _JobCard(order: order, job: j),
                  if (showCorporateProposalCards)
                    for (final dept in order.selectedDepartmentEntries)
                      _CorporatePendingJobCard(
                        order: order,
                        departmentName: dept['name'] ?? '',
                        departmentId: dept['id'] ?? '',
                      ),
                  if (showAdd) _AddDepartmentCard(order: order),
                ];

                return SingleChildScrollView(
                  padding: pad,
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i += 2) ...[
                        if (i > 0) SizedBox(height: runSpacing),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: items[i]),
                              const SizedBox(width: crossSpacing),
                              Expanded(
                                child: i + 1 < items.length
                                    ? items[i + 1]
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

String _normalizeDeptKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _canAddDepartmentToOrder(PosOrder order) {
  if (order.id.trim().isEmpty) return false;
  final src = order.source.toLowerCase().replaceAll('-', '_');
  if (!src.contains('walk')) return false;
  if (order.isCorporateWalkIn && order.isRejectedByCorporate) return false;
  final st = order.status.toLowerCase();
  if (st == 'invoiced' || st == 'cancelled' || st == 'completed' || st == 'edited') return false;
  if ((order.invoiceNo ?? '').trim().isNotEmpty) return false;
  return true;
}

Future<void> _onAddDepartmentTap(BuildContext context, PosOrder order) async {
  if (!_canAddDepartmentToOrder(order)) return;

  final deptVm = context.read<DepartmentViewModel>();
  if (deptVm.departments.isEmpty) {
    await deptVm.fetchDepartments();
  }
  if (!context.mounted) return;

  final blockedIds = <String>{};
  final blockedNameKeys = <String>{};
  for (final j in order.jobs) {
    if (j.isCancelledJob) continue;
    final r = _resolveDepartmentForJob(context, j);
    if (r != null) {
      blockedIds.add(r.id);
      blockedNameKeys.add(_normalizeDeptKey(r.name));
    } else if (j.department.trim().isNotEmpty) {
      blockedNameKeys.add(_normalizeDeptKey(j.department));
    }
  }

  final anyAvailable = deptVm.departments.any((d) {
    if (!d.isActive) return false;
    if (blockedIds.contains(d.id)) return false;
    if (blockedNameKeys.contains(_normalizeDeptKey(d.name))) return false;
    return true;
  });
  if (!anyAvailable) {
    ToastService.showError(context, 'No departments available to add.');
    return;
  }

  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PosDepartmentView(
        addJobsToOrderId: order.id,
        excludedDepartmentIds: blockedIds.toList(),
        excludedNormalizedNameKeys: blockedNameKeys.toList(),
      ),
    ),
  );
}

class _AddDepartmentCard extends StatelessWidget {
  final PosOrder order;
  const _AddDepartmentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onAddDepartmentTap(context, order),
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0xFFC5CAD3),
            strokeWidth: 1.5,
            borderRadius: 14,
            dashPattern: [6, 4],
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFFFCC247), size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.posOrdersAddDepartment,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CorporatePendingJobCard extends StatelessWidget {
  final PosOrder order;
  final String departmentName;
  final String departmentId;
  const _CorporatePendingJobCard({
    required this.order,
    required this.departmentName,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    final isRejectedCorporateOrder =
        order.isCorporateWalkIn && order.isRejectedByCorporate;
    final orderItems = order.items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final deptId = departmentId.trim();
    final deptNameLower = departmentName.trim().toLowerCase();
    final deptItems = orderItems.where((item) {
      final itemDeptId = (item['departmentId'] ?? '').toString().trim();
      final itemDeptName =
      (item['departmentName'] ?? '').toString().trim().toLowerCase();
      if (deptId.isNotEmpty && itemDeptId.isNotEmpty) {
        return itemDeptId == deptId;
      }
      return itemDeptName == deptNameLower;
    }).toList();
    final hasDeptItems = deptItems.isNotEmpty;
    final deptItemCount = deptItems.length;
    final deptTotal = deptItems.fold<double>(0.0, (sum, item) {
      final lineTotal = double.tryParse(item['lineTotal']?.toString() ?? '');
      if (lineTotal != null) return sum + lineTotal;
      final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
      final unitPrice =
          double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0;
      return sum + (qty * unitPrice);
    });

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Color(0xFFFF9800),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LocalizedApiText(
                          departmentName,
                          uppercase: Localizations.localeOf(context).languageCode != 'ar',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.35,
                            color: Color(0xFF1E2124),
                          ),
                        ),
                        const SizedBox(height: 6),
                        posOrdersJobStatusBadge(context, 'pending'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 5),
              child: Column(
                children: [
                  _ModernActionChip(
                    icon: Icons.add_shopping_cart_rounded,
                    label: hasDeptItems
                        ? AppLocalizations.of(context)!.posOrdersItemCount(deptItemCount)
                        : AppLocalizations.of(context)!.posOrdersProductsAndServices,
                    trailing: hasDeptItems
                        ? Text(
                      AppLocalizations.of(context)!.posCommonSarAmount(deptTotal.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2124),
                      ),
                    )
                        : null,
                    onTap: () async {
                      if (isRejectedCorporateOrder) {
                        ToastService.showError(
                          context,
                          AppLocalizations.of(context)!.posOrdersRejectedCorporateReadOnly,
                        );
                        return;
                      }
                      final vm = context.read<PosViewModel>();
                      vm.primeCorporateWalkInDraftFromOrder(order);
                      vm.clearCart();
                      PosOrderJob? matchedJob;

                      PosOrder sourceOrder = order;
                      var latestOrder = await vm.loadCashierOrderDetail(order.id);
                      if (latestOrder != null) {
                        sourceOrder = latestOrder;
                      }

                      for (final j in sourceOrder.jobs) {
                        final jid = (j.departmentId ?? '').trim();
                        final jname = j.department.trim().toLowerCase();
                        final wantId = departmentId.trim();
                        final wantName = departmentName.trim().toLowerCase();
                        if (wantId.isNotEmpty && jid.isNotEmpty && jid == wantId) {
                          matchedJob = j;
                          break;
                        }
                        if (jname.isNotEmpty && jname == wantName) {
                          matchedJob = j;
                          break;
                        }
                      }

                      if (matchedJob != null && matchedJob.id.trim().isNotEmpty) {
                        final preSelected = <dynamic>[];
                        for (final item in matchedJob.items) {
                          preSelected.add({
                            item.itemType == 'service' ? 'serviceId' : 'productId':
                            item.productId,
                            'quantity': item.qty,
                            'discountType': item.discountType,
                            'discountValue': item.discountValue ?? 0.0,
                            if (item.unitPrice > 0) 'unitPrice': item.unitPrice,
                          });
                        }
                        vm.setEditOrderContext(
                          departmentId: departmentId.trim().isNotEmpty
                              ? departmentId
                              : (matchedJob.departmentId ?? ''),
                          preSelectedItems: preSelected,
                          order: sourceOrder,
                          completingOrderId: matchedJob.id,
                        );
                      } else {
                        vm.clearEditOrderContext(notify: false);
                        if (context.mounted) {
                          ToastService.showError(
                            context,
                            'Job ID not available for this department yet. Pricing API cannot run without job.',
                          );
                        }
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PosProductGridView(
                            departmentName: departmentName,
                            departmentId:
                            departmentId.trim().isNotEmpty ? departmentId : null,
                            selectedDepartmentIds: order.selectedDepartmentEntries
                                .map((e) => e['id'] ?? '')
                                .where((id) => id.trim().isNotEmpty)
                                .toList(),
                            selectedDepartmentNames: order.selectedDepartmentEntries
                                .map((e) => e['name'] ?? '')
                                .where((name) => name.trim().isNotEmpty)
                                .toList(),
                            completingOrder: matchedJob != null ? sourceOrder : null,
                            completingOrderId: matchedJob?.id,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _ModernActionChip(
                    icon: Icons.engineering_rounded,
                    label: AppLocalizations.of(context)!.posOrdersAssignTechnicians,
                    onTap: () => ToastService.showError(
                      context,
                      isRejectedCorporateOrder
                          ? AppLocalizations.of(context)!.posOrdersRejectedCorporateReadOnly
                          : 'This corporate walk-in has no job yet. Wait for corporate approval, then assign technicians.',
                    ),
                  ),
                ],
              ),
            ),
            if (!isRejectedCorporateOrder) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _JobFooterButton(
                        label: AppLocalizations.of(context)!.posCommonCancel,
                        backgroundColor: const Color(0xFF23262D),
                        textColor: Colors.white,
                        enabled: true,
                        onTap: () => showCashierCancelOrderDialog(context, order.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _JobFooterButton(
                        label: AppLocalizations.of(context)!.posOrdersMarkComplete,
                        backgroundColor: const Color(0xFFFCC247),
                        textColor: const Color(0xFF23262D),
                        enabled: true,
                        onTap: () => ToastService.showError(
                          context,
                          'Corporate order must be approved before completing jobs.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final List<double> dashPattern;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final segment in _calculateDashes(path, dashPattern)) {
      canvas.drawPath(segment, paint);
    }
  }

  List<Path> _calculateDashes(Path source, List<double> pattern) {
    final List<Path> result = [];
    final PathMetrics metrics = source.computeMetrics();
    for (final PathMetric metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = pattern[result.length % pattern.length];
        if (draw) {
          result.add(metric.extractPath(distance, distance + len));
        }
        distance += len;
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Resolved department id + display name for a job (job payload → line items → department list → catalog).
({String id, String name})? _resolveDepartmentForJob(BuildContext context, PosOrderJob job) {
  final posVm = context.read<PosViewModel>();
  final deptVm = context.read<DepartmentViewModel>();

  String deptId = job.departmentId?.trim() ?? '';
  String deptName = job.department;

  for (final item in job.items) {
    if (item.departmentId.isNotEmpty) {
      deptId = item.departmentId;
      if (item.departmentName.isNotEmpty) {
        deptName = item.departmentName;
      }
      break;
    }
  }

  if (deptId.isEmpty && deptVm.departments.isNotEmpty) {
    final jobKey = _normalizeDeptKey(job.department);
    for (final d in deptVm.departments) {
      final dk = _normalizeDeptKey(d.name);
      if (dk == jobKey || dk.contains(jobKey) || jobKey.contains(dk)) {
        deptId = d.id;
        deptName = d.name;
        break;
      }
    }
  }

  if (deptId.isEmpty && posVm.allProducts.isNotEmpty) {
    final jobKey = _normalizeDeptKey(job.department);
    for (final p in posVm.allProducts) {
      final pd = (p.departmentId ?? '').trim();
      if (pd.isEmpty) continue;
      final pKey = _normalizeDeptKey(p.departmentName ?? '');
      if (pKey == jobKey || pKey.contains(jobKey) || jobKey.contains(pKey)) {
        deptId = pd;
        if ((p.departmentName ?? '').trim().isNotEmpty) {
          deptName = p.departmentName!.trim();
        }
        break;
      }
    }
  }

  if (deptId.isEmpty) return null;
  return (id: deptId, name: deptName);
}

void _openJobTechnicianAssignment(BuildContext context, PosOrder order, PosOrderJob job) {
  final resolved = _resolveDepartmentForJob(context, job);
  if (resolved == null) {
    ToastService.showError(
      context,
      'Could not resolve department for "${job.department}".',
    );
    return;
  }
  if (job.id.trim().isEmpty) {
    ToastService.showError(context, 'Job ID missing.');
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  showPosOrdersHubDialog(
    context: context,
    title: l10n.posNavTechnicians,
    variant: PosOrdersHubDialogVariant.assignTechnician,
    child: PosTechnicianAssignmentView(
      jobId: job.id,
      departmentName: resolved.name,
      departmentId: resolved.id,
      isWalkIn: false,
      initialAssignedTechnicians: job.distinctActiveTechnicians,
      embeddedInOrdersHubDialog: true,
    ),
  );
}

Future<void> _openJobProductGrid(
  BuildContext context,
  PosOrder order,
  PosOrderJob job,
) async {
  final posVm = context.read<PosViewModel>();

  if (posVm.vehicleNumber.trim().isEmpty && order.plateNumber.trim().isEmpty) {
    ToastService.showError(
      context,
      AppLocalizations.of(context)!.posOrdersPleaseAddVehicleFirst,
    );
    return;
  }

  final resolved = _resolveDepartmentForJob(context, job);
  if (resolved == null) {
    ToastService.showError(
      context,
      'Could not resolve department for "${job.department}".',
    );
    return;
  }
  final deptId = resolved.id.trim();
  final deptName = resolved.name;

  final preSelected = <dynamic>[];
  for (final item in dedupeCashierServiceLinesForPosDisplay(job.items)) {
    preSelected.add({
      item.itemType == 'service' ? 'serviceId' : 'productId': item.productId,
      'quantity': item.qty,
      'discountType': item.discountType,
      'discountValue': item.discountValue ?? 0.0,
      if (item.unitPrice > 0) 'unitPrice': item.unitPrice,
    });
  }

  posVm.clearCart();
  if (order.isCorporateWalkIn || order.isCorporateBookingOrder) {
    posVm.primeCorporateWalkInDraftFromOrder(order);
  } else {
    posVm.clearCorporatePricingContext();
    posVm.setCustomerData(
      name: order.customerName,
      vat: order.customer?.vatNumber ?? '',
      mobile: order.customer?.mobile ?? '',
      vehicleNumber: order.plateNumber.trim().isNotEmpty ? order.plateNumber : posVm.vehicleNumber,
      vinNumber: order.vehicle?.vin ?? '',
      make: order.vehicle?.make ?? '',
      model: order.vehicle?.model ?? '',
      odometer: order.odometerReading,
      previousOrderId: order.id,
      vehicleYear: order.vehicle?.year ?? '',
      vehicleColor: order.vehicle?.color ?? '',
    );
  }
  posVm.setEditOrderContext(
    departmentId: deptId,
    preSelectedItems: preSelected,
    order: order,
    completingOrderId: job.id,
  );

  if (!context.mounted) return;

  // Catalog loads inside PosProductGridView (overlay loader there), not before open.
  showPosOrdersHubDialog(
    context: context,
    title: deptName.trim().isNotEmpty
        ? deptName
        : AppLocalizations.of(context)!.posOrdersProductsAndServices,
    variant: PosOrdersHubDialogVariant.productsAndServices,
    catalogSyncDepartmentId: deptId,
    child: PosProductGridView(
      departmentName: deptName,
      departmentId: deptId,
      selectedDepartmentIds: [deptId],
      selectedDepartmentNames: [deptName],
      preSelectedItems: preSelected,
      completingOrderId: job.id,
      completingOrder: order,
      showBackButton: false,
      embeddedInOrdersHubDialog: true,
      resizeForKeyboard: false,
    ),
  );
}

Future<void> _onMarkJobComplete(
    BuildContext context,
    PosOrder order,
    PosOrderJob job,
    ) async {
  Future<PosOrder> resolveLatestOrderSnapshot() async {
    final vm = context.read<PosViewModel>();
    final oid = order.id.trim();
    if (oid.isEmpty) return order;
    try {
      return vm.orders.firstWhere((o) => o.id.trim() == oid);
    } catch (_) {
      // Corporate flows: after pricing edits, the hub list can lag behind while
      // the dialog UI already shows new lines. Fetch authoritative detail.
      final detail = await vm.loadCashierOrderDetail(oid);
      return detail ?? order;
    }
  }

  PosOrderJob resolveLatestJobSnapshot(PosOrder latestOrder) {
    final jid = job.id.trim();
    if (jid.isEmpty) return job;
    try {
      return latestOrder.jobs.firstWhere((j) => j.id.trim() == jid);
    } catch (_) {
      return job;
    }
  }

  List<PosOrderJobItem> resolveJobItems({
    required PosOrder latestOrder,
    required PosOrderJob liveJob,
  }) {
    if (liveJob.items.isNotEmpty) return liveJob.items;
    // Corporate flows sometimes hydrate billable lines at order-level (`order.items`)
    // while the job snapshot stays stale in the UI tree.
    final raw = latestOrder.items;
    if (raw.isEmpty) return const [];
    final parsed = <PosOrderJobItem>[];
    for (final it in raw) {
      if (it is! Map) continue;
      parsed.add(PosOrderJobItem.fromJson(Map<String, dynamic>.from(it)));
    }
    final jobId = liveJob.id.trim();
    final deptId = (liveJob.departmentId ?? '').trim();
    final filtered = parsed.where((i) {
      final iid = (i.jobId ?? '').trim();
      if (iid.isNotEmpty) return iid == jobId;
      // Fallback: unassigned jobId lines — keep only if department matches.
      if (deptId.isEmpty) return false;
      return i.departmentId.trim() == deptId;
    }).toList();
    return dedupeCashierServiceLinesForPosDisplay(filtered);
  }

  final latestOrder = await resolveLatestOrderSnapshot();
  final liveJob = resolveLatestJobSnapshot(latestOrder);
  final effectiveItems = resolveJobItems(latestOrder: latestOrder, liveJob: liveJob);

  if (order.isCorporateWalkIn &&
      !order.isCorporateBookingOrder &&
      (order.isCorporateUnapproved ||
          order.isWaitingCorporateApproval ||
          order.isRejectedByCorporate)) {
    ToastService.showError(
      context,
      'Corporate order must be approved before completing jobs.',
    );
    return;
  }
  // If server snapshots have no billable lines, completing will fail anyway. Route the cashier
  // back to Products/Services so they can press Save (persist pricing) first.
  if (effectiveItems.isEmpty) {
    ToastService.showError(
      context,
      AppLocalizations.of(context)!.posOrdersThisJobNoLineItems,
    );
    _openJobProductGrid(context, latestOrder, liveJob);
    return;
  }

  // Ensure technicians are assigned
  if (liveJob.distinctActiveTechnicians.isEmpty) {
    ToastService.showError(context, 'Technician assignment is required.');
    return;
  }
  final vm = context.read<PosViewModel>();
  final response = await vm.completeCashierJob(
    liveJob.id,
    sourceOrder: latestOrder,
  );
  if (!context.mounted) return;
  if (response != null && response.success) {
    ToastService.showSuccess(
      context,
      response.message.isNotEmpty ? response.message : 'Job marked complete',
    );
  } else {
    final msg = (response?.message ?? '').toLowerCase();
    if (msg.contains('no billable') || msg.contains('no line') || msg.contains('add products')) {
      _openJobProductGrid(context, latestOrder, liveJob);
    }
    ToastService.showError(
      context,
      response?.message ?? 'Failed to complete job',
    );
  }
}

Future<void> _onCancelJob(
  BuildContext context,
  PosOrderJob job,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showPosOrdersCompactConfirmDialog(
    context,
    title: l10n.posOrdersDeleteJobTitle,
    body: l10n.posOrdersDeleteJobBody,
    confirmLabel: l10n.posOrdersYesDeleteBtn,
    onConfirm: () async {
      final vm = context.read<PosViewModel>();
      return vm.cancelCashierJob(context, job.id);
    },
  );
}

class _JobCard extends StatelessWidget {
  final PosOrder order;
  final PosOrderJob job;
  const _JobCard({required this.order, required this.job});

  IconData _getDepartmentIcon(String dept) {
    final d = dept.toLowerCase();
    if (d.contains('mechanical')) return Icons.build_rounded;
    if (d.contains('paint') || d.contains('body')) return Icons.format_paint_rounded;
    if (d.contains('electrical')) return Icons.electrical_services_rounded;
    if (d.contains('wash') || d.contains('detail')) return Icons.local_car_wash_rounded;
    if (d.contains('ac')) return Icons.ac_unit_rounded;
    return Icons.settings_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusForUi =
    (order.isCorporateWalkIn && order.isRejectedByCorporate)
        ? order.status
        : job.status;
    var st = job.status.toLowerCase().trim();
    if (st == 'complete') st = 'completed';
    if (st == 'job_edited') st = 'edited';
    final isInvoiced = st == 'invoiced';
    final isComplete = st == 'completed';
    final isEdited = st == 'edited';
    final isInProgressCard = _posOrdersStatusIsInProgress(statusForUi);
    final isCancelled = job.isCancelledJob;
    final isRejectedCorporateOrder =
        order.isCorporateWalkIn && order.isRejectedByCorporate;
    final isLocked = isInvoiced || isCancelled || isRejectedCorporateOrder;

    final jobLineItems = dedupeCashierServiceLinesForPosDisplay(job.items);
    final hasLineItems = jobLineItems.isNotEmpty;
    final lineItemCount = jobLineItems.length;
    // Department card stays pre-promo so it matches Order Summary job totals.
    // Invoice-level promo is shown only on the order footer.
    final jobPrePromoExVat = _draftJobPrePromoSubtotalExVat(job);
    final jobPrePromoVat = job.vatPercent > 0
        ? jobPrePromoExVat * (job.vatPercent / 100.0)
        : 0.0;
    final jobTotalDisplay = jobPrePromoExVat + jobPrePromoVat;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Premium Header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isComplete || isEdited)
                          ? const Color(0xFFE8F5E9)
                          : isInProgressCard
                          ? AppColors.primaryLight.withValues(alpha: 0.28)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getDepartmentIcon(job.department),
                      color: (isComplete || isEdited)
                          ? const Color(0xFF4CAF50)
                          : isInProgressCard
                          ? AppColors.primaryLight
                          : const Color(0xFFFF9800),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LocalizedApiText(
                          job.department,
                          uppercase: Localizations.localeOf(context).languageCode != 'ar',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.35,
                            color: Color(0xFF1E2124),
                          ),
                        ),
                        const SizedBox(height: 6),
                        posOrdersJobStatusBadge(context, statusForUi),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 2. Action Chips (no Expanded — avoids empty stretch above footer)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModernActionChip(
                    icon: Icons.add_shopping_cart_rounded,
                    label: hasLineItems
                        ? AppLocalizations.of(context)!.posOrdersItemCount(lineItemCount)
                        : AppLocalizations.of(context)!.posOrdersProductsAndServices,
                    trailing: hasLineItems
                        ? Builder(
                      builder: (ctx) {
                        final langCode = Localizations.localeOf(ctx).languageCode;
                        return Text(
                          AppLocalizations.of(ctx)!.posCommonSarAmount(
                            AppTranslationService.localizeDigitsForLanguage(
                              jobTotalDisplay.toStringAsFixed(2),
                              langCode,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2124),
                          ),
                        );
                      },
                    )
                        : null,
                    onTap: isLocked
                        ? () => ToastService.showError(
                      context,
                      AppLocalizations.of(context)!.posOrdersJobCannotBeEdited,
                    )
                        : () => _openJobProductGrid(
                      context,
                      order,
                      job,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ModernActionChip(
                    icon: Icons.engineering_rounded,
                    label: job.distinctActiveTechnicians.isEmpty
                        ? AppLocalizations.of(context)!.posOrdersAssignTechnicians
                        : AppLocalizations.of(context)!.posOrdersTechnicianCount(job.distinctActiveTechnicians.length),
                    onTap: isLocked
                        ? () => ToastService.showError(
                      context,
                      AppLocalizations.of(context)!.posOrdersJobCannotBeEdited,
                    )
                        : () => _openJobTechnicianAssignment(
                      context,
                      order,
                      job,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 3. Footer Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: Consumer<PosViewModel>(
                builder: (context, posVm, _) {
                  final completing = posVm.isCashierCompletingJob(job.id);
                  return Row(
                    children: [
                      if (!isInvoiced && !isComplete && !isEdited) ...[
                        Expanded(
                          child: _JobFooterButton(
                            label: AppLocalizations.of(context)!.posCommonCancel,
                            backgroundColor: isCancelled
                                ? const Color(0xFF23262D).withValues(alpha: 0.45)
                                : const Color(0xFF23262D),
                            textColor: Colors.white,
                            isBusy: false, // Cancellation happens in a dialog now
                            enabled:
                            !isCancelled && !completing && !isRejectedCorporateOrder,
                            onTap: () {
                              if (isRejectedCorporateOrder) {
                                ToastService.showError(
                                  context,
                                  AppLocalizations.of(context)!.posOrdersRejectedCorporateReadOnly,
                                );
                                return;
                              }
                              _onCancelJob(context, job);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!isInvoiced)
                        Expanded(
                          child: _JobFooterButton(
                            label: (isComplete || isEdited)
                                ? AppLocalizations.of(context)!.posOrdersEdit
                                : isCancelled
                                ? AppLocalizations.of(context)!.posOrdersStatusCancelled
                                : AppLocalizations.of(context)!.posOrdersMarkComplete,
                            backgroundColor: (isComplete || isEdited)
                                ? const Color(0xFF23262D)
                                : isCancelled
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFFFCC247),
                            textColor: (isComplete || isEdited)
                                ? Colors.white
                                : isCancelled
                                ? Colors.white
                                : const Color(0xFF23262D),
                            isBusy: (isComplete || isEdited)
                                ? false
                                : completing &&
                                !isInvoiced &&
                                !isComplete &&
                                !isEdited &&
                                !isCancelled,
                            enabled: !completing && !isRejectedCorporateOrder,
                            onTap: (isComplete || isEdited)
                                ? () {
                              if (isRejectedCorporateOrder) {
                                ToastService.showError(
                                  context,
                                  AppLocalizations.of(context)!.posOrdersRejectedCorporateReadOnly,
                                );
                                return;
                              }
                              _openJobProductGrid(
                                context,
                                order,
                                job,
                              );
                            }
                                : isCancelled
                                ? () {}
                                : () => _onMarkJobComplete(context, order, job),
                          ),
                        ),
                    ],
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

class _ModernActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  /// When null, shows the default edit (pen) icon.
  final Widget? trailing;
  /// When set, replaces the default [label] text (e.g. multi-line technicians).
  final Widget? labelWidget;

  const _ModernActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, color: const Color(0xFF64748B), size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: labelWidget ??
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: trailing ??
                    const Icon(
                      Icons.mode_edit_outline_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobFooterButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isBusy;
  /// When false, button is non-interactive (e.g. Cancel after job already cancelled).
  final bool enabled;

  const _JobFooterButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.isBusy = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: (isBusy || !enabled) ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          child: isBusy
              ? AppButtonBusy.loaderOnFill(
                  backgroundColor,
                  size: 14,
                  strokeWidth: 2,
                )
              : Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Draft totals panel: amounts follow GET /cashier/orders job & order fields (VAT excl. where noted on model). ---

String _draftFmtQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

double _draftLineDisplayTotal(PosOrderJob job, PosOrderJobItem item) {
  if (item.lineTotalExcludingVat > 0.0001) return item.lineTotalExcludingVat;
  final exVatFromUnit = _draftLineUnitPriceExVat(job, item) * item.qty;
  if (exVatFromUnit > 0.0001) return exVatFromUnit;
  if (item.lineTotal > 0) {
    final pct = job.vatPercent;
    if (pct > 0) {
      return item.lineTotal / (1.0 + pct / 100.0);
    }
    return item.lineTotal;
  }
  return item.qty * item.unitPrice;
}

/// Unit price excl. VAT for ORDER SUMMARY qty row (matches product grid cart).
double _draftLineUnitPriceExVat(PosOrderJob job, PosOrderJobItem item) {
  if (item.qty > 0.0001 && item.lineTotalExcludingVat > 0.0001) {
    return item.lineTotalExcludingVat / item.qty;
  }
  if (item.unitPriceExcludingVat > 0.0001) return item.unitPriceExcludingVat;
  final pct = job.vatPercent;
  if (pct <= 0 || item.unitPrice <= 0) return item.unitPrice;
  return item.unitPrice / (1.0 + pct / 100.0);
}

String? _draftLineDiscountLabel(PosOrderJobItem item) {
  final dv = item.discountValue ?? 0;
  if (dv <= 0) return null;
  final t = (item.discountType ?? '').toLowerCase();
  if (t == 'percent' || t == 'percentage') {
    final s = dv == dv.roundToDouble() ? dv.toInt().toString() : dv.toStringAsFixed(1);
    return 'Line discount ($s%)';
  }
  return 'Line discount';
}

/// SAR amount for the line discount row (fixed value or % of `qty × unitPrice`).
double? _draftLineDiscountAmountSar(PosOrderJobItem item) {
  final dv = item.discountValue ?? 0;
  if (dv <= 0) return null;
  final t = (item.discountType ?? '').toLowerCase();
  if (t == 'percent' || t == 'percentage') {
    final base = item.qty * item.unitPrice;
    if (base <= 0) return null;
    return base * (dv / 100.0);
  }
  return dv;
}

double _draftJobOrderLevelDiscountAmount(PosOrderJob job) {
  final v = job.totalDiscountValue;
  if (v <= 0) return 0;
  final t = (job.totalDiscountType ?? '').toLowerCase();
  if (t == 'percent' || t == 'percentage') {
    if (job.amountAfterDiscount <= 0) return 0;
    return job.amountAfterDiscount * (v / 100);
  }
  return v;
}

double _draftOrderLevelDiscountAmount(PosOrder order) {
  final raw = order.totalDiscountValue;
  if (raw == null || raw <= 0) return 0;
  final t = (order.totalDiscountType ?? '').toLowerCase();
  if (t == 'percent' || t == 'percentage') {
    var base = order.subtotal;
    if (base <= 0) {
      base = order.jobs
          .where((j) => !j.isCancelledJob)
          .fold<double>(0, (s, j) => s + j.amountAfterPromo);
    }
    if (base <= 0) return 0;
    return base * (raw / 100);
  }
  return raw;
}

bool _draftJobHasPromo(PosOrderJob job, [PosOrder? order]) {
  if (job.promoDiscountAmount > 0.0001 ||
      (job.promoCodeName ?? '').trim().isNotEmpty) {
    return true;
  }
  if (order == null) return false;
  final activeJobs = order.jobs.where((j) => !j.isCancelledJob).length;
  if (activeJobs != 1) return false;
  return (order.promoDiscountAmount ?? 0) > 0.0001 ||
      (order.promoCodeName ?? '').trim().isNotEmpty;
}

double _draftJobPromoDiscountAmount(PosOrderJob job, [PosOrder? order]) {
  if (job.promoDiscountAmount > 0.0001) return job.promoDiscountAmount;
  if (order == null) return 0;
  final activeJobs = order.jobs.where((j) => !j.isCancelledJob).length;
  if (activeJobs != 1) return 0;
  return order.promoDiscountAmount ?? 0;
}

/// Fixed scoped promos were persisted as a single unit discount — scale by line qty for display.
double _draftJobResolvedPromoDiscountAmount(PosOrderJob job, [PosOrder? order]) {
  if (!_draftJobHasPromo(job, order)) return 0;
  final stored = _draftJobPromoDiscountAmount(job, order);
  if (_draftJobPromoIsPercent(job, order)) return stored;

  final perUnit = job.promoDiscountValue > 0.0001
      ? job.promoDiscountValue
      : (order?.promoDiscountValue ?? 0);
  if (perUnit <= 0.0001) return stored;

  // Stored amount equals one unit of a fixed promo — multiply by eligible line qty.
  if (stored <= 0.0001 || (stored - perUnit).abs() > 0.03) return stored;

  var scaled = stored;
  for (final item in dedupeCashierServiceLinesForPosDisplay(job.items)) {
    if (item.qty <= 1.0001) continue;
    final lineBase = _draftLineDisplayTotal(job, item);
    final candidate = (perUnit * item.qty).clamp(0.0, lineBase);
    if (candidate > scaled + 0.0001) scaled = candidate;
  }
  return scaled;
}

double _draftJobEffectivePromoDiscount(PosOrderJob job, [PosOrder? order]) =>
    _draftJobResolvedPromoDiscountAmount(job, order);

bool _draftJobPromoAmountStale(PosOrderJob job, [PosOrder? order]) {
  if (!_draftJobHasPromo(job, order)) return false;
  final stored = _draftJobPromoDiscountAmount(job, order);
  final resolved = _draftJobResolvedPromoDiscountAmount(job, order);
  return resolved > stored + 0.05;
}

double _draftJobPrePromoSubtotalExVat(PosOrderJob job) {
  if (job.amountAfterDiscount > 0.0001) return job.amountAfterDiscount;
  final lineFallback = dedupeCashierServiceLinesForPosDisplay(job.items)
      .fold<double>(0.0, (s, item) => s + _draftLineDisplayTotal(job, item));
  final orderDisc = _draftJobOrderLevelDiscountAmount(job);
  return (lineFallback - orderDisc).clamp(0.0, double.infinity);
}

bool _draftJobTotalsStaleAfterPromo(PosOrderJob job, [PosOrder? order]) {
  if (!_draftJobHasPromo(job, order)) return false;
  if (_draftJobPromoAmountStale(job, order)) return true;
  if (job.amountAfterPromo <= 0.0001 && job.totalAmount > 0.0001) {
    return true;
  }
  final expectedTotal =
      job.amountAfterPromo * (1.0 + job.vatPercent / 100.0);
  return job.totalAmount > 0.0001 &&
      (job.totalAmount - expectedTotal).abs() > 0.05;
}

/// Per job: taxable total after discounts/promo, before VAT ([PosOrderJob.amountAfterPromo]).
double _draftJobTotalBeforeVat(PosOrderJob job, [PosOrder? order]) {
  final hasPromo = _draftJobHasPromo(job, order);
  if (hasPromo) {
    if (!_draftJobTotalsStaleAfterPromo(job, order)) {
      return job.amountAfterPromo.clamp(0.0, double.infinity);
    }
    final promoAmt = _draftJobEffectivePromoDiscount(job, order);
    return (_draftJobPrePromoSubtotalExVat(job) - promoAmt)
        .clamp(0.0, double.infinity);
  }
  if (job.amountAfterPromo > 0.0001) return job.amountAfterPromo;
  final apiDerived = (job.totalAmount - job.vatAmount).clamp(0.0, double.infinity);
  if (apiDerived > 0.0001) return apiDerived;
  final lineFallback = dedupeCashierServiceLinesForPosDisplay(job.items)
      .fold<double>(
    0.0,
        (s, item) => s + _draftLineDisplayTotal(job, item),
  );
  return lineFallback.clamp(0.0, double.infinity);
}

bool _draftDiscountTypeIsPercent(String? type) {
  final t = (type ?? '').toLowerCase();
  return t == 'percent' || t == 'percentage';
}

double _draftJobAfterLineDiscountsExVat(PosOrderJob job) {
  if (job.amountAfterDiscount > 0.0001) return job.amountAfterDiscount;
  return dedupeCashierServiceLinesForPosDisplay(job.items)
      .fold<double>(0.0, (s, item) => s + _draftLineDisplayTotal(job, item));
}

bool _draftJobPromoIsPercent(PosOrderJob job, [PosOrder? order]) {
  if (_draftDiscountTypeIsPercent(job.promoDiscountType)) return true;
  final jobType = (job.promoDiscountType ?? '').trim().toLowerCase();
  if (jobType == 'fixed' || jobType == 'amount') return false;
  if (order == null) return false;
  final activeJobs = order.jobs.where((j) => !j.isCancelledJob).length;
  if (activeJobs != 1) return false;
  return _draftDiscountTypeIsPercent(order.promoDiscountType);
}

enum _DraftPromoDisplayMode { none, perLine, summary }

_DraftPromoDisplayMode _draftJobPromoDisplayMode(
  PosOrderJob job,
  PosOrder? order,
  PromoEligibility? eligibility,
) {
  if (!_draftJobHasPromo(job, order)) return _DraftPromoDisplayMode.none;
  if (eligibility?.isKnown == true) {
    return eligibility!.usesEntireOrderDiscount
        ? _DraftPromoDisplayMode.summary
        : _DraftPromoDisplayMode.perLine;
  }

  final totalPromo = _draftJobEffectivePromoDiscount(job, order);
  final prePromo = _draftJobPrePromoSubtotalExVat(job);
  if (_draftJobPromoIsPercent(job, order) && prePromo > 0.0001) {
    final pct = job.promoDiscountValue > 0.0001
        ? job.promoDiscountValue
        : (order?.promoDiscountValue ?? 0);
    final fullCartDiscount = prePromo * pct / 100;
    if ((fullCartDiscount - totalPromo).abs() <= 0.05) {
      return _DraftPromoDisplayMode.summary;
    }
  }
  return _DraftPromoDisplayMode.perLine;
}

/// Resolves the promo display mode for a job including promo name/id fallback
/// and eligibility lookup — same resolution as [_DraftDepartmentSection].
_DraftPromoDisplayMode _draftJobResolvedPromoDisplayMode(
  BuildContext context,
  PosOrderJob job,
  PosOrder? order,
) {
  if (!_draftJobHasPromo(job, order)) return _DraftPromoDisplayMode.none;
  final jobPromoName = (job.promoCodeName ?? '').trim();
  final displayPromoName = jobPromoName.isNotEmpty
      ? jobPromoName
      : (order?.promoCodeName ?? '').trim();
  final displayPromoId = job.promoCodeId ?? order?.promoCodeId;
  // watch: display mode must re-resolve when eligibility/scope data loads.
  final promoVm = context.watch<PromoViewModel>();
  final cached = displayPromoName.isNotEmpty
      ? promoVm.lookupPromoData(
          code: displayPromoName,
          promoCodeId: displayPromoId,
        )
      : null;
  final eligibility = displayPromoName.isNotEmpty
      ? promoVm.resolveOrderSummaryPromoEligibility(
          promoCode: displayPromoName,
          promoCodeId: displayPromoId,
        )
      : null;
  final resolvedEligibility = eligibility ??
      (cached != null ? PromoEligibility.fromPromoData(cached) : null);
  return _draftJobPromoDisplayMode(job, order, resolvedEligibility);
}

String _draftJobItemPromoKey(PosOrderJobItem item) =>
    item.id.trim().isNotEmpty ? item.id.trim() : item.productId.trim();

Map<String, double> _draftAllocateLinePromoDiscounts({
  required PosOrderJob job,
  PosOrder? order,
  required PromoEligibility eligibility,
  PromoData? cached,
  required double totalPromoAmt,
}) {
  final items = dedupeCashierServiceLinesForPosDisplay(job.items);
  final jobDisc = _draftJobOrderLevelDiscountAmount(job);
  final itemsSum = items.fold<double>(
    0,
    (s, item) => s + _draftLineDisplayTotal(job, item),
  );

  final lineAmounts = <String, double>{};
  final eligibleItems = <PosOrderJobItem>[];
  var eligibleBase = 0.0;

  for (final item in items) {
    final isService = item.itemType.toLowerCase() == 'service';
    if (!eligibility.isOrderJobItemEligible(
      productId: item.productId,
      productName: item.productName,
      isService: isService,
      productNameHints: cached?.productNames ?? const [],
      serviceNameHints: cached?.serviceNames ?? const [],
    )) {
      continue;
    }
    final lineBase = _draftLineDisplayTotal(job, item);
    final lineAfterJob = itemsSum > 0.0001
        ? lineBase - (jobDisc * lineBase / itemsSum)
        : lineBase;
    if (lineAfterJob <= 0.0001) continue;
    eligibleItems.add(item);
    eligibleBase += lineAfterJob;
  }

  if (eligibleItems.isEmpty || eligibleBase <= 0.0001) return const {};

  var sum = 0.0;
  for (final item in eligibleItems) {
    final lineBase = _draftLineDisplayTotal(job, item);
    final lineAfterJob = itemsSum > 0.0001
        ? lineBase - (jobDisc * lineBase / itemsSum)
        : lineBase;
    double amt;
    if (_draftJobPromoIsPercent(job, order)) {
      final pct = job.promoDiscountValue > 0.0001
          ? job.promoDiscountValue
          : (order?.promoDiscountValue ?? 0);
      amt = (lineAfterJob * pct / 100).clamp(0, lineAfterJob).toDouble();
    } else {
      final perUnit = job.promoDiscountValue > 0.0001
          ? job.promoDiscountValue
          : (order?.promoDiscountValue ?? 0);
      amt = (perUnit * item.qty).clamp(0, lineAfterJob).toDouble();
    }
    lineAmounts[_draftJobItemPromoKey(item)] = amt;
    sum += amt;
  }

  if (totalPromoAmt > 0.0001 &&
      sum > 0.0001 &&
      (sum - totalPromoAmt).abs() > 0.05) {
    final scale = totalPromoAmt / sum;
    for (final key in lineAmounts.keys.toList()) {
      lineAmounts[key] = (lineAmounts[key]! * scale)
          .clamp(0, double.infinity)
          .toDouble();
    }
  }
  return lineAmounts;
}

Set<String> _draftPromoEligibleItemKeys({
  required PosOrderJob job,
  required PromoEligibility eligibility,
  PromoData? cached,
}) {
  if (!eligibility.isKnown) return const {};
  final keys = <String>{};
  for (final item in dedupeCashierServiceLinesForPosDisplay(job.items)) {
    final isService = item.itemType.toLowerCase() == 'service';
    if (!eligibility.isOrderJobItemEligible(
      productId: item.productId,
      productName: item.productName,
      isService: isService,
      productNameHints: cached?.productNames ?? const [],
      serviceNameHints: cached?.serviceNames ?? const [],
    )) {
      continue;
    }
    keys.add(_draftJobItemPromoKey(item));
  }
  return keys;
}

Widget _draftOrderSummaryLinePrice(
  BuildContext context, {
  required double lineTotal,
  double promoDiscount = 0,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  String fmt(double value) =>
      AppTranslationService.localizeDigitsForLanguage(
        value.toStringAsFixed(2),
        lang,
      );

  final hasPromo = promoDiscount > 0.0001;
  final payable =
      (lineTotal - promoDiscount).clamp(0, lineTotal).toDouble();

  if (!hasPromo) {
    return Text(
      fmt(lineTotal),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E2124),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        fmt(lineTotal),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          decoration: TextDecoration.lineThrough,
          decorationColor: Colors.grey.shade600,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        fmt(payable),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.green.shade800,
          height: 1.2,
        ),
      ),
    ],
  );
}

Widget _draftOrderSummaryPromoBadge(
  BuildContext context, {
  required String promoCode,
  required double linePromoDiscount,
  bool compactTop = true,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final discountText = linePromoDiscount > 0.0001
      ? '- ${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(linePromoDiscount.toStringAsFixed(2), lang))}'
      : null;

  return Padding(
    padding: EdgeInsets.only(top: compactTop ? 2 : 3),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color(0xFF43A047).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_rounded,
              size: 10,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.posProductPromoLabel(promoCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: localeFontWeight(context, FontWeight.w700),
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ),
            if (discountText != null) ...[
              const SizedBox(width: 4),
              Text(
                discountText,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: localeFontWeight(context, FontWeight.w800),
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _draftOrderSummaryPromoRow(
  BuildContext context, {
  required String label,
  required double amount,
  bool isPromo = true,
}) {
  final labelColor =
      isPromo ? Colors.green.shade800 : Colors.grey.shade600;
  return Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
        Text(
          '− ${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(amount.toStringAsFixed(2), Localizations.localeOf(context).languageCode))}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.green.shade800,
          ),
        ),
      ],
    ),
  );
}

double _draftJobVatAmount(PosOrderJob job, double beforeVat, [PosOrder? order]) {
  if (beforeVat <= 0.0001) return 0.0;

  final promoAmt = _draftJobPromoDiscountAmount(job, order);
  final jobDiscAmt = _draftJobOrderLevelDiscountAmount(job);
  final hasPromo = _draftJobHasPromo(job, order);

  if (hasPromo ||
      jobDiscAmt > 0.0001 ||
      _draftJobTotalsStaleAfterPromo(job, order)) {
    return computePosOrderLevelVat(
      afterItemExclVat: _draftJobAfterLineDiscountsExVat(job),
      globalDiscount: jobDiscAmt,
      globalIsPercent: _draftDiscountTypeIsPercent(job.totalDiscountType),
      promoDiscount: promoAmt,
      promoIsPercent: _draftJobPromoIsPercent(job, order),
    );
  }

  final vatFromLines = dedupeCashierServiceLinesForPosDisplay(job.items).fold<double>(
    0.0,
        (s, item) => s + item.lineVatAmount,
  );
  if (job.vatAmount > 0.0001) return job.vatAmount;
  if (vatFromLines > 0.0001) return vatFromLines;
  final pct = job.vatPercent;
  return pct > 0 ? beforeVat * (pct / 100.0) : 0.0;
}

double _draftLinePayableExVat(
  PosOrderJob job,
  PosOrderJobItem item, [
  PosOrder? order,
]) {
  final raw = _draftLineDisplayTotal(job, item);
  if (!_draftJobHasPromo(job, order)) return raw;
  final items = dedupeCashierServiceLinesForPosDisplay(job.items);
  final linesSum = items.fold<double>(
    0.0,
    (s, i) => s + _draftLineDisplayTotal(job, i),
  );
  if (linesSum <= 0.0001) return 0;
  final afterPromo = _draftJobTotalBeforeVat(job, order);
  return afterPromo * (raw / linesSum);
}

/// Per job total including VAT, matching the department summary rows exactly.
double _draftJobTotalInclVat(PosOrderJob job, [PosOrder? order]) {
  final beforeVat = _draftJobTotalBeforeVat(job, order);
  final vatAmount = _draftJobVatAmount(job, beforeVat, order);
  final computed = beforeVat + vatAmount;
  if (_draftJobHasPromo(job, order) || _draftJobTotalsStaleAfterPromo(job, order)) {
    return computed;
  }
  return job.totalAmount > 0.0001 ? job.totalAmount : computed;
}

/// Plain totals under dept discount (no highlight strip) — same label typography as dept discount.
Widget _draftDeptTotalsPlainTextRows(
  BuildContext context,
  PosOrderJob job, [
  PosOrder? order,
]) {
  final labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade600,
    height: 1.25,
  );
  final valueStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Colors.grey.shade800,
    height: 1.25,
  );
  final pct = job.vatPercent;
  final pctLabel = (pct - pct.round()).abs() < 0.001
      ? pct.round().toString()
      : pct.toStringAsFixed(1);
  // Department cards stay pre-promo. Promo / referral reduce the taxable
  // base on the order footer (before VAT), so the two department totals
  // still add up to "before promo" instead of the payable grand total.
  final beforeVat = _draftJobPrePromoSubtotalExVat(job);
  final vatAmount = pct > 0 ? beforeVat * (pct / 100.0) : 0.0;
  final totalInclVat = beforeVat + vatAmount;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(AppLocalizations.of(context)!.posOrdersTotalBeforeVat, style: labelStyle)),
          Text(
            AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(beforeVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode)),
            style: valueStyle,
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(AppLocalizations.of(context)!.posOrdersVatPercent(pctLabel), style: labelStyle)),
          Text(
            '+ ${AppTranslationService.localizeDigitsForLanguage(vatAmount.toStringAsFixed(2), Localizations.localeOf(context).languageCode)} ${AppLocalizations.of(context)!.posCommonSar}',
            style: valueStyle.copyWith(color: Colors.red.shade700),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.posOrdersTotalInclVat,
              style: appManropeTextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
                height: 1.25,
                locale: Localizations.localeOf(context),
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(totalInclVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode)),
            style: appManropeTextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2124),
              locale: Localizations.localeOf(context),
              height: 1.25,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Light fill for ORDER SUMMARY department name row (matches badge hue).
Color _orderSummaryDeptHeaderFillForStatus(String statusRaw) {
  var s = statusRaw.toLowerCase().replaceAll(' ', '_');
  if (s == 'complete') s = 'completed';
  if (s == 'job_edited') s = 'edited';
  final isComplete = s == 'completed' || s == 'invoiced';
  final isEdited = s == 'edited';
  final isCancelled = s == 'cancelled' || s == 'canceled';
  final isInProgress =
      s == 'in_progress' || s == 'inprogress' || statusRaw.toLowerCase() == 'in progress';

  if (isCancelled) return const Color(0xFFFFEBEE);
  if (isComplete || isEdited) return const Color(0xFFE8F5E9);
  if (isInProgress) return const Color(0xFFFFF9E8);
  return const Color(0xFFFFF3E0);
}

/// Highlight strip for department name / dept total rows in the order summary column.
/// [departmentTotalStripe] uses a light neutral strip for per-job department totals.
/// [departmentStatusHeaderTint] when set, tints the strip to the same hue as the job status badge.
Widget _orderSummaryHighlightBox({
  required Widget child,
  bool emphasized = false,
  bool secondaryBackground = false,
  /// Tighter padding & radius (e.g. grand total row).
  bool compact = false,
  /// Per-job "Department total" row — light background, distinct from grand total.
  bool departmentTotalStripe = false,
  String? departmentStatusHeaderTint,
}) {
  final useDeptStatusTint = !departmentTotalStripe &&
      !secondaryBackground &&
      (departmentStatusHeaderTint?.trim().isNotEmpty ?? false);

  final Color bg;
  final Color borderColor;
  final double borderW;
  List<BoxShadow>? boxShadow;

  if (departmentTotalStripe) {
    bg = const Color(0xFFEFF1F5);
    borderColor = const Color(0xFFD1D9E6);
    borderW = 1;
    boxShadow = null;
  } else if (secondaryBackground) {
    bg = AppColors.secondaryLight;
    borderColor = AppColors.primaryLight.withValues(alpha: emphasized ? 0.55 : 0.4);
    borderW = emphasized ? 2 : 1.5;
    boxShadow = emphasized
        ? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.18),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ]
        : null;
  } else if (useDeptStatusTint) {
    bg = _orderSummaryDeptHeaderFillForStatus(departmentStatusHeaderTint!);
    borderColor = Colors.transparent;
    borderW = 0;
    boxShadow = null;
  } else {
    bg = emphasized
        ? const Color(0xFFFFF3D6)
        : const Color(0xFFFFF9E8);
    borderColor =
        const Color(0xFFFCC247).withValues(alpha: emphasized ? 0.95 : 0.55);
    borderW = emphasized ? 2 : 1.5;
    boxShadow = emphasized
        ? [
      BoxShadow(
        color: const Color(0xFFFCC247).withValues(alpha: 0.22),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ]
        : null;
  }

  final hPad = compact
      ? 9.0
      : (emphasized ? 12.0 : 10.0);
  final vPad = compact
      ? 7.0
      : (emphasized ? 10.0 : 8.0);
  final radius = compact
      ? 9.0
      : (departmentTotalStripe ? 9.0 : 10.0);

  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: hPad,
      vertical: vPad,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: useDeptStatusTint
          ? null
          : Border.all(
        color: borderColor,
        width: borderW,
      ),
      boxShadow: compact || departmentTotalStripe || useDeptStatusTint
          ? null
          : boxShadow,
    ),
    child: child,
  );
}

String? _ordersRequestedPaymentLabelForInvoice(
    bool? isCorporate,
    Set<PaymentMethod> methods,
    ) {
  if (isCorporate == true) {
    if (methods.isEmpty) return 'Corporate';
    if (methods.length > 1) {
      return 'Corporate — Split (${methods.map((p) => p.label).join(' + ')})';
    }
    return 'Corporate — ${methods.first.label}';
  }
  if (methods.length > 1) {
    return 'Split (${methods.map((p) => p.label).join(' + ')})';
  }
  if (methods.length == 1) return methods.first.label;
  return null;
}

/// Confirm payment amount(s) before invoice (always shown for non-corporate from Orders).
///
/// Controllers are owned by [_OrdersSplitPaymentDialog] so they are disposed only after
/// the route is unmounted — disposing in `showDialog`'s `finally` caused
/// `_dependents.isEmpty` when Cancel was pressed.
Future<List<Map<String, dynamic>>?> _showOrdersSplitPaymentDialog(
    BuildContext context, {
      required List<PaymentMethod> methods,
      required double invoiceTotal,
    }) {
  return showDialog<List<Map<String, dynamic>>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _OrdersSplitPaymentDialog(
      methods: methods,
      invoiceTotal: invoiceTotal,
    ),
  );
}

class _OrdersSplitPaymentDialog extends StatefulWidget {
  final List<PaymentMethod> methods;
  final double invoiceTotal;

  const _OrdersSplitPaymentDialog({
    required this.methods,
    required this.invoiceTotal,
  });

  @override
  State<_OrdersSplitPaymentDialog> createState() => _OrdersSplitPaymentDialogState();
}

class _OrdersSplitPaymentDialogState extends State<_OrdersSplitPaymentDialog> {
  late final Map<PaymentMethod, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final pm in widget.methods) pm: TextEditingController(),
    };
    if (widget.methods.length == 1) {
      _controllers[widget.methods.first]!.text =
          widget.invoiceTotal.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double currentSum = 0;
    for (final c in _controllers.values) {
      currentSum += double.tryParse(c.text.trim()) ?? 0.0;
    }
    final remaining = widget.invoiceTotal - currentSum;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceLight,
      title: Text(
        widget.methods.length > 1 ? l10n.posOrdersSplitPayment : l10n.posOrdersPayment,
        style: AppTextStyles.h3.copyWith(color: AppColors.secondaryLight),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.posOrdersInvoiceTotal, style: AppTextStyles.bodyMedium),
                  Text(
                    '${widget.invoiceTotal.toStringAsFixed(2)} ${l10n.posCommonSar}',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...widget.methods.map((pm) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Icon(pm.icon, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            pm.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[pm],
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.posOrdersAmountSar,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (remaining.abs() > 0.05)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  remaining > 0
                      ? l10n.posPaymentRemaining(AppTranslationService.localizeDigitsForLanguage(remaining.toStringAsFixed(2), Localizations.localeOf(context).languageCode))
                      : AppLocalizations.of(context)!.posOrdersExceedsBy(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(remaining.abs().toStringAsFixed(2), Localizations.localeOf(context).languageCode))),
                  style: TextStyle(
                    color: remaining > 0 ? Colors.orange.shade700 : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            l10n.posOrdersCancelDialog,
            style: AppTextStyles.button.copyWith(color: AppColors.secondaryLight),
          ),
        ),
        FilledButton(
          onPressed: remaining.abs() > 0.05
              ? null
              : () {
            final result = <Map<String, dynamic>>[];
            for (final pm in widget.methods) {
              result.add({
                'method': pm.label,
                'amount':
                double.tryParse(_controllers[pm]!.text.trim()) ?? 0.0,
              });
            }
            Navigator.pop(context, result);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.onPrimaryLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(l10n.posOrdersConfirmAmounts),
        ),
      ],
    );
  }
}

Future<void> _requestPaymentFromOrdersSummary(
  BuildContext context,
  PosViewModel vm,
  PosOrder order,
  double orderTotal,
) async {
  if (!await SoftPosConnectionGuard.ensureStableOrToast(context)) return;

  var payOrder = order;
  final fresh = await vm.loadCashierOrderDetail(order.id);
  if (fresh != null) payOrder = fresh;

  if (payOrder.isPosPrepaid) {
    ToastService.showError(
      context,
      AppLocalizations.of(context)!.posOrdersPaymentReceived,
    );
    return;
  }

  if (payOrder.isCorporateWalkIn &&
      !payOrder.isCorporateBookingOrder &&
      (payOrder.isCorporateUnapproved ||
          payOrder.isWaitingCorporateApproval ||
          payOrder.isRejectedByCorporate)) {
    ToastService.showError(
      context,
      AppLocalizations.of(context)!.posReviewCorporateMustBeApproved,
    );
    return;
  }

  final isRetailEmployee = _ordersIsRetailWalkInBranchEmployee(vm, payOrder);
  bool? isCorporate;
  late final List<Map<String, dynamic>> paymentSplits;

  if (isRetailEmployee) {
    final eid = _ordersBranchEmployeeIdForPayroll(vm, payOrder);
    if (eid == null || eid.isEmpty) {
      ToastService.showError(
        context,
        AppLocalizations.of(context)!.posOrdersSelectBranchEmployeeCustomer,
      );
      return;
    }
    isCorporate = false;
    paymentSplits = <Map<String, dynamic>>[
      {
        'method': PaymentMethod.employees.label,
        'amount': orderTotal,
        'employeeIds': <String>[eid],
      },
    ];
  } else {
    final l10n = AppLocalizations.of(context)!;
    if (!vm.walkInBillingReadyForInvoice(payOrder)) {
      final saved = await applyOrdersCheckoutDetailsDialog(
        context: context,
        order: payOrder,
        posVm: vm,
        showPaymentSection: true,
      );
      if (!context.mounted) return;
      if (!saved || !vm.walkInBillingReadyForInvoice(payOrder)) {
        ToastService.showError(context, l10n.posOrdersSelectCustomerAndPayment);
        return;
      }
    }
    if (!vm.invoicePaymentSelectionReadyFor(payOrder)) {
      ToastService.showError(context, l10n.posOrdersSelectYourPaymentMethod);
      return;
    }
    isCorporate = vm.invoicePaymentIsCorporate;
    final methods = vm.invoicePaymentMethods;
    if (isCorporate == null || methods.isEmpty) {
      ToastService.showError(context, l10n.posOrdersSelectYourPaymentMethod);
      return;
    }
    final amounts = vm.invoicePaymentAmounts;
    if (methods.length == 1) {
      paymentSplits = <Map<String, dynamic>>[
        {'method': methods.first.label, 'amount': orderTotal},
      ];
    } else {
      paymentSplits = methods
          .map(
            (m) => {'method': m.label, 'amount': (amounts[m] ?? 0)},
          )
          .where((p) => (p['amount'] as num) > 0)
          .toList();
      final splitSum = paymentSplits.fold<double>(
        0,
        (s, p) => s + ((p['amount'] as num).toDouble()),
      );
      if ((splitSum - orderTotal).abs() > 0.05) {
        ToastService.showError(
          context,
          l10n.posOrdersSplitAmountsMustEqualTotal(orderTotal.toStringAsFixed(2)),
        );
        return;
      }
    }
  }

  final snap = vm.walkInBillingSnapshotForOrder(payOrder.id);
  final err = await vm.requestPaymentForOrder(
    context: context,
    order: payOrder,
    orderTotal: orderTotal,
    paymentSplits: paymentSplits,
    isCorporate: isCorporate == true,
    customerNameOverride: snap?.name,
    customerMobileOverride: snap?.mobile,
    plateNoOverride: snap?.vehicleNumber,
  );
  if (!context.mounted) return;
  if (err != null) {
    ToastService.showError(context, err);
    return;
  }
  ToastService.showSuccess(
    context,
    AppLocalizations.of(context)!.posOrdersRequestPaymentSuccess,
  );
}

Future<void> _generateInvoiceFromOrdersSummary(
    BuildContext context,
    PosViewModel vm,
    PosOrder order,
    ) async {
  vm.beginInvoiceGeneration(order.id);
  try {
    await _generateInvoiceFromOrdersSummaryImpl(context, vm, order);
  } finally {
    if (vm.isInvoicingOrder(order.id)) {
      vm.endInvoiceGeneration();
    }
  }
}

Future<void> _generateInvoiceFromOrdersSummaryImpl(
    BuildContext context,
    PosViewModel vm,
    PosOrder order,
    ) async {
  var invoiceOrder = order;
  final fresh = await vm.loadCashierOrderDetail(order.id);
  if (fresh != null) {
    // Detail GET can briefly omit prepaid fields — keep SoftPOS app-bar paid state.
    invoiceOrder = (!fresh.isPosPrepaid && order.isPosPrepaid)
        ? fresh.copyWith(
            posPrepaidAmount: order.posPrepaidAmount,
            posPrepaidAt: order.posPrepaidAt,
            posPrepaidPayments: order.posPrepaidPayments,
            posPrepaidIntentId: order.posPrepaidIntentId,
          )
        : fresh;
  }
  final alreadySoftPosPaid =
      order.isPosPrepaid || invoiceOrder.isPosPrepaid;

  if (invoiceOrder.isCorporateWalkIn &&
      !invoiceOrder.isCorporateBookingOrder &&
      (invoiceOrder.isCorporateUnapproved ||
          invoiceOrder.isWaitingCorporateApproval ||
          invoiceOrder.isRejectedByCorporate)) {
    ToastService.showError(
      context,
      AppLocalizations.of(context)!.posReviewCorporateMustBeApproved,
    );
    return;
  }
  if (!invoiceOrder.meetsCashierInvoicePrerequisites) {
    ToastService.showError(context, AppLocalizations.of(context)!.posReviewOrderNotReadyForInvoicing);
    return;
  }

  final totalAmount = invoiceOrder.draftPosOrderPayableDisplay;

  if (invoiceOrder.isPosPrepaid &&
      !invoiceOrder.canInvoiceWithPrepaidMismatch(totalAmount)) {
    ToastService.showError(
      context,
      AppLocalizations.of(context)!.posOrdersPrepaidAmountMismatch(
        (invoiceOrder.posPrepaidAmount ?? 0).toStringAsFixed(2),
      ),
    );
    return;
  }

  // SoftPOS app-bar: warn when order total ≠ customer paid (still allow invoice).
  if (invoiceOrder.isSoftPosAppBarPrepaid &&
      !invoiceOrder.prepaidAmountMatchesTotal(totalAmount)) {
    final paid = invoiceOrder.posPrepaidAmount ?? 0;
    final diff = totalAmount - paid;
    final over = diff > 0.05;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final body = over
            ? 'You are generating an invoice for SAR ${totalAmount.toStringAsFixed(2)}, but the customer paid SAR ${paid.toStringAsFixed(2)} via SoftPOS (under by SAR ${diff.abs().toStringAsFixed(2)}). Continue?'
            : 'You are generating an invoice for SAR ${totalAmount.toStringAsFixed(2)}, but the customer paid SAR ${paid.toStringAsFixed(2)} via SoftPOS (over by SAR ${diff.abs().toStringAsFixed(2)}). Continue?';
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Payment amount mismatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
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
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.posCommonCancel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.secondaryLight,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.posOrdersGenerateInvoice,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight,
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
      },
    );
    if (!context.mounted) return;
    if (confirmed != true) return;
  }

  final isRetailEmployee = _ordersIsRetailWalkInBranchEmployee(vm, invoiceOrder);
  bool? isCorporate;
  Set<PaymentMethod> methodsForDialogLabel = {};
  late final List<Map<String, dynamic>> paymentSplits;

  if (isRetailEmployee) {
    final eid = _ordersBranchEmployeeIdForPayroll(vm, invoiceOrder);
    if (eid == null || eid.isEmpty) {
      ToastService.showError(
        context,
        AppLocalizations.of(context)!.posOrdersSelectBranchEmployeeCustomer,
      );
      return;
    }
    isCorporate = false;
    methodsForDialogLabel = {PaymentMethod.employees};
    paymentSplits = <Map<String, dynamic>>[
      <String, dynamic>{
        'method': PaymentMethod.employees.label,
        'amount': totalAmount,
        'employeeIds': <String>[eid],
      },
    ];
  } else {
    final l10n = AppLocalizations.of(context)!;
    final billingOk = vm.walkInBillingReadyForInvoice(invoiceOrder);
    if (!billingOk) {
      final saved = await applyOrdersCheckoutDetailsDialog(
        context: context,
        order: invoiceOrder,
        posVm: vm,
        showPaymentSection: true,
        paymentSelectionLocked: invoiceOrder.isPosPrepaid,
      );
      if (!context.mounted) return;
      if (!saved || !vm.walkInBillingReadyForInvoice(invoiceOrder)) {
        ToastService.showError(
          context,
          invoiceOrder.isPosPrepaid
              ? l10n.posOrdersCustomerDetailsSaved
              : l10n.posOrdersSelectCustomerAndPayment,
        );
        return;
      }
    }
    if (!vm.invoicePaymentSelectionReadyFor(invoiceOrder)) {
      ToastService.showError(context, l10n.posOrdersSelectYourPaymentMethod);
      return;
    }
    isCorporate = vm.invoicePaymentIsCorporate;
    final methods = vm.invoicePaymentMethods;
    if (invoiceOrder.isPosPrepaid &&
        (isCorporate == null || methods.isEmpty)) {
      // SoftPOS already paid — rebuild splits from prepaid rows if VM draft is empty.
      isCorporate = false;
      final prepaidRows =
          invoiceOrder.posPrepaidPayments ?? invoiceOrder.posPayments;
      if (prepaidRows != null && prepaidRows.isNotEmpty) {
        paymentSplits = prepaidRows
            .map(
              (r) => <String, dynamic>{
                'method': r.method,
                'amount': r.amount,
              },
            )
            .toList();
        methodsForDialogLabel = {
          for (final r in prepaidRows)
            if (parsePaymentMethodFromDraftApiLabel(r.method) != null)
              parsePaymentMethodFromDraftApiLabel(r.method)!,
        };
        if (methodsForDialogLabel.isEmpty) {
          methodsForDialogLabel = {PaymentMethod.tapToPay};
        }
      } else {
        paymentSplits = <Map<String, dynamic>>[
          <String, dynamic>{
            'method': PaymentMethod.tapToPay.label,
            'amount': invoiceOrder.posPrepaidAmount ?? totalAmount,
          },
        ];
        methodsForDialogLabel = {PaymentMethod.tapToPay};
      }
    } else if (isCorporate == null || methods.isEmpty) {
      ToastService.showError(context, l10n.posOrdersSelectYourPaymentMethod);
      return;
    } else {
      methodsForDialogLabel = methods;
      final amounts = vm.invoicePaymentAmounts;
      if (methods.length == 1) {
        paymentSplits = <Map<String, dynamic>>[
          <String, dynamic>{
            'method': methods.first.label,
            'amount': totalAmount,
          },
        ];
      } else {
        paymentSplits = methods
            .map(
              (m) => <String, dynamic>{
            'method': m.label,
            'amount': (amounts[m] ?? 0),
          },
        )
            .where((p) => (p['amount'] as num) > 0)
            .toList();
        final splitSum = paymentSplits.fold<double>(
          0,
              (s, p) => s + ((p['amount'] as num).toDouble()),
        );
        if ((splitSum - totalAmount).abs() > 0.05) {
          ToastService.showError(
            context,
            AppLocalizations.of(context)!.posOrdersSplitAmountsMustEqualTotal(totalAmount.toStringAsFixed(2)),
          );
          return;
        }
      }
    }
  }

  // Only ping SoftPOS when payment still needs collecting on the terminal.
  // Already SoftPOS-paid orders (app-bar / prepaid) must never block invoice.
  if (isCorporate != true && !alreadySoftPosPaid) {
    if (!await SoftPosConnectionGuard.ensureStableOrToast(context)) return;
    final snap = vm.walkInBillingSnapshotForOrder(invoiceOrder.id);
    try {
      final softPosOk = await runSoftPosBeforeInvoice(
        context: context,
        order: invoiceOrder,
        paymentSplits: paymentSplits,
        customerNameOverride: snap?.name,
        customerMobileOverride: snap?.mobile,
        plateNoOverride: snap?.vehicleNumber,
      );
      if (!context.mounted) return;
      if (!softPosOk) {
        ToastService.showError(
          context,
          'Tap to Pay was not approved on SoftPOS.',
        );
        return;
      }
    } on SoftPosBridgeException catch (e) {
      if (!context.mounted) return;
      ToastService.showError(context, e.message);
      return;
    }
  }

  try {
    final response = await vm.generateInvoice(
      invoiceOrder.id,
      orderForBilling: invoiceOrder,
      isCorporate: isCorporate,
      paymentMethod: paymentSplits.length == 1
          ? paymentSplits.first['method'] as String?
          : null,
      payments: paymentSplits,
    );

    if (!context.mounted) return;
    if (response != null && response.success) {
      // PosViewModel.generateInvoice already removes the invoiced order from
      // the in-memory list and updates stats; no /cashier/orders refetch
      // needed here.
      vm.setOrdersListTab('All');
      if (!context.mounted) return;
      final inv = response.invoice;
      if (inv != null) {
        final mergedInv =
            invoiceWithMergedCustomerTax(inv, invoiceOrder.customer?.vatNumber);
        final fresh = vm.selectedOrder;
        final mcFallback = (fresh != null && fresh.id == invoiceOrder.id)
            ? fresh.maintenanceChecks
            : invoiceOrder.maintenanceChecks;
        final requestedPayment =
            _ordersRequestedPaymentLabelForInvoice(
              isCorporate,
              methodsForDialogLabel,
            );
        final paymentText = invoiceDialogPaymentMethodText(
          mergedInv,
          requestedPaymentMethod: requestedPayment,
        );
        // Skip the invoice popup — fire WhatsApp + thermal print in parallel.
        // Toasts surface via the root ScaffoldMessenger so success/failure
        // remains visible on the Orders Hub.
        InvoiceAutoDispatch.dispatch(
          invoice: mergedInv,
          paymentMethodText: paymentText,
          maintenanceChecksFallback: mcFallback,
        );
        ToastService.showSuccess(
          context,
          'Invoice generated. Sending to printer and WhatsApp…',
        );
      } else {
        ToastService.showSuccess(
          context,
          AppLocalizations.of(context)!.posOrdersInvoiceSavedNoReceipt,
        );
      }
    } else {
      final msg = (response?.message ?? '').trim();
      final l10n = AppLocalizations.of(context)!;
      if (msg.toLowerCase().contains('payment method')) {
        ToastService.showError(context, l10n.posOrdersSelectYourPaymentMethod);
      } else {
        ToastService.showError(
          context,
          msg.isNotEmpty ? msg : 'Failed to generate invoice',
        );
      }
    }
  } catch (e) {
    if (context.mounted) ToastService.showError(context, e.toString());
  }
}

/// Order Summary: opens the same promo dialog as the department cart, but in
/// order mode — validation runs against the placed order's lines and
/// apply/remove persist straight to the order's editable jobs.
Future<void> _openOrderSummaryPromoDialog(
  BuildContext context, {
  required PosViewModel vm,
  required PosOrder order,
  required String appliedPromoName,
}) async {
  final editableJobs = vm.promoEditableJobsForOrder(order);
  if (editableJobs.isEmpty) return;

  var orderAmountExclVat = 0.0;
  var orderAmountInclVat = 0.0;
  final lineItems = <Map<String, dynamic>>[];
  for (final job in editableJobs) {
    final prePromo = _draftJobPrePromoSubtotalExVat(job);
    orderAmountExclVat += prePromo;
    orderAmountInclVat += prePromo * (1 + job.vatPercent / 100);
    for (final item in dedupeCashierServiceLinesForPosDisplay(job.items)) {
      final isService = item.itemType == 'service';
      lineItems.add({
        'itemType': isService ? 'service' : 'product',
        if (isService)
          'serviceId': item.productId
        else
          'productId': item.productId,
        'lineAmount': _draftLineDisplayTotal(job, item),
        'quantity': item.qty,
        if (item.unitPriceExcludingVat > 0)
          'unitPrice': item.unitPriceExcludingVat,
      });
    }
  }

  await PromoCodeDialog.show(
    context,
    orderTarget: PromoOrderTarget(
      order: order,
      orderAmountExclVat: orderAmountExclVat,
      orderAmountInclVat: orderAmountInclVat,
      primaryJobId: editableJobs.length == 1 ? editableJobs.first.id : null,
      lineItems: lineItems,
      appliedPromoCode: appliedPromoName,
      onApply: (code, validResult) async {
        final ok = await vm.applyPromoCodeToOrder(
          order: order,
          promoCode: code,
          promoCodeId: validResult['id']?.toString(),
        );
        if (context.mounted) {
          if (ok) {
            ToastService.showSuccess(context, code, title: 'Promo applied');
          } else {
            ToastService.showError(
              context,
              vm.errorMessage ?? 'Failed to apply promo code',
            );
          }
        }
        return ok;
      },
      onRemove: () async {
        final ok = await vm.removePromoCodeFromOrder(order);
        if (context.mounted) {
          if (ok) {
            ToastService.showSuccess(context, 'Promo removed',
                messageOnly: true);
          } else {
            ToastService.showError(
              context,
              vm.errorMessage ?? 'Failed to remove promo code',
            );
          }
        }
        return ok;
      },
    ),
  );
}

/// Confirmation before removing the promo from the whole order, then removes
/// it via the job pricing endpoint and refreshes the summary.
Future<void> _confirmAndRemoveOrderPromo(
  BuildContext context, {
  required PosViewModel vm,
  required PosOrder order,
  required String promoCode,
}) async {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  await showPosLogoutStyleConfirmDialog(
    context,
    title: isAr ? 'إزالة كود الخصم؟' : 'Remove promo code?',
    body: isAr
        ? 'سيتم إزالة "$promoCode" من هذا الطلب وإعادة احتساب الإجمالي.'
        : '"$promoCode" will be removed from this order and the totals will be recalculated.',
    confirmLabel: isAr ? 'إزالة' : 'Remove',
    cancelLabel: AppLocalizations.of(context)!.posCommonCancel,
    onConfirm: () async {
      final ok = await vm.removePromoCodeFromOrder(order);
      if (!context.mounted) return ok;
      if (ok) {
        ToastService.showSuccess(
          context,
          isAr ? 'تمت إزالة كود الخصم' : 'Promo code removed',
          messageOnly: true,
        );
      } else {
        ToastService.showError(
          context,
          vm.errorMessage ?? 'Failed to remove promo code',
        );
      }
      return ok;
    },
  );
}

/// "See details" on the applied-promo banner: opens the same requirements /
/// applies-to popup used on the promo cards. Fetches the promo catalog once
/// if it is not cached yet.
Future<void> _showAppliedOrderPromoDetails(
  BuildContext context,
  String promoCode,
) async {
  final promoVm = context.read<PromoViewModel>();
  var promo = promoVm.findAvailablePromotionByCode(promoCode);
  if (promo == null) {
    await promoVm.fetchAvailablePromos();
    promo = promoVm.findAvailablePromotionByCode(promoCode);
  }
  if (!context.mounted) return;
  if (promo == null) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ToastService.showError(
      context,
      isAr ? 'تعذر تحميل تفاصيل كود الخصم' : 'Could not load promo details',
    );
    return;
  }
  showPromoDetailsDialog(context, promo);
}

const double _kOrderSummaryCodeChipHeight = 36;
const double _kOrderSummaryCodeChipAction = 20;

Widget _orderSummaryCodeChipActionSlot({Widget? child}) {
  return SizedBox(
    width: _kOrderSummaryCodeChipAction,
    height: _kOrderSummaryCodeChipAction,
    child: child == null ? null : Center(child: child),
  );
}

const Color _kOrderSummaryCodeChipBg = Color(0xFFFFF7E6);
const Color _kOrderSummaryAppliedChipBg = Color(0xFFE8F5E9);
const Color _kOrderSummaryAppliedChipBorder = Color(0xFF43A047);

/// Equal-sized promo / referral chip. Trailing close slot is always reserved so
/// apply/remove does not change height or width.
Widget _orderSummaryCodeChip({
  required Color borderColor,
  required Widget leading,
  required String label,
  required Color labelColor,
  required FontWeight labelWeight,
  Color backgroundColor = _kOrderSummaryCodeChipBg,
  VoidCallback? onTap,
  Widget? trailingClose,
}) {
  return SizedBox(
    height: _kOrderSummaryCodeChipHeight,
    width: double.infinity,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 4),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: labelWeight,
                      fontSize: 11,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (trailingClose != null)
            _orderSummaryCodeChipActionSlot(child: trailingClose)
          else
            const SizedBox(width: 2),
        ],
      ),
    ),
  );
}

/// Same look as the department cart's "Add Promo Code" banner (compact),
/// shown in the Order Summary footer above the totals.
Widget? _orderSummaryAddPromoBanner(
  BuildContext context, {
  required PosViewModel vm,
  required PosOrder order,
  required String appliedPromoName,
}) {
  final editableJobs = vm.promoEditableJobsForOrder(order);
  if (editableJobs.isEmpty) return null;
  final st = order.status.toLowerCase();
  if (st.contains('invoiced') || st.contains('cancel')) {
    return null;
  }

  final loc = AppLocalizations.of(context)!;
  final promoCode = appliedPromoName.trim();
  final hasPromo = promoCode.isNotEmpty;
  final busy = vm.isOrderPromoMutationInFlight;
  final paidLocked = order.isPosPrepaid;

  void toastPaid() {
    ToastService.showInfo(context, 'This order is already paid');
  }

  Widget? closeChild;
  if (hasPromo && busy) {
    closeChild = const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.secondaryLight,
      ),
    );
  } else if (hasPromo) {
    closeChild = GestureDetector(
      onTap: paidLocked
          ? toastPaid
          : () => _confirmAndRemoveOrderPromo(
                context,
                vm: vm,
                order: order,
                promoCode: promoCode,
              ),
      child: Opacity(
        opacity: paidLocked ? 0.45 : 1,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.secondaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  return Opacity(
    opacity: paidLocked && !hasPromo ? 0.55 : 1,
    child: _orderSummaryCodeChip(
      backgroundColor:
          hasPromo ? _kOrderSummaryAppliedChipBg : _kOrderSummaryCodeChipBg,
      borderColor: hasPromo
          ? _kOrderSummaryAppliedChipBorder
          : const Color(0xFFFFC145).withValues(alpha: 0.6),
      leading: Icon(
        Icons.local_offer_outlined,
        size: 14,
        color: hasPromo ? Colors.green.shade700 : Colors.amber.shade700,
      ),
      label: hasPromo
          ? '${loc.posProductPromoPrefix} $promoCode'
          : loc.posProductAddPromoCode,
      labelColor: hasPromo ? Colors.green.shade700 : const Color(0xFF1E2124),
      labelWeight: localeFontWeight(context, FontWeight.w700),
      onTap: busy
          ? null
          : paidLocked
              ? toastPaid
              : () => _openOrderSummaryPromoDialog(
                    context,
                    vm: vm,
                    order: order,
                    appliedPromoName: promoCode,
                  ),
      trailingClose: closeChild,
    ),
  );
}

Widget? _orderSummaryAddReferralBanner(
  BuildContext context, {
  required PosViewModel vm,
  required PosOrder order,
  required double orderAmountInclVat,
}) {
  final st = order.status.toLowerCase();
  if (st.contains('invoiced') || st.contains('cancel')) {
    return null;
  }

  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final code = (order.referralCode ?? '').trim();
  final hasCode = code.isNotEmpty;
  final hasLineItems = order.jobs.any(
        (j) => dedupeCashierServiceLinesForPosDisplay(j.items).isNotEmpty,
      ) ||
      order.items.isNotEmpty;
  if (!hasLineItems && !hasCode) {
    return null;
  }

  final busy = vm.isOrderReferralMutationInFlight;
  final paidLocked = order.isPosPrepaid;

  void toastPaid() {
    ToastService.showInfo(context, 'This order is already paid');
  }

  Widget? closeChild;
  if (hasCode && busy) {
    closeChild = const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.secondaryLight,
      ),
    );
  } else if (hasCode) {
    closeChild = GestureDetector(
      onTap: paidLocked
          ? toastPaid
          : () async {
              final ok = await vm.removeReferralCodeFromOrder(order);
              if (!context.mounted) return;
              if (!ok) {
                ToastService.showError(
                  context,
                  vm.errorMessage ??
                      (isAr ? 'تعذر إزالة الرمز' : 'Failed to remove referral'),
                );
              }
            },
      child: Opacity(
        opacity: paidLocked ? 0.45 : 1,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.secondaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  return Opacity(
    opacity: paidLocked && !hasCode ? 0.55 : 1,
    child: _orderSummaryCodeChip(
      backgroundColor:
          hasCode ? _kOrderSummaryAppliedChipBg : _kOrderSummaryCodeChipBg,
      borderColor: hasCode
          ? _kOrderSummaryAppliedChipBorder
          : AppColors.primaryLight.withValues(alpha: 0.7),
      leading: Icon(
        Icons.person_add_alt_1_outlined,
        size: 14,
        color: hasCode ? Colors.green.shade700 : Colors.amber.shade700,
      ),
      label: hasCode
          ? (isAr ? 'إحالة: $code' : 'Referral: $code')
          : (isAr ? 'إضافة رمز إحالة' : 'Add referral code'),
      labelColor: hasCode ? Colors.green.shade700 : const Color(0xFF1E2124),
      labelWeight: localeFontWeight(context, FontWeight.w700),
      onTap: busy
          ? null
          : paidLocked
              ? toastPaid
              : () => ReferralCodeDialog.show(
                    context,
                    order: order,
                    orderAmountInclVat: orderAmountInclVat,
                    appliedReferralCode: code,
                  ),
      trailingClose: closeChild,
    ),
  );
}

class _OrderSummaryPanel extends StatelessWidget {
  final PosViewModel vm;
  const _OrderSummaryPanel({required this.vm});

  @override
  Widget build(BuildContext context) {
    final order = vm.selectedOrder;
    if (order == null) return const SizedBox();

    final activeJobs = order.jobs.where((j) => !j.isCancelledJob).toList();
    final totalJobs = activeJobs.length;
    final completedJobs = activeJobs
        .where((j) {
      final s = j.status.toLowerCase();
      return s == 'completed' || s == 'invoiced' || s == 'edited';
    })
        .length;
    final progress = totalJobs > 0 ? completedJobs / totalJobs : 0.0;
    final allDepartmentsComplete =
        totalJobs > 0 && completedJobs == totalJobs;
    final meetsPrereq = order.meetsCashierInvoicePrerequisites;
    final billingOk = vm.walkInBillingReadyForInvoice(order);
    final hideRetailPaymentPicker =
    _ordersIsRetailWalkInBranchEmployee(vm, order);
    // Same rule as payment: only block invoicing for corporate **walk-in** while waiting on
    // corporate approval (or rejected). Do not require literal `corporate approved` status
    // (cashier orders often stay `in progress` / `completed` on jobs while invoice is due).
    final corporateApprovedForBilling = !(order.isCorporateWalkIn &&
        !order.isCorporateBookingOrder &&
        (order.isCorporateUnapproved ||
            order.isWaitingCorporateApproval ||
            order.isRejectedByCorporate));
    final needsWalkInCustomerDetails =
        vm.isStandardWalkInOrderForBilling(order);

    final orderDiscAmt = _draftOrderLevelDiscountAmount(order);

    final grandTotalFromJobs = activeJobs.fold<double>(
      0.0,
          (sum, job) => sum + _draftJobTotalInclVat(job, order),
    );
    // Pre-promo base across jobs — when > 0 while the payable total is 0, the
    // zero is genuine (promo/discount covered the invoice), not missing data.
    final jobsPrePromoBaseExVat = activeJobs.fold<double>(
      0.0,
      (sum, job) => sum + _draftJobPrePromoSubtotalExVat(job),
    );
    final grandTotalBeforeReferral = grandTotalFromJobs > 0.0001
        ? grandTotalFromJobs
        : (activeJobs.isNotEmpty && jobsPrePromoBaseExVat > 0.0001
            ? 0.0
            : (activeJobs.isEmpty &&
                    order.totalAmount <= 0.0001 &&
                    order.orderLevelLinesPayableTotal <= 0.0001
                ? 0.0
                : order.draftPosOrderTotalDisplay));
    final referralDiscountAmt =
        (order.referralCode ?? '').trim().isNotEmpty
            ? order.referralDiscountAmount.clamp(0.0, double.infinity)
            : 0.0;
    final grandTotal = (grandTotalBeforeReferral - referralDiscountAmt)
        .clamp(0.0, double.infinity);

    final canTapGenerateInvoice = allDepartmentsComplete &&
        meetsPrereq &&
        corporateApprovedForBilling &&
        (!needsWalkInCustomerDetails || billingOk) &&
        (!order.isPosPrepaid ||
            order.canInvoiceWithPrepaidMismatch(grandTotal));
    // Request Payment removed — SoftPOS runs via Tap to Pay / SoftPOS app-bar send.
    const showRequestPaymentButton = false;
    const canTapRequestPayment = false;
    final showGenerateInvoiceButton = allDepartmentsComplete &&
        corporateApprovedForBilling &&
        (!needsWalkInCustomerDetails || billingOk);

    final detailChildren = <Widget>[];

    if (orderDiscAmt > 0) {
      final dt = (order.totalDiscountType ?? '').toLowerCase();
      final dv = order.totalDiscountValue ?? 0;
      final label = (dt == 'percent' || dt == 'percentage')
          ? AppLocalizations.of(context)!.posOrdersDeptDiscountPercent(dv.toStringAsFixed(0))
          : AppLocalizations.of(context)!.posOrdersOrderDiscount;
      detailChildren.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Text(
                '− ${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(orderDiscAmt.toStringAsFixed(2), Localizations.localeOf(context).languageCode))}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (detailChildren.isNotEmpty) {
      detailChildren.add(const Divider(height: 20, thickness: 1, color: Color(0xFFE8ECF3)));
    }

    // Promo shown once at order level (removed from department sections).
    final orderPromoAmt = activeJobs.isNotEmpty
        ? activeJobs.fold<double>(
            0.0,
            (sum, job) => sum + _draftJobEffectivePromoDiscount(job, order),
          )
        : (order.promoDiscountAmount ?? 0.0);
    final orderPromoName = () {
      final orderName = (order.promoCodeName ?? '').trim();
      if (orderName.isNotEmpty) return orderName;
      for (final job in activeJobs) {
        final n = (job.promoCodeName ?? '').trim();
        if (n.isNotEmpty) return n;
      }
      return '';
    }();
    // Promo / referral reduce the taxable base (ex VAT). Department cards
    // stay pre-promo; this footer is the only place those cuts appear.
    final vatPercent = () {
      for (final job in activeJobs) {
        if (job.vatPercent > 0.0001) return job.vatPercent;
      }
      return 15.0;
    }();
    final vatRate = vatPercent / 100.0;
    final prePromoExVat = activeJobs.isNotEmpty
        ? jobsPrePromoBaseExVat
        : 0.0;
    final promoExVat = orderPromoAmt.clamp(0.0, prePromoExVat);
    final referralExVat = referralDiscountAmt > 0.0001
        ? (referralDiscountAmt / (1.0 + vatRate)).clamp(0.0, double.infinity)
        : 0.0;
    final totalAfterDiscount = activeJobs.isNotEmpty
        ? (prePromoExVat - promoExVat - referralExVat)
            .clamp(0.0, double.infinity)
        : (grandTotal / (1.0 + vatRate));
    final totalBeforeVat = activeJobs.isNotEmpty
        ? prePromoExVat
        : (totalAfterDiscount + promoExVat + referralExVat);
    final footerVat = totalAfterDiscount * vatRate;
    final hasAppliedDiscount = promoExVat > 0.0001 || referralExVat > 0.0001;
    final vatPctLabel = (vatPercent - vatPercent.round()).abs() < 0.001
        ? vatPercent.round().toString()
        : vatPercent.toStringAsFixed(1);
    final showPromoInFooter =
        promoExVat > 0.0001 || orderPromoName.isNotEmpty;
    final referralCodeLabel = (order.referralCode ?? '').trim();

    for (var ji = 0; ji < activeJobs.length; ji++) {
      final job = activeJobs[ji];
      detailChildren.add(_DraftDepartmentSection(job: job, sourceOrder: order));
      if (ji < activeJobs.length - 1) {
        detailChildren.add(const SizedBox(height: 12));
        detailChildren.add(const Divider(height: 1, color: Color(0xFFE8ECF3)));
        detailChildren.add(const SizedBox(height: 12));
      }
    }

    if (activeJobs.isEmpty && order.items.isNotEmpty) {
      detailChildren.add(_OrderLevelItemsSection(order: order));
    }

    final fixedFooter = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 14, thickness: 1, color: Color(0xFFE8ECF3)),
        Builder(
          builder: (bannerContext) {
            final promoBanner = _orderSummaryAddPromoBanner(
              bannerContext,
              vm: vm,
              order: order,
              appliedPromoName: orderPromoName,
            );
            final referralBanner = _orderSummaryAddReferralBanner(
              bannerContext,
              vm: vm,
              order: order,
              orderAmountInclVat: grandTotalBeforeReferral,
            );
            if (promoBanner == null && referralBanner == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: _kOrderSummaryCodeChipHeight,
                child: Row(
                  children: [
                    Expanded(child: promoBanner ?? const SizedBox.expand()),
                    const SizedBox(width: 8),
                    Expanded(child: referralBanner ?? const SizedBox.expand()),
                  ],
                ),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.posOrdersTotalBeforeVat,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.posCommonSarAmount(
                AppTranslationService.localizeDigitsForLanguage(
                  totalBeforeVat.toStringAsFixed(2),
                  Localizations.localeOf(context).languageCode,
                ),
              ),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        if (showPromoInFooter) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      size: 12,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        orderPromoName.isNotEmpty
                            ? AppLocalizations.of(context)!
                                .posProductPromoLabel(orderPromoName)
                            : AppLocalizations.of(context)!
                                .posProductPromoDiscount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (promoExVat > 0.0001)
                Text(
                  '− ${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(promoExVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode))}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade800,
                  ),
                ),
            ],
          ),
        ],
        if (referralCodeLabel.isNotEmpty || referralDiscountAmt > 0.0001) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 12,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'خصم الإحالة${referralCodeLabel.isNotEmpty ? ' ($referralCodeLabel)' : ''}'
                            : 'Referral${referralCodeLabel.isNotEmpty ? ': $referralCodeLabel' : ' discount'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (referralExVat > 0.0001)
                Text(
                  '− ${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(referralExVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode))}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade800,
                  ),
                ),
            ],
          ),
        ],
        if (hasAppliedDiscount) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.posOrdersTotalAfterDiscount,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.posCommonSarAmount(
                  AppTranslationService.localizeDigitsForLanguage(
                    totalAfterDiscount.toStringAsFixed(2),
                    Localizations.localeOf(context).languageCode,
                  ),
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.posOrdersVatPercent(vatPctLabel),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '+ ${AppTranslationService.localizeDigitsForLanguage(footerVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode)} ${AppLocalizations.of(context)!.posCommonSar}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.posOrdersGrandTotal,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.posCommonSarAmount(
                AppTranslationService.localizeDigitsForLanguage(
                  grandTotal.toStringAsFixed(2),
                  Localizations.localeOf(context).languageCode,
                ),
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
          ],
        ),
        if (order.isPosPrepaid) ...[
          const SizedBox(height: 8),
          _OrdersPaymentStatusBanner(order: order, grandTotal: grandTotal),
        ],
        const SizedBox(height: 8),
        _OrdersHeaderCustomerPaymentRow(
          vm: vm,
          order: order,
          showPaymentMethodButton: !hideRetailPaymentPicker,
          paymentSelectionLocked: order.isPosPrepaid,
        ),
        if (order.isPosPrepaid &&
            !order.isSoftPosAppBarPrepaid &&
            !order.prepaidAmountMatchesTotal(grandTotal)) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.posOrdersPrepaidAmountMismatch(
              (order.posPrepaidAmount ?? 0).toStringAsFixed(2),
            ),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC62828),
            ),
          ),
        ],
        if (showRequestPaymentButton ||
            (allDepartmentsComplete && showGenerateInvoiceButton)) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (showRequestPaymentButton) ...[
                Expanded(
                  child: Consumer<PosViewModel>(
                    builder: (context, posVm, _) {
                      final requesting =
                          posVm.isRequestingPaymentFor(order.id);
                      return SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: canTapRequestPayment && !requesting
                              ? () => _requestPaymentFromOrdersSummary(
                                    context,
                                    posVm,
                                    order,
                                    grandTotal,
                                  )
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryLight,
                            side: BorderSide(
                              color: AppColors.secondaryLight.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: requesting
                              ? AppButtonBusy.loaderOnFill(
                                  AppColors.secondaryLight,
                                  size: 18,
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final label = AppLocalizations.of(context)!
                                        .posOrdersRequestPayment
                                        .replaceAll(' ', '\u00A0');
                                    return SizedBox(
                                      width: constraints.maxWidth,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: Text(
                                          label,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                          softWrap: false,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ),
                if (allDepartmentsComplete && showGenerateInvoiceButton)
                  const SizedBox(width: 8),
              ],
              if (allDepartmentsComplete && showGenerateInvoiceButton)
                Expanded(
                child: Consumer<PosViewModel>(
                  builder: (context, posVm, _) {
                    final invoicingThisOrder = posVm.isInvoicingOrder(order.id);
                    return SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: canTapGenerateInvoice && !invoicingThisOrder
                            ? () => _generateInvoiceFromOrdersSummary(
                                  context,
                                  posVm,
                                  order,
                                )
                            : null,
                        style: AppButtonBusy.elevatedLocked(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: AppColors.onSecondaryLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: invoicingThisOrder
                            ? AppButtonBusy.loaderOnFill(
                                AppColors.secondaryLight,
                                size: 20,
                              )
                            : Text(
                                AppLocalizations.of(context)!
                                    .posOrdersGenerateInvoice,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSecondaryLight,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isVeryTight = availableHeight.isFinite && availableHeight < 260;

        Widget summaryHeader() => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                AppLocalizations.of(context)!.posOrdersOrderSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF1F4F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF34C759),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$completedJobs/$totalJobs',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final normalContent = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summaryHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: detailChildren,
                ),
              ),
            ),
            fixedFooter,
          ],
        );

        final tightContent = SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryHeader(),
              const SizedBox(height: 10),
              ...detailChildren,
              if (detailChildren.isNotEmpty) const SizedBox(height: 12),
              fixedFooter,
            ],
          ),
        );

        return Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF3), width: 1.5),
          ),
          child: isVeryTight ? tightContent : normalContent,
        );
      },
    );
  }
}

double _orderLevelLinePayableTotal(PosOrderJobItem item) {
  if (item.lineTotal > 0.0001) return item.lineTotal;
  return item.lineTotalExcludingVat + item.lineVatAmount;
}

class _OrderLevelItemsSection extends StatelessWidget {
  final PosOrder order;
  const _OrderLevelItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final parsed = <PosOrderJobItem>[];
    for (final raw in order.items) {
      if (raw is! Map) continue;
      parsed.add(PosOrderJobItem.fromJson(Map<String, dynamic>.from(raw)));
    }
    final items = dedupeCashierServiceLinesForPosDisplay(parsed);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _orderSummaryHighlightBox(
          child: Text(
            AppLocalizations.of(context)!.posOrdersOrderSummary,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Color(0xFF1E2124),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...List<Widget>.generate(items.length, (i) {
          final item = items[i];
          final lineTot = _orderLevelLinePayableTotal(item);
          final isLast = i == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 0 : 12,
              bottom: isLast ? 10 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 6),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: AppColors.secondaryLight,
                  ),
                ),
                Expanded(
                  child: Text(
                    _ordersProductNameForLocale(context, item),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2124),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppTranslationService.localizeDigitsForLanguage(
                    lineTot.toStringAsFixed(2),
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2124),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DraftDepartmentSection extends StatelessWidget {
  final PosOrderJob job;
  final PosOrder? sourceOrder;
  const _DraftDepartmentSection({required this.job, this.sourceOrder});

  @override
  Widget build(BuildContext context) {
    final statusForUi = (sourceOrder != null &&
        sourceOrder!.isCorporateWalkIn &&
        sourceOrder!.isRejectedByCorporate)
        ? sourceOrder!.status
        : job.status;

    final jobPromoNameRaw = (job.promoCodeName ?? '').trim();
    final jobPromoAmt = _draftJobEffectivePromoDiscount(job, sourceOrder);
    final useOrderPromoFallback = sourceOrder != null &&
        jobPromoNameRaw.isEmpty &&
        jobPromoAmt <= 0.0001 &&
        sourceOrder!.jobs.where((j) => !j.isCancelledJob).length == 1;
    final displayPromoName = useOrderPromoFallback
        ? (sourceOrder!.promoCodeName ?? '').trim()
        : jobPromoNameRaw;
    final displayPromoId = useOrderPromoFallback
        ? sourceOrder!.promoCodeId
        : job.promoCodeId;

    final promoVm = context.watch<PromoViewModel>();
    final promoCached = displayPromoName.isNotEmpty
        ? promoVm.lookupPromoData(
            code: displayPromoName,
            promoCodeId: displayPromoId,
          )
        : null;
    final promoEligibility = displayPromoName.isNotEmpty
        ? promoVm.resolveOrderSummaryPromoEligibility(
            promoCode: displayPromoName,
            promoCodeId: displayPromoId,
          )
        : null;
    final resolvedEligibility = promoEligibility ??
        (promoCached != null
            ? PromoEligibility.fromPromoData(promoCached)
            : null);
    final promoEligibleItemKeys = resolvedEligibility != null &&
            resolvedEligibility.isKnown &&
            displayPromoName.isNotEmpty
        ? _draftPromoEligibleItemKeys(
            job: job,
            eligibility: resolvedEligibility,
            cached: promoCached,
          )
        : const <String>{};

    final jobDiscAmt = _draftJobOrderLevelDiscountAmount(job);

    final items = dedupeCashierServiceLinesForPosDisplay(job.items);
    final techs = job.distinctActiveTechnicians;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _orderSummaryHighlightBox(
          departmentStatusHeaderTint: statusForUi,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LocalizedApiText(
                  job.department,
                  uppercase: Localizations.localeOf(context).languageCode != 'ar',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFF1E2124),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              posOrdersJobStatusBadge(context, statusForUi),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            AppLocalizations.of(context)!.posOrdersNoProductsOrServices,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          )
        else
          ...List<Widget>.generate(items.length, (i) {
            final item = items[i];
            final discLabel = _draftLineDiscountLabel(item);
            final discAmt = _draftLineDiscountAmountSar(item);
            final itemPromoKey = _draftJobItemPromoKey(item);
            final showPromoBadge = displayPromoName.isNotEmpty &&
                (promoEligibleItemKeys.isEmpty ||
                    promoEligibleItemKeys.contains(itemPromoKey));
            final lineTot = _draftLineDisplayTotal(job, item);
            final isLast = i == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : 12,
                bottom: isLast ? 10 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 6),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _ordersProductNameForLocale(context, item),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2124),
                            height: 1.12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showPromoBadge)
                          _draftOrderSummaryPromoBadge(
                            context,
                            promoCode: displayPromoName,
                            // Price cut lives on the order footer (before VAT).
                            linePromoDiscount: 0,
                          ),
                        SizedBox(
                          height: showPromoBadge ? 4 : 2,
                        ),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                            children: [
                              TextSpan(
                                text: AppLocalizations.of(context)!
                                    .posOrdersQtyWithoutVat(
                                  AppTranslationService
                                      .localizeDigitsForLanguage(
                                    _draftFmtQty(item.qty),
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ),
                                  AppTranslationService
                                      .localizeDigitsForLanguage(
                                    _draftLineUnitPriceExVat(job, item)
                                        .toStringAsFixed(2),
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (discLabel != null &&
                            discAmt != null &&
                            discAmt > 0.0001) ...[
                          const SizedBox(height: 4),
                          _draftOrderSummaryPromoRow(
                            context,
                            label: discLabel,
                            amount: discAmt,
                            isPromo: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _draftOrderSummaryLinePrice(
                    context,
                    lineTotal: lineTot,
                    promoDiscount: 0,
                  ),
                ],
              ),
            );
          }),
        if (techs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.posOrdersAssignedTechnicians,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                ...techs.map((t) {
                  final name =
                      t.name.trim().isEmpty ? 'Technician' : t.name.trim();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: LocalizedApiText(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
        if (jobDiscAmt > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                      () {
                    final dt = (job.totalDiscountType ?? '').toLowerCase();
                    final dv = job.totalDiscountValue;
                    if (dt == 'percent' || dt == 'percentage') {
                      return AppLocalizations.of(context)!.posOrdersDeptDiscountPercent(dv.toStringAsFixed(0));
                    }
                    return AppLocalizations.of(context)!.posOrdersDeptDiscount;
                  }(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Text(
                '− ${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(jobDiscAmt.toStringAsFixed(2), Localizations.localeOf(context).languageCode))}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        _draftDeptTotalsPlainTextRows(context, job, sourceOrder),
      ],
    );
  }
}

Widget _orderStripStatusBadge(BuildContext context, PosOrder order, {required bool isSelected}) {
  String label = order.jobsAggregateBadgeLabel;
  if (order.isCorporateWalkIn) {
    if (order.isCorporateUnapproved) {
      label = 'UNAPPROVED';
    } else if (order.isWaitingCorporateApproval) {
      label = 'WAITING APPROVAL';
    } else if (order.isCorporateApproved) {
      label = 'CORP APPROVED';
    } else if (order.isRejectedByCorporate) {
      label = 'REJECTED';
    }
  }
  // SoftPOS / prepaid — cashier needs a clear Paid signal on the list.
  if (order.isPosPrepaid && label != 'COMPLETED') {
    label = 'PAID';
  }
  final Color fg;
  final Color bg;

  // Unselected tiles: same soft grey pill for PENDING, COMPLETED, and DRAFT.
  if (!isSelected) {
    fg = AppColors.secondaryLight;
    bg = AppColors.secondaryLight.withValues(alpha: 0.08);
  } else if (label == 'PAID') {
    fg = Colors.white;
    bg = const Color(0xFF2E7D32);
  } else if (label == 'COMPLETED') {
    fg = Colors.white;
    bg = AppColors.secondaryLight;
  } else if (label == 'DRAFT') {
    fg = const Color(0xFF23262D).withValues(alpha: 0.8);
    bg = const Color(0xFF23262D).withValues(alpha: 0.1);
  } else {
    fg = Colors.white;
    bg = AppColors.secondaryLight;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      _ordersTranslatedStatusLabel(context, label),
      style: TextStyle(
        fontSize: 7,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        height: 1,
        color: fg,
      ),
    ),
  );
}

class _HorizontalOrderTile extends StatelessWidget {
  final PosOrder order;
  final bool isSelected;
  final VoidCallback onTap;
  /// When true (tablet vertical list), tile spans the column width.
  final bool fullWidth;

  const _HorizontalOrderTile({
    required this.order,
    required this.isSelected,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeJobs = order.jobs.where((j) => !j.isCancelledJob).toList();
    final completedActive = activeJobs
        .where((j) {
      final s = j.status.toLowerCase();
      return s == 'completed' || s == 'invoiced' || s == 'edited';
    })
        .length;
    final jobProgressLabel = '$completedActive/${activeJobs.length}';
    final deptNames = order.selectedDepartmentNames;
    final isCorporateOrder =
        order.isCorporateWalkIn || order.isCorporateBookingOrder;
    final showCorporateLine = isCorporateOrder && deptNames.isNotEmpty;
    final rightMetaLabel = jobProgressLabel;
    final canCancel = posOrderCanCashierCancel(order);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: fullWidth ? double.infinity : 162,
            padding: EdgeInsets.fromLTRB(9, 6, canCancel ? 22 : 9, 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFCC247) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFFCC247) : const Color(0xFFE8ECF3),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFFFCC247).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (ctx) {
                          final langCode = Localizations.localeOf(ctx).languageCode;
                          final rawId = order.id.split('-').last.toUpperCase();
                          return Text(
                            '#${AppTranslationService.localizeDigitsForLanguage(rawId, langCode)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: isSelected ? const Color(0xFF23262D).withOpacity(0.7) : Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    _orderStripStatusBadge(context, order, isSelected: isSelected),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/car icon.png',
                      width: 16,
                      height: 16,
                      color: isSelected ? const Color(0xFF23262D) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Builder(
                        builder: (ctx) {
                          final langCode =
                              Localizations.localeOf(ctx).languageCode;
                          final plateRaw = order.vehicle?.plateNo;
                          if (plateRaw == null || plateRaw.trim().isEmpty) {
                            return Text(
                              AppLocalizations.of(ctx)!.posOrdersNoPlate,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                color: isSelected
                                    ? const Color(0xFF23262D)
                                    : const Color(0xFF1E2124),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          final plate = langCode == 'ar'
                              // Use raw API plate for Arabic so the letter block is
                              // transliterated before any UI formatter changes order.
                              ? PlateTransliterator.localize(plateRaw, langCode)
                              : formatVehiclePlateLettersFirst(plateRaw);
                          return Text(
                            plate,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.4,
                              color: isSelected
                                  ? const Color(0xFF23262D)
                                  : const Color(0xFF1E2124),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    Builder(
                      builder: (ctx) {
                        final langCode = Localizations.localeOf(ctx).languageCode;
                        return Text(
                          AppTranslationService.localizeDigitsForLanguage(rightMetaLabel, langCode),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? const Color(0xFF23262D) : const Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (showCorporateLine) ...[
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 22),
                    child: Text(
                      AppLocalizations.of(context)!.posPaymentCorporate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF23262D).withOpacity(0.78)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Builder(
                  builder: (ctx) {
                    final langCode = Localizations.localeOf(ctx).languageCode;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDateLocalized(order, langCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 7,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF23262D).withOpacity(0.55) : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 7,
                            height: 1,
                            color: isSelected ? const Color(0xFF23262D).withOpacity(0.35) : Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          _formatTimeLocalized(order, langCode),
                          style: TextStyle(
                            fontSize: 7,
                            height: 1,
                            color: isSelected ? const Color(0xFF23262D).withOpacity(0.6) : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (canCancel)
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: InkWell(
                onTap: () => showCashierCancelOrderDialog(context, order.id),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2124),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateLocalized(PosOrder order, String langCode) {
    try {
      final locale = langCode == 'ar' ? 'ar' : 'en';
      final dStr = order.date;
      if (dStr.isNotEmpty) {
        final dt = DateTime.tryParse(dStr);
        if (dt != null) {
          final formatted = DateFormat('dd MMM yyyy', locale).format(dt);
          return langCode == 'ar'
              ? AppTranslationService.localizeDigitsForLanguage(formatted, langCode)
              : formatted;
        }
      }
      final dt = DateTime.tryParse(order.createdAt);
      if (dt != null) {
        final formatted = DateFormat('dd MMM yyyy', locale).format(dt);
        return langCode == 'ar'
            ? AppTranslationService.localizeDigitsForLanguage(formatted, langCode)
            : formatted;
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
    }
    return '—';
  }

  String _formatTimeLocalized(PosOrder order, String langCode) {
    try {
      DateTime? dt;
      if (order.orderDate.isNotEmpty && order.orderTime.isNotEmpty) {
        final dateTimeStr = '${order.orderDate} ${order.orderTime}';
        dt = DateTime.tryParse(dateTimeStr) ?? DateTime.tryParse(order.createdAt);
        if (dt == null && order.orderTime.contains(':')) {
          final parts = order.orderTime.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final now = DateTime.now();
          dt = DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
      dt ??= DateTime.tryParse(order.createdAt);

      if (dt != null) {
        // Use 24h format for Arabic (more natural) and localize the digits
        final formatted = langCode == 'ar'
            ? DateFormat('HH:mm').format(dt)
            : DateFormat('hh:mm a').format(dt);
        return langCode == 'ar'
            ? AppTranslationService.localizeDigitsForLanguage(formatted, langCode)
            : formatted;
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }
    return order.orderTime.isNotEmpty
        ? (langCode == 'ar'
        ? AppTranslationService.localizeDigitsForLanguage(order.orderTime, langCode)
        : order.orderTime)
        : '16:55';
  }
}