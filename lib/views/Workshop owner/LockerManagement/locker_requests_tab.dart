import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'locker_management_view_model.dart';
import 'locker_shared_widgets.dart';

/// Requests tab: full list of collection requests (cashier closings
/// awaiting pickup / collection by a locker officer).
class LockerRequestsTab extends StatelessWidget {
  final LockerManagementViewModel vm;

  const LockerRequestsTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        SectionHeader(
          AppLocalizations.of(context)!.ownerLockerRecentRequests,
          vm.recentRequests.length,
          action: Icons.refresh_rounded,
          onAction: vm.refresh,
        ),
        buildRequestsTable(context, vm.recentRequests),
      ],
    );
  }
}
