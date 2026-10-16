import 'package:flutter/material.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/technician_advance_model.dart';
import '../../../models/technician_salary_payment_model.dart';
import '../../../services/session_service.dart';

class PosSalariesViewModel extends ChangeNotifier {
  PosSalariesViewModel({
    PosRepository? posRepository,
    SessionService? sessionService,
  })  : _posRepository = posRepository ?? PosRepository(),
        _sessionService = sessionService ?? SessionService();

  final PosRepository _posRepository;
  final SessionService _sessionService;

  List<TechSalaryPayment> salaryPayments = [];
  bool isLoadingSalaryPayments = false;
  double salaryPaymentsTotalNet = 0;
  int salaryPaymentsTotal = 0;

  List<TechAdvanceTransaction> salaryAdvanceTransactions = [];
  bool isLoadingSalaryAdvances = false;
  double salaryAdvancesTotalOutstanding = 0;
  double salaryAdvancesTotalIssued = 0;
  double salaryAdvancesTotalDeducted = 0;

  late DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _to = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime get fromDate => _from;
  DateTime get toDate => _to;

  final Map<String, String> _ackInFlight = {};

  bool isSalaryAcceptInFlight(String id) => _ackInFlight[id] == 'accepted';
  bool isSalaryRejectInFlight(String id) => _ackInFlight[id] == 'rejected';

  Future<void> applyStartDate(DateTime d) async {
    var next = DateTime(d.year, d.month, d.day);
    final end = DateTime(_to.year, _to.month, _to.day);
    if (next.isAfter(end)) next = end;
    _from = next;
    _clearForReload();
    notifyListeners();
    await fetchAll();
  }

  Future<void> applyEndDate(DateTime d) async {
    var next = DateTime(d.year, d.month, d.day);
    final start = DateTime(_from.year, _from.month, _from.day);
    if (next.isBefore(start)) _from = next;
    _to = next;
    _clearForReload();
    notifyListeners();
    await fetchAll();
  }

  void _clearForReload() {
    salaryPayments = [];
    salaryAdvanceTransactions = [];
    salaryPaymentsTotalNet = 0;
    salaryPaymentsTotal = 0;
    isLoadingSalaryPayments = true;
    isLoadingSalaryAdvances = true;
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchSalaryPayments(), fetchSalaryAdvances()]);
  }

  Future<void> fetchSalaryPayments() async {
    isLoadingSalaryPayments = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken();
      if (token == null || token.isEmpty) return;
      final res = await _posRepository.getCashierSalaryPayments(
        token,
        from: _from,
        to: _to,
      );
      if (res.success) {
        salaryPayments = res.payments;
        salaryPaymentsTotalNet = res.totalNetPaid;
        salaryPaymentsTotal = res.total;
      }
    } finally {
      isLoadingSalaryPayments = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalaryAdvances() async {
    isLoadingSalaryAdvances = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken();
      if (token == null || token.isEmpty) return;
      final res = await _posRepository.getCashierSalaryAdvances(
        token,
        from: _from,
        to: _to,
      );
      if (res.success) {
        salaryAdvanceTransactions = res.transactions;
        salaryAdvancesTotalOutstanding = res.totalOutstanding;
        salaryAdvancesTotalIssued = res.totalIssued;
        salaryAdvancesTotalDeducted = res.totalDeducted;
      }
    } finally {
      isLoadingSalaryAdvances = false;
      notifyListeners();
    }
  }

  Future<String?> respondToSalaryPayment(
    String paymentId,
    String response, {
    BuildContext? context,
  }) async {
    if (_ackInFlight.containsKey(paymentId)) return null;
    final l10n = context != null ? AppLocalizations.of(context) : null;
    _ackInFlight[paymentId] = response;
    notifyListeners();
    try {
      final token = await _sessionService.getToken();
      if (token == null) return l10n?.techNotSignedIn ?? 'Not signed in';
      final result = await _posRepository.respondToCashierSalaryPayment(
        token,
        paymentId,
        response,
      );
      if (result['success'] != true) {
        return result['message']?.toString() ??
            (l10n?.techCouldNotSubmitResponse ?? 'Could not submit response');
      }
      final idx = salaryPayments.indexWhere((p) => p.id == paymentId);
      if (idx >= 0) {
        final old = salaryPayments[idx];
        salaryPayments[idx] = TechSalaryPayment(
          id: old.id,
          period: old.period,
          paymentDate: old.paymentDate,
          basicSalary: old.basicSalary,
          commissionAmount: old.commissionAmount,
          advanceDeduction: old.advanceDeduction,
          penalties: old.penalties,
          penaltyNotes: old.penaltyNotes,
          totalDeductions: old.totalDeductions,
          grossSalary: old.grossSalary,
          netSalary: old.netSalary,
          payFromAccountName: old.payFromAccountName,
          method: old.method,
          status: old.status,
          technicianAckStatus:
              result['technicianAckStatus']?.toString() ?? response,
          technicianAckAt: DateTime.tryParse(
                result['technicianAckAt']?.toString() ?? '',
              ) ??
              DateTime.now(),
          notes: old.notes,
          journalId: old.journalId,
          createdAt: old.createdAt,
        );
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _ackInFlight.remove(paymentId);
      notifyListeners();
    }
  }
}
