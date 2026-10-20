import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import 'notifications_view_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../AI Orders/pos_ai_order_detail_view.dart';
import '../More Tab/settings_view_model.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<NotificationsViewModel>();
      try {
        vm.bindSettingsViewModel(context.read<SettingsViewModel>());
      } catch (_) {}
      vm.fetchInbox();
    });
  }

  void _onTap(
    BuildContext context,
    NotificationsViewModel vm,
    NotificationModel notification,
  ) {
    // Don't wait on mark-read API — open detail immediately.
    unawaited(vm.markRead(notification));
    final aiId = notification.aiOrderId ??
        (notification.entityType == 'ai_order' ? notification.entityId : null);
    if (aiId == null || aiId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PosAiOrderDetailView(aiOrderId: aiId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final l10n = AppLocalizations.of(context)!;
    final crossAxisCount = isTablet ? 3 : 2;
    // Gap BETWEEN cards only (not inner card padding).
    const hGap = 6.0;
    const vGap = 6.0;
    final pad = EdgeInsets.fromLTRB(
      isTablet ? 16 : 12,
      isTablet ? 12 : 10,
      isTablet ? 16 : 12,
      isTablet ? 20 : 14,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: PosScreenAppBar(
          title: l10n.notifTitle,
          showNotificationIcon: false,
          actions: [
            Consumer<NotificationsViewModel>(
              builder: (context, vm, _) {
                if (vm.notifications.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => vm.markAllAsRead(),
                  child: const Text('Mark all read'),
                );
              },
            ),
          ],
        ),
        body: Consumer<NotificationsViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.notifications.isEmpty) {
              return _NotificationsShimmerGrid(
                isTablet: isTablet,
                crossAxisCount: crossAxisCount,
                padding: pad,
                hGap: hGap,
                vGap: vGap,
              );
            }
            if (vm.errorMessage != null && vm.notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vm.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => vm.fetchInbox(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final notifications = vm.notifications;
            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }
            // Row-based grid so See more can grow card height (fixed GridView
            // extent cannot expand a single cell).
            final rowCount = (notifications.length + crossAxisCount - 1) ~/
                crossAxisCount;
            return RefreshIndicator(
              onRefresh: () => vm.fetchInbox(silent: true),
              child: ListView.separated(
                padding: pad,
                itemCount: rowCount,
                separatorBuilder: (_, __) => const SizedBox(height: vGap),
                itemBuilder: (context, rowIndex) {
                  final start = rowIndex * crossAxisCount;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var col = 0; col < crossAxisCount; col++) ...[
                        if (col > 0) const SizedBox(width: hGap),
                        Expanded(
                          child: start + col < notifications.length
                              ? _NotificationCard(
                                  notification: notifications[start + col],
                                  isTablet: isTablet,
                                  onTap: () => _onTap(
                                    context,
                                    vm,
                                    notifications[start + col],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.notification,
    required this.isTablet,
    required this.onTap,
  });

  final NotificationModel notification;
  final bool isTablet;
  final VoidCallback onTap;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _expanded = false;
  bool _needsSeeMore = false;

  TextStyle get _messageStyle => AppTextStyles.bodyMedium.copyWith(
        color: Colors.grey.shade600,
        fontSize: widget.isTablet ? 13 : 12,
        height: 1.25,
      );

  void _measureOverflow(double maxWidth) {
    if (_expanded) return;
    final painter = TextPainter(
      text: TextSpan(
        text: widget.notification.message,
        style: _messageStyle,
      ),
      maxLines: 2,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    final needs = painter.didExceedMaxLines;
    if (needs != _needsSeeMore && mounted) {
      setState(() => _needsSeeMore = needs);
    }
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;
    final notification = widget.notification;
    final pad = isTablet ? 14.0 : 12.0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(pad, pad, pad, isTablet ? 12 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: notification.isRead
                  ? null
                  : Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      width: 1,
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 7),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    notification.icon,
                    color: AppColors.primaryLight,
                    size: isTablet ? 19 : 17,
                  ),
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedApiText(
                        notification.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 14 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      SizedBox(height: isTablet ? 4 : 3),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _measureOverflow(constraints.maxWidth);
                          });
                          return LocalizedApiText(
                            notification.message,
                            style: _messageStyle,
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            softWrap: true,
                          );
                        },
                      ),
                      if (_needsSeeMore) ...[
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: _toggleExpand,
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            _expanded ? 'See less' : 'See more',
                            style: TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 12 : 11,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: isTablet ? 4 : 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: LocalizedApiText(
                              notification.time,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsShimmerGrid extends StatelessWidget {
  const _NotificationsShimmerGrid({
    required this.isTablet,
    required this.crossAxisCount,
    required this.padding,
    required this.hGap,
    required this.vGap,
  });

  final bool isTablet;
  final int crossAxisCount;
  final EdgeInsets padding;
  final double hGap;
  final double vGap;

  @override
  Widget build(BuildContext context) {
    final rowCount = 3;
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rowCount,
      separatorBuilder: (_, __) => SizedBox(height: vGap),
      itemBuilder: (_, __) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < crossAxisCount; col++) ...[
                if (col > 0) SizedBox(width: hGap),
                const Expanded(child: _NotificationShimmerCard()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NotificationShimmerCard extends StatelessWidget {
  const _NotificationShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const PosShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosShimmerBox(width: 34, height: 34, radius: 8),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(width: 140, height: 13, radius: 6),
                  SizedBox(height: 4),
                  PosShimmerBox(width: double.infinity, height: 10, radius: 5),
                  SizedBox(height: 4),
                  PosShimmerBox(width: 120, height: 10, radius: 5),
                  SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: PosShimmerBox(width: 48, height: 9, radius: 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
