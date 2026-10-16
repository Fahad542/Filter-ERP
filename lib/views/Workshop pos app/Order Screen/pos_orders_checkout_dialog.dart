import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/pos_order_model.dart';
import '../../../models/pos_payment_method.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/toast_service.dart';
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
    initialPayments: posVm.invoicePaymentMethods,
    initialPaymentAmounts: posVm.invoicePaymentAmounts,
    initialEmployeeIds: posVm.invoicePaymentEmployeeIds,
    totalAmount: order.draftPosOrderTotalDisplay,
    customerTypeLocked: true,
    persistDraftFn: showPaymentSection && !paymentSelectionLocked
        ? (proposal) {
            return posVm.persistCashierOrderPaymentDraft(
              orderId: order.id,
              isCorporate: proposal.isCorporate,
              methods: proposal.payments,
              paymentAmounts: proposal.paymentAmounts,
              payableTotal: order.draftPosOrderTotalDisplay,
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

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final customer =
          await _customerKey.currentState?.saveCustomerDetails();
      if (!mounted) return;
      if (customer == null) return;

      InvoicePaymentChoiceResult? payment;
      final paymentLocked =
          widget.paymentSelectionLocked || _order.isPosPrepaid;
      if (widget.showPaymentSection && !paymentLocked) {
        payment = _paymentKey.currentState?.collectResult();
        if (payment == null) {
          ToastService.showError(
            context,
            AppLocalizations.of(context)!.posOrdersSelectPaymentMethod,
          );
          return;
        }
        if (widget.persistDraftFn != null) {
          final err = await widget.persistDraftFn!(payment);
          if (!mounted) return;
          if (err != null) {
            ToastService.showError(context, err);
            return;
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
    final hubInsets = posOrdersHubDialogInsets(size);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: widget.keyboardBottomInset),
      child: Dialog(
        insetPadding: hubInsets,
        backgroundColor: const Color(0xFFFBF9F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                size.height - hubInsets.vertical - widget.keyboardBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosPrimaryDialogHeader(
                title: l10n.posOrdersEditCustomerDetails,
                isTablet: isTablet,
                onClose: _saving ? null : () => Navigator.of(context).pop(),
              ),
              if (_orderDetailRefreshing)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primaryLight,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 16 : 12,
                    8,
                    isTablet ? 16 : 12,
                    12,
                  ),
                  child: widget.showPaymentSection
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: WalkInInvoiceDetailsDialog(
                                    key: _customerKey,
                                    embedded: true,
                                    order: _order,
                                    posVm: widget.posVm,
                                    showVehicleSection: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l10n.posOrdersSelectPaymentMethod,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF1E2124),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InvoicePaymentChoicePanel(
                                        key: _paymentKey,
                                        embedded: true,
                                        initialIsCorporate:
                                            widget.initialIsCorporate,
                                        initialPayments:
                                            widget.initialPayments,
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
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: WalkInInvoiceDetailsDialog(
                            key: _customerKey,
                            embedded: true,
                            order: _order,
                            posVm: widget.posVm,
                            showVehicleSection: true,
                          ),
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
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
                      onPressed: _saving ? null : _submit,
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
                          if (_saving) ...[
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
      ),
    );
  }
}

