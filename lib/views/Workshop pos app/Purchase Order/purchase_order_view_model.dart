import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../models/purchase_order_models.dart';
import '../../../models/pos_product_model.dart';
import '../../../services/catalog_sync_service.dart';
import '../../../services/session_service.dart';

class PurchaseOrderViewModel extends ChangeNotifier {
  PurchaseOrderViewModel({
    required PosRepository posRepository,
    required SessionService sessionService,
    required CatalogSyncService catalogSync,
  })  : _posRepository = posRepository,
        _sessionService = sessionService,
        _catalogSync = catalogSync;

  final PosRepository _posRepository;
  final SessionService _sessionService;
  final CatalogSyncService _catalogSync;

  bool productsLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  List<PoAffiliatedSupplier> suppliers = [];
  List<PoBranchProduct> products = [];
  List<PurchaseOrderSummary> history = [];
  List<IncomingSupplierInvoiceSummary> incoming = [];

  String? selectedSupplierId;
  String description = '';
  String draftReference = '';
  bool referenceLoading = true;
  DateTime issueDate = DateTime.now();
  final List<PoLineDraft> lines = [PoLineDraft()];

  Future<void> init() async {
    await Future.wait([
      fetchSuppliers(),
      fetchBranchProducts(),
      fetchHistory(),
      fetchIncoming(),
    ]);
    await fetchNextReference();
  }

  static String formatNextPoReference(Iterable<String> refs) {
    var maxNum = 0;
    for (final raw in refs) {
      final match =
          RegExp(r'^PO-(\d+)$', caseSensitive: false).firstMatch(raw.trim());
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null && n > maxNum) maxNum = n;
      }
    }
    return 'PO-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  String _computeNextReferenceFromHistory() {
    final refs = history
        .map((h) => h.vendorInvoiceRef)
        .where((ref) => ref.trim().isNotEmpty);
    return formatNextPoReference(refs);
  }

  Future<void> fetchNextReference({bool showLoading = true}) async {
    if (showLoading) {
      referenceLoading = true;
      draftReference = '';
      notifyListeners();
    }

    final token = await _token();
    if (token == null) {
      draftReference = _computeNextReferenceFromHistory();
      if (draftReference.isEmpty) draftReference = 'PO-0001';
      referenceLoading = false;
      notifyListeners();
      return;
    }

    try {
      final fromApi = await _posRepository.getPurchaseOrderNextReference(token);
      draftReference = fromApi.isNotEmpty
          ? fromApi
          : _computeNextReferenceFromHistory();
    } catch (_) {
      draftReference = _computeNextReferenceFromHistory();
    }

    if (draftReference.isEmpty) {
      draftReference = 'PO-0001';
    }

    referenceLoading = false;
    notifyListeners();
  }

  Future<String?> _token() => _sessionService.getToken();

  Future<void> fetchSuppliers() async {
    final token = await _token();
    if (token == null) return;
    try {
      suppliers = await _posRepository.getPurchaseOrderSuppliers(token);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchBranchProducts({String? supplierId}) async {
    productsLoading = true;
    notifyListeners();
    try {
      final local = await _catalogSync.loadProductsLocal();
      final localProducts = local?.products ?? const <PosProduct>[];
      products = localProducts
          .where((p) => !p.isServiceType)
          .map(_poBranchProductFromCatalog)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      productsLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureBranchProductsLoaded() async {
    if (products.isNotEmpty || productsLoading) return;
    await fetchBranchProducts();
  }

  void setSupplier(String? id) {
    selectedSupplierId = id;
    fetchBranchProducts();
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
  }

  void setIssueDate(DateTime date) {
    issueDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void addLine() {
    lines.add(PoLineDraft());
    notifyListeners();
  }

  void removeLine(int index) {
    if (lines.length <= 1) return;
    lines.removeAt(index);
    notifyListeners();
  }

  void applyProductToLine(int index, PoBranchProduct product) {
    if (index < 0 || index >= lines.length) return;
    final line = lines[index];
    line.productId = product.id;
    line.productName = product.name;
    line.uom = product.unit;
    line.unitPrice = product.purchasePrice;
    notifyListeners();
  }

  void clearProductFromLine(int index) {
    if (index < 0 || index >= lines.length) return;
    final line = lines[index];
    line.productId = null;
    line.productName = '';
    line.uom = '';
    line.unitPrice = '0';
    notifyListeners();
  }

  Future<bool> submitPurchaseOrder(void Function(String) onError) async {
    final token = await _token();
    if (token == null) {
      onError('Not signed in');
      return false;
    }
    final supplierId = selectedSupplierId?.trim() ?? '';
    if (supplierId.isEmpty) {
      onError('Select a supplier');
      return false;
    }
    final validLines = <Map<String, dynamic>>[];
    for (final ln in lines) {
      if ((ln.productId ?? '').isEmpty || ln.productName.trim().isEmpty) {
        continue;
      }
      final qty = double.tryParse(ln.qty.trim()) ?? 0;
      if (qty <= 0) {
        onError('Enter qty for ${ln.productName}');
        return false;
      }
      if (ln.uom.trim().isEmpty) {
        onError('UOM missing for ${ln.productName}');
        return false;
      }
      validLines.add(ln.toSubmitJson());
    }
    if (validLines.isEmpty) {
      onError('Add at least one product line');
      return false;
    }

    isSubmitting = true;
    notifyListeners();
    try {
      final reference = draftReference.trim();
      final body = {
        'issueDate': DateFormat('yyyy-MM-dd').format(issueDate),
        'supplierId': supplierId,
        if (reference.isNotEmpty) 'reference': reference,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'lines': validLines,
      };
      await _posRepository.createPurchaseOrder(token, body);
      description = '';
      selectedSupplierId = null;
      lines
        ..clear()
        ..add(PoLineDraft());
      if (reference.isNotEmpty) {
        draftReference = formatNextPoReference([reference]);
      }
      referenceLoading = false;
      notifyListeners();
      await fetchHistory();
      await fetchNextReference(showLoading: false);
      return true;
    } catch (e) {
      onError(e.toString());
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    final token = await _token();
    if (token == null) return;
    try {
      history = await _posRepository.listPurchaseOrders(token);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchIncoming() async {
    final token = await _token();
    if (token == null) return;
    try {
      incoming = await _posRepository.listIncomingPurchaseInvoices(token);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<IncomingSupplierInvoiceDetail?> loadIncomingDetail(String id) async {
    final token = await _token();
    if (token == null) return null;
    return _posRepository.getIncomingPurchaseInvoice(token, id);
  }

  Future<bool> receiveInvoice(
    String invoiceId,
    List<IncomingSupplierInvoiceLine> invoiceLines,
    Map<String, String> receivedQtyByLineId,
    void Function(String) onError,
  ) async {
    final token = await _token();
    if (token == null) {
      onError('Not signed in');
      return false;
    }
    isSubmitting = true;
    notifyListeners();
    try {
      final payloadLines = invoiceLines.map((ln) {
        final raw = receivedQtyByLineId[ln.id]?.trim();
        return {
          'invoiceItemId': ln.id,
          if (raw != null && raw.isNotEmpty) 'receivedQty': double.parse(raw),
        };
      }).toList();
      await _posRepository.receivePurchaseInvoice(token, invoiceId, {
        'lines': payloadLines,
      });
      await fetchIncoming();
      await fetchHistory();
      return true;
    } catch (e) {
      onError(e.toString());
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  static PoBranchProduct _poBranchProductFromCatalog(PosProduct p) {
    return PoBranchProduct(
      id: p.id,
      name: p.name.trim(),
      unit: (p.unit ?? '').trim().isNotEmpty ? p.unit!.trim() : 'pcs',
      purchasePrice: ((p.purchasePrice ?? 0) > 0 ? p.purchasePrice! : p.priceBeforeVat)
          .toStringAsFixed(2),
      qtyOnHand: p.stock.toDouble(),
    );
  }
}
