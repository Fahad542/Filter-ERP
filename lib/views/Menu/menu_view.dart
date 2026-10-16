import 'package:flutter/material.dart';
import '../../data/network/api_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/widgets.dart';
import '../../services/session_service.dart';
import '../../services/mobile_app_menu_service.dart';
import 'menu_grid_shimmer.dart';
import '../Workshop pos app/Login/login_view.dart';
import '../Locker App/Auth/locker_login_view.dart';
import '../Workshop owner/Auth/owner_login_view.dart';
import '../Technician App/Auth/tech_login_view.dart';
import '../Super Admin/Auth/super_admin_login_view.dart';
import '../supplier/Login/supplier_login_view.dart';

class _MenuPortalItem {
  const _MenuPortalItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String key;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  final MobileAppMenuService _menuService = MobileAppMenuService();

  List<MobileAppMenuPortal>? _enabledPortals;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchPortals();
  }

  Future<void> _fetchPortals({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    final portals = await _menuService.fetchEnabledPortals();
    if (!mounted) return;
    setState(() {
      _enabledPortals = portals;
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _refreshPortals() => _fetchPortals(isRefresh: true);

  Map<String, _MenuPortalItem> _builtInPortals(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return {
      MobileAppMenuPortalKeys.superAdmin: _MenuPortalItem(
        key: MobileAppMenuPortalKeys.superAdmin,
        title: l10n.menuSuperAdminPortal,
        icon: Icons.admin_panel_settings_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SuperAdminLoginView()),
          );
        },
      ),
      MobileAppMenuPortalKeys.workshopOwner: _MenuPortalItem(
        key: MobileAppMenuPortalKeys.workshopOwner,
        title: l10n.menuWorkshopOwner,
        icon: Icons.store_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OwnerLoginView()),
          );
        },
      ),
      MobileAppMenuPortalKeys.technician: _MenuPortalItem(
        key: MobileAppMenuPortalKeys.technician,
        title: l10n.menuTechnicianApp,
        icon: Icons.engineering_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TechLoginView()),
          );
        },
      ),
      MobileAppMenuPortalKeys.pos: _MenuPortalItem(
        key: MobileAppMenuPortalKeys.pos,
        title: l10n.menuWorkshopPosApp,
        icon: Icons.point_of_sale_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginView()),
          );
        },
      ),
      MobileAppMenuPortalKeys.locker: _MenuPortalItem(
        key: MobileAppMenuPortalKeys.locker,
        title: l10n.menuLockerPortal,
        icon: Icons.lock_rounded,
        onTap: () async {
          final isLoggedIn =
              await SessionService().isLoggedIn(role: 'locker');
          if (!context.mounted) return;

          if (!isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LockerLoginView()),
            );
            return;
          }

          final dashboard =
              await SessionService().lockerDashboardForLoggedInUser();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => dashboard),
          );
        },
      ),
      MobileAppMenuPortalKeys.supplier: _MenuPortalItem(
        key: MobileAppMenuPortalKeys.supplier,
        title: l10n.menuSupplier,
        icon: Icons.local_shipping_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupplierLoginView()),
          );
        },
      ),
    };
  }

  List<_MenuPortalItem> _resolveVisiblePortals(
    BuildContext context,
    AppLocalizations l10n,
    List<MobileAppMenuPortal> enabledPortals,
  ) {
    final builtIn = _builtInPortals(context, l10n);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return [
      for (final remote in enabledPortals)
        if (builtIn.containsKey(remote.key))
          builtIn[remote.key]!
        else
          _MenuPortalItem(
            key: remote.key,
            title: (isArabic && (remote.titleAr?.isNotEmpty ?? false))
                ? remote.titleAr!
                : (remote.titleEn ?? remote.key),
            icon: Icons.apps_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.menuPortalComingSoon)),
              );
            },
          ),
    ];
  }

  Widget _buildPortalGrid({
    required BuildContext context,
    required AppLocalizations l10n,
    required int crossAxisCount,
    required double childAspectRatio,
    required bool isLandscape,
    required double horizontalPadding,
    required double gridTop,
    required double? headerHeight,
  }) {
    final showShimmer =
        (_isLoading && _enabledPortals == null) || _isRefreshing;

    if (showShimmer) {
      return Padding(
        padding: EdgeInsets.only(
          top: gridTop,
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        child: MenuGridShimmer(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isLandscape ? 10 : 16,
          mainAxisSpacing: isLandscape ? 10 : 16,
          itemCount: 6,
        ),
      );
    }

    final portals = _resolveVisiblePortals(
      context,
      l10n,
      _enabledPortals ?? const [],
    );

    return Padding(
      padding: EdgeInsets.only(
        top: gridTop,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: portals.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  l10n.menuNoPortalsAvailable,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          : GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isLandscape ? 10 : 16,
              mainAxisSpacing: isLandscape ? 10 : 16,
              childAspectRatio: childAspectRatio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final portal in portals)
                  MenuCard(
                    title: portal.title,
                    icon: portal.icon,
                    onTap: portal.onTap,
                  ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;
    final l10n = AppLocalizations.of(context)!;

    final crossAxisCount = isTablet ? (isLandscape ? 4 : 2) : 2;
    final childAspectRatio =
        isTablet ? (isLandscape ? 1.3 : 1.12) : 0.85;
    final horizontalPadding = isTablet
        ? screenWidth * (isLandscape ? 0.1 : 0.12)
        : 24.0;
    final headerHeight = isTablet
        ? (isLandscape ? screenHeight * 0.4 : null)
        : null;
    final gridTop = isTablet
        ? (isLandscape ? screenHeight * 0.26 : screenHeight * 0.25)
        : screenHeight * 0.22;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          isTablet ? (isLandscape ? 1.08 : 1.0) : 1.0,
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: Colors.white,
          displacement: gridTop + 12,
          onRefresh: _refreshPortals,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomAuthHeader(
                        title: l10n.menuAllApps,
                        subtitle: l10n.menuSubtitle,
                        height: headerHeight,
                      ),
                      _buildPortalGrid(
                        context: context,
                        l10n: l10n,
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        isLandscape: isLandscape,
                        horizontalPadding: horizontalPadding,
                        gridTop: gridTop,
                        headerHeight: headerHeight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      l10n.menuVersion,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (ApiConstants.environmentLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        ApiConstants.environmentLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    height: 24 + MediaQuery.of(context).padding.bottom,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
