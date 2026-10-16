import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/add_button_fab.dart';
import '../owner_shell.dart';
import '../widgets/owner_app_bar.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../widgets/owner_shimmer.dart';
import 'add_supplier_dialog.dart';
import 'purchase_history_tab.dart';
import 'suppliers_tab.dart';
import 'suppliers_view_model.dart';

class SuppliersView extends StatefulWidget {
  const SuppliersView({super.key});

  @override
  State<SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<SuppliersView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SuppliersViewModel>().initData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<SuppliersViewModel>();
    final showAddSupplierFab = _tabController.index == 0;

    final showBack = OwnerShell.openedWithBack(context);
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: l10n.ownerSuppliersTitle),
        showDrawer: !showBack,
        showBackButton: showBack,
        showNotification: false,
        onMenuPressed: () => OwnerShell.openDrawer(context),
      ),
      floatingActionButton: showAddSupplierFab
          ? AppFabSheetButton<SuppliersViewModel>(
        label: l10n.ownerSuppliersAdd,
        icon: Icons.add_business_rounded,
        viewModel: vm,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.secondaryLight,
        onClear: () {
          // Reset the form to its default (blank) values and kick off
          // the registered-suppliers fetch immediately, same as the
          // previous showAddSupplierDialog entry point did, so the
          // list is ready/loading by the time the sheet animates in.
          vm.clearForm();
          vm.loadRegisteredSuppliers();
        },
        sheetBuilder: (context, vm) => const AddSupplierDialog(),
      )
          : null,
      body: vm.isLoading && vm.suppliersList.isEmpty
          ? const OwnerListPageShimmer(showTabs: true)
          : Column(
        children: [
          OwnerSegmentedTabs(
            controller: _tabController,
            tabs: [
              l10n.ownerSuppliersTabSuppliers,
              l10n.ownerSuppliersTabHistory,
            ],
            layout: PosSegmentedTabLayout.expanded,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SuppliersTab(),
                PurchaseHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
