import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

class SuperAdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SuperAdminBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Dashboard', 0),
              _buildNavItem(context, 1, Icons.bar_chart_rounded, 'Reports', 9),
              _buildNavItem(context, 2, Icons.receipt_long_rounded, 'Orders', 6),
              _buildNavItem(context, 3, Icons.person_rounded, 'Profile', 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int navIndex, IconData icon, String label, int targetIndex) {
    final isSelected = currentIndex == targetIndex;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: () => onTap(targetIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? 28 : 22,
              color: isSelected ? AppColors.primaryLight : Colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isTablet ? 12 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.secondaryLight : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
