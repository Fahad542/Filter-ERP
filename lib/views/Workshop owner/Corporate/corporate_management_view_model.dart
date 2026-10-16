import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/toast_service.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../l10n/app_localizations.dart';

class ReferralOption {
  final String id;
  final String name;
  final String category;

  ReferralOption({
    required this.id,
    required this.name,
    required this.category,
  });

  factory ReferralOption.fromJson(Map<String, dynamic> json) {
    return ReferralOption(
      id: json['id']?.toString() ?? '',
      name: (json['fullName'] ?? json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
    );
  }
}

class CorporateManagementViewModel extends ChangeNotifier {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;

  // ── Create form controllers ──
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController vatNumberController = TextEditingController();
  final TextEditingController contactNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController referralIdController = TextEditingController();

  // ── Edit form controllers ──
  final TextEditingController editCompanyNameController = TextEditingController();
  final TextEditingController editCustomerNameController = TextEditingController();
  final TextEditingController editMobileController = TextEditingController();
  final TextEditingController editTaxIdController = TextEditingController();
  final TextEditingController editCreditLimitController = TextEditingController();
  final TextEditingController editAddressController = TextEditingController();
  final TextEditingController editContactPersonController = TextEditingController();
  String? _editingCorporateId;
  String? get editingCorporateId => _editingCorporateId;
  String _editStatus = 'active';
  String get editStatus => _editStatus;
  final Set<String> _editSelectedBranchIds = <String>{};
  List<String> get editSelectedBranchIds => _editSelectedBranchIds.toList();

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController userPasswordController = TextEditingController();

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  bool _isListLoading = false;
  bool get isListLoading => _isListLoading;

  List<CorporateCustomer> _corporateCustomers = [];
  List<CorporateCustomer> get corporateCustomers => _corporateCustomers;

  List<Branch> _branches = [];
  List<Branch> get branches => _branches;
  final Set<String> _selectedBranchIds = <String>{};
  List<String> get selectedBranchIds => _selectedBranchIds.toList();

  List<ReferralOption> _referrals = [];
  List<ReferralOption> get referrals => _referrals;
  String? _selectedReferralId;
  String? get selectedReferralId => _selectedReferralId;

  CorporateManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
  }) {
    Future.microtask(_init);
  }

  Future<void> _init() async {
    _isListLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token != null) {
        final response = await ownerRepository.getCorporateCustomers(token);
        if (response['success'] == true && response['corporateCustomers'] != null) {
          _corporateCustomers = (response['corporateCustomers'] as List)
              .map((e) => CorporateCustomer.fromJson(e))
              .toList();
        }
        await _loadBranches(token);
        await _loadReferrals(token);
      }
    } catch (e) {
    }

    _isListLoading = false;
    notifyListeners();
  }

  void clearForm() {
    companyNameController.clear();
    vatNumberController.clear();
    contactNameController.clear();
    mobileController.clear();
    emailController.clear();
    passwordController.clear();
    referralIdController.clear();
    _selectedBranchIds.clear();
    _selectedReferralId = _referrals.isNotEmpty ? _referrals.first.id : null;

    userNameController.clear();
    userEmailController.clear();
    userPasswordController.clear();
  }

  Future<void> _loadBranches(String token) async {
    final branchResponse = await ownerRepository.getBranches(token);
    if (branchResponse is! Map<String, dynamic>) return;

    final dynamic rawBranches = branchResponse['branches'] ?? branchResponse['data'];
    if (rawBranches is List) {
      _branches = rawBranches
          .whereType<Map<String, dynamic>>()
          .map(Branch.fromJson)
          .toList();
    }
  }

  Future<void> _loadReferrals(String token) async {
    final referralsResponse = await ownerRepository.getReferrers(token);
    if (referralsResponse is! Map<String, dynamic>) return;

    final dynamic rawReferrers = referralsResponse['referrers'] ?? referralsResponse['data'];
    if (rawReferrers is List) {
      _referrals = rawReferrers
          .whereType<Map<String, dynamic>>()
          .map(ReferralOption.fromJson)
          .where((r) => r.id.isNotEmpty)
          .toList();
      if (_selectedReferralId == null && _referrals.isNotEmpty) {
        _selectedReferralId = _referrals.first.id;
      }
    }
  }

  void setSelectedReferralId(String? id) {
    _selectedReferralId = id;
    notifyListeners();
  }

  void toggleBranchSelection(String branchId) {
    if (_selectedBranchIds.contains(branchId)) {
      _selectedBranchIds.remove(branchId);
    } else {
      _selectedBranchIds.add(branchId);
    }
    notifyListeners();
  }

  Future<void> submitCorporateForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (companyNameController.text.trim().isEmpty ||
        contactNameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        vatNumberController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ToastService.showError(context, l10n.corporateValidationRequired);
      return;
    }
    if (_selectedBranchIds.isEmpty) {
      ToastService.showError(context, l10n.corporateValidationBranch);
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final referralId = referralIdController.text.trim().isNotEmpty
          ? referralIdController.text.trim()
          : (_selectedReferralId ?? '1');
      final data = <String, dynamic>{
        'companyName': companyNameController.text.trim(),
        'vatNumber': vatNumberController.text.trim(),
        'contactPerson': contactNameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'selectedStoreIds':
        _selectedBranchIds.map((id) => id.toString()).toList(),
        'referralId': referralId,
        'referrerId': referralId,
        'mobile': mobileController.text.trim(),
      };

      await ownerRepository.createCorporateAccount(data, token);

      if (context.mounted) {
        ToastService.showSuccess(context, l10n.corporateCreateSuccess);
        clearForm();
        Navigator.pop(context);
        _init();
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, l10n.corporateCreateError);
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitCorporateUserForm(BuildContext context, String corporateAccountId) async {
    final l10n = AppLocalizations.of(context)!;

    if (userNameController.text.trim().isEmpty ||
        userEmailController.text.trim().isEmpty ||
        userPasswordController.text.trim().isEmpty) {
      ToastService.showError(context, l10n.corporateValidationRequired);
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        'name': userNameController.text.trim(),
        'email': userEmailController.text.trim(),
        'password': userPasswordController.text.trim(),
        'corporateAccountId': corporateAccountId,
      };

      await ownerRepository.createCorporateUser(data, token);

      if (context.mounted) {
        ToastService.showSuccess(context, l10n.corporateUserCreateSuccess);
        clearForm();
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, l10n.corporateUserCreateError);
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── Edit Corporate Account ──
  void setEditCorporate(CorporateCustomer customer) {
    _editingCorporateId = customer.id;
    editCompanyNameController.text = customer.companyName;
    editCustomerNameController.text = customer.contactName;
    editMobileController.text = customer.mobile;
    editTaxIdController.text = customer.vatNumber;
    editCreditLimitController.text =
    customer.creditLimit > 0 ? customer.creditLimit.toStringAsFixed(0) : '';
    editAddressController.text = customer.address;
    editContactPersonController.text = customer.contactPerson;
    _editStatus = customer.status.isEmpty ? 'active' : customer.status;
    _editSelectedBranchIds
      ..clear()
      ..addAll(customer.selectedBranchIds);
    notifyListeners();
  }

  void setEditStatus(String status) {
    _editStatus = status;
    notifyListeners();
  }

  void toggleEditBranchSelection(String branchId) {
    if (_editSelectedBranchIds.contains(branchId)) {
      _editSelectedBranchIds.remove(branchId);
    } else {
      _editSelectedBranchIds.add(branchId);
    }
    notifyListeners();
  }

  Future<void> submitEditCorporateForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (_editingCorporateId == null) return;
    if (editCompanyNameController.text.trim().isEmpty) {
      ToastService.showError(context, l10n.corporateValidationCompanyName);
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token');

      final data = <String, dynamic>{
        if (editCompanyNameController.text.trim().isNotEmpty)
          'companyName': editCompanyNameController.text.trim(),
        if (editCustomerNameController.text.trim().isNotEmpty)
          'customerName': editCustomerNameController.text.trim(),
        if (editMobileController.text.trim().isNotEmpty)
          'mobile': editMobileController.text.trim(),
        if (editTaxIdController.text.trim().isNotEmpty)
          'taxId': editTaxIdController.text.trim(),
        if (editCreditLimitController.text.trim().isNotEmpty)
          'creditLimit':
          double.tryParse(editCreditLimitController.text.trim()) ?? 0,
        if (editAddressController.text.trim().isNotEmpty)
          'address': editAddressController.text.trim(),
        if (editContactPersonController.text.trim().isNotEmpty)
          'contactPerson': editContactPersonController.text.trim(),
        'status': _editStatus,
        if (_editSelectedBranchIds.isNotEmpty)
          'selectedBranchIds': _editSelectedBranchIds.toList(),
      };

      await ownerRepository.updateCorporateAccount(token, _editingCorporateId!, data);

      if (context.mounted) {
        ToastService.showSuccess(context, l10n.corporateUpdateSuccess);
        _editingCorporateId = null;
        Navigator.pop(context);
        _init();
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, l10n.corporateUpdateError);
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    vatNumberController.dispose();
    contactNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    referralIdController.dispose();
    editCompanyNameController.dispose();
    editCustomerNameController.dispose();
    editMobileController.dispose();
    editTaxIdController.dispose();
    editCreditLimitController.dispose();
    editAddressController.dispose();
    editContactPersonController.dispose();
    userNameController.dispose();
    userEmailController.dispose();
    userPasswordController.dispose();
    super.dispose();
  }
}