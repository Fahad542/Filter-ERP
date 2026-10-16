import 'package:flutter/material.dart';

import '../../../widgets/pos_shimmer.dart';
import 'owner_ui_constants.dart';

/// White card row skeleton — matches owner list / catalog cards.
class OwnerCardRowShimmer extends StatelessWidget {
  const OwnerCardRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosShimmerBox(width: 44, height: 44, radius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(
                    width: double.infinity,
                    height: 14,
                    radius: 6,
                  ),
                  SizedBox(height: 8),
                  PosShimmerBox(
                    width: double.infinity,
                    height: 12,
                    radius: 6,
                  ),
                  SizedBox(height: 6),
                  PosShimmerBox(width: 140, height: 12, radius: 6),
                ],
              ),
            ),
            SizedBox(width: 8),
            PosShimmerBox(width: 40, height: 22, radius: 11),
          ],
        ),
      ),
    );
  }
}

/// KPI grid skeleton for owner dashboards and summary screens.
class OwnerKpiGridShimmer extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool showFeatured;

  const OwnerKpiGridShimmer({
    super.key,
    this.count = 4,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.32,
    this.showFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFeatured) ...[
          const PosShimmerBox(
            width: double.infinity,
            height: 72,
            radius: 16,
          ),
          const SizedBox(height: 8),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 8,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (_, __) => const PosShimmerBox(
            width: double.infinity,
            height: double.infinity,
            radius: 14,
          ),
        ),
      ],
    );
  }
}

/// Section card skeleton with header + stacked rows.
class OwnerSectionCardShimmer extends StatelessWidget {
  final int rowCount;

  const OwnerSectionCardShimmer({super.key, this.rowCount = 2});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                PosShimmerLine(width: 120, height: 14, radius: 6),
                SizedBox(width: 8),
                PosShimmerBox(width: 52, height: 18, radius: 10),
                Spacer(),
                PosShimmerLine(width: 48, height: 12, radius: 6),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(
              rowCount,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: i == rowCount - 1 ? 0 : 12),
                child: const Row(
                  children: [
                    PosShimmerBox(width: 32, height: 32, radius: 8),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PosShimmerLine(width: double.infinity, height: 12),
                          SizedBox(height: 6),
                          PosShimmerLine(width: 160, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerSearchBarShimmer extends StatelessWidget {
  const OwnerSearchBarShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const PosShimmerBox(
      width: double.infinity,
      height: 44,
      radius: 14,
    );
  }
}

class OwnerSegmentedTabsShimmer extends StatelessWidget {
  const OwnerSegmentedTabsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const PosShimmerBox(
      width: double.infinity,
      height: 40,
      radius: 12,
    );
  }
}

/// Generic owner list page skeleton.
class OwnerListPageShimmer extends StatelessWidget {
  final bool showKpi;
  final int kpiCount;
  final bool showFeaturedKpi;
  final bool showTabs;
  final bool showSearch;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const OwnerListPageShimmer({
    super.key,
    this.showKpi = false,
    this.kpiCount = 4,
    this.showFeaturedKpi = false,
    this.showTabs = false,
    this.showSearch = false,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 100),
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: ListView(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (showKpi) ...[
              OwnerKpiGridShimmer(
                count: kpiCount,
                showFeatured: showFeaturedKpi,
              ),
              const SizedBox(height: 16),
            ],
            if (showTabs) ...[
              const OwnerSegmentedTabsShimmer(),
              const SizedBox(height: 12),
            ],
            if (showSearch) ...[
              const OwnerSearchBarShimmer(),
              const SizedBox(height: 12),
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

/// Dashboard body skeleton (app bar stays real in parent).
class OwnerDashboardShimmer extends StatelessWidget {
  const OwnerDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              OwnerSectionCardShimmer(rowCount: 2),
              SizedBox(height: 20),
              OwnerKpiGridShimmer(count: 4, childAspectRatio: 1.32),
              SizedBox(height: 20),
              PosShimmerLine(width: 140, height: 14, radius: 6),
              SizedBox(height: 10),
              OwnerCardRowShimmer(),
              SizedBox(height: 10),
              OwnerCardRowShimmer(),
              SizedBox(height: 20),
              PosShimmerLine(width: 110, height: 14, radius: 6),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 88,
                      radius: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 88,
                      radius: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 88,
                      radius: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 88,
                      radius: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reports / table-style page skeleton.
class OwnerTablePageShimmer extends StatelessWidget {
  final bool showKpi;
  final bool showTabs;
  final bool showFilters;
  final int rowCount;

  const OwnerTablePageShimmer({
    super.key,
    this.showKpi = true,
    this.showTabs = true,
    this.showFilters = true,
    this.rowCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (showKpi) ...[
              const SizedBox(
                height: 82,
                child: Row(
                  children: [
                    Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        radius: 14,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        radius: 14,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        radius: 14,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: PosShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        radius: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (showTabs) ...[
              const OwnerSegmentedTabsShimmer(),
              const SizedBox(height: 12),
            ],
            if (showFilters) ...[
              const Row(
                children: [
                  Expanded(child: OwnerSearchBarShimmer()),
                  SizedBox(width: 8),
                  PosShimmerBox(width: 110, height: 44, radius: 14),
                ],
              ),
              const SizedBox(height: 12),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: List.generate(
                  rowCount,
                  (i) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            PosShimmerLine(
                              width: i.isEven ? 120.0 : 96.0,
                              height: 12,
                            ),
                            const Spacer(),
                            PosShimmerLine(width: 72, height: 12),
                          ],
                        ),
                      ),
                      if (i < rowCount - 1)
                        Divider(
                          height: 0,
                          thickness: 0.6,
                          color: Colors.grey.withValues(alpha: 0.12),
                        ),
                    ],
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

/// Master catalog grid skeleton.
class OwnerGridCardsShimmer extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const OwnerGridCardsShimmer({
    super.key,
    this.count = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, __) => DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(width: 44, height: 44, radius: 12),
                  SizedBox(height: 12),
                  PosShimmerLine(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  PosShimmerLine(width: 80, height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings / form-style page skeleton.
class OwnerFormPageShimmer extends StatelessWidget {
  final int fieldCount;

  const OwnerFormPageShimmer({super.key, this.fieldCount = 6});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...List.generate(
              fieldCount,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PosShimmerLine(width: 90 + (i * 12.0), height: 11),
                    const SizedBox(height: 8),
                    PosShimmerBox(
                      width: double.infinity,
                      height: i == fieldCount - 1 ? 88 : 44,
                      radius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small inline pagination / load-more skeleton.
class OwnerPaginationShimmer extends StatelessWidget {
  const OwnerPaginationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: PosShimmer(child: OwnerCardRowShimmer()),
    );
  }
}
