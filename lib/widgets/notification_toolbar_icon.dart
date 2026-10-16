import 'package:flutter/material.dart';

import '../utils/pos_tablet_layout.dart';

/// Same bell asset + red badge as [PosScreenAppBar] / main POS shell (not Material outline bell).
class NotificationToolbarIcon extends StatelessWidget {
  const NotificationToolbarIcon({
    super.key,
    required this.onTap,
    this.margin = const EdgeInsets.only(right: 16),
    this.inCluster = false,
  });

  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;
  final bool inCluster;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final box = isTablet ? PosTabletLayout.appBarIconBox : 40.0;
    final img = isTablet ? 26.0 : 22.0;
    final badgeTop = isTablet ? 9.0 : 8.0;
    final badgeRight = isTablet ? 9.0 : 8.0;
    final badgeSize = isTablet ? 10.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: box,
        height: box,
        margin: inCluster ? EdgeInsets.zero : margin,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/notifications.png',
              width: img,
              height: img,
              color: Colors.black,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.notifications_rounded,
                size: img,
                color: Colors.black,
              ),
            ),
            Positioned(
              top: badgeTop,
              right: badgeRight,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
