import re
import sys

filepath = "/Users/fahad/Downloads/Filter Apps/Filter Project/Untitled/fliter-service-provider/lib/views/Workshop pos app/Order Screen/pos_order_review_view.dart"

with open(filepath, "r") as f:
    text = f.read()

# 1. State changes
text = text.replace("PaymentMethod? _selectedPayment;", "Set<PaymentMethod> _selectedPayments = {};")

# 2. _generateInvoice validation
old_validation = """    if (_isCorporate == false && _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }"""
new_validation = """    if (_isCorporate == false && _selectedPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one payment method.')),
      );
      return;
    }"""
text = text.replace(old_validation, new_validation)

# 3. Add split payment popup helper
popup_code = """
  Future<List<Map<String, dynamic>>?> _promptForSplitAmounts() async {
    if (_selectedPayments.length == 1) {
      return [{'method': _selectedPayments.first.label, 'amount': _totalAmount}];
    }

    final controllers = <PaymentMethod, TextEditingController>{};
    for (final pm in _selectedPayments) {
      controllers[pm] = TextEditingController();
    }

    return await showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentSum = 0;
            for (final c in controllers.values) {
              currentSum += double.tryParse(c.text.trim()) ?? 0.0;
            }
            final remaining = _totalAmount - currentSum;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.surfaceLight,
              title: Text(
                'Split Payment',
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
                          Text('Invoice Total', style: AppTextStyles.bodyMedium),
                          Text('${_totalAmount.toStringAsFixed(2)} SAR',
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._selectedPayments.map((pm) {
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
                                  Text(pm.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: controllers[pm],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _walkInInvoiceFieldDecoration('Amount (SAR)'),
                                onChanged: (_) => setDialogState(() {}),
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
                              ? 'Remaining: ${remaining.toStringAsFixed(2)} SAR'
                              : 'Exceeds total by ${(remaining.abs()).toStringAsFixed(2)} SAR',
                          style: TextStyle(
                            color: remaining > 0 ? Colors.orange.shade700 : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.secondaryLight)),
                ),
                FilledButton(
                  onPressed: remaining.abs() > 0.05
                      ? null
                      : () {
                          final result = <Map<String, dynamic>>[];
                          for (final pm in _selectedPayments) {
                            result.add({
                              'method': pm.label,
                              'amount': double.tryParse(controllers[pm]!.text.trim()) ?? 0.0,
                            });
                          }
                          Navigator.pop(ctx, result);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm amounts'),
                ),
              ],
            );
          },
        );
      },
    );
  }
"""
text = text.replace("void _generateInvoice() async {", popup_code + "\n  void _generateInvoice() async {")

# 4. In _generateInvoice (Takeaway preview part)
takeaway_old = """        takeawayVm.setPaymentMethod(
          _isCorporate == true ? 'corporate credit' : (_selectedPayment?.label ?? 'Cash'),
        );

        final checkoutRes = await takeawayVm.submitCheckout();"""
takeaway_new = """        List<Map<String, dynamic>>? paymentSplits;
        if (_isCorporate != true) {
          paymentSplits = await _promptForSplitAmounts();
          if (paymentSplits == null) {
            setState(() => _isLoading = false);
            return;
          }
        }

        if (_isCorporate == true) {
          takeawayVm.setPaymentMethod('corporate credit');
        } else if (paymentSplits!.length == 1) {
          takeawayVm.setPaymentMethod(paymentSplits.first['method']);
        } else {
          takeawayVm.setPayments(paymentSplits);
        }

        final checkoutRes = await takeawayVm.submitCheckout();"""
text = text.replace(takeaway_old, takeaway_new)

# 5. In _generateInvoice (Post order part)
pos_old = """      final response = await posVm.generateInvoice(
        widget.order.id,
        orderForBilling: widget.order,
        isCorporate: _isCorporate,
        paymentMethod: _isCorporate == true
            ? 'Corporate'
            : _selectedPayment?.label,
      );"""
pos_new = """      List<Map<String, dynamic>>? paymentSplits;
      if (_isCorporate != true) {
        paymentSplits = await _promptForSplitAmounts();
        if (paymentSplits == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final response = await posVm.generateInvoice(
        widget.order.id,
        orderForBilling: widget.order,
        isCorporate: _isCorporate,
        paymentMethod: _isCorporate == true ? 'Corporate' : (paymentSplits?.length == 1 ? paymentSplits!.first['method'] : null),
        payments: _isCorporate != true && paymentSplits!.length > 1 ? paymentSplits : null,
      );"""
text = text.replace(pos_old, pos_new)

# 6. UI: Widget building
selector_old = """                  _SectionCard(
                    title: 'Payment Method',
                    icon: Icons.payment_rounded,
                    child: _PaymentMethodSelector(
                      selected: _selectedPayment,
                      onChanged: (pm) => setState(() => _selectedPayment = pm),
                      isTablet: isTablet,
                    ),
                  ),"""

selector_new = """                  _SectionCard(
                    title: 'Payment Method (Select multiple if splitting)',
                    icon: Icons.payment_rounded,
                    child: _PaymentMethodSelector(
                      selected: _selectedPayments,
                      onChanged: (pms) => setState(() => _selectedPayments = pms),
                      isTablet: isTablet,
                    ),
                  ),"""
text = text.replace(selector_old, selector_new)

print("did replace 1:", takeaway_old in text) # Should be false if replaced
print("did replace 2:", pos_old in text)
print("did replace 3:", selector_old in text)

# 7. Print dialog
print_old = """        requestedPaymentMethod: _isCorporate == true
            ? 'Corporate (Monthly)'
            : _selectedPayment?.label,"""

print_new = """        requestedPaymentMethod: _isCorporate == true
            ? 'Corporate (Monthly)'
            : (_selectedPayments.length > 1 ? 'Split Payment' : _selectedPayments.firstOrNull?.label),"""
text = text.replace(print_old, print_new)

# 8. Component Class
comp_old = """class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod?> onChanged;
  final bool isTablet;
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PaymentMethod.values.map((pm) {
        final isSelected = selected == pm;
        return GestureDetector(
          onTap: () => onChanged(pm),"""

comp_new = """class _PaymentMethodSelector extends StatelessWidget {
  final Set<PaymentMethod> selected;
  final ValueChanged<Set<PaymentMethod>> onChanged;
  final bool isTablet;
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PaymentMethod.values.map((pm) {
        final isSelected = selected.contains(pm);
        return GestureDetector(
          onTap: () {
            final newSelection = Set.of(selected);
            if (isSelected) {
              newSelection.remove(pm);
            } else {
              newSelection.add(pm);
            }
            onChanged(newSelection);
          },"""
text = text.replace(comp_old, comp_new)

with open(filepath, "w") as f:
    f.write(text)

print("done")
