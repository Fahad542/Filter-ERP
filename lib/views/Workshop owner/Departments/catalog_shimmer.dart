import 'package:flutter/material.dart';

import '../../../widgets/pos_shimmer.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_shimmer.dart';

/// Full-tab loading placeholder — search/filter row + catalog card skeletons.
class CatalogListLoadingShimmer extends StatelessWidget {
  final bool showSearchBar;
  final bool showDeptDropdown;
  final int itemCount;

  const CatalogListLoadingShimmer({
    super.key,
    this.showSearchBar = true,
    this.showDeptDropdown = false,
    this.itemCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (showSearchBar || showDeptDropdown) ...[
              Row(
                children: [
                  if (showSearchBar)
                    const Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: 44,
                        radius: 14,
                      ),
                    ),
                  if (showSearchBar && showDeptDropdown)
                    const SizedBox(width: 6),
                  if (showDeptDropdown)
                    const PosShimmerBox(
                      width: 88,
                      height: 44,
                      radius: 10,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ...List.generate(
              itemCount,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: OwnerCardRowShimmer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single catalog row skeleton — matches department/service/product cards.
typedef CatalogCardShimmer = OwnerCardRowShimmer;

/// Bottom-of-list pagination placeholder.
class CatalogPaginationShimmer extends StatelessWidget {
  const CatalogPaginationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const OwnerPaginationShimmer();
  }
}
