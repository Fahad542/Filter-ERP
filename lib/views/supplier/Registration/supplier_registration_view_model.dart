import 'package:flutter/material.dart';

class SupplierRegistrationViewModel extends ChangeNotifier {
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController tradeLicenseController = TextEditingController();
  final TextEditingController vatIdController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityDistrictController = TextEditingController();
  final TextEditingController ibanController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  bool _isInternalWarehouse = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isInternalWarehouse => _isInternalWarehouse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setInternalWarehouse(bool value) {
    _isInternalWarehouse = value;
    notifyListeners();
  }

  Future<bool> register() async {
    if (companyNameController.text.trim().isEmpty) {
      _errorMessage = 'Please enter company name';
      notifyListeners();
      return false;
    }
    if (tradeLicenseController.text.trim().isEmpty) {
      _errorMessage = 'Please enter trade license / CR number';
      notifyListeners();
      return false;
    }
    if (vatIdController.text.trim().isEmpty) {
      _errorMessage = 'Please enter VAT ID';
      notifyListeners();
      return false;
    }
    if (contactPersonController.text.trim().isEmpty) {
      _errorMessage = 'Please enter contact person name';
      notifyListeners();
      return false;
    }
    if (mobileController.text.trim().isEmpty) {
      _errorMessage = 'Please enter mobile number';
      notifyListeners();
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _errorMessage = 'Please enter email';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void detectGps() {
    // Stub: could integrate geolocator
    streetController.text = 'Street (GPS placeholder)';
    cityDistrictController.text = 'City (GPS placeholder)';
    notifyListeners();
  }

  @override
  void dispose() {
    companyNameController.dispose();
    tradeLicenseController.dispose();
    vatIdController.dispose();
    contactPersonController.dispose();
    mobileController.dispose();
    emailController.dispose();
    streetController.dispose();
    cityDistrictController.dispose();
    ibanController.dispose();
    bankNameController.dispose();
    super.dispose();
  }
}
