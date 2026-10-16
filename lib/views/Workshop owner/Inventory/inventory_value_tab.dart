import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import 'inventory_management_view.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  INVENTORY VALUE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class InventoryValueTab extends StatelessWidget {
  final InventoryV2ViewModel vm;
  const InventoryValueTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branchName = vm.branches.firstWhere(
          (b) => b['id'] == vm.selectedBranchId,
      orElse: () => {'name': l10n.ownerCommonAllBranches},
    )['name']!;

    final products = List<InvProduct>.from(vm.filteredProducts)
      ..sort((a, b) => (b.currentStock * b.purchasePrice)
          .compareTo(a.currentStock * a.purchasePrice));

    final withStock = products.where((p) => p.currentStock > 0).length;
    final withValue =
        products.where((p) => p.currentStock * p.purchasePrice > 0).length;
    final total = products.fold(
        0.0, (sum, p) => sum + p.currentStock * p.purchasePrice);
    final currency = l10n.ownerCurrencySar;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Formula banner ────────────────────────────────────────
              InfoBanner(
                icon: Icons.functions_rounded,
                color: AppColors.secondaryLight,
                bg: Colors.grey.shade50,
                border: Colors.grey.shade200,
                text: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: 12,
                        height: 1.5),
                    children: [
                      TextSpan(
                          text: l10n.ownerInventoryFormulaLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: l10n.ownerInventoryFormulaBody(currency)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Scope banner ──────────────────────────────────────────
              InfoBanner(
                icon: Icons.store_outlined,
                color: AppColors.secondaryLight,
                bg: Colors.grey.shade50,
                border: Colors.grey.shade200,
                text: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: 12,
                        height: 1.5),
                    children: [
                      TextSpan(
                          text: l10n.ownerInventoryScopeLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: l10n.ownerInventoryScopeBody(branchName)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),



              // ── Product value cards ───────────────────────────────────
              if (products.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(l10n.ownerInventoryNoProducts,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ),
                )
              else
                ...products.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final p = entry.value;
                  final lineVal = p.currentStock * p.purchasePrice;
                  final pct = total > 0 ? lineVal / total : 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row + line value
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rank badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: rank <= 3
                                    ? AppColors.primaryLight
                                    .withValues(alpha: 0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                ownerLocalizeDigits(context, '#$rank'),
                                style: TextStyle(
                                  color: rank <= 3
                                      ? AppColors.secondaryLight
                                      : Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  LocalizedApiText(
                                    p.name,
                                    style: const TextStyle(
                                      color: AppColors.secondaryLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  LocalizedApiText(
                                    '${p.sku}  ·  ${p.department}',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Line value
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  ownerFormatMoney(context, lineVal.round(), decimals: 0),
                                  style: const TextStyle(
                                    color: Color(0xFF27AE60),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  l10n.ownerInventoryPctOfTotal(
                                    ownerLocalizeDigits(
                                      context,
                                      (pct * 100).toStringAsFixed(1),
                                    ),
                                  ),
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rank <= 3
                                  ? AppColors.primaryLight
                                  : Colors.green.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Stats row
                        Row(
                          children: [
                            _ValStatChip(
                              label: 'Stock',
                              value: '${p.currentStock} ${p.unit}',
                            ),
                            const SizedBox(width: 8),
                            _ValStatChip(
                              label: 'Purchase price',
                              value:
                              ownerFormatMoney(context, p.purchasePrice),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ValStatChip extends StatelessWidget {
  final String label;
  final String value;
  const _ValStatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 1),
          Text(value,
              style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
// end of file