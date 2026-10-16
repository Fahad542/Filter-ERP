import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/pos_payment_method.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_keyboard_locale.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../services/softpos_access_service.dart';
import '../../../utils/toast_service.dart';

/// Optional handler to persist PAY draft to `PATCH …/payment-method` before closing.
typedef InvoicePaymentDraftPersistFn = Future<String?> Function(
    InvoicePaymentChoiceResult proposal,
    );

/// Result of [showInvoicePaymentChoiceDialog].
class InvoicePaymentChoiceResult {
  final bool isCorporate;
  final Set<PaymentMethod> payments;
  final Map<PaymentMethod, double> paymentAmounts;
  final Set<String> employeeIds;

  const InvoicePaymentChoiceResult({
    required this.isCorporate,
    required this.payments,
    this.paymentAmounts = const {},
    this.employeeIds = const <String>{},
  });
}

Future<InvoicePaymentChoiceResult?> showInvoicePaymentChoiceDialog(
    BuildContext context, {
      bool? initialIsCorporate,
      Set<PaymentMethod>? initialPayments,
      Map<PaymentMethod, double>? initialPaymentAmounts,
      Set<String>? initialEmployeeIds,
      double totalAmount = 0,
      InvoicePaymentDraftPersistFn? persistDraftFn,
      Future<String?> Function()? clearPersistedDraftFn,
      /// When true (e.g. cashier order hub), Individual/Corporate matches the order and cannot be changed.
      bool customerTypeLocked = false,
    }) {
  return showDialog<InvoicePaymentChoiceResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _InvoicePaymentChoiceDialogShell(
      initialIsCorporate: initialIsCorporate,
      initialPayments: initialPayments,
      initialPaymentAmounts: initialPaymentAmounts,
      initialEmployeeIds: initialEmployeeIds,
      totalAmount: totalAmount,
      persistDraftFn: persistDraftFn,
      clearPersistedDraftFn: clearPersistedDraftFn,
      customerTypeLocked: customerTypeLocked,
    ),
  );
}

class _InvoicePaymentChoiceDialogShell extends StatefulWidget {
  final bool? initialIsCorporate;
  final Set<PaymentMethod>? initialPayments;
  final Map<PaymentMethod, double>? initialPaymentAmounts;
  /// Prefill from cashier order-summary flow when reopening dialog.
  final Set<String>? initialEmployeeIds;
  final double totalAmount;
  final InvoicePaymentDraftPersistFn? persistDraftFn;
  final Future<String?> Function()? clearPersistedDraftFn;
  final bool customerTypeLocked;

  const _InvoicePaymentChoiceDialogShell({
    this.initialIsCorporate,
    this.initialPayments,
    this.initialPaymentAmounts,
    this.initialEmployeeIds,
    this.totalAmount = 0,
    this.persistDraftFn,
    this.clearPersistedDraftFn,
    this.customerTypeLocked = false,
  });

  @override
  State<_InvoicePaymentChoiceDialogShell> createState() =>
      _InvoicePaymentChoiceDialogShellState();
}

class _InvoicePaymentChoiceDialogShellState
    extends State<_InvoicePaymentChoiceDialogShell> {
  final _panelKey = GlobalKey<InvoicePaymentChoicePanelState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.sizeOf(context);
    final maxW = min(560.0, mq.width - 40);
    final maxH = min(600.0, mq.height * 0.85);

    return Dialog(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      backgroundColor: AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.posPaymentMethodTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.posPaymentMethodDescription,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: InvoicePaymentChoicePanel(
                key: _panelKey,
                embedded: true,
                initialIsCorporate: widget.initialIsCorporate,
                initialPayments: widget.initialPayments,
                initialPaymentAmounts: widget.initialPaymentAmounts,
                initialEmployeeIds: widget.initialEmployeeIds,
                totalAmount: widget.totalAmount,
                customerTypeLocked: widget.customerTypeLocked,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.posCommonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.onPrimaryLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _panelKey.currentState?.submitSave(
                      persistDraftFn: widget.persistDraftFn,
                    ),
                    child: Text(l10n.posCommonSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable payment method form (embedded in takeaway checkout or payment dialog).
class InvoicePaymentChoicePanel extends StatefulWidget {
  final bool? initialIsCorporate;
  final Set<PaymentMethod>? initialPayments;
  final Map<PaymentMethod, double>? initialPaymentAmounts;
  final Set<String>? initialEmployeeIds;
  final double totalAmount;
  final bool customerTypeLocked;
  final bool paymentSelectionLocked;
  final bool embedded;

  const InvoicePaymentChoicePanel({
    super.key,
    this.initialIsCorporate,
    this.initialPayments,
    this.initialPaymentAmounts,
    this.initialEmployeeIds,
    this.totalAmount = 0,
    this.customerTypeLocked = false,
    this.paymentSelectionLocked = false,
    this.embedded = false,
  });

  @override
  InvoicePaymentChoicePanelState createState() =>
      InvoicePaymentChoicePanelState();
}

class InvoicePaymentChoicePanelState extends State<InvoicePaymentChoicePanel> {
  bool? _isCorporate;
  late Set<PaymentMethod> _selected;
  final Map<PaymentMethod, TextEditingController> _amountControllers = {};

  bool _draftSaving = false;
  bool _draftClearing = false;

  static const _corporateMethods = <PaymentMethod>[
    PaymentMethod.monthlyBilling,
    PaymentMethod.bankTransfer,
    PaymentMethod.cash,
    PaymentMethod.card,
    PaymentMethod.wallet,
  ];

  static const _retailDisplayOrder = <PaymentMethod>[
    PaymentMethod.cash,
    PaymentMethod.card,
    PaymentMethod.tapToPay,
    PaymentMethod.bankTransfer,
    PaymentMethod.tabby,
    PaymentMethod.tamara,
  ];

  bool get _isSplitMode => _selected.length > 1;
  double get _safeTotal => widget.totalAmount > 0 ? widget.totalAmount : 0.0;
  String _languageCode = 'en';

  @override
  void initState() {
    super.initState();
    _isCorporate = widget.initialIsCorporate;
    final initial = widget.initialPayments;
    if (initial != null && initial.isNotEmpty) {
      _selected = Set<PaymentMethod>.from(initial)
        ..remove(PaymentMethod.employees);
    } else {
      _selected = {};
    }
    // Do not read Localizations/Theme here. initState cannot depend on inherited widgets.
    _syncAmountControllers(seedFromInitial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextLanguageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode == nextLanguageCode) return;
    _languageCode = nextLanguageCode;
    // Safe place to apply locale-specific digit formatting to initial/auto-filled amounts.
    _syncAmountControllers(seedFromInitial: true);
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearAllControllers() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    _amountControllers.clear();
  }

  /// Changing Individual ↔ Corporate resets payment selections; confirm when there is something to lose.
  bool _shouldConfirmCustomerTypeSwitch() {
    if (_selected.isEmpty) return false;
    if (_isCorporate == true) {
      if (_selected.length > 1) return true;
      if (_selected.length == 1) {
        return _selected.single != PaymentMethod.monthlyBilling;
      }
    }
    return true;
  }

  Future<void> _onCustomerTypeTapped(bool wantCorporate) async {
    if (widget.customerTypeLocked) return;
    final l10n = AppLocalizations.of(context)!;
    if (_isCorporate == wantCorporate) return;

    final firstPick = _isCorporate == null;
    if (!firstPick &&
        _shouldConfirmCustomerTypeSwitch() &&
        wantCorporate != _isCorporate) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final maxW = min(340.0, MediaQuery.sizeOf(ctx).width - 56);
          return AlertDialog(
            constraints: BoxConstraints(maxWidth: maxW),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              l10n.posPaymentChangeCustomerTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
                fontSize: 17,
              ),
            ),
            content: Text(
              l10n.posPaymentChangeCustomerBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  l10n.posCommonCancel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryLight.withValues(alpha: 0.85),
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.onPrimaryLight,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  l10n.posPaymentChangeCustomerButton,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      );
      if (go != true) return;
    }
    if (!mounted) return;

    setState(() {
      _clearAllControllers();
      _isCorporate = wantCorporate;
      _selected = {};
      _syncAmountControllers();
    });
  }

  void _toggleRetailMethod(PaymentMethod pm, bool isSelected) {
    if (widget.paymentSelectionLocked) return;
    final wasRetail = _isCorporate == false;
    final oldLen = wasRetail ? _selected.length : 0;
    setState(() {
      if (isSelected) {
        _selected.remove(pm);
      } else {
        _selected.add(pm);
      }
      final newLen = _isCorporate == false ? _selected.length : 0;
      final oneToMany =
          wasRetail && oldLen == 1 && newLen >= 2;
      _syncAmountControllers(fromOneToManySplit: oneToMany);
    });
  }

  void _toggleCorporateMethod(PaymentMethod pm, bool isSelected) {
    if (widget.paymentSelectionLocked) return;
    if (!_corporateMethods.contains(pm)) return;
    final wasCorp = _isCorporate == true;
    final oldLen = wasCorp ? _selected.length : 0;
    setState(() {
      if (isSelected) {
        _selected.remove(pm);
      } else {
        _selected.add(pm);
      }
      final newLen = _isCorporate == true ? _selected.length : 0;
      final oneToMany = wasCorp && oldLen == 1 && newLen >= 2;
      _syncAmountControllers(fromOneToManySplit: oneToMany);
    });
  }

  String _amountToText(double v, {String? languageCode}) {
    final raw = (v - v.roundToDouble()).abs() < 0.0001
        ? v.round().toString()
        : v.toStringAsFixed(2);
    return AppTranslationService.localizeDigitsForLanguage(
      raw,
      languageCode ?? _languageCode,
    );
  }

  void _syncAmountControllers({
    bool seedFromInitial = false,
    /// True when user goes from 1 method (total auto-filled) to 2+ — clear split fields.
    bool fromOneToManySplit = false,
  }) {
    final current = Set<PaymentMethod>.from(_amountControllers.keys);
    final desired = _isCorporate != null
        ? Set<PaymentMethod>.from(_selected)
        : <PaymentMethod>{};

    for (final removed in current.difference(desired)) {
      _amountControllers[removed]?.dispose();
      _amountControllers.remove(removed);
    }

    for (final pm in desired) {
      final existing = _amountControllers[pm];
      if (existing != null) continue;
      final initialAmount = seedFromInitial
          ? (widget.initialPaymentAmounts != null
          ? widget.initialPaymentAmounts![pm]
          : null)
          : null;
      _amountControllers[pm] = TextEditingController(
        text: initialAmount != null && initialAmount > 0
            ? _amountToText(initialAmount) : '',
      );
    }

    if (!_isSplitMode && _isCorporate != null && _selected.length == 1) {
      final only = _selected.first;
      _amountControllers[only]?.text = _amountToText(_safeTotal);
    }

    if (_isSplitMode && fromOneToManySplit) {
      for (final pm in _selected) {
        _amountControllers[pm]?.text = '';
      }
    }
  }

  double _parseAmount(TextEditingController c) {
    final raw = c.text
        .trim()
        .replaceAll(',', '')
    // Convert Arabic-Indic digits → ASCII
        .replaceAllMapped(RegExp(r'[٠-٩]'), (m) {
      return (m.group(0)!.codeUnitAt(0) - 0x0660).toString();
    });
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }
  double get _splitSum {
    double sum = 0;
    for (final pm in _selected) {
      final c = _amountControllers[pm];
      if (c != null) sum += _parseAmount(c);
    }
    return sum;
  }

  double get _remainingAmount => _safeTotal - _splitSum;

  bool get _canSave {
    if (_isCorporate == null || _selected.isEmpty) return false;
    if (!_isSplitMode) return true;
    for (final pm in _selected) {
      final c = _amountControllers[pm];
      if (c == null || _parseAmount(c) <= 0) return false;
    }
    return _remainingAmount.abs() <= 0.05;
  }

  String _methodLabel(AppLocalizations l10n, PaymentMethod pm) {
    switch (pm) {
      case PaymentMethod.cash:
        return l10n.posPaymentCash;
      case PaymentMethod.card:
        return l10n.posPaymentCard;
      case PaymentMethod.tapToPay:
        return l10n.posPaymentTapToPay;
      case PaymentMethod.bankTransfer:
        return l10n.posPaymentBankTransfer;
      case PaymentMethod.tamara:
        return l10n.posPaymentTamara;
      case PaymentMethod.tabby:
        return l10n.posPaymentTabby;
      case PaymentMethod.wallet:
        return l10n.posPaymentWallet;
      case PaymentMethod.monthlyBilling:
        return l10n.posPaymentMonthlyBilling;
      case PaymentMethod.employees:
        return l10n.posPaymentEmployees;
    }
  }

  Widget _paymentTile(PaymentMethod pm, {required bool isCorporateMode}) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selected.contains(pm);
    final locked = widget.paymentSelectionLocked;
    return Opacity(
      opacity: locked ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: locked
              ? null
              : () {
                  if (isCorporateMode) {
                    _toggleCorporateMethod(pm, isSelected);
                  } else {
                    _toggleRetailMethod(pm, isSelected);
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFFFCFDFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.secondaryLight.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _methodLabel(l10n, pm),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isSelected
                          ? AppColors.secondaryLight
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.onPrimaryLight,
                    ),
                  ),
                if (locked && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentGrid({
    required List<PaymentMethod> methods,
    required bool isCorporateMode,
  }) {
    const spacing = 8.0;
    const cols = 3;
    final rows = <Widget>[];
    for (var i = 0; i < methods.length; i += cols) {
      final rowTiles = <Widget>[];
      for (var k = 0; k < cols; k++) {
        if (k > 0) rowTiles.add(const SizedBox(width: spacing));
        final idx = i + k;
        if (idx < methods.length) {
          rowTiles.add(
            Expanded(
              child: _paymentTile(
                methods[idx],
                isCorporateMode: isCorporateMode,
              ),
            ),
          );
        } else {
          rowTiles.add(const Expanded(child: SizedBox()));
        }
      }
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowTiles));
      if (i + cols < methods.length) {
        rows.add(const SizedBox(height: spacing));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _splitAmountsEditor() {
    final l10n = AppLocalizations.of(context)!;
    final methods = _selected.toList();
    const spacing = 8.0;
    const cols = 3;
    final rows = <Widget>[];
    for (var i = 0; i < methods.length; i += cols) {
      final rowChildren = <Widget>[];
      for (var k = 0; k < cols; k++) {
        if (k > 0) rowChildren.add(const SizedBox(width: spacing));
        final idx = i + k;
        rowChildren.add(
          Expanded(
            child: idx < methods.length
                ? _amountField(methods[idx])
                : const SizedBox(),
          ),
        );
      }
      rows.add(Row(children: rowChildren));
      if (i + cols < methods.length) {
        rows.add(const SizedBox(height: spacing));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.posPaymentAmountByMethod,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _remainingAmount.abs() <= 0.05
                ? const Color(0xFFEAF8EE)
                : const Color(0xFFFFF4E5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _remainingAmount.abs() <= 0.05
                  ? const Color(0xFFA7D7B2)
                  : const Color(0xFFF4C27A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _remainingAmount.abs() <= 0.05 ? Icons.check_circle : Icons.info_outline,
                size: 16,
                color: _remainingAmount.abs() <= 0.05
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFB26A00),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.posPaymentRemaining(
                    AppTranslationService.localizeDigitsForLanguage(
                      _remainingAmount.toStringAsFixed(2),
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _remainingAmount.abs() <= 0.05
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF8B5E00),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountField(PaymentMethod pm) {
    final l10n = AppLocalizations.of(context)!;
    final c = _amountControllers[pm]!;
    return TextFormField(
      controller: c,
      readOnly: widget.paymentSelectionLocked,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      hintLocales: appKeyboardHintLocales(context),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^[\d٠-٩]*[.,]?[\d٠-٩]{0,2}$')),
      ],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: l10n.posPaymentAmountLabel(_methodLabel(l10n, pm)),
        labelStyle: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryLight,
        ),
        suffixText: l10n.posCommonSar,
        suffixStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.55,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Map<PaymentMethod, double> _buildPaymentAmounts() {
    if (_selected.isEmpty) return const {};
    if (_selected.length == 1) {
      return {_selected.first: _safeTotal};
    }
    final out = <PaymentMethod, double>{};
    for (final pm in _selected) {
      final c = _amountControllers[pm];
      if (c != null) out[pm] = _parseAmount(c);
    }
    return out;
  }

  bool get canSave => _canSave;

  InvoicePaymentChoiceResult? collectResult() {
    if (!_canSave || _isCorporate == null) return null;
    return InvoicePaymentChoiceResult(
      isCorporate: _isCorporate!,
      payments: Set<PaymentMethod>.from(_selected),
      paymentAmounts: _buildPaymentAmounts(),
      employeeIds: const <String>{},
    );
  }

  Future<void> submitSave({
    InvoicePaymentDraftPersistFn? persistDraftFn,
  }) async {
    if (!_canSave || _draftSaving || _draftClearing) return;
    final proposal = collectResult();
    if (proposal == null) return;
    if (persistDraftFn != null) {
      setState(() => _draftSaving = true);
      try {
        final err = await persistDraftFn(proposal);
        if (!mounted) return;
        setState(() => _draftSaving = false);
        if (err != null) {
          ToastService.showError(context, err);
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _draftSaving = false);
          ToastService.showError(context, e.toString());
        }
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(proposal);
  }

  Future<void> clearPersistedDraft({
    required Future<String?> Function() clearFn,
  }) async {
    if (_draftSaving || _draftClearing) return;
    setState(() => _draftClearing = true);
    try {
      final err = await clearFn();
      if (!mounted) return;
      setState(() => _draftClearing = false);
      if (err != null) {
        ToastService.showError(context, err);
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _draftClearing = false);
      ToastService.showError(context, e.toString());
    }
  }

  Widget _buildPaymentFormColumn(AppLocalizations l10n) {
    final retailMethods = _retailDisplayOrder
        .where((pm) =>
            pm.isRetailSelectable &&
            (pm != PaymentMethod.tapToPay || isSoftPosUiEnabled))
        .toList();
    if (!isSoftPosUiEnabled && _selected.contains(PaymentMethod.tapToPay)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selected.remove(PaymentMethod.tapToPay);
          _amountControllers[PaymentMethod.tapToPay]?.dispose();
          _amountControllers.remove(PaymentMethod.tapToPay);
        });
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(l10n.posPaymentCustomerType),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: RadioTheme(
            data: RadioThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryLight;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey.shade400;
                }
                return Colors.grey.shade500;
              }),
            ),
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  groupValue: _isCorporate,
                  onChanged: widget.customerTypeLocked
                      ? null
                      : (_) => _onCustomerTypeTapped(false),
                  title: Text(
                    l10n.posPaymentIndividual,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                RadioListTile<bool>(
                  value: true,
                  groupValue: _isCorporate,
                  onChanged: widget.customerTypeLocked
                      ? null
                      : (_) => _onCustomerTypeTapped(true),
                  title: Text(
                    l10n.posPaymentCorporate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        if (_isCorporate == null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.posPaymentTapCustomerFirst,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
        if (_isCorporate != null) ...[
          const SizedBox(height: 14),
          if (widget.paymentSelectionLocked) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.posOrdersPaymentMethodLocked,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F2F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _isCorporate!
                          ? Icons.corporate_fare_rounded
                          : Icons.shopping_bag_outlined,
                      size: 16,
                      color: AppColors.secondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isCorporate!
                            ? l10n.posPaymentCorporateMulti
                            : l10n.posPaymentMulti,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _paymentGrid(
                  methods: _isCorporate! ? _corporateMethods : retailMethods,
                  isCorporateMode: _isCorporate!,
                ),
                if (_isSplitMode) ...[
                  const SizedBox(height: 12),
                  _splitAmountsEditor(),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SoftPosAccessService.instance,
      builder: (context, _) => _buildPaymentDialogBody(context),
    );
  }

  Widget _buildPaymentDialogBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final form = _buildPaymentFormColumn(l10n);

    if (widget.embedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: form,
      );
    }

    final mq = MediaQuery.sizeOf(context);
    final maxW = min(560.0, mq.width - 40);
    final maxH = min(600.0, mq.height * 0.85);

    return Dialog(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      backgroundColor: AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.posPaymentMethodTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.posPaymentMethodDescription,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: form,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
