import 'package:flutter/material.dart';
import '../../../utils/toast_service.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../models/workshop_owner_models.dart';
import '../PurchaseInvoices/purchase_invoices_view_model.dart';

class SuppliersViewModel extends ChangeNotifier {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController vatNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController openingBalanceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // ── Main "Suppliers" tab state ───────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _loadError;
  String? get loadError => _loadError;

  SupplierStatsResponse? _stats;
  SupplierStatsResponse? get stats => _stats;

  List<Supplier> _suppliersList = [];
  List<Supplier> get suppliersList => _suppliersList;

  String? _currencyCode;
  String? get currencyCode => _currencyCode;

  /// Same entity + tax-invoice view as Purchase Invoices screen / web.
  final List<PurchaseInvoiceEntity> _purchaseInvoices = [];
  List<PurchaseInvoiceEntity> get purchaseInvoices =>
      List.unmodifiable(_purchaseInvoices);

  // ── "Add Supplier" picker state (registered suppliers) ──────────────────
  bool _isRegisteredLoading = false;
  bool get isRegisteredLoading => _isRegisteredLoading;

  String? _registeredError;
  String? get registeredError => _registeredError;

  List<RegisteredSupplier> _registeredSuppliers = [];
  List<RegisteredSupplier> get registeredSuppliers => _registeredSuppliers;

  bool _registeredLoadedOnce = false;

  SuppliersViewModel({
    required this.ownerRepository,
    required this.sessionService,
  });

  // ───────────────────────────────────────────────────────────────────────
  // Main tab load
  // ───────────────────────────────────────────────────────────────────────

  Future<void> initData() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token != null) {
        // Stats + suppliers + purchase invoices fetched together — one
        // round-trip batch instead of sequential awaits, important on
        // slow networks. Stats and invoices failures are non-fatal
        // (caught individually) so a hiccup on either never blocks the
        // supplier list from showing.
        final statsFuture = ownerRepository.getSupplierStats(token).catchError((_) => null);
        final suppliersFuture = ownerRepository.getWorkshopSuppliers(token, limit: 500);
        final invoicesFuture = _fetchPurchaseInvoices(token);

        final statsRaw = await statsFuture;
        if (statsRaw != null) {
          _stats = SupplierStatsResponse.fromJson(statsRaw as Map<String, dynamic>);
        }

        final suppliersResp = await suppliersFuture;
        _currencyCode = suppliersResp.currencyCode;
        // Map RegisteredSupplier (rich API shape) -> Supplier (the existing
        // UI model already used by SuppliersTab) so the rest of the screen
        // doesn't need to change.
        // NOTE: built via Supplier.fromJson (not a direct constructor call)
        // since this VM doesn't have visibility into Supplier's exact
        // constructor signature — fromJson is the one path every other
        // call site in owner_repository.dart already relies on, so it's
        // guaranteed compatible. We re-shape the richer API payload into
        // the same JSON keys Supplier.fromJson already expects.
        _suppliersList = suppliersResp.suppliers
            .map((r) => Supplier.fromJson({
          'id': r.id,
          'name': r.name,
          'category': 'Supplier',
          'mobile': r.mobile,
          'email': r.email,
          'address': r.address,
          'vatNumber': r.vatId,
          'crNumber': r.crNumber,
          'contactPerson': r.contactPerson,
          'status': r.isActive ? 'active' : 'inactive',
          'outstanding': r.outstanding,
        }))
            .toList();

        final invoices = await invoicesFuture;
        _purchaseInvoices
          ..clear()
          ..addAll(invoices);
      }
    } catch (e) {
      // Keep screen usable even if a call fails — only show a hard error
      // state if we ended up with nothing to display at all.
      if (_suppliersList.isEmpty) {
        _loadError = 'Could not load suppliers. Pull down to retry.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Purchase History tab — real data from local + supplier-affiliated
  // purchase invoice endpoints (GET /workshop-staff/purchase-invoices and
  // GET /workshop-staff/supplier-purchase-invoices).
  // ───────────────────────────────────────────────────────────────────────

  /// Fetches both invoice sources in parallel into [PurchaseInvoiceEntity]
  /// (same parser as Purchase Invoices / web tax view), newest first.
  Future<List<PurchaseInvoiceEntity>> _fetchPurchaseInvoices(
      String token) async {
    final results = await Future.wait([
      ownerRepository
          .getLocalPurchaseInvoices(token)
          .catchError((_) => <Map<String, dynamic>>[]),
      ownerRepository
          .getSupplierPurchaseInvoices(token)
          .catchError((_) => <Map<String, dynamic>>[]),
    ]);

    final localList = results[0]
        .map(PurchaseInvoiceEntity.fromLocalJson)
        .toList();
    final supplierList = results[1]
        .map(PurchaseInvoiceEntity.fromSupplierJson)
        .toList();

    final combined = [...localList, ...supplierList]
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return combined;
  }

  Future<void> refresh() => initData();

  // ───────────────────────────────────────────────────────────────────────
  // Default branch (used to pre-select branch when opening "New Purchase
  // Invoice" straight from a supplier card) — cached after first lookup so
  // repeated taps on different supplier cards don't each pay for a fresh
  // session read.
  // ───────────────────────────────────────────────────────────────────────

  String? _cachedDefaultBranchId;

  Future<String?> getDefaultBranchId() async {
    if (_cachedDefaultBranchId != null) return _cachedDefaultBranchId;
    final user = await sessionService.getUser(role: 'owner');
    _cachedDefaultBranchId = user?.branchId;
    return _cachedDefaultBranchId;
  }

  // ───────────────────────────────────────────────────────────────────────
  // "Add Supplier" picker — registered suppliers list
  // ───────────────────────────────────────────────────────────────────────

  /// Loads the full platform supplier registry for the picker. Cached for
  /// the lifetime of this VM (cleared by [refreshRegisteredSuppliers]) so
  /// reopening the dialog doesn't re-hit the network every time — important
  /// on slow connections and low-memory devices.
  Future<void> loadRegisteredSuppliers({bool force = false}) async {
    if (_registeredLoadedOnce && !force) return;
    if (_isRegisteredLoading) return;

    _isRegisteredLoading = true;
    _registeredError = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final resp = await ownerRepository.getRegisteredSuppliers(token, limit: 500);
      _registeredSuppliers = resp.suppliers;
      _registeredLoadedOnce = true;
    } catch (e) {
      _registeredError = 'Could not load suppliers. Check your connection and try again.';
    } finally {
      _isRegisteredLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRegisteredSuppliers() => loadRegisteredSuppliers(force: true);

  /// Links the given supplier IDs to this workshop, then refreshes both the
  /// registered list (to flip isLinkedToWorkshop) and the main suppliers tab
  /// list in the background. Returns true on success.
  Future<bool> linkSelectedSuppliers(BuildContext context, Set<String> supplierIds) async {
    if (supplierIds.isEmpty) return false;

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final resp = await ownerRepository.linkSuppliers(supplierIds.toList(), token);

      if (context.mounted) {
        ToastService.showSuccess(
          context,
          resp.linkedCount == 1
              ? 'Supplier linked successfully'
              : '${resp.linkedCount} suppliers linked successfully',
        );
      }

      // Refresh in the background so closing the dialog feels instant.
      unawaited(refreshRegisteredSuppliers());
      unawaited(initData());
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to link supplier(s). Please try again.');
      }
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Workshop-only (local) supplier creation
  // ───────────────────────────────────────────────────────────────────────

  void clearForm() {
    nameController.clear();
    vatNumberController.clear();
    emailController.clear();
    mobileController.clear();
    addressController.clear();
    openingBalanceController.clear();
    passwordController.clear();
    notesController.clear();
  }

  /// Creates a workshop-only vendor (no supplier-portal login) via
  /// POST /workshop-staff/supplier/create with workshopLocalOnly: true.
  Future<bool> submitWorkshopOnlySupplier(BuildContext context) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ToastService.showError(context, 'Supplier name is required');
      return false;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      await ownerRepository.createWorkshopOnlySupplier(
        token,
        name: name,
        mobile: mobileController.text.trim(),
        address: addressController.text.trim(),
        vatId: vatNumberController.text.trim(),
        notes: notesController.text.trim(),
      );

      if (context.mounted) {
        ToastService.showSuccess(context, 'Supplier added for this workshop');
        clearForm();
        Navigator.pop(context);
        unawaited(initData());
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to add supplier. Please try again.');
      }
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // Kept for any older call sites still referencing the previous flow name.
  Future<void> submitSupplierForm(BuildContext context) => submitWorkshopOnlySupplier(context);

  // ───────────────────────────────────────────────────────────────────────
  // Purchase order (unchanged)
  // ───────────────────────────────────────────────────────────────────────

  Future<void> submitPurchaseOrder(
      BuildContext context, {
        required Supplier supplier,
        required List<Map<String, dynamic>> items,
        required String defaultBranchId,
      }) async {
    if (items.isEmpty) {
      ToastService.showError(context, 'Please add at least one item');
      return;
    }

    for (final item in items) {
      final name = item['name']?.toString().trim() ?? '';
      final qty = double.tryParse(item['qty']?.toString() ?? '') ?? 0;
      final price = double.tryParse(item['price']?.toString() ?? '') ?? 0;
      if (name.isEmpty || qty <= 0 || price <= 0) {
        ToastService.showError(context, 'Please fill all item details properly');
        return;
      }
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      final user = await sessionService.getUser(role: 'owner');
      if (token == null || user == null) throw Exception('Session invalid');

      final branchId = user.branchId ?? defaultBranchId;
      final formattedItems = items
          .map((e) => {
        'productName': e['name'].toString().trim(),
        'qty': double.tryParse(e['qty'].toString().trim()) ?? 0,
        'unitPrice': double.tryParse(e['price'].toString().trim()) ?? 0.0,
      })
          .toList();

      await ownerRepository.createPurchaseOrder({
        'supplierId': supplier.id,
        'branchId': branchId,
        'items': formattedItems,
      }, token);

      // Refresh history so the new row opens with the full tax-invoice entity.
      final invoices = await _fetchPurchaseInvoices(token);
      _purchaseInvoices
        ..clear()
        ..addAll(invoices);

      if (context.mounted) {
        ToastService.showSuccess(context, 'Purchase order created successfully');
        Navigator.pop(context);
        await initData();
      }
    } catch (_) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create purchase order');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    vatNumberController.dispose();
    emailController.dispose();
    mobileController.dispose();
    addressController.dispose();
    openingBalanceController.dispose();
    passwordController.dispose();
    notesController.dispose();
    super.dispose();
  }
}

/// Lightweight no-op awaiter so we can intentionally fire-and-forget a
/// refresh without blocking the calling action on it (keeps "Add" / "Link"
/// actions feeling instant even on slow networks, while still keeping the
/// list eventually-consistent).
void unawaited(Future<void> future) {
  // ignore: body_might_complete_normally_catch_error
  future.catchError((_) {});
}