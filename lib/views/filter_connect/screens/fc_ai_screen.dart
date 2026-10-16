import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcAiScreen extends StatelessWidget {
  const FcAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Row(
          children: [
            Expanded(child: FcKpi(label: 'Insights', value: '126', delta: 'Last 30 days')),
            SizedBox(width: 10),
            Expanded(child: FcKpi(label: 'Forecast accuracy', value: '93.6%', delta: '7-day model')),
          ],
        ),
        const SizedBox(height: 14),
        FcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI chat', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Why is Malaz behind target and what should I do this week?',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Malaz is at 52%. Ticket size fell 18%, 9 bookings cancelled, bay 3 was down 4 days.\n\n'
                  '• Push brake + filter combo\n'
                  '• Move Khalid to bay 1 mornings\n'
                  '• Call 23 churn-risk customers\n\n'
                  'Projected impact: +SAR 46,000',
                  style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...MockData.insights.take(2).map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FcPill(label: i.tag, info: true),
                  const SizedBox(height: 8),
                  Text(i.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(i.body, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}