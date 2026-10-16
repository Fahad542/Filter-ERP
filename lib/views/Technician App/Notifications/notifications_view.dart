import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../models/technician_models.dart';
import '../widgets/tech_app_bar_actions.dart';
import '../technician_view_model.dart';

class NotificationsView extends StatelessWidget {
  final bool showDrawerIcon;
  const NotificationsView({super.key, this.showDrawerIcon = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TechAppViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            backgroundColor: AppColors.primaryLight,
            elevation: 0,
            toolbarHeight: 70,
            automaticallyImplyLeading: false,
            leadingWidth: 70,
            leading: Center(
              child: GestureDetector(
                onTap: () => showDrawerIcon
                    ? Scaffold.of(context).openDrawer()
                    : Navigator.pop(context),
                child: Container(
                  width: showDrawerIcon ? 44 : 40,
                  height: showDrawerIcon ? 44 : 40,
                  decoration: showDrawerIcon
                      ? BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryLight.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                  child: Center(
                    child: Icon(
                      showDrawerIcon
                          ? Icons.menu_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      color: showDrawerIcon
                          ? Colors.white
                          : AppColors.secondaryLight,
                      size: showDrawerIcon ? 22 : 20,
                    ),
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            title: Text(
              l10n.techNotificationsTitle,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            actions: techAppBarTrailingActions(context),
          ),
          body: vm.notifications.isEmpty
              ? _buildEmptyState(l10n)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: vm.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(
                      context,
                      l10n,
                      vm.notifications[index],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.techNotificationsEmptyTitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.techNotificationsEmptyBody,
            style: const TextStyle(color: Colors.black26, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppLocalizations l10n,
    TechNotification notification,
  ) {
    final isCommission =
        notification.type.toLowerCase() == 'commission';
    String title = notification.title;
    String message = notification.message;
    if (isCommission) {
      title = l10n.techNotifCommissionCredited;
      final parts = notification.message.split('|');
      final amount = parts.isNotEmpty ? parts[0] : '0.00';
      final orderId = parts.length > 1 ? parts[1] : '';
      message = l10n.techNotifCommissionCreditedBody(
        l10n.ownerCurrencySar,
        amount,
        orderId,
      );
    }
    final timeLabel = DateFormat(
      'HH:mm',
      Localizations.localeOf(context).toString(),
    ).format(notification.timestamp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.primaryLight,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              timeLabel,
              style: const TextStyle(
                color: Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
