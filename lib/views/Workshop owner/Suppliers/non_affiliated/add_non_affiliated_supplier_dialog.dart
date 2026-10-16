import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/owner_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import '../../widgets/owner_sheet_actions.dart';
import 'non_affilidated_supplier_models.dart';

/// Add **or** edit a non-affiliated supplier.
///
/// - Create mode (default): POSTs a new supplier.
/// - Edit mode (`editing` supplied): PATCHes the existing supplier's info.
///
/// Pops with the resulting [NonAffiliatedSupplier] on success (the caller
/// uses that as the signal to refresh its list), or `null` if cancelled.
class AddNonAffiliatedSupplierDialog extends StatefulWidget {
  final String token;
  final NonAffiliatedSuppliersRepository repo;
  final NonAffiliatedSupplier? editing;

  /// Branch to attach a newly-created supplier to (ignored in edit mode,
  /// where the supplier keeps its existing branchId). Pass the workshop's
  /// currently active/selected branch id from the caller; omit for a
  /// workshop-wide supplier if your backend allows a null branchId.
  final String? defaultBranchId;

  const AddNonAffiliatedSupplierDialog({
    super.key,
    required this.token,
    required this.repo,
    this.editing,
    this.defaultBranchId,
  });

  @override
  State<AddNonAffiliatedSupplierDialog> createState() =>
      _AddNonAffiliatedSupplierDialogState();
}

class _AddNonAffiliatedSupplierDialogState
    extends State<AddNonAffiliatedSupplierDialog> {
  late final AddNonAffiliatedSupplierForm _form;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _form = AddNonAffiliatedSupplierForm();
    final s = widget.editing;
    if (s != null) {
      _form.nameCtrl.text = s.name;
      _form.contactCtrl.text = s.contactPerson == '—' ? '' : s.contactPerson;
      _form.phoneCtrl.text = s.mobile;
      _form.emailCtrl.text = s.email;
      _form.vatCtrl.text = s.vatId == '—' ? '' : s.vatId;
      _form.crCtrl.text = s.cr == '—' ? '' : s.cr;
      _form.addressCtrl.text = s.address;
      // Opening balance is fixed once set on the backend — shown read-only
      // in edit mode below, so we don't bother prefilling/parsing it here.
      _form.openingCtrl.text = s.openingBalance.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context)!;
    try {
      if (_isEdit) {
        final res = await widget.repo.updateSupplierInfo(
          widget.token,
          id: widget.editing!.id,
          name: _form.nameCtrl.text.trim(),
          phone: _form.phoneCtrl.text.trim(),
          email: _form.emailCtrl.text.trim(),
          address: _form.addressCtrl.text.trim(),
          vatId: _form.vatCtrl.text.trim(),
          crNumber: _form.crCtrl.text.trim(),
          contactPerson: _form.contactCtrl.text.trim(),
          branchId: widget.editing!.branchId,
        );
        if (!mounted) return;
        if (res.success) {
          Navigator.pop(context, widget.editing);
        } else {
          setState(() => _error = l10n.ownerNonAffiliatedUpdateFailed);
        }
      } else {
        final opening = double.tryParse(_form.openingCtrl.text.trim()) ?? 0.0;
        final res = await widget.repo.createSupplier(
          widget.token,
          name: _form.nameCtrl.text.trim(),
          phone: _form.phoneCtrl.text.trim(),
          email: _form.emailCtrl.text.trim(),
          vatId: _form.vatCtrl.text.trim(),
          crNumber: _form.crCtrl.text.trim(),
          contactPerson: _form.contactCtrl.text.trim(),
          address: _form.addressCtrl.text.trim(),
          openingBalance: opening,
          openingBalanceDate: _isoFromDdMmYyyy(_form.dateCtrl.text.trim()),
          branchId: widget.defaultBranchId,
        );
        if (!mounted) return;
        if (res.success && res.supplier != null) {
          Navigator.pop(context, res.supplier);
        } else {
          setState(() => _error = l10n.ownerNonAffiliatedAddFailed);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.ownerNonAffiliatedNetworkError('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Converts the dd/MM/yyyy text shown in the date field to yyyy-MM-dd for
  /// the API. Falls back to today if parsing fails.
  String _isoFromDdMmYyyy(String s) {
    final parts = s.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      }
    }
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit
                            ? l10n.ownerNonAffiliatedEditTitle
                            : l10n.ownerNonAffiliatedAddTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _submitting ? null : () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Supplier name *
                _FieldLabel(l10n.ownerNonAffiliatedSupplierName),
                const SizedBox(height: 7),
                _TextInput(
                  controller: _form.nameCtrl,
                  hint: l10n.ownerNonAffiliatedNameHint,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? l10n.ownerNonAffiliatedRequired
                          : null,
                ),
                const SizedBox(height: 14),

                // Contact person
                _FieldLabel(l10n.ownerNonAffiliatedContactPerson),
                const SizedBox(height: 7),
                _TextInput(controller: _form.contactCtrl, hint: ''),
                const SizedBox(height: 14),

                // Phone + Email
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(l10n.ownerNonAffiliatedPhone),
                          const SizedBox(height: 7),
                          _TextInput(
                            controller: _form.phoneCtrl,
                            hint: '',
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(l10n.ownerNonAffiliatedEmail),
                          const SizedBox(height: 7),
                          _TextInput(
                            controller: _form.emailCtrl,
                            hint: '',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // VAT + CR
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(l10n.ownerNonAffiliatedVatId),
                          const SizedBox(height: 7),
                          _TextInput(controller: _form.vatCtrl, hint: ''),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(l10n.ownerNonAffiliatedCrNumber),
                          const SizedBox(height: 7),
                          _TextInput(controller: _form.crCtrl, hint: ''),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Address
                _FieldLabel(l10n.ownerNonAffiliatedAddress),
                const SizedBox(height: 7),
                _TextInput(
                  controller: _form.addressCtrl,
                  hint: '',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),

                // Opening balance + As of date — only on create; the
                // backend treats opening balance as a fixed seed value.
                if (!_isEdit)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(
                              l10n.ownerNonAffiliatedOpeningBalanceSar(
                                l10n.ownerCurrencySar,
                              ),
                            ),
                            const SizedBox(height: 7),
                            _TextInput(
                              controller: _form.openingCtrl,
                              hint: ownerLocalizeDigits(context, '0.00'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(l10n.ownerNonAffiliatedAsOfDate),
                            const SizedBox(height: 7),
                            _TextInput(
                              controller: _form.dateCtrl,
                              hint: l10n.ownerNonAffiliatedDateHint,
                              suffixIcon: Icons.calendar_today_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (!_isEdit) const SizedBox(height: 24) else const SizedBox(height: 10),

                // Buttons
                OwnerSheetActions(
                  onCancel: () => Navigator.pop(context),
                  onPrimary: _submitting ? null : _submit,
                  isLoading: _submitting,
                  cancelLabel: l10n.ownerCommonCancel,
                  primaryLabel: _isEdit
                      ? l10n.ownerRolesSaveChanges
                      : l10n.ownerNonAffiliatedAddSupplier,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small shared widgets ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(suffixIcon, size: 16, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
