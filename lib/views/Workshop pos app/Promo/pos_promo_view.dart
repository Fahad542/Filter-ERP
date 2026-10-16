import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import 'promo_view_model.dart';
import 'promo_promotion_card.dart';

class PosPromoView extends StatefulWidget {
  const PosPromoView({super.key});

  @override
  State<PosPromoView> createState() => _PosPromoViewState();
}

class _PosPromoViewState extends State<PosPromoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final promoVm = context.read<PromoViewModel>();
      promoVm.clearPromoError();
      promoVm.fetchAvailablePromos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final promoVm = Provider.of<PromoViewModel>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      resizeToAvoidBottomInset: false,
      appBar: PosScreenAppBar(
        title: AppLocalizations.of(context)!.posPromoTitle,
        showBackButton: false,
        showHamburger: true,
        onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
      ),
      body: wrapPosShellRailBody(
        context,
        promoVm.isLoadingPromos && promoVm.availablePromotions.isEmpty
            ? _PromoScreenShimmer(isTablet: isTablet)
            : promoVm.isLoadingPromos
                ? _PromoPromotionsShimmer(isTablet: isTablet)
                : promoVm.availablePromotions.isEmpty
                    ? _buildEmptyState(context)
                    : _buildPromotionCatalog(
                        promoVm.availablePromotions,
                        isTablet,
                        MediaQuery.of(context).orientation,
                      ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.posPromoNoPromotionsAvailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCatalog(
    List<AvailablePromotion> promos,
    bool isTablet,
    Orientation orientation,
  ) {
    final crossAxisCount = isTablet
        ? (orientation == Orientation.landscape ? 3 : 2)
        : 1;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 14 : 12,
        isTablet ? 12 : 10,
        isTablet ? 14 : 12,
        isTablet ? 16 : 14,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: promoPromotionCardExtent(isTablet: isTablet),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: promos.length,
      itemBuilder: (context, index) =>
          PromoPromotionCard(promo: promos[index]),
    );
  }
}

class _PromoCardShimmer extends StatelessWidget {
  const _PromoCardShimmer();

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return SizedBox(
      height: promoPromotionCardExtent(isTablet: isTablet),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: PosShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PosShimmerLine(width: double.infinity, height: 14),
                            SizedBox(height: 8),
                            PosShimmerLine(width: 140, height: 10),
                            SizedBox(height: 6),
                            PosShimmerLine(width: 100, height: 10),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      PosShimmerBox(width: 72, height: 28, radius: 10),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: 30,
                        radius: 7,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: 30,
                        radius: 7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoScreenShimmer extends StatelessWidget {
  const _PromoScreenShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return _PromoPromotionsShimmer(isTablet: isTablet);
  }
}

class _PromoPromotionsShimmer extends StatelessWidget {
  const _PromoPromotionsShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final count = isTablet ? 6 : 3;
    final crossAxisCount = isTablet ? 3 : 1;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 14 : 12,
        isTablet ? 12 : 10,
        isTablet ? 14 : 12,
        isTablet ? 16 : 14,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: promoPromotionCardExtent(isTablet: isTablet),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const _PromoCardShimmer(),
    );
  }
}
