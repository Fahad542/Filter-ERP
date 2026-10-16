import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../services/session_service.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../models/create_invoice_model.dart';
import '../../../models/submit_sales_return_model.dart';
import '../../../utils/toast_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/locker_translation_mixin.dart';
import 'sales_return_list_view_model.dart';

class SalesReturnViewModel extends ChangeNotifier with TranslatableMixin {
  final SessionService sessionService;
  final PosRepository posRepository;

  SalesReturnViewModel({
    required this.sessionService,
    required this.posRepository,
  });

  void clearSearchResults() {
    _searchResults = [];
    _selectedInvoice = null;
    _selectedItems.clear();
    _returnQuantities.clear();
    _returnReasons.clear();
    _proofImage = null;
    notifyListeners();
  }

  // Search State
  final searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchRequestVersion = 0;
  bool _isSearching = false;
  String? _searchError;
  List<Invoice> _searchResults = [];

  // Return Details State
  Invoice? _selectedInvoice;
  final Map<String, bool> _selectedItems = {};
  final Map<String, double> _returnQuantities = {};
  final Map<String, String> _returnReasons = {};
  File? _proofImage;
  bool _isSubmitting = false;
  bool _loadingReturnAvailability = false;
  final Map<String, double> _returnedQtyByItemId = {};
  bool _hasPendingReturnForInvoice = false;

  final List<String> returnReasonOptions = const [
    'Defective Product/Service',
    'Customer Cancellation',
    'Wrong Item / Service',
    'Other',
  ];

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  String localizedReturnReason(BuildContext context, String reason) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason) {
      case 'Defective Product/Service':
        return l10n.posSalesReturnReasonDefective;
      case 'Customer Cancellation':
        return l10n.posSalesReturnReasonCancellation;
      case 'Wrong Item / Service':
        return l10n.posSalesReturnReasonWrongItem;
      case 'Other':
        return l10n.posSalesReturnReasonOther;
      default:
        return reason;
    }
  }

  String? localizedSearchError(BuildContext context) {
    if (_searchError == null) return null;
    final l10n = AppLocalizations.of(context)!;
    if (_searchError == 'Error fetching invoices. Ensure invoice number is correct.') {
      return l10n.posSalesReturnErrorFetchInvoices;
    }
    return _searchError;
  }

  // Getters
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  List<Invoice> get searchResults => _searchResults;
  
  Invoice? get selectedInvoice => _selectedInvoice;
  Map<String, bool> get selectedItems => _selectedItems;
  Map<String, double> get returnQuantities => _returnQuantities;
  Map<String, String> get returnReasons => _returnReasons;
  File? get proofImage => _proofImage;
  bool get isSubmitting => _isSubmitting;
  bool get loadingReturnAvailability => _loadingReturnAvailability;
  bool get hasPendingReturnForInvoice => _hasPendingReturnForInvoice;

  double availableReturnQty(String itemId, double soldQty) {
    final returned = _returnedQtyByItemId[itemId] ?? 0;
    return (soldQty - returned).clamp(0, soldQty);
  }

  String? itemReturnBlockReason(BuildContext context, String itemId, double soldQty) {
    final available = availableReturnQty(itemId, soldQty);
    if (available > 0) return null;
    final l10n = AppLocalizations.of(context)!;
    if (_hasPendingReturnForInvoice) {
      return l10n.posSalesReturnItemPendingApproval;
    }
    return l10n.posSalesReturnItemFullyReturned;
  }

  static String apiErrorMessage(Object error) {
    final raw = error.toString();
    for (final prefix in [
      'Invalid Request: ',
      'Error During Communication: ',
      'Unauthorised: ',
    ]) {
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length);
      }
    }
    return raw;
  }

  /// True when at least one line is selected and every selected line has return qty > 0 (and at most invoice qty).
  bool get canSubmitReturn {
    final inv = _selectedInvoice;
    if (inv == null) return false;
    var anySelected = false;
    for (final item in inv.items) {
      if (!(_selectedItems[item.id] ?? false)) continue;
      anySelected = true;
      final q = _returnQuantities[item.id];
      final max = availableReturnQty(item.id, item.qty);
      if (q == null || q <= 0 || q > max) return false;
    }
    return anySelected;
  }

  static String _westernDigits(String text) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var out = text;
    for (var i = 0; i < arabic.length; i++) {
      out = out.replaceAll(arabic[i], i.toString());
    }
    return out;
  }

  void searchInvoiceSuggestions() {
    _searchDebounce?.cancel();
    final query = _westernDigits(searchController.text).trim();
    if (query.isEmpty) {
      _searchRequestVersion++;
      clearSearchResults();
      return;
    }

    _searchError = null;
    _selectedInvoice = null;
    _selectedItems.clear();
    _returnQuantities.clear();
    _returnReasons.clear();
    _proofImage = null;
    notifyListeners();

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      searchInvoice,
    );
  }

  Future<void> searchInvoice() async {
    _searchDebounce?.cancel();
    final query = _westernDigits(searchController.text).trim();
    if (query.isEmpty) {
      _searchRequestVersion++;
      clearSearchResults();
      return;
    }
    final requestVersion = ++_searchRequestVersion;

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await posRepository.getInvoicedOrdersByInvoiceNo(query, token);
      if (requestVersion != _searchRequestVersion) return;

      if (response.success) {
        _searchResults = response.orders.map((order) {
          return Invoice(
            id: order.invoiceId,
            invoiceNo: order.invoiceNo.isNotEmpty ? order.invoiceNo : order.invoiceId,
            invoiceDate: order.createdAt,
            subtotal: order.totalAmount,
            vatAmount: 0,
            discountAmount: order.totalDiscountValue,
            totalAmount: order.totalAmount,
            paymentStatus: order.status,
            customerName: order.customerName.isNotEmpty ? order.customerName : order.invoiceNo,
            customerType: '',
            vehicleInfo: '',
            plateNo: '',
            salesOrderId: order.id,
            customerId: order.customerId,
            nextOilChangeKm: null,
            items: order.items.map((item) {
              String? productNameArabic;
              try {
                final dynamic dynItem = item;
                productNameArabic = dynItem.productNameArabic as String?;
              } catch (_) {
                productNameArabic = null;
              }
              return InvoiceItem(
                id: item.id,
                productName: item.productName,
                productNameArabic: productNameArabic,
                qty: item.qty,
                unitPrice: item.unitPrice,
                lineTotal: item.lineTotal,
              );
            }).toList(),
            departments: [],
            payments: [],
          );
        }).toList();
      } else {
        _searchResults = [];
        // Backend signals cross-branch (or any other guarded refusal) via `message`.
        // Surface it both as the inline error banner and a global toast.
        final backendMessage = response.message?.trim();
        if (backendMessage != null && backendMessage.isNotEmpty) {
          _searchError = backendMessage;
          // Defer the toast one frame so the active route (e.g. Sales Return view that
          // was just pushed) is mounted and provides the Overlay/ScaffoldMessenger the
          // toast renders into. Without this, a toast emitted during a route transition
          // can be swallowed.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = ToastService.scaffoldMessengerKey.currentContext;
            if (ctx != null) {
              ToastService.showError(ctx, backendMessage);
            }
          });
        }
      }

    } catch (e) {
      if (requestVersion != _searchRequestVersion) return;
      _searchError = 'Error fetching invoices. Ensure invoice number is correct.';
      _searchResults = [];
    } finally {
      if (requestVersion == _searchRequestVersion) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectInvoice(Invoice invoice) async {
    _selectedInvoice = invoice;
    _selectedItems.clear();
    _returnQuantities.clear();
    _returnReasons.clear();
    _proofImage = null;
    _returnedQtyByItemId.clear();
    _hasPendingReturnForInvoice = false;
    _loadingReturnAvailability = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token != null) {
        final response = await posRepository.getSalesReturns(
          token,
          invoiceId: invoice.id,
          limit: 100,
        );
        if (response.success) {
          for (final sr in response.salesReturns) {
            if (sr.isRejected) continue;
            if (sr.isPending) _hasPendingReturnForInvoice = true;
            for (final line in sr.items) {
              final key = line.salesOrderItemId;
              _returnedQtyByItemId[key] =
                  (_returnedQtyByItemId[key] ?? 0) + line.qty;
            }
          }
        }
      }
    } catch (_) {
      // Availability hints are best-effort; submit still validates on server.
    } finally {
      _loadingReturnAvailability = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedInvoice = null;
    _selectedItems.clear();
    _returnQuantities.clear();
    _returnReasons.clear();
    _proofImage = null;
    notifyListeners();
  }

  void toggleItemSelection(String itemId, bool isSelected, double maxQty) {
    if (isSelected && availableReturnQty(itemId, maxQty) <= 0) return;
    _selectedItems[itemId] = isSelected;
    if (isSelected) {
      _returnQuantities[itemId] = 0;
      _returnReasons[itemId] = returnReasonOptions.first;
    } else {
      _returnQuantities.remove(itemId);
      _returnReasons.remove(itemId);
    }
    notifyListeners();
  }

  void updateReturnQuantity(String itemId, double qty) {
    _returnQuantities[itemId] = qty;
    notifyListeners();
  }

  void updateReturnReason(String itemId, String reason) {
    _returnReasons[itemId] = reason;
    notifyListeners();
  }

  Future<void> pickProofImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _proofImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> submitReturnRequest(BuildContext context) async {
    if (_selectedInvoice == null) return;
    
    final selectedItemsCount = _selectedItems.values.where((v) => v).length;
    if (selectedItemsCount == 0) {
      ToastService.showError(context, AppLocalizations.of(context)!.posSalesReturnErrorSelectItem);
      return;
    }

    if (!canSubmitReturn) {
      ToastService.showError(
        context,
        AppLocalizations.of(context)!.posSalesReturnErrorQty,
      );
      return;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception(AppLocalizations.of(context)!.posSalesReturnAuthTokenNotFound);

      const defaultReason = 'Defective Product/Service';

      final List<SalesReturnItem> returnItems = [];
      _selectedItems.forEach((itemId, isSelected) {
        if (!isSelected) return;
        final q = _returnQuantities[itemId];
        if (q == null || q <= 0) return;
        returnItems.add(SalesReturnItem(
          salesOrderItemId: itemId,
          qty: q,
          reason: _returnReasons[itemId] ?? defaultReason,
        ));
      });
      if (returnItems.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.posSalesReturnErrorNoValidLines);
      }

      String? proofUrl;
      if (_proofImage != null) {
        final bytes = await _proofImage!.readAsBytes();
        final path = _proofImage!.path.toLowerCase();
        final mime = path.endsWith('.png') ? 'image/png' : 'image/jpeg';
        proofUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      }

      final request = SubmitSalesReturnRequest(
        invoiceId: _selectedInvoice!.id,
        orderId: _selectedInvoice!.salesOrderId,
        customerId: _selectedInvoice!.customerId,
        reason: returnItems.first.reason,
        proofUrl: proofUrl,
        items: returnItems,
      );

      final response = await posRepository.submitSalesReturn(request, token);

      if (response.success) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          final baseMsg = response.message.trim().isNotEmpty
              ? response.message.trim()
              : l10n.posSalesReturnSuccessSubmitted;
          final sr = response.salesReturn;
          final detail = sr != null && sr.returnNo.isNotEmpty
              ? '${l10n.posSalesReturnNoLabel}: ${sr.returnNo}'
              : null;
          ToastService.showSuccess(
            context,
            detail != null ? '$baseMsg\n$detail' : baseMsg,
          );
          context.read<SalesReturnListViewModel>().fetchReturns(refresh: true);
        }

        // Reset state on success
        clearSelection();
        searchController.clear();
        _searchResults = [];
      } else {
        throw Exception(response.message);
      }

    } catch (e) {
      if (context.mounted) {
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.posSalesReturnErrorSubmit(
            SalesReturnViewModel.apiErrorMessage(e),
          ),
        );
      }
    } finally {
      if (context.mounted) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    unbindLocaleRetranslation();
    searchController.dispose();
    super.dispose();
  }

}
