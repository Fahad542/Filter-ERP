import 'package:flutter/material.dart';

class PaymentItem {
  final String id;
  final String date;
  final String invoiceId;
  final String amount;
  final String method;
  final String status;
  final String? reference;

  PaymentItem({
    required this.id,
    required this.date,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.status,
    this.reference,
  });
}

class SupplierPaymentsReceivedViewModel extends ChangeNotifier {
  String currentReceivables = 'SAR 45,300';
  List<PaymentItem> payments = [];

  SupplierPaymentsReceivedViewModel() {
    loadPayments();
  }

  void loadPayments() {
    payments = [
      PaymentItem(
        id: '1',
        date: '12 Feb',
        invoiceId: 'INV-S-7845',
        amount: 'SAR 1,840',
        method: 'Bank Trans',
        status: 'Pending',
      ),
      PaymentItem(
        id: '2',
        date: '11 Feb',
        invoiceId: 'INV-S-7844',
        amount: 'SAR 4,200',
        method: 'Online',
        status: 'Paid',
        reference: 'TXN-45678',
      ),
    ];
    notifyListeners();
  }

  void acceptPayment(String paymentId) {
    final i = payments.indexWhere((p) => p.id == paymentId);
    if (i >= 0 && payments[i].status == 'Pending') {
      final p = payments[i];
      payments[i] = PaymentItem(
        id: p.id,
        date: p.date,
        invoiceId: p.invoiceId,
        amount: p.amount,
        method: p.method,
        status: 'Paid',
        reference: p.reference,
      );
      notifyListeners();
    }
  }
}
