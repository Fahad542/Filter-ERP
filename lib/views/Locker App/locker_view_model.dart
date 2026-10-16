import 'package:flutter/material.dart';
import '../../models/locker_models.dart';

class LockerViewModel extends ChangeNotifier {
  LockerOfficer? _currentUser;
  List<LockerRequest> _allRequests = [];
  List<LockerCollection> _collections = [];
  List<LockerOfficer> _officers = [];

  LockerOfficer? get currentUser => _currentUser;
  List<LockerRequest> get allRequests => _allRequests;
  List<LockerCollection> get collections => _collections;
  List<LockerOfficer> get officers => _officers;

  // Role based filtering
  List<LockerRequest> get filteredRequests {
    if (_currentUser == null) return [];
    return _allRequests.where((r) => r.assignedOfficerId == _currentUser!.id).toList();
  }

  void init() {
    _mockData();
    // Default to Manager for initial view
    notifyListeners();
  }

  void _mockData() {
    _officers = [
      LockerOfficer(id: 'OFF001', name: 'Khalid Salman', mobile: '0501234567', displayCode: '', email: '', userType: ''),
      LockerOfficer(id: 'OFF002', name: 'Ahmad Abdullah', mobile: '0507654321', displayCode: '', email: '', userType: '', ),
      LockerOfficer(id: 'OFF003', name: 'Sami Nasser', mobile: '0501112223', displayCode: '', email: '', userType: '', ),
    ];

    _allRequests = [
      LockerRequest(
        id: 'REQ-101',
        branchName: 'Riyadh Central',
        cashierName: 'Omar Khan',
        closingDate: DateTime.now().subtract(const Duration(hours: 2)),
        lockedCashAmount: 5200.0,
        status: LockerStatus.pending,
        referenceCode: '',
      ),
      LockerRequest(
        id: 'REQ-102',
        branchName: 'Jeddah North',
        cashierName: 'Yasin Ali',
        closingDate: DateTime.now().subtract(const Duration(hours: 4)),
        lockedCashAmount: 3450.0,
        status: LockerStatus.assigned,
        assignedOfficerId: 'OFF002',
        referenceCode: '',
      ),
      LockerRequest(
        id: 'REQ-103',
        branchName: 'Dammam East',
        cashierName: 'Hassan Aziz',
        closingDate: DateTime.now().subtract(const Duration(days: 1)),
        lockedCashAmount: 8900.0,
        status: LockerStatus.approved,
        assignedOfficerId: 'OFF003',
        referenceCode: '',
      ),
      LockerRequest(
        id: 'REQ-104',
        branchName: 'Makkah South',
        cashierName: 'Fahad Saeed',
        closingDate: DateTime.now().subtract(const Duration(hours: 1)),
        lockedCashAmount: 12500.0,
        status: LockerStatus.pending,
        referenceCode: '',
      ),
    ];

    _collections = [
      LockerCollection(
        id: 'COL-001',
        requestId: 'REQ-103',
        officerId: 'OFF003',
        receivedAmount: 8900.0,
        collectionDate: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        difference: 0.0,
      ),
    ];
  }

  void switchRole(String role) {
    notifyListeners();
  }

  void assignOfficer(String requestId, String officerId) {
    int index = _allRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _allRequests[index] = _allRequests[index].copyWith(
        status: LockerStatus.assigned,
        assignedOfficerId: officerId,
      );
      notifyListeners();
    }
  }

  void recordCollection({
    required String requestId,
    required double receivedAmount,
    String? notes,
    String? proofUrl,
  }) {
    int index = _allRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      double locked = _allRequests[index].lockedCashAmount;
      double diff = receivedAmount - locked;

      LockerCollection newCollection = LockerCollection(
        id: 'COL-${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        officerId: _currentUser!.id,
        receivedAmount: receivedAmount,
        collectionDate: DateTime.now(),
        difference: diff,
        notes: notes,
        proofUrl: proofUrl,
      );

      _collections.add(newCollection);
      _allRequests[index] = _allRequests[index].copyWith(status: LockerStatus.awaitingApproval);
      notifyListeners();
    }
  }

  double calculateTodayCollected() {
    return _collections
        .where((c) => 
            c.collectionDate.day == DateTime.now().day &&
            c.collectionDate.month == DateTime.now().month &&
            c.collectionDate.year == DateTime.now().year)
        .fold(0, (sum, c) => sum + c.receivedAmount);
  }

  double calculateTotalDifferences() {
    return _collections.fold(0, (sum, c) => sum + c.difference);
  }

  double calculateTotalShort() {
    return _collections.where((c) => c.difference < 0).fold(0, (sum, c) => sum + c.difference.abs());
  }

  double calculateTotalOver() {
    return _collections.where((c) => c.difference > 0).fold(0, (sum, c) => sum + c.difference);
  }
}
