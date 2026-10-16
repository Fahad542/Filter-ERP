import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../utils/invoice_preview_capture_pdf.dart';
import '../widgets/owner_ui_constants.dart';
import 'purchase_invoices_view_model.dart';

/// Public web verify URL for workshop purchase invoices (matches web WPI view).
const String kWpiVerifyBaseUrl = 'https://www.filtercarservices.com';

Future<void> showPurchaseInvoiceTaxView(
  BuildContext context, {
  required PurchaseInvoiceEntity invoice,
  required String currency,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PurchaseInvoiceTaxViewSheet(
      invoice: invoice,
      currency: currency,
    ),
  );
}

/// Tax-invoice layout aligned with web `WorkshopPurchaseInvoiceView`
/// (`variant="workshop_receive"`), adapted for mobile width.
class PurchaseInvoiceTaxViewSheet extends StatefulWidget {
  final PurchaseInvoiceEntity invoice;
  final String currency;

  const PurchaseInvoiceTaxViewSheet({
    super.key,
    required this.invoice,
    required this.currency,
  });

  @override
  State<PurchaseInvoiceTaxViewSheet> createState() =>
      _PurchaseInvoiceTaxViewSheetState();
}

class _PurchaseInvoiceTaxViewSheetState
    extends State<PurchaseInvoiceTaxViewSheet> {
  final GlobalKey _pdfKey = GlobalKey();
  bool _pdfBusy = false;

  PurchaseInvoiceEntity get inv => widget.invoice;
  String get currency => widget.currency;

  String get _verifyUrl =>
      '$kWpiVerifyBaseUrl/verify/wpi/${Uri.encodeComponent(inv.id)}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String _fmtDateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _money(double v) =>
      '$currency ${v.toStringAsFixed(2)}';

  String _qty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  Future<void> _downloadPdf() async {
    if (_pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      final bytes = await InvoicePreviewCapturePdf.repaintBoundaryKeyToPdf(
        repaintBoundaryKey: _pdfKey,
        context: context,
      );
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate PDF')),
        );
        return;
      }
      final name = 'Filter-WPI-${inv.invoiceNo.isNotEmpty ? inv.invoiceNo : inv.id}.pdf';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: OwnerUi.sheetInitialSize,
      minChildSize: OwnerUi.sheetMinSize,
      maxChildSize: OwnerUi.sheetMaxSize,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tax Invoice',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _pdfBusy ? 'Preparing…' : 'Download PDF',
                      onPressed: _pdfBusy ? null : _downloadPdf,
                      icon: _pdfBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.download_rounded,
                              color: Color(0xFF2E7D32),
                            ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 24 + bottom),
                  child: RepaintBoundary(
                    key: _pdfKey,
                    child: ColoredBox(
                      color: Colors.white,
                      child: _TaxInvoiceBody(
                        invoice: inv,
                        currency: currency,
                        verifyUrl: _verifyUrl,
                        fmtDate: _fmtDate,
                        fmtDateIso: _fmtDateIso,
                        money: _money,
                        qty: _qty,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaxInvoiceBody extends StatelessWidget {
  const _TaxInvoiceBody({
    required this.invoice,
    required this.currency,
    required this.verifyUrl,
    required this.fmtDate,
    required this.fmtDateIso,
    required this.money,
    required this.qty,
  });

  final PurchaseInvoiceEntity invoice;
  final String currency;
  final String verifyUrl;
  final String Function(DateTime) fmtDate;
  final String Function(DateTime) fmtDateIso;
  final String Function(double) money;
  final String Function(double) qty;

  static const _red = Color(0xFFC62828);
  static const _green = Color(0xFF1B5E20);
  static const _greenSoft = Color(0xFFE8F5E9);
  static const _notesBg = Color(0xFFFFF8E1);
  static const _categories = [
    'OEM PARTS',
    'LUBRICANTS',
    'FILTERS',
    'FLUIDS',
    'BATTERIES',
    'WORKSHOP SUPPLY',
    'WHOLESALE',
    'RETAIL',
  ];

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    final paymentLabel = inv.isPaid
        ? 'Paid'
        : inv.paymentStatus == 'partially_paid'
            ? 'Partially paid'
            : 'Unpaid';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: seller + logo + QR ───────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.vendorName.isNotEmpty
                          ? inv.vendorName
                          : 'FILTER - WAREHOUSE',
                      style: const TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automotive parts & supplies',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'VAT No. —',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  QrImageView(
                    data: verifyUrl,
                    size: 72,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 88,
                    child: Text(
                      'Scan to receive\nstock & invoice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        height: 1.2,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verifyUrl,
            style: TextStyle(
              fontSize: 8.5,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),
          // ── Category pills ───────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _categories.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '|',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    _categories[i],
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          // ── Tax Invoice ribbon ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _greenSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _green.withValues(alpha: 0.25)),
            ),
            child: const Column(
              children: [
                Text(
                  'فاتورة ضريبية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'TAX INVOICE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // ── Customer + Invoice details ───────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetaPanel(
                  title: 'CUSTOMER',
                  rows: [
                    ('Customer name',
                        inv.branchName.isNotEmpty ? inv.branchName : '—'),
                    ('Customer mobile', '—'),
                    ('Customer VAT no.', '—'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetaPanel(
                  title: 'INVOICE DETAILS',
                  twoColumns: true,
                  rows: [
                    (
                      'Invoice no.',
                      inv.invoiceNo.isNotEmpty ? inv.invoiceNo : inv.id
                    ),
                    ('Issue date', fmtDateIso(inv.issueDate)),
                    ('Due date', fmtDateIso(inv.dueDate)),
                    (
                      'Vendor reference',
                      inv.ref.isNotEmpty ? inv.ref : '—'
                    ),
                    ('Payment', paymentLabel),
                  ],
                ),
              ),
            ],
          ),

          if (inv.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _notesBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                'Notes: ${inv.description.trim()}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // ── Line items ───────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: _green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Unit',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'VAT',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (inv.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No line items',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                else
                  ...inv.items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    final bg = i.isOdd
                        ? const Color(0xFFF9FAFB)
                        : Colors.white;
                    return Container(
                      color: bg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              item.productName.isNotEmpty
                                  ? item.productName
                                  : (item.description.isNotEmpty
                                      ? item.description
                                      : 'Item'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                                height: 1.25,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${qty(item.qty)}${item.uom.isNotEmpty ? '\n${item.uom}' : ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.grey.shade800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              money(item.unitPrice),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              money(item.totalExcl),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              money(item.taxAmt),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // ── Totals (full width) ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _TotalLine('Total (ex VAT)', money(inv.subtotal)),
                if (inv.discount > 0)
                  _TotalLine('Discount', '- ${money(inv.discount)}'),
                if (inv.freight > 0)
                  _TotalLine('Freight', money(inv.freight)),
                _TotalLine('VAT', money(inv.totalTax)),
                const Divider(height: 12),
                _TotalLine(
                  'Net total',
                  money(inv.grandTotal),
                  bold: true,
                ),
                _TotalLine('Amount paid', money(inv.amountPaid)),
                _TotalLine(
                  'Balance due',
                  money(inv.balance),
                  bold: true,
                  valueColor: inv.balance > 0
                      ? const Color(0xFFC62828)
                      : _green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Text(
            'Filter — workshop purchase invoice · receive stock & invoice',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Issued ${fmtDate(inv.issueDate)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({
    required this.title,
    required this.rows,
    this.twoColumns = false,
  });

  final String title;
  final List<(String, String)> rows;
  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          if (!twoColumns)
            for (final row in rows) ...[
              _MetaField(label: row.$1, value: row.$2),
              const SizedBox(height: 6),
            ]
          else
            ...List.generate((rows.length + 1) ~/ 2, (i) {
              final left = rows[i * 2];
              final right = i * 2 + 1 < rows.length ? rows[i * 2 + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetaField(label: left.$1, value: left.$2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: right == null
                          ? const SizedBox.shrink()
                          : _MetaField(label: right.$1, value: right.$2),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine(
    this.label,
    this.value, {
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
