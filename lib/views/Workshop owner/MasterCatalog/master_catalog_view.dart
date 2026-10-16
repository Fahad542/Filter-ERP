// ─── master_catalog_view.dart ─────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_branch_reload_registrar.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../widgets/owner_ui_constants.dart';
import 'master_catalog_categories_tab.dart';
import 'master_catalog_departments_tab.dart';
import 'master_catalog_products_tab.dart';
import 'master_catalog_services_tab.dart';
import 'master_catalog_view_model.dart';

class MasterCatalogView extends StatelessWidget {
  /// Both params are optional.
  /// - If passed explicitly they are used as-is (e.g. from a parent that
  ///   already holds these objects, or in tests).
  /// - If omitted (the common `const MasterCatalogView()` case) fresh
  ///   instances are created directly — no Provider ancestor required.
  ///   CatalogRepository is stateless (wraps BaseApiService) so a new
  ///   instance is always safe.  SessionService reads its token from secure
  ///   storage internally, so a new instance also works correctly.
  final CatalogRepository? repository;
  final SessionService? sessionService;
  final int initialTab;

  const MasterCatalogView({
    super.key,
    this.repository,
    this.sessionService,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? CatalogRepository();
    final session = sessionService ?? SessionService();

    return ChangeNotifierProvider(
      create: (ctx) => MasterCatalogViewModel(
        repository: repo,
        sessionService: session,
        ownerDataService: ctx.read<OwnerDataService>(),
      ),
      child: OwnerBranchReloadRegistrar(
        tabIndex: 15,
        onReload: (ctx) =>
            ctx.read<MasterCatalogViewModel>().syncWithSelectedBranch(),
        child: _MasterCatalogBody(initialTab: initialTab),
      ),
    );
  }
}

class _MasterCatalogBody extends StatefulWidget {
  final int initialTab;
  const _MasterCatalogBody({this.initialTab = 0});

  @override
  State<_MasterCatalogBody> createState() => _MasterCatalogBodyState();
}

class _MasterCatalogBodyState extends State<_MasterCatalogBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _tabController.addListener(_onTabChanged);

    // Kick off the initial data load once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<MasterCatalogViewModel>();
      vm.init().then((_) {
        if (!mounted) return;
        vm.ensureTabData(_tabController.index);
      });
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    context.read<MasterCatalogViewModel>().ensureTabData(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MasterCatalogViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: AppLocalizations.of(context)!.ownerShellMasterCatalog,
            showDrawer: true,
            showBackButton: false,
            showNotification: false,
          ),
          body: Column(
            children: [
              // ── Subtitle banner ────────────────────────────────────────
              _SubtitleBanner(currentTabIndex: _tabController.index),

              _MasterCatalogTabBar(controller: _tabController),

              // ── Tab content ────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    MasterCatalogDepartmentsTab(),
                    MasterCatalogCategoriesTab(),
                    MasterCatalogProductsTab(),
                    MasterCatalogServicesTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Subtitle Banner ──────────────────────────────────────────────────────────

class _SubtitleBanner extends StatelessWidget {
  final int currentTabIndex;
  const _SubtitleBanner({required this.currentTabIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}

class _MasterCatalogTabBar extends StatelessWidget {
  final TabController controller;
  const _MasterCatalogTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerSegmentedTabs(
      controller: controller,
      tabs: [
        l10n.ownerCatalogTabDepartments,
        l10n.ownerCatalogTabCategories,
        l10n.ownerCatalogTabProducts,
        l10n.ownerCatalogTabServices,
      ],
    );
  }
}