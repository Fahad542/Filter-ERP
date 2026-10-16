import 'package:flutter/material.dart';

class InvoiceIssuedItem {
  final String id;
  final String branch;
  final String date;
  final String amount;
  final String status;

  InvoiceIssuedItem({
    required this.id,
    required this.branch,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class SupplierInvoicesIssuedViewModel extends ChangeNotifier {
  List<InvoiceIssuedItem> invoices = [];
  String? dateFrom;
  String? dateTo;
  String selectedBranch = 'All';
  String selectedStatus = 'All';

  SupplierInvoicesIssuedViewModel() {
    loadInvoices();
  }

  void loadInvoices() {
    invoices = [
      InvoiceIssuedItem(
        id: 'INV-S-7845',
        branch: 'Riyadh',
        date: '12 Feb',
        amount: 'SAR 1,840',
        status: 'Pending',
      ),
      InvoiceIssuedItem(
        id: 'INV-S-7844',
        branch: 'Jeddah',
        date: '11 Feb',
        amount: 'SAR 4,200',
        status: 'Paid',
      ),
    ];
    notifyListeners();
  }

  void sendReminder(String invoiceId) {
    notifyListeners();
  }

  void downloadPdf(String invoiceId) {
    notifyListeners();
  }
}
