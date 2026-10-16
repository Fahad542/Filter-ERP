import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/google_places_service.dart';

// ---------------------------------------------------------------------------
// OwnerRegistrationViewModel
//
// Pure logic — no UI strings here. All user-visible strings are in the View
// (owner_registration_view.dart) via AppLocalizations.
//
// NOTE: The Google Places API key should be injected via environment config
// or a secrets service rather than hardcoded in source code.
// ---------------------------------------------------------------------------

class OwnerRegistrationViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final SessionService sessionService;

  OwnerRegistrationViewModel({
    required this.authRepository,
    required this.sessionService,
  });

  // Google Places service — API key should come from your env/config.
  final GooglePlacesService googlePlacesService =
  GooglePlacesService(const String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: 'AIzaSyDfxcDdlq5IDIHjpRQKeAHepYIFaSYvVMQ',
  ));

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController workshopNameController = TextEditingController();
  final TextEditingController emailController        = TextEditingController();
  final TextEditingController passwordController     = TextEditingController();
  final TextEditingController ownerNameController    = TextEditingController();
  final TextEditingController mobileController       = TextEditingController();
  final TextEditingController taxIdController        = TextEditingController();
  final TextEditingController addressController      = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  double _gpsLat = 24.7136; // Default: Riyadh
  double _gpsLng = 46.6753;

  bool get isLoading       => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAddressSuggestions(
      String input) async {
    return await googlePlacesService.getSuggestions(input);
  }

  Future<void> onAddressSelected(Map<String, dynamic> selection) async {
    final description = selection['description'] as String;
    addressController.text = description;

    final placeId = selection['place_id'] as String;
    final details = await googlePlacesService.getPlaceDetails(placeId);

    if (details != null) {
      _gpsLat = details['lat'];
      _gpsLng = details['lng'];
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    workshopNameController.clear();
    emailController.clear();
    passwordController.clear();
    ownerNameController.clear();
    mobileController.clear();
    taxIdController.clear();
    addressController.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register() async {
    if (!formKey.currentState!.validate()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.registerWorkshopOwner(
        name: workshopNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        ownerName: ownerNameController.text.trim(),
        mobile: mobileController.text.trim(),
        taxId: taxIdController.text.trim(),
        address: addressController.text.trim(),
        gpsLat: _gpsLat,
        gpsLng: _gpsLng,
      );

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

  @override
  void dispose() {
    workshopNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    ownerNameController.dispose();
    mobileController.dispose();
    taxIdController.dispose();
    addressController.dispose();
    super.dispose();
  }
}