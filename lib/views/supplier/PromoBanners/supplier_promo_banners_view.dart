import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import 'supplier_promo_banners_view_model.dart';

class SupplierPromoBannersView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierPromoBannersView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final isLargeScreen = isDesktop || isTablet;

    return ChangeNotifierProvider(
      create: (_) => SupplierPromoBannersViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isLargeScreen ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: isDesktop
              ? null
              : PosScreenAppBar(
                  title: 'Promo Banners',
                  showHamburger: true,
                  onMenuPressed: () => Scaffold.of(context).openDrawer(),
                  showBackButton: false,
                ),
          body: Consumer<SupplierPromoBannersViewModel>(
            builder: (context, vm, _) {
              return SafeArea(
                top: isDesktop,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 32 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) ...[
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondaryLight
                                          .withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Promo Banners',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () => _showComingSoon(context),
                              icon: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'Upload Banner',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.secondaryLight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primaryLight.withOpacity(
                                  0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Header Overview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryLight.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: AppColors.primaryLight,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Promotions',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${vm.filteredBanners.where((b) => b.status == 'Active').length} Banners',
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (v) => vm.searchQuery = v,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search promo banners...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.secondaryLight,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: AppColors.secondaryLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Promotional Campaigns',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (vm.loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        )
                      else if (vm.filteredBanners.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.dnd_forwardslash_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No banners found',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (isLargeScreen)
                        _buildDesktopDataTable(context, vm)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: vm.filteredBanners.length,
                          itemBuilder: (context, i) => _BannerCard(
                            banner: vm.filteredBanners[i],
                            vm: vm,
                          ),
                        ),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showComingSoon(context),
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  elevation: 4,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                  label: const Text(
                    'Upload Banner',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopDataTable(
    BuildContext context,
    SupplierPromoBannersViewModel vm,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FD)),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
              fontSize: 13,
            ),
            dataTextStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight,
              fontSize: 14,
            ),
            columnSpacing: 32,
            columns: const [
              DataColumn(label: Text('Preview')),
              DataColumn(label: Text('Impressions')),
              DataColumn(label: Text('Target Branches')),
              DataColumn(label: Text('Validity Period')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: vm.filteredBanners.map((b) {
              final isActive = b.status == 'Active';
              final statusColor = isActive
                  ? AppColors.primaryLight
                  : Colors.grey.shade500;

              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      width: 70,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${b.impressions}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Text(b.targetBranches),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      b.validity,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? statusColor.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.status,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.secondaryLight
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: AppColors.secondaryLight,
                          ),
                          onPressed: () => _showComingSoon(context),
                          tooltip: 'Edit Banner',
                        ),
                        IconButton(
                          icon: Icon(
                            isActive
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            size: 24,
                            color: isActive
                                ? AppColors.primaryLight
                                : Colors.grey,
                          ),
                          onPressed: () => vm.deactivateBanner(b.id),
                          tooltip: isActive ? 'Deactivate' : 'Activate',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Feature coming soon!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBannerItem banner;
  final SupplierPromoBannersViewModel vm;
  const _BannerCard({required this.banner, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isActive = banner.status == 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Area
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.image_rounded, size: 48, color: Colors.grey),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryLight.withOpacity(0.9)
                          : Colors.grey.shade200.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      banner.status,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isActive
                            ? AppColors.secondaryLight
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Impressions',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${banner.impressions}',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Validity Period',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner.validity,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          banner.targetBranches,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coming soon'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryLight,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => vm.deactivateBanner(banner.id),
                        icon: Icon(
                          isActive
                              ? Icons.toggle_off_rounded
                              : Icons.toggle_on_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isActive ? 'Deactivate' : 'Activate',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? Colors.grey.shade100
                              : AppColors.primaryLight,
                          foregroundColor: AppColors.secondaryLight,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
