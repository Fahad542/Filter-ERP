import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcTargetsScreen extends StatelessWidget {
  const FcTargetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Row(
          children: [
            Expanded(child: FcKpi(label: 'Company target', value: 'SAR 950,000', delta: 'August 2026')),
            SizedBox(width: 10),
            Expanded(child: FcKpi(label: 'Achieved', value: 'SAR 615,900', delta: '+6.4%')),
          ],
        ),
        const SizedBox(height: 14),
        ...MockData.branches.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(b.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700))),
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
                      color: b.pct < 60 ? AppColors.errorLight : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${b.actual} / ${b.target}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}