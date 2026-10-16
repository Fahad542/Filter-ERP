import 'package:flutter/material.dart';

class SuperAdminDashboardViewModel extends ChangeNotifier {
  // Stats
  double totalRevenue = 1250000.50;
  int totalOrders = 8432;
  int totalBranches = 45;
  int totalUsers = 1250;



  bool isLoading = false;

  Future<void> refreshData() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    isLoading = false;
    notifyListeners();
  }
}
