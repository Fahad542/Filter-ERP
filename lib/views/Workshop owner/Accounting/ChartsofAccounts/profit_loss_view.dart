import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../data/repositories/owner_repository.dart';
import '../../../../services/owner_data_service.dart';
import '../../../../services/session_service.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../owner_shell.dart';
import '../../widgets/owner_branch_reload_registrar.dart';
import '../../widgets/owner_global_date_filters.dart';
import '../../widgets/owner_ui_constants.dart';
import 'profit_loss_tab.dart';
import 'profit_loss_view_model.dart';

/// Standalone P&L screen — same report as web Chart of Accounts → P&L.
class ProfitLossView extends StatelessWidget {
  const ProfitLossView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitLossViewModel>(
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: OwnerDashboardTitle(subtitle: l10n.ownerPnLTitle),
            showBackButton: false,
            showNotification: true,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
            onMenuPressed: () => OwnerShell.openDrawer(context),
            bottomOverlap: const OwnerGlobalDateOverlapFilters(),
          ),
          body: const ProfitAndLossTab(),
        );
      },
    );
  }
}

/// Shell tab — provides [ProfitLossViewModel] wired to owner auth + API.
class ProfitLossShellTab extends StatelessWidget {
  const ProfitLossShellTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProfitLossViewModel(
        ownerRepository: ctx.read<OwnerRepository>(),
        sessionService: ctx.read<SessionService>(),
        ownerDataService: ctx.read<OwnerDataService>(),
      ),
      child: OwnerBranchReloadRegistrar(
        tabIndex: 35,
        onReload: (ctx) =>
            ctx.read<ProfitLossViewModel>().syncWithSelectedBranch(),
        child: const ProfitLossView(),
      ),
    );
  }
}
