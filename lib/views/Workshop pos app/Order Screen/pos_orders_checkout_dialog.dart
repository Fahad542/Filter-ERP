import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/pos_order_model.dart';
import '../../../models/pos_payment_method.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/toast_service.dart';
import '../../../services/softpos_access_service.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/softpos_settings_dialog.dart';
import '../Home Screen/pos_view_model.dart';
import 'pos_invoice_payment_dialog.dart';
import 'pos_order_review_view.dart';
import 'pos_orders_hub_dialog.dart';

/// Customer (+ optional payment) from merged orders checkout dialog.
class OrdersCheckoutDetailsResult {
  final WalkInInvoiceFormResult customer;
  final InvoicePaymentChoiceResult? payment;
  final String resolvedOrderId;

  const OrdersCheckoutDetailsResult({
    required this.customer,
    this.payment,
    required this.resolvedOrderId,
  });
}

/// Opens merged dialog and applies payment prefs to [posVm]. Returns false if cancelled.
Future<bool> applyOrdersCheckoutDetailsDialog({
  required BuildContext context,
  required PosOrder order,
  required PosViewModel posVm,
  required bool showPaymentSection,
  bool paymentSelectionLocked = false,
}) async {
  posVm.ensureInvoicePaymentPrefillForOrder(order);
  final orderIsCorporate =
      order.isCorporateWalkIn || order.isCorporateBookingOrder;
  // Orders Hub list already includes customer, vehicle, payment draft, and jobs.
  final result = await showOrdersCheckoutDetailsDialog(
    context: context,
    order: order,
    posVm: posVm,
    // Re-fetch the order detail on open so a reopen right after "Save" shows
    // the freshly patched billing/vehicle data instead of the hub-list snapshot.
    refreshOrderOnOpen: true,
    showPaymentSection: showPaymentSection,
    paymentSelectionLocked: paymentSelectionLocked,
    initialIsCorporate: orderIsCorporate,
    // Don't re-open previously selected methods — cashier picks fresh each time.
    // Received SoftPOS/cash amounts still show in the Received Amount banner.
    initialPayments: const <PaymentMethod>{},
    initialPaymentAmounts: const <PaymentMethod, double>{},
    initialEmployeeIds: const <String>{},
    totalAmount: order.draftPosOrderTotalDisplay,
    customerTypeLocked: true,
    persistDraftFn: showPaymentSection && !paymentSelectionLocked
        ? (proposal) {
            // Prefer live hub order — prepaid may have just been updated.
            final live = posVm.selectedOrder?.id == order.id
                ? posVm.selectedOrder!
                : order;
            final payable = live.draftPosOrderTotalDisplay;
            // Advance SoftPOS/cash may be taken while cart total is still 0 —
            // skip draft amount validation; prefs still apply on Save.
            if (payable <= 0.0001) return Future<String?>.value(null);
            return posVm.persistCashierOrderPaymentDraft(
              orderId: live.id,
              isCorporate: proposal.isCorporate,
              methods: proposal.payments,
              paymentAmounts: proposal.paymentAmounts,
              payableTotal: payable,
              alreadyReceived: live.posPrepaidAmount ?? 0,
            );
          }
        : null,
    clearPersistedDraftFn: showPaymentSection && !paymentSelectionLocked
        ? () => posVm.clearCashierOrderPaymentDraft(order.id)
        : null,
  );
  if (result == null) return false;
  final resolvedOrderId = result.resolvedOrderId;
  if (result.payment != null) {
    posVm.setInvoicePaymentPreferences(
      isCorporate: result.payment!.isCorporate,
      payments: result.payment!.payments,
      paymentAmounts: result.payment!.paymentAmounts,
      employeeIds: result.payment!.employeeIds,
      forOrderId: resolvedOrderId,
    );
  }
  return true;
}

Future<OrdersCheckoutDetailsResult?> showOrdersCheckoutDetailsDialog({
  required BuildContext context,
  required PosOrder order,
  required PosViewModel posVm,
  bool refreshOrderOnOpen = false,
  required bool showPaymentSection,
  bool paymentSelectionLocked = false,
  required bool? initialIsCorporate,
  required Set<PaymentMethod> initialPayments,
  required Map<PaymentMethod, double> initialPaymentAmounts,
  required Set<String> initialEmployeeIds,
  required double totalAmount,
  bool customerTypeLocked = true,
  InvoicePaymentDraftPersistFn? persistDraftFn,
  Future<String?> Function()? clearPersistedDraftFn,
}) {
  return showDialog<OrdersCheckoutDetailsResult>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      return MediaQuery(
        data: media.copyWith(viewInsets: EdgeInsets.zero),
        child: _OrdersCheckoutDetailsDialog(
          order: order,
          posVm: posVm,
          refreshOrderOnOpen: refreshOrderOnOpen,
          showPaymentSection: showPaymentSection,
          paymentSelectionLocked: paymentSelectionLocked,
          initialIsCorporate: initialIsCorporate,
          initialPayments: initialPayments,
          initialPaymentAmounts: initialPaymentAmounts,
          initialEmployeeIds: initialEmployeeIds,
          totalAmount: totalAmount,
          customerTypeLocked: customerTypeLocked,
          persistDraftFn: persistDraftFn,
          clearPersistedDraftFn: clearPersistedDraftFn,
          keyboardBottomInset: media.viewInsets.bottom,
        ),
      );
    },
  );
}

class _OrdersCheckoutDetailsDialog extends StatefulWidget {
  const _OrdersCheckoutDetailsDialog({
    required this.order,
    required this.posVm,
    this.refreshOrderOnOpen = false,
    required this.showPaymentSection,
    this.paymentSelectionLocked = false,
    required this.initialIsCorporate,
    required this.initialPayments,
    required this.initialPaymentAmounts,
    required this.initialEmployeeIds,
    required this.totalAmount,
    required this.customerTypeLocked,
    required this.persistDraftFn,
    required this.clearPersistedDraftFn,
    required this.keyboardBottomInset,
  });

  final PosOrder order;
  final PosViewModel posVm;
  final bool refreshOrderOnOpen;
  final bool showPaymentSection;
  final bool paymentSelectionLocked;
  final bool? initialIsCorporate;
  final Set<PaymentMethod> initialPayments;
  final Map<PaymentMethod, double> initialPaymentAmounts;
  final Set<String> initialEmployeeIds;
  final double totalAmount;
  final bool customerTypeLocked;
  final InvoicePaymentDraftPersistFn? persistDraftFn;
  final Future<String?> Function()? clearPersistedDraftFn;
  final double keyboardBottomInset;

  @override
  State<_OrdersCheckoutDetailsDialog> createState() =>
      _OrdersCheckoutDetailsDialogState();
}

class _OrdersCheckoutDetailsDialogState extends State<_OrdersCheckoutDetailsDialog> {
  late GlobalKey<WalkInInvoiceDetailsDialogState> _customerKey;
  final _paymentKey = GlobalKey<InvoicePaymentChoicePanelState>();
  bool _saving = false;
  late PosOrder _order;
  bool _orderDetailRefreshing = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _customerKey = GlobalKey<WalkInInvoiceDetailsDialogState>();
    if (widget.refreshOrderOnOpen) {
      unawaited(_refreshOrderDetail());
    }
  }

  /// Billing/vehicle fields the customer form seeds from — used to decide
  /// whether a fresh order detail actually changed anything worth re-seeding.
  static String _billingSeedFingerprint(PosOrder o) {
    final c = o.customer;
    final v = o.vehicle;
    return [
      (c?.name ?? '').trim(),
      (c?.mobile ?? '').trim(),
      (c?.vatNumber ?? '').trim(),
      (v?.plateNo ?? '').trim(),
      (v?.make ?? '').trim(),
      (v?.model ?? '').trim(),
      (v?.year ?? '').trim(),
      (v?.vin ?? '').trim(),
      '${o.odometerReading}',
    ].join('|');
  }

  Future<void> _refreshOrderDetail() async {
    if (_orderDetailRefreshing) return;
    if (mounted) setState(() => _orderDetailRefreshing = true);
    try {
      final fresh = await widget.posVm.loadCashierOrderDetail(_order.id);
      if (!mounted) return;
      if (fresh != null) {
        widget.posVm.ensureInvoicePaymentPrefillForOrder(fresh);
        // Only rebuild (re-seed) the customer form when the server copy really
        // differs — an unconditional key reset would wipe anything the cashier
        // already started typing while the fetch was in flight.
        final changed =
            _billingSeedFingerprint(fresh) != _billingSeedFingerprint(_order);
        setState(() {
          _order = fresh;
          if (changed) {
            _customerKey = GlobalKey<WalkInInvoiceDetailsDialogState>();
          }
        });
      }
    } catch (_) {
      // Keep list snapshot in the form if refresh fails.
    } finally {
      if (mounted) setState(() => _orderDetailRefreshing = false);
    }
  }

  void _syncOrderFromHub() {
    final id = _order.id.trim();
    PosOrder? latest;
    for (final o in widget.posVm.orders) {
      if (o.id.trim() == id) {
        latest = o;
        break;
      }
    }
    latest ??= widget.posVm.selectedOrder;
    if (latest != null && mounted) {
      setState(() => _order = latest!);
    }
  }

  WalkInInvoiceFormResult _customerSnapshotFromOrder() {
    final c = _order.customer;
    final v = _order.vehicle;
    final country = (v?.plateCountryCode ?? 'SA').trim();
    return WalkInInvoiceFormResult(
      name: (c?.name ?? '').trim(),
      mobile: (c?.mobile ?? '').trim(),
      vat: (c?.vatNumber ?? '').trim(),
      vehicleNumber: (v?.displayPlate ?? v?.plateNo ?? '').trim(),
      vin: (v?.vin ?? '').trim(),
      make: (v?.make ?? '').trim(),
      model: (v?.model ?? '').trim(),
      year: (v?.year ?? '').trim(),
      color: (v?.color ?? '').trim(),
      odometer: _order.odometerReading,
      billingCustomerIsEmployee: c?.isCustomerEmployee == true,
      billingEmployeeId: c?.branchEmployeeId,
      billingEmployeeType: c?.employeeType,
      vehiclePlateCountry: country.isEmpty ? 'SA' : country,
      vehiclePlateEmirate: v?.plateEmirate,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Payment-only dialog: keep existing customer; do not show/edit details.
      final WalkInInvoiceFormResult? customer = widget.showPaymentSection
          ? _customerSnapshotFromOrder()
          : await _customerKey.currentState?.saveCustomerDetails();
      if (!mounted) return;
      if (customer == null) return;

      InvoicePaymentChoiceResult? payment;
      final paymentLocked = widget.paymentSelectionLocked;
      if (widget.showPaymentSection && !paymentLocked) {
        final panel = _paymentKey.currentState;
        payment = panel?.collectResult();
        if (payment == null) {
          ToastService.showError(
            context,
            AppLocalizations.of(context)!.posOrdersSelectPaymentMethod,
          );
          return;
        }

        final amounts = panel?.collectAdvanceAmounts() ?? payment.paymentAmounts;
        final tapAmount = amounts[PaymentMethod.tapToPay] ?? 0;

        // Tap to Pay first — if it fails, keep Edit customer open.
        if (tapAmount > 0.0001) {
          if (!isSoftPosUiEnabled) {
            ToastService.showError(
              context,
              AppLocalizations.of(context)!.posSoftPosConnectionNotStable,
            );
            return;
          }
          final ok = await showSoftPosSendRequestDialog(
            context,
            order: _order,
            suggestedAmount: tapAmount,
            lockAmount: true,
            skipReadyGate: false,
          );
          if (!mounted) return;
          if (!ok) {
            ToastService.showError(
              context,
              'Tap to Pay payment was not successful',
            );
            return;
          }
          _syncOrderFromHub();
        }

        // Record other selected methods (Cash / Card / …) with typed amounts.
        for (final entry in amounts.entries) {
          if (entry.key == PaymentMethod.tapToPay) continue;
          if (entry.value <= 0.0001) continue;
          final err = await widget.posVm.recordAdvanceOrderPayment(
            order: _order,
            method: entry.key,
            paidAmount: entry.value,
          );
          if (!mounted) return;
          if (err != null) {
            ToastService.showError(context, err);
            return;
          }
          _syncOrderFromHub();
        }
        // Avoid double-counting: prepaid now includes amounts just recorded.
        panel?.clearTypedAdvanceAmounts();

        // Draft only if something is still due. Prepaid SoftPOS/cash must
        // count toward the total (was wrongly comparing Cash-only vs full total).
        if (widget.persistDraftFn != null) {
          final payable = _order.draftPosOrderTotalDisplay;
          final prepaid = _order.posPrepaidAmount ?? 0;
          if (payable > 0.0001 && prepaid + 0.05 < payable) {
            final err = await widget.persistDraftFn!(payment);
            if (!mounted) return;
            if (err != null) {
              ToastService.showError(context, err);
              return;
            }
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        OrdersCheckoutDetailsResult(
          customer: customer,
          payment: payment,
          resolvedOrderId: _order.id,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;
    final paymentOnly = widget.showPaymentSection;
    // Narrow dialogs: customer-only / payment-only (no side-by-side).
    final maxDialogWidth = paymentOnly ? 520.0 : 580.0;
    final horizontalInset =
        ((size.width - maxDialogWidth) / 2).clamp(16.0, size.width * 0.28);
    final hubInsets = posOrdersHubDialogInsets(size);
    final insetPadding = EdgeInsets.fromLTRB(
      horizontalInset,
      hubInsets.top,
      horizontalInset,
      hubInsets.bottom,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: widget.keyboardBottomInset),
      child: Dialog(
        insetPadding: insetPadding,
        backgroundColor: const Color(0xFFFBF9F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight:
                size.height - insetPadding.vertical - widget.keyboardBottomInset,
          ),
          // Shrink to content — no empty gap above Cancel/Save.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosPrimaryDialogHeader(
                title: paymentOnly
                    ? l10n.posOrdersSelectPaymentMethod
                    : l10n.posOrdersEditCustomerDetails,
                isTablet: isTablet,
                roundBottom: false,
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.secondaryLight,
                // Close via Cancel — no X on payment / edit-customer dialogs.
                onClose: null,
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 16 : 12,
                  isTablet ? 20 : 18,
                  isTablet ? 16 : 12,
                  isTablet ? 12 : 10,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 16 : 12,
                    6,
                    isTablet ? 16 : 12,
                    4,
                  ),
                  // Open-time order detail fetch — shimmer instead of progress bar.
                  // Do not shimmer on Save: panel GlobalKey must stay mounted for collect.
                  child: _orderDetailRefreshing
                      ? (paymentOnly
                          ? const _CheckoutPaymentPopupShimmer()
                          : const _CheckoutCustomerPopupShimmer())
                      : paymentOnly
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InvoicePaymentChoicePanel(
                                    key: _paymentKey,
                                    embedded: true,
                                    // Customer type is edited in Edit customer details.
                                    hideCustomerType: true,
                                    initialIsCorporate:
                                        widget.initialIsCorporate,
                                    initialPayments: widget.initialPayments,
                                    initialPaymentAmounts:
                                        widget.initialPaymentAmounts,
                                    initialEmployeeIds:
                                        widget.initialEmployeeIds,
                                    totalAmount:
                                        _order.draftPosOrderTotalDisplay,
                                    customerTypeLocked:
                                        widget.customerTypeLocked,
                                    paymentSelectionLocked:
                                        widget.paymentSelectionLocked,
                                    softPosReceiveOrder: _order,
                                    softPosAlreadyReceived:
                                        _order.posPrepaidAmount ?? 0,
                                    softPosAlreadyReceivedLabel:
                                        _order.prepaidPaymentMethodLabel,
                                    softPosAlreadyReceivedRows:
                                        _order.posPrepaidPayments ??
                                            _order.posPayments,
                                    onCustomerTypeChanged: (_) {
                                      if (mounted) setState(() {});
                                    },
                                    onReady: () {
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  WalkInInvoiceDetailsDialog(
                                    key: _customerKey,
                                    embedded: true,
                                    order: _order,
                                    posVm: widget.posVm,
                                    showVehicleSection: true,
                                  ),
                                  const SizedBox(height: 10),
                                  // Customer type on one row under customer fields.
                                  InvoicePaymentChoicePanel(
                                    key: _paymentKey,
                                    embedded: true,
                                    hideCustomerType: false,
                                    hidePaymentMethods: true,
                                    initialIsCorporate:
                                        widget.initialIsCorporate,
                                    initialPayments: const {},
                                    customerTypeLocked:
                                        widget.customerTypeLocked,
                                    onCustomerTypeChanged: (_) {
                                      if (mounted) setState(() {});
                                    },
                                    onReady: () {
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 14 : 12,
                  4,
                  isTablet ? 14 : 12,
                  isTablet ? 12 : 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_saving || _orderDetailRefreshing)
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: AppButtonBusy.elevatedLocked(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.posCommonCancel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: (_saving || _orderDetailRefreshing)
                            ? null
                            : _submit,
                        style: AppButtonBusy.filledLocked(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.onPrimaryLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: (_saving || _orderDetailRefreshing)
                            ? AppButtonBusy.loaderOnFill(
                                AppColors.primaryLight,
                              )
                            : Text(
                                l10n.posCommonSave,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

/// Matches [InvoicePaymentChoicePanel] layout (methods card + receiving banner).
class _CheckoutPaymentPopupShimmer extends StatelessWidget {
  const _CheckoutPaymentPopupShimmer();

  static const _tileBorder = Color(0xFFE2E8F0);
  static const _cardBg = Color(0xFFFAFBFC);
  static const _cardBorder = Color(0xFFF0F2F5);

  Widget _methodTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tileBorder),
      ),
      child: const Row(
        children: [
          Expanded(child: PosShimmerBox(width: double.infinity, height: 12, radius: 4)),
          SizedBox(width: 8),
          PosShimmerCircle(size: 20),
        ],
      ),
    );
  }

  Widget _methodRow() {
    return Row(
      children: [
        Expanded(child: _methodTile()),
        const SizedBox(width: 8),
        Expanded(child: _methodTile()),
        const SizedBox(width: 8),
        Expanded(child: _methodTile()),
      ],
    );
  }

  Widget _summaryLine({double labelW = 110, double valueW = 64}) {
    return Row(
      children: [
        PosShimmerBox(width: labelW, height: 11, radius: 4),
        const Spacer(),
        PosShimmerBox(width: valueW, height: 12, radius: 4),
      ],
    );
  }

  Widget _receivedLine() {
    return const Row(
      children: [
        PosShimmerCircle(size: 6),
        SizedBox(width: 8),
        Expanded(child: PosShimmerBox(width: double.infinity, height: 11, radius: 4)),
        SizedBox(width: 12),
        PosShimmerBox(width: 56, height: 11, radius: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same inset as embedded [InvoicePaymentChoicePanel].
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      PosShimmerBox(width: 16, height: 16, radius: 4),
                      SizedBox(width: 6),
                      Expanded(
                        child: PosShimmerBox(
                          width: double.infinity,
                          height: 12,
                          radius: 4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _methodRow(),
                  const SizedBox(height: 8),
                  _methodRow(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const PosShimmerBox(width: 130, height: 13, radius: 4),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _tileBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _receivedLine(),
                  const SizedBox(height: 6),
                  _receivedLine(),
                  const SizedBox(height: 10),
                  _summaryLine(labelW: 120, valueW: 72),
                  const SizedBox(height: 8),
                  _summaryLine(labelW: 100, valueW: 72),
                  const SizedBox(height: 8),
                  _summaryLine(labelW: 70, valueW: 56),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Matches embedded [WalkInInvoiceDetailsDialog] + customer-type row.
class _CheckoutCustomerPopupShimmer extends StatelessWidget {
  const _CheckoutCustomerPopupShimmer();

  static const _fieldBorder = Color(0xFFD1D5DB);

  Widget _field() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fieldBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: const PosShimmerBox(width: 72, height: 11, radius: 4),
    );
  }

  Widget _fieldsRow() {
    return Row(
      children: [
        Expanded(child: _field()),
        const SizedBox(width: 8),
        Expanded(child: _field()),
        const SizedBox(width: 8),
        Expanded(child: _field()),
      ],
    );
  }

  Widget _sectionTitle({double width = 120}) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: PosShimmerBox(width: width, height: 14, radius: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(width: 130),
            const SizedBox(height: 8),
            _fieldsRow(),
            const SizedBox(height: 14),
            _sectionTitle(width: 70),
            const SizedBox(height: 8),
            // Car / Bike radios
            const Row(
              children: [
                PosShimmerCircle(size: 18),
                SizedBox(width: 4),
                PosShimmerBox(width: 16, height: 16, radius: 4),
                SizedBox(width: 4),
                PosShimmerBox(width: 36, height: 12, radius: 4),
                SizedBox(width: 20),
                PosShimmerCircle(size: 18),
                SizedBox(width: 4),
                PosShimmerBox(width: 16, height: 16, radius: 4),
                SizedBox(width: 4),
                PosShimmerBox(width: 36, height: 12, radius: 4),
              ],
            ),
            const SizedBox(height: 8),
            // GCC country chips
            Row(
              children: List.generate(6, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i == 5 ? 0 : 6),
                  child: const PosShimmerBox(width: 40, height: 28, radius: 8),
                );
              }),
            ),
            const SizedBox(height: 8),
            _fieldsRow(),
            const SizedBox(height: 8),
            _fieldsRow(),
            const SizedBox(height: 14),
            // CUSTOMER TYPE label (uppercase section)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: PosShimmerBox(width: 90, height: 9, radius: 3),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: const Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        PosShimmerCircle(size: 18),
                        SizedBox(width: 8),
                        PosShimmerBox(width: 70, height: 12, radius: 4),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 1,
                    height: 36,
                    child: ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        PosShimmerCircle(size: 18),
                        SizedBox(width: 8),
                        PosShimmerBox(width: 80, height: 12, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

