import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../data/network/base_api_service.dart';
import '../../../../data/repositories/pos_repository.dart';
import '../../../../models/create_invoice_model.dart';
import '../../../../models/pos_payment_method.dart';
import '../../../../models/pos_product_model.dart';
import '../../../../models/takeaway_models.dart';
import '../../../../services/session_service.dart';
import '../../../../services/catalog_sync_service.dart';
import '../../../../services/locker_translation_mixin.dart';

class TakeawayCartLine {
  TakeawayCartLine({
    required this.product,
    required this.qty,
    required this.unitPrice,
    this.lineDiscountType,
    this.lineDiscountValue = 0,
  });

  final TakeawayProduct product;
  double qty;
  /// VAT-inclusive unit price.
  double unitPrice;
  String? lineDiscountType;
  double lineDiscountValue;

  /// VAT-exclusive unit price.
  double get unitPriceExclVat =>
      ((unitPrice / 1.15) * 100).roundToDouble() / 100;
}

class TakeawayViewModel extends ChangeNotifier with TranslatableMixin {
  /// Matches [PosProductGridView] live invoice panel (15% VAT on taxable amount).
  static const double liveInvoiceVatRate = 0.15;

  TakeawayViewModel({
    required this.posRepository,
    required this.sessionService,
    required this.catalogSync,
  }) {
    // Keep invoice preview sheet reactive for every field edit.
    vatController.addListener(_onPreviewInputChanged);
    orderDiscountValueController.addListener(_onPreviewInputChanged);
    promoCodeController.addListener(_onPreviewInputChanged);
    for (final c in <TextEditingController>[
      customerNameController,
      customerMobileController,
      vehiclePlateController,
      vehicleMakeController,
      vehicleModelController,
      vehicleVinController,
      vehicleYearController,
      odometerController,
    ]) {
      c.addListener(_onPreviewInputChanged);
    }
  }

  final PosRepository posRepository;
  final SessionService sessionService;
  final CatalogSyncService catalogSync;
  
  void _onPreviewInputChanged() {
    notifyListeners();
  }

  TakeawayCatalogData? _catalog;
  bool _catalogLoading = false;
  String? _catalogError;

  TakeawayCheckoutContext? _checkoutContext;
  bool _checkoutContextLoading = false;
  String? _checkoutContextError;

  final List<TakeawayCartLine> _cart = [];
  String? _selectedDepartmentId;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final TextEditingController searchController = TextEditingController();

  bool _checkoutLoading = false;
  String? _checkoutError;
  Invoice? _lastInvoice;
  String? _lastOrderId;
  String _appliedPromoCode = '';
  String? _appliedPromoCodeId;
  double _promoDiscountValue = 0;
  bool _isPromoPercent = false;
  String _referralCode = '';
  double _referralDiscountInclVat = 0;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerMobileController =
      TextEditingController();
  final TextEditingController customerTaxIdController =
      TextEditingController();
  final TextEditingController vehiclePlateController = TextEditingController();
  final TextEditingController vehicleVinController = TextEditingController();
  final TextEditingController vehicleMakeController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehicleYearController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();
  final TextEditingController odometerController = TextEditingController();
  final TextEditingController promoCodeController = TextEditingController();
  final TextEditingController vatController = TextEditingController();
  final TextEditingController invoiceDateController = TextEditingController();
  final TextEditingController discountAmountController =
      TextEditingController();
  final TextEditingController orderDiscountValueController =
      TextEditingController();

  String _orderDiscountType = '';
  String? _paymentMethod = 'Cash';
  List<Map<String, dynamic>>? _payments;
  bool? _isCorporate;
  final Set<PaymentMethod> _invoicePaymentMethods = <PaymentMethod>{};
  final Map<PaymentMethod, double> _invoicePaymentAmounts =
      <PaymentMethod, double>{};

  TakeawayCatalogData? get catalog => _catalog;
  bool get catalogLoading => _catalogLoading;
  String? get catalogError => _catalogError;

  TakeawayCheckoutContext? get checkoutContext => _checkoutContext;
  bool get checkoutContextLoading => _checkoutContextLoading;
  String? get checkoutContextError => _checkoutContextError;
  List<TakeawayBranchEmployee> get branchEmployees =>
      _checkoutContext?.branchEmployees ?? const [];

  List<TakeawayCartLine> get cart => List.unmodifiable(_cart);
  int get cartLineCount => _cart.length;
  double get cartQtyTotal => _cart.fold<double>(0, (a, b) => a + b.qty);

  String? get selectedDepartmentId => _selectedDepartmentId;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Matches POS [getCartCount]: sum of piece counts for the bottom bar label.
  int get cartItemCountDisplay => _cart.fold<int>(
        0,
        (sum, line) => sum + (line.qty >= 1 ? line.qty.round() : 1),
      );

  bool get catalogHasProducts {
    if (_catalog == null) return false;
    for (final c in _catalog!.categories) {
      if (c.products.isNotEmpty) return true;
    }
    return _catalog!.uncategorizedProducts.isNotEmpty;
  }

  bool get checkoutLoading => _checkoutLoading;
  String? get checkoutError => _checkoutError;
  Invoice? get lastInvoice => _lastInvoice;
  String? get lastOrderId => _lastOrderId;

  String get orderDiscountType => _orderDiscountType;
  String? get paymentMethod => _paymentMethod;
  List<Map<String, dynamic>>? get payments => _payments;
  bool? get isCorporate => _isCorporate;
  Set<PaymentMethod> get invoicePaymentMethods =>
      Set<PaymentMethod>.unmodifiable(_invoicePaymentMethods);
  Map<PaymentMethod, double> get invoicePaymentAmounts =>
      Map<PaymentMethod, double>.unmodifiable(_invoicePaymentAmounts);
  bool get paymentSelectionReady =>
      _isCorporate != null && _invoicePaymentMethods.isNotEmpty;

  /// Name and mobile; vehicle is optional (Takeaway collects customer only in the dialog).
  bool get hasRequiredTakeawayBillingFields {
    return customerNameController.text.trim().isNotEmpty &&
        customerMobileController.text.trim().isNotEmpty;
  }

  /// Block Generate until cart, billing, and payment match Orders-tab rules.
  bool get canGenerateTakeawayInvoice =>
      cartLineCount > 0 &&
      !checkoutLoading &&
      hasRequiredTakeawayBillingFields &&
      paymentSelectionReady;

  /// Legacy: payment is collected in the merged checkout dialog.
  bool get showTakeawayPaymentMethodButton => false;

  String get appliedPromoCode => _appliedPromoCode;
  String? get appliedPromoCodeId => _appliedPromoCodeId;
  double get promoDiscountValue => _promoDiscountValue;
  bool get isPromoPercent => _isPromoPercent;
  String get referralCode => _referralCode;
  double get referralDiscountInclVat => _referralDiscountInclVat;

  static const List<String> paymentMethods = [
    'Cash',
    'Bank transfer',
    'tamara',
    'Tabby',
    'corporate credit',
  ];

  void setSelectedDepartmentId(String? id) {
    _selectedDepartmentId = id;
    _selectedCategory = 'All';
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setOrderDiscountType(String? type) {
    _orderDiscountType = type ?? '';
    notifyListeners();
  }

  void setPaymentMethod(String? m) {
    _paymentMethod = m;
    _payments = null;
    notifyListeners();
  }

  void setPayments(List<Map<String, dynamic>> p) {
    _paymentMethod = null;
    _payments = p;
    notifyListeners();
  }

  void setInvoicePaymentPreferences({
    required bool isCorporate,
    required Set<PaymentMethod> methods,
    Map<PaymentMethod, double> amounts = const {},
  }) {
    _isCorporate = isCorporate;
    _invoicePaymentMethods
      ..clear()
      ..addAll(methods);
    _invoicePaymentAmounts
      ..clear()
      ..addAll(amounts);
    notifyListeners();
  }

  void clearInvoicePaymentPreferences() {
    _isCorporate = null;
    _invoicePaymentMethods.clear();
    _invoicePaymentAmounts.clear();
    _paymentMethod = 'Cash';
    _payments = null;
    notifyListeners();
  }

  Map<String, dynamic> buildPaymentPayloadForTotal(double invoiceTotal) {
    if (_isCorporate == null || _invoicePaymentMethods.isEmpty) {
      return {
        'paymentMethod': null,
        'payments': null,
        'isCorporate': null,
      };
    }

    if (_isCorporate == true) {
      if (_invoicePaymentMethods.length == 1) {
        final method = _invoicePaymentMethods.first.label;
        return {
          'paymentMethod': method,
          'payments': <Map<String, dynamic>>[
            {'method': method, 'amount': invoiceTotal}
          ],
          'isCorporate': true,
        };
      }
      final list = <Map<String, dynamic>>[];
      for (final pm in _invoicePaymentMethods) {
        final amount = _invoicePaymentAmounts[pm] ?? 0;
        if (amount > 0) {
          list.add({'method': pm.label, 'amount': amount});
        }
      }
      return {
        'paymentMethod': null,
        'payments': list,
        'isCorporate': true,
      };
    }

    if (_invoicePaymentMethods.length == 1) {
      final method = _invoicePaymentMethods.first.label;
      return {
        'paymentMethod': method,
        'payments': <Map<String, dynamic>>[
          {'method': method, 'amount': invoiceTotal}
        ],
        'isCorporate': false,
      };
    }

    final list = <Map<String, dynamic>>[];
    for (final pm in _invoicePaymentMethods) {
      final amount = _invoicePaymentAmounts[pm] ?? 0;
      if (amount > 0) {
        list.add({'method': pm.label, 'amount': amount});
      }
    }
    return {
      'paymentMethod': null,
      'payments': list,
      'isCorporate': false,
    };
  }

  void setAppliedPromo({
    required String code,
    String? promoId,
    required double discount,
    required bool isPercent,
  }) {
    _appliedPromoCode = code;
    _appliedPromoCodeId = promoId;
    _promoDiscountValue = discount;
    _isPromoPercent = isPercent;
    promoCodeController.text = code;
    notifyListeners();
  }

  void clearAppliedPromo() {
    _appliedPromoCode = '';
    _appliedPromoCodeId = null;
    _promoDiscountValue = 0;
    _isPromoPercent = false;
    promoCodeController.clear();
    notifyListeners();
  }

  void setAppliedReferral({
    required String code,
    required double discountInclVat,
  }) {
    _referralCode = code.trim();
    _referralDiscountInclVat =
        discountInclVat.clamp(0, double.infinity).toDouble();
    notifyListeners();
  }

  void clearAppliedReferral() {
    _referralCode = '';
    _referralDiscountInclVat = 0;
    notifyListeners();
  }

  void setOrderDiscountValue(double v) {
    // Controller already holds latest typed value from the field.
    notifyListeners();
  }

  void clearCheckoutError() {
    _checkoutError = null;
    notifyListeners();
  }

  void refreshPreview() => notifyListeners();

  Future<void> loadCatalog() async {
    if (_catalogLoading) return;
    _catalogLoading = true;
    _catalogError = null;
    notifyListeners();
    try {
      _catalog = await catalogSync.buildTakeawayCatalogFromLocal();
      if (_catalog == null) {
        _catalogError =
            'No local catalog yet. Use Sync data in the menu to download.';
      } else if (vatController.text.trim().isEmpty &&
          _catalog!.vatPercentDefault > 0) {
        final v = _catalog!.vatPercentDefault;
        vatController.text = v == v.roundToDouble()
            ? v.round().toString()
            : v.toStringAsFixed(2);
      }
    } on AppException catch (e) {
      _catalogError = e.toString();
    } catch (e) {
      _catalogError = e.toString();
    } finally {
      _catalogLoading = false;
      notifyListeners();
    }
    unawaited(loadCheckoutContext());
  }

  /// Branch employees + payment options from GET /cashier/takeaway/products-catalog.
  Future<void> loadCheckoutContext({bool force = false}) async {
    if (_checkoutContextLoading) return;
    if (_checkoutContext != null && !force) return;
    _checkoutContextLoading = true;
    _checkoutContextError = null;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null || token.isEmpty) {
        _checkoutContextError = 'Not signed in';
        return;
      }
      final data = await posRepository.getTakeawayProductsCatalog(token);
      _checkoutContext = data.checkoutContext;
      if (_checkoutContext == null) {
        _checkoutContextError = 'Checkout data unavailable';
      }
    } on AppException catch (e) {
      _checkoutContextError = e.toString();
    } catch (e) {
      _checkoutContextError = e.toString();
    } finally {
      _checkoutContextLoading = false;
      notifyListeners();
    }
  }

  List<TakeawayProduct> _allCatalogProducts() {
    if (_catalog == null) return [];
    final out = <TakeawayProduct>[];
    for (final c in _catalog!.categories) {
      out.addAll(c.products);
    }
    out.addAll(_catalog!.uncategorizedProducts);
    return out;
  }

  bool _matchesTakeawaySearch(TakeawayProduct p) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (p.name.toLowerCase().contains(q)) return true;
    final ar = p.nameArabic?.trim().toLowerCase() ?? '';
    return ar.isNotEmpty && ar.contains(q);
  }

  /// Search only — used for department tab counts.
  List<TakeawayProduct> get _searchFilteredProducts =>
      _allCatalogProducts().where(_matchesTakeawaySearch).toList();

  /// Department + search (used for category chip labels and counts).
  List<TakeawayProduct> get _baseFilteredProducts {
    final deptId = _selectedDepartmentId;
    final out = _searchFilteredProducts.where((p) {
      if (deptId == null || deptId.isEmpty) return true;
      return p.department.id == deptId;
    }).toList();
    out.sort((a, b) {
      final da = a.department.name;
      final db = b.department.name;
      if (da != db) return da.compareTo(db);
      return a.name.compareTo(b.name);
    });
    return out;
  }

  int takeawayCountForDepartmentTab(String? departmentId) {
    final products = _searchFilteredProducts;
    if (departmentId == null || departmentId.isEmpty) return products.length;
    return products.where((p) => p.department.id == departmentId).length;
  }

  int takeawayCountForCategoryTab(String category) {
    if (category == 'All') return _baseFilteredProducts.length;
    return _baseFilteredProducts
        .where((p) => p.category?.name == category)
        .length;
  }

  List<String> get takeawayCategoryChipNames {
    final names = <String>{};
    for (final p in _baseFilteredProducts) {
      final n = p.category?.name;
      if (n != null && n.isNotEmpty) names.add(n);
    }
    return names.toList()..sort();
  }

  double qtyInCartForProduct(String productId) {
    final line = _lineForProduct(productId);
    return line?.qty ?? 0;
  }

  /// Browsing list: department + search + category chip (same idea as product grid).
  List<TakeawayProduct> get visibleProducts {
    if (_selectedCategory == 'All') return _baseFilteredProducts;
    return _baseFilteredProducts
        .where((p) => p.category?.name == _selectedCategory)
        .toList();
  }

  TakeawayCartLine? _lineForProduct(String productId) {
    for (final line in _cart) {
      if (line.product.id == productId) return line;
    }
    return null;
  }

  void addProduct(TakeawayProduct product) {
    bumpProductQuantity(product, product.allowDecimalQty ? 1.0 : 1.0);
  }

  void bumpProductQuantity(TakeawayProduct product, double delta) {
    if (!product.isActive) return;
    if (product.isOutOfStockForTakeaway) return;
    final line = _lineForProduct(product.id);
    final cur = line?.qty ?? 0;
    applyProductQuantity(product, cur + delta);
  }

  void applyProductQuantity(TakeawayProduct product, double qty) {
    if (!product.isActive && qty > 0) return;
    if (product.isOutOfStockForTakeaway && qty > 0) return;
    if (qty <= 0) {
      removeLine(product.id);
      return;
    }
    final requested = product.allowDecimalQty ? qty : qty.roundToDouble();
    final q = product.allowMinusQty
        ? requested
        : (requested > product.qtyOnHand ? product.qtyOnHand : requested);
    if (q <= 0) return;
    final existing = _lineForProduct(product.id);
    if (existing == null) {
      _cart.add(TakeawayCartLine(
        product: product,
        qty: q,
        unitPrice: product.salePrice,
      ));
    } else {
      existing.qty = q;
    }
    notifyListeners();
  }

  void removeLine(String productId) {
    _cart.removeWhere((l) => l.product.id == productId);
    notifyListeners();
  }

  void updateLineQty(String productId, double qty) {
    final line = _lineForProduct(productId);
    if (line == null) return;
    if (qty <= 0) {
      removeLine(productId);
      return;
    }
    if (!line.product.allowDecimalQty) {
      line.qty = qty.roundToDouble();
    } else {
      line.qty = qty;
    }
    notifyListeners();
  }

  void updateLineUnitPrice(String productId, double price) {
    final line = _lineForProduct(productId);
    if (line == null) return;
    if (!line.product.isPriceEditable) return;
    if (price <= 0 || !price.isFinite) return;
    final err = line.product.validateEditableUnitPrice(price);
    if (err == 'below_min') {
      // Keep previous price; UI shows toast.
      return;
    }
    line.unitPrice = ((price * 100).roundToDouble() / 100);
    notifyListeners();
  }

  /// Returns error code when reject (`below_min` / `invalid`), else null after applying.
  String? tryUpdateLineUnitPrice(String productId, double price) {
    final line = _lineForProduct(productId);
    if (line == null) return 'invalid';
    if (!line.product.isPriceEditable) return 'invalid';
    if (price <= 0 || !price.isFinite) return 'invalid';
    final err = line.product.validateEditableUnitPrice(price);
    if (err != null) return err;
    line.unitPrice = ((price * 100).roundToDouble() / 100);
    notifyListeners();
    return null;
  }

  void updateLineDiscount(
    String productId, {
    String? discountType,
    required double discountValue,
  }) {
    final line = _lineForProduct(productId);
    if (line == null) return;
    line.lineDiscountType = (discountType == null || discountType.isEmpty)
        ? null
        : discountType;
    line.lineDiscountValue = discountValue < 0 ? 0 : discountValue;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Sum of line gross (excl. VAT) before per-line discounts — matches product grid "Gross Amount".
  double get grossExclVatBeforeLineDiscounts {
    return _cart.fold<double>(
      0,
      (sum, line) => sum + line.unitPriceExclVat * line.qty,
    );
  }

  /// Subtotal VAT-exclusive: sum of (unitPriceExclVat × qty - line discount).
  /// Same as product grid "Price after line discount" base.
  double get subtotalBeforeOrderDiscount {
    double sum = 0;
    for (final line in _cart) {
      final gross = line.unitPriceExclVat * line.qty;
      final type = line.lineDiscountType?.toLowerCase() ?? '';
      if (type == 'amount') {
        sum += (gross - line.lineDiscountValue).clamp(0, double.infinity);
      } else if (type == 'percent' || type == 'percentage') {
        sum += gross * (1 - (line.lineDiscountValue / 100).clamp(0, 1));
      } else {
        sum += gross;
      }
    }
    return sum;
  }

  /// Matches product grid "Line discount" row (excl. VAT).
  double get lineDiscountTotalExclVat {
    final g = grossExclVatBeforeLineDiscounts;
    final after = subtotalBeforeOrderDiscount;
    return (g - after).clamp(0, double.infinity);
  }

  /// Payable before marketing referral (incl. VAT).
  double get estimatedTotalBeforeReferral {
    final sub = subtotalBeforeOrderDiscount;

    final orderDiscInput =
        double.tryParse(orderDiscountValueController.text.trim()) ?? 0.0;
    final isOrderDiscPercent =
        _orderDiscountType == 'percent' || _orderDiscountType == 'percentage';
    final orderDisc = isOrderDiscPercent
        ? (sub * (orderDiscInput / 100)).clamp(0, sub).toDouble()
        : orderDiscInput.clamp(0, sub).toDouble();
    final afterOrderDiscount =
        (sub - orderDisc).clamp(0, double.infinity).toDouble();

    final promoDiscount = _isPromoPercent
        ? (afterOrderDiscount * (_promoDiscountValue / 100))
            .clamp(0, afterOrderDiscount)
            .toDouble()
        : _promoDiscountValue.clamp(0, afterOrderDiscount).toDouble();
    final taxable = (afterOrderDiscount - promoDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    final hasOrderLevelDiscount = orderDisc > 0.0001 || promoDiscount > 0.0001;
    final vatAmount = hasOrderLevelDiscount
        ? computePosOrderLevelVat(
            afterItemExclVat: sub,
            globalDiscount: orderDisc,
            globalIsPercent: isOrderDiscPercent,
            promoDiscount: promoDiscount,
            promoIsPercent: _isPromoPercent,
          )
        : taxable * liveInvoiceVatRate;
    return taxable + vatAmount;
  }

  /// Shown in bottom bar / SoftPOS — after referral cut (incl. VAT).
  double get estimatedDisplayTotal {
    final before = estimatedTotalBeforeReferral;
    if (_referralCode.trim().isEmpty || _referralDiscountInclVat <= 0) {
      return before;
    }
    return (before - _referralDiscountInclVat).clamp(0, double.infinity);
  }

  /// Taxable (ex VAT) after promo — for Order-summary-style footer rows.
  double get taxableExclVatAfterPromo {
    final sub = subtotalBeforeOrderDiscount;
    final orderDiscInput =
        double.tryParse(orderDiscountValueController.text.trim()) ?? 0.0;
    final isOrderDiscPercent =
        _orderDiscountType == 'percent' || _orderDiscountType == 'percentage';
    final orderDisc = isOrderDiscPercent
        ? (sub * (orderDiscInput / 100)).clamp(0, sub).toDouble()
        : orderDiscInput.clamp(0, sub).toDouble();
    final afterOrderDiscount =
        (sub - orderDisc).clamp(0, double.infinity).toDouble();
    final promoDiscount = _isPromoPercent
        ? (afterOrderDiscount * (_promoDiscountValue / 100))
            .clamp(0, afterOrderDiscount)
            .toDouble()
        : _promoDiscountValue.clamp(0, afterOrderDiscount).toDouble();
    return (afterOrderDiscount - promoDiscount)
        .clamp(0, double.infinity)
        .toDouble();
  }

  double get promoDiscountExclVat {
    final sub = subtotalBeforeOrderDiscount;
    final orderDiscInput =
        double.tryParse(orderDiscountValueController.text.trim()) ?? 0.0;
    final isOrderDiscPercent =
        _orderDiscountType == 'percent' || _orderDiscountType == 'percentage';
    final orderDisc = isOrderDiscPercent
        ? (sub * (orderDiscInput / 100)).clamp(0, sub).toDouble()
        : orderDiscInput.clamp(0, sub).toDouble();
    final afterOrderDiscount =
        (sub - orderDisc).clamp(0, double.infinity).toDouble();
    return _isPromoPercent
        ? (afterOrderDiscount * (_promoDiscountValue / 100))
            .clamp(0, afterOrderDiscount)
            .toDouble()
        : _promoDiscountValue.clamp(0, afterOrderDiscount).toDouble();
  }

  double get referralDiscountExclVat {
    if (_referralCode.trim().isEmpty || _referralDiscountInclVat <= 0) {
      return 0;
    }
    return (_referralDiscountInclVat / 1.15).clamp(0, double.infinity);
  }

  Future<TakeawayCheckoutResponse?> submitCheckout() async {
    _checkoutError = null;
    _lastInvoice = null;
    _lastOrderId = null;
    if (_cart.isEmpty) {
      _checkoutError = 'Cart is empty.';
      notifyListeners();
      return null;
    }
    final name = customerNameController.text.trim();

    double lineDiscountAmount(TakeawayCartLine line) {
      final gross = line.unitPriceExclVat * line.qty;
      final type = (line.lineDiscountType ?? '').toLowerCase();
      if (type == 'percent' || type == 'percentage') {
        return (gross * (line.lineDiscountValue / 100)).clamp(0, gross);
      }
      if (type == 'amount') {
        return line.lineDiscountValue.clamp(0, gross);
      }
      return 0.0;
    }

    final amountBeforeDiscount = _cart.fold<double>(
      0.0,
      (sum, line) => sum + (line.unitPriceExclVat * line.qty),
    );

    final items = _cart.map((line) {
      final beforeDiscountPrice = line.unitPriceExclVat * line.qty;
      final lineDiscount = lineDiscountAmount(line);
      final double afterDiscountPrice =
          (beforeDiscountPrice - lineDiscount).clamp(0, double.infinity).toDouble();
      return TakeawayCheckoutLinePayload(
        productId: line.product.id,
        qty: line.qty,
        discountType: line.lineDiscountType,
        discountValue: line.lineDiscountValue,
        unitPrice: line.unitPrice != line.product.salePrice ? line.unitPrice : null,
        beforeDiscountPrice: beforeDiscountPrice,
        afterDiscountPrice: afterDiscountPrice,
      );
    }).toList();

    final odType = _orderDiscountType.trim();
    final odVal =
        double.tryParse(orderDiscountValueController.text.trim()) ?? 0;

    final amountAfterLineDiscount = items.fold<double>(
      0.0,
      (sum, line) => sum + (line.afterDiscountPrice ?? 0.0),
    );
    final isOrderDiscountPercent =
        odType == 'percent' || odType == 'percentage';
    final double orderDiscountAmount = isOrderDiscountPercent
        ? (amountAfterLineDiscount * (odVal / 100)).clamp(0, amountAfterLineDiscount)
        : odVal.clamp(0, amountAfterLineDiscount);
    final double amountAfterDiscount =
        (amountAfterLineDiscount - orderDiscountAmount).clamp(0, double.infinity).toDouble();

    final double promoDiscountAmount = _isPromoPercent
        ? (amountAfterDiscount * (_promoDiscountValue / 100)).clamp(0, amountAfterDiscount)
        : _promoDiscountValue.clamp(0, amountAfterDiscount);
    final double amountAfterPromo =
        (amountAfterDiscount - promoDiscountAmount).clamp(0, double.infinity).toDouble();

    // Align with main POS live invoice (fixed SAR discounts reduce total by exact amount).
    const vatPercent = 15.0;
    final hasOrderLevelDiscount =
        orderDiscountAmount > 0.0001 || promoDiscountAmount > 0.0001;
    final vatAmount = hasOrderLevelDiscount
        ? computePosOrderLevelVat(
            afterItemExclVat: amountAfterLineDiscount,
            globalDiscount: orderDiscountAmount,
            globalIsPercent: isOrderDiscountPercent,
            promoDiscount: promoDiscountAmount,
            promoIsPercent: _isPromoPercent,
          )
        : amountAfterPromo * (vatPercent / 100.0);
    final totalBeforeReferral = amountAfterPromo + vatAmount;
    final referralCut = _referralCode.trim().isEmpty
        ? 0.0
        : _referralDiscountInclVat.clamp(0, totalBeforeReferral).toDouble();
    final totalAmount =
        (totalBeforeReferral - referralCut).clamp(0, double.infinity).toDouble();
    final discAmt =
        double.tryParse(discountAmountController.text.trim()) ?? 0;

    final plate = vehiclePlateController.text.trim();
    final make = vehicleMakeController.text.trim();
    final model = vehicleModelController.text.trim();
    final vin = vehicleVinController.text.trim();
    final color = vehicleColorController.text.trim();
    final year = int.tryParse(vehicleYearController.text.trim());
    final odo = int.tryParse(
      odometerController.text.trim().replaceAll(RegExp(r'[\s,]'), ''),
    );

    final request = TakeawayCheckoutRequest(
      customerName: name.isEmpty ? 'Walk-in Customer' : name,
      customerMobile: customerMobileController.text.trim().isEmpty
          ? null
          : customerMobileController.text.trim(),
      customerTaxId: customerTaxIdController.text.trim().isEmpty
          ? null
          : customerTaxIdController.text.trim(),
      items: items,
      totalDiscountType:
          odType.isEmpty || odVal <= 0 ? null : odType,
      totalDiscountValue: odVal > 0 ? odVal : 0,
      promoCode: _appliedPromoCode.isEmpty ? null : _appliedPromoCode,
      promoCodeId: _appliedPromoCodeId,
      referralCode: _referralCode.trim().isEmpty ? null : _referralCode.trim(),
      amountBeforeDiscount: amountBeforeDiscount,
      amountAfterDiscount: amountAfterDiscount,
      amountAfterPromo: amountAfterPromo,
      vatPercent: vatPercent,
      totalAmount: totalAmount,
      paymentMethod: _paymentMethod,
      payments: _payments,
      invoiceDate: invoiceDateController.text.trim().isEmpty
          ? null
          : invoiceDateController.text.trim(),
      discountAmount: discAmt > 0 ? discAmt : 0,
      vehicleNumber: plate.isNotEmpty ? plate : null,
      make: make.isNotEmpty ? make : null,
      model: model.isNotEmpty ? model : null,
      vin: vin.isNotEmpty ? vin : null,
      year: year,
      odometerReading: (odo != null && odo > 0) ? odo : null,
      color: color.isNotEmpty ? color : null,
    );

    // Dev trace: verify contract payload sent to takeaway checkout API.
    assert(() {
      debugPrint(
        '[Takeaway] Checkout payload: ${jsonEncode(request.toJson())}',
      );
      return true;
    }());

    _checkoutLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null || token.isEmpty) {
        _checkoutError = 'Not logged in';
        _checkoutLoading = false;
        notifyListeners();
        return null;
      }
      final res = await posRepository.postTakeawayCheckout(request, token);
      if (res.success) {
        // Do not PATCH /billing after takeaway checkout: the API creates the invoice
        // in the same flow, and billing is locked ("Cannot edit billing after invoice generation").
        // Customer + vehicle are sent on [TakeawayCheckoutRequest] only.
        Invoice? resolvedInvoice;
        if (res.orderId != null && res.orderId!.isNotEmpty) {
          final invoiceByOrder = await posRepository.getInvoiceByOrder(
            res.orderId!,
            token,
          );
          resolvedInvoice = invoiceByOrder.invoice;
        }

        _lastInvoice = resolvedInvoice;
        _lastOrderId = null;
        if (resolvedInvoice != null) {
          clearCart();
          searchController.clear();
          _searchQuery = '';
          _selectedCategory = 'All';
          customerNameController.clear();
          customerMobileController.clear();
          customerTaxIdController.clear();
          vehiclePlateController.clear();
          vehicleVinController.clear();
          vehicleMakeController.clear();
          vehicleModelController.clear();
          vehicleYearController.clear();
          vehicleColorController.clear();
          odometerController.clear();
          promoCodeController.clear();
          orderDiscountValueController.clear();
          discountAmountController.clear();
          _orderDiscountType = '';
          clearAppliedPromo();
          clearAppliedReferral();
          clearInvoicePaymentPreferences();
        } else {
          _checkoutError =
              res.message.isNotEmpty ? res.message : 'No invoice in response';
        }
      } else {
        _checkoutError =
            res.message.isNotEmpty ? res.message : 'Checkout failed';
      }
      _checkoutLoading = false;
      notifyListeners();
      return res;
    } on AppException catch (e) {
      _checkoutError = e.toString();
      _checkoutLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _checkoutError = e.toString();
      _checkoutLoading = false;
      notifyListeners();
      return null;
    }
  }

  void resetLastInvoice() {
    _lastInvoice = null;
    _lastOrderId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    vatController.removeListener(_onPreviewInputChanged);
    orderDiscountValueController.removeListener(_onPreviewInputChanged);
    promoCodeController.removeListener(_onPreviewInputChanged);
    for (final c in <TextEditingController>[
      customerNameController,
      customerMobileController,
      vehiclePlateController,
      vehicleMakeController,
      vehicleModelController,
      vehicleVinController,
      vehicleYearController,
      odometerController,
    ]) {
      c.removeListener(_onPreviewInputChanged);
    }
    searchController.dispose();
    customerNameController.dispose();
    customerMobileController.dispose();
    customerTaxIdController.dispose();
    vehiclePlateController.dispose();
    vehicleVinController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleYearController.dispose();
    vehicleColorController.dispose();
    odometerController.dispose();
    promoCodeController.dispose();
    vatController.dispose();
    invoiceDateController.dispose();
    discountAmountController.dispose();
    orderDiscountValueController.dispose();
    super.dispose();
  }

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }
}
