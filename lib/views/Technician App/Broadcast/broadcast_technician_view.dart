import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/technician_broadcast_model.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../widgets/tech_app_bar_actions.dart';
import '../technician_view_model.dart';

/// Lists cashier-triggered broadcasts from GET /technician/broadcasts with Accept / Reject.
class BroadcastTechnicianView extends StatefulWidget {
  const BroadcastTechnicianView({super.key, this.usePosShellRail = false});

  final bool usePosShellRail;

  @override
  State<BroadcastTechnicianView> createState() => _BroadcastTechnicianViewState();
}

class _BroadcastTechnicianViewState extends State<BroadcastTechnicianView> {
  TechAppViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm = context.read<TechAppViewModel>();
      _vm!.setHideBroadcastOverlay(true);
      _vm!.fetchBroadcasts();
    });
  }

  @override
  void dispose() {
    _vm?.setHideBroadcastOverlay(false);
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00';
    final m = d.inMinutes.remainder(100).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _windowLabel(AppLocalizations l10n, int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return l10n.techBroadcastWindow(m.toString(), s.toString().padLeft(2, '0'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<TechAppViewModel>();
    final list = vm.broadcasts;
    final window = vm.broadcastWindowSeconds;
    final displayCount =
        vm.broadcastActiveCountMeta > 0 ? vm.broadcastActiveCountMeta : list.length;

    final scroll = RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.fetchBroadcasts(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondaryLight,
                      AppColors.secondaryLight.withOpacity(0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryLight.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.podcasts_rounded,
                        color: AppColors.secondaryLight,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.techBroadcastListTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            list.isEmpty
                                ? l10n.techBroadcastNoActive
                                : l10n.techBroadcastCountActive(
                                    '$displayCount',
                                    _windowLabel(l10n, window),
                                  ),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.techBroadcastNoActive,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.crossAxisExtent >= 560;
                  if (!wide) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TechnicianBroadcastCard(
                              broadcast: list[index],
                              vm: vm,
                              windowLabel: _windowLabel(l10n, window),
                              formatCountdown: _formatCountdown,
                            ),
                          );
                        },
                        childCount: list.length,
                      ),
                    );
                  }
                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      // Room for Soon chip + 2-line subtitle + progress + Accept/Reject.
                      mainAxisExtent: 348,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _TechnicianBroadcastCard(
                          broadcast: list[index],
                          vm: vm,
                          windowLabel: _windowLabel(l10n, window),
                          formatCountdown: _formatCountdown,
                        );
                      },
                      childCount: list.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Center(
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryLight.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_rounded, size: 22, color: Colors.white),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          l10n.techBroadcastLabel,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: techAppBarTrailingActions(context),
      ),
      body: widget.usePosShellRail ? wrapPosShellRailBody(context, scroll) : scroll,
    );
  }
}

class _TechnicianBroadcastCard extends StatelessWidget {
  const _TechnicianBroadcastCard({
    required this.broadcast,
    required this.vm,
    required this.windowLabel,
    required this.formatCountdown,
  });

  final TechBroadcast broadcast;
  final TechAppViewModel vm;
  final String windowLabel;
  final String Function(Duration) formatCountdown;

  @override
  Widget build(BuildContext context) {
    final b = broadcast;
    final left = vm.remainingForBroadcast(b);
    final expired = vm.broadcastExpired(b);
    final urgent = vm.broadcastShowSoon(b);
    final progress = vm.broadcastProgress(b);
    final acceptBusy = vm.isBroadcastAcceptBusy(b.jobId);
    final rejectBusy = vm.isBroadcastRejectBusy(b.jobId);
    final anyBusy = acceptBusy || rejectBusy;
    final mode = b.broadcastMode?.toLowerCase().trim();
    final l10n = AppLocalizations.of(context)!;
    final badge = mode == null || mode.isEmpty
        ? null
        : mode == 'on_call'
            ? l10n.techBroadcastOnCall
            : mode == 'workshop'
                ? l10n.techBroadcastWorkshop
                : b.broadcastMode;

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: expired
                ? Colors.grey.shade200
                : urgent
                    ? const Color(0xFFFFB74D).withOpacity(0.55)
                    : Colors.grey.shade200,
            width: urgent && !expired ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: expired ? Colors.grey.shade300 : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      color: expired ? Colors.grey.shade600 : AppColors.secondaryLight,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                b.displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: expired ? Colors.grey.shade500 : const Color(0xFF1B1E24),
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!expired && urgent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      l10n.techBroadcastSoon,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFE65100),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                Text(
                                  formatCountdown(left),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.35,
                                    height: 1.05,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                    color: expired
                                        ? Colors.grey.shade400
                                        : urgent
                                            ? const Color(0xFFE65100)
                                            : AppColors.secondaryLight,
                                  ),
                                ),
                                Text(
                                  expired
                                      ? l10n.techBroadcastClosed
                                      : l10n.techBroadcastRemaining,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (badge != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (b.displaySubtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            b.displaySubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: expired ? 0 : progress,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                  color: expired
                      ? Colors.grey.shade300
                      : urgent
                          ? const Color(0xFFFF9800)
                          : AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                expired ? l10n.techBroadcastExpired : windowLabel,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!expired) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: anyBusy
                              ? null
                              : () => vm.rejectBroadcastJob(context, b.jobId),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondaryLight,
                            foregroundColor: AppColors.onSecondaryLight,
                            disabledBackgroundColor:
                                AppColors.secondaryLight.withValues(alpha: 0.45),
                            disabledForegroundColor:
                                AppColors.onSecondaryLight.withValues(alpha: 0.65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: rejectBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onSecondaryLight,
                                  ),
                                )
                              : Text(
                                  l10n.techBroadcastReject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: anyBusy
                              ? null
                              : () => vm.acceptBroadcastJob(context, b.jobId),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: acceptBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black87,
                                  ),
                                )
                              : Text(
                                  l10n.techBroadcastAccept,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
