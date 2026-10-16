import 'package:flutter/material.dart';

class SuperAdminFinanceViewModel extends ChangeNotifier {
  bool isLoading = false;
  String searchQuery = '';
  String typeFilter = 'All Types';

  // Overall Financials
  final double totalRevenue = 1250000.50;
  final double totalExpenses = 345000.20;
  
  double get netProfit => totalRevenue - totalExpenses;

  final List<Map<String, dynamic>> _allTransactions = [
    {'id': 'TRD-5091', 'date': 'Today, 02:30 PM', 'description': 'Corporate Invoice Payment (Aramco)', 'amount': 45500.0, 'type': 'Revenue', 'category': 'B2B Sales'},
    {'id': 'TRD-5090', 'date': 'Today, 10:15 AM', 'description': 'Supplier Payment (Parts Dist.)', 'amount': -15000.0, 'type': 'Expense', 'category': 'Inventory'},
    {'id': 'TRD-5089', 'date': 'Yesterday, 04:00 PM', 'description': 'Daily POS Settlement (Riyadh Main)', 'amount': 12450.0, 'type': 'Revenue', 'category': 'Retail Sales'},
    {'id': 'TRD-5088', 'date': '2026-02-28', 'description': 'Monthly Server Hosting', 'amount': -1200.0, 'type': 'Expense', 'category': 'IT Infrastructure'},
    {'id': 'TRD-5087', 'date': '2026-02-28', 'description': 'Staff Payroll Processing', 'amount': -125000.0, 'type': 'Expense', 'category': 'Payroll'},
    {'id': 'TRD-5086', 'date': '2026-02-27', 'description': 'Corporate Invoice Payment (STC)', 'amount': 12000.0, 'type': 'Revenue', 'category': 'B2B Sales'},
  ];

  List<Map<String, dynamic>> get filteredTransactions {
    return _allTransactions.where((trx) {
      final matchesSearch = trx['description'].toString().toLowerCase().contains(searchQuery.toLowerCase()) || 
                            trx['id'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = typeFilter == 'All Types' || 
                          trx['type'].toString().toLowerCase() == typeFilter.toLowerCase();
      return matchesSearch && matchesType;
    }).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    typeFilter = type;
    notifyListeners();
  }
}
