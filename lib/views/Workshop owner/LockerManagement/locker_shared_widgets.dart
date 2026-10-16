import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../models/workshop_owner_models.dart';
import '../widgets/reusable_data_table.dart';

/// Shared formatting / small widgets reused across all locker
/// management tabs.

String fmtDate(DateTime d) => DateFormat('dd/MM/yy, hh:mm a').format(d.toLocal());

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData? action;
  final VoidCallback? onAction;

  const SectionHeader(
      this.title,
      this.count, {
        super.key,
        this.action,
        this.onAction,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.h2.copyWith(fontSize: 15, color: AppColors.secondaryLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ownerLocalizeDigits(context, '$count'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
          const Spacer(),
          if (action != null)
            IconButton(
              onPressed: onAction,
              icon: Icon(action, size: 18, color: AppColors.secondaryLight),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

Widget statusPill(String status, {bool isOverdue = false}) {
  final s = status.toUpperCase();
  Color bg;
  Color fg;
  String label = s;

  if (isOverdue) {
    bg = Colors.red.withValues(alpha: 0.10);
    fg = Colors.red;
    label = 'OVERDUE';
  } else {
    switch (s) {
      case 'PENDING':
      case 'ASSIGN':
        bg = const Color(0xFFFCC247).withValues(alpha: 0.22);
        fg = const Color(0xFF8A6A0A);
        label = s == 'ASSIGN' ? 'PENDING' : s;
        break;
      case 'ASSIGNED':
      case 'COLLECT':
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        fg = const Color(0xFF3B82F6);
        label = s == 'COLLECT' ? 'ASSIGNED' : s;
        break;
      case 'COLLECTED':
      case 'MATCHED':
        bg = Colors.green.withValues(alpha: 0.10);
        fg = Colors.green.shade700;
        break;
      case 'SHORT':
        bg = Colors.red.withValues(alpha: 0.10);
        fg = Colors.red;
        break;
      case 'EXCESS':
        bg = Colors.green.withValues(alpha: 0.10);
        fg = Colors.green.shade700;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade700;
    }
  }

  return TablePill(label: label, bgColor: bg, textColor: fg, fontSize: 9.5);
}

// ── Collection requests table ─────────────────────────────────────────────
Widget buildRequestsTable(
  BuildContext context,
  List<LockerCollectionRequest> items,
) {
  final l10n = AppLocalizations.of(context)!;
  return ReusableDataTable<LockerCollectionRequest>(
    items: items,
    emptyMessage: 'No collection requests yet',
    outerPadding: EdgeInsets.zero,
    minWidth: 780,
    columns: [
      ReusableTableColumn(
        key: 'reference',
        title: l10n.ownerLockerColReference,
        width: 130,
      ),
      ReusableTableColumn(
        key: 'branch',
        title: l10n.ownerLockerColBranch,
        width: 110,
      ),
      ReusableTableColumn(
        key: 'cashier',
        title: l10n.ownerLockerColCashier,
        width: 90,
      ),
      const ReusableTableColumn(key: 'officer', title: 'OFFICER', width: 90),
      const ReusableTableColumn(
        key: 'expected',
        title: 'EXPECTED',
        width: 90,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(
        key: 'cashDiff',
        title: 'CASH DIFF (CLOSING)',
        width: 110,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(
        key: 'status',
        title: 'STATUS',
        width: 90,
        alignment: Alignment.center,
      ),
      const ReusableTableColumn(key: 'created', title: 'CREATED', width: 130),
    ],
    rowBuilder: (context, item, index) {
      final diffColor = item.closingCashDiff > 0.01
          ? Colors.red
          : (item.closingCashDiff < -0.01 ? Colors.green : Colors.grey.shade600);
      return [
        TablePill(
          label: item.referenceCode,
          bgColor: AppColors.secondaryLight.withValues(alpha: 0.06),
          textColor: AppColors.secondaryLight,
        ),
        Text(item.branchName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        LocalizedApiText(
          item.cashierName,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          item.assignedOfficerName ?? '—',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.assignedOfficerName == null ? Colors.grey : Colors.black87),
        ),
        Text(ownerFormatMoney(context, item.expectedAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(ownerFormatMoney(context, item.closingCashDiff), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: diffColor)),
        statusPill(item.uiStatus.isNotEmpty ? item.uiStatus : item.status, isOverdue: item.isOverdue),
        Text(fmtDate(item.createdAt), style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
      ];
    },
  );
}

// ── Collections table ───────────────────────────────────────────────────────
Widget buildCollectionsTable(
  BuildContext context,
  List<LockerCollectionRecord> items,
) {
  final l10n = AppLocalizations.of(context)!;
  return ReusableDataTable<LockerCollectionRecord>(
    items: items,
    emptyMessage: 'No collections recorded yet',
    outerPadding: EdgeInsets.zero,
    minWidth: 820,
    columns: [
      ReusableTableColumn(
        key: 'reference',
        title: l10n.ownerLockerColReference,
        width: 130,
      ),
      ReusableTableColumn(
        key: 'branch',
        title: l10n.ownerLockerColBranch,
        width: 110,
      ),
      ReusableTableColumn(
        key: 'cashier',
        title: l10n.ownerLockerColCashier,
        width: 90,
      ),
      const ReusableTableColumn(key: 'officer', title: 'OFFICER', width: 90),
      const ReusableTableColumn(
        key: 'expected',
        title: 'EXPECTED',
        width: 90,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(
        key: 'received',
        title: 'RECEIVED',
        width: 90,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(
        key: 'difference',
        title: 'DIFFERENCE',
        width: 90,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(
        key: 'status',
        title: 'STATUS',
        width: 90,
        alignment: Alignment.center,
      ),
      const ReusableTableColumn(key: 'collected', title: 'COLLECTED', width: 130),
    ],
    rowBuilder: (context, item, index) {
      final diffColor = item.difference < -0.01
          ? Colors.red
          : (item.difference > 0.01 ? Colors.green : Colors.grey.shade600);
      return [
        TablePill(
          label: item.referenceCode,
          bgColor: AppColors.secondaryLight.withValues(alpha: 0.06),
          textColor: AppColors.secondaryLight,
        ),
        Text(item.branchName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        LocalizedApiText(
          item.cashierName,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          item.officerName ?? '—',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.officerName == null ? Colors.grey : Colors.black87),
        ),
        Text(ownerFormatMoney(context, item.expectedAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(ownerFormatMoney(context, item.receivedAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(ownerFormatMoney(context, item.difference), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: diffColor)),
        statusPill(item.status),
        Text(fmtDate(item.collectedAt), style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
      ];
    },
  );
}

// ── Bank deposits table ─────────────────────────────────────────────────────
Widget buildDepositsTable(
  BuildContext context,
  List<LockerBankDeposit> items,
) {
  final l10n = AppLocalizations.of(context)!;
  return ReusableDataTable<LockerBankDeposit>(
    items: items,
    emptyMessage: 'No bank deposits yet',
    outerPadding: EdgeInsets.zero,
    minWidth: 560,
    columns: [
      ReusableTableColumn(
        key: 'reference',
        title: l10n.ownerLockerColReference,
        width: 130,
      ),
      const ReusableTableColumn(key: 'register', title: 'REGISTER', width: 110),
      ReusableTableColumn(
        key: 'branch',
        title: l10n.ownerLockerColBranch,
        width: 110,
      ),
      const ReusableTableColumn(
        key: 'amount',
        title: 'AMOUNT',
        width: 90,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(key: 'date', title: 'DATE', width: 130),
    ],
    rowBuilder: (context, item, index) {
      return [
        TablePill(
          label: item.referenceCode.isEmpty ? '—' : item.referenceCode,
          bgColor: AppColors.secondaryLight.withValues(alpha: 0.06),
          textColor: AppColors.secondaryLight,
        ),
        Text(item.registerName.isEmpty ? '—' : item.registerName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        Text(item.branchName.isEmpty ? '—' : item.branchName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        Text(ownerFormatMoney(context, item.amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondaryLight)),
        Text(fmtDate(item.date), style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
      ];
    },
  );
}

// ── Petty cash table ─────────────────────────────────────────────────────────
Widget buildPettyCashTable(
  BuildContext context,
  List<LockerPettyCash> items,
) {
  final l10n = AppLocalizations.of(context)!;
  return ReusableDataTable<LockerPettyCash>(
    items: items,
    emptyMessage: 'No petty cash float issued yet',
    outerPadding: EdgeInsets.zero,
    minWidth: 560,
    columns: [
      ReusableTableColumn(
        key: 'cashier',
        title: l10n.ownerLockerColCashier,
        width: 130,
      ),
      const ReusableTableColumn(
        key: 'amount',
        title: 'AMOUNT',
        width: 100,
        alignment: Alignment.centerRight,
      ),
      const ReusableTableColumn(key: 'description', title: 'DESCRIPTION', width: 200),
      const ReusableTableColumn(key: 'date', title: 'DATE', width: 130),
    ],
    rowBuilder: (context, item, index) {
      return [
        item.cashierName.isEmpty
            ? Text('—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))
            : LocalizedApiText(
                item.cashierName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
        Text(ownerFormatMoney(context, item.amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondaryLight)),
        Text(
          item.description.isEmpty ? '—' : item.description,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: item.description.isEmpty ? Colors.grey : Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(fmtDate(item.date), style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
      ];
    },
  );
}

// ── Staff (supervisors / officers) table ────────────────────────────────────
Widget buildStaffTable(
  BuildContext context,
  List<LockerUser> items,
  String emptyMessage,
) {
  final l10n = AppLocalizations.of(context)!;
  return ReusableDataTable<LockerUser>(
    items: items,
    emptyMessage: emptyMessage,
    outerPadding: EdgeInsets.zero,
    minWidth: 480,
    columns: [
      ReusableTableColumn(key: 'name', title: l10n.ownerLockerColName, width: 150),
      ReusableTableColumn(key: 'email', title: l10n.ownerLockerColEmail, width: 170),
      ReusableTableColumn(key: 'mobile', title: l10n.ownerLockerColMobile, width: 110),
      ReusableTableColumn(
        key: 'status',
        title: l10n.ownerLockerColStatus,
        width: 90,
        alignment: Alignment.center,
      ),
    ],
    rowBuilder: (context, item, index) {
      return [
        Text(item.name.isEmpty ? '—' : item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(
          item.email ?? '—',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: item.email == null ? Colors.grey : Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(item.mobile.isEmpty ? '—' : item.mobile, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        TablePill(
          label: item.isActive
              ? l10n.ownerCommonActiveLabel
              : l10n.ownerCommonInactive,
          bgColor: item.isActive ? Colors.green.withValues(alpha: 0.10) : Colors.grey.withValues(alpha: 0.12),
          textColor: item.isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 9.5,
        ),
      ];
    },
  );
}