import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcTasksScreen extends StatelessWidget {
  const FcTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Row(
          children: [
            Expanded(child: FcKpi(label: 'Active tasks', value: '24', delta: '8 due this week')),
            SizedBox(width: 10),
            Expanded(child: FcKpi(label: 'Allocated', value: 'SAR 25,100', delta: '65% spent')),
          ],
        ),
        const SizedBox(height: 14),
        ...MockData.tasks.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.id, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      FcPill(label: t.priority, danger: t.priority == 'High'),
                      if (t.overBudget) ...[
                        const SizedBox(width: 6),
                        const FcPill(label: 'Over budget', danger: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(t.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${t.assignee} · ${t.branch} · due ${t.due}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                  if (!t.noBudget) ...[
                    const SizedBox(height: 10),
                    Text('${t.spent} / ${t.budget}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.overBudget ? AppColors.errorLight : AppColors.secondaryLight,
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}