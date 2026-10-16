import 'package:flutter/material.dart';

/// Cashier invoice payment options (individual vs corporate sets differ in UI).
enum PaymentMethod {
  cash,
  card,
  tapToPay,
  bankTransfer,
  monthlyBilling,
  wallet,
  tabby,
  tamara,
  employees,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.tapToPay:
        return 'Tap to Pay';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.monthlyBilling:
        return 'Monthly billing';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.tabby:
        return 'Tabby';
      case PaymentMethod.tamara:
        return 'Tamara';
      case PaymentMethod.employees:
        return 'Employees';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.tapToPay:
        return Icons.contactless_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.monthlyBilling:
        return Icons.calendar_month_rounded;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.tabby:
        return Icons.splitscreen_rounded;
      case PaymentMethod.tamara:
        return Icons.shopping_bag_rounded;
      case PaymentMethod.employees:
        return Icons.groups_outlined;
    }
  }

  /// Individual / split flow — excludes corporate-only methods and Employees payment.
  bool get isRetailSelectable =>
      this != PaymentMethod.monthlyBilling &&
      this != PaymentMethod.wallet &&
      this != PaymentMethod.employees;
}
