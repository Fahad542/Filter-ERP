import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcCommandCenterScreen extends StatefulWidget {
  const FcCommandCenterScreen({super.key});

  @override
  State<FcCommandCenterScreen> createState() => _FcCommandCenterScreenState();
}

class _FcCommandCenterScreenState extends State<FcCommandCenterScreen> {
  String _sectionTab = 'insights';

  static const _teal = Color(0xFF14B8A6);
  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: MockData.kpis.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.48,
          ),
          itemBuilder: (_, i) {
            final k = MockData.kpis[i];
            return FcKpi(
              label: k.label,
              value: k.value,
              delta: k.delta,
              hint: k.hint,
            );
          },
        ),
        const SizedBox(height: 12),
        PosSegmentedListTabs(
          tabs: const [
            PosSegmentedTab(id: 'insights', label: 'AI insights'),
            PosSegmentedTab(id: 'targets', label: 'Branch targets'),
            PosSegmentedTab(id: 'sales', label: 'Sales forecast'),
            PosSegmentedTab(id: 'budget', label: 'Budget'),
            PosSegmentedTab(id: 'tasks', label: 'Tasks'),
          ],
          selectedId: _sectionTab,
          onSelected: (id) => setState(() => _sectionTab = id),
          layout: PosSegmentedTabLayout.scrollable,
          padding: EdgeInsets.zero,
          tabVerticalPadding: 10,
          fontSize: 11.5,
        ),
        const SizedBox(height: 12),
        ..._tabBody(),
      ],
    );
  }

  List<Widget> _tabBody() {
    switch (_sectionTab) {
      case 'targets':
        return _branchesList();
      case 'sales':
        return [_salesForecastCard()];
      case 'budget':
        return [_budgetCategoryCard()];
      case 'tasks':
        return [_tasksAttentionCard()];
      case 'insights':
      default:
        return _insightsList();
    }
  }

  List<Widget> _insightsList() {
    return MockData.insights
        .map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FcPill(label: i.tag, info: true),
                  const SizedBox(height: 8),
                  Text(
                    i.title,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i.body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _branchesList() {
    return MockData.branches
        .map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.name,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${b.pct}%', style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: b.pct / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: b.pct < 60
                          ? AppColors.errorLight
                          : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${b.actual} of ${b.target} · ${b.staff} staff',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _salesForecastCard() {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales vs AI forecast',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last 7 days · all branches',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _teal.withOpacity(0.5)),
                ),
                child: const Text(
                  'AI forecasting',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 15,
                      reservedSize: 34,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}k',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= MockData.salesDays.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            MockData.salesDays[i],
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 60,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < MockData.salesActual.length; i++)
                        FlSpot(i.toDouble(), MockData.salesActual[i]),
                    ],
                    isCurved: true,
                    color: _orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _orange.withOpacity(0.28),
                          _orange.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < MockData.salesForecast.length; i++)
                        FlSpot(i.toDouble(), MockData.salesForecast[i]),
                    ],
                    isCurved: true,
                    color: _teal,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dashArray: const [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendLine(color: _orange, label: 'Actual', dashed: false),
              const SizedBox(width: 18),
              _legendLine(color: _teal, label: 'AI forecast', dashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetCategoryCard() {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget vs actual by category',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Current month',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 15,
                      reservedSize: 34,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}k',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= MockData.budgetCategories.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            MockData.budgetCategories[i],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < MockData.budgetCategories.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: MockData.budgetValues[i],
                          color: Colors.grey.shade400,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: MockData.budgetActual[i],
                          color: _orange,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendSwatch(color: Colors.grey.shade400, label: 'Budget'),
              const SizedBox(width: 18),
              _legendSwatch(color: _orange, label: 'Actual'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tasksAttentionCard() {
    return FcCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks needing attention',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Budget vs actual updates only after an expense is approved',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryLight,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('All tasks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final t in MockData.tasks) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t.id,
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 8),
                      FcPill(
                        label: t.priority,
                        danger: t.priority == 'High',
                        info: t.priority == 'Medium',
                      ),
                      if (t.overBudget) ...[
                        const SizedBox(width: 6),
                        const FcPill(label: 'Over budget', danger: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.assignee} · ${t.branch} · due ${t.due}',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (t.noBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'No budget set',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Text(
                          t.spent,
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '  /  ${t.budget}',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _taskProgress(t),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: t.overBudget ? const Color(0xFF16A34A) : _orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _taskProgress(TaskItem t) {
    final spent = _parseSar(t.spent);
    final budget = _parseSar(t.budget);
    if (budget <= 0) return 0;
    return (spent / budget).clamp(0.0, 1.0);
  }

  double _parseSar(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  Widget _legendLine({
    required Color color,
    required String label,
    required bool dashed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 3),
          painter: _LegendLinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _legendSwatch({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  _LegendLinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }
    const dash = 3.0;
    const gap = 2.5;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}
