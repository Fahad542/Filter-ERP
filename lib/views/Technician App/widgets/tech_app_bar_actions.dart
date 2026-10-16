import 'package:flutter/material.dart';

import '../../../widgets/app_bar_live_clock.dart';
import '../../../widgets/global_locale_toolbar_icon.dart';
import '../../../widgets/notification_toolbar_icon.dart';
import '../Notifications/notifications_view.dart';

/// Technician app bar trailing actions: global + notification (no date/time).
List<Widget> techAppBarTrailingActions(BuildContext context) {
  return filterAppBarActions(
    includeClock: false,
    belowClock: [
      const GlobalLocaleToolbarIcon(inCluster: true),
      const SizedBox(width: 6),
      NotificationToolbarIcon(
        inCluster: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const NotificationsView(),
          ),
        ),
      ),
      const SizedBox(width: 16),
    ],
  );
}
