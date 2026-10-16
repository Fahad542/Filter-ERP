import 'package:flutter/material.dart';

class SuperAdminOrdersViewModel extends ChangeNotifier {
  bool isLoading = false;
  String searchQuery = '';
  String filterStatus = 'All';

  final List<Map<String, dynamic>> _allOrders = [
    {'id': 'ORD-10201', 'date': '2026-03-02 10:30 AM', 'customer': 'Ahmed S.', 'branch': 'Riyadh Main', 'total': 450.0, 'status': 'Completed', 'payment': 'Credit Card', 'items': 3},
    {'id': 'ORD-10202', 'date': '2026-03-02 11:15 AM', 'customer': 'STC Fleet', 'branch': 'Jeddah Central', 'total': 1200.0, 'status': 'Pending', 'payment': 'Corporate', 'items': 12},
    {'id': 'ORD-10203', 'date': '2026-03-02 12:00 PM', 'customer': 'Walk-in Customer', 'branch': 'Dammam East', 'total': 85.0, 'status': 'Completed', 'payment': 'Cash', 'items': 1},
    {'id': 'ORD-10204', 'date': '2026-03-01 04:45 PM', 'customer': 'Khalid A.', 'branch': 'Mecca Plaza', 'total': 320.0, 'status': 'Cancelled', 'payment': 'Credit Card', 'items': 2},
    {'id': 'ORD-10205', 'date': '2026-03-01 02:30 PM', 'customer': 'Aramco Logistics', 'branch': 'Riyadh North', 'total': 5400.0, 'status': 'Completed', 'payment': 'Corporate', 'items': 45},
    {'id': 'ORD-10206', 'date': '2026-03-01 01:10 PM', 'customer': 'Nouf B.', 'branch': 'Jeddah Central', 'total': 150.0, 'status': 'Refunded', 'payment': 'Apple Pay', 'items': 1},
  ];

  List<Map<String, dynamic>> get filteredOrders {
    return _allOrders.where((order) {
      final matchesSearch = order['id'].toString().toLowerCase().contains(searchQuery.toLowerCase()) || 
                            order['customer'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                            order['branch'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = filterStatus == 'All' || 
                            order['status'].toString().toLowerCase() == filterStatus.toLowerCase();
      return matchesSearch && matchesStatus;
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

  void setFilterStatus(String status) {
    filterStatus = status;
    notifyListeners();
  }

  void exportData() {
    // Dummy export action
  }
}
