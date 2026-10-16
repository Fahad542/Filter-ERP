import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/session_service.dart';
import '../../../data/repositories/owner_repository.dart';

enum OwnerSettingsState { idle, loading, saving, success, error }

class OwnerSettingsViewModel extends ChangeNotifier {
  final OwnerRepository _repository = OwnerRepository();

  // ─── State ──────────────────────────────────────────────────────────────────

  OwnerSettingsState _state = OwnerSettingsState.idle;
  OwnerSettingsState get state => _state;

  WorkshopProfile? _profile;
  WorkshopProfile? get profile => _profile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  // ─── Notification preferences (local only) ──────────────────────────────────

  bool notifications = true;
  bool emailAlerts = true;
  bool stockAlerts = true;
  bool lockerAlerts = true;

  // ─── Editable field controllers ─────────────────────────────────────────────

  late TextEditingController workshopNameController;
  late TextEditingController ownerNameController;
  late TextEditingController mobileController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  // ─── Init ───────────────────────────────────────────────────────────────────

  OwnerSettingsViewModel() {
    workshopNameController = TextEditingController();
    ownerNameController = TextEditingController();
    mobileController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
  }

  // ─── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _setState(OwnerSettingsState.loading);
    try {
      final session = SessionService();
      final token = await session.getToken(role: 'owner');
      if (token == null) throw Exception('Session expired');

      final response = await _repository.getWorkshopProfile(token);
      if (response != null && response['success'] == true) {
        _profile = WorkshopProfile.fromJson(response);
        _populateControllers();
        _setState(OwnerSettingsState.idle);
      } else {
        throw Exception(response?['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setState(OwnerSettingsState.error);
    }
  }

  void _populateControllers() {
    if (_profile == null) return;
    workshopNameController.text = _profile!.name;
    ownerNameController.text = _profile!.ownerName;
    mobileController.text = _profile!.mobile;
    emailController.text = _profile!.email;
    addressController.text = _profile!.address;
  }

  // ─── Edit ───────────────────────────────────────────────────────────────────

  void startEditing() {
    _isEditing = true;
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    _populateControllers(); // reset to last saved values
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    _setState(OwnerSettingsState.saving);
    try {
      final session = SessionService();
      final token = await session.getToken(role: 'owner');
      if (token == null) throw Exception('Session expired');

      final data = {
        'name': workshopNameController.text.trim(),
        'ownerName': ownerNameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
      };

      final response = await _repository.updateWorkshopProfile(token, data);
      if (response != null && response['success'] == true) {
        _profile = _profile?.copyWith(
          name: data['name'],
          ownerName: data['ownerName'],
          mobile: data['mobile'],
          email: data['email'],
          address: data['address'],
        );
        _isEditing = false;
        _setState(OwnerSettingsState.success);
        return true;
      } else {
        throw Exception(response?['message'] ?? 'Failed to save profile');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setState(OwnerSettingsState.error);
      return false;
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _setState(OwnerSettingsState s) {
    _state = s;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == OwnerSettingsState.error) {
      _state = OwnerSettingsState.idle;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    workshopNameController.dispose();
    ownerNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
