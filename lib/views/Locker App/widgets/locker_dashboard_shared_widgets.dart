import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/app_colors.dart';
import '../../../data/repositories/locker_repository.dart'
    show LockerHistoryItem;
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';

// ── Loading / error states ──────────────────────────────────────────────────

class LockerDashboardLoader extends StatelessWidget {
  const LockerDashboardLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const OwnerDashboardShimmer();
  }
}

class LockerDashboardErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const LockerDashboardErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.lockerFailedLoadDashboard,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.lockerUnexpectedError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.lockerRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String localizedLockerUserType(BuildContext context, String? userType) {
  final l10n = AppLocalizations.of(context)!;
  switch (userType?.toLowerCase()) {
    case 'supervisor':
      return l10n.lockerRoleSupervisor;
    case 'manager':
      return l10n.lockerRoleManager;
    case 'workshop_owner':
      return l10n.lockerRoleWorkshopOwner;
    case 'workshop_supervisor':
      return l10n.lockerRoleWorkshopSupervisor;
    case 'collector':
      return l10n.lockerRoleCollector;
    case 'collection_officer':
      return l10n.lockerRoleCollectionOfficer;
    case 'workshop_collector':
      return l10n.lockerRoleWorkshopCollector;
    default:
      return userType == null || userType.trim().isEmpty
          ? ''
          : l10n.lockerStatusUnknown;
  }
}

/// Localize API collection / request status codes for badges.
String localizedLockerCollectionStatus(
  AppLocalizations l10n,
  String status,
) {
  switch (status.toLowerCase().trim()) {
    case 'pending':
      return l10n.lockerStatusPending;
    case 'assigned':
      return l10n.lockerStatusAssigned;
    case 'awaiting_approval':
    case 'pending_approval':
      return l10n.lockerStatusAwaiting;
    case 'collected':
      return l10n.lockerStatusCollected;
    case 'approved':
      return l10n.lockerStatusApproved;
    case 'rejected':
      return l10n.lockerStatusRejected;
    case 'matched':
      return l10n.lockerStatusMatched;
    case 'open':
      return l10n.lockerPosStatusOpen;
    case 'closed':
      return l10n.lockerPosStatusClosed;
    default:
      return status.trim().isEmpty ? '—' : l10n.lockerStatusUnknown;
  }
}

// ── Quick actions ────────────────────────────────────────────────────────────

class LockerActionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const LockerActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  /// Legacy single-line label (title without newline).
  String get label => title;
}

/// Quick actions grid — Owner dashboard dark-card chrome.
class LockerQuickActionsGrid extends StatelessWidget {
  final List<LockerActionItem> actions;
  final void Function(LockerActionItem) onTap;
  final int? Function(LockerActionItem item)? badgeFor;

  const LockerQuickActionsGrid({
    super.key,
    required this.actions,
    required this.onTap,
    this.badgeFor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerQuickActions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryLight,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];
            return _LockerQuickActionCard(
              item: item,
              badgeCount: badgeFor?.call(item),
              onTap: () => onTap(item),
            );
          },
        ),
      ],
    );
  }
}

class _LockerQuickActionCard extends StatelessWidget {
  final LockerActionItem item;
  final int? badgeCount;
  final VoidCallback onTap;

  const _LockerQuickActionCard({
    required this.item,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryLight,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: AppColors.secondaryLight,
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSecondaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          AppColors.onSecondaryLight.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  color: AppColors.onSecondaryLight,
                  size: 12,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Recent collections table ────────────────────────────────────────────────

class LockerRecentCollectionsCard extends StatelessWidget {
  final List<LockerHistoryItem> items;
  final int total;
  final bool isLoading;
  final VoidCallback onViewAll;

  const LockerRecentCollectionsCard({
    super.key,
    required this.items,
    required this.total,
    required this.isLoading,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.lockerRecentCollections,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight,
                  height: 1.1,
                ),
              ),
            ),
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  l10n.lockerViewAll,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(4),
            child: OwnerCardRowShimmer(),
          )
        else if (items.isEmpty)
          DecoratedBox(
            decoration: OwnerListStyle.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Center(
                child: Text(
                  l10n.lockerNoRecentCollections,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
        else
          Column(
            children: items
                .take(2)
                .map((item) => _RecentCollectionCard(item: item))
                .toList(),
          ),
      ],
    );
  }
}

class _RecentCollectionCard extends StatelessWidget {
  final LockerHistoryItem item;

  const _RecentCollectionCard({required this.item});

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'assigned':
        return Colors.blue.shade800;
      case 'awaiting_approval':
      case 'pending_approval':
        return Colors.purple.shade800;
      case 'collected':
        return Colors.green.shade700;
      case 'approved':
        return Colors.green.shade800;
      case 'rejected':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final statusLabel =
        localizedLockerCollectionStatus(l10n, item.collectionStatus);
    final officerRaw = item.officerName.trim();
    final branchRaw = item.branchName.trim();
    final cashierRaw = item.cashierName.trim();
    final dateRaw =
        '${DateFormat('dd/MM/yyyy').format(item.collectedAt)}, '
        '${DateFormat('HH:mm:ss').format(item.collectedAt)}';
    final amountRaw =
        '${l10n.lockerSarCurrency} ${item.expectedAmount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OwnerListIconBox(
                    icon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.referenceCode.isNotEmpty
                              ? AppTranslationService.localizeDigitsForLanguage(
                                  item.referenceCode,
                                  lang,
                                )
                              : AppTranslationService.localizeDigitsForLanguage(
                                  item.transactionRef,
                                  lang,
                                ),
                          style: OwnerListStyle.titleStyle,
                        ),
                        const SizedBox(height: 3),
                        if (branchRaw.isEmpty)
                          Text('—', style: OwnerListStyle.subtitleStyle)
                        else
                          LocalizedApiText(
                            branchRaw,
                            style: OwnerListStyle.subtitleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBg(item.collectionStatus),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel.isEmpty ? '—' : statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: OwnerListStyle.cardBorder),
              const SizedBox(height: 12),
              _RecentInfoRow(
                label: l10n.lockerLabelCashier,
                value: cashierRaw.isEmpty ? '—' : cashierRaw,
                translateValue: cashierRaw.isNotEmpty,
              ),
              const SizedBox(height: 8),
              _RecentInfoRow(
                label: l10n.lockerLabelOfficer,
                value: officerRaw.isEmpty ? '—' : officerRaw,
                translateValue: officerRaw.isNotEmpty,
              ),
              const SizedBox(height: 8),
              _RecentInfoRow(
                label: l10n.lockerLabelRequested,
                value: AppTranslationService.localizeDigitsForLanguage(
                  dateRaw,
                  lang,
                ),
              ),
              const SizedBox(height: 8),
              _RecentInfoRow(
                label: l10n.lockerLabelExpected,
                value: AppTranslationService.localizeDigitsForLanguage(
                  amountRaw,
                  lang,
                ),
                valueStyle: OwnerListStyle.titleStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool translateValue;

  const _RecentInfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.translateValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = valueStyle ??
        OwnerListStyle.subtitleStyle.copyWith(
          color: AppColors.secondaryLight,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: OwnerListStyle.metaStyle.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: OwnerListStyle.labelGrey,
            ),
          ),
        ),
        Expanded(
          child: translateValue
              ? LocalizedApiText(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                )
              : Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
        ),
      ],
    );
  }
}

// ── AppBar title (used with OwnerAppBar on the locker dashboards) ──────────

/// Two-line title used as the `title` widget for [OwnerAppBar] on the
/// locker supervisor/collector dashboards — same copy as the old inline
/// AppBar title, just reusable now that both dashboards share OwnerAppBar.
class LockerAppBarTitle extends StatelessWidget {
  const LockerAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.lockerPortalAppBarTitle,
      style: const TextStyle(
        color: AppColors.secondaryLight,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        fontSize: 16,
      ),
    );
  }
}
