import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/cashier_ai_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/toast_service.dart';
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
      context.read<AiOrdersViewModel>().loadDetail(widget.aiOrderId);
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
                          trailing: const Icon(Icons.link_rounded),
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
    return Consumer<AiOrdersViewModel>(
      builder: (context, vm, _) {
        final order = vm.selectedOrder;
        final title = order?.displayPlate ?? 'AI Order';
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: PosScreenAppBar(
            title: title,
            showNotificationIcon: false,
          ),
          body: vm.isDetailLoading && order == null
              ? const Center(child: CircularProgressIndicator())
              : vm.detailError != null && order == null
                  ? Center(child: Text(vm.detailError!))
                  : order == null
                      ? const Center(child: Text('Order not found'))
                      : _buildContent(vm, order),
        );
      },
    );
  }

  Widget _buildContent(AiOrdersViewModel vm, AiOrderCashier order) {
    final canAck = order.isUnbilledAlert ||
        (order.status == 'CONFIRMED' &&
            order.cashierAcknowledgedAt == null &&
            order.cashierOrderId == null);
    final canLink = order.status != 'MATCHED' &&
        order.status != 'EXPIRED' &&
        order.cashierOrderId == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _headerCard(order),
        const SizedBox(height: 12),
        _infoCard(order),
        const SizedBox(height: 12),
        _bayTimeline(order),
        if (order.linkedSalesOrder != null) ...[
          const SizedBox(height: 12),
          _linkedOrderCard(order.linkedSalesOrder!),
        ],
        const SizedBox(height: 20),
        if (vm.isActionBusy)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              if (canAck)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _acknowledge(vm),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Acknowledge'),
                  ),
                ),
              if (canAck && canLink) const SizedBox(width: 10),
              if (canLink)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _linkToPos(vm),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Link to POS'),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _headerCard(AiOrderCashier order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: order.isUnbilledAlert
              ? Colors.red.shade200
              : order.isCompanyVehicle
                  ? Colors.indigo.shade200
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.displayPlate,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                order.status,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.captureNo,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (order.isCompanyVehicle) _chip('Company vehicle', Colors.indigo),
              if (order.isUnbilledAlert) _chip('Unbilled alert', Colors.red),
              if (order.hasOpenPosOrder) _chip('Open POS', Colors.green),
              if (order.cashierAcknowledgedAt != null)
                _chip('Acknowledged', Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.shade800,
        ),
      ),
    );
  }

  Widget _infoCard(AiOrderCashier order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _kv('Entrance', _fmt(order.entranceDetectedAt)),
          _kv('First service bay', _fmt(order.firstServiceBayAt)),
          if (order.minutesSinceFirstBay != null)
            _kv('Minutes since bay', '${order.minutesSinceFirstBay}'),
          if (order.unbilledGraceMinutes != null)
            _kv('Grace (min)', '${order.unbilledGraceMinutes}'),
          if (order.entranceCameraName != null)
            _kv('Entrance camera', order.entranceCameraName!),
          if (order.confidence != null)
            _kv(
              'Confidence',
              '${(order.confidence! * 100).toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bayTimeline(AiOrderCashier order) {
    final events = order.serviceBayEvents;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service bay timeline',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Text(
              'No bay detections yet',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...events.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.departmentName ?? 'Bay',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_fmt(e.detectedAt)}'
                            '${e.cameraName != null ? ' · ${e.cameraName}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _linkedOrderCard(AiOrderLinkedSalesOrder linked) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linked POS order',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text('Order #${linked.id}'),
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
