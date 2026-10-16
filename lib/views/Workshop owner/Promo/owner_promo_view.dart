import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';
import 'owner_promo_view_model.dart';
import 'promo_create_sheet.dart';
import '../../../models/workshop_owner_models.dart';
import 'package:intl/intl.dart';

class OwnerPromoView extends StatefulWidget {
  const OwnerPromoView({super.key});

  @override
  State<OwnerPromoView> createState() => _OwnerPromoViewState();
}

class _OwnerPromoViewState extends State<OwnerPromoView> {
  // Tracks which promo cards have their extra details expanded.
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<OwnerPromoViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: 'Promo Codes',
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              vm.setEditPromoCode(null);
              PromoCreateSheet.show(context);
            },
            backgroundColor: AppColors.primaryLight,
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            label: const Text('New Promo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          body: vm.isLoading && vm.promoCodes.isEmpty
              ? const OwnerListPageShimmer(showKpi: true, showSearch: true)
              : _buildBody(vm),
        );
      },
    );
  }

  Widget _buildBody(OwnerPromoViewModel vm) {
    final total = vm.promoCodes.length;
    final active = vm.promoCodes.where((p) {
      bool isExpired = false;
      try {
        if (DateTime.parse(p.validTo).isBefore(DateTime.now())) isExpired = true;
      } catch (_) {}
      return p.isActive && !isExpired;
    }).length;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.fetchPromoCodes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          ReusableKpiGrid.owner(
            metrics: [
              ReusableKpiMetric(
                title: 'Total Promo Codes',
                value: '$total',
                icon: Icons.local_offer_rounded,
              ),
              ReusableKpiMetric(
                title: 'Active Promos',
                value: '$active',
                icon: Icons.toggle_on_rounded,
              ),
            ],
            crossAxisCount: 3,
          ),
          const SizedBox(height: 6),
          if (vm.promoCodes.isEmpty)
            _buildEmptyState()
          else
            ...vm.promoCodes.map((p) => _buildPromoCard(vm, p)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_rounded, size: 72, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No promo codes found', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(OwnerPromoViewModel vm, PromoCode p) {
    bool isExpired = false;
    try {
      final validToDateTime = DateTime.parse(p.validTo);
      if (validToDateTime.isBefore(DateTime.now())) {
        isExpired = true;
      }
    } catch (_) {}

    final activeColor = (p.isActive && !isExpired) ? Colors.green : Colors.grey;
    final isExpanded = _expandedIds.contains(p.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.local_offer_rounded, color: activeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.code,
                            style: AppTextStyles.h2.copyWith(fontSize: 15, color: AppColors.secondaryLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${p.discountValue} ${p.discountType == 'percent' ? '%' : 'SAR'} OFF',
                                style: TextStyle(color: activeColor, fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              _buildStatusBadge(p, isExpired),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                offset: const Offset(0, 40),
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    vm.setEditPromoCode(p);
                    PromoCreateSheet.show(context);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, vm, p);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.secondaryLight),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondaryLight),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_rounded, size: 16, color: AppColors.secondaryLight),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Primary quick stats - laid out with Wrap so they never overflow
          // on narrow screens.
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _buildStat('Usage', '${p.usageCount} / ${p.usageLimit}'),
              _buildStat('Min Order', 'SAR ${p.minOrderAmount.toInt()}'),
              _buildStat('Valid Till', _formatDate(p.validTo)),
            ],
          ),

          // Expandable details section
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded ? _buildExpandedDetails(p) : const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedIds.remove(p.id);
                  } else {
                    _expandedIds.add(p.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'Hide details' : 'View details',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.secondaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PromoCode p, bool isExpired) {
    final String label;
    final Color color;
    if (isExpired) {
      label = 'Expired';
      color = Colors.orange;
    } else if (p.isActive) {
      label = 'Active';
      color = Colors.green;
    } else {
      label = 'Inactive';
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildExpandedDetails(PromoCode p) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.description != null && p.description!.trim().isNotEmpty) ...[
              _buildDetailRow(Icons.notes_rounded, 'Description', p.description!),
              const SizedBox(height: 10),
            ],
            _buildDetailRow(Icons.calendar_today_rounded, 'Valid From', _formatDate(p.validFrom)),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.event_rounded, 'Valid To', _formatDate(p.validTo)),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.discount_rounded,
              'Discount Type',
              p.discountType == 'percent' ? 'Percentage' : 'Fixed Amount (SAR)',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.store_mall_directory_rounded, 'Branches', 'All branches'),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.inventory_2_rounded, 'Products', 'All products'),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.build_rounded, 'Services', 'All services'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryLight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.secondaryLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final d = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(d);
    } catch (_) {
      return isoString.split('T').first;
    }
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.secondaryLight)),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, OwnerPromoViewModel vm, PromoCode p) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${p.code}"? This action cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    vm.deletePromoCode(parentContext, p.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.secondaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}