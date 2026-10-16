import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'locker_management_view_model.dart';
import 'locker_shared_widgets.dart';

/// Collections tab: completed cashier → locker collections.
class LockerCollectionsTab extends StatelessWidget {
  final LockerManagementViewModel vm;

  const LockerCollectionsTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        SectionHeader(
          l10n.ownerLockerRecentCollections,
          vm.recentCollections.length,
          action: Icons.refresh_rounded,
          onAction: vm.refresh,
        ),
        buildCollectionsTable(context, vm.recentCollections),
      ],
    );
  }
}
