import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'locker_management_view_model.dart';
import 'locker_shared_widgets.dart';

/// Petty cash tab: petty cash floats issued from the locker.
class LockerPettyCashTab extends StatelessWidget {
  final LockerManagementViewModel vm;

  const LockerPettyCashTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        SectionHeader(AppLocalizations.of(context)!.ownerLockerPettyIssued, vm.recentPettyCashIssues.length),
        buildPettyCashTable(context, vm.recentPettyCashIssues),
      ],
    );
  }
}
