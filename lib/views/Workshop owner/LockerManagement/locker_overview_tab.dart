import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'locker_management_view_model.dart';
import 'locker_shared_widgets.dart';

/// Overview tab: quick snapshot (first 3 rows) of every section.
class LockerOverviewTab extends StatelessWidget {
  final LockerManagementViewModel vm;

  const LockerOverviewTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        SectionHeader(AppLocalizations.of(context)!.ownerLockerRecentRequests, vm.recentRequests.length),
        buildRequestsTable(context, vm.recentRequests.take(3).toList()),
        const SizedBox(height: 22),
        SectionHeader(AppLocalizations.of(context)!.ownerLockerRecentCollections, vm.recentCollections.length),
        buildCollectionsTable(context, vm.recentCollections.take(3).toList()),
        const SizedBox(height: 22),
        SectionHeader(AppLocalizations.of(context)!.ownerLockerBankDeposits, vm.recentBankDeposits.length),
        buildDepositsTable(context, vm.recentBankDeposits.take(3).toList()),
        const SizedBox(height: 22),
        SectionHeader(AppLocalizations.of(context)!.ownerLockerPettyIssued, vm.recentPettyCashIssues.length),
        buildPettyCashTable(context, vm.recentPettyCashIssues.take(3).toList()),
      ],
    );
  }
}
