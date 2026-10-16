import 'package:flutter/material.dart';
import '../../../data/repositories/super_admin_repository.dart';
import '../../../services/session_service.dart';
import '../../../models/super_admin_branches_api_model.dart';

class SuperAdminBranchesViewModel extends ChangeNotifier {
  final SuperAdminRepository _repository = SuperAdminRepository();
  final SessionService _sessionService = SessionService();

  bool isLoading = false;
  String searchQuery = '';
  String statusFilter = 'All';

  List<SuperAdminBranch> _allBranches = [];

  List<SuperAdminBranch> get filteredBranches {
    return _allBranches.where((branch) {
      final matchesSearch = branch.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            branch.id.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = statusFilter == 'All' || 
                            branch.status.toLowerCase() == statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    
    try {
      final token = await _sessionService.getToken(role: 'super_admin');
      if (token != null) {
        final response = await _repository.getBranches(token);
        if (response.success) {
          _allBranches = response.branches;
        }
      }
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    statusFilter = status;
    notifyListeners();
  }

  void deleteBranch(String id) {
    _allBranches.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
