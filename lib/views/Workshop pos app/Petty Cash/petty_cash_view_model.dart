import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/session_service.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../models/petty_cash_model.dart';
import '../../../models/expense_category_model.dart';
import '../../../models/cashier_expense_models.dart';
import '../../../models/department_model.dart';
import '../../../models/purchase_order_models.dart';
import '../../../services/realtime_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../constants/petty_cash_expense_categories.dart';

class PettyCashViewModel extends ChangeNotifier with TranslatableMixin {
  final SessionService sessionService;
  final PosRepository posRepository;

  PettyCashViewModel({
    required this.sessionService,
    required this.posRepository,
  });

  /// Bind from the screen/provider with SettingsViewModel so raw API labels are
  /// re-translated when the app locale changes.
  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  List<ExpenseCategory> _expenseCategories = [];
  List<BranchEmployee> _branchEmployees = [];
  BranchEmployee? _selectedBranchEmployee;
  bool _branchEmployeesLoading = false;

  List<CashierExpenseHistoryEntry> _expenseHistory = [];
  bool _expenseHistoryLoading = false;
  bool _notifyScheduled = false;
  String _expenseHistoryStatusFilter = 'all';
  int _expenseHistoryOffset = 0;
  bool _expenseHistoryHasMore = true;
  static const int _expenseHistoryPageSize = 30;
  DateTime? _expenseHistoryFromDate;
  DateTime? _expenseHistoryToDate;
  String? _expenseHistoryCategoryId;

  // Petty Cash State
  double _pettyCashBalance = 450.0;
  double _lowBalanceThreshold = 100.0;
  bool _requestFundRecommended = false;
  final List<PettyCashExpense> _expenses = [];
  final List<FundRequest> _fundRequests = [];
  bool _isPettyCashLoading = false;
  bool _isExpenseSubmitting = false;
  bool _isRequestSubmitting = false;
  final RealtimeService _realtimeService = RealtimeService();
  bool _realtimeBound = false;

  // Form State
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final requestAmountController = TextEditingController();
  final reasonController = TextEditingController();
  final noCashBillNoController = TextEditingController();
  final noCashOtherSupplierController = TextEditingController();
  final noCashDepartmentController = TextEditingController();
  final noCashAmountController = TextEditingController();
  final noCashRemarksController = TextEditingController();

  ExpenseCategory? _selectedCategory;
  File? _selectedImage;
  final List<File> _noCashImages = [];
  DateTime _noCashDate = DateTime.now();
  PoAffiliatedSupplier? _selectedNoCashSupplier;
  Department? _selectedNoCashDepartment;
  String? _selectedNoCashExpenseType;
  List<PoAffiliatedSupplier> _noCashSuppliers = [];
  List<Department> _noCashDepartments = [];
  bool _noCashSuppliersLoading = false;
  bool _noCashDepartmentsLoading = false;
  bool _isNoCashSubmitting = false;
  bool _isRequestingFunds = false;
  bool _showPendingRequestStatus = false;

  ExpenseCategory? get selectedCategory => _selectedCategory;
  File? get selectedImage => _selectedImage;
  List<File> get noCashImages => List.unmodifiable(_noCashImages);
  DateTime get noCashDate => _noCashDate;
  PoAffiliatedSupplier? get selectedNoCashSupplier => _selectedNoCashSupplier;
  Department? get selectedNoCashDepartment => _selectedNoCashDepartment;
  String? get selectedNoCashExpenseType => _selectedNoCashExpenseType;
  List<PoAffiliatedSupplier> get noCashSuppliers => _noCashSuppliers;
  List<Department> get noCashDepartments => _noCashDepartments;
  bool get noCashSuppliersLoading => _noCashSuppliersLoading;
  bool get noCashDepartmentsLoading => _noCashDepartmentsLoading;
  bool get isNoCashSubmitting => _isNoCashSubmitting;
  bool get isRequestingFunds => _isRequestingFunds;
  bool get showPendingRequestStatus => _showPendingRequestStatus;

  List<ExpenseCategory> get expenseCategories => _expenseCategories;
  List<BranchEmployee> get branchEmployees => _branchEmployees;
  BranchEmployee? get selectedBranchEmployee => _selectedBranchEmployee;
  bool get branchEmployeesLoading => _branchEmployeesLoading;
  List<CashierExpenseHistoryEntry> get expenseHistory => _expenseHistory;
  bool get expenseHistoryLoading => _expenseHistoryLoading;
  String get expenseHistoryStatusFilter => _expenseHistoryStatusFilter;
  bool get expenseHistoryHasMore => _expenseHistoryHasMore;
  DateTime? get expenseHistoryFromDate => _expenseHistoryFromDate;
  DateTime? get expenseHistoryToDate => _expenseHistoryToDate;
  String? get expenseHistoryCategoryId => _expenseHistoryCategoryId;
  bool get isPettyCashLoading => _isPettyCashLoading;
  bool get isExpenseSubmitting => _isExpenseSubmitting;
  bool get isRequestSubmitting => _isRequestSubmitting;
  double get pettyCashBalance => _pettyCashBalance;
  bool get isLowPettyCashBalance => _pettyCashBalance < _lowBalanceThreshold;
  bool get requestFundRecommended => _requestFundRecommended;
  List<PettyCashExpense> get expenses => _expenses;
  List<FundRequest> get fundRequests => _fundRequests;

  Future<void> initPettyCash() async {
    _isPettyCashLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchExpenseCategories(),
        fetchWalletBalance(),
        // Prefetch full branch roster (cashiers, managers, technicians, self)
        // so Salary Advances is not stuck on a stale technicians-only list.
        fetchBranchEmployees(force: true),
      ]);
      await bindRealtime();
    } catch (e) {
    } finally {
      _isPettyCashLoading = false;
      notifyListeners();
    }
  }

  void setCategory(ExpenseCategory? category) {
    _selectedCategory = category;
    _selectedBranchEmployee = null;
    notifyListeners();
    if (category?.requiresEmployeeSelection == true) {
      fetchBranchEmployees(force: true);
    }
  }

  void setBranchEmployee(BranchEmployee? employee) {
    _selectedBranchEmployee = employee;
    notifyListeners();
  }

  void _deferNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  void setExpenseHistoryStatusFilter(String value) {
    if (_expenseHistoryStatusFilter == value) return;
    _expenseHistoryStatusFilter = value;
    fetchExpenseHistory(refresh: true);
  }

  void setExpenseHistoryDateRange({
    DateTime? from,
    DateTime? to,
  }) {
    if (from != null && to != null && from.isAfter(to)) {
      // Keep API contract: from must be <= to.
      _expenseHistoryFromDate = to;
      _expenseHistoryToDate = from;
    } else {
      _expenseHistoryFromDate = from;
      _expenseHistoryToDate = to;
    }
    fetchExpenseHistory(refresh: true);
  }

  void setExpenseHistoryCategoryId(String? categoryId) {
    final next = (categoryId == null || categoryId.trim().isEmpty)
        ? null
        : categoryId.trim();
    if (_expenseHistoryCategoryId == next) return;
    _expenseHistoryCategoryId = next;
    fetchExpenseHistory(refresh: true);
  }

  void clearExpenseHistoryFilters() {
    _expenseHistoryFromDate = null;
    _expenseHistoryToDate = null;
    _expenseHistoryCategoryId = null;
    _expenseHistoryStatusFilter = 'all';
    fetchExpenseHistory(refresh: true);
  }

  Future<void> fetchBranchEmployees({bool force = false}) async {
    if (_branchEmployeesLoading) return;
    if (!force && _branchEmployees.isNotEmpty) return;
    _branchEmployeesLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) return;
      // Full cashier-branch roster: technicians, staff, cashiers (incl. self),
      // managers, locker users — same people as workshop Employees page.
      final res = await posRepository.getExpenseBranchEmployees(token);
      if (res.success) {
        _branchEmployees = List<BranchEmployee>.from(res.employees)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (kDebugMode) {
          debugPrint(
            '[PettyCash] branch employees: ${_branchEmployees.length} '
            '(${_branchEmployees.map((e) => '${e.name}/${e.employeeType ?? '?'}').join(', ')})',
          );
        }
        // Drop selection if it is no longer in the refreshed branch list.
        if (_selectedBranchEmployee != null &&
            !_branchEmployees.any((e) => e.id == _selectedBranchEmployee!.id)) {
          _selectedBranchEmployee = null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PettyCash] branch employees fetch failed: $e');
      }
    } finally {
      _branchEmployeesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpenseHistory({bool refresh = false}) async {
    if (_expenseHistoryLoading) return;
    if (refresh) {
      _expenseHistoryOffset = 0;
      _expenseHistoryHasMore = true;
      _expenseHistory = [];
    }
    if (!_expenseHistoryHasMore && !refresh) return;

    _expenseHistoryLoading = true;
    _deferNotify();
    try {
      final token = await sessionService.getToken();
      if (token == null) return;
      final statusParam =
          _expenseHistoryStatusFilter == 'all' ? null : _expenseHistoryStatusFilter;
      final res = await posRepository.getExpenseHistory(
        token,
        status: statusParam,
        from: _formatDateOnly(_expenseHistoryFromDate),
        to: _formatDateOnly(_expenseHistoryToDate),
        categoryId: _expenseHistoryCategoryId,
        limit: _expenseHistoryPageSize,
        offset: _expenseHistoryOffset,
      );
      if (refresh) {
        _expenseHistory = List<CashierExpenseHistoryEntry>.from(res.items);
      } else {
        _expenseHistory.addAll(res.items);
      }
      _expenseHistoryOffset += res.items.length;
      _expenseHistoryHasMore = res.items.length >= _expenseHistoryPageSize;
    } catch (e) {
    } finally {
      _expenseHistoryLoading = false;
      _deferNotify();
    }
  }

  void setIsRequestingFunds(bool isRequesting) {
    if (_isRequestingFunds == isRequesting) return;
    _isRequestingFunds = isRequesting;
    notifyListeners();
  }

  void setShowPendingRequestStatus(bool show) {
    _showPendingRequestStatus = show;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  void setNoCashDate(DateTime date) {
    _noCashDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setNoCashSupplier(PoAffiliatedSupplier? supplier) {
    _selectedNoCashSupplier = supplier;
    if (supplier != null &&
        noCashOtherSupplierController.text.trim() !=
            supplier.supplierName.trim()) {
      noCashOtherSupplierController.text = supplier.supplierName;
    }
    notifyListeners();
  }

  void onNoCashSupplierNameChanged(String raw) {
    final q = raw.trim().toLowerCase();
    PoAffiliatedSupplier? match;
    if (q.isNotEmpty) {
      for (final s in _noCashSuppliers) {
        if (s.supplierName.trim().toLowerCase() == q) {
          match = s;
          break;
        }
      }
    }
    if (_selectedNoCashSupplier?.supplierId == match?.supplierId) return;
    _selectedNoCashSupplier = match;
    notifyListeners();
  }

  void setNoCashDepartment(Department? department) {
    _selectedNoCashDepartment = department;
    notifyListeners();
  }

  void setNoCashExpenseType(String? type) {
    _selectedNoCashExpenseType = type;
    notifyListeners();
  }

  Future<void> fetchNoCashLookups({bool force = false}) async {
    await Future.wait([
      fetchNoCashSuppliers(force: force),
      fetchNoCashDepartments(force: force),
    ]);
  }

  Future<void> fetchNoCashSuppliers({bool force = false}) async {
    if (_noCashSuppliersLoading) return;
    if (!force && _noCashSuppliers.isNotEmpty) return;
    _noCashSuppliersLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) return;
      _noCashSuppliers = await posRepository.getLocalSuppliers(token);
    } catch (e) {
      _noCashSuppliers = [];
    } finally {
      _noCashSuppliersLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNoCashDepartments({bool force = false}) async {
    if (_noCashDepartmentsLoading) return;
    if (!force && _noCashDepartments.isNotEmpty) return;
    _noCashDepartmentsLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) return;
      _noCashDepartments = await posRepository.getCashierDepartments(token);
    } catch (e) {
      _noCashDepartments = [];
    } finally {
      _noCashDepartmentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNoCashImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final picked = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 70,
      );
      if (picked.isEmpty) return;
      for (final file in picked) {
        if (_noCashImages.length >= 8) break;
        _noCashImages.add(File(file.path));
      }
    } else {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 70,
      );
      if (pickedFile == null) return;
      if (_noCashImages.length >= 8) return;
      _noCashImages.add(File(pickedFile.path));
    }
    notifyListeners();
  }

  void removeNoCashImage(int index) {
    if (index < 0 || index >= _noCashImages.length) return;
    _noCashImages.removeAt(index);
    notifyListeners();
  }

  void clearNoCashForm() {
    noCashBillNoController.clear();
    noCashOtherSupplierController.clear();
    noCashDepartmentController.clear();
    noCashAmountController.clear();
    noCashRemarksController.clear();
    _noCashImages.clear();
    _selectedNoCashSupplier = null;
    _selectedNoCashDepartment = null;
    _selectedNoCashExpenseType = null;
    _noCashDate = DateTime.now();
    notifyListeners();
  }

  Future<bool> submitNoCashAction(Function(String) onError) async {
    final amount = double.tryParse(noCashAmountController.text.trim()) ?? 0;
    if (amount <= 0) {
      onError(await t('Please enter a valid amount'));
      return false;
    }
    if (noCashBillNoController.text.trim().isEmpty) {
      onError(await t('Please enter bill number'));
      return false;
    }
    final supplierName = noCashOtherSupplierController.text.trim();
    if (supplierName.isEmpty) {
      onError(await t('Please select or enter supplier name'));
      return false;
    }
    final departmentName =
        (_selectedNoCashDepartment?.name ?? noCashDepartmentController.text)
            .trim();
    if (departmentName.isEmpty) {
      onError(await t('Please select a department'));
      return false;
    }
    if (_selectedNoCashExpenseType == null ||
        !noCashExpenseTypes.contains(_selectedNoCashExpenseType)) {
      onError(await t('Please select an expense type'));
      return false;
    }
    if (_noCashImages.isEmpty) {
      onError(await t('Please add at least one photo'));
      return false;
    }

    _isNoCashSubmitting = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final response = await posRepository.submitExpense(
        amount: amount,
        description: noCashRemarksController.text.trim(),
        receiptFilePaths: _noCashImages.map((f) => f.path).toList(),
        extraJson: {
          'noCash': true,
          'billNo': noCashBillNoController.text.trim(),
          if (_selectedNoCashSupplier != null)
            'supplierId': _selectedNoCashSupplier!.supplierId,
          'supplierName': supplierName,
          'departmentName': departmentName,
          'expenseType': _selectedNoCashExpenseType,
          'expenseDate': _formatDateOnly(_noCashDate),
          'remarks': noCashRemarksController.text.trim(),
        },
        token: token,
      );
      if (response['success'] == true) {
        clearNoCashForm();
        await fetchWalletBalance();
        return true;
      }
      onError(await t('Failed to submit expense. Try again.'));
      return false;
    } catch (e) {
      onError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _isNoCashSubmitting = false;
      notifyListeners();
    }
  }

  void clearExpenseForm() {
    amountController.clear();
    notesController.clear();
    _selectedCategory = null;
    _selectedBranchEmployee = null;
    _selectedImage = null;
    notifyListeners();
  }

  void clearRequestForm() {
    requestAmountController.clear();
    reasonController.clear();
    notifyListeners();
  }

  Future<bool> submitExpenseAction(Function(String) onError) async {
    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      onError(await t('Please enter a valid amount'));
      return false;
    }
    if (_selectedCategory == null) {
      onError(await t('Please select a category'));
      return false;
    }
    if (_selectedCategory!.requiresEmployeeSelection) {
      if (_selectedBranchEmployee == null) {
        onError(await t('Please select an employee for Salary Advances'));
        return false;
      }
    }

    try {
      final success = await submitExpense(
        amount: amount,
        categoryId: _selectedCategory!.id,
        description: notesController.text,
        employeeId: _selectedCategory!.requiresEmployeeSelection
            ? _selectedBranchEmployee?.id
            : null,
        receiptPath: _selectedImage?.path,
      );

      if (success) {
        clearExpenseForm();
        return true;
      } else {
        onError(await t('Failed to submit expense. Check balance or try again.'));
        return false;
      }
    } catch (e) {
      onError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> submitRequestAction(
    Function(String) onError,
    VoidCallback onSuccess,
  ) async {
    _isRequestSubmitting = true;
    notifyListeners();

    final amount = double.tryParse(requestAmountController.text) ?? 0;
    if (amount <= 0) {
      onError(await t('Please enter a valid amount'));
      _isRequestSubmitting = false;
      notifyListeners();
      return;
    }
    if (reasonController.text.isEmpty) {
      onError(await t('Please enter a reason'));
      _isRequestSubmitting = false;
      notifyListeners();
      return;
    }

    final success = await requestFunds(
      amount: amount,
      reason: reasonController.text,
    );

    if (success) {
      onSuccess();
      clearRequestForm();
      setShowPendingRequestStatus(true);
      await fetchWalletBalance();
    } else {
      onError(await t('Failed to submit fund request'));
    }
    _isRequestSubmitting = false;
    notifyListeners();
  }

  Future<void> fetchExpenseCategories() async {
    try {
      final token = await sessionService.getToken();
      if (token == null) return;

      final response = await posRepository.getExpenseCategories(token);
      if (response.success) {
        _expenseCategories = response.categories;
        notifyListeners();
      }
    } catch (e) {
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final token = await sessionService.getToken();
      if (token == null) return;

      final response = await posRepository.getWalletBalance(token);
      if (response.success) {
        _pettyCashBalance = response.balance;
        _lowBalanceThreshold = response.lowBalanceThreshold;
        _requestFundRecommended = response.requestFundRecommended;
        notifyListeners();
      } else if (response.message.isNotEmpty) {
      }
    } catch (e) {
    }
  }

  Future<bool> submitExpense({
    required double amount,
    required String categoryId,
    required String description,
    String? employeeId,
    String? receiptPath,
  }) async {
    _isExpenseSubmitting = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await posRepository.submitExpense(
        amount: amount,
        categoryId: categoryId,
        description: description,
        employeeId: employeeId,
        receiptFilePath: receiptPath,
        extraJson: (receiptPath == null || receiptPath.isEmpty)
            ? {'proofUrl': ''}
            : null,
        token: token,
      );
      final success = response['success'] == true;
      if (success) {
        await fetchWalletBalance();
        return true;
      }
      return false;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('low balance')) {
        throw Exception('Low balance - request fund first');
      }
      return false;
    } finally {
      _isExpenseSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> requestFunds({
    required double amount,
    required String reason,
  }) async {
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await posRepository.requestPettyCashFund({
        'amount': amount,
        'reason': reason,
      }, token);

      if (response['success'] == true) {
        final request = FundRequest(
          id: response['requestId']?.toString() ??
              'REQ-${DateTime.now().millisecondsSinceEpoch}',
          amount: double.tryParse(response['amount']?.toString() ?? '$amount') ??
              amount,
          reason: reason,
          date: DateTime.now(),
        );
        _fundRequests.add(request);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String? _formatDateOnly(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> bindRealtime() async {
    if (_realtimeBound) return;
    final token = await sessionService.getToken();
    if (token == null || token.isEmpty) return;
    _realtimeService.connect(token);
    _realtimeService.on(
      RealtimeService.eventCashierPettyCashUpdated,
      _onCashierPettyCashUpdated,
    );
    _realtimeBound = true;
  }

  void unbindRealtime() {
    if (!_realtimeBound) return;
    _realtimeService.off(
      RealtimeService.eventCashierPettyCashUpdated,
      _onCashierPettyCashUpdated,
    );
    _realtimeService.disconnect();
    _realtimeBound = false;
  }

  void _onCashierPettyCashUpdated(Map<String, dynamic> _) {
    fetchWalletBalance();
    fetchExpenseHistory(refresh: true);
  }

  @override
  void dispose() {
    unbindRealtime();
    amountController.dispose();
    notesController.dispose();
    requestAmountController.dispose();
    reasonController.dispose();
    noCashBillNoController.dispose();
    noCashOtherSupplierController.dispose();
    noCashDepartmentController.dispose();
    noCashAmountController.dispose();
    noCashRemarksController.dispose();
    super.dispose();
  }
}
