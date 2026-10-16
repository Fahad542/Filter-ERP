import 'dart:async';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../models/cashier_active_broadcasts_model.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_shell_left_menu_rail.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import 'cashier_broadcast_view_model.dart';
import '../../../services/locker_translation_mixin.dart';

class PosCashierBroadcastView extends StatefulWidget {
  const PosCashierBroadcastView({super.key});

  @override
  State<PosCashierBroadcastView> createState() =>
      _PosCashierBroadcastViewState();
}

class _BroadcastUiData {
  const _BroadcastUiData({
    required this.isLoading,
    required this.errorMessage,
    required this.list,
    required this.windowSeconds,
    required this.activeCountMeta,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<CashierActiveBroadcastItem> list;
  final int windowSeconds;
  final int activeCountMeta;
}

class _PosCashierBroadcastViewState extends State<PosCashierBroadcastView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: PosScreenAppBar(
        title: l10n.posBroadcastTitle,
        showBackButton: false,
        showHamburger: false,
      ),
      body: ExcludeSemantics(
        child: wrapPosShellRailBody(
          context,
          Selector<CashierBroadcastViewModel, _BroadcastUiData>(
            selector: (_, vm) => _BroadcastUiData(
              isLoading: vm.isLoading,
              errorMessage: vm.errorMessage,
              list: vm.broadcasts,
              windowSeconds: vm.windowSeconds,
              activeCountMeta: vm.activeCountMeta,
            ),
            shouldRebuild: (prev, next) =>
                prev.isLoading != next.isLoading ||
                prev.errorMessage != next.errorMessage ||
                prev.list.length != next.list.length ||
                prev.windowSeconds != next.windowSeconds ||
                prev.activeCountMeta != next.activeCountMeta ||
                !identical(prev.list, next.list),
            builder: (context, data, _) {
              return _BroadcastScrollContent(
                l10n: l10n,
                data: data,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BroadcastScrollContent extends StatelessWidget {
  const _BroadcastScrollContent({
    required this.l10n,
    required this.data,
  });

  final AppLocalizations l10n;
  final _BroadcastUiData data;

  String _windowLabel(BuildContext context, int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final lang = Localizations.localeOf(context).languageCode;
    final time = AppTranslationService.localizeDigitsForLanguage(
      '$m:${s.toString().padLeft(2, '0')}',
      lang,
    );
    final secondsText = AppTranslationService.localizeDigitsForLanguage(
      s.toString().padLeft(2, '0'),
      lang,
    );
    return l10n.posBroadcastWindow(time, secondsText);
  }

  @override
  Widget build(BuildContext context) {
    final list = data.list;
    final vm = context.read<CashierBroadcastViewModel>();
    final displayCount = data.activeCountMeta > 0
        ? data.activeCountMeta
        : list.length;
    final windowLabel = _windowLabel(context, data.windowSeconds);
    final bodyMinHeight = (MediaQuery.sizeOf(context).height * 0.55).clamp(320.0, 900.0);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondaryLight,
                    AppColors.secondaryLight.withValues(alpha: 0.92),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryLight.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.podcasts_rounded,
                      color: AppColors.secondaryLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.posBroadcastHeading,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          list.isEmpty && !data.isLoading
                              ? l10n.posBroadcastNoActive
                              : l10n.posBroadcastCountActive(
                                  displayCount,
                                  windowLabel,
                                ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
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
        if (data.isLoading && list.isEmpty)
          _BroadcastShimmerGridSliver()
        else if (data.errorMessage != null && list.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: bodyMinHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => vm.fetchActive(),
                        child: Text(l10n.posBroadcastRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (list.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: bodyMinHeight,
              child: Center(
                child: Text(
                  l10n.posBroadcastNoActive,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
        else
          _BroadcastGridSliver(
            items: list,
            vm: vm,
            windowLabel: windowLabel,
            l10n: l10n,
          ),
      ],
    );
  }
}

class _BroadcastGridSliver extends StatelessWidget {
  const _BroadcastGridSliver({
    required this.items,
    required this.vm,
    required this.windowLabel,
    required this.l10n,
  });

  final List<CashierActiveBroadcastItem> items;
  final CashierBroadcastViewModel vm;
  final String windowLabel;
  final AppLocalizations l10n;

  double _aspectFor(double width) {
    const crossGap = 10.0;
    final cellW = (width - crossGap) / 2;
    const targetCellHeight = 118.0;
    return (cellW / targetCellHeight).clamp(2.0, 4.5);
  }

  @override
  Widget build(BuildContext context) {
    final rail =
        PosShellRailLayout.hasLeftMenuRail(context)
            ? kPosShellLeftMenuRailTotalWidth
            : 0.0;
    final innerWidth = MediaQuery.sizeOf(context).width - rail - 32;
    final aspect = _aspectFor(innerWidth);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: aspect,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _BroadcastCard(
              key: ValueKey(items[index].broadcastId),
              item: items[index],
              vm: vm,
              windowLabel: windowLabel,
              l10n: l10n,
            );
          },
          childCount: items.length,
          addSemanticIndexes: false,
        ),
      ),
    );
  }
}


/// Paint-only progress — value changes repaint without sliver relayout.
class _BroadcastProgressBar extends StatelessWidget {
  const _BroadcastProgressBar({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 7,
        width: double.infinity,
        child: CustomPaint(
          painter: _BroadcastProgressPainter(
            value: value,
            fillColor: color,
            trackColor: const Color(0xFFE8ECF3),
          ),
        ),
      ),
    );
  }
}

class _BroadcastProgressPainter extends CustomPainter {
  _BroadcastProgressPainter({
    required this.value,
    required this.fillColor,
    required this.trackColor,
  });

  final double value;
  final Color fillColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, track);

    final fillW = size.width * value.clamp(0.0, 1.0);
    if (fillW > 0) {
      final fill = Paint()..color = fillColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, fillW, size.height), fill);
    }
  }

  @override
  bool shouldRepaint(_BroadcastProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.trackColor != trackColor;
}

class _BroadcastCard extends StatefulWidget {
  const _BroadcastCard({
    super.key,
    required this.item,
    required this.vm,
    required this.windowLabel,
    required this.l10n,
  });

  final CashierActiveBroadcastItem item;
  final CashierBroadcastViewModel vm;
  final String windowLabel;
  final AppLocalizations l10n;

  @override
  State<_BroadcastCard> createState() => _BroadcastCardState();
}

class _BroadcastCardState extends State<_BroadcastCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(BuildContext context, Duration d) {
    final lang = Localizations.localeOf(context).languageCode;
    if (d.isNegative) {
      return AppTranslationService.localizeDigitsForLanguage('00:00', lang);
    }
    final m = d.inMinutes.remainder(100).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return AppTranslationService.localizeDigitsForLanguage('$m:$s', lang);
  }

  String _typeBadge(String rawType) {
    final type = rawType.trim().toLowerCase();
    if (type == 'on_call') return widget.l10n.posBroadcastTypeOnCall;
    if (type == 'workshop') return widget.l10n.posBroadcastTypeWorkshop;
    if (type.isEmpty) return '';
    return rawType;
  }

  String _cardSubtitle(CashierActiveBroadcastItem item) {
    final s = item.subtitle.trim();
    if (s.isNotEmpty) return s;
    final parts = <String>[];
    final customer = item.customerName?.trim();
    if (customer != null && customer.isNotEmpty) parts.add(customer);
    final label = item.vehicleLabel?.trim();
    final plate = item.vehiclePlate?.trim();
    if (label != null && label.isNotEmpty) {
      parts.add(label);
    } else if (plate != null && plate.isNotEmpty) {
      parts.add(plate);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final vm = widget.vm;
    final l10n = widget.l10n;
    final left = vm.remainingFor(item);
    final expired = vm.isExpired(item);
    final urgent = vm.showSoon(item);
    final progress = vm.progressRemaining(item);
    final rawType = item.broadcastType.trim().toLowerCase();
    final badge = rawType.isEmpty ? null : _typeBadge(rawType);

    return RepaintBoundary(
      child: Material(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: expired
                  ? Colors.grey.shade200
                  : urgent
                      ? const Color(0xFFFFB74D).withValues(alpha: 0.55)
                      : const Color(0xFFE8ECF3),
              width: urgent ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: expired
                          ? Colors.grey.shade100
                          : AppColors.primaryLight.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 17,
                      color: expired
                          ? Colors.grey.shade400
                          : AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: expired
                                ? Colors.grey.shade500
                                : const Color(0xFF1A1D26),
                            height: 1.15,
                          ),
                        ),
                        if (_cardSubtitle(item).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _cardSubtitle(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.grey.shade600,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: expired
                            ? Colors.grey.shade100
                            : AppColors.secondaryLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: expired
                              ? Colors.grey.shade500
                              : AppColors.secondaryLight,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _BroadcastProgressBar(
                value: expired ? 0 : progress.clamp(0.0, 1.0),
                color: expired
                    ? Colors.grey.shade300
                    : urgent
                        ? const Color(0xFFFFB74D)
                        : AppColors.secondaryLight,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: expired
                          ? Colors.grey.shade100
                          : urgent
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      expired
                          ? l10n.posBroadcastLabelExpired
                          : urgent
                              ? l10n.posBroadcastLabelSoon
                              : l10n.posBroadcastLabelRemaining,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: expired
                            ? Colors.grey.shade600
                            : urgent
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatCountdown(context, left),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: expired
                          ? Colors.grey.shade500
                          : urgent
                              ? const Color(0xFFE65100)
                              : AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                expired
                    ? l10n.posBroadcastLabelExpired
                    : widget.windowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer as [SliverGrid] — avoids [SliverFillRemaining] null geometry during paint.
class _BroadcastShimmerGridSliver extends StatelessWidget {
  const _BroadcastShimmerGridSliver();

  @override
  Widget build(BuildContext context) {
    final rail =
        PosShellRailLayout.hasLeftMenuRail(context)
            ? kPosShellLeftMenuRailTotalWidth
            : 0.0;
    final innerWidth = MediaQuery.sizeOf(context).width - rail - 32;
    const crossGap = 10.0;
    final cellW = (innerWidth - crossGap) / 2;
    const targetCellHeight = 118.0;
    final aspect = (cellW / targetCellHeight).clamp(2.0, 4.5);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: aspect,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => const _BroadcastCardShimmer(),
          childCount: 6,
        ),
      ),
    );
  }
}

class _BroadcastCardShimmer extends StatelessWidget {
  const _BroadcastCardShimmer();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: const PosShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PosShimmerBox(width: 32, height: 32, radius: 9),
                  SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosShimmerBox(
                          width: double.infinity,
                          height: 11,
                          radius: 6,
                        ),
                        SizedBox(height: 6),
                        PosShimmerBox(width: 120, height: 10, radius: 5),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  PosShimmerBox(width: 42, height: 14, radius: 8),
                ],
              ),
              SizedBox(height: 10),
              PosShimmerBox(width: double.infinity, height: 7, radius: 4),
              SizedBox(height: 8),
              Row(
                children: [
                  PosShimmerBox(width: 76, height: 18, radius: 9),
                  Spacer(),
                  PosShimmerBox(width: 60, height: 18, radius: 9),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
