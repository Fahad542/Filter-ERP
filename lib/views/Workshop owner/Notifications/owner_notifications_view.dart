import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../models/workshop_owner_models.dart';
import '../widgets/owner_app_bar.dart';

class OwnerNotificationsView extends StatefulWidget {
  final bool showBackButton;
  const OwnerNotificationsView({super.key, this.showBackButton = false});

  @override
  State<OwnerNotificationsView> createState() => _OwnerNotificationsViewState();
}

class _OwnerNotificationsViewState extends State<OwnerNotificationsView> {
  final List<OwnerNotification> _notifications = [
    OwnerNotification(id: '1', title: 'Expense Submitted', message: 'Ali Hassan submitted an expense of SAR 450 for approval.', type: 'expense', timestamp: DateTime.now().subtract(const Duration(minutes: 15))),
    OwnerNotification(id: '2', title: 'Low Stock Alert', message: 'Engine Oil 5W-30 is critically low at Riyadh Main (3 units left).', type: 'stock', timestamp: DateTime.now().subtract(const Duration(hours: 1)), isRead: true),
    OwnerNotification(id: '3', title: 'Corporate Payment Received', message: 'Gulf Corp. LLC paid SAR 15,000 for January bill.', type: 'payment', timestamp: DateTime.now().subtract(const Duration(hours: 3))),
    OwnerNotification(id: '4', title: 'Locker Difference', message: 'Jeddah Center – SAR 50 difference detected at EOD closing.', type: 'locker', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    OwnerNotification(id: '5', title: 'Invoice Approved', message: 'Purchase order PO-002 has been approved and stock updated.', type: 'invoice', timestamp: DateTime.now().subtract(const Duration(hours: 8)), isRead: true),
    OwnerNotification(id: '6', title: 'Overdue Bill Alert', message: 'Saudi Aramco Corp. bill of SAR 38,000 is now overdue.', type: 'payment', timestamp: DateTime.now().subtract(const Duration(days: 1))),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: 'Notifications',
        showBackButton: widget.showBackButton,
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return _buildNotifCard(n);
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNotifCard(OwnerNotification n) {
    final data = _getTypeData(n.type);
    final timeAgo = _timeAgo(n.timestamp);

    return GestureDetector(
      onTap: () => setState(() => n.isRead = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: n.isRead 
              ? null 
              : Border.all(color: AppColors.primaryLight.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with Secondary Background and Primary Color (like POS App)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.secondaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                data['icon'], 
                color: AppColors.primaryLight, 
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!n.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeData(String type) {
    switch (type) {
      case 'expense': return {'color': Colors.orange, 'icon': Icons.receipt_rounded};
      case 'stock': return {'color': Colors.red, 'icon': Icons.inventory_2_rounded};
      case 'payment': return {'color': Colors.green, 'icon': Icons.payments_rounded};
      case 'locker': return {'color': Colors.purple, 'icon': Icons.lock_rounded};
      case 'invoice': return {'color': const Color(0xFF2D9CDB), 'icon': Icons.description_rounded};
      default: return {'color': Colors.grey, 'icon': Icons.notifications_rounded};
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
