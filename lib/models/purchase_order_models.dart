class PoAffiliatedSupplier {
  final String supplierId;
  final String supplierName;

  PoAffiliatedSupplier({
    required this.supplierId,
    required this.supplierName,
  });

  factory PoAffiliatedSupplier.fromJson(Map<String, dynamic> json) {
    return PoAffiliatedSupplier(
      supplierId: '${json['supplierId'] ?? json['id'] ?? ''}',
      supplierName: '${json['supplierName'] ?? json['name'] ?? 'Supplier'}',
    );
  }
}

class PoBranchProduct {
  final String id;
  final String name;
  final String unit;
  final String purchasePrice;
  final double? qtyOnHand;

  PoBranchProduct({
    required this.id,
    required this.name,
    required this.unit,
    this.purchasePrice = '0',
    this.qtyOnHand,
  });

  factory PoBranchProduct.fromJson(Map<String, dynamic> json) {
    final qtyRaw = json['qtyOnHand'] ?? json['currentQty'];
    return PoBranchProduct(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      unit: '${json['unit'] ?? json['workshopUnit'] ?? 'pcs'}',
      purchasePrice: '${json['purchasePrice'] ?? '0'}',
      qtyOnHand: qtyRaw == null ? null : double.tryParse('$qtyRaw'),
    );
  }
}

class PoLineDraft {
  String? productId;
  String productName;
  String description;
  String qty;
  String uom;
  String unitPrice;

  PoLineDraft({
    this.productId,
    this.productName = '',
    this.description = '',
    this.qty = '1',
    this.uom = '',
    this.unitPrice = '0',
  });

  Map<String, dynamic> toSubmitJson() => {
        'productId': productId ?? '',
        'productName': productName.trim(),
        'description': description.trim(),
        'qty': double.tryParse(qty.trim()) ?? 0,
        'uom': uom.trim(),
        if (double.tryParse(unitPrice.trim()) != null)
          'unitPrice': double.parse(unitPrice.trim()),
      };
}

class PurchaseOrderSummary {
  final String id;
  final String invoiceNumber;
  final String vendorInvoiceRef;
  final String status;
  final String issueDate;
  final String supplierName;
  final double grandTotal;

  PurchaseOrderSummary({
    required this.id,
    required this.invoiceNumber,
    this.vendorInvoiceRef = '',
    required this.status,
    required this.issueDate,
    required this.supplierName,
    required this.grandTotal,
  });

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderSummary(
      id: '${json['id'] ?? ''}',
      invoiceNumber:
          '${json['invoiceNumber'] ?? json['invoice_number'] ?? ''}',
      vendorInvoiceRef:
          '${json['vendorInvoiceRef'] ?? json['vendor_invoice_ref'] ?? json['refNumber'] ?? ''}',
      status: '${json['status'] ?? ''}',
      issueDate: '${json['issueDate'] ?? json['issue_date'] ?? ''}',
      supplierName:
          '${json['supplierName'] ?? json['supplier']?['name'] ?? '—'}',
      grandTotal: double.tryParse('${json['grandTotal'] ?? json['grand_total'] ?? 0}') ??
          0,
    );
  }
}

class IncomingSupplierInvoiceSummary {
  final String id;
  final String invoiceNo;
  final String invoiceDate;
  final String supplierName;
  final String productLabel;
  final double grandTotal;
  final String reviewStatus;

  IncomingSupplierInvoiceSummary({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.supplierName,
    required this.productLabel,
    required this.grandTotal,
    required this.reviewStatus,
  });

  factory IncomingSupplierInvoiceSummary.fromJson(Map<String, dynamic> json) {
    return IncomingSupplierInvoiceSummary(
      id: '${json['id'] ?? ''}',
      invoiceNo: '${json['invoiceNo'] ?? json['invoice_no'] ?? ''}',
      invoiceDate: '${json['invoiceDate'] ?? json['invoice_date'] ?? ''}',
      supplierName:
          '${json['supplierName'] ?? json['supplier']?['name'] ?? '—'}',
      productLabel: '${json['productLabel'] ?? json['product_label'] ?? '—'}',
      grandTotal:
          double.tryParse('${json['grandTotal'] ?? json['grand_total'] ?? 0}') ??
              0,
      reviewStatus:
          '${json['workshopReviewStatus'] ?? json['workshop_review_status'] ?? 'pending'}',
    );
  }
}

class IncomingSupplierInvoiceLine {
  final String id;
  final String productName;
  final String? description;
  final double invoiceQty;
  final String? unit;

  IncomingSupplierInvoiceLine({
    required this.id,
    required this.productName,
    this.description,
    required this.invoiceQty,
    this.unit,
  });

  factory IncomingSupplierInvoiceLine.fromJson(Map<String, dynamic> json) {
    return IncomingSupplierInvoiceLine(
      id: '${json['id'] ?? ''}',
      productName: '${json['productName'] ?? ''}',
      description: json['lineDescription']?.toString(),
      invoiceQty: double.tryParse('${json['qty'] ?? 0}') ?? 0,
      unit: json['unit']?.toString(),
    );
  }
}

class IncomingSupplierInvoiceDetail {
  final String id;
  final String invoiceNo;
  final String supplierName;
  final List<IncomingSupplierInvoiceLine> lines;

  IncomingSupplierInvoiceDetail({
    required this.id,
    required this.invoiceNo,
    required this.supplierName,
    required this.lines,
  });

  factory IncomingSupplierInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final inv = json['invoice'] is Map
        ? Map<String, dynamic>.from(json['invoice'] as Map)
        : json;
    final items = inv['items'];
    return IncomingSupplierInvoiceDetail(
      id: '${inv['id'] ?? ''}',
      invoiceNo: '${inv['invoiceNo'] ?? ''}',
      supplierName: '${inv['supplier']?['name'] ?? '—'}',
      lines: items is List
          ? items
              .whereType<Map>()
              .map((e) => IncomingSupplierInvoiceLine.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : [],
    );
  }
}
