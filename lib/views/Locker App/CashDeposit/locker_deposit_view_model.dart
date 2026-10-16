import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/repositories/locker_repository.dart';
import '../../../data/network/base_api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum LockerDepositState { idle, loading, submitting, success, error }

// ── BankRegister alias ────────────────────────────────────────────────────────
// View continues to use BankRegister; the real model lives in the repo layer.
typedef BankRegister = BankRegisterModel;

// ── DepositRecord (display model for recent deposits list) ────────────────────

class DepositRecord {
  final String id;
  final String reference;
  final String registerName;
  final String branchName;
  final double amount;
  final String currency;
  final DateTime depositedAt;

  const DepositRecord({
    required this.id,
    required this.reference,
    required this.registerName,
    required this.branchName,
    required this.amount,
    required this.currency,
    required this.depositedAt,
  });

  /// Map from the overview API's recentBankDeposits entries.
  factory DepositRecord.fromOverview(LockerOverviewDeposit d) {
    return DepositRecord(
      id          : d.id,
      reference   : d.reference,
      registerName: d.registerName,
      branchName  : d.branchName,
      amount      : d.amount,
      currency    : d.currency,
      depositedAt : d.depositedAt,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LockerDepositViewModel extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────────────────────────
  final LockerRepository _repository;
  final SessionService _sessionService;

  LockerDepositViewModel({
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ───────────────────────────────────────────────────────────────────
  String? _token;

  // ── State ─────────────────────────────────────────────────────────────────────
  LockerDepositState _state = LockerDepositState.idle;
  String? _errorMessage;
  String? _successMessage;

  LockerDepositState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isLoading    => _state == LockerDepositState.loading;
  bool get isSubmitting => _state == LockerDepositState.submitting;
  bool get hasError     => _state == LockerDepositState.error;
  bool get isSuccess    => _state == LockerDepositState.success;

  // ── Slow-network indicator ───────────────────────────────────────────────────
  // Flips true if a submit is still in flight after a few seconds, so the UI
  // can show a reassuring "still working…" hint instead of looking frozen.
  bool _isSlowNetwork = false;
  bool get isSlowNetwork => _isSlowNetwork;

  // ── Vault balance (sourced from overview KPIs) ────────────────────────────────
  double _vaultBalance      = 0.0;
  String _vaultCurrency     = 'SAR';
  String _vaultAccountLabel = 'Cash in Transit — Locker';

  double get vaultBalance      => _vaultBalance;
  String get vaultCurrency     => _vaultCurrency;
  String get vaultAccountLabel => _vaultAccountLabel;

  // ── Bank registers (from GET /locker/bank-registers) ─────────────────────────
  List<BankRegisterModel> _bankRegisters = const [];
  BankRegisterModel? _selectedRegister;

  List<BankRegisterModel> get bankRegisters => _bankRegisters;
  BankRegisterModel? get selectedRegister   => _selectedRegister;

  // ── Form fields ───────────────────────────────────────────────────────────────
  double? _amount;
  DateTime _depositDate = DateTime.now();
  String _reference = '';

  double? get amount       => _amount;
  DateTime get depositDate => _depositDate;
  String get reference     => _reference;

  // ── Recent deposits (from overview recentBankDeposits) ────────────────────────
  List<DepositRecord> _recentDeposits = const [];
  List<DepositRecord> get recentDeposits => _recentDeposits;

  AppLocalizations? _l10n(BuildContext? context) =>
      context != null ? AppLocalizations.of(context) : null;

  // ── Init ──────────────────────────────────────────────────────────────────────

  Future<void> init([BuildContext? context]) async {
    final l10n = _l10n(context);
    _state = LockerDepositState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _token = await _sessionService.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n?.lockerSessionExpired ??
            'Session expired. Please log in again.');
        return;
      }

      // ── Parallel fetch: bank registers + overview KPIs ─────────────────────
      final results = await Future.wait([
        _repository.getBankRegisters(token: _token!),
        _repository.getOverview(token: _token!),
      ]);

      _bankRegisters = results[0] as List<BankRegisterModel>;
      final overview = results[1] as LockerOverviewData;

      _vaultBalance  = overview.kpis.lockerVaultBalance;
      _vaultCurrency = 'SAR';
      if (l10n != null) {
        _vaultAccountLabel = l10n.lockerCashInTransit;
      }

      _recentDeposits = overview.recentBankDeposits
          .map(DepositRecord.fromOverview)
          .toList();

      _state = LockerDepositState.idle;
      notifyListeners();
    } on UnauthorisedException {
      _setError(l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.');
    } on BadRequestException catch (e) {
      _setError(l10n != null
          ? l10n.lockerBadRequest(_friendly(e))
          : 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e) {
      _setError(l10n?.lockerFailedLoadData ?? 'Failed to load data.');
      debugLog('[LockerDepositVM] Init error: $e');
    }
  }

  // ── Form setters ──────────────────────────────────────────────────────────────

  void selectRegister(BankRegisterModel? register) {
    _selectedRegister = register;
    notifyListeners();
  }

  void setAmount(String raw) {
    _amount = double.tryParse(raw.replaceAll(',', ''));
    notifyListeners();
  }

  void setDepositDate(DateTime date) {
    _depositDate = date;
    notifyListeners();
  }

  void setReference(String value) {
    _reference = value.trim();
    notifyListeners();
  }

  void clearSuccess() {
    if (_state == LockerDepositState.success) {
      _state = LockerDepositState.idle;
      _successMessage = null;
      notifyListeners();
    }
  }

  /// Dismisses a submit-time error back to idle once the UI has shown it
  /// (e.g. via a SnackBar). Safe to call even if no error is pending.
  void clearError() {
    if (_state == LockerDepositState.error) {
      _state = LockerDepositState.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────────

  /// Localized amount validation; callers should pass [l10n] from the view.
  String? amountErrorFor(AppLocalizations l10n) {
    if (_amount == null) return null;
    if (_amount! <= 0) return l10n.lockerAmountMustBePositive;
    if (_amount! > _vaultBalance) return l10n.lockerAmountExceedsVault;
    return null;
  }

  bool get canSubmit =>
      _selectedRegister != null &&
          _amount != null &&
          _amount! > 0 &&
          _amount! <= _vaultBalance &&
          _state != LockerDepositState.submitting;

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> submitDeposit({BuildContext? context}) async {
    final l10n = _l10n(context);
    if (!canSubmit) return;
    if (_token == null) {
      _setError(l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.');
      return;
    }

    _state = LockerDepositState.submitting;
    _errorMessage = null;
    _isSlowNetwork = false;
    notifyListeners();

    // Flag a slow connection if the request is still pending after a few
    // seconds, so the UI can show a "still working…" hint instead of
    // looking frozen — without blocking or retrying the actual request.
    final slowNetworkTimer = Timer(const Duration(seconds: 4), () {
      if (_state == LockerDepositState.submitting) {
        _isSlowNetwork = true;
        notifyListeners();
      }
    });

    // Snapshot the fields being submitted — the form resets on success,
    // so we need these to build the optimistic recent-deposit row.
    final register       = _selectedRegister!;
    final submittedAmount = _amount!;
    final submittedDate   = _depositDate;
    final submittedRef    = _reference;

    try {
      final result = await _repository.postDeposit(
        token            : _token!,
        cashBankAccountId: register.id,
        amount           : submittedAmount,
        depositedAt      : submittedDate,
        reference        : submittedRef,
      );

      // Reconcile with the server response (source of truth for the
      // posted amount/ids) rather than blindly trusting local input.
      _vaultBalance -= result.amount;

      final newRecord = DepositRecord(
        id          : result.depositId,
        reference   : result.reference.isNotEmpty
            ? result.reference
            : (submittedRef.isNotEmpty ? submittedRef : 'DEP-${result.depositId}'),
        registerName: register.name,
        branchName  : '',
        amount      : result.amount,
        currency    : _vaultCurrency,
        depositedAt : submittedDate,
      );
      _recentDeposits = [newRecord, ..._recentDeposits];

      // Reset form
      _selectedRegister = null;
      _amount           = null;
      _depositDate      = DateTime.now();
      _reference        = '';

      _state          = LockerDepositState.success;
      _successMessage = l10n?.lockerDepositPostedSuccess(result.journalId.toString()) ??
          'Deposit posted successfully. GL entry recorded (Journal #${result.journalId}).';
      notifyListeners();

      debugLog('[LockerDepositVM] Deposit submitted. '
          'depositId=${result.depositId} journalId=${result.journalId}');
    } on UnauthorisedException {
      _setError(l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.');
    } on BadRequestException catch (e) {
      _setError(l10n != null
          ? l10n.lockerBadRequest(_friendly(e))
          : 'Bad request: ${_friendly(e)}');
    } on TimeoutException {
      _setError(l10n?.lockerSomethingWentWrong ??
          'Something went wrong.');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e, st) {
      _setError(l10n?.lockerSomethingWentWrong ??
          'Something went wrong.');
      debugLog('[LockerDepositVM] Submit error: $e\n$st');
    } finally {
      slowNetworkTimer.cancel();
      _isSlowNetwork = false;
    }
  }

  Future<void> refresh([BuildContext? context]) => init(context);

  // ── Private ───────────────────────────────────────────────────────────────────

  void _setError(String msg) {
    _state = LockerDepositState.error;
    _errorMessage = msg;
    notifyListeners();
    debugLog('[LockerDepositVM] Error: $msg');
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
