import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/toast_service.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/pos_payment_method.dart';
import '../../../models/takeaway_models.dart';
import '../../../utils/app_colors.dart';
import '../Home Screen/pos_view_model.dart';
import '../Order Screen/pos_invoice_payment_dialog.dart';
import '../Order Screen/pos_order_review_view.dart'
    show WalkInInvoiceDetailsDialog, WalkInInvoiceDetailsDialogState, WalkInInvoiceFormResult;
import '../Order Screen/pos_orders_hub_dialog.dart';

/// Customer + payment saved together from the merged takeaway checkout dialog.
class TakeawayCheckoutDetailsResult {
  final WalkInInvoiceFormResult customer;
  final InvoicePaymentChoiceResult payment;

  const TakeawayCheckoutDetailsResult({
    required this.customer,
    required this.payment,
  });
}

Future<TakeawayCheckoutDetailsResult?> showTakeawayCheckoutDetailsDialog({
  required BuildContext context,
  required WalkInInvoiceFormResult initialCustomer,
  required bool? initialIsCorporate,
  required Set<PaymentMethod> initialPayments,
  required Map<PaymentMethod, double> initialPaymentAmounts,
  required double totalAmount,
  required List<TakeawayBranchEmployee> branchEmployees,
  bool checkoutContextLoading = false,
}) {
  return showDialog<TakeawayCheckoutDetailsResult>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      return MediaQuery(
        data: media.copyWith(viewInsets: EdgeInsets.zero),
        child: _TakeawayCheckoutDetailsDialog(
          initialCustomer: initialCustomer,
          initialIsCorporate: initialIsCorporate,
          initialPayments: initialPayments,
          initialPaymentAmounts: initialPaymentAmounts,
          totalAmount: totalAmount,
          branchEmployees: branchEmployees,
          checkoutContextLoading: checkoutContextLoading,
          keyboardBottomInset: media.viewInsets.bottom,
        ),
      );
    },
  );
}

class _TakeawayCheckoutDetailsDialog extends StatefulWidget {
  const _TakeawayCheckoutDetailsDialog({
    required this.initialCustomer,
    required this.initialIsCorporate,
    required this.initialPayments,
    required this.initialPaymentAmounts,
    required this.totalAmount,
    required this.branchEmployees,
    required this.checkoutContextLoading,
    required this.keyboardBottomInset,
  });

  final WalkInInvoiceFormResult initialCustomer;
  final bool? initialIsCorporate;
  final Set<PaymentMethod> initialPayments;
  final Map<PaymentMethod, double> initialPaymentAmounts;
  final double totalAmount;
  final List<TakeawayBranchEmployee> branchEmployees;
  final bool checkoutContextLoading;
  final double keyboardBottomInset;

  @override
  State<_TakeawayCheckoutDetailsDialog> createState() =>
      _TakeawayCheckoutDetailsDialogState();
}

class _TakeawayCheckoutDetailsDialogState
    extends State<_TakeawayCheckoutDetailsDialog> {
  final _customerKey = GlobalKey<WalkInInvoiceDetailsDialogState>();
  final _paymentKey = GlobalKey<InvoicePaymentChoicePanelState>();

  Future<void> _submit() async {
    final customer = await _customerKey.currentState?.saveCustomerDetails();
    if (!mounted) return;
    if (customer == null) return;

    final payment = _paymentKey.currentState?.collectResult();
    if (payment == null) {
      ToastService.showError(
        context,
        AppLocalizations.of(context)!.posTakeawaySelectPaymentFirst,
      );
      return;
    }
    Navigator.of(context).pop(
      TakeawayCheckoutDetailsResult(
        customer: customer,
        payment: payment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;
    final hubInsets = posOrdersHubDialogInsets(size);
    final posVm = context.read<PosViewModel>();

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
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 16 : 12,
                    8,
                    isTablet ? 16 : 12,
                    12,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            // Same customer form + fonts as Orders Edit Customer Details.
                            child: WalkInInvoiceDetailsDialog(
                              key: _customerKey,
                              embedded: true,
                              showVehicleSection: false,
                              showOptionalPlateField: true,
                              standaloneInitial: widget.initialCustomer,
                              posVm: posVm,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.posTakeawaySelectPayment,
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
                                  initialIsCorporate: widget.initialIsCorporate,
                                  initialPayments: widget.initialPayments,
                                  initialPaymentAmounts:
                                      widget.initialPaymentAmounts,
                                  totalAmount: widget.totalAmount,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.posCommonCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
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
                      onPressed: _submit,
                      child: Text(l10n.posCommonSave),
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
