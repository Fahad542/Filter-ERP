import 'package:flutter/material.dart';

class QueueOrderItem {
  final String id;
  final String poNumber;
  final String branch;
  final String itemsSummary;
  final String status;
  final String workshopNotes;

  QueueOrderItem({
    required this.id,
    required this.poNumber,
    required this.branch,
    required this.itemsSummary,
    required this.status,
    required this.workshopNotes,
  });
}

class SupplierOrderProcessingQueueViewModel extends ChangeNotifier {
  List<QueueOrderItem> queueOrders = [];
  String? selectedOrderId;

  SupplierOrderProcessingQueueViewModel() {
    loadQueue();
  }

  void loadQueue() {
    queueOrders = [
      QueueOrderItem(
        id: '1',
        poNumber: 'PO-9875',
        branch: 'Jeddah',
        itemsSummary: 'Brake Pads x20',
        status: 'Accepted',
        workshopNotes: 'Please deliver before 3 PM',
      ),
      QueueOrderItem(
        id: '2',
        poNumber: 'PO-9874',
        branch: 'Riyadh Main',
        itemsSummary: '5W-30 Oil x50',
        status: 'Processing',
        workshopNotes: '—',
      ),
    ];
    notifyListeners();
  }

  QueueOrderItem? get selectedOrder {
    if (selectedOrderId == null) return null;
    try {
      return queueOrders.firstWhere((o) => o.id == selectedOrderId);
    } catch (_) {
      return null;
    }
  }

  void setSelectedOrder(String? id) {
    selectedOrderId = id;
    notifyListeners();
  }

  void startProcessing(String poId) {
    final i = queueOrders.indexWhere((o) => o.id == poId);
    if (i >= 0 && queueOrders[i].status == 'Accepted') {
      final o = queueOrders[i];
      queueOrders[i] = QueueOrderItem(
        id: o.id,
        poNumber: o.poNumber,
        branch: o.branch,
        itemsSummary: o.itemsSummary,
        status: 'Processing',
        workshopNotes: o.workshopNotes,
      );
      notifyListeners();
    }
  }

  void markReadyToDeliver(String poId) {
    final i = queueOrders.indexWhere((o) => o.id == poId);
    if (i >= 0 && queueOrders[i].status == 'Processing') {
      final o = queueOrders[i];
      queueOrders[i] = QueueOrderItem(
        id: o.id,
        poNumber: o.poNumber,
        branch: o.branch,
        itemsSummary: o.itemsSummary,
        status: 'Ready to Deliver',
        workshopNotes: o.workshopNotes,
      );
      notifyListeners();
    }
  }
}
