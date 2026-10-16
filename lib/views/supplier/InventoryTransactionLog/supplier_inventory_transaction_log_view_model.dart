import 'package:flutter/material.dart';

class TransactionLogItem {
  final String dateTime;
  final String type;
  final String reason;
  final String user;
  final String qtyBefore;
  final String delta;
  final String qtyAfter;
  final String reference;

  TransactionLogItem({
    required this.dateTime,
    required this.type,
    required this.reason,
    required this.user,
    required this.qtyBefore,
    required this.delta,
    required this.qtyAfter,
    required this.reference,
  });
}

class SupplierInventoryTransactionLogViewModel extends ChangeNotifier {
  List<String> products = ['All', '5W-30 Oil', 'Brake Pads'];
  List<String> types = ['All', 'Receipt', 'Sale', 'Adjustment'];
  List<String> locations = ['All', 'Warehouse', 'Workshop'];
  String selectedProduct = 'All';
  String selectedType = 'All';
  String selectedLocation = 'All';
  String? dateFrom;
  String? dateTo;
  List<TransactionLogItem> transactions = [];

  SupplierInventoryTransactionLogViewModel() {
    loadTransactions();
  }

  void loadTransactions() {
    transactions = [
      TransactionLogItem(
        dateTime: '21-Feb 14:30',
        type: 'Receipt',
        reason: 'From Main Oil Co.',
        user: 'Admin',
        qtyBefore: '1,045 L',
        delta: '+200',
        qtyAfter: '1,245 L',
        reference: 'Receipt #REC-456',
      ),
      TransactionLogItem(
        dateTime: '20-Feb 09:15',
        type: 'Sale',
        reason: 'To Riyadh Workshop',
        user: 'Processing',
        qtyBefore: '1,085 L',
        delta: '-40',
        qtyAfter: '1,045 L',
        reference: 'INV-S-7845',
      ),
    ];
    notifyListeners();
  }
}
