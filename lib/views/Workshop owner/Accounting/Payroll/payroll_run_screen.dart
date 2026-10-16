import 'package:flutter/material.dart';
import '../../widgets/owner_ui_constants.dart';
import 'package:flutter/services.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PayrollRunScreen
//
// A full payroll-run form screen that matches the HTML preview design.
// Uses existing OwnerAppBar, ReusableKpiGrid, and app theme tokens.
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const PayrollRunScreen(),
//   ));
// ─────────────────────────────────────────────────────────────────────────────

// ── Data models ──────────────────────────────────────────────────────────────

class _PayrollRow {
  String employee;
  double gross;
  double deduction;
  String payFrom;
  String notes;

  _PayrollRow({
    required this.employee,
    this.gross = 0,
    this.deduction = 0,
    required this.payFrom,
    this.notes = '',
  });

  double get net => gross - deduction;
}

class _RecentPayment {
  final String employee;
  final String period;
  final String date;
  final double gross;
  final double deduction;
  final double net;
  final String payFrom;

  const _RecentPayment({
    required this.employee,
    required this.period,
    required this.date,
    required this.gross,
    required this.deduction,
    required this.net,
    required this.payFrom,
  });
}

// ── Screen ───────────────────────────────────────────────────────────────────

class PayrollRunScreen extends StatefulWidget {
  const PayrollRunScreen({super.key});

  @override
  State<PayrollRunScreen> createState() => _PayrollRunScreenState();
}

class _PayrollRunScreenState extends State<PayrollRunScreen> {
  // Constants
  static const List<String> _employees = ['Ubaid', 'Taha', 'Sultan'];
  static const List<String> _payFromOptions = [
    'Cash On Hand',
    'Bank',
    'Petty Cash',
  ];

  static const List<_RecentPayment> _recentPayments = [
    _RecentPayment(
      employee: 'Ubaid',
      period: '2026-05',
      date: '31/05/2026',
      gross: 100.80,
      deduction: 15.00,
      net: 85.80,
      payFrom: 'Cash In Hand',
    ),
    _RecentPayment(
      employee: 'Taha',
      period: '2026-05',
      date: '31/05/2026',
      gross: 709.79,
      deduction: 100.00,
      net: 609.79,
      payFrom: 'Cash In Hand',
    ),
  ];

  // State
  final List<_PayrollRow> _rows = [];
  final List<GlobalKey<_PayrollRowCardState>> _rowKeys = [];

  String _period = 'June 2026';
  String _paymentDate = '17/06/2026';

  // Totals
  double get _totalGross =>
      _rows.fold(0, (sum, r) => sum + r.gross);
  double get _totalDeduction =>
      _rows.fold(0, (sum, r) => sum + r.deduction);
  double get _totalNet => _totalGross - _totalDeduction;

  @override
  void initState() {
    super.initState();
    // Seed two draft rows
    _addRow(employee: 'Ubaid', gross: 1500, deduction: 200, payFrom: 'Cash On Hand');
    _addRow(employee: 'Taha', gross: 1800, deduction: 150, payFrom: 'Bank');
  }

  void _addRow({
    String? employee,
    double gross = 0,
    double deduction = 0,
    String? payFrom,
  }) {
    setState(() {
      _rows.add(_PayrollRow(
        employee: employee ?? _employees.first,
        gross: gross,
        deduction: deduction,
        payFrom: payFrom ?? _payFromOptions.first,
      ));
      _rowKeys.add(GlobalKey<_PayrollRowCardState>());
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows.removeAt(index);
      _rowKeys.removeAt(index);
    });
  }

  void _onRowChanged() => setState(() {});

  void _showToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.secondaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(milliseconds: 1600),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  String _fmt(double n) => 'SAR ${n.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final kpiMetrics = [
      ReusableKpiMetric(
        title: 'Net Payroll',
        value: _fmt(_totalNet),
        icon: Icons.savings_rounded,
        subtitle: '${_rows.length} employee${_rows.length == 1 ? '' : 's'}',
      ),
      ReusableKpiMetric(
        title: 'Total Gross',
        value: _fmt(_totalGross),
        icon: Icons.trending_up_rounded,
        subtitle: 'this period',
      ),
      ReusableKpiMetric(
        title: 'Deductions',
        value: _fmt(_totalDeduction),
        icon: Icons.remove_circle_outline_rounded,
        subtitle: 'FIFO settled',
      ),
    ];

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: 'Payroll Run'),
        showDrawer: true,
        showNotification: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── KPI Grid ─────────────────────────────────────────────────────
            ReusableKpiGrid(
              metrics: kpiMetrics,
              showFeatured: true,
              crossAxisCount: 2,
              childAspectRatio: 2.05,
            ),
            const SizedBox(height: 14),

            // ── Period & Payment Date card ────────────────────────────────────
            _PeriodCard(
              period: _period,
              paymentDate: _paymentDate,
              onPeriodChanged: (v) => setState(() => _period = v),
              onPaymentDateChanged: (v) => setState(() => _paymentDate = v),
              onRefresh: () => _showToast('Lookups refreshed'),
            ),
            const SizedBox(height: 20),

            // ── Payroll Rows section header ───────────────────────────────────
            Row(
              children: [
                Text(
                  'Payroll Rows',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${_rows.length}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Payroll Row Cards ─────────────────────────────────────────────
            ...List.generate(_rows.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PayrollRowCard(
                  key: _rowKeys[i],
                  row: _rows[i],
                  employees: _employees,
                  payFromOptions: _payFromOptions,
                  canDelete: _rows.length > 1,
                  onDelete: () => _removeRow(i),
                  onChanged: _onRowChanged,
                ),
              );
            }),

            // ── Add Row button ────────────────────────────────────────────────
            _AddRowButton(onTap: () => _addRow()),
            const SizedBox(height: 4),

            // ── Summary box ───────────────────────────────────────────────────
            _SummaryBox(
              gross: _totalGross,
              deduction: _totalDeduction,
              net: _totalNet,
            ),
            const SizedBox(height: 12),

            // ── Submit button ─────────────────────────────────────────────────
            _SubmitButton(
              onTap: () => _showToast('Payroll run submitted'),
            ),
            const SizedBox(height: 10),

            // ── Recent Payments section ───────────────────────────────────────
            Text(
              'Recent Salary Payments',
              style: AppTextStyles.h3.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 10),

            ..._recentPayments.map(
                  (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecentPaymentCard(payment: p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period & Payment Date Card
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodCard extends StatelessWidget {
  final String period;
  final String paymentDate;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onPaymentDateChanged;
  final VoidCallback onRefresh;

  const _PeriodCard({
    required this.period,
    required this.paymentDate,
    required this.onPeriodChanged,
    required this.onPaymentDateChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FieldBlock(
                  label: 'Period',
                  child: _IconTextField(
                    icon: Icons.calendar_today_rounded,
                    initialValue: period,
                    onChanged: onPeriodChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldBlock(
                  label: 'Payment Date',
                  child: _IconTextField(
                    icon: Icons.calendar_today_rounded,
                    initialValue: paymentDate,
                    onChanged: onPaymentDateChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GhostButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh lookups',
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payroll Row Card
// ─────────────────────────────────────────────────────────────────────────────

class _PayrollRowCard extends StatefulWidget {
  final _PayrollRow row;
  final List<String> employees;
  final List<String> payFromOptions;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _PayrollRowCard({
    super.key,
    required this.row,
    required this.employees,
    required this.payFromOptions,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_PayrollRowCard> createState() => _PayrollRowCardState();
}

class _PayrollRowCardState extends State<_PayrollRowCard> {
  late TextEditingController _grossCtrl;
  late TextEditingController _deductCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _grossCtrl = TextEditingController(
      text: widget.row.gross == 0 ? '' : widget.row.gross.toStringAsFixed(2),
    );
    _deductCtrl = TextEditingController(
      text: widget.row.deduction == 0
          ? ''
          : widget.row.deduction.toStringAsFixed(2),
    );
    _notesCtrl = TextEditingController(text: widget.row.notes);
  }

  @override
  void dispose() {
    _grossCtrl.dispose();
    _deductCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(double n) => 'SAR ${n.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row header: avatar + employee picker + delete ─────────────────
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.secondaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),

              // Employee dropdown
              Expanded(
                child: _StyledDropdown<String>(
                  value: widget.row.employee,
                  items: widget.employees,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => widget.row.employee = v);
                      widget.onChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Delete button
              _DeleteButton(
                enabled: widget.canDelete,
                onTap: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Gross + Deduction ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _FieldBlock(
                  label: 'Gross (SAR)',
                  child: _NumericTextField(
                    controller: _grossCtrl,
                    onChanged: (v) {
                      setState(() {
                        widget.row.gross = double.tryParse(v) ?? 0;
                      });
                      widget.onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldBlock(
                  label: 'Advance Deduction',
                  child: _NumericTextField(
                    controller: _deductCtrl,
                    onChanged: (v) {
                      setState(() {
                        widget.row.deduction = double.tryParse(v) ?? 0;
                      });
                      widget.onChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Net (auto) box ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET (AUTO)',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.secondaryLight.withOpacity(0.46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(widget.row.net),
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Pay From ─────────────────────────────────────────────────────
          _FieldBlock(
            label: 'Pay From',
            child: _StyledDropdown<String>(
              value: widget.row.payFrom,
              items: widget.payFromOptions,
              onChanged: (v) {
                if (v != null) {
                  setState(() => widget.row.payFrom = v);
                  widget.onChanged();
                }
              },
            ),
          ),
          const SizedBox(height: 10),

          // ── Notes ─────────────────────────────────────────────────────────
          _FieldBlock(
            label: 'Notes',
            child: _StyledTextField(
              controller: _notesCtrl,
              hintText: 'Optional note',
              onChanged: (v) => widget.row.notes = v,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Box
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  final double gross;
  final double deduction;
  final double net;

  const _SummaryBox({
    required this.gross,
    required this.deduction,
    required this.net,
  });

  String _fmt(double n) => 'SAR ${n.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _SummaryItem(label: 'GROSS', value: _fmt(gross))),
            VerticalDivider(
              color: AppColors.secondaryLight.withOpacity(0.10),
              width: 1,
            ),
            Expanded(
                child: _SummaryItem(label: 'DEDUCTIONS', value: _fmt(deduction))),
            VerticalDivider(
              color: AppColors.secondaryLight.withOpacity(0.10),
              width: 1,
            ),
            Expanded(child: _SummaryItem(label: 'NET', value: _fmt(net))),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.secondaryLight.withOpacity(0.46),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit Button
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SubmitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_rounded,
              color: AppColors.primaryLight,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Submit Payroll Run',
              style: AppTextStyles.button.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Payment Card
// ─────────────────────────────────────────────────────────────────────────────

class _RecentPaymentCard extends StatelessWidget {
  final _RecentPayment payment;

  const _RecentPaymentCard({required this.payment});

  String _fmt(double n) => 'SAR ${n.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: icon + employee name + period + date ──────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.secondaryLight,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.employee,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            payment.period,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3B5BDB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          payment.date,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLight.withOpacity(0.46),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.secondaryLight.withOpacity(0.07)),
          const SizedBox(height: 12),

          // ── Gross · Deduction · Net ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniBox(label: 'Gross', value: _fmt(payment.gross)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniBox(
                  label: 'Deduction',
                  value: _fmt(payment.deduction),
                  valueColor: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniBox(
                  label: 'Net',
                  value: _fmt(payment.net),
                  highlight: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Pay From full width ───────────────────────────────────────────
          _MiniBox(
            label: 'Pay From',
            value: payment.payFrom,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }
}

class _MiniBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlight;
  final IconData? icon;

  const _MiniBox({
    required this.label,
    required this.value,
    this.valueColor,
    this.highlight = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = highlight
        ? AppColors.primaryLight
        : (valueColor ?? AppColors.secondaryLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryLight.withOpacity(0.08)
            : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: AppColors.primaryLight.withOpacity(0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: effectiveColor.withOpacity(0.55)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.secondaryLight.withOpacity(0.46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: effectiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Row Button
// ─────────────────────────────────────────────────────────────────────────────

class _AddRowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddRowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.secondaryLight.withOpacity(0.25),
            width: 1.5,
            // strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.secondaryLight, size: 15),
            const SizedBox(width: 8),
            Text(
              'Add Row',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

/// White card with border, shadow, rounded corners
class _AppCard extends StatelessWidget {
  final Widget child;

  const _AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Label + child field
class _FieldBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.secondaryLight.withOpacity(0.46),
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

InputDecoration _inputDecoration({String? hint, Widget? prefix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodySmall.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.secondaryLight.withOpacity(0.35),
    ),
    prefixIcon: prefix,
    filled: true,
    fillColor: const Color(0xFFFAFAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: AppColors.secondaryLight.withOpacity(0.10)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: AppColors.secondaryLight.withOpacity(0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
    isDense: true,
  );
}

/// Text field with a leading icon
class _IconTextField extends StatelessWidget {
  final IconData icon;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _IconTextField({
    required this.icon,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
      decoration: _inputDecoration(
        prefix: Icon(icon, size: 13, color: AppColors.secondaryLight.withOpacity(0.46)),
      ),
    );
  }
}

/// Plain styled text field
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
      decoration: _inputDecoration(hint: hintText),
    );
  }
}

/// Numeric-only text field
class _NumericTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NumericTextField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
      decoration: _inputDecoration(hint: '0.00'),
    );
  }
}

/// Styled dropdown
class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppColors.secondaryLight.withOpacity(0.45),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
      dropdownColor: Colors.white,
      decoration: _inputDecoration(),
      items: items
          .map((e) => DropdownMenuItem<T>(
        value: e,
        child: Text(e.toString()),
      ))
          .toList(),
    );
  }
}

/// Ghost (outline) button
class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: AppColors.secondaryLight.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.secondaryLight),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red delete button
class _DeleteButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _DeleteButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFBE7E7),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFD6433D),
            size: 16,
          ),
        ),
      ),
    );
  }
}