import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/LocalizedApiText.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import '../../../../widgets/pos_shimmer.dart';
import 'profit_loss_view_model.dart';

/// P&L report — layout & data match web Chart of Accounts → P&L
/// (`GET /accounts/reports/pl`).
class ProfitAndLossTab extends StatefulWidget {
  const ProfitAndLossTab({super.key});

  @override
  State<ProfitAndLossTab> createState() => _ProfitAndLossTabState();
}

class _ProfitAndLossTabState extends State<ProfitAndLossTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfitLossViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitLossViewModel>(
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context)!;
        String money(double v) => ownerFormatMoney(context, v);
        if (vm.isLoading) {
          return const _PnLShimmer();
        }

        final d = vm.report;
        return RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: vm.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              if (vm.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(l10n.ownerPnLRevenue),
                          if (d.revenue.isEmpty)
                            const _EmptyHint('No revenue accounts')
                          else
                            ...d.revenue.map(
                              (r) => _PlRow(
                                label: r.name,
                                amount: money(r.amount),
                                localizeLabel: true,
                              ),
                            ),
                          _PlRow(
                            label: l10n.ownerPnLTotalRevenue,
                            amount: money(d.totalRevenue),
                            emphasis: _PlEmphasis.totalGreen,
                          ),
                          _SectionHeader(l10n.ownerPnLCogs),
                          if (d.costOfGoodsSold.isEmpty)
                            const _EmptyHint('No COGS accounts')
                          else
                            ...d.costOfGoodsSold.map(
                              (r) => _PlRow(
                                label: r.name,
                                amount: money(r.amount),
                                localizeLabel: true,
                              ),
                            ),
                          _PlRow(
                            label: l10n.ownerPnLTotalCogs,
                            amount: money(d.totalCOGS),
                            emphasis: _PlEmphasis.totalRed,
                          ),
                          _PlRow(
                            label: l10n.ownerPnLGrossProfit,
                            amount: money(d.grossProfit),
                            emphasis: _PlEmphasis.gross,
                          ),
                          _SectionHeader(l10n.ownerPnLOperatingExpenses),
                          if (d.operatingExpenses.isEmpty)
                            const _EmptyHint('No operating expenses')
                          else
                            ...d.operatingExpenses.map(
                              (r) => _PlRow(
                                label: r.name,
                                amount: money(r.amount),
                                localizeLabel: true,
                              ),
                            ),
                          _PlRow(
                            label: 'Total Operating Expenses',
                            amount: money(d.totalOperatingExpenses),
                            emphasis: _PlEmphasis.totalRed,
                          ),
                          const _SectionHeader('OTHER INCOME'),
                          if (d.otherIncome.isEmpty)
                            const _EmptyHint('No other income')
                          else
                            ...d.otherIncome.map(
                              (r) => _PlRow(
                                label: r.name,
                                amount: money(r.amount),
                                localizeLabel: true,
                              ),
                            ),
                          _PlRow(
                            label: 'Total Other Income',
                            amount: money(d.totalOtherIncome),
                            emphasis: _PlEmphasis.totalGreen,
                          ),
                          const _SectionHeader('OTHER EXPENSES'),
                          if (d.otherExpenses.isEmpty)
                            const _EmptyHint('No other expenses')
                          else
                            ...d.otherExpenses.map(
                              (r) => _PlRow(
                                label: r.name,
                                amount: money(r.amount),
                                localizeLabel: true,
                              ),
                            ),
                          _PlRow(
                            label: 'Total Other Expenses',
                            amount: money(d.totalOtherExpenses),
                            emphasis: _PlEmphasis.totalRed,
                          ),
                          const SizedBox(height: 12),
                          _NetIncomeBar(
                            amount: money(d.netIncome),
                            isProfit: d.netIncome >= 0,
                          ),
                        ],
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

// ── Initial load shimmer ──────────────────────────────────────────────────────

class _PnLShimmer extends StatelessWidget {
  const _PnLShimmer();

  @override
  Widget build(BuildContext context) {
    return PosShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PosShimmerBox(width: 80, height: 12, radius: 4),
                  const SizedBox(height: 14),
                  ...List.generate(
                    10,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: PosShimmerBox(
                              width: double.infinity,
                              height: 14,
                              radius: 6,
                            ),
                          ),
                          SizedBox(width: 24),
                          PosShimmerBox(width: 90, height: 14, radius: 6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const PosShimmerBox(
                    width: double.infinity,
                    height: 48,
                    radius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report rows ───────────────────────────────────────────────────────────────

enum _PlEmphasis { none, totalGreen, totalRed, gross }

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }
}

class _PlRow extends StatelessWidget {
  final String label;
  final String amount;
  final _PlEmphasis emphasis;
  final bool localizeLabel;

  const _PlRow({
    required this.label,
    required this.amount,
    this.emphasis = _PlEmphasis.none,
    this.localizeLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    FontWeight weight;
    switch (emphasis) {
      case _PlEmphasis.totalGreen:
      case _PlEmphasis.gross:
        color = const Color(0xFF16A34A);
        weight = emphasis == _PlEmphasis.gross
            ? FontWeight.w800
            : FontWeight.w700;
        break;
      case _PlEmphasis.totalRed:
        color = const Color(0xFFDC2626);
        weight = FontWeight.w700;
        break;
      case _PlEmphasis.none:
        color = AppColors.secondaryLight;
        weight = FontWeight.w500;
        break;
    }

    final labelStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: weight,
      color: color,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: localizeLabel
                ? LocalizedApiText(label, style: labelStyle)
                : Text(label, style: labelStyle),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: weight,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetIncomeBar extends StatelessWidget {
  final String amount;
  final bool isProfit;

  const _NetIncomeBar({required this.amount, required this.isProfit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Net Income / (Loss)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
