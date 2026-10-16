import 'package:flutter/material.dart';

class DeliveryTaskItem {
  final String id;
  final String poNumber;
  final String location;
  final String items;
  final String status;
  final String? eta;

  DeliveryTaskItem({
    required this.id,
    required this.poNumber,
    required this.location,
    required this.items,
    required this.status,
    this.eta,
  });
}

class SupplierDeliveryTasksViewModel extends ChangeNotifier {
  List<DeliveryTaskItem> readyToDeliverList = [];
  List<DeliveryTaskItem> myTasks = [];

  SupplierDeliveryTasksViewModel() {
    loadTasks();
  }

  void loadTasks() {
    readyToDeliverList = [
      DeliveryTaskItem(
        id: '1',
        poNumber: 'PO-9874',
        location: 'Riyadh',
        items: 'Tire Set x4',
        status: 'Ready to Deliver',
      ),
    ];
    myTasks = [
      DeliveryTaskItem(
        id: '2',
        poNumber: 'PO-9873',
        location: 'Jeddah',
        items: 'Brake Pads x10',
        status: 'On the Way',
        eta: '45 min',
      ),
    ];
    notifyListeners();
  }

  void acceptTask(String poId) {
    final i = readyToDeliverList.indexWhere((t) => t.id == poId);
    if (i >= 0) {
      final t = readyToDeliverList.removeAt(i);
      myTasks.add(
        DeliveryTaskItem(
          id: t.id,
          poNumber: t.poNumber,
          location: t.location,
          items: t.items,
          status: 'Driver Assigned',
        ),
      );
      notifyListeners();
    }
  }

  void setOnTheWay(String poId, int etaMinutes) {
    final i = myTasks.indexWhere((t) => t.id == poId);
    if (i >= 0 && myTasks[i].status == 'Driver Assigned') {
      myTasks[i] = DeliveryTaskItem(
        id: myTasks[i].id,
        poNumber: myTasks[i].poNumber,
        location: myTasks[i].location,
        items: myTasks[i].items,
        status: 'On the Way',
        eta: '$etaMinutes min',
      );
      notifyListeners();
    }
  }

  void markDelivered(String poId) {
    final i = myTasks.indexWhere((t) => t.id == poId);
    if (i >= 0) {
      myTasks[i] = DeliveryTaskItem(
        id: myTasks[i].id,
        poNumber: myTasks[i].poNumber,
        location: myTasks[i].location,
        items: myTasks[i].items,
        status: 'Delivered',
        eta: myTasks[i].eta,
      );
      notifyListeners();
    }
  }
}
