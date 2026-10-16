import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'reports_management_view_model.dart';

class _ProductItem {
  final String name;
  final String type;
  final int qty;
  final double revenue;

  _ProductItem({
    required this.name,
    required this.type,
    required this.qty,
    required this.revenue,
  });
}

class ByProductTab extends StatelessWidget {
  final String searchQuery;
  final String selectedTechnician;
  final ValueChanged<String> onTechnicianChanged;
  final ReportsManagementViewModel vm;

  const ByProductTab({
    super.key,
    required this.searchQuery,
    required this.selectedTechnician,
    required this.onTechnicianChanged,
    required this.vm,
  });

  List<_ProductItem> get _items {
    return (vm.reportsData?.byProduct ?? [])
        .map(
          (r) => _ProductItem(
            name: r.displayProductName.isNotEmpty ? r.displayProductName : '—',
            type: r.itemType.isNotEmpty ? r.itemType : 'product',
            qty: r.qtySold,
            revenue: r.revenueSar,
          ),
        )
        .toList();
  }
  List<String> get _technicians => ['All technicians'];

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      final q = searchQuery.toLowerCase();
      return q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.type.toLowerCase().contains(q) ||
          i.revenue.toString().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 200,
              child: OwnerStyledDropdown<String>(
                value: selectedTechnician,
                options: [
                  for (final t in _technicians)
                    OwnerDropdownOption(value: t, label: t),
                ],
                onChanged: (v) {
                  if (v != null) onTechnicianChanged(v);
                },
                height: 44,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                menuMinWidth: 200,
                localizeLabels: true,
                triggerStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ReportsTable(
              columns: [
                AppLocalizations.of(context)!.ownerReportsColProductService,
                AppLocalizations.of(context)!.ownerReportsColType,
                AppLocalizations.of(context)!.ownerReportsColQty,
                AppLocalizations.of(context)!.ownerReportsColRevenue,
              ],
              rows: filtered.map((p) => [
                Text(p.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis) as Widget,
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.type,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ),
                Text(ownerLocalizeDigits(context, '${p.qty}'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(ownerFormatMoney(context, p.revenue),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900)),
              ]).toList(),
              emptyWidget: _EmptyState(
                message: searchQuery.isNotEmpty
                    ? 'No products match your search.'
                    : 'No product breakdown for this scope.',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded,
                color: Colors.grey.shade400, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
