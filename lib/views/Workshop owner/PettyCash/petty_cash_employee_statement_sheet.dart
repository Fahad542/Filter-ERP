import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/reusable_kpi_grid.dart';
import 'petty_cash_view_model.dart';

/// Opens full-screen employee Fund [1280] statement with date filters.
Future<void> showPettyCashEmployeeStatementSheet(
  BuildContext context, {
  required StaffRequest request,
}) {
  final vm = context.read<PettyCashViewModel>();
  final userId = vm.resolveRequestWalletUserId(request);
  if (userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not resolve this employee for the statement.'),
      ),
    );
    return Future.value();
  }

  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: PettyCashEmployeeStatementScreen(
          walletUserId: userId,
          employeeName: request.displayStaffName,
        ),
      ),
    ),
  );
}

class PettyCashEmployeeStatementScreen extends StatefulWidget {
  final String walletUserId;
  final String employeeName;

  const PettyCashEmployeeStatementScreen({
    super.key,
    required this.walletUserId,
    required this.employeeName,
  });

  @override
  State<PettyCashEmployeeStatementScreen> createState() =>
      _PettyCashEmployeeStatementScreenState();
}

class _PettyCashEmployeeStatementScreenState
    extends State<PettyCashEmployeeStatementScreen> {
  bool _loading = true;
  String? _error;
  PettyCashEmployeeStatement? _statement;
  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<PettyCashViewModel>();
      setState(() {
        _dateFrom = vm.reportDateFrom;
        _dateTo = vm.reportDateTo;
      });
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vm = context.read<PettyCashViewModel>();
      final data = await vm.fetchStatementForEmployee(
        widget.walletUserId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      if (!mounted) return;
      setState(() {
        _statement = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtSar(double v) {
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final whole = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final fromEnd = whole.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    final sign = v < 0 ? '-' : '';
    return 'SAR $sign${buf.toString()}.${parts[1]}';
  }

  String _fmtBal(double v) {
    if (v.abs() < 0.005) return 'SAR 0.00';
    final side = v >= 0 ? 'Dr' : 'Cr';
    return '${_fmtSar(v.abs())} $side';
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : OwnerUi.scaffoldBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: OwnerAppBar(
        title: widget.employeeName,
        showDrawer: false,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        bottomOverlap: TechDashboardOverlapFilters(
          startDate: _dateFrom,
          endDate: _dateTo,
          dateOnly: true,
          onStartDateChanged: (date) async {
            setState(() => _dateFrom = date);
            await _load();
          },
          onEndDateChanged: (date) async {
            setState(() => _dateTo = date);
            await _load();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_loading && _statement != null)
            ReusableKpiGrid(
              metrics: [
                ReusableKpiMetric(
                  title: 'Total Debit',
                  value: _fmtSar(_statement!.totalDebit),
                  icon: Icons.arrow_downward_rounded,
                  accentColor: AppColors.primaryLight,
                ),
                ReusableKpiMetric(
                  title: 'Total Credit',
                  value: _fmtSar(_statement!.totalCredit),
                  icon: Icons.arrow_upward_rounded,
                  accentColor: AppColors.primaryLight,
                ),
                ReusableKpiMetric(
                  title: 'Closing Balance',
                  value: _fmtBal(_statement!.closingBalance),
                  icon: Icons.account_balance_rounded,
                  accentColor: AppColors.primaryLight,
                ),
              ],
              showFeatured: false,
              crossAxisCount: 3,
              dense: true,
              iconOnTop: true,
              mainAxisExtent: 112,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            )
          else if (_loading)
            PosShimmer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 5,
                          right: i == 2 ? 0 : 5,
                        ),
                        child: const PosShimmerBox(
                          width: double.infinity,
                          height: 112,
                          radius: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const _ScreenBodyShimmer()
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final s = _statement!;
    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          DecoratedBox(
            decoration: OwnerListStyle.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OwnerListIconBox(icon: Icons.receipt_long_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statement',
                          style:
                              OwnerListStyle.titleStyle.copyWith(fontSize: 15.5),
                        ),
                        if (s.companyName.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.companyName,
                            style: OwnerListStyle.subtitleStyle.copyWith(
                              fontSize: 13,
                              color: AppColors.secondaryLight
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '[${s.accountCode}] ${s.accountName}',
                          style: OwnerListStyle.metaStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLight
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Employee · ${widget.employeeName}',
                          style: OwnerListStyle.metaStyle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'From ${_iso(_dateFrom)}  ·  To ${_iso(_dateTo)}',
                          style: OwnerListStyle.metaStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: OwnerListStyle.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  const OwnerListIconBox(icon: Icons.play_arrow_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opening balance',
                      style: OwnerListStyle.titleStyle.copyWith(fontSize: 14),
                    ),
                  ),
                  Text(
                    _fmtBal(s.openingBalance),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (s.rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 42, color: Color(0xFFD0D0D0)),
                  SizedBox(height: 10),
                  Text(
                    'No transactions in this period',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final r in s.rows) ...[
              _ScreenLineCard(row: r, fmtSar: _fmtSar, fmtBal: _fmtBal),
            ],
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.08),
              borderRadius: OwnerListStyle.cardRadius,
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  _sumLine('Opening balance', _fmtBal(s.openingBalance)),
                  _sumLine('Total debits', '${_fmtSar(s.totalDebit)} Dr'),
                  _sumLine('Total credits', _fmtSar(s.totalCredit)),
                  const Divider(height: 16),
                  _sumLine(
                    'Closing balance',
                    _fmtBal(s.closingBalance),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.secondaryLight.withValues(alpha: 0.75),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: AppColors.secondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenBodyShimmer extends StatelessWidget {
  const _ScreenBodyShimmer();

  @override
  Widget build(BuildContext context) {
    return PosShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const OwnerCardRowShimmer(),
          const SizedBox(height: 10),
          const OwnerCardRowShimmer(),
          const SizedBox(height: 8),
          for (var i = 0; i < 3; i++) ...[
            const OwnerCardRowShimmer(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ScreenLineCard extends StatelessWidget {
  final PettyCashReportRow row;
  final String Function(double) fmtSar;
  final String Function(double) fmtBal;

  const _ScreenLineCard({
    required this.row,
    required this.fmtSar,
    required this.fmtBal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwnerListIconBox(icon: Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayDescription.trim().isNotEmpty
                          ? row.displayDescription
                          : row.displayWalletUserLabel,
                      style: OwnerListStyle.titleStyle.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.debit > 0.005
                          ? fmtSar(row.debit)
                          : (row.credit > 0.005 ? fmtSar(row.credit) : '—'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: row.debit > 0.005
                            ? AppColors.secondaryLight
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(row.date, style: OwnerListStyle.metaStyle),
                    Text(
                      'Bal ${fmtBal(row.runningBalance)}',
                      style: OwnerListStyle.metaStyle,
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
