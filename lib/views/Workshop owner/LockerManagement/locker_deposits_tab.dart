import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'locker_management_view_model.dart';
import 'locker_shared_widgets.dart';

/// Deposits tab: locker → bank deposit records.
class LockerDepositsTab extends StatelessWidget {
  final LockerManagementViewModel vm;

  const LockerDepositsTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        SectionHeader(AppLocalizations.of(context)!.ownerLockerBankDeposits, vm.recentBankDeposits.length),
        buildDepositsTable(context, vm.recentBankDeposits),
      ],
    );
  }
}
