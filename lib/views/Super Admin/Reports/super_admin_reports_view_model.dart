import 'package:flutter/material.dart';

class SuperAdminReportsViewModel extends ChangeNotifier {
  // Chart Data (dummy daily sales for a week)
  final List<double> salesData = [12000, 15000, 11000, 18000, 22000, 19000, 25000];
  
  // Recent Orders (dummy)
  final List<Map<String, dynamic>> recentOrders = [
    {'id': '#ORD-1092', 'customer': 'Ali Ahmad', 'branch': 'Riyadh Main', 'amount': 450.0, 'status': 'Completed', 'date': 'Today, 10:30 AM'},
    {'id': '#ORD-1091', 'customer': 'Corporate XYZ', 'branch': 'Jeddah Central', 'amount': 1200.0, 'status': 'Pending', 'date': 'Today, 09:15 AM'},
    {'id': '#ORD-1090', 'customer': 'Sara M.', 'branch': 'Dammam East', 'amount': 320.0, 'status': 'Completed', 'date': 'Yesterday, 04:20 PM'},
    {'id': '#ORD-1089', 'customer': 'Khalid S.', 'branch': 'Riyadh North', 'amount': 850.0, 'status': 'Cancelled', 'date': 'Yesterday, 02:10 PM'},
    {'id': '#ORD-1088', 'customer': 'Nouf B.', 'branch': 'Mecca Branch', 'amount': 150.0, 'status': 'Completed', 'date': 'Yesterday, 11:00 AM'},
  ];

  bool isLoading = false;

  Future<void> refreshData() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    isLoading = false;
    notifyListeners();
  }
}
