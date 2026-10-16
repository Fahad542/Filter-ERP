import 'package:flutter/material.dart';

class InvoiceLineItem {
  final String product;
  final double lastPurchase;
  double salesPrice;
  int qty;
  double get profitPercent =>
      lastPurchase > 0 ? ((salesPrice - lastPurchase) / lastPurchase * 100) : 0;
  double get lineTotal => salesPrice * qty;

  InvoiceLineItem({
    required this.product,
    required this.lastPurchase,
    required this.salesPrice,
    required this.qty,
  });
}

class SupplierManualInvoiceViewModel extends ChangeNotifier {
  List<String> workshops = ['Riyadh Main', 'Jeddah'];
  String? selectedWorkshopId;
  List<InvoiceLineItem> lineItems = [];
  final notesController = TextEditingController();
  String searchQuery = '';

  SupplierManualInvoiceViewModel() {
    selectedWorkshopId = workshops.first;
    lineItems = [
      InvoiceLineItem(
        product: '5W-30 Oil',
        lastPurchase: 24.50,
        salesPrice: 29.00,
        qty: 10,
      ),
    ];
  }

  double get subtotal => lineItems.fold(0, (s, i) => s + i.lineTotal);
  double get vatAmount => subtotal * 0.15;
  double get grandTotal => subtotal + vatAmount;

  void addLineItem(
    String product,
    double lastPurchase,
    double salesPrice,
    int qty,
  ) {
    lineItems.add(
      InvoiceLineItem(
        product: product,
        lastPurchase: lastPurchase,
        salesPrice: salesPrice,
        qty: qty,
      ),
    );
    notifyListeners();
  }

  void updateQty(int index, int qty) {
    if (index >= 0 && index < lineItems.length) {
      lineItems[index].qty = qty;
      notifyListeners();
    }
  }

  void removeLine(int index) {
    if (index >= 0 && index < lineItems.length) {
      lineItems.removeAt(index);
      notifyListeners();
    }
  }

  void submitInvoice() {
    if (selectedWorkshopId == null || lineItems.isEmpty) return;
    // Stub
    notifyListeners();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
