import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/cashier_ai_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import 'ai_orders_view_model.dart';

class PosAiOrderDetailView extends StatefulWidget {
  const PosAiOrderDetailView({super.key, required this.aiOrderId});

  final String aiOrderId;

  @override
  State<PosAiOrderDetailView> createState() => _PosAiOrderDetailViewState();
}

class _PosAiOrderDetailViewState extends State<PosAiOrderDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cache-first so screen paints immediately; API refresh is silent.
      context.read<AiOrdersViewModel>().openDetail(widget.aiOrderId);
    });
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy · HH:mm').format(dt.toLocal());
  }

  String _fmtShort(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  Future<void> _acknowledge(AiOrdersViewModel vm) async {
    try {
      await vm.acknowledgeSelected();
      if (!mounted) return;
      ToastService.showSuccess(context, 'Alert acknowledged');
    } catch (e) {
      if (!mounted) return;
      ToastService.showError(context, e.toString());
    }
  }

  Future<void> _linkToPos(AiOrdersViewModel vm) async {
    final order = vm.selectedOrder;
    if (order == null) return;
    try {
      final result = await vm.openPosOrdersForSelected();
      if (!mounted) return;
      if (!result.found || result.orders.isEmpty) {
        ToastService.showError(
          context,
          'No open POS order found for this plate',
        );
        return;
      }
      final picked = await showModalBottomSheet<OpenPosOrderByPlateItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Link to open POS order',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plate ${result.plateNumber}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: result.orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final o = result.orders[i];
                        final subtitle = [
                          if (o.customerName != null &&
                              o.customerName!.isNotEmpty)
                            o.customerName!,
                          if (o.status != null) o.status!,
                          if (o.createdAt != null) _fmtShort(o.createdAt),
                        ].join(' · ');
                        return ListTile(
                          title: Text(
                            'Order #${o.id}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(subtitle),
                          trailing: const Icon(
                            Icons.link_rounded,
                            color: AppColors.secondaryLight,
                          ),
                          onTap: () => Navigator.pop(ctx, o),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (picked == null || !mounted) return;
      await vm.linkSelectedToSalesOrder(picked.id);
      if (!mounted) return;
      ToastService.showSuccess(context, 'AI order linked to POS');
    } catch (e) {
      if (!mounted) return;
      ToastService.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Consumer<AiOrdersViewModel>(
        builder: (context, vm, _) {
          final order = vm.selectedOrder;
          final title = order?.displayPlate ?? 'AI Order';
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: PosScreenAppBar(
              title: title,
              showNotificationIcon: false,
            ),
            body: vm.isDetailLoading && order == null
                ? const _DetailShimmer()
                : vm.detailError != null && order == null
                    ? _ErrorBody(
                        message: vm.detailError!,
                        onRetry: () => vm.openDetail(widget.aiOrderId),
                      )
                    : order == null
                        ? const Center(child: Text('Order not found'))
                        : _buildBody(vm, order, isTablet: isTablet),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    AiOrdersViewModel vm,
    AiOrderCashier order, {
    required bool isTablet,
  }) {
    final canAck = order.isUnbilledAlert ||
        (order.status == 'CONFIRMED' &&
            order.cashierAcknowledgedAt == null &&
            order.cashierOrderId == null);
    final canLink = order.status != 'MATCHED' &&
        order.status != 'EXPIRED' &&
        order.cashierOrderId == null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 20 : 14,
              12,
              isTablet ? 20 : 14,
              16,
            ),
            children: [
              _OverviewCard(order: order),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Details',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DetailTile(
                        label: 'Entrance',
                        value: _fmt(order.entranceDetectedAt),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailTile(
                        label: 'First service bay',
                        value: _fmt(order.firstServiceBayAt),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailTile(
                        label: 'Minutes since bay',
                        value: order.minutesSinceFirstBay != null
                            ? '${order.minutesSinceFirstBay}'
                            : '—',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailTile(
                        label: 'Grace (min)',
                        value: order.unbilledGraceMinutes != null
                            ? '${order.unbilledGraceMinutes}'
                            : '—',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailTile(
                        label: 'Confidence',
                        value: order.confidence != null
                            ? '${(order.confidence! * 100).toStringAsFixed(1)}%'
                            : '—',
                      ),
                    ),
                    if (order.entranceCameraName != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailTile(
                          label: 'Entrance camera',
                          value: order.entranceCameraName!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Service bay timeline',
                child: order.serviceBayEvents.isEmpty
                    ? Text(
                        'No bay detections yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : _BayTimelineGrid(
                        events: order.serviceBayEvents,
                        fmt: _fmt,
                      ),
              ),
              if (order.linkedSalesOrder != null) ...[
                const SizedBox(height: 10),
                _LinkedOrderCard(linked: order.linkedSalesOrder!),
              ],
            ],
          ),
        ),
        if (canAck || canLink)
          _BottomActions(
            busy: vm.isActionBusy,
            canAck: canAck,
            canLink: canLink,
            onAcknowledge: () => _acknowledge(vm),
            onLink: () => _linkToPos(vm),
          ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.busy,
    required this.canAck,
    required this.canLink,
    required this.onAcknowledge,
    required this.onLink,
  });

  final bool busy;
  final bool canAck;
  final bool canLink;
  final VoidCallback onAcknowledge;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: busy
              ? const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              : Row(
                  children: [
                    if (canAck)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: onAcknowledge,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondaryLight,
                              foregroundColor: AppColors.onSecondaryLight,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Acknowledge',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    if (canAck && canLink) const SizedBox(width: 10),
                    if (canLink)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: onLink,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.onPrimaryLight,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Link to POS',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.order});

  final AiOrderCashier order;

  @override
  Widget build(BuildContext context) {
    final alert = order.isUnbilledAlert;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isCompanyVehicle
              ? const Color(0xFFC7D2FE)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
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
                      order.displayPlate,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.captureNo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Unbilled alert immediately before CONFIRMED / status.
              if (alert) ...[
                _MiniChip(
                  'Unbilled alert',
                  bg: const Color(0xFFFEF2F2),
                  fg: const Color(0xFFB91C1C),
                ),
                const SizedBox(width: 6),
              ],
              _StatusPill(status: order.status),
            ],
          ),
          if (order.isCompanyVehicle ||
              order.hasOpenPosOrder ||
              order.cashierAcknowledgedAt != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (order.isCompanyVehicle)
                  _MiniChip(
                    'Company vehicle',
                    bg: const Color(0xFFEEF2FF),
                    fg: const Color(0xFF4338CA),
                  ),
                if (order.hasOpenPosOrder)
                  _MiniChip(
                    'Open POS',
                    bg: const Color(0xFFECFDF5),
                    fg: const Color(0xFF15803D),
                  ),
                if (order.cashierAcknowledgedAt != null)
                  _MiniChip(
                    'Acknowledged',
                    bg: const Color(0xFFF1F5F9),
                    fg: const Color(0xFF475569),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    switch (status) {
      case 'CONFIRMED':
        fg = const Color(0xFFB48A14);
        bg = const Color(0xFFFFF9EC);
      case 'MATCHED':
        fg = const Color(0xFF15803D);
        bg = const Color(0xFFECFDF5);
      case 'UNMATCHED':
        fg = const Color(0xFFB91C1C);
        bg = const Color(0xFFFFF5F5);
      case 'EXPIRED':
        fg = const Color(0xFF64748B);
        bg = const Color(0xFFF8FAFC);
      default:
        fg = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label, {required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }
}

class _BayTimelineGrid extends StatelessWidget {
  const _BayTimelineGrid({
    required this.events,
    required this.fmt,
  });

  final List<AiOrderBayEvent> events;
  final String Function(DateTime?) fmt;

  @override
  Widget build(BuildContext context) {
    const perRow = 3;
    final rows = <Widget>[];
    for (var i = 0; i < events.length; i += perRow) {
      final slice = events.skip(i).take(perRow).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + perRow < events.length ? 10 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < perRow; c++) ...[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: c < slice.length
                      ? _BayEventRow(
                          title: slice[c].departmentName ?? 'Bay',
                          subtitle:
                              '${fmt(slice[c].detectedAt)}${slice[c].cameraName != null ? ' · ${slice[c].cameraName}' : ''}',
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _BayEventRow extends StatelessWidget {
  const _BayEventRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.place_outlined,
            size: 14,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkedOrderCard extends StatelessWidget {
  const _LinkedOrderCard({required this.linked});

  final AiOrderLinkedSalesOrder linked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Linked POS order',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Order #${linked.id}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight,
            ),
          ),
          if (linked.customerName != null) Text(linked.customerName!),
          if (linked.invoiceNo != null) Text('Invoice ${linked.invoiceNo}'),
          if (linked.status != null)
            Text(
              linked.status!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 160,
              height: 42,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.onPrimaryLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: const PosShimmer(
            child: Row(
              children: [
                PosShimmerBox(width: 42, height: 42, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosShimmerBox(width: 120, height: 16, radius: 6),
                      SizedBox(height: 8),
                      PosShimmerBox(width: 160, height: 10, radius: 5),
                    ],
                  ),
                ),
                PosShimmerBox(width: 72, height: 22, radius: 999),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: const PosShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosShimmerBox(width: 80, height: 14, radius: 6),
                SizedBox(height: 12),
                PosShimmerBox(width: double.infinity, height: 12, radius: 5),
                SizedBox(height: 8),
                PosShimmerBox(width: double.infinity, height: 12, radius: 5),
                SizedBox(height: 8),
                PosShimmerBox(width: 180, height: 12, radius: 5),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
