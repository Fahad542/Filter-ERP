import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../Collection/record_collection_view.dart';
import '../widgets/locker_dashboard_shared_widgets.dart'
    show localizedLockerCollectionStatus;
import 'locker_request_details_view_model.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerRequestDetailsView extends StatelessWidget {
  final String requestId;

  const LockerRequestDetailsView({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerRequestDetailsViewModel(requestId: requestId),
      child: const _LockerRequestDetailsBody(),
    );
  }
}

// ── Inner StatefulWidget ──────────────────────────────────────────────────────

class _LockerRequestDetailsBody extends StatefulWidget {
  const _LockerRequestDetailsBody();

  @override
  State<_LockerRequestDetailsBody> createState() =>
      _LockerRequestDetailsBodyState();
}

class _LockerRequestDetailsBodyState
    extends State<_LockerRequestDetailsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.read<LockerRequestDetailsViewModel>().init(l10n);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LockerRequestDetailsViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: Text(
              AppLocalizations.of(context)!.lockerRequestDetailsTitle,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 18,
              ),
            ),
            showDrawer: false,
            showBackButton: true,
            onBackPressed: () => Navigator.maybePop(context),
          ),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  // ── PDF Generation ────────────────────────────────────────────────────────
  // NOTE: PDF content uses the l10n strings passed in at generation time.
  // The PDF is always generated with the current locale strings.

  Future<void> _generateAndSharePdf(
      BuildContext context, LockerRequestDetail detail) async {
    final l10n = AppLocalizations.of(context)!;
    final doc = pw.Document();

    final headerColor = PdfColor.fromHex('2E323A');
    final labelColor = PdfColors.grey600;
    final dividerColor = PdfColors.grey300;

    final generatedAt =
    DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final localizedStatus = _localizedStatus(context, detail.status);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      l10n.lockerLoaderAuditReport,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      detail.referenceCode,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: labelColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _pdfStatusColor(detail.status),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    localizedStatus,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: dividerColor, thickness: 1),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: dividerColor, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${l10n.lockerGeneratedAt}: $generatedAt',
                  style: pw.TextStyle(fontSize: 8, color: labelColor),
                ),
                pw.Text(
                  '${l10n.lockerPage} ${context.pageNumber} ${l10n.lockerOf} ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: labelColor),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // ── Secured Asset Hero ────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: headerColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  l10n.lockerTotalSecuredAsset,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${detail.currency} ${detail.totalSecuredAsset.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Request Information ───────────────────────────────────────────
          _pdfSectionTitle(l10n.lockerRequestInformation),
          pw.SizedBox(height: 8),
          _pdfInfoTable([
            _pdfRow(l10n.lockerSourceBranch, detail.branchName),
            _pdfRow(l10n.lockerCashier, detail.cashierName),
            _pdfRow(
              l10n.lockerShiftCloseTime,
              DateFormat('dd MMM yyyy, hh:mm a')
                  .format(detail.shiftCloseTime.toLocal()),
            ),
            if (detail.assignedOfficerName != null)
              _pdfRow(l10n.lockerAssignedOfficer, detail.assignedOfficerName!),
          ]),

          pw.SizedBox(height: 20),

          // ── POS Session ───────────────────────────────────────────────────
          if (detail.posSession != null) ...[
            _pdfSectionTitle(l10n.lockerPosSession),
            pw.SizedBox(height: 8),
            _pdfInfoTable([
              _pdfRow(
                l10n.lockerOpenedAt,
                DateFormat('dd MMM yyyy, hh:mm a')
                    .format(detail.posSession!.openedAt.toLocal()),
              ),
              _pdfRow(
                l10n.lockerClosedAt,
                DateFormat('dd MMM yyyy, hh:mm a')
                    .format(detail.posSession!.closedAt.toLocal()),
              ),
              _pdfRow(
                l10n.lockerSessionStatus,
                localizedLockerCollectionStatus(
                  l10n,
                  detail.posSession!.status,
                ),
              ),
            ]),
            pw.SizedBox(height: 20),
          ],

          // ── Counter Closing ───────────────────────────────────────────────
          if (detail.counterClosing != null) ...[
            _pdfSectionTitle(l10n.lockerCounterClosing),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: dividerColor),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  _pdfStatCell(
                    l10n.lockerPhysicalCash,
                    '${detail.currency} ${detail.counterClosing!.physicalCash.toStringAsFixed(2)}',
                    PdfColors.teal700,
                    isFirst: true,
                  ),
                  _pdfStatCell(
                    l10n.lockerSystemTotal,
                    '${detail.currency} ${detail.counterClosing!.systemCashTotal.toStringAsFixed(2)}',
                    PdfColors.blue700,
                  ),
                  _pdfStatCell(
                    l10n.lockerDifference,
                    '${detail.currency} ${detail.counterClosing!.cashDiff.toStringAsFixed(2)}',
                    detail.counterClosing!.cashDiff != 0
                        ? PdfColors.red700
                        : PdfColors.green700,
                    isLast: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Collection Record ─────────────────────────────────────────────
          if (detail.collection != null) ...[
            _pdfSectionTitle(l10n.lockerCollectionRecord),
            pw.SizedBox(height: 8),
            _pdfInfoTable([
              _pdfRow(
                l10n.lockerReceivedAmount,
                '${detail.currency} ${detail.collection!.receivedAmount.toStringAsFixed(2)}',
              ),
              _pdfRow(
                l10n.lockerDifference,
                '${detail.currency} ${detail.collection!.difference.abs().toStringAsFixed(2)}',
              ),
              if (detail.collection!.notes != null &&
                  detail.collection!.notes!.isNotEmpty)
                _pdfRow(l10n.lockerNotes, detail.collection!.notes!),
            ]),
            pw.SizedBox(height: 20),
          ],

          // ── Footer Note ───────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              '${l10n.lockerAuditFootnote} '
                  '${l10n.lockerAuditFootnoteAmounts(detail.currency)}',
              style: pw.TextStyle(
                fontSize: 8,
                color: labelColor,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'audit_${detail.referenceCode}.pdf',
    );
  }

  // ── PDF helpers ────────────────────────────────────────────────────────────

  PdfColor _pdfStatusColor(LockerStatus status) {
    switch (status) {
      case LockerStatus.pending:
        return PdfColors.orange700;
      case LockerStatus.assigned:
        return PdfColors.blue700;
      case LockerStatus.collected:
        return PdfColors.teal700;
      case LockerStatus.awaitingApproval:
        return PdfColors.purple700;
      case LockerStatus.approved:
        return PdfColors.green700;
      case LockerStatus.rejected:
        return PdfColors.red700;
    }
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey700,
        letterSpacing: 1.5,
      ),
    );
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('2E323A'),
          ),
        ),
      ),
    ]);
  }

  pw.Widget _pdfInfoTable(List<pw.TableRow> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  pw.Widget _pdfStatCell(
      String label,
      String value,
      PdfColor color, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: isLast
                ? const pw.BorderSide(style: pw.BorderStyle.none)
                : pw.BorderSide(color: PdfColors.grey300),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.grey500,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body dispatcher ───────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, LockerRequestDetailsViewModel vm) {
    if (vm.isDetailLoading) return _buildLoader(context);
    if (vm.isDetailError) return _buildError(context, vm);
    if (vm.detail == null) return _buildLoader(context);

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(context, vm.detail!),
            const SizedBox(height: 24),
            _buildLockedCashSection(context, vm.detail!),
            const SizedBox(height: 24),
            _buildCounterClosingSection(context, vm.detail!),
            const SizedBox(height: 24),
            if (vm.detail!.collection != null) ...[
              _buildCollectionResultSection(context, vm.detail!),
              const SizedBox(height: 24),
            ],
            _buildTransactionDetails(context, vm.detail!),
            const SizedBox(height: 32),
            _buildActionButtons(context, vm),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────────

  Widget _buildLoader(BuildContext context) {
    return const OwnerFormPageShimmer(fieldCount: 5);
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(
      BuildContext context, LockerRequestDetailsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.lockerFailedLoadDetails,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              vm.detailError ?? l10n.lockerUnexpectedError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: vm.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.lockerRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status header ─────────────────────────────────────────────────────────

  Widget _buildStatusHeader(BuildContext context, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(detail.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lockerSystemStatus,
                style: TextStyle(
                  color: color.withOpacity(0.5),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _localizedStatus(context, detail.status),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              detail.referenceCode,
              style: TextStyle(
                color: AppColors.secondaryLight.withOpacity(0.5),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ── Locked-cash section ───────────────────────────────────────────────────

  Widget _buildLockedCashSection(
      BuildContext context, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E323A), AppColors.secondaryLight],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded,
                color: AppColors.primaryLight, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            '${detail.currency} ${detail.totalSecuredAsset.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.lockerTotalSecuredAsset,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  // ── Counter-closing breakdown ─────────────────────────────────────────────

  Widget _buildCounterClosingSection(
      BuildContext context, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final cc = detail.counterClosing;
    if (cc == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerCounterClosing,
          style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: OwnerListStyle.cardDecoration,
          child: Row(
            children: [
              _buildCounterStat(
                label: l10n.lockerPhysicalCash,
                value: '${detail.currency} ${cc.physicalCash.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                color: Colors.teal,
              ),
              _buildDivider(),
              _buildCounterStat(
                label: l10n.lockerSystemTotal,
                value: '${detail.currency} ${cc.systemCashTotal.toStringAsFixed(0)}',
                icon: Icons.computer_outlined,
                color: Colors.blue,
              ),
              _buildDivider(),
              _buildCounterStat(
                label: l10n.lockerDifference,
                value: '${detail.currency} ${cc.cashDiff.toStringAsFixed(0)}',
                icon: Icons.compare_arrows_rounded,
                color: cc.cashDiff != 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Collection result panel ───────────────────────────────────────────────

  Widget _buildCollectionResultSection(
      BuildContext context, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final col = detail.collection!;
    final hasDiff = col.difference.abs() > 0;
    final diffColor = hasDiff ? Colors.red : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerCollectionRecord,
          style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: OwnerListStyle.cardDecoration.copyWith(
            border: Border.all(
              color: hasDiff
                  ? Colors.red.withOpacity(0.15)
                  : OwnerListStyle.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildCounterStat(
                    label: l10n.lockerReceived,
                    value: '${detail.currency} ${col.receivedAmount.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.teal,
                  ),
                  _buildDivider(),
                  _buildCounterStat(
                    label: l10n.lockerDifference,
                    value: '${detail.currency} ${col.difference.abs().toStringAsFixed(0)}',
                    icon: Icons.compare_arrows_rounded,
                    color: diffColor,
                  ),
                ],
              ),
              if (col.notes != null && col.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OwnerUi.contentBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded,
                          size: 14, color: OwnerListStyle.mutedText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          col.notes!,
                          style: OwnerListStyle.metaStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Container(
    width: 1,
    height: 40,
    color: Colors.black.withOpacity(0.05),
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );

  Widget _buildCounterStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black.withOpacity(0.3),
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  // ── Transaction details ───────────────────────────────────────────────────

  Widget _buildTransactionDetails(
      BuildContext context, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerInternalData,
          style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: OwnerListStyle.cardDecoration,
          child: Column(
            children: [
              _buildDetailItem(
                l10n.lockerSourceBranch,
                detail.branchName,
                Icons.location_on_outlined,
              ),
              _buildDetailItem(
                l10n.lockerCashierIdentity,
                detail.cashierName,
                Icons.person_outline,
              ),
              _buildDetailItem(
                l10n.lockerShiftCloseTime,
                DateFormat('dd MMM, hh:mm a')
                    .format(detail.shiftCloseTime.toLocal()),
                Icons.access_time,
              ),
              if (detail.posSession != null) ...[
                _buildDetailItem(
                  l10n.lockerSessionOpened,
                  DateFormat('dd MMM, hh:mm a')
                      .format(detail.posSession!.openedAt.toLocal()),
                  Icons.login_rounded,
                ),
                _buildDetailItem(
                  l10n.lockerSessionClosed,
                  DateFormat('dd MMM, hh:mm a')
                      .format(detail.posSession!.closedAt.toLocal()),
                  Icons.logout_rounded,
                ),
              ],
              if (detail.assignedOfficerName != null)
                _buildDetailItem(
                  l10n.lockerAssignedOfficer,
                  detail.assignedOfficerName!,
                  Icons.assignment_ind_outlined,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          OwnerListIconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: OwnerListStyle.metaStyle.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: OwnerListStyle.titleStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons (role-aware) ───────────────────────────────────────────

  Widget _buildActionButtons(
      BuildContext context, LockerRequestDetailsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final detail = vm.detail!;

    // ── SUPERVISOR ──────────────────────────────────────────────────────────

    if (vm.isSupervisor) {
      if (detail.status == LockerStatus.pending) {
        return _PrimaryButton(
          label: l10n.lockerAssignCollectionOfficer,
          icon: Icons.person_add_alt_1_rounded,
          onTap: () => _openOfficerSheet(context, vm),
        );
      }

      if (detail.status == LockerStatus.assigned) {
        final isSelfAssigned = detail.assignedOfficerId != null &&
            detail.assignedOfficerId == vm.userId;

        return Column(
          children: [
            if (isSelfAssigned) ...[
              _PrimaryButton(
                label: l10n.lockerProceedToCollection,
                icon: Icons.arrow_forward_rounded,
                onTap: () => _navigateToCollection(context, detail),
              ),
              const SizedBox(height: 10),
            ],
            _SecondaryButton(
              label: l10n.lockerGenerateAuditPdf,
              icon: Icons.picture_as_pdf_outlined,
              onTap: () => _generateAndSharePdf(context, detail),
            ),
          ],
        );
      }

      if (detail.status == LockerStatus.awaitingApproval) {
        final collectionId = detail.collection?.id;

        if (collectionId == null) {
          return _InfoBanner(
            message: l10n.lockerCollectionPendingApproval,
            color: Colors.orange,
          );
        }

        return _buildVarianceApprovalSection(context, vm, collectionId);
      }
    }

    // ── COLLECTOR ───────────────────────────────────────────────────────────

    if (vm.isCollector) {
      if (detail.status == LockerStatus.assigned) {
        return Column(
          children: [
            _PrimaryButton(
              label: l10n.lockerProceedToCollection,
              icon: Icons.arrow_forward_rounded,
              onTap: () => _navigateToCollection(context, detail),
            ),
            const SizedBox(height: 10),
            _SecondaryButton(
              label: l10n.lockerGenerateAuditPdf,
              icon: Icons.picture_as_pdf_outlined,
              onTap: () => _generateAndSharePdf(context, detail),
            ),
          ],
        );
      }

      if (detail.status == LockerStatus.collected ||
          detail.status == LockerStatus.awaitingApproval) {
        return _InfoBanner(
          message: detail.status == LockerStatus.awaitingApproval
              ? l10n.lockerPendingSupervisorApproval
              : l10n.lockerCollectedSuccessfully,
          color: detail.status == LockerStatus.awaitingApproval
              ? Colors.orange
              : Colors.teal,
        );
      }
    }

    // ── Terminal states ─────────────────────────────────────────────────────

    if (detail.status == LockerStatus.approved) {
      return _InfoBanner(
        message: l10n.lockerVarianceApproved,
        color: Colors.green,
      );
    }

    if (detail.status == LockerStatus.rejected) {
      return _InfoBanner(
        message: l10n.lockerVarianceRejectedBanner,
        color: Colors.red,
      );
    }

    return const SizedBox.shrink();
  }

  // ── Variance approval widget ──────────────────────────────────────────────

  Widget _buildVarianceApprovalSection(
      BuildContext context,
      LockerRequestDetailsViewModel vm,
      String collectionId,
      ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBanner(
          message: l10n.lockerVarianceDifferenceReview,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        if (vm.varianceActionError != null)
          _ErrorBanner(message: vm.varianceActionError!),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: vm.isVarianceProcessing
                      ? null
                      : () async {
                    final ok =
                    await vm.approveVariance(collectionId: collectionId);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.lockerApproveVariance),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: vm.isVarianceProcessing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: Text(l10n.lockerApprove,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: vm.isVarianceProcessing
                      ? null
                      : () => _showRejectDialog(context, vm, collectionId),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(l10n.lockerReject,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Reject dialog ─────────────────────────────────────────────────────────

  void _showRejectDialog(
      BuildContext context,
      LockerRequestDetailsViewModel vm,
      String collectionId,
      ) {
    final l10n = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.lockerRejectVarianceTitle,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lockerRejectVarianceBody,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.lockerRejectionReasonHint,
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.lockerCancel,
                style: const TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.rejectVariance(
                collectionId: collectionId,
                rejectionReason: reasonCtrl.text.trim(),
              );
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.lockerVarianceRejected),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.lockerConfirmReject,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigateToCollection(
      BuildContext context, LockerRequestDetail detail) {
    final request = LockerRequest(
      id                 : detail.id,
      referenceCode      : detail.referenceCode,
      branchName         : detail.branchName,
      cashierName        : detail.cashierName,
      closingDate        : detail.shiftCloseTime,
      lockedCashAmount   : detail.totalSecuredAsset,
      status             : detail.status,
      assignedOfficerId  : detail.assignedOfficerId,
      assignedOfficerName: detail.assignedOfficerName,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordCollectionView(request: request),
      ),
    );
  }

  // ── Officer bottom sheet ──────────────────────────────────────────────────

  Future<void> _openOfficerSheet(
      BuildContext context, LockerRequestDetailsViewModel vm) async {
    await vm.loadOfficersIfNeeded();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<LockerRequestDetailsViewModel>(
          builder: (ctx, vm2, _) {
            final l10n = AppLocalizations.of(ctx)!;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      l10n.lockerSelectOfficer,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryLight,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.lockerSelectOfficerSubtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.4)),
                    ),
                    const SizedBox(height: 16),
                    if (vm2.assignError != null)
                      _ErrorBanner(message: vm2.assignError!),
                    if (vm2.isOfficersLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryLight))
                    else if (vm2.officersState == LockerOfficersState.error)
                      _OfficersErrorState(
                        message: vm2.officersError ??
                            l10n.lockerOfficersLoadError,
                        onRetry: vm2.loadOfficersIfNeeded,
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: vm2.officers.length,
                          separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final officer = vm2.officers[i];
                            final isAssigning =
                                vm2.isAssigning &&
                                    vm2.assigningOfficerId == officer.id;
                            final isDisabled = vm2.isAssigning;

                            return _OfficerTile(
                              officer: officer,
                              isAssigning: isAssigning,
                              isDisabled: isDisabled,
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(
                                      l10n.lockerAssignCollectionOfficer,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.secondaryLight,
                                      ),
                                    ),
                                    content: Text(
                                      '${l10n.lockerAssignedTo} ${officer.name}?',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, false),
                                        child: Text(l10n.lockerCancel),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.secondaryLight,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.lockerAssignCollectionOfficer,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                final success =
                                await vm2.assignOfficer(officer.id);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${l10n.lockerAssignedTo} ${officer.name.toUpperCase()}'),
                                      backgroundColor:
                                      AppColors.secondaryLight,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Status colour helper ──────────────────────────────────────────────────

  Color _statusColor(LockerStatus status) {
    switch (status) {
      case LockerStatus.pending:
        return Colors.orange;
      case LockerStatus.assigned:
        return Colors.blue;
      case LockerStatus.collected:
        return Colors.teal;
      case LockerStatus.awaitingApproval:
        return Colors.purple;
      case LockerStatus.approved:
        return Colors.green;
      case LockerStatus.rejected:
        return Colors.red;
    }
  }

  /// Returns the fully localized UI label for a [LockerStatus].
  String _localizedStatus(BuildContext context, LockerStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case LockerStatus.pending:
        return l10n.lockerStatusPending;
      case LockerStatus.assigned:
        return l10n.lockerStatusAssigned;
      case LockerStatus.awaitingApproval:
        return l10n.lockerStatusAwaiting;
      case LockerStatus.collected:
        return l10n.lockerStatusCollected;
      case LockerStatus.approved:
        return l10n.lockerStatusApproved;
      case LockerStatus.rejected:
        return l10n.lockerStatusRejected;
    }
  }
}

// ── Officer tile ──────────────────────────────────────────────────────────────

class _OfficerTile extends StatelessWidget {
  final LockerOfficer officer;
  final bool isAssigning;
  final bool isDisabled;
  final VoidCallback onTap;

  const _OfficerTile({
    required this.officer,
    required this.isAssigning,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !isDisabled,
      leading: CircleAvatar(
        backgroundColor: AppColors.secondaryLight.withOpacity(0.05),
        child: const Icon(Icons.person_3_outlined,
            color: AppColors.secondaryLight, size: 20),
      ),
      title: Text(
        officer.name,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: isDisabled
              ? AppColors.secondaryLight.withOpacity(0.4)
              : AppColors.secondaryLight,
        ),
      ),
      subtitle: Text(
        officer.displayCode,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      trailing: isAssigning
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primaryLight),
      )
          : const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.black12),
      onTap: isDisabled ? null : onTap,
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.secondaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          side: BorderSide(
              color: AppColors.secondaryLight.withOpacity(0.15)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _InfoBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficersErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _OfficersErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: Colors.red.shade300, size: 36),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 12)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.lockerRetry),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryLight),
          ),
        ],
      ),
    );
  }
}