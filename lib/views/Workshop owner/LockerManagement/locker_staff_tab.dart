import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'locker_management_view_model.dart';
import 'locker_shared_widgets.dart';

/// Staff tab: locker supervisors + collection officers.
class LockerStaffTab extends StatelessWidget {
  final LockerManagementViewModel vm;

  const LockerStaffTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        SectionHeader(l10n.ownerLockerSupervisors, vm.supervisors.length),
        buildStaffTable(
          context,
          vm.supervisors,
          l10n.ownerLockerNoSupervisor,
        ),
        const SizedBox(height: 22),
        SectionHeader(l10n.ownerLockerCollectionOfficers, vm.officers.length),
        buildStaffTable(
          context,
          vm.officers,
          l10n.ownerLockerNoCollectors,
        ),
      ],
    );
  }
}
