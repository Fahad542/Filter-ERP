import 'package:flutter/material.dart';

import '../../../utils/app_text_styles.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcCrmScreen extends StatelessWidget {
  const FcCrmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Row(
          children: [
            Expanded(child: FcKpi(label: 'Active customers', value: '3,482', delta: '+3.2%')),
            SizedBox(width: 10),
            Expanded(child: FcKpi(label: 'Churn risk', value: '23', delta: 'AI win-back drafted')),
          ],
        ),
        const SizedBox(height: 14),
        ...MockData.customers.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.name,
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      FcPill(
                        label: c.segment,
                        danger: c.segment == 'Lost' || c.segment == 'Churn Risk',
                        success: c.segment == 'Loyal',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${c.type} · ${c.vehicles} vehicles · ${c.ltv}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                  Text('Churn ${c.churn}% · Last visit ${c.lastVisit}',
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