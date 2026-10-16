import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/owner_data_service.dart';
import '../../../utils/app_colors.dart';

/// Shared branch picker bottom sheet for the Workshop Owner app bar.
Future<void> showOwnerBranchPickerSheet(BuildContext context) async {
  final data = context.read<OwnerDataService>();
  final l10n = AppLocalizations.of(context)!;

  if (data.branches.isEmpty && !data.isLoadingBranches) {
    // Fire-and-forget; sheet still opens with "All Branches".
    data.fetchBranches();
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Consumer<OwnerDataService>(
        builder: (context, svc, _) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardSelectBranch,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: svc.isLoadingBranches && svc.branches.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _OwnerBranchPickerItem(
                                title: l10n.dashboardAllBranches,
                                subtitle: null,
                                isSelected: svc.selectedBranch == null,
                                onTap: () {
                                  svc.setSelectedBranch(null);
                                  Navigator.pop(sheetContext);
                                },
                              ),
                              ...svc.branches.map(
                                (b) => _OwnerBranchPickerItem(
                                  title: b.translatedName ?? b.name,
                                  subtitle: b.translatedLocation ?? b.location,
                                  isSelected: svc.selectedBranch?.id == b.id,
                                  onTap: () {
                                    svc.setSelectedBranch(b);
                                    Navigator.pop(sheetContext);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}

class _OwnerBranchPickerItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OwnerBranchPickerItem({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          subtitle == null ? Icons.business_rounded : Icons.location_on_rounded,
          color: isSelected ? AppColors.secondaryLight : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 15,
          color: AppColors.secondaryLight,
        ),
      ),
      subtitle: subtitle == null || subtitle!.isEmpty
          ? null
          : Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primaryLight, size: 22)
          : null,
    );
  }
}

/// Convenience label for the current global branch selection.
String ownerBranchLabel(OwnerDataService data, AppLocalizations l10n) {
  final Branch? b = data.selectedBranch;
  if (b == null) return l10n.dashboardAllBranches;
  return b.name;
}
