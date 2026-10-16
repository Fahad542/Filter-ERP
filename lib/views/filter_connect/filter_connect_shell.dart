import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../Workshop pos app/More Tab/settings_view_model.dart';
import 'screens/fc_ai_screen.dart';
import 'screens/fc_chat_screen.dart';
import 'screens/fc_command_center_screen.dart';
import 'screens/fc_crm_screen.dart';
import 'screens/fc_expenses_screen.dart';
import 'screens/fc_targets_screen.dart';
import 'screens/fc_tasks_screen.dart';

/// Filter Connect hub — drawer / navbar match Workshop Owner & other portals.
class FilterConnectShell extends StatefulWidget {
  const FilterConnectShell({super.key});

  @override
  State<FilterConnectShell> createState() => _FilterConnectShellState();
}

class _FilterConnectShellState extends State<FilterConnectShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Drawer entries (index → label / icon). Bottom bar uses 0–3 only.
  static const _items = <(int, IconData, String)>[
    (0, Icons.dashboard_rounded, 'Command Center'),
    (1, Icons.chat_bubble_rounded, 'Internal Chat'),
    (2, Icons.task_alt_rounded, 'Tasks & Budget'),
    (3, Icons.receipt_long_rounded, 'Expenses'),
    (4, Icons.flag_rounded, 'Targets'),
    (5, Icons.people_alt_rounded, 'CRM 360°'),
    (6, Icons.auto_awesome_rounded, 'AI Co-Pilot'),
    (7, Icons.emoji_events_rounded, 'Leaderboard'),
    (8, Icons.storefront_rounded, 'Franchise IQ'),
  ];

  static const _badges = <int, int>{1: 4, 3: 2};

  Widget get _body {
    switch (_index) {
      case 0:
        return const FcCommandCenterScreen();
      case 1:
        return const FcChatScreen();
      case 2:
        return const FcTasksScreen();
      case 3:
        return const FcExpensesScreen();
      case 4:
        return const FcTargetsScreen();
      case 5:
        return const FcCrmScreen();
      case 6:
        return const FcAiScreen();
      default:
        return Center(
          child: Text(
            'Coming soon',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
        );
    }
  }

  bool get _showBottomBar => _index <= 3;

  bool get _isHome => _index == 0;

  /// Bottom-nav tabs other than Home: no hamburger, global on the left.
  bool get _isSecondaryTab => _index >= 1 && _index <= 3;

  String get _title {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final raw =
        _items.firstWhere((e) => e.$1 == _index, orElse: () => _items.first).$3;
    return isArabic ? raw : raw.toUpperCase();
  }

  static const _homeGreeting = 'Good evening, Asif';
  static const _homeSubtitle =
      'Every expense is task-linked · AI watches targets across 4 branches.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FD),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: _isHome
                ? Transform.translate(
                    offset: const Offset(0, -26),
                    child: _body,
                  )
                : _body,
          ),
        ],
      ),
      bottomNavigationBar: _showBottomBar ? _buildBottomBar(context) : null,
    );
  }

  // ── App bar (Owner / Super Admin pattern) ──────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    const actionSize = 34.0;
    final isHome = _isHome;
    final isSecondary = _isSecondaryTab;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: ColoredBox(
        color: AppColors.primaryLight,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, isHome ? 8 : 0, 10, isHome ? 4 : 0),
            child: isHome
                ? _homeAppBarRow(context, actionSize)
                : SizedBox(
                    height: 56,
                    child: isSecondary
                        ? _secondaryTabAppBarRow(context, actionSize)
                        : _drawerScreenAppBarRow(context, actionSize),
                  ),
          ),
        ),
      ),
    );
  }

  /// Home: greeting on same row as hamburger; subtitle under greeting with gap.
  Widget _homeAppBarRow(BuildContext context, double actionSize) {
    const hamburgerSize = 32.0;
    const gapAfterHamburger = 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _hamburgerButton(),
            const SizedBox(width: gapAfterHamburger),
            const Expanded(
              child: Text(
                _homeGreeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _localeButton(context, actionSize),
            const SizedBox(width: 6),
            _notificationButton(actionSize),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: hamburgerSize + gapAfterHamburger),
          child: const Text(
            _homeSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xB31F2937),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  /// Chat / Tasks / Expenses: global left, title center, notification right.
  Widget _secondaryTabAppBarRow(BuildContext context, double actionSize) {
    const sideSlotWidth = 48.0;
    return Row(
      children: [
        SizedBox(
          width: sideSlotWidth,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _localeButton(context, actionSize),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
        ),
        SizedBox(
          width: sideSlotWidth,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _notificationButton(actionSize),
          ),
        ),
      ],
    );
  }

  /// Drawer-only screens: back to Home (no hamburger).
  Widget _drawerScreenAppBarRow(BuildContext context, double actionSize) {
    const sideSlotWidth = 78.0;
    return Row(
      children: [
        SizedBox(
          width: sideSlotWidth,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _backButton(),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
        ),
        SizedBox(
          width: sideSlotWidth,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _localeButton(context, actionSize),
                const SizedBox(width: 6),
                _notificationButton(actionSize),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _index = 0),
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _hamburgerButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _scaffoldKey.currentState?.openDrawer(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 17),
      ),
    );
  }

  Widget _localeButton(BuildContext context, double size) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        return InkWell(
          onTap: () {
            final newLocale = settings.locale.languageCode == 'en'
                ? const Locale('ar')
                : const Locale('en');
            settings.updateLocale(newLocale);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/global.png',
                width: 20,
                color: Colors.black,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _notificationButton(double size) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/notifications.png',
              width: 20,
              color: Colors.black,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.notifications_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 7,
                height: 7,
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

  // ── Drawer (dark charcoal — same as OwnerShell) ────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 292,
      backgroundColor: AppColors.secondaryLight,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              children: [
                // Navbar tabs (Home/Chat/Tasks/Expenses) live only in bottom bar.
                for (final item in _items.where((e) => e.$1 >= 4)) ...[
                  _drawerItem(context, item.$1, item.$3, item.$2),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI approval limit',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SAR 1,500',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white24, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filter Connect',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icon/splash_logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: const Text(
                    'F',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FILTER CONNECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Filter Car Services',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    int index,
    String title,
    IconData icon,
  ) {
    final isSelected = _index == index;
    final badge = _badges[index];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _index = index);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primaryLight : Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar (same pattern as OwnerBottomBar) ────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    const tabs = <(int, IconData, String)>[
      (0, Icons.home_rounded, 'Home'),
      (1, Icons.chat_bubble_rounded, 'Chat'),
      (2, Icons.task_alt_rounded, 'Tasks'),
      (3, Icons.receipt_long_rounded, 'Expenses'),
    ];

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
              for (final t in tabs)
                _bottomNavItem(
                  t.$1,
                  t.$2,
                  t.$3,
                  badge: t.$1 == 1 ? (_badges[1] ?? 4) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
    int targetIndex,
    IconData icon,
    String label, {
    int? badge,
  }) {
    final isSelected = _index == targetIndex;
    return GestureDetector(
      onTap: () => setState(() => _index = targetIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primaryLight : Colors.grey,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 10,
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