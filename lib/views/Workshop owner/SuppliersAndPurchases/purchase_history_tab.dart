import 'package:flutter/material.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../PurchaseInvoices/purchase_invoice_tax_view_sheet.dart';
import '../PurchaseInvoices/purchase_invoices_view_model.dart';
import '../widgets/owner_list_style.dart';
import 'suppliers_view_model.dart';

class PurchaseHistoryTab extends StatelessWidget {
  const PurchaseHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuppliersViewModel>();
    final invoices = vm.purchaseInvoices;
    final currency = vm.currencyCode ?? 'SAR';

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: invoices.isEmpty
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: const [
                SizedBox(height: 140),
                Center(
                  child: Text(
                    'No purchase invoices found',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _PurchaseInvoiceCard(
                  invoice: invoices[index],
                  currency: currency,
                );
              },
            ),
    );
  }
}

class _PurchaseInvoiceCard extends StatelessWidget {
  final PurchaseInvoiceEntity invoice;
  final String currency;

  const _PurchaseInvoiceCard({
    required this.invoice,
    required this.currency,
  });

  static String _fmtDate(BuildContext context, DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    final raw = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  $h:$m';
    return ownerLocalizeDigits(context, raw);
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (invoice.status) {
      case PurchaseInvoiceStatus.approved:
        return l10n.ownerPurchaseInvoicesStatusApproved;
      case PurchaseInvoiceStatus.completed:
        return l10n.ownerPurchaseInvoicesStatusCompleted;
      case PurchaseInvoiceStatus.delivered:
        return l10n.ownerPurchaseInvoicesStatusDelivered;
      case PurchaseInvoiceStatus.rejected:
        return l10n.ownerPurchaseInvoicesStatusRejected;
      case PurchaseInvoiceStatus.draft:
        return l10n.ownerPurchaseInvoicesStatusDraft;
      case PurchaseInvoiceStatus.pending:
        return l10n.ownerPurchaseInvoicesStatusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _statusLabel(l10n);
    final isApproved = invoice.status == PurchaseInvoiceStatus.approved ||
        invoice.status == PurchaseInvoiceStatus.completed;
    final isRejected = invoice.status == PurchaseInvoiceStatus.rejected;
    final paymentLabel = invoice.isPaid
        ? l10n.ownerPurchaseInvoicesPaid
        : invoice.paymentStatus == 'partially_paid'
            ? l10n.ownerPurchaseInvoicesPartial
            : l10n.ownerPurchaseInvoicesUnpaid;

    return GestureDetector(
      onTap: () => showPurchaseInvoiceTaxView(
        context,
        invoice: invoice,
        currency: currency,
      ),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: DecoratedBox(
                  decoration: OwnerListStyle.iconBoxDecoration,
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryLight,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LocalizedApiText(
                            invoice.vendorName.isEmpty
                                ? l10n.ownerPurchaseInvoicesUnknownVendor
                                : invoice.vendorName,
                            style: OwnerListStyle.titleStyle
                                .copyWith(fontSize: 14.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isRejected
                                ? const Color(0x14F44336)
                                : isApproved
                                    ? const Color(0x1427AE60)
                                    : const Color(0x38FCC247),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isRejected
                                  ? const Color(0xFFE53935)
                                  : isApproved
                                      ? const Color(0xFF169B4D)
                                      : AppColors.secondaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.invoiceNo.isNotEmpty
                          ? invoice.invoiceNo
                          : invoice.id,
                      style: OwnerListStyle.subtitleStyle
                          .copyWith(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.ownerPurchaseHistoryTotal}  ${ownerFormatMoney(context, invoice.grandTotal, currency: currency)}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _PurchaseMetaGrid(
                      children: [
                        _PurchaseMetaLine(
                          icon: Icons.account_balance_outlined,
                          text:
                              '${l10n.ownerSuppliersVat} ${ownerFormatMoney(context, invoice.totalTax, currency: currency)}',
                        ),
                        _PurchaseMetaLine(
                          icon: Icons.payments_outlined,
                          text: paymentLabel,
                        ),
                        _PurchaseMetaLine(
                          icon: Icons.inventory_2_outlined,
                          text: l10n.ownerPurchaseHistoryItems(
                            ownerLocalizeDigits(context, '${invoice.items.length}'),
                          ),
                        ),
                        _PurchaseMetaLine(
                          icon: Icons.access_time_rounded,
                          text: _fmtDate(context, invoice.issueDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseMetaGrid extends StatelessWidget {
  const _PurchaseMetaGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) {
      if (w is _PurchaseMetaLine) return w.text.trim().isNotEmpty;
      return true;
    }).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i += 2) {
      final left = visible[i];
      final right = i + 1 < visible.length ? visible[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < visible.length ? 2 : 0),
          child: Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 8),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _PurchaseMetaLine extends StatelessWidget {
  const _PurchaseMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 13, color: OwnerListStyle.mutedText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: OwnerListStyle.metaStyle.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
