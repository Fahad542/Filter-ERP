import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import 'technician_view_model.dart';
import '../Home Screen/pos_view_model.dart';
import '../../../models/pos_technician_model.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';

class PosTechnicianView extends StatefulWidget {
  final bool showBackButton;
  final bool showHamburger;

  const PosTechnicianView({
    super.key,
    this.showBackButton = false,
    this.showHamburger = true,
  });

  @override
  State<PosTechnicianView> createState() => _PosTechnicianViewState();
}

class _PosTechnicianViewState extends State<PosTechnicianView> {
  /// Internal key stays English for switch-case logic safety.
  String _presenceTab = 'All';

  static String _dutyModeResolved(PosTechnician t) {
    final dm = t.dutyMode?.toLowerCase().trim() ?? '';
    if (dm.isNotEmpty) return dm;
    if (t.workshopDuty) return 'workshop';
    if (t.onCallDuty) return 'on_call';
    return 'inactive';
  }

  /// Maps internal key → localised display label.
  String _tabLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'All':        return l10n.posTechViewTabAll;
      case 'Offline':    return l10n.posTechViewTabOffline;
      case 'Online':     return l10n.posTechViewTabOnline;
      case 'On call':    return l10n.empTechTypeOnCall;
      case 'Not available': return l10n.posTechViewNoOffline;
      default:           return key;
    }
  }

  static const _presenceTabKeys = [
    'All',
    'Offline',
    'Online',
    'On call',
    'Not available',
  ];

  Widget _buildPresenceTabsBar(
    AppLocalizations l10n,
    double horizontalPadding,
    List<PosTechnician> searched,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 0),
      child: PosSegmentedListTabs(
        layout: PosSegmentedTabLayout.expanded,
        containerColor: Colors.white,
        unselectedTabColor: Colors.white,
        tabVerticalPadding: isTablet ? 9 : 8,
        tabs: [
        for (final key in _presenceTabKeys)
          PosSegmentedTab(
            id: key,
            label: _tabLabel(l10n, key),
            count: _filterByPresenceKey(searched, key).length,
          ),
      ],
      selectedId: _presenceTab,
      onSelected: (id) {
        if (_presenceTab != id) setState(() => _presenceTab = id);
      },
      ),
    );
  }

  List<PosTechnician> _filterByPresenceKey(
    List<PosTechnician> searched,
    String tabKey,
  ) {
    bool presenceOnline(PosTechnician t) => t.isOnline;

    switch (tabKey) {
      case 'All':
        return searched;
      case 'Offline':
        return searched.where((t) => !presenceOnline(t)).toList();
      case 'Online':
        return searched
            .where((t) =>
                presenceOnline(t) && _dutyModeResolved(t) == 'workshop')
            .toList();
      case 'On call':
        return searched
            .where(
                (t) => presenceOnline(t) && _dutyModeResolved(t) == 'on_call')
            .toList();
      case 'Not available':
        return searched
            .where(
                (t) => presenceOnline(t) && _dutyModeResolved(t) == 'inactive')
            .toList();
      default:
        return searched;
    }
  }

  List<PosTechnician> _filterByPresence(List<PosTechnician> searched) =>
      _filterByPresenceKey(searched, _presenceTab);

  String _emptyFilterMessage(AppLocalizations l10n) {
    switch (_presenceTab) {
      case 'Online':       return l10n.posTechViewNoOnline;
      case 'Offline':      return l10n.posTechViewNoOffline;
      default:             return l10n.posTechViewNoTechnicians;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: PosScreenAppBar(
        title: l10n.posTechViewTitle,
        showBackButton: widget.showBackButton,
        showHamburger: widget.showHamburger,
        onMenuPressed: widget.showHamburger ? PosShellScaffoldRegistry.openDrawer : null,
      ),
      body: wrapPosShellRailBody(
        context,
        RefreshIndicator(
          onRefresh: () => context.read<TechnicianViewModel>().fetchTechnicians(),
          color: AppColors.secondaryLight,
          backgroundColor: Colors.white,
          child: Consumer<TechnicianViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading && vm.technicians.isEmpty) {
                return _TechnicianViewListShimmer(isTablet: isTablet);
              }

              if (vm.errorMessage != null && vm.technicians.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.posTechViewErrorPrefix(vm.errorMessage!)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: vm.fetchTechnicians,
                            child: Text(l10n.posTechViewErrorRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final searched = vm.technicians;
              final technicians = _filterByPresence(searched);
              final horizontalPadding = isTablet ? 20.0 : 12.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                    child: _buildSearchSection(context, l10n),
                  ),
                  const SizedBox(height: 8),
                  _buildPresenceTabsBar(l10n, horizontalPadding, searched, isTablet),
                  const SizedBox(height: 8),
                  Expanded(
                    child: searched.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                            child: SizedBox(
                              height: 280,
                              child: Center(child: Text(l10n.posTechViewNoTechnicians)),
                            ),
                          )
                        : technicians.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                                child: SizedBox(
                                  height: 260,
                                  child: Center(
                                    child: Text(
                                      _emptyFilterMessage(l10n),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 16),
                                child: _buildTechnicianGrid(context, vm, technicians, isTablet),
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: PosWorkshopSearchBar(
            hintText: l10n.posTechViewSearchHint,
            onChanged: (val) => context.read<TechnicianViewModel>().setSearchQuery(val),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianGrid(
    BuildContext context,
    TechnicianViewModel vm,
    List<PosTechnician> technicians,
    bool isTablet,
  ) {
    final orientation = MediaQuery.of(context).orientation;
    final crossAxisCount = orientation == Orientation.landscape ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: technicians.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isTablet
            ? (orientation == Orientation.landscape ? 1.30 : 1.32)
            : (orientation == Orientation.landscape ? 1.26 : 1.24),
        crossAxisSpacing: isTablet ? 12 : 8,
        mainAxisSpacing: isTablet ? 12 : 8,
      ),
      itemBuilder: (context, index) {
        final tech = technicians[index];
        return TechnicianCard(
          tech: tech,
          compact: !isTablet && orientation == Orientation.portrait,
          showPresenceToggle: true,
          presenceBusy: vm.isPresenceToggleBusy(tech.id),
          onPresenceChanged: (online) => vm.setTechnicianPresence(context, tech.id, online),
          showDutyToggles: true,
          dutyBusy: vm.isDutyToggleBusy(tech.id),
          onWorkshopDutyChanged: (v) => vm.setTechnicianWorkshopDuty(context, tech, v),
          onOnCallDutyChanged: (v) => vm.setTechnicianOnCallDuty(context, tech, v),
        );
      },
    );
  }
}


class _TechnicianViewListShimmer extends StatelessWidget {
  const _TechnicianViewListShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isTablet ? 20.0 : 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
          child: const PosShimmer(
            child: PosShimmerBox(width: double.infinity, height: 42, radius: 12),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: const PosShimmer(
            child: PosShimmerBox(width: double.infinity, height: 44, radius: 12),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: isTablet ? 6 : 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).orientation ==
                      Orientation.landscape
                  ? 4
                  : 2,
              childAspectRatio: isTablet ? 1.30 : 1.26,
              crossAxisSpacing: 12,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, __) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const PosShimmer(
                child: Row(
                  children: [
                    PosShimmerCircle(size: 44),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PosShimmerLine(width: 150, height: 14),
                          SizedBox(height: 10),
                          PosShimmerLine(width: 110, height: 11),
                          SizedBox(height: 12),
                          PosShimmerBox(width: 90, height: 24, radius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
