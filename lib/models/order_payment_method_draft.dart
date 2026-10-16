import 'pos_payment_method.dart';

/// One row persisted by PATCH `/cashier/order/:id/payment-method`.
class PosPaymentDraftRow {
  final String method;
  final double amount;
  /// SoftPOS app-bar prepaid marker (`softpos_app_bar`) when present.
  final String? source;

  PosPaymentDraftRow({
    required this.method,
    required this.amount,
    this.source,
  });

  factory PosPaymentDraftRow.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    final src = map['source']?.toString().trim();
    return PosPaymentDraftRow(
      method: map['method']?.toString().trim() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '') ?? 0.0,
      source: src != null && src.isNotEmpty ? src : null,
    );
  }

  bool get isSoftPosAppBar =>
      (source ?? '').trim().toLowerCase() == 'softpos_app_bar';
}

/// PATCH body shape for `{ clear: true }` or `{ customerKind, payments }`.
class PatchOrderPaymentMethodPayload {
  final bool clear;
  final String? customerKind;
  final List<Map<String, dynamic>>? payments;

  const PatchOrderPaymentMethodPayload._({
    required this.clear,
    this.customerKind,
    this.payments,
  });

  factory PatchOrderPaymentMethodPayload.clear() =>
      const PatchOrderPaymentMethodPayload._(clear: true);

  factory PatchOrderPaymentMethodPayload.saveDraft({
    required bool isCorporate,
    required List<Map<String, dynamic>> payments,
  }) {
    return PatchOrderPaymentMethodPayload._(
      clear: false,
      customerKind: isCorporate ? 'corporate' : 'individual',
      payments: payments,
    );
  }

  Map<String, dynamic> toJson() {
    if (clear) return <String, dynamic>{'clear': true};
    return <String, dynamic>{
      'customerKind': customerKind,
      'payments': payments,
    };
  }
}

/// Maps [PaymentMethod] to API `method` strings for the payment-method draft PATCH.
extension PaymentMethodCashierDraftApiValue on PaymentMethod {
  /// Keep aligned with NestJS expectations and POS invoice payloads.
  String get cashierDraftApiMethodLabel {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.tapToPay:
        return 'Tap to Pay';
      case PaymentMethod.bankTransfer:
        return 'Bank transfer';
      case PaymentMethod.monthlyBilling:
        return 'corporate credit';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.tabby:
        return 'Tabby';
      case PaymentMethod.tamara:
        return 'tamara';
      case PaymentMethod.employees:
        return 'Employees';
    }
  }
}

/// Loose parser for POS draft rows returned from GET (method names may vary in casing).
PaymentMethod? parsePaymentMethodFromDraftApiLabel(String raw) {
  final k = raw.trim().toLowerCase().replaceAll('_', ' ');
  if (k.isEmpty) return null;

  bool containsAny(String hay, List<String> subs) =>
      subs.any((s) => hay.contains(s));

  if (k == 'corp' ||
      containsAny(k, ['corporate credit', 'monthly billing', 'on account'])) {
    return PaymentMethod.monthlyBilling;
  }
  if (containsAny(k, ['bank transfer', 'wire', 'iban', 'swift'])) {
    return PaymentMethod.bankTransfer;
  }
  if (k.contains('cash')) return PaymentMethod.cash;
  if (containsAny(k, ['tap to pay', 'taptopay', 'softpos', 'nearpay'])) {
    return PaymentMethod.tapToPay;
  }
  if (containsAny(k, ['card', 'mada', 'visa', 'master', 'debit', 'credit'])) {
    return PaymentMethod.card;
  }
  if (k.contains('wallet')) return PaymentMethod.wallet;
  if (k.contains('tabby')) return PaymentMethod.tabby;
  if (k.contains('tamara')) return PaymentMethod.tamara;
  if (k.contains('employee')) return PaymentMethod.employees;

  /// Exact label fallback (capitalization variants)
  if (k == 'employees') return PaymentMethod.employees;

  return null;
}
