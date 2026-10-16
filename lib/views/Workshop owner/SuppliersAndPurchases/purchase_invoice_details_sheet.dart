import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';

Future<void> showPurchaseInvoiceDetails(BuildContext context, PurchaseInvoice invoice) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PurchaseInvoiceDetailsSheet(invoice: invoice),
  );
}

class PurchaseInvoiceDetailsSheet extends StatelessWidget {
  final PurchaseInvoice invoice;
  const PurchaseInvoiceDetailsSheet({super.key, required this.invoice});

  double get vat => invoice.totalAmount * .15;
  double get grandTotal => invoice.totalAmount + vat;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width > 760 ? 680 : width),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
              child: Column(
                children: [
                  _header(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _invoiceHero(),
                          const SizedBox(height: 18),
                          _sectionTitle('Invoice details'),
                          _detailGrid(),
                          const SizedBox(height: 18),
                          _sectionTitle('Items'),
                          ...invoice.items.map(_itemRow),
                          const SizedBox(height: 18),
                          _totals(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3)))),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, color: AppColors.secondaryLight),
          const SizedBox(width: 10),
          Expanded(child: Text('Purchase invoice', style: AppTextStyles.h2.copyWith(fontSize: 21, color: AppColors.secondaryLight))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
            child: Text(invoice.status.toLowerCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F3F7)),
          ),
        ],
      ),
    );
  }

  Widget _invoiceHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(.18), borderRadius: BorderRadius.circular(14)),
            child: const Text('TAX INVOICE', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ),
          const SizedBox(height: 16),
          Text(invoice.supplierName, textAlign: TextAlign.center, style: AppTextStyles.h2.copyWith(fontSize: 18, color: AppColors.secondaryLight)),
          const SizedBox(height: 6),
          const Text('Specialist procurement & inventory for automotive workshops', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.secondaryLight, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    );
  }

  Widget _detailGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _detailTile('Invoice no.', invoice.id),
        _detailTile('Supplier', invoice.supplierName),
        _detailTile('Date', '${invoice.date.year}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.day.toString().padLeft(2, '0')}'),
        _detailTile('Payment', 'unpaid'),
      ],
    );
  }

  Widget _detailTile(String label, String value) {
    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7E9EE))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _itemRow(PurchaseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OwnerUi.scaffoldBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(child: Text(item.productName, style: const TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w900))),
        Text('${item.qty.g} ${item.unit}', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
        const SizedBox(width: 14),
        Text('SAR ${item.total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _totals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E9EE))),
      child: Column(children: [
        _totalRow('Subtotal', invoice.totalAmount),
        _totalRow('VAT', vat),
        const Divider(height: 24),
        _totalRow('Grand total', grandTotal, strong: true),
      ]),
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: strong ? AppColors.secondaryLight : const Color(0xFF6B7280), fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
        Text('SAR ${value.toStringAsFixed(2)}', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w900, fontSize: strong ? 18 : 14)),
      ]),
    );
  }
}

extension on num {
  String get g => this % 1 == 0 ? toInt().toString() : toStringAsFixed(2);
}
