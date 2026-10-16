import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import 'package:provider/provider.dart';

import '../../../services/cashier_open_session_guard.dart';
import '../../../services/network_thermal_printer.dart';
import '../../../services/store_closing_print_prefetch.dart';
import '../../../services/thermal_print_isolate_pipeline.dart';
import '../../../services/thermal_printer_settings.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_keyboard_locale.dart';
import '../../../utils/toast_service.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/business_timezone.dart';
import '../Home Screen/pos_view_model.dart';
import '../../Menu/menu_view.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/thermal_printer_wifi_dialog.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../Login/login_view_model.dart';
import 'package:filter_service_providers/utils/restart_widget.dart';
import '../../../models/store_closing_model.dart';
import 'store_closing_view_model.dart';

class PosStoreClosingView extends StatefulWidget {
  const PosStoreClosingView({super.key});

  @override
  State<PosStoreClosingView> createState() => _PosStoreClosingViewState();
}

class _PosStoreClosingViewState extends State<PosStoreClosingView> {
  List<int>? _cachedClosingEscPosBytes;
  String? _closingEscPosCacheKey;
  final TextEditingController _departmentSearchController =
      TextEditingController();
  String _departmentSearchQuery = '';

  /// Drives the in-button spinner on the Store Closing **Print** button so
  /// the cashier gets immediate feedback the moment they tap it. Stays
  /// `true` from the tap until raster + ESC/POS encode + TCP send all
  /// finish (or fail) so back-to-back taps can't double-fire.
  bool _isPrintingClosing = false;

  String _closingEscPosCacheKeyFor(
    StoreClosingReport report,
    String? closingId,
  ) =>
      '${closingId ?? ''}_${report.timestamp.millisecondsSinceEpoch}';

  void _warmClosingPrintCache(StoreClosingReport report, String? closingId) {
    final key = _closingEscPosCacheKeyFor(report, closingId);
    if (_closingEscPosCacheKey == key) return;
    _closingEscPosCacheKey = key;
    _cachedClosingEscPosBytes = null;
    StoreClosingPrintPrefetch.start(report: report, closingId: closingId);
  }

  Future<List<int>> _resolveClosingEscPosBytes({
    required StoreClosingReport report,
    String? closingId,
  }) async {
    final key = _closingEscPosCacheKeyFor(report, closingId);
    if (_closingEscPosCacheKey == key &&
        _cachedClosingEscPosBytes != null &&
        _cachedClosingEscPosBytes!.isNotEmpty) {
      return _cachedClosingEscPosBytes!;
    }

    Uint8List? prefetchedPdf;
    final pdfPending = StoreClosingPrintPrefetch.pdfFutureFor(report, closingId);
    if (pdfPending != null) {
      prefetchedPdf = await pdfPending;
      StoreClosingPrintPrefetch.discard(report, closingId);
    }

    await WidgetsBinding.instance.endOfFrame;

    final bytes = await prepareStoreClosingEscPosBytesOffUi(
      report: report,
      closingId: closingId,
      prefetchedPdfBytes: prefetchedPdf,
    );
    _closingEscPosCacheKey = key;
    _cachedClosingEscPosBytes = bytes;
    return bytes;
  }

  Future<void> _handoffClosingEscPosBytesToTcpPrinter(List<int> bytes) async {
    if (bytes.isEmpty) {
      throw StateError('Could not prepare store closing receipt for printing.');
    }
    final cfg = await ThermalPrinterSettings.load();
    await sendEscPosBytesToTcpPrinter(
      host: cfg.host,
      port: cfg.port,
      bytes: bytes,
    );
  }

  /// Fire-and-forget store-closing print: build PDF (isolate) → raster + ESC/POS
  /// → TCP send. Reconcile screen stays interactive; user can tap Logout or
  /// Print again. Toasts via root [ScaffoldMessenger] so they survive logout
  /// navigation.
  Future<void> _runStoreClosingPrintInBackground({
    required StoreClosingReport report,
    required String? closingId,
    required String successMessage,
  }) async {
    BuildContext resolveToastCtx() {
      if (mounted) return context;
      return ToastService.scaffoldMessengerKey.currentContext ?? context;
    }

    // Flip the in-button spinner ON immediately so the cashier sees feedback
    // the same frame they tapped Print. If we're already mid-print, ignore
    // the second tap (the flag also gates the button's onPressed below).
    if (_isPrintingClosing) return;
    if (mounted) setState(() => _isPrintingClosing = true);

    try {
      final bytes = await _resolveClosingEscPosBytes(
        report: report,
        closingId: closingId,
      );
      await _handoffClosingEscPosBytesToTcpPrinter(bytes);
      final ctx = resolveToastCtx();
      if (ctx.mounted) {
        ToastService.showSuccess(ctx, successMessage);
      }
    } catch (e) {
      final ctx = resolveToastCtx();
      if (ctx.mounted) {
        ToastService.showError(ctx, 'Print failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isPrintingClosing = false);
    }
  }

  @override
  void dispose() {
    _departmentSearchController.dispose();
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
      final vm = context.read<StoreClosingViewModel>();
      // After a successful close, [PosShell] swaps the body subtree (rail + inner
      // IndexedStack vs plain IndexedStack). That can remount this widget; do not
      // reset here or the reconciliation / difference UI vanishes immediately.
      if (!vm.isReconciled) {
        vm.reset();
        unawaited(vm.loadSummary());
      }
      // Store-closing GET summary loads on enter for session start + department breakdown.
    });
  }


  String _storeDigits(Object? value) {
    return AppTranslationService.localizeDigitsForLanguage(
      value?.toString() ?? '',
      Localizations.localeOf(context).languageCode,
    );
  }

  String _storeMoney(num amount) {
    return AppLocalizations.of(context)!
        .posSalesReturnSarAmount(_storeDigits(amount.toStringAsFixed(2)));
  }

  String _storeSignedAmount(num amount) {
    final sign = amount >= 0 ? '+' : '';
    return _storeDigits('$sign${amount.toStringAsFixed(2)}');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isReconciled = context.watch<StoreClosingViewModel>().isReconciled;
    // PosViewModel exposes only static post-login fields here
    // (cashierName / branchName / workshopName). Read it WITHOUT listening so
    // socket / realtime / order-list notifyListeners() events on PosVm do not
    // rebuild this screen's form & text fields — that was the root cause of
    // keyboard reveal lag and the "screen feels stuck" behaviour while typing.
    final posVm = context.read<PosViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PosScreenAppBar(
        title: AppLocalizations.of(context)!.posStoreClosingTitle,
        showBackButton: false,
        showHamburger: false,
        minimalTrailingActions: isReconciled,
      ),
      body: wrapPosShellRailBody(
        context,
        Consumer<StoreClosingViewModel>(
        builder: (context, closingVm, _) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final footerPad = closingVm.isReconciled ? 88.0 : 0.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              14,
              10,
              14,
              10 + keyboardHeight + footerPad,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReconciliationSummary(isTablet, posVm, closingVm),
                const SizedBox(height: 18),
                if (closingVm.isReconciled) ...[
                  _buildDepartmentSalesSection(closingVm),
                  const SizedBox(height: 18),
                ],
                Divider(
                  height: 28,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 10),
                _buildSectionTitle(AppLocalizations.of(context)!.posStoreClosingCounterReconciliation, Icons.account_balance_rounded),
                const SizedBox(height: 12),
                if (!closingVm.isReconciled)
                  _buildPhysicalCountForm(isTablet, closingVm)
                else
                  _buildReconciliationResult(isTablet, closingVm),
              ],
            ),
          );
        },
      ),
      ),
      bottomNavigationBar: wrapPosShellRailBody(
        context,
        Consumer<StoreClosingViewModel>(
          builder: (context, closingVm, _) =>
              _buildBottomActions(isTablet, posVm, closingVm),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: AppColors.secondaryLight.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2124),
          ),
        ),
      ],
    );
  }

  String _formatSessionStart(DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy, hh:mm a', locale)
        .format(BusinessTimezone.toWall(dt));
  }

  String _formatSessionEnd(DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy, hh:mm a', locale)
        .format(BusinessTimezone.toWall(dt));
  }

  Widget _buildReconciliationSummary(
    bool isTablet,
    PosViewModel posVm,
    StoreClosingViewModel closingVm,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondaryLight, Color(0xFF2C3136)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.posStoreClosingSummaryTitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context)!.posStoreClosingShiftStatus,
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_toggle_off_rounded,
                    color: AppColors.primaryLight, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildSummaryItem(AppLocalizations.of(context)!.posStoreClosingCashier, posVm.cashierName, Icons.person_outline),
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildSummaryItem(
                AppLocalizations.of(context)!.posStoreClosingBranch,
                posVm.branchName.isNotEmpty ? posVm.branchName : AppLocalizations.of(context)!.posStoreClosingMainBranch,
                Icons.storefront_outlined,
              ),
            ],
          ),
          if (closingVm.sessionOpenedAt != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSessionTimeChip(
                    icon: Icons.event_outlined,
                    label: AppLocalizations.of(context)!.posStoreClosingSessionStart,
                    value: _formatSessionStart(closingVm.sessionOpenedAt!),
                  ),
                ),
                if (closingVm.sessionClosedAt != null) ...[
                  Container(
                    width: 1,
                    height: 34,
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: _buildSessionTimeChip(
                      icon: Icons.event_available_outlined,
                      label: AppLocalizations.of(context)!.posStoreClosingSessionEnd,
                      value: _formatSessionEnd(closingVm.sessionClosedAt!),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (closingVm.isReconciled &&
              (closingVm.commissionPercent > 0 ||
                  closingVm.commissionAmount > 0.001)) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: AppColors.primaryLight,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .posStoreClosingCommissionTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!
                              .posStoreClosingCommissionEarned(
                            closingVm.commissionAmount.toStringAsFixed(2),
                            closingVm.commissionPercent.toStringAsFixed(2),
                            closingVm.commissionBaseSales.toStringAsFixed(2),
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DepartmentSalesRow> _filterDepartmentRows(List<DepartmentSalesRow> rows) {
    final q = _departmentSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((row) {
      final haystack =
          '${row.departmentName} ${row.ordersCount} ${row.revenueSar.toStringAsFixed(2)}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Widget _buildDepartmentSalesSection(StoreClosingViewModel closingVm) {
    final l10n = AppLocalizations.of(context)!;
    final allRows = closingVm.departmentBreakdown;
    final filteredRows = _filterDepartmentRows(allRows);
    final isLoading = closingVm.isLoadingSummary && allRows.isEmpty;

    final hdrStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
      letterSpacing: 0.6,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade900,
    );
    final revenueStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: Color(0xFF1E2124),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.posStoreClosingDepartmentSales,
            style: AppTextStyles.h3
                .copyWith(fontSize: 14, color: const Color(0xFF1E2124)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _departmentSearchController,
            onChanged: (v) => setState(() => _departmentSearchQuery = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.posStoreClosingDepartmentSearch,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const _DepartmentSalesTableShimmer()
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(l10n.posStoreClosingDepartmentCol, style: hdrStyle),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.posStoreClosingOrdersCol,
                      textAlign: TextAlign.center,
                      style: hdrStyle,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.posStoreClosingRevenueCol,
                      textAlign: TextAlign.right,
                      style: hdrStyle,
                    ),
                  ),
                ],
              ),
            ),
            if (allRows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    l10n.posStoreClosingDepartmentEmpty,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (filteredRows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    l10n.posStoreClosingDepartmentNoMatch,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              ...filteredRows.map((row) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: LocalizedApiText(
                              row.departmentName,
                              style: cellStyle,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _storeDigits(row.ordersCount),
                              textAlign: TextAlign.center,
                              style: cellStyle,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _storeMoney(row.revenueSar),
                              textAlign: TextAlign.right,
                              style: revenueStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                  ],
                );
              }),
              if (filteredRows.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          l10n.posStoreClosingGrandTotal,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E2124),
                          ),
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox.shrink()),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _storeMoney(
                            allRows.fold<double>(
                              0,
                              (sum, r) => sum + r.revenueSar,
                            ),
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E2124),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSessionTimeChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.primaryLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LocalizedApiText(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalCountForm(bool isTablet, StoreClosingViewModel closingVm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.posStoreClosingPhysicalDrawerCount,
            style: AppTextStyles.h3.copyWith(fontSize: 14, color: const Color(0xFF1E2124)),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.posStoreClosingPhysicalDrawerHint,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey, fontSize: 11),
          ),

          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
                  label: AppLocalizations.of(context)!.posStoreClosingPhysicalCashAmount,
                  controller: closingVm.cashController,
                  icon: Icons.payments_outlined,
                  onChanged: (_) => closingVm.updatePhysicalCount(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: AppLocalizations.of(context)!.posStoreClosingBankCardSlips,
                  controller: closingVm.bankController,
                  icon: Icons.credit_card_outlined,
                  onChanged: (_) => closingVm.updatePhysicalCount(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: AppLocalizations.of(context)!.posStoreClosingCorporateInvoices,
                  controller: closingVm.corporateController,
                  icon: Icons.business_outlined,
                  onChanged: (_) => closingVm.updatePhysicalCount(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
                  label: AppLocalizations.of(context)!.posStoreClosingTamaraCredits,
                  controller: closingVm.tamaraController,
                  icon: Icons.receipt_long_outlined,
                  onChanged: (_) => closingVm.updatePhysicalCount(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: AppLocalizations.of(context)!.posStoreClosingTabbyCredits,
                  controller: closingVm.tabbyController,
                  icon: Icons.receipt_long_outlined,
                  onChanged: (_) => closingVm.updatePhysicalCount(),
                ),
              ),
              Expanded(
                child: _buildInputField(
                  label: AppLocalizations.of(context)!.posStoreClosingOthersEmployeeSales,
                  controller: closingVm.othersController,
                  icon: Icons.groups_outlined,
                  onChanged: (_) => closingVm.updatePhysicalCount(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: AppLocalizations.of(context)!.posStoreClosingNotesOptional,
            controller: closingVm.notesController,
            icon: Icons.notes_rounded,
            isNumeric: false,
            maxLines: 3,
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.posStoreClosingTotalPhysicalSum,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.secondaryLight),
                ),
                // Only this number rebuilds while user types — keeps keyboard responsive.
                ValueListenableBuilder<double>(
                  valueListenable: closingVm.physicalTotalNotifier,
                  builder: (context, total, _) => Text(
                    _storeMoney(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.secondaryLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHintRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            _storeMoney(amount),
            style: TextStyle(
              fontSize: 11,
              color: bold ? AppColors.secondaryLight : Colors.grey.shade700,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool isNumeric = true,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.multiline,
            hintLocales: appKeyboardHintLocales(context),
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.secondaryLight),
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: AppColors.secondaryLight.withOpacity(0.5), size: 18),
              hintText: hint ?? (isNumeric ? _storeDigits('0.00') : AppLocalizations.of(context)!.posStoreClosingAddNotesHint),
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primaryLight, width: 2)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReconciliationResult(bool isTablet, StoreClosingViewModel closingVm) {
    final report = closingVm.report;
    if (report == null) return const SizedBox();

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final diff = report.netDifference;
    final isShort = diff > 0.01;
    final isOver = diff < -0.01;
    final statusLabel = isShort
        ? (isAr ? 'عجز' : 'Short')
        : isOver
            ? (isAr ? 'زيادة' : 'Over')
            : (isAr ? 'متوازن' : 'Balanced');
    final statusColor = isShort
        ? Colors.red.shade800
        : isOver
            ? const Color(0xFFE65100)
            : Colors.green.shade800;
    final statusBg = isShort
        ? const Color(0xFFFFEBEE)
        : isOver
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9);
    final statusHint = isShort
        ? (isAr
            ? 'العد الفعلي أقل من النظام'
            : 'Physical count is less than the system')
        : isOver
            ? (isAr
                ? 'العد الفعلي أكثر من النظام'
                : 'Physical count is more than the system')
            : (isAr ? 'لا يوجد فرق' : 'No difference');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isShort
                      ? Icons.trending_down_rounded
                      : isOver
                          ? Icons.trending_up_rounded
                          : Icons.check_circle_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusHint,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Closing ID
          if (closingVm.closingId != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.posStoreClosingClosingId,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  Text(
                    _storeDigits(closingVm.closingId!),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          _buildResultHeader(
              showGrossNetLegend: report.salesReturnsTotal > 0.001),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _buildResultRow(AppLocalizations.of(context)!.posStoreClosingCashAccount, report.systemCashGross, report.physicalCash, report.cashDiff),
          const SizedBox(height: 10),
          _buildResultRow(AppLocalizations.of(context)!.posStoreClosingBankCards, report.systemBankGross, report.physicalBank, report.bankDiff),
          const SizedBox(height: 10),
          _buildResultRow(AppLocalizations.of(context)!.posStoreClosingCorporate, report.systemCorporateGross, report.physicalCorporate, report.corporateDiff),
          const SizedBox(height: 10),
          _buildResultRow(AppLocalizations.of(context)!.posStoreClosingTamara, report.systemTamaraGross, report.physicalTamara, report.tamaraDiff),
          const SizedBox(height: 10),
          _buildResultRow(AppLocalizations.of(context)!.posStoreClosingTabby, report.systemTabbyGross, report.physicalTabby, report.tabbyDiff),
          const SizedBox(height: 10),
          _buildResultRow(AppLocalizations.of(context)!.posStoreClosingOthers, report.systemOthersGross, report.physicalOthers, report.othersDiff),
          const Divider(height: 16),
          _buildResultTableFooter(report),
        ],
      ),
    );
  }

  Widget _buildResultHeader({bool showGrossNetLegend = false}) {
    final hdrStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade500,
      fontSize: 11,
    );
    final subStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade400,
      fontSize: 8.5,
    );
    Widget hdrCol(String top, String? bottom, double w) {
      return SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(top, textAlign: TextAlign.right, style: hdrStyle),
            if (bottom != null) Text(bottom, textAlign: TextAlign.right, style: subStyle),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.posStoreClosingCategory,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
          ),
        ),
        showGrossNetLegend
            ? hdrCol(AppLocalizations.of(context)!.posStoreClosingSystem, AppLocalizations.of(context)!.posStoreClosingGross, 64)
            : SizedBox(
                width: 64,
                child: Text(AppLocalizations.of(context)!.posStoreClosingSystem, textAlign: TextAlign.right, style: hdrStyle),
              ),
        SizedBox(
          width: 72,
          child: Text(
            AppLocalizations.of(context)!.posStoreClosingPhysical,
            textAlign: TextAlign.right,
            maxLines: 1,
            style: hdrStyle,
          ),
        ),
        showGrossNetLegend
            ? hdrCol(AppLocalizations.of(context)!.posStoreClosingDiff, AppLocalizations.of(context)!.posStoreClosingNet, 56)
            : SizedBox(
                width: 56,
                child: Text(AppLocalizations.of(context)!.posStoreClosingDiff, textAlign: TextAlign.right, style: hdrStyle),
              ),
      ],
    );
  }

  Widget _buildResultRow(
      String label, double system, double physical, double diff) {
    // diff = system - physical: positive = cashier short (red), negative = cashier excess (green)
    final diffColor =
        diff == 0 ? Colors.green : (diff > 0 ? Colors.red : Colors.green);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey.shade800),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            _storeDigits(system.toStringAsFixed(2)),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            _storeDigits(physical.toStringAsFixed(2)),
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            _storeSignedAmount(diff),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 12, color: diffColor),
          ),
        ),
      ],
    );
  }

  /// Column totals, optional sales-return deduction, then net grand total (aligned with table).
  Widget _buildResultTableFooter(StoreClosingReport report) {
    final sys = report.systemBucketsSumGross;
    final phy = report.physicalTotal;
    final dsum = report.diffBucketsSum;
    final diffColor =
        dsum == 0 ? Colors.green : (dsum > 0 ? Colors.red : Colors.green);

    Widget sumCell(String text, {Color? color, FontWeight w = FontWeight.w800}) {
      return Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          fontWeight: w,
          color: color ?? Colors.grey.shade800,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.posSalesReturnTotal,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
            SizedBox(width: 64, child: sumCell(_storeDigits(sys.toStringAsFixed(2)))),
            SizedBox(width: 72, child: sumCell(_storeDigits(phy.toStringAsFixed(2)))),
            SizedBox(
              width: 56,
              child: sumCell(
                _storeSignedAmount(dsum),
                color: diffColor,
              ),
            ),
          ],
        ),
        if (report.salesReturnsTotal > 0.001) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.posStoreClosingLessSalesReturn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ),
                Text(
                  '− ${_storeMoney(report.salesReturnsTotal)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.posStoreClosingGrandTotal,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              Text(
                _storeMoney(report.systemSales),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.secondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
      bool isTablet, PosViewModel posVm, StoreClosingViewModel closingVm) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pad = EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset);

    if (!closingVm.isReconciled) {
      return Container(
        padding: pad,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
                onPressed: (!closingVm.isReconciling)
                    ? () async {
                          final ws = posVm.workshopName.trim();
                          final workshopForClosing = (ws.isEmpty ||
                                  ws == 'Loading...' ||
                                  ws == '...')
                              ? ''
                              : ws;
                          await WidgetsBinding.instance.endOfFrame;
                          await closingVm.reconcile(
                            posVm.branchName,
                            posVm.cashierName,
                            workshopForClosing,
                            context,
                          );
                          if (!mounted) return;
                          final rpt = closingVm.report;
                          if (closingVm.isReconciled && rpt != null) {
                            // Background only — never await raster before UI updates.
                            _warmClosingPrintCache(rpt, closingVm.closingId);
                          }
                        }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  disabledBackgroundColor: AppColors.primaryLight,
                  disabledForegroundColor: AppColors.secondaryLight,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  shadowColor: AppColors.primaryLight.withOpacity(0.3),
                ),
                child: closingVm.isReconciling
                    ? AppButtonBusy.loaderOnFill(AppColors.primaryLight)
                    : Text(AppLocalizations.of(context)!.posStoreClosingCloseShift,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
        ),
      );
    }

    // No eager warmup. Printing.raster() locked the main isolate and made
    // the Logout button unresponsive immediately after reconciliation.
    // _resolveClosingEscPosBytes already calls _warmClosingPrintCache on
    // demand if no cached bytes exist when Print is tapped.
    final rpt = closingVm.report;

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
                        message: AppLocalizations.of(context)!
                            .posStoreClosingPrinterHint,
                        child: GestureDetector(
                          onLongPress: () async {
                            final ok = await showThermalPrinterWifiDialog(
                              context,
                            );
                            if (!mounted) return;
                            if (ok) {
                              ToastService.showSuccess(
                                context,
                                AppLocalizations.of(context)!
                                    .posStoreClosingSaveSuccess,
                              );
                            }
                          },
                          child: ElevatedButton(
                            onPressed: (rpt == null || _isPrintingClosing)
                                ? null
                                : () {
                                    // Fire-and-forget: do NOT await. Reconcile
                                    // screen stays interactive (user can tap
                                    // Logout); errors / success toast on root
                                    // ScaffoldMessenger. The in-button spinner
                                    // is driven by `_isPrintingClosing` inside
                                    // `_runStoreClosingPrintInBackground`.
                                    final closingId = closingVm.closingId;
                                    final l10n = AppLocalizations.of(context)!;
                                    unawaited(
                                      _runStoreClosingPrintInBackground(
                                        report: rpt,
                                        closingId: closingId,
                                        successMessage:
                                            l10n.posStoreClosingReceiptSent,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryLight,
                              foregroundColor: AppColors.onSecondaryLight,
                              disabledBackgroundColor:
                                  AppColors.secondaryLight,
                              disabledForegroundColor:
                                  AppColors.onSecondaryLight,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: _isPrintingClosing
                                ? AppButtonBusy.loaderOnFill(
                                    AppColors.secondaryLight,
                                  )
                                : Text(
                                    AppLocalizations.of(context)!
                                        .posStoreClosingPrint,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
          const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.secondaryLight,
                          disabledBackgroundColor: AppColors.primaryLight,
                          disabledForegroundColor: AppColors.secondaryLight,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.primaryLight
                              .withValues(alpha: 0.35),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .posStoreClosingFinalLogout,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.posStoreClosingLogout,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.posStoreClosingLogoutConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(AppLocalizations.of(context)!.posStoreClosingCancel,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryLight)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.read<LoginViewModel>().logout();
                        if (context.mounted) {
                          RestartWidget.restartApp(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.posStoreClosingLogout,
                          style: TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching department sales table (header + rows).
class _DepartmentSalesTableShimmer extends StatelessWidget {
  const _DepartmentSalesTableShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const PosShimmer(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PosShimmerBox(width: 72, height: 10, radius: 5),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: PosShimmerBox(width: 40, height: 10, radius: 5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PosShimmerBox(width: 56, height: 10, radius: 5),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(5, (index) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: PosShimmer(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: PosShimmerLine(
                          width: double.infinity,
                          height: 12,
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Center(
                          child: PosShimmerBox(width: 28, height: 12, radius: 6),
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: PosShimmerBox(width: 64, height: 12, radius: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index < 4) Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ],
    );
  }
}
