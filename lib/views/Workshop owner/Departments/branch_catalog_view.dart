// ─── branch_catalog_view.dart ─────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/add_button_fab.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_branch_reload_registrar.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../owner_shell.dart';
import 'branch_catalog_view_model.dart';
import 'catalog_departments_tab.dart';
import 'catalog_products_tab.dart';
import 'catalog_services_tab.dart';
import 'catalog_categories_tab.dart';

class BranchCatalogView extends StatelessWidget {
  final CatalogRepository repository;
  final SessionService sessionService;
  final int initialTab;
  final bool initialLowStock;

  const BranchCatalogView({
    super.key,
    required this.repository,
    required this.sessionService,
    this.initialTab = 0,
    this.initialLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => BranchCatalogViewModel(
        repository: repository,
        sessionService: sessionService,
        ownerDataService: ctx.read<OwnerDataService>(),
        initialLowStock: initialLowStock,
      ),
      child: OwnerBranchReloadRegistrar(
        tabIndex: 13,
        onReload: (ctx) =>
            ctx.read<BranchCatalogViewModel>().syncWithSelectedBranch(),
        child: _BranchCatalogViewBody(initialTab: initialTab),
      ),
    );
  }
}

// ─── View Body ────────────────────────────────────────────────────────────────

class _BranchCatalogViewBody extends StatefulWidget {
  final int initialTab;
  const _BranchCatalogViewBody({this.initialTab = 0});

  @override
  State<_BranchCatalogViewBody> createState() => _BranchCatalogViewBodyState();
}

class _BranchCatalogViewBodyState extends State<_BranchCatalogViewBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.clamp(0, 3);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _currentTab,
    );
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchCatalogViewModel>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BranchCatalogViewModel>(
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: OwnerDashboardTitle(
                subtitle: l10n.ownerDashboardActionDeptProductsTitle),
            showBackButton: OwnerShell.openedWithBack(context),
            showDrawer: false,
            showGlobalLeft: !OwnerShell.openedWithBack(context),
            showNotification: true,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
          ),
          floatingActionButton: _buildFab(context, vm, l10n),
          body: Column(
            children: [
              // Branch selection is now done via the side menu drawer.
              // The top branch chip row has been removed — cleaner UI with
              // more vertical space for the actual content.
              _CatalogTabBar(
                controller: _tabController,
                deptsCount: vm.departmentsCount,
                productsCount: vm.productsCount,
                servicesCount: vm.servicesCount,
                categoriesCount: vm.categoriesCount,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CatalogDepartmentsTab(vm: vm),
                    CatalogProductsTab(vm: vm),
                    CatalogServicesTab(vm: vm),
                    CatalogCategoriesTab(vm: vm),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildFab(
      BuildContext context, BranchCatalogViewModel vm, AppLocalizations l10n) {
    if (_currentTab == 2) return null;
    switch (_currentTab) {
      case 0:
        return AppFabSheetButton<BranchCatalogViewModel>(
          key: const ValueKey(0),
          label: l10n.ownerCatalogRequestDepartment,
          icon: Icons.add_rounded,
          viewModel: vm,
          onClear: () {},
          sheetBuilder: (ctx, _) => CreateDepartmentSheet(vm: vm),
        );
      case 1:
        return AppFabSheetButton<BranchCatalogViewModel>(
          key: const ValueKey(1),
          label: l10n.ownerCatalogRequestProduct,
          icon: Icons.add_rounded,
          viewModel: vm,
          onClear: () {},
          sheetBuilder: (ctx, _) => CreateProductSheet(vm: vm),
        );
      case 3:
        return AppFabSheetButton<BranchCatalogViewModel>(
          key: const ValueKey(3),
          label: l10n.ownerCatalogRequestCategory,
          icon: Icons.add_rounded,
          viewModel: vm,
          onClear: () {},
          sheetBuilder: (ctx, _) => CreateCategorySheet(vm: vm),
        );
      default:
        return null;
    }
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _CatalogTabBar extends StatelessWidget {
  final TabController controller;
  final int deptsCount;
  final int productsCount;
  final int servicesCount;
  final int categoriesCount;

  const _CatalogTabBar({
    required this.controller,
    required this.deptsCount,
    required this.productsCount,
    required this.servicesCount,
    required this.categoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerSegmentedTabs(
      controller: controller,
      tabs: [
        l10n.ownerCatalogTabDepartments,
        l10n.ownerCatalogTabProducts,
        l10n.ownerCatalogTabServices,
        l10n.ownerCatalogTabCategories,
      ],
      counts: [deptsCount, productsCount, servicesCount, categoriesCount],
    );
  }
}
