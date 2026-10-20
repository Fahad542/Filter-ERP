import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../models/pos_order_model.dart';
import '../../../models/pos_payment_method.dart';
import '../../../models/create_invoice_model.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/plate_transliterator.dart';
import '../../../utils/toast_service.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/invoice_maintenance_checklist.dart';
import '../../../services/invoice_auto_dispatch.dart';
import '../../../services/invoice_dialog_launcher.dart';
import '../../../widgets/pos_widgets.dart';
import '../Home Screen/pos_view_model.dart' as pvm;
import 'package:provider/provider.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../models/cashier_expense_models.dart';
import '../../../services/session_service.dart';
import 'pos_orders_hub_dialog.dart';
import '../Add Customer Screen/pos_add_customer_phone_format.dart';
import '../Add Customer Screen/add_customer_view_model.dart'
    show AddCustomerViewModel, PosAddCustomerVehicleKind, vehicleModelYearChoices;
import '../../../models/cashier_corporate_accounts_api_model.dart';
import '../../../models/customer_search_model.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/gcc_plate.dart' hide canonicalSaudiPlateForApi;
import '../../../widgets/gcc_plate_field.dart';
import '../../../widgets/pos_ksa_vehicle_make_model_row.dart';
import '../../../services/softpos_access_service.dart';
import '../../../services/softpos_bridge.dart';
import '../../../services/softpos_invoice_flow.dart';
import '../../../services/softpos_connection_guard.dart';
import '../../../widgets/softpos_settings_dialog.dart';
import '../../../widgets/pos_shimmer.dart';



String _reviewProductNameForLocale(
  BuildContext context, {
  required String productName,
  String? productNameArabic,
  String? fallback,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final ar = (productNameArabic ?? '').trim();
  if (lang == 'ar' && ar.isNotEmpty) return ar;
  final en = productName.trim();
  if (en.isNotEmpty) return en;
  return fallback ?? AppLocalizations.of(context)!.posReviewItemFallback;
}

String _reviewPlateDisplay(BuildContext context, String raw, {bool upperCase = true}) {
  final plate = raw.trim();
  if (plate.isEmpty) return '—';
  final normalized = upperCase ? plate.toUpperCase() : plate;
  return PlateTransliterator.localize(
    normalized,
    Localizations.localeOf(context).languageCode,
  );
}

String _invoiceLocalizedPlateOrDigits(BuildContext context, String value) {
  final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
  if (lang != 'ar') return value;
  final clean = value.trim();
  if (clean.isEmpty) return value;
  if (PlateTransliterator.looksLikePlate(clean)) {
    return PlateTransliterator.localize(clean, lang);
  }
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var out = clean;
  for (var i = 0; i < western.length; i++) {
    out = out.replaceAll(western[i], arabic[i]);
  }
  return out;
}

DateTime _invoiceHistoryOrderDate(SearchedCustomerOrder o) {
  try {
    return DateTime.parse(o.createdAt);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

SearchedCustomerOrder? _invoiceHistoryBestVehicleOrder(List<SearchedCustomerOrder> orders) {
  if (orders.isEmpty) return null;
  bool hasVehicleData(SearchedCustomerVehicle? v) {
    if (v == null) return false;
    return v.plateNo.trim().isNotEmpty ||
        v.make.trim().isNotEmpty ||
        v.model.trim().isNotEmpty ||
        ((v.vin ?? '').trim().isNotEmpty);
  }

  final sorted = [...orders]..sort((a, b) => _invoiceHistoryOrderDate(b).compareTo(_invoiceHistoryOrderDate(a)));
  for (final o in sorted) {
    if (hasVehicleData(o.vehicle)) return o;
  }
  return sorted.first;
}

SearchedCustomerVehicle? _invoiceHistoryVehicleSnapshot(SearchedCustomer c) =>
    _invoiceHistoryBestVehicleOrder(c.orders)?.vehicle;

// ── Mock data models used exclusively for this review screen ─────────────────

class ReviewLineItem {
  final String name;
  final String technicianName;
  /// VAT-inclusive catalog unit price (stored as-is for reference).
  final double unitPrice;
  final int qty;
  final double commissionRate; // e.g. 0.10 = 10%
  final String? discountType;
  final double discountValue;

  ReviewLineItem({
    required this.name,
    required this.technicianName,
    required this.unitPrice,
    required this.qty,
    this.commissionRate = 0.10,
    this.discountType,
    this.discountValue = 0.0,
  });

  static double _r2(double v) => (v * 100).roundToDouble() / 100;

  /// Unit price excluding VAT.
  double get unitPriceExclVat => _r2(unitPrice / 1.15);

  /// Gross amount before VAT (unitPriceExclVat × qty).
  double get grossBeforeVat => unitPriceExclVat * qty;

  /// Discount amount (computed on VAT-exclusive gross).
  double get discountAmount {
    if (discountType == 'amount' || discountType == 'fixed') {
      return discountValue;
    } else if (discountType == 'percentage' || discountType == 'percent') {
      return grossBeforeVat * (discountValue / 100);
    }
    return 0.0;
  }

  /// Total before VAT (after line discount).
  double get totalBeforeVat => grossBeforeVat - discountAmount;

  /// VAT on this line item.
  double get vatOnLine => totalBeforeVat * 0.15;

  /// Total with VAT.
  double get totalWithVat => totalBeforeVat + vatOnLine;

  // Backward compat aliases
  double get baseTotal => grossBeforeVat;
  double get lineTotal => totalBeforeVat;
  double get commission => lineTotal * commissionRate;
}

// ── Walk-in invoice dialog (StatefulWidget: controllers disposed with route) ─

String _invoiceDlgNormalizeSaudiPlate(String value) {
  return value.replaceAll(RegExp(r'[\s\-\|]'), '').toUpperCase();
}

bool _invoiceDlgIsArabicPlateLetter(String char) {
  return RegExp(r'^[\u0621-\u064A]$').hasMatch(char);
}

bool _invoiceDlgIsEnglishPlateLetter(String char) {
  return RegExp(r'^[A-Z]$').hasMatch(char);
}

/// Same input shaping as [PosAddCustomerView] `_saudiPlateInputFormatter`: letters first with ` - `,
/// digits-first typing supported via [shapeSaudiPlateForLiveInput].
TextInputFormatter invoiceDialogSaudiPlateInputFormatter(BuildContext context) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    final raw =
        _invoiceDlgNormalizeSaudiPlate(EnglishNumberFormatter.convert(newValue.text));
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final shaped = shapeSaudiPlateForLiveInput(raw);
    final formatted = shaped.displayText;

    if (shaped.rejectedExtraLetter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.posAddCustomerValidationVehiclePlateMaxThreeLetters,
        );
      });
    }
    if (shaped.rejectedExtraDigit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.posAddCustomerValidationVehiclePlateMaxFourDigits,
        );
      });
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  });
}

/// Same rules as [PosAddCustomerView] (`validateGccPlateInput` for Saudi).
String? invoiceDialogValidateSaudiPlate(BuildContext context, String? value) {
  final l10n = AppLocalizations.of(context)!;
  return validateSaudiPlateInput(
    value,
    emptyMessage: l10n.posInvoiceDetailsPlateRequired,
    threeLettersMessage: l10n.posInvoiceDetailsPlateSaudiThreeLetters,
    digitsMessage: l10n.posInvoiceDetailsPlateSaudiDigits,
    letterCharsMessage: l10n.posInvoiceDetailsPlateSaudiLetterChars,
  );
}

/// Loads a few customer rows when history autocompletes gain focus (same API as New Order).
class _WalkInInvoiceHistoryFocusLoader extends StatefulWidget {
  const _WalkInInvoiceHistoryFocusLoader({
    required this.focusNode,
    required this.textEditingController,
    required this.onLoadHints,
    required this.child,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final Future<void> Function() onLoadHints;
  final Widget child;

  @override
  State<_WalkInInvoiceHistoryFocusLoader> createState() => _WalkInInvoiceHistoryFocusLoaderState();
}

class _WalkInInvoiceHistoryFocusLoaderState extends State<_WalkInInvoiceHistoryFocusLoader> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _WalkInInvoiceHistoryFocusLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _kickAutocompleteRebuild() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    widget.textEditingController.notifyListeners();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) return;
    if (widget.textEditingController.text.trim().isNotEmpty) return;
    widget.onLoadHints().whenComplete(() {
      if (!mounted || !widget.focusNode.hasFocus) return;
      _kickAutocompleteRebuild();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

const TextStyle _kWalkInInvoiceDialogFieldStyle =
TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

/// Sentinel row in year [Autocomplete] to clear optional year (same as legacy dropdown `null`).
const String _kWalkInInvoiceYearNoneOption = '—';

InputDecoration _walkInInvoiceFieldDecoration(
    String label, {
      bool optional = false,
      String optionalSuffix = 'optional',
      bool compact = false,
    }) {
  final borderRadius = BorderRadius.circular(compact ? 10 : 12);
  final baseLabel = TextStyle(
    fontSize: compact ? 11.5 : null,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade700,
  );
  return InputDecoration(
    labelText: optional ? '$label ($optionalSuffix)' : label,
    labelStyle: compact ? baseLabel : null,
    floatingLabelStyle: compact
        ? baseLabel.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.secondaryLight,
    )
        : null,
    filled: true,
    fillColor: Colors.grey.shade50,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 10 : 14,
    ),
    border: OutlineInputBorder(borderRadius: borderRadius),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
  );
}

const PosAddCustomerMobileDial _walkInInvoiceMobileDial =
    PosAddCustomerMobileDial.saudiArabia;

String _walkInInvoiceMobileDisplay(String raw) {
  final normalized = PosAddCustomerPhoneFormat.normalizeNational(
    _walkInInvoiceMobileDial,
    raw,
  );
  return PosAddCustomerPhoneFormat.formatDigits(
    _walkInInvoiceMobileDial,
    normalized,
  );
}

String _walkInInvoiceMobilePayload(String raw) {
  final normalized = PosAddCustomerPhoneFormat.normalizeNational(
    _walkInInvoiceMobileDial,
    raw,
  );
  return normalized.isEmpty
      ? ''
      : '+${_walkInInvoiceMobileDial.dialDigits}$normalized';
}

/// Saudi mobile must start with 5 (same rule as Add Customer).
String? walkInNationalMobileValidator(
  String? raw,
  AppLocalizations l10n, {
  bool required = true,
}) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) {
    return required ? l10n.posInvoiceDetailsRequired : null;
  }
  if (PosAddCustomerPhoneFormat.isValidNational(
    _walkInInvoiceMobileDial,
    trimmed,
  )) {
    return null;
  }
  return l10n.posAddCustomerValidationMobileSaudi;
}

/// Invoice dialogs: billing draft name, then API customer, then order summary (no synthetic walk-in labels).
String _walkInInvoiceCustomerNameSeed(
  PosOrder o,
  pvm.WalkInBillingSnapshot? snap,
) {
  if (snap != null) {
    final sn = snap.name.trim();
    if (sn.isNotEmpty && !PosOrder.isPlaceholderCustomerName(sn)) return sn;
  }
  final cn = (o.customer?.name ?? '').trim();
  if (cn.isNotEmpty && !PosOrder.isPlaceholderCustomerName(cn)) return cn;
  final legacy = o.customerName.trim();
  if (legacy.isNotEmpty) return legacy;
  return '';
}

/// Shell create often omits year on GET order; prefer vehicle, then billing snapshot, then VM overlay.
String _walkInInvoiceVehicleYearSeed(
  PosOrder o,
  pvm.WalkInBillingSnapshot? snap,
  pvm.PosViewModel vm,
) {
  final vy = (o.vehicle?.year ?? '').trim();
  if (vy.isNotEmpty) return vy;
  if (snap != null && snap.year.trim().isNotEmpty) return snap.year.trim();
  return vm.vehicleYear.trim();
}

InputDecoration _walkInInvoiceMobileFieldDecoration(
  BuildContext context, {
  bool compact = false,
}) {
  final dial = _walkInInvoiceMobileDial;
  final textStyle = TextStyle(
    fontSize: compact ? 12 : 13,
    fontWeight: FontWeight.w700,
    color: AppColors.secondaryLight,
  );
  return _walkInInvoiceFieldDecoration(
    AppLocalizations.of(context)!.posInvoiceDetailsMobile,
    compact: compact,
  ).copyWith(
    hintText: dial.inputHintSample,
    hintTextDirection: TextDirection.ltr,
    prefixIconConstraints: BoxConstraints(
      minWidth: compact ? 72 : 78,
      minHeight: compact ? 40 : 46,
    ),
    prefixIcon: Padding(
      padding: EdgeInsets.only(left: compact ? 10 : 12, right: compact ? 8 : 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dial.flagEmoji, style: TextStyle(fontSize: compact ? 15 : 16)),
          const SizedBox(width: 5),
          Text('+${dial.dialDigits}', style: textStyle),
          const SizedBox(width: 2),
        ],
      ),
    ),
  );
}

Widget _walkInInvoiceSectionHeader(
    String title,
    IconData? icon, {
      bool compact = false,
    }) {
  return Row(
    children: [
      if (icon != null) ...[
        Icon(
          icon,
          size: compact ? 17 : 20,
          color: AppColors.secondaryLight,
        ),
        const SizedBox(width: 6),
      ],
      Text(
        title,
        style: compact
            ? TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryLight,
        )
            : AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryLight,
        ),
      ),
    ],
  );
}

class WalkInInvoiceFormResult {
  final String name;
  final String mobile;
  final String vat;
  final String vehicleNumber;
  final String vin;
  final String make;
  final String model;
  final String year;
  final String color;
  final int odometer;
  final bool billingCustomerIsEmployee;
  final String? billingEmployeeId;
  final String? billingEmployeeType;

  /// GCC plate country (`SA` / `AE` / `KW` / `BH` / `QA` / `OM`).
  /// Defaults to `SA` for backwards compatibility with existing call sites.
  final String vehiclePlateCountry;

  /// UAE emirate key (only set when [vehiclePlateCountry] is `AE`).
  final String? vehiclePlateEmirate;

  const WalkInInvoiceFormResult({
    required this.name,
    required this.mobile,
    required this.vat,
    required this.vehicleNumber,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.odometer,
    this.billingCustomerIsEmployee = false,
    this.billingEmployeeId,
    this.billingEmployeeType,
    this.vehiclePlateCountry = 'SA',
    this.vehiclePlateEmirate,
  });
}

class WalkInInvoiceDetailsDialog extends StatefulWidget {
  /// When null (e.g. Takeaway checkout), use [standaloneInitial] to seed fields.
  final PosOrder? order;
  final pvm.PosViewModel posVm;
  final WalkInInvoiceFormResult? standaloneInitial;
  /// Takeaway only asks for customer + VAT; walk-in orders still show vehicle fields.
  final bool showVehicleSection;
  /// Takeaway: optional plate field without the full vehicle section.
  final bool showOptionalPlateField;
  /// When true, renders only the form (for merged orders checkout dialog).
  final bool embedded;
  /// Takeaway: Corporate selected → Customer name becomes corporate accounts dropdown.
  final bool corporateNameAsDropdown;

  const WalkInInvoiceDetailsDialog({
    super.key,
    this.order,
    required this.posVm,
    this.standaloneInitial,
    this.showVehicleSection = true,
    this.showOptionalPlateField = false,
    this.embedded = false,
    this.corporateNameAsDropdown = false,
  }) : assert(
  order != null || standaloneInitial != null,
  'Provide order or standaloneInitial',
  );

  @override
  State<WalkInInvoiceDetailsDialog> createState() => WalkInInvoiceDetailsDialogState();
}

class WalkInInvoiceDetailsDialogState extends State<WalkInInvoiceDetailsDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _vatCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _odoCtrl;
  final _formKey = GlobalKey<FormState>();
  String? _selectedCorporateAccountId;

  /// GCC plate country selected in the Vehicle section. Mirrors the
  /// "Add New Order" flow: defaults to Saudi but the user may switch to any
  /// GCC country (UAE, Kuwait, Bahrain, Qatar, Oman). When `AE` is picked
  /// the emirate dropdown becomes visible.
  String _plateCountryCode = 'SA';
  String? _plateEmirate;
  PosAddCustomerVehicleKind _vehicleKind = PosAddCustomerVehicleKind.car;

  bool _continuingSubmit = false;

  static const String _historyHintLimit = '4';
  List<SearchedCustomer> _historyFocusHints = const [];
  bool _invoiceHistoryHintsLoading = false;
  List<SearchedCustomer> _vehicleHistorySuggestions = const [];
  List<SearchedCustomer> _mobileHistorySuggestions = const [];
  int _invoiceHistoryUiToken = 0;

  static int _parseOdometer(String s) {
    final t = s.trim().replaceAll(RegExp(r'[\s,]'), '');
    if (t.isEmpty) return 0;
    return int.tryParse(t) ?? 0;
  }

  /// Strip the GCC country prefix from a stored normalized plate so the text
  /// field shows just the user-typed body (e.g. `AEDubai1234ABC` → `1234ABC`,
  /// `KW1234ABC` → `1234ABC`, Saudi plates pass through untouched).
  static String _stripGccPlateCountryPrefix(
    String stored, {
    required String countryCode,
    String? emirate,
  }) {
    final cc = countryCode.toUpperCase();
    final s = stored.trim();
    if (s.isEmpty) return s;
    if (cc == 'SA') return s;
    if (cc == 'AE') {
      final em = UaeEmirate.parseOrDefault(emirate).key;
      final prefix = 'AE$em';
      if (s.toUpperCase().startsWith(prefix.toUpperCase())) {
        return s.substring(prefix.length);
      }
      if (s.toUpperCase().startsWith('AE')) {
        return s.substring(2);
      }
      return s;
    }
    if (cc == 'KW' || cc == 'BH' || cc == 'QA' || cc == 'OM') {
      if (s.toUpperCase().startsWith(cc)) {
        return s.substring(cc.length);
      }
    }
    return s;
  }

  /// Auto-detect the GCC plate country (and UAE emirate, if present) from a
  /// stored normalized plate string — used when no in-session snapshot exists
  /// yet, so the country selector pre-fills correctly the **first time** the
  /// "Edit customer details" popup is opened for an order that was created
  /// from the Add-New-Order GCC flow.
  ///
  /// Returns `('SA', null)` for Saudi plates (no prefix) or empty input.
  static ({String countryCode, String? emirate}) _detectGccPlateCountry(
    String storedPlate,
  ) {
    final raw = storedPlate.trim();
    if (raw.isEmpty) return (countryCode: 'SA', emirate: null);
    final upper = raw.toUpperCase();

    if (upper.startsWith('AE')) {
      for (final em in UaeEmirate.all) {
        final prefix = 'AE${em.key.toUpperCase()}';
        if (upper.startsWith(prefix)) {
          return (countryCode: 'AE', emirate: em.key);
        }
      }
      // Bare `AE` without a known emirate — fall back to default emirate.
      return (countryCode: 'AE', emirate: UaeEmirate.all[1].key);
    }

    for (final cc in const ['KW', 'BH', 'QA', 'OM']) {
      if (upper.startsWith(cc)) {
        return (countryCode: cc, emirate: null);
      }
    }

    return (countryCode: 'SA', emirate: null);
  }

  static PosAddCustomerVehicleKind _inferVehicleKindFromSaudiPlate(String plate) {
    final reg = parseGccPlate(plate.trim(), countryCode: 'SA');
    if (reg.plateLettersEn.length == 2 && reg.plateNumber.length == 4) {
      return PosAddCustomerVehicleKind.bike;
    }
    return PosAddCustomerVehicleKind.car;
  }

  bool get _isWalkInBike => _vehicleKind == PosAddCustomerVehicleKind.bike;

  void _setWalkInVehicleKind(PosAddCustomerVehicleKind kind) {
    setState(() {
      _vehicleKind = kind;
      if (kind == PosAddCustomerVehicleKind.bike) {
        _plateCountryCode = 'SA';
        _plateEmirate = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      final o = widget.order!;
      final c = o.customer;
      final v = o.vehicle;
      final posVm = widget.posVm;
      final snap = posVm.walkInBillingSnapshotForOrder(o.id);
      // Billing contact + plate: snapshot wins when set (user draft for this order).
      // Name / year: merge snapshot with GET order — snapshot used to clear name and drop year
      // when the shell response omitted them even though the cashier entered them at order create.
      // Resolve the country/emirate the order was created with.
      // Priority order:
      //   1. In-session draft snapshot (cashier-edited country in this session).
      //   2. The order's vehicle row from the API — backend now surfaces
      //      `plateCountryCode` / `plateEmirate` for cashier orders, so an
      //      order originally placed via Add-New-Order with `Kuwait` (etc.)
      //      pre-fills the selector to `Kuwait` on first edit.
      //   3. Prefix detection on the stored plate string (legacy fallback).
      ({String countryCode, String? emirate}) _resolvePlateCountry(String storedPlate) {
        final apiCountry = (v?.plateCountryCode ?? '').trim().toUpperCase();
        if (apiCountry.isNotEmpty) {
          return (
            countryCode: apiCountry,
            emirate: (v?.plateEmirate ?? '').trim().isNotEmpty
                ? v!.plateEmirate!.trim()
                : null,
          );
        }
        // Same-session Add New Order selection before a billing snapshot exists.
        final vmCountry = posVm.vehiclePlateCountry.trim().toUpperCase();
        final orderId = o.id.trim();
        final vmTargetsOrder = posVm.selectedOrder?.id.trim() == orderId ||
            (posVm.walkInDraftOrderId ?? '').trim() == orderId;
        if (vmCountry.isNotEmpty && vmTargetsOrder) {
          return (
            countryCode: vmCountry,
            emirate: posVm.vehiclePlateEmirate,
          );
        }
        return _detectGccPlateCountry(storedPlate);
      }

      if (snap != null) {
        _nameCtrl = TextEditingController(
          text: _walkInInvoiceCustomerNameSeed(o, snap),
        );
        _mobileCtrl = TextEditingController(
          text: _walkInInvoiceMobileDisplay(
            snap.mobile.trim().isNotEmpty ? snap.mobile : (c?.mobile ?? '').trim(),
          ),
        );
        _vatCtrl = TextEditingController(
          text: snap.vat.trim().isNotEmpty ? snap.vat : (c?.vatNumber ?? '').trim(),
        );
        final storedPlate = snap.vehicleNumber.trim().isNotEmpty
            ? snap.vehicleNumber
            : (v?.plateNo ?? '').trim();
        // Snapshot carries Add-New-Order plate country; backfill from API/prefix
        // only when the snapshot still has the legacy default `SA`.
        _plateCountryCode =
            GccPlateCountry.parseOrDefault(snap.vehiclePlateCountry).code;
        _plateEmirate = snap.vehiclePlateEmirate;
        if (_plateCountryCode == 'SA') {
          final resolved = _resolvePlateCountry(storedPlate);
          if (resolved.countryCode != 'SA') {
            _plateCountryCode = resolved.countryCode;
            _plateEmirate = resolved.emirate;
          }
        }
        final plateBody = _stripGccPlateCountryPrefix(
          storedPlate,
          countryCode: _plateCountryCode,
          emirate: _plateEmirate,
        );
        _plateCtrl = TextEditingController(
          text: _plateCountryCode == 'SA'
              ? formatVehiclePlateLettersFirst(plateBody)
              : plateBody,
        );
      } else {
        _nameCtrl = TextEditingController(
          text: _walkInInvoiceCustomerNameSeed(o, null),
        );
        _mobileCtrl = TextEditingController(
          text: _walkInInvoiceMobileDisplay((c?.mobile ?? '').trim()),
        );
        _vatCtrl = TextEditingController(text: (c?.vatNumber ?? '').trim());
        final storedPlate = (v?.plateNo ?? '').trim();
        final resolved = _resolvePlateCountry(storedPlate);
        _plateCountryCode = resolved.countryCode;
        _plateEmirate = resolved.emirate;
        final plateBody = _stripGccPlateCountryPrefix(
          storedPlate,
          countryCode: _plateCountryCode,
          emirate: _plateEmirate,
        );
        _plateCtrl = TextEditingController(
          text: _plateCountryCode == 'SA'
              ? formatVehiclePlateLettersFirst(plateBody)
              : plateBody,
        );
      }
      // Vehicle fields: same-session billing snapshot wins over the order row —
      // right after "Save" the orders-list GET can still return the pre-patch
      // values, and the snapshot holds exactly what the cashier just saved.
      _makeCtrl = TextEditingController(
        text: (snap?.make.trim().isNotEmpty ?? false)
            ? snap!.make.trim()
            : (v?.make ?? '').trim(),
      );
      _modelCtrl = TextEditingController(
        text: (snap?.model.trim().isNotEmpty ?? false)
            ? snap!.model.trim()
            : (v?.model ?? '').trim(),
      );
      _yearCtrl = TextEditingController(
        text: (snap?.year.trim().isNotEmpty ?? false)
            ? snap!.year.trim()
            : _walkInInvoiceVehicleYearSeed(o, snap, posVm),
      );
      _vinCtrl = TextEditingController(
        text: (snap?.vin.trim().isNotEmpty ?? false)
            ? snap!.vin.trim()
            : (v?.vin ?? '').trim(),
      );
      final suggestedOdo = (snap != null && snap.odometer != 0)
          ? snap.odometer
          : posVm.suggestedOdometerForOrder(o);
      _odoCtrl = TextEditingController(
        text: suggestedOdo != 0 ? '$suggestedOdo' : '',
      );
    } else {
      final d = widget.standaloneInitial!;
      _nameCtrl = TextEditingController(text: d.name);
      _mobileCtrl = TextEditingController(
        text: _walkInInvoiceMobileDisplay(d.mobile),
      );
      _vatCtrl = TextEditingController(text: d.vat);
      _plateCountryCode =
          GccPlateCountry.parseOrDefault(d.vehiclePlateCountry).code;
      _plateEmirate = d.vehiclePlateEmirate;
      if (_plateCountryCode == 'SA') {
        final detected = _detectGccPlateCountry(d.vehicleNumber);
        if (detected.countryCode != 'SA') {
          _plateCountryCode = detected.countryCode;
          _plateEmirate = detected.emirate;
        }
      }
      final plateBody = _stripGccPlateCountryPrefix(
        d.vehicleNumber,
        countryCode: _plateCountryCode,
        emirate: _plateEmirate,
      );
      _plateCtrl = TextEditingController(
        text: _plateCountryCode == 'SA'
            ? formatVehiclePlateLettersFirst(plateBody)
            : plateBody,
      );
      _makeCtrl = TextEditingController(text: d.make);
      _modelCtrl = TextEditingController(text: d.model);
      _yearCtrl = TextEditingController(text: d.year);
      _vinCtrl = TextEditingController(text: d.vin);
      _odoCtrl = TextEditingController(
        text: d.odometer != 0 ? '${d.odometer}' : '',
      );
    }
    if (_plateCountryCode == 'SA') {
      _vehicleKind = _inferVehicleKindFromSaudiPlate(_plateCtrl.text);
    }
    if (widget.corporateNameAsDropdown) {
      _ensureCorporateAccountsLoaded();
      _tryMatchCorporateFromName();
    }
  }

  @override
  void didUpdateWidget(covariant WalkInInvoiceDetailsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.corporateNameAsDropdown && !oldWidget.corporateNameAsDropdown) {
      _ensureCorporateAccountsLoaded();
      _tryMatchCorporateFromName();
    } else if (!widget.corporateNameAsDropdown &&
        oldWidget.corporateNameAsDropdown) {
      // Switching Corporate → Individual: clear fields so corporate data
      // does not stay in the free-text Individual form.
      clearCustomerIdentityFields();
    }
  }

  /// Clears name / mobile / VAT (and corporate selection) for Individual mode.
  void clearCustomerIdentityFields() {
    setState(() {
      _selectedCorporateAccountId = null;
      _nameCtrl.clear();
      _mobileCtrl.clear();
      _vatCtrl.clear();
      _invoiceHistoryUiToken++;
    });
  }

  void _ensureCorporateAccountsLoaded() {
    widget.posVm.fetchCorporateAccounts(silent: true);
  }

  void _tryMatchCorporateFromName() {
    final name = _nameCtrl.text.trim().toLowerCase();
    if (name.isEmpty) return;
    final accounts = widget.posVm.corporateAccounts;
    for (final a in accounts) {
      if (a.companyName.trim().toLowerCase() == name ||
          (a.posContactName ?? '').trim().toLowerCase() == name) {
        _selectedCorporateAccountId = a.id;
        return;
      }
    }
  }

  List<CashierCorporateAccount> _dedupeCorporateAccounts(
    List<CashierCorporateAccount> accounts,
  ) {
    final seen = <String>{};
    final out = <CashierCorporateAccount>[];
    for (final a in accounts) {
      final id = a.id.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      out.add(a);
    }
    return out;
  }

  void _applyCorporateAccount(CashierCorporateAccount acct) {
    final company = acct.companyName.trim();
    final contact = (acct.posContactName ?? '').trim();
    setState(() {
      _selectedCorporateAccountId = acct.id;
      _nameCtrl.text = company.isNotEmpty ? company : contact;
      _mobileCtrl.text = _walkInInvoiceMobileDisplay(acct.posContactPhone ?? '');
      _vatCtrl.text = (acct.effectiveVatNumber ?? '').trim();
      _invoiceHistoryUiToken++;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _vatCtrl.dispose();
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _vinCtrl.dispose();
    _odoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceHistoryFocusHints() async {
    if (_historyFocusHints.isNotEmpty || _invoiceHistoryHintsLoading) return;
    _invoiceHistoryHintsLoading = true;
    try {
      final token =
          await Provider.of<SessionService>(context, listen: false).getToken(role: 'cashier');
      if (token == null) return;
      var found = <SearchedCustomer>[];
      for (final params in <Map<String, String>>[
        {'phone': '05', 'limit': _historyHintLimit},
        {'phone': '0', 'limit': _historyHintLimit},
        {'name': 'a', 'limit': _historyHintLimit},
        {'name': 'ا', 'limit': _historyHintLimit},
      ]) {
        final response = await widget.posVm.posRepository.searchCustomers(params, token);
        if (response.success && response.customers.isNotEmpty) {
          found = response.customers.take(4).toList();
          break;
        }
      }
      if (!mounted) return;
      setState(() => _historyFocusHints = found);
    } catch (_) {
      if (mounted) setState(() => _historyFocusHints = const []);
    } finally {
      _invoiceHistoryHintsLoading = false;
    }
  }

  Future<void> _searchInvoiceHistoryVehicle(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() => _vehicleHistorySuggestions = const []);
      return;
    }
    try {
      final token =
          await Provider.of<SessionService>(context, listen: false).getToken(role: 'cashier');
      if (token == null) {
        setState(() => _vehicleHistorySuggestions = const []);
        return;
      }
      final response = await widget.posVm.posRepository.searchCustomers(
        {'vehicleNumber': q, 'limit': '20'},
        token,
      );
      if (!mounted) return;
      setState(() {
        _vehicleHistorySuggestions = response.success ? response.customers : const [];
      });
    } catch (_) {
      if (mounted) setState(() => _vehicleHistorySuggestions = const []);
    }
  }

  Future<void> _searchInvoiceHistoryMobile(String query) async {
    final q = AddCustomerViewModel.digitsOnlyPhone(query);
    if (q.length < 3) {
      setState(() => _mobileHistorySuggestions = const []);
      return;
    }
    try {
      final token =
          await Provider.of<SessionService>(context, listen: false).getToken(role: 'cashier');
      if (token == null) {
        setState(() => _mobileHistorySuggestions = const []);
        return;
      }
      final response = await widget.posVm.posRepository.searchCustomers(
        {'phone': q, 'limit': '20'},
        token,
      );
      if (!mounted) return;
      setState(() {
        _mobileHistorySuggestions = response.success ? response.customers : const [];
      });
    } catch (_) {
      if (mounted) setState(() => _mobileHistorySuggestions = const []);
    }
  }

  void _prefillFromInvoiceHistoryCustomer(SearchedCustomer customer) {
    final best = _invoiceHistoryBestVehicleOrder(customer.orders);
    final vehicle = best?.vehicle;
    _nameCtrl.text = customer.name.trim();
    final tax = (customer.taxId ?? '').trim();
    if (tax.isNotEmpty) {
      _vatCtrl.text = tax;
    }
    _mobileCtrl.text = _walkInInvoiceMobileDisplay(customer.mobile);
    if ((vehicle?.plateNo ?? '').trim().isNotEmpty) {
      _plateCtrl.text = formatVehiclePlateLettersFirst(vehicle!.plateNo.trim());
    }
    if ((vehicle?.make ?? '').trim().isNotEmpty) {
      _makeCtrl.text = vehicle!.make.trim();
    }
    if ((vehicle?.model ?? '').trim().isNotEmpty) {
      _modelCtrl.text = vehicle!.model.trim();
    }
    final y = (vehicle?.year ?? '').trim();
    if (y.isNotEmpty) {
      _yearCtrl.text = y;
    }
    if ((vehicle?.vin ?? '').trim().isNotEmpty) {
      _vinCtrl.text = vehicle!.vin!.trim();
    }
    if ((best?.odometerReading ?? 0) > 0) {
      _odoCtrl.text = best!.odometerReading.toString();
    }
    setState(() => _invoiceHistoryUiToken++);
  }

  Widget _invoiceHistoryCustomerOptionsView(
    BuildContext context, {
    required void Function(SearchedCustomer) onSelected,
    required Iterable<SearchedCustomer> options,
    required String Function(SearchedCustomer) titleFor,
    required String Function(SearchedCustomer) subtitleFor,
  }) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final list = options.toList();
    return Align(
      alignment: isAr ? Alignment.topRight : Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 220),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final option = list[index];
              final title = titleFor(option);
              final subtitle = subtitleFor(option);
              return InkWell(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onSelected(option);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedApiText(
                        title,
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
                        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        LocalizedApiText(
                          subtitle,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _walkInInvoiceNamePlainField({
    required bool isCorporateLocked,
    required bool lockNameMobileFromEmployee,
  }) {
    final readOnly = isCorporateLocked || lockNameMobileFromEmployee;
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    return KeyedSubtree(
      key: ValueKey('invhist_name_$_invoiceHistoryUiToken'),
      child: TextFormField(
        controller: _nameCtrl,
        readOnly: readOnly,
        style: _kWalkInInvoiceDialogFieldStyle.copyWith(color: Colors.grey.shade900),
        decoration: _walkInInvoiceFieldDecoration(
          AppLocalizations.of(context)!.posInvoiceDetailsCustomerName,
          compact: true,
        ),
        textCapitalization: TextCapitalization.words,
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        inputFormatters: [EnglishNumberFormatter()],
        validator: (s) => isCorporateLocked
            ? null
            : (s == null || s.trim().isEmpty)
                ? AppLocalizations.of(context)!.posInvoiceDetailsRequired
                : null,
      ),
    );
  }

  Widget _walkInInvoiceCorporateNameDropdown() {
    final l10n = AppLocalizations.of(context)!;
    // Same as filled TextFormField value text.
    final fieldStyle = _kWalkInInvoiceDialogFieldStyle.copyWith(
      color: Colors.grey.shade900,
      height: 1.25,
    );
    // Same as empty TextFormField floating label (VAT / Plate placeholders).
    final emptyLabelStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade700,
      height: 1.25,
    );
    return ListenableBuilder(
      listenable: widget.posVm,
      builder: (context, _) {
        if (widget.posVm.isCorpAccountsLoading &&
            widget.posVm.corporateAccounts.isEmpty) {
          return InputDecorator(
            decoration: _walkInInvoiceFieldDecoration(
              l10n.posInvoiceDetailsCustomerName,
              compact: true,
            ),
            child: const SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PosShimmer(
                  child: PosShimmerBox(width: 120, height: 13, radius: 6),
                ),
              ),
            ),
          );
        }

        final accounts =
            _dedupeCorporateAccounts(widget.posVm.corporateAccounts);
        final selectedId = _selectedCorporateAccountId;
        final dropdownValue =
            selectedId != null && accounts.any((a) => a.id == selectedId)
                ? selectedId
                : null;
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            // DropdownButton reads bodyLarge / titleMedium — force field font.
            textTheme: theme.textTheme.copyWith(
              bodyLarge: fieldStyle,
              bodyMedium: fieldStyle,
              titleMedium: fieldStyle,
            ),
          ),
          child: DropdownButtonFormField<String>(
            key: ValueKey('corp_name_$selectedId'),
            value: dropdownValue,
            isExpanded: true,
            isDense: true,
            style: fieldStyle,
            iconSize: 20,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.grey.shade500,
            ),
            decoration: _walkInInvoiceFieldDecoration(
              l10n.posInvoiceDetailsCustomerName,
              compact: true,
            ),
            hint: Text(
              accounts.isEmpty
                  ? l10n.posAddCustomerNoCorporateFound
                  : l10n.posAddCustomerSelectCorporate,
              style: emptyLabelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selectedItemBuilder: (context) {
              return accounts
                  .map(
                    (corp) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        corp.companyName,
                        style: fieldStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList();
            },
            items: accounts
                .map(
                  (corp) => DropdownMenuItem<String>(
                    value: corp.id,
                    child: Text(
                      corp.companyName,
                      style: fieldStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (_) {
              if ((_selectedCorporateAccountId ?? '').trim().isEmpty ||
                  _nameCtrl.text.trim().isEmpty) {
                return l10n.posInvoiceDetailsRequired;
              }
              return null;
            },
            onChanged: accounts.isEmpty
                ? null
                : (value) {
                    if (value == null) return;
                    CashierCorporateAccount? match;
                    for (final a in accounts) {
                      if (a.id == value) {
                        match = a;
                        break;
                      }
                    }
                    if (match == null) return;
                    _applyCorporateAccount(match);
                  },
          ),
        );
      },
    );
  }

  Widget _walkInInvoiceCustomerNameField({
    required bool isCorporateLocked,
    required bool lockNameMobileFromEmployee,
  }) {
    if (widget.corporateNameAsDropdown) {
      return _walkInInvoiceCorporateNameDropdown();
    }
    return _walkInInvoiceNamePlainField(
      isCorporateLocked: isCorporateLocked,
      lockNameMobileFromEmployee: lockNameMobileFromEmployee,
    );
  }

  Widget _walkInInvoiceMobileAutocompleteField({
    required bool isCorporateLocked,
    required bool lockNameMobileFromEmployee,
  }) {
    final readOnly = isCorporateLocked || lockNameMobileFromEmployee;
    return KeyedSubtree(
      key: ValueKey('invhist_mobile_$_invoiceHistoryUiToken'),
      child: Autocomplete<SearchedCustomer>(
        displayStringForOption: (o) => o.mobile,
        initialValue: TextEditingValue(text: _mobileCtrl.text),
        optionsBuilder: (tev) {
          final q = AddCustomerViewModel.digitsOnlyPhone(tev.text);
          if (q.length < 3) return _historyFocusHints;
          return _mobileHistorySuggestions;
        },
        onSelected: _prefillFromInvoiceHistoryCustomer,
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          return _WalkInInvoiceHistoryFocusLoader(
            focusNode: focusNode,
            textEditingController: textController,
            onLoadHints: _loadInvoiceHistoryFocusHints,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
              controller: textController,
              focusNode: focusNode,
              readOnly: readOnly,
              style: _kWalkInInvoiceDialogFieldStyle.copyWith(color: Colors.grey.shade900),
              decoration: _walkInInvoiceMobileFieldDecoration(context, compact: true),
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
              inputFormatters: [
                EnglishNumberFormatter(),
                PosAddCustomerNationalMobileFormatter(_walkInInvoiceMobileDial),
              ],
              validator: (s) => isCorporateLocked
                  ? null
                  : walkInNationalMobileValidator(
                      s,
                      AppLocalizations.of(context)!,
                    ),
              onChanged: (v) {
                _mobileCtrl.text = v;
                if (!readOnly) _searchInvoiceHistoryMobile(v);
              },
            ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return _invoiceHistoryCustomerOptionsView(
            context,
            onSelected: onSelected,
            options: options,
            titleFor: (o) => o.mobile.trim().isNotEmpty ? o.mobile : o.name,
            subtitleFor: (o) {
              final v = _invoiceHistoryVehicleSnapshot(o);
              final plate = (v?.plateNo ?? '').trim();
              final name = o.name.trim();
              final mm = '${v?.make ?? ''} ${v?.model ?? ''}'.trim();
              final parts = <String>[];
              if (plate.isNotEmpty) parts.add(_invoiceLocalizedPlateOrDigits(context, plate));
              if (name.isNotEmpty) parts.add(name);
              if (mm.isNotEmpty) parts.add(mm);
              return parts.join(' · ');
            },
          );
        },
      ),
    );
  }

  Widget _buildWalkInVehicleKindSelector({required bool enabled}) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: enabled ? const Color(0xFF1E2124) : Colors.grey.shade500,
    );

    Widget radioOption({
      required PosAddCustomerVehicleKind kind,
      required String label,
      required IconData icon,
    }) {
      return InkWell(
        onTap: enabled ? () => _setWalkInVehicleKind(kind) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<PosAddCustomerVehicleKind>(
                value: kind,
                groupValue: _vehicleKind,
                onChanged: enabled
                    ? (value) {
                        if (value != null) _setWalkInVehicleKind(value);
                      }
                    : null,
                activeColor: AppColors.primaryLight,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryLight;
                  }
                  return Colors.grey.shade400;
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Icon(
                icon,
                size: 16,
                color: enabled ? AppColors.secondaryLight : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(label, style: labelStyle),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        radioOption(
          kind: PosAddCustomerVehicleKind.car,
          label: l10n.posAddCustomerVehicleKindCar,
          icon: Icons.directions_car_outlined,
        ),
        const SizedBox(width: 20),
        radioOption(
          kind: PosAddCustomerVehicleKind.bike,
          label: l10n.posAddCustomerVehicleKindBike,
          icon: Icons.two_wheeler_outlined,
        ),
      ],
    );
  }

  List<TextInputFormatter> _walkInPlateInputFormatters(AppLocalizations l10n) {
    if (_isWalkInBike) {
      return [
        saudiBikePlateInputFormatter(
          onRejectedDigitBeyondFour: () {
            if (!mounted) return;
            ToastService.showError(
              context,
              l10n.posAddCustomerValidationBikePlateFourDigits,
            );
          },
          onRejectedLetterBeyondTwo: () {
            if (!mounted) return;
            ToastService.showError(
              context,
              l10n.posAddCustomerValidationBikePlateTwoLetters,
            );
          },
        ),
      ];
    }
    return [
      gccPlateInputFormatter(
        countryCode: _plateCountryCode,
        onRejectedDigitBeyondFour: () {
          if (!mounted) return;
          ToastService.showError(
            context,
            l10n.posAddCustomerValidationVehiclePlateMaxFourDigits,
          );
        },
        onRejectedLetterBeyondThree: () {
          if (!mounted) return;
          ToastService.showError(
            context,
            l10n.posAddCustomerValidationVehiclePlateMaxThreeLetters,
          );
        },
      ),
    ];
  }

  String? _validateWalkInPlate(String? raw, AppLocalizations l10n) {
    if (_isWalkInBike) {
      return validateSaudiBikePlateInput(
        raw,
        emptyMessage: l10n.posInvoiceDetailsPlateRequired,
        twoLettersMessage: l10n.posAddCustomerValidationBikePlateTwoLetters,
        fourDigitsMessage: l10n.posAddCustomerValidationBikePlateFourDigits,
        letterCharsMessage: l10n.posInvoiceDetailsPlateSaudiLetterChars,
      );
    }
    return validateGccPlateInput(
      raw,
      countryCode: _plateCountryCode,
      emirate: _plateEmirate,
      emptyMessage: l10n.posInvoiceDetailsPlateRequired,
      saudiThreeLettersMessage: l10n.posInvoiceDetailsPlateSaudiThreeLetters,
      saudiDigitsMessage: l10n.posInvoiceDetailsPlateSaudiDigits,
      saudiLetterCharsMessage: l10n.posInvoiceDetailsPlateSaudiLetterChars,
      gccFormatMessage: l10n.posGccPlateValidationGccFormat,
      emirateRequiredMessage: l10n.posGccPlateValidationEmirateRequired,
    );
  }

  Widget _walkInInvoicePlateAutocompleteField({required bool vehicleFieldsLocked}) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;
    return KeyedSubtree(
      // Country + vehicle kind keyed so formatters/validators rebuild correctly.
      key: ValueKey(
        'invhist_plate_${_invoiceHistoryUiToken}_${_plateCountryCode}_${_vehicleKind.name}',
      ),
      child: Autocomplete<SearchedCustomer>(
        displayStringForOption: (o) {
          final plate = (_invoiceHistoryVehicleSnapshot(o)?.plateNo ?? '').trim();
          return plate.isNotEmpty ? plate : o.mobile;
        },
        initialValue: TextEditingValue(text: _plateCtrl.text),
        optionsBuilder: (tev) {
          final q = tev.text.trim();
          if (q.length < 2) return _historyFocusHints;
          return _vehicleHistorySuggestions;
        },
        onSelected: _prefillFromInvoiceHistoryCustomer,
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          return _WalkInInvoiceHistoryFocusLoader(
            focusNode: focusNode,
            textEditingController: textController,
            onLoadHints: _loadInvoiceHistoryFocusHints,
            child: TextFormField(
              controller: textController,
              focusNode: focusNode,
              readOnly: vehicleFieldsLocked,
              style: _kWalkInInvoiceDialogFieldStyle,
              decoration: _walkInInvoiceFieldDecoration(
                l10n.posInvoiceDetailsPlateNumber,
                compact: true,
              ),
              textCapitalization: TextCapitalization.characters,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              inputFormatters: _walkInPlateInputFormatters(l10n),
              validator: (s) => _validateWalkInPlate(s, l10n),
              onChanged: (v) {
                _plateCtrl.text = v;
                if (!vehicleFieldsLocked) _searchInvoiceHistoryVehicle(v);
              },
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return _invoiceHistoryCustomerOptionsView(
            context,
            onSelected: onSelected,
            options: options,
            titleFor: (o) {
              final plate = (_invoiceHistoryVehicleSnapshot(o)?.plateNo ?? '').trim();
              final t = plate.isNotEmpty ? plate : o.mobile;
              return _invoiceLocalizedPlateOrDigits(context, t);
            },
            subtitleFor: (o) {
              final v = _invoiceHistoryVehicleSnapshot(o);
              final name = o.name.trim();
              final mm = '${v?.make ?? ''} ${v?.model ?? ''}'.trim();
              if (mm.isNotEmpty) return '$name · $mm'.trim();
              return name;
            },
          );
        },
      ),
    );
  }

  Widget _walkInInvoiceKsaMakeModelRow({
    required bool vehicleFieldsLocked,
    Widget? thirdChild,
  }) {
    return PosKsaVehicleMakeModelRow(
      makeController: _makeCtrl,
      modelController: _modelCtrl,
      decorationFor: _walkInInvoiceFieldDecoration,
      fieldStyle: _kWalkInInvoiceDialogFieldStyle,
      readOnly: vehicleFieldsLocked,
      compact: true,
      thirdChild: thirdChild,
    );
  }

  Widget _walkInInvoiceYearAutocompleteField({required bool vehicleFieldsLocked}) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final years = vehicleModelYearChoices();
    return KeyedSubtree(
      key: ValueKey('walkin_year_$_invoiceHistoryUiToken'),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: _yearCtrl.text.trim()),
        displayStringForOption: (option) =>
            option == _kWalkInInvoiceYearNoneOption ? '' : option,
        optionsBuilder: (textEditingValue) {
          if (vehicleFieldsLocked) return const Iterable<String>.empty();
          final q = textEditingValue.text.trim();
          final filtered = q.isEmpty
              ? years
              : years.where((y) => y.contains(q)).toList();
          if (filtered.isEmpty) {
            return const [_kWalkInInvoiceYearNoneOption];
          }
          return [_kWalkInInvoiceYearNoneOption, ...filtered];
        },
        onSelected: (selection) {
          if (selection == _kWalkInInvoiceYearNoneOption) {
            _yearCtrl.clear();
          } else {
            _yearCtrl.text = selection;
          }
          setState(() {});
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            readOnly: vehicleFieldsLocked,
            keyboardType: TextInputType.number,
            style: _kWalkInInvoiceDialogFieldStyle,
            decoration: _walkInInvoiceFieldDecoration(
              AppLocalizations.of(context)!.posInvoiceDetailsYear,
              optional: true,
              optionalSuffix: AppLocalizations.of(context)!.posSalesReturnOptional,
              compact: true,
            ),
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            onFieldSubmitted: (_) => onFieldSubmitted(),
            validator: (_) {
              final t = _yearCtrl.text.trim();
              if (t.isEmpty) return null;
              final yi = int.tryParse(t);
              if (yi == null || yi < 1900 || yi > 2100) {
                return AppLocalizations.of(context)!.posInvoiceDetailsInvalidYear;
              }
              return null;
            },
            onChanged: (v) {
              _yearCtrl.text = v;
              setState(() {});
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: isAr ? Alignment.topRight : Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 220),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final isNone = option == _kWalkInInvoiceYearNoneOption;
                    return InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        onSelected(option);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: LocalizedApiText(
                          option,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isNone
                                ? Colors.grey.shade600
                                : AppColors.secondaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _close([WalkInInvoiceFormResult? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(result);
  }

  /// Validates, PATCHes order billing when applicable, returns result (no Navigator pop).
  Future<WalkInInvoiceFormResult?> saveCustomerDetails() async {
    if (_continuingSubmit) return null;
    final isCorporateLocked = widget.order != null &&
        widget.order!.isCorporateWalkIn &&
        !widget.order!.isCorporateBookingOrder;

    if (_formKey.currentState?.validate() != true) return null;

    final WalkInInvoiceFormResult formResult;

    if (!widget.showVehicleSection) {
      formResult = WalkInInvoiceFormResult(
        name: _nameCtrl.text,
        mobile: _walkInInvoiceMobilePayload(_mobileCtrl.text),
        vat: _vatCtrl.text,
        vehicleNumber: widget.showOptionalPlateField
            ? _plateCtrl.text.trim()
            : '',
        vin: '',
        make: '',
        model: '',
        year: '',
        color: '',
        odometer: 0,
      );
    } else {
      final colorResult = widget.order != null
          ? () {
        final o = widget.order!;
        final v = o.vehicle;
        final prev =
        widget.posVm.walkInBillingSnapshotForOrder(o.id);
        final pc = (prev?.color ?? '').trim();
        if (pc.isNotEmpty) return pc;
        return (v?.color ?? '').trim();
      }()
          : '';
      formResult = WalkInInvoiceFormResult(
        name: _nameCtrl.text,
        mobile: _walkInInvoiceMobilePayload(_mobileCtrl.text),
        vat: _vatCtrl.text,
        vehicleNumber: canonicalGccPlateForApi(
          _plateCtrl.text.trim(),
          countryCode: _isWalkInBike ? 'SA' : _plateCountryCode,
          emirate: _isWalkInBike ? null : _plateEmirate,
        ),
        vin: _vinCtrl.text,
        make: _makeCtrl.text,
        model: _modelCtrl.text,
        year: _yearCtrl.text,
        color: colorResult,
        odometer: _parseOdometer(_odoCtrl.text),
        vehiclePlateCountry: _isWalkInBike ? 'SA' : _plateCountryCode,
        vehiclePlateEmirate: _isWalkInBike ? null : _plateEmirate,
      );
    }

    if (widget.order != null) {
      final o = widget.order!;
      widget.posVm.updateWalkInBillingContact(
        forOrderId: o.id,
        name: formResult.name,
        mobile: formResult.mobile,
        vat: formResult.vat,
        vehicleNumber: formResult.vehicleNumber,
        vin: formResult.vin,
        make: formResult.make,
        model: formResult.model,
        odometer: formResult.odometer,
        year: formResult.year,
        color: formResult.color,
        billingCustomerIsEmployee: formResult.billingCustomerIsEmployee,
        billingEmployeeId: formResult.billingEmployeeId,
        billingEmployeeType: formResult.billingEmployeeType,
        vehiclePlateCountry: formResult.vehiclePlateCountry,
        vehiclePlateEmirate: formResult.vehiclePlateEmirate,
      );
      setState(() => _continuingSubmit = true);
      try {
        final patchErr =
        await widget.posVm.submitWalkInOrderBillingPatch(widget.order!);
        if (!mounted) return null;
        if (patchErr != null) {
          ToastService.showError(context, patchErr);
          return null;
        }
      } finally {
        if (mounted) setState(() => _continuingSubmit = false);
      }
      if (!mounted) return null;
    }

    return formResult;
  }

  Future<void> _submitContinue() async {
    final formResult = await saveCustomerDetails();
    if (formResult != null) _close(formResult);
  }

  @override
  Widget build(BuildContext context) {
    // Lock billing only for corporate **walk-in** approval flow, not corporate bookings.
    final isCorporateLocked = widget.order != null &&
        widget.order!.isCorporateWalkIn &&
        !widget.order!.isCorporateBookingOrder;
    final vehicleFieldsLocked = false;
    final mq = MediaQuery.sizeOf(context);
    // Compact card; same max-width formula as payment dialog.
    final maxW = min(520.0, mq.width - 40);
    final maxH = min(520.0, mq.height * 0.78);
    final formBody = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            _walkInInvoiceSectionHeader(
              AppLocalizations.of(context)!.posReviewCustomerDetails,
              null,
              compact: true,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _walkInInvoiceCustomerNameField(
                    isCorporateLocked: isCorporateLocked,
                    lockNameMobileFromEmployee: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _walkInInvoiceMobileAutocompleteField(
                    isCorporateLocked: isCorporateLocked,
                    lockNameMobileFromEmployee: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _vatCtrl,
                    readOnly: isCorporateLocked,
                    style: _kWalkInInvoiceDialogFieldStyle,
                    decoration: _walkInInvoiceFieldDecoration(
                      AppLocalizations.of(context)!.posInvoiceDetailsVat,
                      optional: true,
                      optionalSuffix:
                          AppLocalizations.of(context)!.posSalesReturnOptional,
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showOptionalPlateField && !widget.showVehicleSection) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _plateCtrl,
                style: _kWalkInInvoiceDialogFieldStyle,
                textCapitalization: TextCapitalization.characters,
                decoration: _walkInInvoiceFieldDecoration(
                  AppLocalizations.of(context)!.posInvoiceDetailsPlateNumber,
                  optional: true,
                  optionalSuffix:
                      AppLocalizations.of(context)!.posSalesReturnOptional,
                  compact: true,
                ),
              ),
            ],
            if (widget.showVehicleSection) ...[
              const SizedBox(height: 14),
              _walkInInvoiceSectionHeader(
                AppLocalizations.of(context)!.posReviewVehicle,
                null,
                compact: true,
              ),
              const SizedBox(height: 8),
              _buildWalkInVehicleKindSelector(enabled: !vehicleFieldsLocked),
              const SizedBox(height: 8),
              if (!_isWalkInBike) ...[
                // GCC country (+ UAE emirate) picker — same flow as
                // "Add New Order". Hidden for Saudi motorcycle plates.
                GccPlateCountrySelector(
                  countryCode: _plateCountryCode,
                  emirate: _plateEmirate,
                  enabled: !vehicleFieldsLocked,
                  onCountryChanged: (code) {
                    if (vehicleFieldsLocked) return;
                    setState(() {
                      _plateCountryCode = code;
                      _plateEmirate = code == 'AE'
                          ? (_plateEmirate ?? UaeEmirate.all[1].key)
                          : null;
                    });
                  },
                  onEmirateChanged: (em) {
                    if (vehicleFieldsLocked) return;
                    setState(() => _plateEmirate = em);
                  },
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _walkInInvoicePlateAutocompleteField(
                      vehicleFieldsLocked: vehicleFieldsLocked,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _odoCtrl,
                      readOnly: vehicleFieldsLocked,
                      style: _kWalkInInvoiceDialogFieldStyle,
                      decoration: _walkInInvoiceFieldDecoration(
                        AppLocalizations.of(context)!.posInvoiceDetailsOdometer,
                        optional: true, optionalSuffix: AppLocalizations.of(context)!.posSalesReturnOptional,
                        compact: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _walkInInvoiceYearAutocompleteField(
                      vehicleFieldsLocked: vehicleFieldsLocked,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _walkInInvoiceKsaMakeModelRow(
                vehicleFieldsLocked: vehicleFieldsLocked,
                thirdChild: TextFormField(
                  controller: _vinCtrl,
                  readOnly: vehicleFieldsLocked,
                  style: _kWalkInInvoiceDialogFieldStyle,
                  decoration: _walkInInvoiceFieldDecoration(
                    AppLocalizations.of(context)!.posInvoiceDetailsVin,
                    optional: true,
                    optionalSuffix:
                        AppLocalizations.of(context)!.posSalesReturnOptional,
                    compact: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      );

    if (widget.embedded) {
      return formBody;
    }

    final formScroll = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      physics: widget.showVehicleSection
          ? null
          : const ClampingScrollPhysics(),
      child: formBody,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      backgroundColor: AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: widget.showVehicleSection
            ? BoxConstraints(maxWidth: maxW, maxHeight: maxH)
            : BoxConstraints(maxWidth: maxW),
        child: Column(
          mainAxisSize: widget.showVehicleSection
              ? MainAxisSize.max
              : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.showVehicleSection
                        ? AppLocalizations.of(context)!.posInvoiceDetailsTitle
                        : AppLocalizations.of(context)!.posInvoiceDetailsCustomerDetails,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.showVehicleSection
                        ? AppLocalizations.of(context)!.posInvoiceDetailsConfirmVehicle
                        : AppLocalizations.of(context)!.posInvoiceDetailsConfirmContact,
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
            if (widget.showVehicleSection)
              Expanded(child: formScroll)
            else
              formScroll,
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _continuingSubmit ? null : () => _close(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.posReviewCancelBtn,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.onPrimaryLight,
                      disabledBackgroundColor: AppColors.primaryLight,
                      disabledForegroundColor: AppColors.onPrimaryLight,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                    _continuingSubmit ? null : _submitContinue,
                    child: _continuingSubmit
                        ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimaryLight),
                      ),
                    )
                        : Text(
                      AppLocalizations.of(context)!.posReviewContinueBtn,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

// ── View ──────────────────────────────────────────────────────────────────────

class PosOrderReviewView extends StatefulWidget {
  final PosOrder order;
  final Invoice? invoice;

  const PosOrderReviewView({super.key, required this.order, this.invoice});

  @override
  State<PosOrderReviewView> createState() => _PosOrderReviewViewState();
}

class _PosOrderReviewViewState extends State<PosOrderReviewView> {
  List<ReviewLineItem> _items = [];

  // Financial variables
  static const double _vatRate = 0.15;

  // UX state
  bool? _isCorporate; // null = not answered yet
  Set<PaymentMethod> _selectedPayments = {};
  bool _isGenerated = false;
  bool _isLoading = false;
  Invoice? _currentInvoice;
  bool _canExit = false;

  // Inline split payment controllers (created/disposed as _selectedPayments changes)
  final Map<PaymentMethod, TextEditingController> _splitControllers = {};

  // Inline billing + vehicle form (walk-in orders)
  final _billingFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _vatCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _odoCtrl;

  /// Invoice contact: optional pick from GET [/cashier/employees] when customer is staff.
  bool _inlineBillingPickEmployeeMode = false;
  List<BranchEmployee> _inlineBillingEmployeesPickList = [];
  bool _inlineBillingEmployeesPickLoading = false;
  BranchEmployee? _inlineBillingEmployeePickSelection;

  /// Standard walk‑in billing PATCH allowed (editable contact / vehicle).
  bool get _billingWalkInEditable =>
      !(widget.order.isCorporateWalkIn && !widget.order.isCorporateBookingOrder);

  /// Branch employee customer: payroll — skip retail payment picker; use Employees + selected staff id.
  bool get _isBranchEmployeeRetailWalkIn =>
      _isStandardWalkInOrder(widget.order) &&
          _billingWalkInEditable &&
          _inlineBillingPickEmployeeMode;

  /// Six bilingual checklist rows; persisted via PATCH before invoice.
  late final List<bool> _maintenanceCheckDone;
  bool _maintenanceChecklistSavedOnServer = false;

  /// Takeaway skips checklist; other sources need server-saved checklist before invoicing.
  bool _isMaintenanceChecklistSavedOnServer(PosOrder order) {
    if (order.isTakeawaySource) return true;
    final m = order.maintenanceChecks;
    return m != null && m.length == InvoiceMaintenanceChecklist.rows.length;
  }

  PosOrder _orderForReview(pvm.PosViewModel posVm) {
    final id = widget.order.id.trim();
    if (id.isEmpty) return widget.order;
    if (posVm.selectedOrder?.id.trim() == id) return posVm.selectedOrder!;
    for (final o in posVm.orders) {
      if (o.id.trim() == id) return o;
    }
    return widget.order;
  }

  /// Tablet split-row scroll areas (Final Review) — scrollbars on tech + summary only.
  late final ScrollController _reviewTechScrollController;
  late final ScrollController _reviewSummaryScrollController;

  @override
  void initState() {
    super.initState();
    final mc = widget.order.maintenanceChecks;
    _maintenanceCheckDone = (mc != null &&
        mc.length == InvoiceMaintenanceChecklist.rows.length)
        ? List<bool>.from(mc)
        : List<bool>.filled(
      InvoiceMaintenanceChecklist.rows.length,
      false,
    );
    _maintenanceChecklistSavedOnServer =
        _isMaintenanceChecklistSavedOnServer(widget.order);
    _reviewTechScrollController = ScrollController();
    _reviewSummaryScrollController = ScrollController();
    _currentInvoice = widget.invoice;
    if (_currentInvoice != null) {
      _isGenerated = true;
    }
    _buildItems();
    _initBillingControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
      if (posVm.invoicePaymentIsCorporate == null) return;
      setState(() {
        _isCorporate = posVm.invoicePaymentIsCorporate;
        _selectedPayments = Set<PaymentMethod>.from(posVm.invoicePaymentMethods)
          ..remove(PaymentMethod.employees);
        if (_isCorporate == true && _selectedPayments.isEmpty) {
          _selectedPayments = {PaymentMethod.monthlyBilling};
        }
        _syncSplitControllers();
        for (final entry in posVm.invoicePaymentAmounts.entries) {
          final c = _splitControllers[entry.key];
          if (c != null && entry.value > 0) {
            c.text = entry.value.toStringAsFixed(2);
          }
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _hydrateInlineBillingEmployeeUi();
    });
  }

  @override
  void didUpdateWidget(covariant PosOrderReviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id) {
      _resetStateForOrder(widget.order);
      return;
    }
    final mc = widget.order.maintenanceChecks;
    if (mc == null || mc.length != InvoiceMaintenanceChecklist.rows.length) {
      return;
    }
    var differ = false;
    for (var i = 0; i < mc.length; i++) {
      if (_maintenanceCheckDone[i] != mc[i]) differ = true;
    }
    if (differ) {
      setState(() {
        for (var i = 0; i < mc.length; i++) {
          _maintenanceCheckDone[i] = mc[i];
        }
      });
    }
  }

  void _resetStateForOrder(PosOrder order) {
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    _splitControllers.clear();
    _selectedPayments.clear();
    _isCorporate = null;
    _isGenerated = false;
    _isLoading = false;
    _canExit = false;
    _currentInvoice = widget.invoice;
    if (_currentInvoice != null) {
      _isGenerated = true;
    }
    final mc = order.maintenanceChecks;
    if (mc != null && mc.length == InvoiceMaintenanceChecklist.rows.length) {
      for (var i = 0; i < mc.length; i++) {
        _maintenanceCheckDone[i] = mc[i];
      }
    } else {
      for (var i = 0; i < _maintenanceCheckDone.length; i++) {
        _maintenanceCheckDone[i] = false;
      }
    }
    _maintenanceChecklistSavedOnServer =
        _isMaintenanceChecklistSavedOnServer(order);
    _applyBillingTextsForOrder(order);
    _buildItems();
    _inlineBillingPickEmployeeMode = false;
    _inlineBillingEmployeePickSelection = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
      if (posVm.invoicePaymentIsCorporate == null) return;
      setState(() {
        _isCorporate = posVm.invoicePaymentIsCorporate;
        _selectedPayments = Set<PaymentMethod>.from(posVm.invoicePaymentMethods)
          ..remove(PaymentMethod.employees);
        if (_isCorporate == true && _selectedPayments.isEmpty) {
          _selectedPayments = {PaymentMethod.monthlyBilling};
        }
        _syncSplitControllers();
        for (final entry in posVm.invoicePaymentAmounts.entries) {
          final c = _splitControllers[entry.key];
          if (c != null && entry.value > 0) {
            c.text = entry.value.toStringAsFixed(2);
          }
        }
      });
      await _hydrateInlineBillingEmployeeUi();
    });
  }

  /// Snapshot wins over GET order; then toggles UI + roster selection from billing flags.
  Future<void> _hydrateInlineBillingEmployeeUi() async {
    if (!mounted) return;
    final o = widget.order;
    final billingLocked =
        o.isCorporateWalkIn && !o.isCorporateBookingOrder;
    if (billingLocked) return;

    final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
    final snap = posVm.walkInBillingSnapshotForOrder(o.id);
    final c = o.customer;

    final bool pickMode;
    final String? prefId;
    if (snap != null) {
      pickMode = snap.billingCustomerIsEmployee;
      prefId = snap.billingEmployeeId;
    } else {
      pickMode = c?.isCustomerEmployee ?? false;
      prefId = c?.branchEmployeeId;
    }
    if (!pickMode) return;

    setState(() => _inlineBillingPickEmployeeMode = true);
    await _ensureInlineBillingEmployeesPickLoaded();
    if (!mounted) return;
    final pid = prefId?.trim();
    if (pid == null || pid.isEmpty) return;
    for (final e in _inlineBillingEmployeesPickList) {
      if (e.id == pid) {
        setState(() => _inlineBillingEmployeePickSelection = e);
        break;
      }
    }
  }

  void _applyBillingTextsForOrder(PosOrder o) {
    final c = o.customer;
    final v = o.vehicle;
    final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
    final snap = posVm.walkInBillingSnapshotForOrder(o.id);
    if (snap != null) {
      _nameCtrl.text = _walkInInvoiceCustomerNameSeed(o, snap);
      _mobileCtrl.text = _walkInInvoiceMobileDisplay(
        snap.mobile.trim().isNotEmpty ? snap.mobile : (c?.mobile ?? '').trim(),
      );
      _vatCtrl.text =
          snap.vat.trim().isNotEmpty ? snap.vat : (c?.vatNumber ?? '').trim();
      _plateCtrl.text = formatVehiclePlateLettersFirst(
        snap.vehicleNumber.trim().isNotEmpty
            ? snap.vehicleNumber
            : (v?.plateNo ?? '').trim(),
      );
      _makeCtrl.text =
          snap.make.trim().isNotEmpty ? snap.make : (v?.make ?? '').trim();
      _modelCtrl.text =
          snap.model.trim().isNotEmpty ? snap.model : (v?.model ?? '').trim();
      _yearCtrl.text = _walkInInvoiceVehicleYearSeed(o, snap, posVm);
      _vinCtrl.text =
          snap.vin.trim().isNotEmpty ? snap.vin : (v?.vin ?? '').trim();
      _odoCtrl.text = snap.odometer != 0
          ? '${snap.odometer}'
          : (o.odometerReading != 0 ? '${o.odometerReading}' : '');
    } else {
      _nameCtrl.text = _walkInInvoiceCustomerNameSeed(o, null);
      _mobileCtrl.text = _walkInInvoiceMobileDisplay((c?.mobile ?? '').trim());
      _vatCtrl.text = (c?.vatNumber ?? '').trim();
      _plateCtrl.text =
          formatVehiclePlateLettersFirst((v?.plateNo ?? '').trim());
      _makeCtrl.text = (v?.make ?? '').trim();
      _modelCtrl.text = (v?.model ?? '').trim();
      _yearCtrl.text = _walkInInvoiceVehicleYearSeed(o, null, posVm);
      _vinCtrl.text = (v?.vin ?? '').trim();
      _odoCtrl.text =
          o.odometerReading != 0 ? '${o.odometerReading}' : '';
    }
  }

  void _initBillingControllers() {
    final o = widget.order;
    final c = o.customer;
    final v = o.vehicle;
    final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
    final snap = posVm.walkInBillingSnapshotForOrder(o.id);
      if (snap != null) {
        _nameCtrl = TextEditingController(
        text: _walkInInvoiceCustomerNameSeed(o, snap),
      );
      _mobileCtrl = TextEditingController(
        text: _walkInInvoiceMobileDisplay(
          snap.mobile.trim().isNotEmpty ? snap.mobile : (c?.mobile ?? '').trim(),
        ),
      );
      _vatCtrl = TextEditingController(
        text: snap.vat.trim().isNotEmpty ? snap.vat : (c?.vatNumber ?? '').trim(),
      );
      _plateCtrl = TextEditingController(
        text: formatVehiclePlateLettersFirst(
          snap.vehicleNumber.trim().isNotEmpty
              ? snap.vehicleNumber
              : (v?.plateNo ?? '').trim(),
        ),
      );
      _makeCtrl = TextEditingController(
        text: snap.make.trim().isNotEmpty ? snap.make : (v?.make ?? '').trim(),
      );
      _modelCtrl = TextEditingController(
        text: snap.model.trim().isNotEmpty ? snap.model : (v?.model ?? '').trim(),
      );
      _yearCtrl = TextEditingController(
        text: _walkInInvoiceVehicleYearSeed(o, snap, posVm),
      );
      _vinCtrl = TextEditingController(
        text: snap.vin.trim().isNotEmpty ? snap.vin : (v?.vin ?? '').trim(),
      );
      _odoCtrl = TextEditingController(
        text: snap.odometer != 0
            ? '${snap.odometer}'
            : (o.odometerReading != 0 ? '${o.odometerReading}' : ''),
      );
    } else {
      _nameCtrl = TextEditingController(
        text: _walkInInvoiceCustomerNameSeed(o, null),
      );
      _mobileCtrl = TextEditingController(
          text: _walkInInvoiceMobileDisplay((c?.mobile ?? '').trim()),
        );
      _vatCtrl = TextEditingController(text: (c?.vatNumber ?? '').trim());
      _plateCtrl = TextEditingController(
        text: formatVehiclePlateLettersFirst((v?.plateNo ?? '').trim()),
      );
      _makeCtrl = TextEditingController(text: (v?.make ?? '').trim());
      _modelCtrl = TextEditingController(text: (v?.model ?? '').trim());
      _yearCtrl = TextEditingController(
        text: _walkInInvoiceVehicleYearSeed(o, null, posVm),
      );
      _vinCtrl = TextEditingController(text: (v?.vin ?? '').trim());
      _odoCtrl = TextEditingController(
        text: o.odometerReading != 0 ? '${o.odometerReading}' : '',
      );
    }
  }

  static String _pickField(String vm, String fallback) {
    final a = vm.trim();
    return a.isNotEmpty ? a : fallback.trim();
  }

  static int _parseOdometer(String s) {
    final t = s.trim().replaceAll(RegExp(r'[\s,]'), '');
    if (t.isEmpty) return 0;
    return int.tryParse(t) ?? 0;
  }

  void _syncSplitControllers() {
    final current = Set.of(_splitControllers.keys);
    final desired = Set.of(_selectedPayments);
    for (final removed in current.difference(desired)) {
      _splitControllers[removed]!.dispose();
      _splitControllers.remove(removed);
    }
    for (final added in desired.difference(current)) {
      _splitControllers[added] = TextEditingController();
    }
  }

  Map<String, dynamic> _paymentSplitLine(PaymentMethod pm, double amount) {
    return <String, dynamic>{
      'method': pm.label,
      'amount': amount,
    };
  }

  Widget _buildSoftPosBridgeSettingsRow() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          await showSoftPosSettingsDialog(context);
        },
        icon: const Icon(Icons.contactless_outlined, size: 18),
        label: const Text('SoftPOS settings'),
      ),
    );
  }

  Future<bool> _runSoftPosBridgeIfNeeded({
    required List<Map<String, dynamic>>? paymentSplits,
  }) async {
    if (paymentSplits == null) return true;

    final order = widget.order;
    final customer = order.customer;
    final vehicle = order.vehicle;
    final plate = _isStandardWalkInOrder(order)
        ? _plateCtrl.text.trim()
        : (vehicle?.plateNo ?? '').trim();

    try {
      return await runSoftPosBeforeInvoice(
        context: context,
        order: order,
        paymentSplits: paymentSplits,
        customerNameOverride: _isStandardWalkInOrder(order)
            ? _nameCtrl.text.trim()
            : (customer?.name ?? '').trim(),
        customerMobileOverride: _isStandardWalkInOrder(order)
            ? _walkInInvoiceMobilePayload(_mobileCtrl.text)
            : (customer?.mobile ?? '').trim(),
        plateNoOverride: plate.isNotEmpty ? plate : null,
      );
    } on SoftPosBridgeException catch (e) {
      if (!mounted) return false;
      ToastService.showError(context, e.message);
      return false;
    }
  }

  Future<void> _ensureInlineBillingEmployeesPickLoaded() async {
    if (_inlineBillingEmployeesPickLoading ||
        _inlineBillingEmployeesPickList.isNotEmpty) {
      return;
    }
    setState(() => _inlineBillingEmployeesPickLoading = true);
    try {
      final session = Provider.of<SessionService>(context, listen: false);
      final repo = Provider.of<PosRepository>(context, listen: false);
      final token = await session.getToken(role: 'cashier');
      if (!mounted) return;
      if (token == null) throw Exception('Session');
      final res = await repo.getCashierEmployees(token);
      if (!mounted) return;
      setState(() {
        _inlineBillingEmployeesPickList = res.employees;
        _inlineBillingEmployeesPickLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _inlineBillingEmployeesPickLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load branch employees.')),
      );
    }
  }

  void _onRetailPaymentMethodsChanged(Set<PaymentMethod> pms) {
    setState(() {
      _selectedPayments = pms;
      _syncSplitControllers();
    });
  }

  void _onCorporateCustomerChanged(bool? v) {
    setState(() {
      _isCorporate = v;
      if (v == true) {
        _selectedPayments = {PaymentMethod.monthlyBilling};
      } else if (v == false) {
        _selectedPayments = {};
      }
    });
  }

  Future<void> _submitMaintenanceChecklistDialog(
      BuildContext dialogContext,
      VoidCallback setBusy,
      VoidCallback setIdle,
      ) async {
    final session =
    Provider.of<SessionService>(context, listen: false);
    final repo = Provider.of<PosRepository>(context, listen: false);
    final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
    setBusy();
    final token = await session.getToken(role: 'cashier');
    if (!mounted || token == null) {
      setIdle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in again.')),
        );
      }
      return;
    }
    try {
      final res = await repo.patchOrderMaintenanceChecklist(
        orderId: widget.order.id,
        checks: List<bool>.from(_maintenanceCheckDone),
        token: token,
      );
      await posVm.refreshOrderInHubAfterMutation(
        widget.order.id,
        apiResponse: res,
      );
      if (!mounted) return;
      setState(() {
        _maintenanceChecklistSavedOnServer = true;
      });
      setIdle();
      Navigator.of(dialogContext).pop();
      if (!mounted) return;
      ToastService.showSuccess(context, AppLocalizations.of(context)!.posOrdersChecklistSaved);
    } catch (e) {
      setIdle();
      if (!mounted) return;
      ToastService.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Same 6 bilingual lines as printable invoice — rows saved via PATCH for this order.
  void _showMaintenanceChecklistDialog() {
    final savingRef = <bool>[false];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void toggle(int i, bool? v) {
            if (savingRef[0]) return;
            setState(() => _maintenanceCheckDone[i] = v ?? false);
            setModalState(() {});
          }

          final l10n = AppLocalizations.of(context)!;
          final size = MediaQuery.sizeOf(dialogContext);
          final isTablet = size.width > 600;
          final hubInsets = posOrdersHubDialogInsets(size);

          return Dialog(
            insetPadding: hubInsets,
            backgroundColor: const Color(0xFFFBF9F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height - hubInsets.vertical,
                maxWidth: 560,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PosPrimaryDialogHeader(
                    title: l10n.posOrdersMaintenanceChecklistTitle,
                    isTablet: isTablet,
                    onClose: savingRef[0]
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 16 : 12,
                        isTablet ? 12 : 10,
                        isTablet ? 16 : 12,
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.posOrdersMaintenanceChecklistDescription,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PosMaintenanceChecklistBulkActions(
                            disabled: savingRef[0],
                            onSelectAll: () {
                              setState(() {
                                for (var i = 0;
                                    i < _maintenanceCheckDone.length;
                                    i++) {
                                  _maintenanceCheckDone[i] = true;
                                }
                              });
                              setModalState(() {});
                            },
                            onClearAll: () {
                              setState(() {
                                for (var i = 0;
                                    i < _maintenanceCheckDone.length;
                                    i++) {
                                  _maintenanceCheckDone[i] = false;
                                }
                              });
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(height: 4),
                          for (var i = 0;
                              i < InvoiceMaintenanceChecklist.rows.length;
                              i++)
                            CheckboxListTile(
                              value: _maintenanceCheckDone[i],
                              onChanged:
                                  savingRef[0] ? null : (v) => toggle(i, v),
                              title: Text(
                                (Localizations.localeOf(context)
                                            .languageCode ==
                                        'ar'
                                    ? InvoiceMaintenanceChecklist.rows[i].ar
                                    : InvoiceMaintenanceChecklist.rows[i].en),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                InvoiceMaintenanceChecklist.rows[i].ar,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 14 : 12,
                      8,
                      isTablet ? 14 : 12,
                      isTablet ? 12 : 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: savingRef[0]
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          style: AppButtonBusy.elevatedLocked(
                            backgroundColor: AppColors.secondaryLight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            l10n.posCommonCancel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: savingRef[0]
                              ? null
                              : () => _submitMaintenanceChecklistDialog(
                                    dialogContext,
                                    () {
                                      savingRef[0] = true;
                                      setModalState(() {});
                                    },
                                    () {
                                      savingRef[0] = false;
                                      if (ctx.mounted) setModalState(() {});
                                    },
                                  ),
                          style: AppButtonBusy.filledLocked(
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (savingRef[0]) ...[
                                AppButtonBusy.loaderOnFill(
                                  AppColors.primaryLight,
                                  size: 20,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                l10n.posCommonSave,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceChecklistGate(bool isTablet) {
    return Consumer<pvm.PosViewModel>(
      builder: (context, posVm, _) {
        final liveOrder = _orderForReview(posVm);
        final saved = _maintenanceChecklistSavedOnServer ||
            _isMaintenanceChecklistSavedOnServer(liveOrder);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!saved)
              Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 10 : 8),
                child: Text(
                  'Optional: invoice print par checklist dikhane ke liye yahan save kar sakte hain.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                    height: 1.35,
                  ),
                ),
              ),
            OutlinedButton.icon(
              icon: Icon(
                saved ? Icons.check_circle : Icons.fact_check_outlined,
                color: AppColors.secondaryLight,
              ),
              label: Text(
                saved
                    ? 'Checklist saved (tap to edit)'
                    : AppLocalizations.of(context)!.posOrdersChecklistOptional,
              ),
              onPressed: _showMaintenanceChecklistDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryLight,
                side: BorderSide(
                  color: saved ? Colors.green.shade700 : Colors.blueGrey.shade400,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 14 : 12,
                  horizontal: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _vatCtrl.dispose();
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _vinCtrl.dispose();
    _odoCtrl.dispose();
    _reviewTechScrollController.dispose();
    _reviewSummaryScrollController.dispose();
    super.dispose();
  }

  void _buildItems() {
    if (_currentInvoice != null) {
      _items = [];
      for (var dept in _currentInvoice!.departments) {
        for (var item in dept.items) {
          _items.add(
            ReviewLineItem(
              name: _reviewProductNameForLocale(
                context,
                productName: item.productName,
                productNameArabic: item.productNameArabic,
              ),
              technicianName: dept.departmentName,
              unitPrice: item.unitPrice,
              qty: item.qty.toInt(),
              commissionRate: 0.10, // Mock commission fallback
              discountType: item.discountType,
              discountValue: item.discountValue ?? 0.0,
            ),
          );
        }
      }
      if (_items.isEmpty && _currentInvoice!.items.isNotEmpty) {
        _items = _currentInvoice!.items
            .map(
              (item) => ReviewLineItem(
            name: _reviewProductNameForLocale(
              context,
              productName: item.productName,
              productNameArabic: item.productNameArabic,
            ),
            technicianName: AppLocalizations.of(context)!.posReviewTechnicianFallback,
            unitPrice: item.unitPrice,
            qty: item.qty.toInt(),
          ),
        )
            .toList();
      }
    } else if (widget.order.jobs.any((j) => !j.isCancelledJob)) {
      _items = widget.order.jobs
          .where((j) => !j.isCancelledJob)
          .expand((job) {
        return job.items.map((item) {
          return ReviewLineItem(
            name: _reviewProductNameForLocale(
              context,
              productName: item.productName,
              productNameArabic: item.productNameArabic,
              fallback: item.productId,
            ),
            technicianName: job.department,
            unitPrice: item.unitPrice,
            qty: item.qty.toInt(),
            commissionRate: 0.10,
            discountType: item.discountType,
            discountValue: item.discountValue ?? 0.0,
          );
        });
      }).toList();
    } else if (widget.order.items.isNotEmpty) {
      _items = widget.order.items.map((item) {
        final priceDynamic = item['price'] ?? item['unitPrice'] ?? 0.0;
        final double price = priceDynamic is int
            ? priceDynamic.toDouble()
            : (priceDynamic as double? ?? 0.0);
        return ReviewLineItem(
          name: _reviewProductNameForLocale(
            context,
            productName: (item['productName'] ?? item['name'] ?? '').toString(),
            productNameArabic: (item['productNameArabic'] ??
                    item['product_name_arabic'] ??
                    item['nameArabic'] ??
                    item['name_arabic'])
                ?.toString(),
          ),
          technicianName: widget.order.jobs.any((j) => !j.isCancelledJob)
              ? widget.order.jobs.firstWhere((j) => !j.isCancelledJob).department
              : AppLocalizations.of(context)!.posReviewTechnicianFallback,
          unitPrice: price,
          qty: item['quantity'] ?? item['qty'] ?? 1,
          commissionRate: 0.10, // Mock commission fallback
        );
      }).toList();
    } else {
      _items = [];
    }
  }

  List<PosOrderJob> get _activeJobs =>
      widget.order.jobs.where((j) => !j.isCancelledJob).toList();

  // ── Gross Amount (Excl. VAT) ──
  // Sum of amountBeforeDiscount across active jobs — backend now stores VAT-exclusive.
  double get _grossSubtotal {
    if (_currentInvoice != null) return _currentInvoice!.subtotal;
    final fromJobs = _activeJobs.fold<double>(
      0.0,
          (s, j) => s + j.amountBeforeDiscount,
    );
    if (fromJobs > 0) return fromJobs;
    return _items.fold(0.0, (s, i) => s + i.grossBeforeVat);
  }

  // ── Item discounts (sum of per-line discounts) ──
  double get _itemDiscountsTotal =>
      _items.fold(0.0, (s, i) => s + i.discountAmount);

  // ── Invoice discount (job-level) ──
  double get _invoiceDiscountTotal {
    final active = _activeJobs;
    double total = 0;
    for (final job in active) {
      if (job.totalDiscountType == 'percent' || job.totalDiscountType == 'percentage') {
        total += job.amountAfterDiscount > 0
            ? job.amountAfterDiscount * (job.totalDiscountValue / 100)
            : 0;
      } else {
        total += job.totalDiscountValue;
      }
    }
    if (total > 0) return total;
    // Fallback to order-level
    if (widget.order.totalDiscountType == 'percent' ||
        widget.order.totalDiscountType == 'percentage') {
      final base = _grossSubtotal - _itemDiscountsTotal;
      return base * ((widget.order.totalDiscountValue ?? 0) / 100);
    }
    return widget.order.totalDiscountValue ?? 0;
  }

  // ── Promo discount ──
  double get _promoDiscountTotal {
    final fromJobs = _activeJobs.fold<double>(
      0.0,
          (s, j) => s + j.promoDiscountAmount,
    );
    if (fromJobs > 0) return fromJobs;
    return widget.order.promoDiscountAmount ?? 0;
  }

  // ── Total of all discounts (for display) ──
  double get _totalDiscountAmount {
    if (_currentInvoice != null) return _currentInvoice!.discountAmount;
    return _itemDiscountsTotal + _invoiceDiscountTotal + _promoDiscountTotal;
  }

  // ── Total Taxable Amount (after ALL discounts, before VAT) ──
  double get _netSubtotal {
    if (_currentInvoice != null) {
      return max(0, _currentInvoice!.totalAmount - _currentInvoice!.vatAmount);
    }
    final fromJobs = _activeJobs.fold<double>(
      0.0,
          (s, j) => s + j.amountAfterPromo,
    );
    if (fromJobs > 0) return fromJobs;
    return max(0, _grossSubtotal - _totalDiscountAmount);
  }

  // ── VAT 15% ──
  double get _vatAmount {
    if (_currentInvoice != null) return _currentInvoice!.vatAmount;
    // Draft review must always recompute VAT from the final discounted amount.
    // Job-level cached VAT can be stale after order/promo discounts are edited.
    return _netSubtotal * 0.15;
  }

  // ── Final Total (Taxable + VAT) ──
  double get _totalAmount {
    if (_currentInvoice != null) return _currentInvoice!.totalAmount;
    // Same rule as VAT: derive the total from the latest discounted subtotal,
    // not from precomputed draft/job totals that may still reflect older tax.
    return _netSubtotal + _vatAmount;
  }

  String? get _promoCode =>
      _currentInvoice?.promoCodeName ?? widget.order.promoCodeName;

  // Build commission display entries from real invoice data
  List<_CommissionDisplayEntry> get _commissions {
    if (_currentInvoice != null && _currentInvoice!.departments.isNotEmpty) {
      final entries = <_CommissionDisplayEntry>[];
      for (final dept in _currentInvoice!.departments) {
        for (final c in dept.commissions) {
          if (c.technicianName.isNotEmpty) {
            entries.add(_CommissionDisplayEntry(
              technicianName: c.technicianName,
              departmentName: dept.departmentName,
              commissionAmount: c.commissionAmount,
              commissionPercent: c.commissionPercent,
            ));
          }
        }
      }
      if (entries.isNotEmpty) return entries;
    }

    // Fallback 1: use technician data already present in the order's jobs
    final jobEntries = <_CommissionDisplayEntry>[];
    for (final job in widget.order.jobs.where((j) => !j.isCancelledJob)) {
      final active =
      job.distinctActiveTechnicians.where((t) => t.name.isNotEmpty).toList();
      final n = active.length;
      for (final tech in active) {
        double amount = tech.commissionAmount;
        double percent = tech.commissionPercent;
        // If backend didn't return a monetary amount, estimate one pool from job total
        // and split equally across assigned technicians (2 techs → each gets pool/2).
        if (amount <= 0) {
          final rate = percent > 0 ? percent / 100.0 : 0.10;
          final pool = job.totalAmount * rate;
          amount = n > 0 ? pool / n : pool;
          if (percent <= 0) percent = 10.0;
        }
        jobEntries.add(_CommissionDisplayEntry(
          technicianName: tech.name,
          departmentName: job.department,
          commissionAmount: amount,
          commissionPercent: percent,
        ));
      }
    }
    if (jobEntries.isNotEmpty) return jobEntries;

    // Fallback 2: pure 10% estimate — no technician data at all
    if (_totalAmount <= 0) return [];
    return [
      _CommissionDisplayEntry(
        technicianName: AppLocalizations.of(context)!.posReviewTechnicianFallback,
        departmentName: widget.order.jobs.any((j) => !j.isCancelledJob)
            ? widget.order.jobs.firstWhere((j) => !j.isCancelledJob).department
            : '',
        commissionAmount: _totalAmount * 0.10,
        commissionPercent: 10.0,
      )
    ];
  }

  bool _isStandardWalkInOrder(PosOrder o) {
    return Provider.of<pvm.PosViewModel>(context, listen: false)
        .isStandardWalkInOrderForBilling(o);
  }

  /// Standard walk-in: confirm billing + vehicle (merged into billing PATCH before invoice).
  Future<bool> _ensureWalkInBillingContact(pvm.PosViewModel posVm) async {
    if (!_isStandardWalkInOrder(widget.order)) return true;

    final result = await showDialog<WalkInInvoiceFormResult?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WalkInInvoiceDetailsDialog(
        order: widget.order,
        posVm: posVm,
      ),
    );

    if (result != null) return true;

    return false;
  }

  Future<List<Map<String, dynamic>>?> _promptForSplitAmounts() async {
    if (_selectedPayments.length == 1) {
      return [
        _paymentSplitLine(_selectedPayments.first, _totalAmount),
      ];
    }

    final controllers = <PaymentMethod, TextEditingController>{};
    for (final pm in _selectedPayments) {
      controllers[pm] = TextEditingController();
    }

    return await showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentSum = 0;
            for (final c in controllers.values) {
              currentSum += double.tryParse(c.text.trim()) ?? 0.0;
            }
            final remaining = _totalAmount - currentSum;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.surfaceLight,
              title: Text(
                AppLocalizations.of(context)!.posPaymentMulti,
                style: AppTextStyles.h3.copyWith(color: AppColors.secondaryLight),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.posReviewInvoiceTotal, style: AppTextStyles.bodyMedium),
                          Text(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(_totalAmount.toStringAsFixed(2), Localizations.localeOf(context).languageCode)),
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._selectedPayments.map((pm) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Icon(pm.icon, size: 20, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(pm.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: controllers[pm],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posReviewAmountSar),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (remaining.abs() > 0.05)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          remaining > 0
                              ? AppLocalizations.of(context)!.posPaymentRemaining(AppTranslationService.localizeDigitsForLanguage(remaining.toStringAsFixed(2), Localizations.localeOf(context).languageCode))
                              : AppLocalizations.of(context)!.posOrdersExceedsBy(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(remaining.abs().toStringAsFixed(2), Localizations.localeOf(context).languageCode))),
                          style: TextStyle(
                            color: remaining > 0 ? Colors.orange.shade700 : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text(AppLocalizations.of(context)!.posReviewCancelBtn, style: AppTextStyles.button.copyWith(color: AppColors.secondaryLight)),
                ),
                FilledButton(
                  onPressed: remaining.abs() > 0.05
                      ? null
                      : () {
                    final result = <Map<String, dynamic>>[];
                    for (final pm in _selectedPayments) {
                      final amt =
                          double.tryParse(controllers[pm]!.text.trim()) ??
                              0.0;
                      result.add(_paymentSplitLine(pm, amt));
                    }
                    Navigator.pop(ctx, result);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm amounts'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Inline Split Payment card ────────────────────────────────────────────
  Widget _buildInlineSplitPaymentCard() {
    double currentSum = 0;
    for (final c in _splitControllers.values) {
      currentSum += double.tryParse(c.text.trim()) ?? 0.0;
    }
    final remaining = _totalAmount - currentSum;

    return _SectionCard(
      title: AppLocalizations.of(context)!.posPaymentMulti,
      icon: Icons.call_split_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.posReviewInvoiceTotal, style: AppTextStyles.bodyMedium),
                Text(
                  AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(_totalAmount.toStringAsFixed(2), Localizations.localeOf(context).languageCode)),
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...() {
            final methods = _selectedPayments.toList();
            final rows = <Widget>[];
            for (int i = 0; i < methods.length; i += 2) {
              final first = methods[i];
              final hasSecond = i + 1 < methods.length;
              rows.add(Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(first.icon, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(first.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _splitControllers[first],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posReviewAmountSar),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    if (hasSecond) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(methods[i + 1].icon, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(methods[i + 1].label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _splitControllers[methods[i + 1]],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posReviewAmountSar),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ));
            }
            return rows;
          }(),
          if (remaining.abs() > 0.05)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                remaining > 0
                    ? AppLocalizations.of(context)!.posPaymentRemaining(AppTranslationService.localizeDigitsForLanguage(remaining.toStringAsFixed(2), Localizations.localeOf(context).languageCode))
                    : AppLocalizations.of(context)!.posOrdersExceedsBy(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(remaining.abs().toStringAsFixed(2), Localizations.localeOf(context).languageCode))),
                style: TextStyle(
                  color: remaining > 0 ? Colors.orange.shade700 : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Inline Billing + Vehicle form ───────────────────────────────────────
  Widget _buildInlineBillingForm() {
    final billingContactLocked = widget.order.isCorporateWalkIn &&
        !widget.order.isCorporateBookingOrder;
    final lockNameMobileFromEmployee =
        !billingContactLocked && _inlineBillingPickEmployeeMode;
    return _SectionCard(
      title: AppLocalizations.of(context)!.posInvoiceDetailsTitle,
      icon: Icons.receipt_outlined,
      child: Form(
        key: _billingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _walkInInvoiceSectionHeader(AppLocalizations.of(context)!.posReviewBilling, Icons.person_outline_rounded),
            const SizedBox(height: 12),
            if (!billingContactLocked) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppLocalizations.of(context)!.posInvoiceDetailsBranchEmployee,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.posInvoiceDetailsPickStaff,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _inlineBillingPickEmployeeMode,
                onChanged: (v) {
                  setState(() {
                    _inlineBillingPickEmployeeMode = v;
                    if (!v) {
                      _inlineBillingEmployeePickSelection = null;
                      _nameCtrl.clear();
                      _mobileCtrl.clear();
                    } else {
                      _selectedPayments.clear();
                      _syncSplitControllers();
                      _ensureInlineBillingEmployeesPickLoaded();
                    }
                  });
                },
              ),
              if (_inlineBillingPickEmployeeMode) ...[
                const SizedBox(height: 4),
                if (_inlineBillingEmployeesPickLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  )
                else if (_inlineBillingEmployeesPickList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context)!.posInvoiceDetailsNoEmployees,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<BranchEmployee>(
                    value: _inlineBillingEmployeePickSelection,
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsEmployee),
                    hint: Text(
                      AppLocalizations.of(context)!.posInvoiceDetailsChooseEmployee,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    isExpanded: true,
                    items: _inlineBillingEmployeesPickList.map((e) {
                      final mob = e.mobile ?? '';
                      final sub = mob.isNotEmpty ? ' · $mob' : '';
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          '${e.name}$sub',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (e) {
                      setState(() {
                        _inlineBillingEmployeePickSelection = e;
                        if (e != null) {
                          _nameCtrl.text = e.name;
                          _mobileCtrl.text = _walkInInvoiceMobileDisplay(e.mobile ?? '');
                        }
                      });
                    },
                  ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 4),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    readOnly:
                    billingContactLocked || lockNameMobileFromEmployee,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsCustomerName),
                    textCapitalization: TextCapitalization.words,
                    validator: (s) =>
                    (s == null || s.trim().isEmpty) ? AppLocalizations.of(context)!.posInvoiceDetailsRequired : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextFormField(
                    controller: _mobileCtrl,
                    readOnly:
                    billingContactLocked || lockNameMobileFromEmployee,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                    decoration: _walkInInvoiceMobileFieldDecoration(context),
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      EnglishNumberFormatter(),
                      PosAddCustomerNationalMobileFormatter(
                        _walkInInvoiceMobileDial,
                      ),
                    ],
                    validator: (s) => billingContactLocked || lockNameMobileFromEmployee
                        ? null
                        : walkInNationalMobileValidator(
                            s,
                            AppLocalizations.of(context)!,
                          ),
                  ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _vatCtrl,
                    readOnly: billingContactLocked,
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsVat, optional: true, optionalSuffix: AppLocalizations.of(context)!.posSalesReturnOptional),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _walkInInvoiceSectionHeader(AppLocalizations.of(context)!.posReviewVehicle, Icons.directions_car_outlined),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _plateCtrl,
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsPlateNumber),
                    textCapitalization: TextCapitalization.characters,
                    validator: (s) =>
                    (s == null || s.trim().isEmpty) ? AppLocalizations.of(context)!.posInvoiceDetailsPlateRequired : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _odoCtrl,
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsOdometer, optional: true, optionalSuffix: AppLocalizations.of(context)!.posSalesReturnOptional),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PosKsaVehicleMakeModelRow(
              makeController: _makeCtrl,
              modelController: _modelCtrl,
              decorationFor: _walkInInvoiceFieldDecoration,
              fieldStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF212121),
              ),
              spacing: 10,
              compact: false,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsYear, optional: true, optionalSuffix: AppLocalizations.of(context)!.posSalesReturnOptional),
                    keyboardType: TextInputType.number,
                    validator: (s) {
                      if (s == null || s.trim().isEmpty) return null;
                      final yi = int.tryParse(s.trim());
                      if (yi == null || yi < 1900 || yi > 2100) {
                        return AppLocalizations.of(context)!.posInvoiceDetailsInvalidYear;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _vinCtrl,
                    decoration: _walkInInvoiceFieldDecoration(AppLocalizations.of(context)!.posInvoiceDetailsVin, optional: true, optionalSuffix: AppLocalizations.of(context)!.posSalesReturnOptional),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateInvoice() async {
    if (widget.order.isCorporateWalkIn &&
        !widget.order.isCorporateBookingOrder &&
        (widget.order.isCorporateUnapproved ||
            widget.order.isWaitingCorporateApproval ||
            widget.order.isRejectedByCorporate)) {
      ToastService.showError(
        context,
        'Corporate order must be approved before invoicing.',
      );
      return;
    }
    if (!widget.order.meetsCashierInvoicePrerequisites) {
      final active =
          widget.order.jobs.where((j) => !j.isCancelledJob).toList();
      String reason;
      if (active.isEmpty) {
        reason = 'No active jobs in this order. Add a job before invoicing.';
      } else if (active.any((j) => j.items.isEmpty)) {
        reason = 'Add items to each job before invoicing.';
      } else if (active.any((j) => j.distinctActiveTechnicians.isEmpty)) {
        reason =
            'Assign a technician to each job before invoicing.';
      } else {
        reason = 'Order is not ready for invoicing.';
      }
      ToastService.showError(context, reason);
      return;
    }
    // 1. Corporate decision must be made
    if (_isCorporate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please indicate if this is a corporate customer.'),
        ),
      );
      return;
    }

    // 2. Payment methods (branch employees → Employees line below)
    if (!_isBranchEmployeeRetailWalkIn && _selectedPayments.isEmpty) {
      ToastService.showError(
        context,
        AppLocalizations.of(context)!.posOrdersSelectYourPaymentMethod,
      );
      return;
    }

    // 3. Validate split amounts sum when 2+ methods selected
    List<Map<String, dynamic>>? paymentSplits;
    if (_isBranchEmployeeRetailWalkIn && _isCorporate == false) {
      final eid = (_inlineBillingEmployeePickSelection?.id ?? '').trim();
      if (eid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select the branch employee customer first.')),
        );
        return;
      }
      paymentSplits = <Map<String, dynamic>>[
        {
          'method': PaymentMethod.employees.label,
          'amount': _totalAmount,
          'employeeIds': <String>[eid],
        },
      ];
    } else if (_selectedPayments.length == 1) {
      paymentSplits = [
        _paymentSplitLine(_selectedPayments.first, _totalAmount),
      ];
    } else if (_selectedPayments.length > 1) {
      double splitSum = 0;
      for (final c in _splitControllers.values) {
        splitSum += double.tryParse(c.text.trim()) ?? 0.0;
      }
      if ((splitSum - _totalAmount).abs() > 0.05) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.posReviewSplitAmountsMustEqual(
                  AppTranslationService.localizeDigitsForLanguage(_totalAmount.toStringAsFixed(2), Localizations.localeOf(context).languageCode),
                  AppTranslationService.localizeDigitsForLanguage(splitSum.toStringAsFixed(2), Localizations.localeOf(context).languageCode)),
            ),
          ),
        );
        return;
      }
      paymentSplits = _selectedPayments.map((pm) {
        final amt =
            double.tryParse(_splitControllers[pm]?.text.trim() ?? '') ?? 0.0;
        return _paymentSplitLine(pm, amt);
      }).toList();
    }

    // 4. Validate inline billing form for walk-in orders
    final posVm = Provider.of<pvm.PosViewModel>(context, listen: false);
    if (_isStandardWalkInOrder(widget.order)) {
      final billingLocked = widget.order.isCorporateWalkIn &&
          !widget.order.isCorporateBookingOrder;
      if (!billingLocked && _inlineBillingPickEmployeeMode) {
        if (_inlineBillingEmployeesPickLoading) {
          ToastService.showInfo(context, AppLocalizations.of(context)!.posInvoiceDetailsLoadingEmployees);
          return;
        }
        if (_inlineBillingEmployeePickSelection == null) {
          ToastService.showError(
            context,
            'Please select an employee from the dropdown first.',
          );
          return;
        }
      }
      if (_billingFormKey.currentState?.validate() != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in the required invoice details.')),
        );
        return;
      }
      final v = widget.order.vehicle;
      posVm.updateWalkInBillingContact(
        forOrderId: widget.order.id,
        name: _nameCtrl.text,
        mobile: _walkInInvoiceMobilePayload(_mobileCtrl.text),
        vat: _vatCtrl.text,
        vehicleNumber: _plateCtrl.text,
        vin: _vinCtrl.text,
        make: _makeCtrl.text,
        model: _modelCtrl.text,
        year: _yearCtrl.text,
        color: _pickField(posVm.vehicleColor, v?.color ?? ''),
        odometer: _parseOdometer(_odoCtrl.text),
        billingCustomerIsEmployee:
        !billingLocked && _inlineBillingPickEmployeeMode,
        billingEmployeeId: (!billingLocked && _inlineBillingPickEmployeeMode)
            ? _inlineBillingEmployeePickSelection?.id
            : null,
        billingEmployeeType: (!billingLocked && _inlineBillingPickEmployeeMode)
            ? _inlineBillingEmployeePickSelection?.employeeType
            : null,
      );
    }

    // 5. SoftPOS bridge (Tap to Pay → SoftPOS handset). Retail + corporate.
    // Skip entirely when SoftPOS already prepaid this order.
    if (paymentSplits != null &&
        !widget.order.isPosPrepaid &&
        SoftPosBridge.splitsIncludeSoftPos(paymentSplits)) {
      if (!await SoftPosConnectionGuard.ensureStableOrToast(context)) return;
      final softPosOk = await _runSoftPosBridgeIfNeeded(
        paymentSplits: paymentSplits,
      );
      if (!softPosOk) {
        ToastService.showError(
          context,
          'Tap to Pay was not approved on SoftPOS.',
        );
        return;
      }
    }

    // 6. Submit
    try {
      setState(() => _isLoading = true);

      final response = await posVm.generateInvoice(
        widget.order.id,
        orderForBilling: widget.order,
        isCorporate: _isCorporate,
        paymentMethod: paymentSplits != null && paymentSplits.length == 1
            ? paymentSplits.first['method'] as String?
            : (_isCorporate == true
                ? (_selectedPayments.isNotEmpty
                    ? _selectedPayments.first.label
                    : AppLocalizations.of(context)!.posPaymentCorporate)
                : null),
        payments: paymentSplits,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        // PosViewModel.generateInvoice already removes the invoiced order from
        // the in-memory list and updates stats; no /cashier/orders refetch
        // needed here.
        final inv = response.invoice;
        if (inv != null) {
          final mergedInv = invoiceWithMergedCustomerTax(
            inv,
            widget.order.customer?.vatNumber,
          );
          setState(() {
            _currentInvoice = mergedInv;
            _buildItems();
          });
          if (!mounted) return;
          // Skip the digital invoice popup entirely. Fire thermal print +
          // WhatsApp delivery in parallel and let the cashier keep working —
          // toasts surface via the root ScaffoldMessenger so success/failure
          // appears on whatever screen they land on.
          final paymentText = invoiceDialogPaymentMethodText(
            mergedInv,
            requestedPaymentMethod: _requestedPaymentLabelForInvoice(),
          );
          InvoiceAutoDispatch.dispatch(
            invoice: mergedInv,
            paymentMethodText: paymentText,
            maintenanceChecksFallback: widget.order.maintenanceChecks,
          );
          ToastService.showSuccess(
            context,
            'Invoice generated. Sending to printer and WhatsApp…',
          );
          if (mounted) Navigator.pop(context);
        } else if (mounted) {
          ToastService.showSuccess(
            context,
            response.message ?? 'Invoice generated',
          );
        }
      } else {
        if (mounted) {
          final msg = (response?.message ?? '').trim();
          final l10n = AppLocalizations.of(context)!;
          if (msg.toLowerCase().contains('payment method')) {
            ToastService.showError(context, l10n.posOrdersSelectYourPaymentMethod);
          } else {
            ToastService.showError(
              context,
              msg.isNotEmpty ? msg : 'Failed to generate invoice',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) ToastService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDepartmentJobs(bool isTablet, NumberFormat currencyFormat) {
    final visibleJobs =
    widget.order.jobs.where((j) => !j.isCancelledJob).toList();
    if (visibleJobs.isEmpty) {
      return Center(
        child: Text(
          'No departmental data found.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade500),
        ),
      );
    }
    final sortedJobs = List<PosOrderJob>.from(visibleJobs)
      ..sort((a, b) {
        final aId = int.tryParse(a.id) ?? -1;
        final bId = int.tryParse(b.id) ?? -1;
        final byNumericId = bId.compareTo(aId);
        if (byNumericId != 0) return byNumericId;
        return b.id.compareTo(a.id);
      });

    final summaryCard = _ReviewDraftOrderSummaryCard(
      isTablet: isTablet,
      currencyFormat: currencyFormat,
      grossSubtotal: _grossSubtotal,
      itemDiscountsTotal: _itemDiscountsTotal,
      invoiceDiscountTotal: _invoiceDiscountTotal,
      promoDiscountTotal: _promoDiscountTotal,
      netSubtotal: _netSubtotal,
      vatAmount: _vatAmount,
      totalAmount: _totalAmount,
      showFinalReviewHints: isTablet,
    );

    if (isTablet) {
      final mq = MediaQuery.of(context);
      final panelH = (mq.size.height * 0.62).clamp(440.0, 780.0);

      return SizedBox(
        height: panelH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minCardH = constraints.maxHeight;
                  final table = _buildDepartmentsDataTable(
                    sortedJobs,
                    isTablet,
                    currencyFormat,
                    minTableHeight: minCardH,
                  );
                  // No Scrollbar here: always-visible thumb/track looked like an "extra" bar when
                  // filler rows match panel height; table still scrolls when content overflows.
                  return SingleChildScrollView(
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minCardH),
                      child: table,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 336,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _ReviewAssignTechniciansCard(
                      isTablet: isTablet,
                      jobs: sortedJobs,
                      bodyScrollable: true,
                      bodyScrollController: _reviewTechScrollController,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 14),
                  Expanded(
                    flex: 3,
                    child: Scrollbar(
                      controller: _reviewSummaryScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        controller: _reviewSummaryScrollController,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        child: summaryCard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final table = _buildDepartmentsDataTable(sortedJobs, isTablet, currencyFormat);

    final sidePanels = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewAssignTechniciansCard(
          isTablet: isTablet,
          jobs: sortedJobs,
        ),
        SizedBox(height: isTablet ? 12 : 14),
        summaryCard,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 640),
            child: table,
          ),
        ),
        const SizedBox(height: 16),
        sidePanels,
      ],
    );
  }

  static const Color _kReviewTableBorder = Color(0xFFE4E6EB);

  TableBorder _reviewTableBorder() => TableBorder.all(
    color: _kReviewTableBorder,
    width: 1,
  );

  /// Review table cell padding (departments grid).
  EdgeInsets _reviewTablePaddingHeader(bool isTablet) => EdgeInsets.symmetric(
    horizontal: isTablet ? 12 : 8,
    vertical: isTablet ? 11 : 9,
  );

  EdgeInsets _reviewTablePaddingBody(bool isTablet) => EdgeInsets.symmetric(
    horizontal: isTablet ? 12 : 8,
    vertical: isTablet ? 9 : 7,
  );

  /// Department line items only (no technician column).
  Map<int, TableColumnWidth> _reviewDeptColumnWidths() => {
    0: const IntrinsicColumnWidth(flex: 1.1),
    1: const IntrinsicColumnWidth(),
    2: const IntrinsicColumnWidth(flex: 0.55),
    3: const FlexColumnWidth(2.4),
    4: const IntrinsicColumnWidth(),
    5: const IntrinsicColumnWidth(),
  };

  TableCell _reviewHeaderCell(String text, bool isTablet, {TextAlign align = TextAlign.start}) {
    final pad = _reviewTablePaddingHeader(isTablet);
    return TableCell(
      child: Container(
        color: const Color(0xFFF5F6FA),
        padding: pad,
        alignment: _alignmentFor(align),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: isTablet ? 12.5 : 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryLight,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Alignment _alignmentFor(TextAlign a) {
    switch (a) {
      case TextAlign.end:
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }

  TableCell _reviewBodyCell(
      String text,
      bool isTablet, {
        TextAlign align = TextAlign.start,
        FontWeight weight = FontWeight.w500,
        Color? color,
        int maxLines = 4,
      }) {
    final pad = _reviewTablePaddingBody(isTablet);
    return TableCell(
      child: Padding(
        padding: pad,
        child: Align(
          alignment: _alignmentFor(align),
          child: Text(
            text,
            textAlign: align,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTablet ? 13 : 11,
              fontWeight: weight,
              color: color ?? const Color(0xFF1E2124),
            ),
          ),
        ),
      ),
    );
  }

  /// Empty rows so [Table] grid lines extend to [minTableHeight] (tablet Final Review).
  static const int _kMaxReviewFillerRows = 120;

  int _reviewFillerRowCount({
    required int tableRowCount,
    required double minViewportHeight,
    required bool isTablet,
  }) {
    final perRow = isTablet ? 39.0 : 33.0;
    final estimated = tableRowCount * perRow;
    if (estimated >= minViewportHeight) return 0;
    final gap = minViewportHeight - estimated;
    final n = (gap / perRow).ceil();
    return n.clamp(0, _kMaxReviewFillerRows);
  }

  Widget _buildDepartmentsDataTable(
      List<PosOrderJob> jobs,
      bool isTablet,
      NumberFormat currencyFormat, {
        double? minTableHeight,
      }) {
    final rows = <TableRow>[
      TableRow(
        children: [
          _reviewHeaderCell(AppLocalizations.of(context)!.posReviewDepartmentCol, isTablet),
          _reviewHeaderCell('Job ID', isTablet),
          _reviewHeaderCell('Status', isTablet),
          _reviewHeaderCell('Product / Service', isTablet),
          _reviewHeaderCell('Qty', isTablet, align: TextAlign.end),
          _reviewHeaderCell(AppLocalizations.of(context)!.posReviewAmountSar, isTablet, align: TextAlign.end),
        ],
      ),
    ];

    for (final job in jobs) {
      final items = job.items;
      if (items.isEmpty) {
        rows.add(TableRow(
          children: [
            _reviewBodyCell(job.department, isTablet, weight: FontWeight.w700),
            _reviewBodyCell(job.id, isTablet),
            _reviewBodyCell(job.status.toUpperCase(), isTablet, maxLines: 2),
            _reviewBodyCell(AppLocalizations.of(context)!.posReviewNoLineItems, isTablet, color: Colors.grey.shade500),
            _reviewBodyCell('—', isTablet, align: TextAlign.end),
            _reviewBodyCell('—', isTablet, align: TextAlign.end),
          ],
        ));
      } else {
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final qtyStr = item.qty % 1 == 0
              ? item.qty.toInt().toString()
              : item.qty.toStringAsFixed(1);
          rows.add(TableRow(
            children: [
              _reviewBodyCell(i == 0 ? job.department : '', isTablet,
                  weight: i == 0 ? FontWeight.w800 : FontWeight.w500),
              _reviewBodyCell(i == 0 ? job.id : '', isTablet),
              _reviewBodyCell(i == 0 ? job.status.toUpperCase() : '', isTablet, maxLines: 2),
              _reviewBodyCell(
                _reviewProductNameForLocale(
                  context,
                  productName: item.productName,
                  productNameArabic: item.productNameArabic,
                  fallback: item.productId,
                ),
                isTablet,
                weight: FontWeight.w600,
              ),
              _reviewBodyCell(qtyStr, isTablet, align: TextAlign.end),
              _reviewBodyCell(item.lineTotal.toStringAsFixed(2), isTablet,
                  align: TextAlign.end, weight: FontWeight.w800),
            ],
          ));
        }
      }

      if (job.items.isNotEmpty) {
        final jobSubtotalExclusive = job.amountBeforeDiscount > 0
            ? job.amountBeforeDiscount
            : job.items.fold(0.0, (sum, i) {
          final exclVat = (i.unitPrice / 1.15 * 100).roundToDouble() / 100;
          return sum + exclVat * i.qty;
        });
        final postItemDiscountJobTotal = job.amountAfterDiscount > 0
            ? job.amountAfterDiscount
            : job.items.fold(0.0, (sum, i) => sum + i.lineTotal);
        final itemDisc = jobSubtotalExclusive - postItemDiscountJobTotal;
        final jobTotal = job.totalAmount > 0 ? job.totalAmount : postItemDiscountJobTotal;
        final jobVatAmount = job.vatAmount > 0
            ? job.vatAmount
            : job.amountAfterPromo > 0
            ? job.amountAfterPromo * 0.15
            : jobTotal - (jobTotal / (1 + _vatRate));

        rows.add(TableRow(
          decoration: const BoxDecoration(color: Color(0xFFFAFAFC)),
          children: [
            _reviewBodyCell('', isTablet),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell(AppLocalizations.of(context)!.posReviewGrossExclVat, isTablet, weight: FontWeight.w700),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell(jobSubtotalExclusive.toStringAsFixed(2), isTablet,
                align: TextAlign.end, weight: FontWeight.w700),
          ],
        ));
        if (itemDisc > 0.009) {
          rows.add(TableRow(
            decoration: const BoxDecoration(color: Color(0xFFFAFAFC)),
            children: [
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('Item / line discounts', isTablet, weight: FontWeight.w600),
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('- ${itemDisc.toStringAsFixed(2)}', isTablet,
                  align: TextAlign.end,
                  weight: FontWeight.w700,
                  color: Colors.green.shade700),
            ],
          ));
        }
        rows.add(TableRow(
          decoration: const BoxDecoration(color: Color(0xFFFAFAFC)),
          children: [
            _reviewBodyCell('', isTablet),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell(AppLocalizations.of(context)!.posReviewVatPct((_vatRate * 100).toStringAsFixed(0)), isTablet, weight: FontWeight.w700),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell(jobVatAmount.toStringAsFixed(2), isTablet,
                align: TextAlign.end, weight: FontWeight.w700),
          ],
        ));
        rows.add(TableRow(
          decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.12)),
          children: [
            _reviewBodyCell('', isTablet),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell(AppLocalizations.of(context)!.posReviewDepartmentTotal, isTablet, weight: FontWeight.w900),
            _reviewBodyCell('', isTablet),
            _reviewBodyCell(currencyFormat.format(jobTotal), isTablet,
                align: TextAlign.end,
                weight: FontWeight.w900,
                color: AppColors.secondaryLight),
          ],
        ));
      }
    }

    final minH = minTableHeight;
    if (minH != null && minH > 0) {
      final extra = _reviewFillerRowCount(
        tableRowCount: rows.length,
        minViewportHeight: minH,
        isTablet: isTablet,
      );
      // One fewer filler row so the table does not show an extra blank line at the bottom.
      final fillCount = extra > 0 ? extra - 1 : 0;
      for (var i = 0; i < fillCount; i++) {
        rows.add(
          TableRow(
            children: [
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('', isTablet),
              _reviewBodyCell('', isTablet, align: TextAlign.end),
              _reviewBodyCell('', isTablet, align: TextAlign.end),
            ],
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: _reviewDeptColumnWidths(),
          defaultColumnWidth: const FlexColumnWidth(1),
          border: _reviewTableBorder(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor = Colors.grey.shade200;
    Color textColor = Colors.grey.shade800;

    String lowerStatus = status.toLowerCase();
    if (lowerStatus == 'completed' || lowerStatus.contains('invoiced')) {
      bgColor = Colors.green.withOpacity(0.15);
      textColor = Colors.green.shade700;
    } else if (lowerStatus.contains('pending')) {
      bgColor = Colors.orange.withOpacity(0.15);
      textColor = Colors.orange.shade800;
    } else if (lowerStatus.contains('progress')) {
      bgColor = Colors.blue.withOpacity(0.15);
      textColor = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final currencyFormat = NumberFormat('#,##0.00');

    return PopScope(
      canPop: !_isGenerated || _canExit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: PosScreenAppBar(
          title: _isGenerated ? AppLocalizations.of(context)!.posReviewInvoiceReady : AppLocalizations.of(context)!.posReviewFinalReview,
          showBackButton: true,
          showHamburger: false,
        ),
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: PosTabletLayout.textScaler(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: isTablet ? 20 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Card ──────────────────────────────────────────────────
                _OrderHeaderCard(order: widget.order, isTablet: isTablet),
                const SizedBox(height: 16),

                if (_isGenerated) ...[
                  // ── Success State ─────────────────────────────────────────────
                  _GeneratedSuccessCard(
                    invoiceNo: _currentInvoice?.invoiceNo ?? 'INV-READY',
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  _CommissionsCard(
                    commissions: _commissions,
                    currencyFormat: currencyFormat,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 24),
                  _PrintButton(onTap: () => _showPrintDialog()),
                  const SizedBox(height: 20),
                ] else ...[
                  // ── Department Jobs List ──────────────────────────────────────
                  _buildDepartmentJobs(isTablet, currencyFormat),
                  const SizedBox(height: 16),

                  // ── Corporate + Payment (tablet: same row when individual) ───
                  if (isTablet) ...[
                    if (_isCorporate == false)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SectionCard(
                              title: AppLocalizations.of(context)!.posPaymentCorporate,
                              icon: Icons.business_rounded,
                              child: _CorporatePrompt(
                                isCorporate: _isCorporate,
                                onChanged: _onCorporateCustomerChanged,
                              ),
                            ),
                          ),
                          if (!_isBranchEmployeeRetailWalkIn) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SectionCard(
                                title: AppLocalizations.of(context)!.posPaymentMethodTitleSplit,
                                icon: Icons.payment_rounded,
                                child: _PaymentMethodSelector(
                                  selected: _selectedPayments,
                                  onChanged: _onRetailPaymentMethodsChanged,
                                  isTablet: isTablet,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_isCorporate == true)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SectionCard(
                              title: AppLocalizations.of(context)!.posPaymentCorporate,
                              icon: Icons.business_rounded,
                              child: _CorporatePrompt(
                                isCorporate: _isCorporate,
                                onChanged: _onCorporateCustomerChanged,
                              ),
                            ),
                          ),
                          if (!_isBranchEmployeeRetailWalkIn) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SectionCard(
                                title: AppLocalizations.of(context)!.posPaymentMethodTitle,
                                icon: Icons.payment_rounded,
                                child: _PaymentMethodSelector(
                                  selected: _selectedPayments,
                                  onChanged: (pms) => setState(() => _selectedPayments = pms),
                                  isTablet: isTablet,
                                  corporateMonthlyOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      _SectionCard(
                        title: AppLocalizations.of(context)!.posPaymentCorporate,
                        icon: Icons.business_rounded,
                        child: _CorporatePrompt(
                          isCorporate: _isCorporate,
                          onChanged: _onCorporateCustomerChanged,
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_isCorporate == false &&
                        !_isBranchEmployeeRetailWalkIn &&
                        _selectedPayments.length >= 2) ...[
                      _buildInlineSplitPaymentCard(),
                      const SizedBox(height: 16),
                    ],
                  ] else ...[
                    _SectionCard(
                      title: AppLocalizations.of(context)!.posPaymentCorporate,
                      icon: Icons.business_rounded,
                      child: _CorporatePrompt(
                        isCorporate: _isCorporate,
                        onChanged: _onCorporateCustomerChanged,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isCorporate == false) ...[
                      if (!_isBranchEmployeeRetailWalkIn) ...[
                        _SectionCard(
                          title: AppLocalizations.of(context)!.posPaymentMethodTitleSplit,
                          icon: Icons.payment_rounded,
                          child: _PaymentMethodSelector(
                            selected: _selectedPayments,
                            onChanged: _onRetailPaymentMethodsChanged,
                            isTablet: isTablet,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedPayments.length >= 2) ...[
                          _buildInlineSplitPaymentCard(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ],
                    if (_isCorporate == true &&
                        !_isBranchEmployeeRetailWalkIn) ...[
                      _SectionCard(
                        title: AppLocalizations.of(context)!.posPaymentMethodTitle,
                        icon: Icons.payment_rounded,
                        child: _PaymentMethodSelector(
                          selected: _selectedPayments,
                          onChanged: (pms) => setState(() => _selectedPayments = pms),
                          isTablet: isTablet,
                          corporateMonthlyOnly: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  ListenableBuilder(
                    listenable: SoftPosAccessService.instance,
                    builder: (context, _) {
                      if (!isSoftPosUiEnabled ||
                          _isBranchEmployeeRetailWalkIn) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildSoftPosBridgeSettingsRow(),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),

                  // ── Inline Billing + Vehicle Form (walk-in) ──────────────────
                  if (_isStandardWalkInOrder(widget.order)) ...[
                    _buildInlineBillingForm(),
                    const SizedBox(height: 16),
                  ],

                  _buildMaintenanceChecklistGate(isTablet),
                  const SizedBox(height: 12),

                  // ── Generate Invoice Button ───────────────────────────────────
                  _GenerateInvoiceButton(
                    onTap: _generateInvoice,
                    isLoading: _isLoading,
                    enabled: widget.order.meetsCashierInvoicePrerequisites &&
                        (!widget.order.isCorporateWalkIn ||
                            widget.order.isCorporateApproved ||
                            widget.order.isCorporateBookingOrder),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Matches [InvoiceDialog] payment hint (corporate / split / single method).
  String? _requestedPaymentLabelForInvoice() {
    if (_isBranchEmployeeRetailWalkIn && _isCorporate == false) {
      final n = _inlineBillingEmployeePickSelection?.name.trim();
      if (n != null && n.isNotEmpty) return 'Employees — $n';
      return 'Employees';
    }
    if (_isCorporate == true) {
      if (_selectedPayments.isEmpty) return AppLocalizations.of(context)!.posPaymentCorporate;
      return AppLocalizations.of(context)!.posReviewCorporatePayment(_selectedPayments.first.label);
    }
    if (_selectedPayments.length > 1) {
      return 'Split (${_selectedPayments.map((p) => p.label).join(' + ')})';
    }
    if (_selectedPayments.length == 1) return _selectedPayments.first.label;
    return null;
  }

  void _showPrintDialog() {
    if (_currentInvoice == null) {
      ToastService.showError(context, AppLocalizations.of(context)!.posReviewInvoiceCouldNotLoad);
      return;
    }

    showInvoiceDialogAfterPrintPrefetch(
      context: context,
      invoice: invoiceWithMergedCustomerTax(
        _currentInvoice!,
        widget.order.customer?.vatNumber,
      ),
      paymentMethodText: invoiceDialogPaymentMethodText(
        _currentInvoice!,
        requestedPaymentMethod: _requestedPaymentLabelForInvoice(),
      ),
      maintenanceChecksFallback: widget.order.maintenanceChecks,
      builder: (context) => InvoiceDialog(
        invoice: invoiceWithMergedCustomerTax(
          _currentInvoice!,
          widget.order.customer?.vatNumber,
        ),
        maintenanceChecksFallback: widget.order.maintenanceChecks,
        requestedPaymentMethod: _requestedPaymentLabelForInvoice(),
        onDone: () {
          setState(() {
            _canExit = true;
          });
          // Note: InvoiceDialog already calls Navigator.pop(ctx) internally before trigger onDone!
          Future.delayed(Duration.zero, () {
            if (context.mounted) Navigator.pop(context); // Exit the view
          });
        },
      ),
    );
  }
}

// ── Sub Widgets ───────────────────────────────────────────────────────────────

class _OrderHeaderCard extends StatelessWidget {
  final PosOrder order;
  final bool isTablet;
  const _OrderHeaderCard({required this.order, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.plateNumber.isNotEmpty
                      ? _reviewPlateDisplay(context, order.plateNumber)
                      : '—',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 21 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                      () {
                    final m = order.carModel.trim();
                    final c = order.customerName;
                    if (c.isNotEmpty) {
                      return m.isEmpty ? c : '$c  •  $m';
                    }
                    return m;
                  }(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Order #${order.id}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ReviewLineItem item;
  final NumberFormat currencyFormat;
  final bool isTablet;
  const _ItemRow({
    required this.item,
    required this.currencyFormat,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final fs = isTablet ? 12.0 : 11.0;
    final labelStyle = TextStyle(fontSize: fs, color: Colors.grey.shade500);
    final valStyle = TextStyle(fontSize: fs, fontWeight: FontWeight.w600, color: const Color(0xFF1E2124));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: isTablet ? 15 : 14, color: const Color(0xFF1E2124)),
                ),
              ),
              Text(
                'SAR ${currencyFormat.format(item.totalWithVat)}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: isTablet ? 15 : 14, color: AppColors.secondaryLight),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: Text(AppLocalizations.of(context)!.posReviewUnitExclVat, style: labelStyle)),
                  Text(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(item.unitPriceExclVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode)), style: valStyle),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(child: Text(AppLocalizations.of(context)!.posCommonQty, style: labelStyle)),
                  Text('${item.qty}', style: valStyle),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(child: Text(AppLocalizations.of(context)!.posReviewGrossBeforeVat, style: labelStyle)),
                  Text(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(item.grossBeforeVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode)), style: valStyle),
                ]),
                if (item.discountAmount > 0) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(child: Text(AppLocalizations.of(context)!.posProductLineDiscount, style: labelStyle)),
                    Text('- \${AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(item.discountAmount.toStringAsFixed(2), Localizations.localeOf(context).languageCode))}', style: valStyle.copyWith(color: Colors.green)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(child: Text(AppLocalizations.of(context)!.posReviewTotalBeforeVat, style: labelStyle)),
                    Text(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(item.totalBeforeVat.toStringAsFixed(2), Localizations.localeOf(context).languageCode)), style: valStyle),
                  ]),
                ],
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(child: Text(AppLocalizations.of(context)!.posReviewVat15, style: labelStyle)),
                  Text(AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(item.vatOnLine.toStringAsFixed(2), Localizations.localeOf(context).languageCode)), style: valStyle),
                ]),
                if (item.technicianName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(child: Text(AppLocalizations.of(context)!.posCommonTech, style: labelStyle)),
                    Text(item.technicianName, style: valStyle),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VatBreakdownWidget extends StatelessWidget {
  final double subtotalExclusive;
  final double vatAmount;
  final double vatRate;
  final double itemDiscountAmount;
  final double globalDiscountValue;
  final String? globalDiscountType;
  final double promoDiscountAmount;
  final double promoDiscountValue;
  final String? promoDiscountType;
  final String? promoCode;
  final double total;
  final NumberFormat currencyFormat;
  final bool isTablet;
  final bool showDetailedBreakdown;

  const _VatBreakdownWidget({
    required this.subtotalExclusive,
    required this.vatAmount,
    required this.vatRate,
    this.itemDiscountAmount = 0.0,
    this.globalDiscountValue = 0.0,
    this.globalDiscountType,
    this.promoDiscountAmount = 0.0,
    this.promoDiscountValue = 0.0,
    this.promoDiscountType,
    this.promoCode,
    required this.total,
    required this.currencyFormat,
    required this.isTablet,
    this.showDetailedBreakdown = true,
  });

  @override
  Widget build(BuildContext context) {
    // Math checks
    final double netSubtotal = subtotalExclusive - itemDiscountAmount;

    final double computedGlobalDiscountAmount =
    (globalDiscountType == 'percent')
        ? (netSubtotal * globalDiscountValue / 100)
        : globalDiscountValue;

    final double priceAfterGlobal = netSubtotal - computedGlobalDiscountAmount;

    final bool isPromoPercent =
        promoDiscountType?.toLowerCase() == 'percent' ||
            promoDiscountType?.toLowerCase() == 'percentage';
    final double computedPromoAmount = isPromoPercent
        ? (priceAfterGlobal * promoDiscountValue / 100)
        : (promoDiscountAmount > 0 ? promoDiscountAmount : promoDiscountValue);

    final double priceAfterPromo = priceAfterGlobal - computedPromoAmount;

    // Calculate Native Tax and Total
    final double computedTaxAmount = priceAfterPromo * vatRate;
    final double computedTotalAmount = priceAfterPromo + computedTaxAmount;

    return Column(
      children: [
        if (showDetailedBreakdown) ...[
          _PriceRow(
            label: AppLocalizations.of(context)!.posReviewGrossAmountExclVat,
            value: 'SAR ${currencyFormat.format(subtotalExclusive)}',
            valueColor: const Color(0xFF1E2124),
          ),
          const SizedBox(height: 8),

          if (itemDiscountAmount > 0) ...[
            _PriceRow(
              label: AppLocalizations.of(context)!.posReviewItemDiscounts,
              value: '-SAR ${currencyFormat.format(itemDiscountAmount)}',
              valueColor: Colors.green.shade600,
              labelColor: Colors.green.shade600,
            ),
            const SizedBox(height: 8),
          ],

          if (computedGlobalDiscountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E2124)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        globalDiscountValue % 1 == 0
                            ? globalDiscountValue.toInt().toString()
                            : globalDiscountValue.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        globalDiscountType == 'percent' ? '%' : 'SAR',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PriceRow(
              label: AppLocalizations.of(context)!.posReviewPriceAfterDiscount,
              value: 'SAR ${currencyFormat.format(priceAfterGlobal)}',
            ),
            const SizedBox(height: 8),
          ],

          if (computedPromoAmount > 0) ...[
            _PriceRow(
              label: promoCode != null && promoCode!.isNotEmpty
                  ? 'Promo Discount ($promoCode)'
                  : 'Promo Discount',
              value: '-SAR ${currencyFormat.format(computedPromoAmount)}',
              valueColor: Colors.green.shade600,
              labelColor: Colors.green.shade600,
            ),
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Price after promo',
              value: 'SAR ${currencyFormat.format(priceAfterPromo)}',
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 1, color: Color(0xFFF0F0F5)),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Tax (${(vatRate * 100).toStringAsFixed(0)}%)',
            value: 'SAR ${currencyFormat.format(computedTaxAmount)}',
            valueColor: Colors.grey.shade400,
            labelColor: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.posReviewTotalAmount,
                style: TextStyle(
                  fontSize: isTablet ? 17 : 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E2124),
                ),
              ),
              Text(
                'SAR ${currencyFormat.format(computedTotalAmount)}',
                style: TextStyle(
                  fontSize: isTablet ? 19 : 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E2124),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? labelColor;
  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: labelColor ?? Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF1E2124),
          ),
        ),
      ],
    );
  }
}

class _CommissionDisplayEntry {
  final String technicianName;
  final String departmentName;
  final double commissionAmount;
  final double commissionPercent;

  const _CommissionDisplayEntry({
    required this.technicianName,
    required this.departmentName,
    required this.commissionAmount,
    required this.commissionPercent,
  });
}

class _CommissionsWidget extends StatelessWidget {
  final List<_CommissionDisplayEntry> commissions;
  final NumberFormat currencyFormat;
  final bool isTablet;
  const _CommissionsWidget({
    required this.commissions,
    required this.currencyFormat,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (commissions.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.posOrdersNoTechnicianCommissions,
        style: TextStyle(color: Colors.grey),
      );
    }
    return Column(
      children: commissions.map((e) {
        final initial = e.technicianName.isNotEmpty
            ? e.technicianName[0].toUpperCase()
            : '?';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.technicianName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 14 : 13,
                      ),
                    ),
                    if (e.departmentName.isNotEmpty)
                      Text(
                        e.departmentName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isTablet ? 12 : 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SAR ${currencyFormat.format(e.commissionAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CorporatePrompt extends StatelessWidget {
  final bool? isCorporate;
  final ValueChanged<bool?> onChanged;
  const _CorporatePrompt({required this.isCorporate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Is this a corporate customer?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2124),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _ChoiceChip(
              label: 'Yes — Corporate',
              icon: Icons.business_rounded,
              selected: isCorporate == true,
              onTap: () => onChanged(true),
              accentColor: AppColors.secondaryLight,
            ),
            const SizedBox(width: 12),
            _ChoiceChip(
              label: 'No — Individual',
              icon: Icons.person_rounded,
              selected: isCorporate == false,
              onTap: () => onChanged(false),
              accentColor: AppColors.secondaryLight,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accentColor : const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accentColor : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final Set<PaymentMethod> selected;
  final ValueChanged<Set<PaymentMethod>> onChanged;
  final bool isTablet;
  /// Corporate invoice: five tappable methods (monthly billing, cash, card, bank, wallet).
  final bool corporateMonthlyOnly;
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
    required this.isTablet,
    this.corporateMonthlyOnly = false,
  });

  Widget _methodChip(
    PaymentMethod pm, {
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDisabled
            ? const Color(0xFFF8FAFC)
            : isSelected
                ? AppColors.primaryLight
                : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDisabled
              ? Colors.grey.shade200
              : isSelected
                  ? AppColors.primaryLight
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pm.icon,
            size: 16,
            color: isDisabled
                ? Colors.grey.shade300
                : isSelected
                    ? Colors.black
                    : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            pm.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDisabled
                  ? Colors.grey.shade400
                  : isSelected
                      ? Colors.black
                      : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (corporateMonthlyOnly) {
      return ListenableBuilder(
        listenable: SoftPosAccessService.instance,
        builder: (context, _) {
          final corporateMethods = <PaymentMethod>[
            PaymentMethod.monthlyBilling,
            PaymentMethod.bankTransfer,
            PaymentMethod.cash,
            PaymentMethod.card,
            if (isSoftPosUiEnabled) PaymentMethod.tapToPay,
            PaymentMethod.wallet,
          ].where(isPosPaymentMethodUiEnabled).toList();
          final blocked = selected
              .where((pm) => !isPosPaymentMethodUiEnabled(pm))
              .toList();
          if (blocked.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final next = Set<PaymentMethod>.of(selected)
                ..removeAll(blocked);
              onChanged(next);
            });
          }
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: corporateMethods.map((pm) {
              final isSelected = selected.contains(pm);
              return GestureDetector(
                onTap: () => onChanged({pm}),
                child: _methodChip(
                  pm,
                  isSelected: isSelected,
                  isDisabled: false,
                ),
              );
            }).toList(),
          );
        },
      );
    }

    return ListenableBuilder(
      listenable: SoftPosAccessService.instance,
      builder: (context, _) {
        final blocked = selected
            .where((pm) => !isPosPaymentMethodUiEnabled(pm))
            .toList();
        if (blocked.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final next = Set<PaymentMethod>.of(selected)..removeAll(blocked);
            onChanged(next);
          });
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PaymentMethod.values
              .where((pm) =>
                  pm.isRetailSelectable && isPosPaymentMethodUiEnabled(pm))
              .map((pm) {
            final isSelected = selected.contains(pm);
            return GestureDetector(
              onTap: () {
                final newSelection = Set.of(selected);
                if (isSelected) {
                  newSelection.remove(pm);
                } else {
                  newSelection.add(pm);
                }
                onChanged(newSelection);
              },
              child: _methodChip(
                pm,
                isSelected: isSelected,
                isDisabled: false,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _GenerateInvoiceButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;
  const _GenerateInvoiceButton({
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Always tappable (unless loading) — the handler surfaces a specific toast
    // explaining why invoicing is blocked, so the disabled-grey button never
    // becomes a silent no-op.
    final canTap = !isLoading;
    final activeStyle = enabled;
    final activeBg =
        activeStyle ? AppColors.primaryLight : const Color(0xFFCBD5E1);
    final activeFg = activeStyle ? Colors.black : const Color(0xFF64748B);
    return ElevatedButton.icon(
      onPressed: canTap ? onTap : null,
      icon: isLoading
          ? const SizedBox.shrink()
          : Icon(
        Icons.auto_awesome_rounded,
        size: 18,
        color: activeFg,
      ),
      label: isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.black,
        ),
      )
          : Text(
        AppLocalizations.of(context)!.posOrdersGenerateInvoice,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: activeFg,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: activeBg,
        foregroundColor: activeFg,
        disabledBackgroundColor: activeBg,
        disabledForegroundColor: activeFg,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _GeneratedSuccessCard extends StatelessWidget {
  final String invoiceNo;
  final bool isTablet;
  const _GeneratedSuccessCard({
    required this.invoiceNo,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: isTablet ? 56 : 44,
            height: isTablet ? 56 : 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.black,
              size: isTablet ? 30 : 22,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 10),
          Text(
            AppLocalizations.of(context)!.posReviewInvoiceGeneratedLocked,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            invoiceNo,
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isTablet ? 14 : 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.posOrdersNoFurtherEditsAllowed,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Commissions have been credited to technician accounts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CommissionsCard extends StatelessWidget {
  final List<_CommissionDisplayEntry> commissions;
  final NumberFormat currencyFormat;
  final bool isTablet;
  const _CommissionsCard({
    required this.commissions,
    required this.currencyFormat,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Commissions Credited',
      icon: Icons.verified_rounded,
      child: _CommissionsWidget(
        commissions: commissions,
        currencyFormat: currencyFormat,
        isTablet: isTablet,
      ),
    );
  }
}

class _PrintButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PrintButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.print_rounded, size: 18),
      label: Text(
        AppLocalizations.of(context)!.posOrdersPrintInvoiceReceipt,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryLight,
        side: BorderSide(color: AppColors.secondaryLight, width: 1.5),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Mock Print Dialog ───────────────────────────────────────────────────

class _MockInvoicePrintDialog extends StatelessWidget {
  final PosOrder order;
  final List<ReviewLineItem> items;
  final String invoiceNo;
  final double total;
  final double vatAmount;
  final double discountAmount;
  final bool isCorporate;
  final PaymentMethod? paymentMethod;
  final List<_CommissionDisplayEntry> commissions;
  final VoidCallback onDone;

  const _MockInvoicePrintDialog({
    required this.order,
    required this.items,
    required this.invoiceNo,
    required this.total,
    required this.vatAmount,
    required this.discountAmount,
    required this.isCorporate,
    required this.paymentMethod,
    required this.commissions,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TAX INVOICE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoiceNo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Customer / vehicle (plate prominent)
              _DialogRow(
                label: AppLocalizations.of(context)!.posReviewVehicleNoLabel,
                value: order.plateNumber.isNotEmpty
                    ? _reviewPlateDisplay(context, order.plateNumber)
                    : '—',
              ),
              _DialogRow(label: AppLocalizations.of(context)!.posReviewCustomerLabel, value: order.customerName),
              _DialogRow(label: AppLocalizations.of(context)!.posReviewVehicle, value: order.carModel),
              _DialogRow(
                label: AppLocalizations.of(context)!.posReviewBilling,
                value: isCorporate
                    ? 'Corporate (Monthly)'
                    : paymentMethod?.label ?? '—',
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Items
              const Text(
                'SERVICES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              ...(() {
                final Map<String, List<ReviewLineItem>> groupedItems = {};
                for (var item in items) {
                  final deptName =
                  item.technicianName.isEmpty ||
                      item.technicianName == AppLocalizations.of(context)!.posReviewTechnicianFallback
                      ? 'General Services'
                      : item.technicianName;
                  groupedItems.putIfAbsent(deptName, () => []).add(item);
                }

                final List<Widget> serviceWidgets = [];
                groupedItems.forEach((dept, deptItems) {
                  // Department Header
                  serviceWidgets.add(
                    Container(
                      margin: const EdgeInsets.only(bottom: 8, top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.label_important_rounded,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dept.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade800,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  // Department Items
                  for (var item in deptItems) {
                    serviceWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                          left: 4,
                          right: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.qty}x  ${item.name}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              'SAR ${currencyFormat.format(item.lineTotal)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  serviceWidgets.add(const SizedBox(height: 4));
                });
                return serviceWidgets;
              })(),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _DialogRow(
                label: 'Subtotal',
                value:
                'SAR ${currencyFormat.format(total - vatAmount + discountAmount)}',
              ),
              _DialogRow(
                label: AppLocalizations.of(context)!.posReviewVat15,
                value: 'SAR ${currencyFormat.format(vatAmount)}',
              ),
              if (discountAmount > 0)
                _DialogRow(
                  label: 'Discount',
                  value: '- SAR ${currencyFormat.format(discountAmount)}',
                ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.posReviewTotal,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'SAR ${currencyFormat.format(total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDone,
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.black,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.posReviewDone,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draft-style order totals beside the final-review table (`pos_orders_view` DRAFT TOTALS).
class _ReviewDraftOrderSummaryCard extends StatelessWidget {
  final bool isTablet;
  final NumberFormat currencyFormat;
  final double grossSubtotal;
  final double itemDiscountsTotal;
  final double invoiceDiscountTotal;
  final double promoDiscountTotal;
  final double netSubtotal;
  final double vatAmount;
  final double totalAmount;
  /// Extra hint lines + spacing (tablet Final Review right column).
  final bool showFinalReviewHints;

  const _ReviewDraftOrderSummaryCard({
    required this.isTablet,
    required this.currencyFormat,
    required this.grossSubtotal,
    required this.itemDiscountsTotal,
    required this.invoiceDiscountTotal,
    required this.promoDiscountTotal,
    required this.netSubtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.showFinalReviewHints = false,
  });

  static const _border = Color(0xFFE8ECF3);

  @override
  Widget build(BuildContext context) {
    final pad = EdgeInsets.all(isTablet ? 18.0 : 16.0);
    final labelStyle = TextStyle(
      fontSize: isTablet ? 13.0 : 12.0,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );
    final valueStyle = TextStyle(
      fontSize: isTablet ? 13.0 : 12.0,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1E2124),
    );

    Widget line(String label, String value, {bool negative = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(
              value,
              style: valueStyle.copyWith(
                color: negative ? Colors.red.shade700 : const Color(0xFF1E2124),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.posReviewOrderSummary,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          line(AppLocalizations.of(context)!.posReviewGrossAmountExclVat, grossSubtotal.toStringAsFixed(2)),
          if (itemDiscountsTotal > 0.001)
            line(AppLocalizations.of(context)!.posReviewItemDiscounts, '- ${itemDiscountsTotal.toStringAsFixed(2)}', negative: true),
          if (invoiceDiscountTotal > 0.001)
            line(AppLocalizations.of(context)!.posReviewInvoiceDiscount, '- ${invoiceDiscountTotal.toStringAsFixed(2)}', negative: true),
          if (promoDiscountTotal > 0.001)
            line(
              AppLocalizations.of(context)!.posReviewPromoDiscountNoCode,
              '- ${promoDiscountTotal.toStringAsFixed(2)}',
              negative: true,
            ),
          line(AppLocalizations.of(context)!.posOrdersTotalBeforeVat, netSubtotal.toStringAsFixed(2)),
          line(AppLocalizations.of(context)!.posReviewVat15, vatAmount.toStringAsFixed(2)),
          if (showFinalReviewHints) ...[
            const SizedBox(height: 10),
            Text(
              'Line totals are net of item-level discounts.',
              style: TextStyle(
                fontSize: isTablet ? 11.5 : 11,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.posReviewDiscountsApplyTaxableSubtotal,
              style: TextStyle(
                fontSize: isTablet ? 11.5 : 11,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.posOrdersGenerateInvoice,
              style: TextStyle(
                fontSize: isTablet ? 11.5 : 11,
                color: Colors.grey.shade500,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
          ],
          const Divider(height: 20, thickness: 1, color: _border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.posReviewTotal,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.posCommonSarAmount(AppTranslationService.localizeDigitsForLanguage(currencyFormat.format(totalAmount), Localizations.localeOf(context).languageCode)),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Department-wise assigned technicians (active assignments only).
class _ReviewAssignTechniciansCard extends StatelessWidget {
  final bool isTablet;
  final List<PosOrderJob> jobs;
  /// When true, the list scrolls inside a fixed-height parent (tablet split row).
  final bool bodyScrollable;
  final ScrollController? bodyScrollController;

  const _ReviewAssignTechniciansCard({
    required this.isTablet,
    required this.jobs,
    this.bodyScrollable = false,
    this.bodyScrollController,
  });

  static const _border = Color(0xFFE8ECF3);

  /// Preview commission for review. API often returns `0` until completion/invoice; mirror
  /// [_commissions] fallback so reassigned techs don’t show SAR 0.00 before invoice.
  String _commissionLabel(BuildContext context, JobTechnician tech, PosOrderJob job) {
    double amount = tech.commissionAmount;
    double percent = tech.commissionPercent;
    if (amount <= 0) {
      final rate = percent > 0 ? percent / 100.0 : 0.10;
      amount = job.totalAmount * rate;
      if (percent <= 0) percent = 10.0;
    }
    final langCode = Localizations.localeOf(context).languageCode;
    final sarPart = AppLocalizations.of(context)!.posCommonSarAmount(
        AppTranslationService.localizeDigitsForLanguage(amount.toStringAsFixed(2), langCode));
    final pctPart = percent > 0 ? ' (${percent.toStringAsFixed(0)}%)' : '';
    return '$sarPart$pctPart';
  }

  List<Widget> _jobBlocks({
    required BuildContext context,
    required TextStyle deptStyle,
    required TextStyle jobIdStyle,
    required TextStyle nameStyle,
    required TextStyle commStyle,
  }) {
    final list = <Widget>[];
    for (var i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final techs = job.distinctActiveTechnicians;
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedApiText(
                job.department,
                uppercase: Localizations.localeOf(context).languageCode != 'ar',
                style: deptStyle,
              ),
              Text('Job #${job.id}', style: jobIdStyle),
              const SizedBox(height: 8),
              if (techs.isEmpty)
                Text(
                  AppLocalizations.of(context)!.posOrdersNoTechnicianAssigned,
                  style: TextStyle(
                    fontSize: isTablet ? 12.5 : 11.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
                )
              else
                ...techs.map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.engineering_outlined,
                          size: isTablet ? 20 : 18,
                          color: AppColors.secondaryLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedApiText(t.name, style: nameStyle),
                              Text(
                                AppLocalizations.of(context)!.posReviewCommissionLabel(_commissionLabel(context, t, job)),
                                style: commStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      if (i < jobs.length - 1) {
        list.add(Divider(height: 1, thickness: 1, color: Colors.grey.shade200));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final pad = EdgeInsets.all(isTablet ? 18.0 : 16.0);
    final deptStyle = TextStyle(
      fontSize: isTablet ? 14 : 13,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1E2124),
    );
    final jobIdStyle = TextStyle(
      fontSize: isTablet ? 11.5 : 10.5,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );
    final nameStyle = TextStyle(
      fontSize: isTablet ? 13 : 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1E2124),
    );
    final commStyle = TextStyle(
      fontSize: isTablet ? 11.5 : 10.5,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade700,
    );

    final header = Text(
      AppLocalizations.of(context)!.posOrdersAssignedTechnicians,
      style: TextStyle(
        fontSize: isTablet ? 13 : 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: const Color(0xFF64748B),
      ),
    );

    final blocks = _jobBlocks(
      context: context,
      deptStyle: deptStyle,
      jobIdStyle: jobIdStyle,
      nameStyle: nameStyle,
      commStyle: commStyle,
    );

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 14),
          if (bodyScrollable)
            Expanded(
              child: bodyScrollController != null
                  ? Scrollbar(
                controller: bodyScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 6,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  controller: bodyScrollController,
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...blocks,
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              )
                  : SingleChildScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: blocks,
                ),
              ),
            )
          else
            ...blocks,
        ],
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  const _DialogRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}