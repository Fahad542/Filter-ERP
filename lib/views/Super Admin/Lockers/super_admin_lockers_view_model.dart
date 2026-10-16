import 'package:flutter/material.dart';

class SuperAdminLockersViewModel extends ChangeNotifier {
  bool isLoading = false;
  String searchQuery = '';
  String filterStatus = 'All';

  final List<Map<String, dynamic>> _allLockers = [
    {
      'id': 'LOK-RYD-001',
      'location': 'Riyadh Main Station',
      'address': 'King Fahd Road',
      'totalBoxes': 24,
      'availableBoxes': 8,
      'status': 'Online',
      'lastSync': 'Just now',
    },
    {
      'id': 'LOK-JED-002',
      'location': 'Jeddah City Center',
      'address': 'Tahlia Street',
      'totalBoxes': 16,
      'availableBoxes': 0,
      'status': 'Full',
      'lastSync': '5 mins ago',
    },
    {
      'id': 'LOK-DMM-003',
      'location': 'Dammam East Mall',
      'address': 'Corniche Road',
      'totalBoxes': 20,
      'availableBoxes': 20,
      'status': 'Offline',
      'lastSync': '2 hours ago',
    },
    {
      'id': 'LOK-MEC-004',
      'location': 'Mecca Plaza',
      'address': 'Aziziyah',
      'totalBoxes': 32,
      'availableBoxes': 12,
      'status': 'Online',
      'lastSync': 'Just now',
    },
    {
      'id': 'LOK-RYD-005',
      'location': 'Riyadh North Station',
      'address': 'Olaya Street',
      'totalBoxes': 16,
      'availableBoxes': 2,
      'status': 'Online',
      'lastSync': '1 min ago',
    },
  ];

  List<Map<String, dynamic>> get filteredLockers {
    return _allLockers.where((locker) {
      final matchesSearch = locker['location'].toLowerCase().contains(searchQuery.toLowerCase()) || 
                            locker['id'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = filterStatus == 'All' || locker['status'] == filterStatus;
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

  void restartLocker(String id) {
    // Dummy restart action
    final index = _allLockers.indexWhere((l) => l['id'] == id);
    if (index != -1) {
      _allLockers[index]['status'] = 'Restarting...';
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        _allLockers[index]['status'] = 'Online';
        _allLockers[index]['lastSync'] = 'Just now';
        notifyListeners();
      });
    }
  }
}
