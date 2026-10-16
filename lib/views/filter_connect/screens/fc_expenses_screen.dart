import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcExpensesScreen extends StatelessWidget {
  const FcExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Row(
          children: [
            Expanded(child: FcKpi(label: 'Submitted today', value: '9', delta: 'SAR 13,480')),
            SizedBox(width: 10),
            Expanded(child: FcKpi(label: 'Approved by AI', value: '5', delta: 'Avg 42s')),
          ],
        ),
        const SizedBox(height: 14),
        ...MockData.expenses.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(e.id, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                      const SizedBox(width: 8),
                      FcPill(label: e.category),
                      const Spacer(),
                      FcPill(
                        label: e.status,
                        info: !e.aboveLimit,
                        danger: e.aboveLimit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(e.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${e.person} · ${e.when}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Linked task ${e.taskId} — ${e.taskTitle}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.amount,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 18,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}