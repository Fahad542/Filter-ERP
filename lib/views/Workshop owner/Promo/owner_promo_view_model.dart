import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../utils/toast_service.dart';

class OwnerPromoViewModel extends ChangeNotifier {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  List<PromoCode> _promoCodes = [];
  List<PromoCode> get promoCodes => _promoCodes;

  // Controllers for creating a promo code
  final codeController = TextEditingController();
  final discountValueController = TextEditingController();
  final validFromController = TextEditingController();
  final validToController = TextEditingController();
  final usageLimitController = TextEditingController();
  final minOrderAmountController = TextEditingController();
  final descriptionController = TextEditingController();
  String _discountType = 'fixed'; // 'fixed' or 'percent'
  String get discountType => _discountType;

  // Status
  String _status = 'active'; // 'active' or 'inactive'
  String get status => _status;

  // Branches: 'all' or 'selected'
  String _branchesMode = 'all';
  String get branchesMode => _branchesMode;
  final Set<String> selectedBranchIds = {};

  // Products: 'all' | 'specific' | 'none'
  String _productsMode = 'all';
  String get productsMode => _productsMode;
  final Set<String> selectedProductIds = {};

  // Services: 'all' | 'specific' | 'none'
  String _servicesMode = 'all';
  String get servicesMode => _servicesMode;
  final Set<String> selectedServiceIds = {};

  String? _editingPromoId;
  bool get isEditing => _editingPromoId != null;

  OwnerPromoViewModel({
    required this.ownerRepository,
    required this.sessionService,
  }) {
    fetchPromoCodes();
  }

  void setDiscountType(String type) {
    _discountType = type;
    notifyListeners();
  }

  void setStatus(String status) {
    _status = status;
    notifyListeners();
  }

  void setBranchesMode(String mode) {
    _branchesMode = mode;
    notifyListeners();
  }

  void setProductsMode(String mode) {
    _productsMode = mode;
    notifyListeners();
  }

  void setServicesMode(String mode) {
    _servicesMode = mode;
    notifyListeners();
  }

  void toggleBranch(String id) {
    if (selectedBranchIds.contains(id)) {
      selectedBranchIds.remove(id);
    } else {
      selectedBranchIds.add(id);
    }
    notifyListeners();
  }

  void toggleProduct(String id) {
    if (selectedProductIds.contains(id)) {
      selectedProductIds.remove(id);
    } else {
      selectedProductIds.add(id);
    }
    notifyListeners();
  }

  void toggleService(String id) {
    if (selectedServiceIds.contains(id)) {
      selectedServiceIds.remove(id);
    } else {
      selectedServiceIds.add(id);
    }
    notifyListeners();
  }

  Future<void> fetchPromoCodes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final response = await ownerRepository.getPromoCodes(token);
      if (response != null && response['success'] == true) {
        final parsed = PromoCodesResponse.fromJson(response);
        _promoCodes = parsed.promoCodes;
      }
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEditPromoCode(PromoCode? p) {
    if (p == null) {
      _editingPromoId = null;
      clearControllers();
    } else {
      _editingPromoId = p.id;
      codeController.text = p.code;
      _discountType = p.discountType;
      discountValueController.text = p.discountValue.toString();
      validFromController.text = p.validFrom.split('T').first;
      validToController.text = p.validTo.split('T').first;
      usageLimitController.text = p.usageLimit.toString();
      minOrderAmountController.text = p.minOrderAmount.toString();
      descriptionController.text = p.description ?? '';
      _status = p.isActive ? 'active' : 'inactive';

      // Reset selection state - actual branch/product/service ids would be
      // populated here from the promo object if the model exposes them.
      _branchesMode = 'all';
      selectedBranchIds.clear();
      _productsMode = 'all';
      selectedProductIds.clear();
      _servicesMode = 'all';
      selectedServiceIds.clear();
    }
    notifyListeners();
  }

  void clearControllers() {
    codeController.clear();
    discountValueController.clear();
    validFromController.clear();
    validToController.clear();
    usageLimitController.clear();
    minOrderAmountController.clear();
    descriptionController.clear();
    _discountType = 'fixed';
    _status = 'active';
    _branchesMode = 'all';
    selectedBranchIds.clear();
    _productsMode = 'all';
    selectedProductIds.clear();
    _servicesMode = 'all';
    selectedServiceIds.clear();
  }

  Future<void> submitPromoCode(BuildContext context) async {
    if (codeController.text.trim().isEmpty || discountValueController.text.trim().isEmpty) {
      ToastService.showInfo(context, 'Please fill required fields (Code, Value)');
      return;
    }

    if (validFromController.text.trim().isEmpty || validToController.text.trim().isEmpty) {
      ToastService.showInfo(context, 'Please select Valid From and Valid To dates');
      return;
    }

    if (_branchesMode == 'selected' && selectedBranchIds.isEmpty) {
      ToastService.showInfo(context, 'Please select at least one branch');
      return;
    }

    if (_productsMode == 'specific' && selectedProductIds.isEmpty) {
      ToastService.showInfo(context, 'Please select at least one product or change Products scope');
      return;
    }

    if (_servicesMode == 'specific' && selectedServiceIds.isEmpty) {
      ToastService.showInfo(context, 'Please select at least one service or change Services scope');
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        "code": codeController.text.trim(),
        "discountType": _discountType,
        "discountValue": double.tryParse(discountValueController.text) ?? 0,
        "validFrom": validFromController.text.trim(),
        "validTo": validToController.text.trim(),
        "usageLimit": int.tryParse(usageLimitController.text) ?? 100,
        "minOrderAmount": double.tryParse(minOrderAmountController.text) ?? 0,
        "description": descriptionController.text.trim(),
        "isActive": _status == 'active',
        "branchesMode": _branchesMode,
        "branchIds": selectedBranchIds.toList(),
        "productsMode": _productsMode,
        "productIds": selectedProductIds.toList(),
        "servicesMode": _servicesMode,
        "serviceIds": selectedServiceIds.toList(),
      };

      final response = _editingPromoId == null
          ? await ownerRepository.createPromoCode(token, data)
          : await ownerRepository.updatePromoCode(token, _editingPromoId!, data);

      if (response != null && response['success'] == true) {
        ToastService.showSuccess(
            context,
            _editingPromoId == null ? 'Promo Code created successfully!' : 'Promo Code updated successfully!'
        );
        Navigator.pop(context); // Close sheet

        // Clear fields
        setEditPromoCode(null);

        // Refresh list
        fetchPromoCodes();
      } else {
        throw Exception(response?['message'] ?? 'Failed to process promo code');
      }
    } catch (e) {
      ToastService.showError(context, e.toString());
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePromoCode(BuildContext context, String id) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final response = await ownerRepository.deletePromoCode(token, id);
      if (response != null && response['success'] == true) {
        ToastService.showSuccess(context, 'Promo Code deleted successfully!');
        fetchPromoCodes();
      } else {
        throw Exception(response?['message'] ?? 'Failed to delete promo code');
      }
    } catch (e) {
      ToastService.showError(context, e.toString());
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    discountValueController.dispose();
    validFromController.dispose();
    validToController.dispose();
    usageLimitController.dispose();
    minOrderAmountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}