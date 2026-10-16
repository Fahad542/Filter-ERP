import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CashBank models — registers, transfers, branch defaults
// ─────────────────────────────────────────────────────────────────────────────

enum RegisterKind { cash, bank, pettyCash }

extension RegisterKindX on RegisterKind {
  String get label {
    switch (this) {
      case RegisterKind.cash:
        return 'Cash';
      case RegisterKind.bank:
        return 'Bank';
      case RegisterKind.pettyCash:
        return 'Petty Cash';
    }
  }

  IconData get icon {
    switch (this) {
      case RegisterKind.cash:
        return Icons.payments_outlined;
      case RegisterKind.bank:
        return Icons.account_balance_outlined;
      case RegisterKind.pettyCash:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

enum RegisterStatus { active, inactive }

extension RegisterStatusX on RegisterStatus {
  String get label => this == RegisterStatus.active ? 'Active' : 'Inactive';
}

/// A single operating register / financial account (Cash, Bank, Petty Cash).
class CashBankAccount {
  final String id;
  final String name;
  final String kindLabel; // e.g. "Operating", "Reserve"
  final RegisterKind type;
  final String branch;
  final String? posSoftPos; // e.g. "Shared", "—"
  final String? coaLink; // e.g. "CB-8-1780508546110-0 · Cash On Hand"
  final double openingBalance;
  final double currentBalance;
  final RegisterStatus status;

  const CashBankAccount({
    required this.id,
    required this.name,
    required this.kindLabel,
    required this.type,
    required this.branch,
    this.posSoftPos,
    this.coaLink,
    required this.openingBalance,
    required this.currentBalance,
    required this.status,
  });
}

/// Branch-level default register pins (for POS card sales, locker deposits, etc.)
class BranchRegisterDefaults {
  final String branch;
  String? defaultCashAccountId;
  String? defaultBankAccountId;

  BranchRegisterDefaults({
    required this.branch,
    this.defaultCashAccountId,
    this.defaultBankAccountId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data
// ─────────────────────────────────────────────────────────────────────────────

class CashBankDummyData {
  static final List<CashBankAccount> accounts = [
    const CashBankAccount(
      id: 'acc_cash_on_hand',
      name: 'Cash On Hand',
      kindLabel: 'Operating',
      type: RegisterKind.cash,
      branch: 'Main Branch',
      posSoftPos: 'Shared',
      coaLink: 'CB-8-1780508546110-0 · Cash On Hand',
      openingBalance: 100,
      currentBalance: 50,
      status: RegisterStatus.active,
    ),
  ];

  static final List<BranchRegisterDefaults> branchDefaults = [
    BranchRegisterDefaults(branch: 'Main Branch'),
  ];

  static const List<String> branches = ['Main Branch'];
}
