import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../Home Screen/pos_view_model.dart';
import '../../../models/pos_product_model.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import '../Promo/pos_promo_view.dart';
import '../../../services/LocalizedApiText.dart';

class PosProductsView extends StatefulWidget {
  final List<String>? preSelectedProducts;
  final String? departmentName;

  const PosProductsView({
    super.key,
    this.preSelectedProducts,
    this.departmentName,
  });

  @override
  State<PosProductsView> createState() => _PosProductsViewState();
}

class _PosProductsViewState extends State<PosProductsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<PosViewModel>();
      await vm.fetchProducts();

      if (widget.departmentName != null && vm.uniqueCategories.contains(widget.departmentName)) {
        vm.setCategory(widget.departmentName!);
      } else {
        vm.setCategory('All');
      }

      if (widget.preSelectedProducts != null && widget.preSelectedProducts!.isNotEmpty) {
        vm.clearCart();
        final allProducts = vm.products;
        for (final productId in widget.preSelectedProducts!) {
          try {
            final product = allProducts.firstWhere((p) => p.id == productId);
            vm.addToCart(product);
          } catch (_) {
             // Ignoring since product ID might not exist
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 900;
    final isHeaderTablet = screenWidth > 600;
    final vm = context.watch<PosViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PosAppBar(
        userName: vm.cashierName,
        infoTitle: vm.workshopName,
        infoBranch: '${AppLocalizations.of(context)!.posProductsBranchPrefix} ${vm.branchName}',
        infoTime: DateFormat('dd MMM yyyy · hh:mm a').format(DateTime.now()),
        showDrawer: false,
        showGlobalLeft: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PosViewModel>().fetchProducts(),
        color: AppColors.secondaryLight,
        backgroundColor: Colors.white,
        child: Consumer<PosViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.products.isEmpty) {
              return _ProductsLoadingShimmer(isTablet: isTablet);
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                if (isTablet) {
                  return _buildTabletLayout(context);
                } else {
                  return _buildMobileLayout(context);
                }
              },
            );
          },
        ),
      ),
    );
  }

  // ── Tablet Layout (Full Width) ──
  Widget _buildTabletLayout(BuildContext context) {
    return _buildProductsSection(context, isTablet: true);
  }

  // ── Mobile Layout (Full Width) ──
  Widget _buildMobileLayout(BuildContext context) {
    return _buildProductsSection(context, isTablet: false);
  }

  // ── Shared Products Section ──
  Widget _buildProductsSection(BuildContext context, {required bool isTablet}) {
    return Column(
      children: [
        // Header (Search + Category Chips)
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBarWidget(),
              SizedBox(height: 16),
              CategorySelector(),
            ],
          ),
        ),
        // Grid of Products
        Expanded(
          child: Consumer<PosViewModel>(
            builder: (context, vm, child) {
              if (vm.errorMessage != null && vm.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.posProductsFailedLoadProducts,
                        style: AppTextStyles.h2.copyWith(color: AppColors.secondaryLight),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => vm.fetchProducts(),
                        child: Text(AppLocalizations.of(context)!.posCommonRetry),
                      ),
                    ],
                  ),
                );
              }

              final products = vm.products;
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.posProductNoProductsFound,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 1,
                  childAspectRatio: isTablet
                      ? 3.5
                      : (MediaQuery.of(context).size.width > 600 ? 5.0 : 2.5),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return
                  ProductCard(product: products[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}



class _ProductsLoadingShimmer extends StatelessWidget {
  const _ProductsLoadingShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: const PosShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosShimmerBox(width: double.infinity, height: 44, radius: 14),
                SizedBox(height: 16),
                Row(
                  children: [
                    PosShimmerBox(width: 82, height: 34, radius: 12),
                    SizedBox(width: 10),
                    PosShimmerBox(width: 96, height: 34, radius: 12),
                    SizedBox(width: 10),
                    PosShimmerBox(width: 74, height: 34, radius: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 2 : 1,
              childAspectRatio: isTablet ? 3.5 : 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: isTablet ? 8 : 5,
            itemBuilder: (context, index) => const _ProductListSkeletonCard(),
          ),
        ),
      ],
    );
  }
}

class _ProductListSkeletonCard extends StatelessWidget {
  const _ProductListSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: const PosShimmer(
        child: Row(
          children: [
            PosShimmerCircle(size: 46),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerLine(width: double.infinity, height: 14),
                  SizedBox(height: 10),
                  PosShimmerLine(width: 140, height: 12),
                ],
              ),
            ),
            SizedBox(width: 12),
            PosShimmerBox(width: 74, height: 34, radius: 12),
          ],
        ),
      ),
    );
  }
}
