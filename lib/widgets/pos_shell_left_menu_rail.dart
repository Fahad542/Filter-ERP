import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_colors.dart';

/// Shell tab index for Orders Hub — rail hidden; menu stays in the app bar.
const int kPosShellOrdersTabIndex = 2;

/// Shell tab index for technician broadcasts list.
const int kPosShellBroadcastTabIndex = 10;

/// Shell tab index for AI Camera / AI Orders list.
const int kPosShellAiOrdersTabIndex = 17;
const int kPosShellNfcAdjustmentsTabIndex = 18;

/// Left inset before the dark rounded rail.
const double kPosShellLeftMenuRailInset = 6;

/// Inner width of the dark navigation strip (icon + label).
const double kPosShellLeftMenuRailWidth = 80;

/// Total horizontal space reserved beside tab body content.
const double kPosShellLeftMenuRailTotalWidth =
    kPosShellLeftMenuRailInset + kPosShellLeftMenuRailWidth + 4;

class PosShellRailNavEntry {
  const PosShellRailNavEntry({
    required this.shellIndex,
    required this.label,
    required this.icon,
  });

  final int shellIndex;
  final String label;
  final IconData icon;
}

List<PosShellRailNavEntry> buildPosShellRailNavEntries(AppLocalizations l10n) {
  return [
    PosShellRailNavEntry(
      shellIndex: 0,
      label: l10n.posNavHome,
      icon: Icons.home_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 12,
      label: l10n.posCorporateBookingsTitle,
      icon: Icons.business_center_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 2,
      label: l10n.posNavOrdersHub,
      icon: Icons.receipt_long_outlined,
    ),
    const PosShellRailNavEntry(
      shellIndex: kPosShellAiOrdersTabIndex,
      label: 'AI Orders',
      icon: Icons.videocam_outlined,
    ),
    PosShellRailNavEntry(
      shellIndex: 9,
      label: l10n.posNavTakeaway,
      icon: Icons.takeout_dining_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 10,
      label: l10n.posNavBroadcastTechnician,
      icon: Icons.podcasts_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 1,
      label: l10n.posNavInventory,
      icon: Icons.inventory_2_outlined,
    ),
    PosShellRailNavEntry(
      shellIndex: 11,
      label: l10n.posNavInventorySales,
      icon: Icons.query_stats_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 13,
      label: l10n.posNavPurchaseOrder,
      icon: Icons.shopping_cart_checkout_outlined,
    ),
    PosShellRailNavEntry(
      shellIndex: 7,
      label: l10n.posNavSalesReturn,
      icon: Icons.assignment_return_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 8,
      label: l10n.posNavReturnsList,
      icon: Icons.list_alt_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 4,
      label: l10n.posNavPettyCash,
      icon: Icons.payments_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 5,
      label: l10n.posNavPromoCodes,
      icon: Icons.local_offer_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 6,
      label: l10n.posNavTechnicians,
      icon: Icons.engineering_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 15,
      label: l10n.posNavSalaries,
      icon: Icons.account_balance_wallet_outlined,
    ),
    PosShellRailNavEntry(
      shellIndex: 16,
      label: l10n.posNavCashCollection,
      icon: Icons.payments_outlined,
    ),
    PosShellRailNavEntry(
      shellIndex: 14,
      label: l10n.posNavClosingHistory,
      icon: Icons.history_rounded,
    ),
    PosShellRailNavEntry(
      shellIndex: 3,
      label: l10n.posNavStoreClosing,
      icon: Icons.store_rounded,
    ),
  ];
}

/// Persistent side navigation (icon above label); follows locale start edge.
class PosShellLeftMenuRail extends StatelessWidget {
  const PosShellLeftMenuRail({
    super.key,
    required this.selectedIndex,
    required this.entries,
    required this.onSelectTab,
  });

  final int selectedIndex;
  final List<PosShellRailNavEntry> entries;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        kPosShellLeftMenuRailInset,
        6,
        0,
        8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _PosShellRailNavTile(
                label: entry.label,
                icon: entry.icon,
                selected: selectedIndex == entry.shellIndex,
                onTap: () => onSelectTab(entry.shellIndex),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PosShellRailNavTile extends StatelessWidget {
  const _PosShellRailNavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idleColor = Colors.white.withValues(alpha: 0.55);
    final activeColor = Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: selected ? activeColor : idleColor,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? activeColor : idleColor,
                  fontSize: 8.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
