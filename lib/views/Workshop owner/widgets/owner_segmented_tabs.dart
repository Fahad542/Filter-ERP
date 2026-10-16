import 'package:flutter/material.dart';

import '../../../widgets/pos_segmented_list_tabs.dart';
import 'owner_ui_constants.dart';

/// POS-style segmented tabs wired to a [TabController] (for [TabBarView] screens).
class OwnerSegmentedTabs extends StatelessWidget {
  const OwnerSegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.layout = PosSegmentedTabLayout.scrollable,
    this.padding,
    this.counts,
  });

  final TabController controller;
  final List<String> tabs;
  final PosSegmentedTabLayout layout;
  final EdgeInsetsGeometry? padding;
  final List<int?>? counts;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final ids = List.generate(tabs.length, (i) => '$i');
        return PosSegmentedListTabs(
          tabs: [
            for (var i = 0; i < tabs.length; i++)
              PosSegmentedTab(
                id: ids[i],
                label: tabs[i],
                count: counts != null && i < counts!.length ? counts![i] : null,
              ),
          ],
          selectedId: ids[controller.index.clamp(0, tabs.length - 1)],
          onSelected: (id) {
            final index = int.tryParse(id);
            if (index == null || index == controller.index) return;
            controller.animateTo(index);
          },
          layout: layout,
          padding: padding ??
              const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          outerRadius: OwnerUi.segmentedTabOuterRadius,
          innerRadius: OwnerUi.segmentedTabInnerRadius,
          tabGap: OwnerUi.segmentedTabGap,
          containerInnerPadding: OwnerUi.segmentedTabContainerPad,
          tabVerticalPadding: OwnerUi.segmentedTabVerticalPad(isTablet),
          tabHorizontalPadding: OwnerUi.segmentedTabHorizontalPad(isTablet),
          fontSize: OwnerUi.segmentedTabFontSize(isTablet),
        );
      },
    );
  }
}
