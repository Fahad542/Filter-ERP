import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart'
    show LockerRepository, LockerCashierModel;
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class PettyCashFloat {
  final String id;
  final String cashierName;
  final double amount;
  final String currency;
  final String description;
  final DateTime issuedAt;
  final String reference;

  const PettyCashFloat({
    required this.id,
    required this.cashierName,
    required this.amount,
    required this.currency,
    required this.description,
    required this.issuedAt,
    required this.reference,
  });

  factory PettyCashFloat.fromJson(Map<String, dynamic> json) {
    return PettyCashFloat(
      id         : json['id']?.toString() ?? '',
      cashierName: json['cashierName'] as String? ?? '',
      amount     : _parseDouble(json['amount']),
      currency   : json['currency'] as String? ?? 'SAR',
      description: json['description'] as String? ?? '',
      reference  : json['reference'] as String? ?? '',
      issuedAt   : DateTime.tryParse(
            (json['issuedAt'] ?? json['createdAt']) as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class CashierOption {
  final String id;
  final String name;

  const CashierOption({required this.id, required this.name});

  factory CashierOption.fromCashierModel(LockerCashierModel model) {
    return CashierOption(id: model.userId, name: model.name);
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

enum PettyCashState { idle, loading, success, error }

enum PettyCashSubmitState { idle, submitting, done, error }

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LockerPettyCashViewModel extends ChangeNotifier {
  final LockerRepository _repository;
  final SessionService _sessionService;

  LockerPettyCashViewModel({
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ──────────────────────────────────────────────────────────────────
  String? _token;

  // ── Vault balance ────────────────────────────────────────────────────────────
  double _vaultBalance = 0.0;
  String _currency = 'SAR';

  double get vaultBalance => _vaultBalance;
  String get currency => _currency;

  // ── Cashiers dropdown ────────────────────────────────────────────────────────
  List<CashierOption> _cashiers = [];
  CashierOption? _selectedCashier;

  List<CashierOption> get cashiers => _cashiers;
  CashierOption? get selectedCashier => _selectedCashier;

  // ── Form fields ──────────────────────────────────────────────────────────────
  double? _amount;
  DateTime _issueDate = DateTime.now();
  String _reference = '';

  double? get amount => _amount;
  DateTime get issueDate => _issueDate;
  String get reference => _reference;

  // ── Recent floats ────────────────────────────────────────────────────────────
  List<PettyCashFloat> _recentFloats = [];
  List<PettyCashFloat> get recentFloats => List.unmodifiable(_recentFloats);

  // ── State ─────────────────────────────────────────────────────────────────────
  PettyCashState _state = PettyCashState.idle;
  PettyCashSubmitState _submitState = PettyCashSubmitState.idle;
  String? _errorMessage;
  String? _submitError;

  PettyCashState get state => _state;
  PettyCashSubmitState get submitState => _submitState;
  String? get errorMessage => _errorMessage;
  String? get submitError => _submitError;

  bool get isLoading => _state == PettyCashState.loading;
  bool get hasError => _state == PettyCashState.error;
  bool get isSubmitting => _submitState == PettyCashSubmitState.submitting;

  // ── Validation ────────────────────────────────────────────────────────────────
  bool get canSubmit =>
      _selectedCashier != null &&
          _amount != null &&
          _amount! > 0 &&
          !isSubmitting;

  AppLocalizations? _l10n(BuildContext? context) =>
      context != null ? AppLocalizations.of(context) : null;

  // ── Public API ────────────────────────────────────────────────────────────────

  Future<void> init([BuildContext? context]) async {
    _state = PettyCashState.loading;
    notifyListeners();

    final l10n = _l10n(context);
    try {
      _token = await _sessionService.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n?.lockerSessionExpired ??
            'Session expired. Please log in again.');
        return;
      }
      await _loadData(context);
    } catch (e) {
      _setError(
        '${l10n?.lockerFailedLoadSession ?? 'Failed to load session.'} ${_friendly(e)}'
            .trim(),
      );
    }
  }

  Future<void> refresh([BuildContext? context]) => _loadData(context);

  void selectCashier(CashierOption? cashier) {
    _selectedCashier = cashier;
    notifyListeners();
  }

  void setAmount(String value) {
    _amount = double.tryParse(value.replaceAll(',', ''));
    notifyListeners();
  }

  void setIssueDate(DateTime date) {
    _issueDate = date;
    notifyListeners();
  }

  void setReference(String value) {
    _reference = value;
    notifyListeners();
  }

  Future<bool> submit({BuildContext? context}) async {
    if (!canSubmit) return false;

    final l10n = _l10n(context);
    _submitState = PettyCashSubmitState.submitting;
    _submitError = null;
    notifyListeners();

    try {
      final response = await _repository.issuePettyCash(
        token        : _token!,
        cashierUserId: _selectedCashier!.id,
        amount       : _amount!,
        issueDate    : _issueDate,
        reference    : _reference,
      );

      // The API confirms success via `message`; no float object is returned,
      // so we build the local entry from what we submitted.
      final defaultDesc =
          l10n?.lockerPettyCashFloatDefault ?? 'Petty cash float';
      final newFloat = PettyCashFloat(
        id         : response['walletTransactionId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        cashierName: _selectedCashier!.name,
        amount     : _amount!,
        currency   : _currency,
        description: _reference.isNotEmpty ? _reference : defaultDesc,
        reference  : response['journalId'] != null
            ? 'JNL-${response['journalId']}'
            : 'PCF-${DateTime.now().millisecondsSinceEpoch % 100000}',
        issuedAt   : _issueDate,
      );

      _recentFloats.insert(0, newFloat);
      _vaultBalance = (_vaultBalance - _amount!).clamp(0, double.infinity);

      // Reset form
      _selectedCashier = null;
      _amount = null;
      _reference = '';
      _issueDate = DateTime.now();

      _submitState = PettyCashSubmitState.done;
      notifyListeners();

      debugLog('[PettyCashVM] Float issued to ${newFloat.cashierName} — '
          '${newFloat.amount} $_currency | '
          'txn=${response['walletTransactionId']} journal=${response['journalId']}');
      return true;
    } on UnauthorisedException {
      _submitState = PettyCashSubmitState.error;
      _submitError = l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.';
      notifyListeners();
      return false;
    } on BadRequestException catch (e) {
      _submitState = PettyCashSubmitState.error;
      _submitError = l10n != null
          ? l10n.lockerBadRequest(_friendly(e))
          : _friendly(e);
      notifyListeners();
      return false;
    } catch (e) {
      _submitState = PettyCashSubmitState.error;
      _submitError =
          l10n?.lockerFailedIssueFloat ?? 'Failed to issue float.';
      notifyListeners();
      debugLog('[PettyCashVM] Submit error: $e');
      return false;
    }
  }

  void resetSubmitState() {
    _submitState = PettyCashSubmitState.idle;
    _submitError = null;
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  Future<void> _loadData([BuildContext? context]) async {
    final l10n = _l10n(context);
    _state = PettyCashState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch cashiers and overview in parallel.
      final results = await Future.wait([
        _repository.getCashiers(token: _token!),
        _repository.getLockerOverview(token: _token!),
      ]);

      final cashierModels = results[0] as List<LockerCashierModel>;
      final overview      = results[1] as Map<String, dynamic>;

      // Cashiers dropdown
      _cashiers = cashierModels
          .map((e) => CashierOption.fromCashierModel(e))
          .toList();

      // Vault balance lives under kpis.lockerVaultBalance in the overview response.
      final kpis = overview['kpis'];
      if (kpis is Map<String, dynamic>) {
        _vaultBalance = PettyCashFloat._parseDouble(kpis['lockerVaultBalance']);
      }

      // Recent petty cash issues — overview.recentPettyCashIssues[]
      final rawIssues = overview['recentPettyCashIssues'];
      if (rawIssues is List) {
        _recentFloats = rawIssues
            .whereType<Map<String, dynamic>>()
            .map((e) => PettyCashFloat.fromJson(e))
            .toList();
      } else {
        _recentFloats = [];
      }

      _state = PettyCashState.success;
      notifyListeners();
    } on UnauthorisedException {
      _setError(l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e) {
      _setError(l10n?.lockerFailedLoadData ?? 'Failed to load data.');
      debugLog('[PettyCashVM] Load error: $e');
    }
  }

  void _setError(String msg) {
    _state = PettyCashState.error;
    _errorMessage = msg;
    notifyListeners();
    debugLog('[PettyCashVM] Error: $msg');
  }

  String _friendly(Object e) {
    final raw = e.toString();
    const prefixes = [
      'Error During Communication: ',
      'Invalid Request: ',
      'Unauthorised: ',
    ];
    for (final p in prefixes) {
      if (raw.startsWith(p)) return raw.substring(p.length);
    }
    return raw;
  }
}
