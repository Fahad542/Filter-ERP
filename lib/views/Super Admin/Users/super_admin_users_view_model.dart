import 'package:flutter/material.dart';
import '../../../data/repositories/super_admin_repository.dart';
import '../../../services/session_service.dart';
import '../../../models/super_admin_users_api_model.dart';

class SuperAdminUsersViewModel extends ChangeNotifier {
  final SuperAdminRepository _repository = SuperAdminRepository();
  final SessionService _sessionService = SessionService();

  bool isLoading = false;
  String searchQuery = '';
  String roleFilter = 'All';

  List<SuperAdminUser> _allUsers = [];

  List<SuperAdminUser> get filteredUsers {
    return _allUsers.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            user.email.toLowerCase().contains(searchQuery.toLowerCase());
      
      final mappedRole = _mapRoleFilter(user.userType);
      final matchesRole = roleFilter == 'All' || 
                          mappedRole.toLowerCase() == roleFilter.toLowerCase();

      return matchesSearch && matchesRole;
    }).toList();
  }

  String _mapRoleFilter(String userType) {
    switch (userType.toLowerCase()) {
      case 'workshop_owner':
      case 'manager':
        return 'Manager';
      case 'technician':
      case 'workshop_technician':
        return 'Technician';
      case 'cashier':
      case 'workshop_cashier':
        return 'Cashier';
      case 'support':
      case 'corporate_user':
        return 'Support';
      default:
        return 'Support';
    }
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    
    try {
      final token = await _sessionService.getToken(role: 'super_admin');
      if (token != null) {
        final response = await _repository.getUsers(token);
        if (response.success) {
          _allUsers = response.users;
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

  void setRoleFilter(String role) {
    roleFilter = role;
    notifyListeners();
  }

  void deleteUser(String id) {
    _allUsers.removeWhere((u) => u.id == id);
    notifyListeners();
  }
}
