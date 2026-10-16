import 'package:flutter/material.dart';
import '../../../models/super_admin_corporate_customers_api_model.dart';
import '../../../data/repositories/super_admin_repository.dart';
import '../../../services/session_service.dart';

class SuperAdminCorporateViewModel extends ChangeNotifier {
  final SuperAdminRepository _repository = SuperAdminRepository();
  final SessionService _sessionService = SessionService();

  bool isLoading = false;
  String searchQuery = '';
  String statusFilter = 'All';
  String? errorMessage;

  List<SuperAdminCorporateClient> _allClients = [];

  List<SuperAdminCorporateClient> get filteredClients {
    return _allClients.where((client) {
      final matchesSearch = client.companyName.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            client.id.toLowerCase().contains(searchQuery.toLowerCase());
      
      final String clientStatusString = client.isActive ? 'Active' : 'Inactive';
      final matchesStatus = statusFilter == 'All' || 
                            clientStatusString.toLowerCase() == statusFilter.toLowerCase();
                            
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _sessionService.getToken(role: 'admin');
      if (token == null) throw Exception('Authentication token not found');

      final response = await _repository.getCorporateClients(token);
      if (response.success) {
        _allClients = response.clients;
      } else {
        errorMessage = 'Failed to load corporate clients';
      }
    } catch (e) {
      errorMessage = _extractErrorMessage(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(String error) {
    String clean = error;
    if (clean.startsWith('Exception: ')) clean = clean.substring(11);
    if (clean.startsWith('Error: ')) clean = clean.substring(7);
    return clean;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    statusFilter = status;
    notifyListeners();
  }

  void deleteClient(String id) {
    _allClients.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
