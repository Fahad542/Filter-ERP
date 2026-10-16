import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/gcc_plate.dart';
import '../../../widgets/gcc_plate_field.dart';
import '../../../utils/plate_transliterator.dart';
import '../../../utils/app_keyboard_locale.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../models/customer_search_model.dart';
import '../../../models/cashier_corporate_accounts_api_model.dart';
import '../../../models/cashier_expense_models.dart';
// import '../../Department/pos_department_view.dart';
import 'package:provider/provider.dart';
import '../Department/pos_department_view.dart';
import '../Home Screen/pos_view_model.dart';
import 'add_customer_view_model.dart';

/// One [DropdownMenuItem] per id (API can return duplicate company names).
List<CashierCorporateAccount> _dedupeCorporateAccountsById(
  List<CashierCorporateAccount> list,
) {
  final byId = <String, CashierCorporateAccount>{};
  for (final c in list) {
    final id = c.id.trim();
    if (id.isEmpty) continue;
    byId.putIfAbsent(id, () => c);
  }
  return byId.values.toList();
}

/// Drives which list/API branch fills customer history under [Autocomplete].
enum _CustomerHistorySearchKind { vehicle, mobile }

class PosAddCustomerView extends StatefulWidget {
  final int initialTab;

  const PosAddCustomerView({super.key, this.initialTab = 0});

  @override
  State<PosAddCustomerView> createState() => _PosAddCustomerViewState();
}

class _PosAddCustomerViewState extends State<PosAddCustomerView>
    with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  late TabController _tabController;
  static const Map<String, String> _makeArabicMap = {
    'Toyota': 'تويوتا',
    'Nissan': 'نيسان',
    'Hyundai': 'هيونداي',
    'Kia': 'كيا',
    'Honda': 'هوندا',
    'Mazda': 'مازدا',
    'Mitsubishi': 'ميتسوبيشي',
    'Ford': 'فورد',
    'Chevrolet': 'شيفروليه',
    'GMC': 'جي إم سي',
    'Lexus': 'لكزس',
    'BMW': 'بي إم دبليو',
    'Mercedes-Benz': 'مرسيدس بنز',
    'Audi': 'أودي',
    'Volkswagen': 'فولكس واجن',
    'Isuzu': 'إيسوزو',
    'Suzuki': 'سوزوكي',
  };

  /// Slightly darker than [Colors.grey.shade400] so hints stay readable on white fields.
  static Color get _fieldHintColor => Colors.grey.shade500;

  String _localizeDigitsForLocale(String value) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    if (lang != 'ar') return value;
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var out = value;
    for (var i = 0; i < western.length; i++) {
      out = out.replaceAll(western[i], arabic[i]);
    }
    return out;
  }

  String _localizedPlateOrDigits(String value) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    if (lang != 'ar') return value;
    final clean = value.trim();
    if (clean.isEmpty) return value;
    if (PlateTransliterator.looksLikePlate(clean)) {
      return PlateTransliterator.localize(clean, lang);
    }
    return _localizeDigitsForLocale(clean);
  }

  // Form keys
  final _normalFormKey = GlobalKey<FormState>();
  final _corporateFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_onTabChanged);
    if (widget.initialTab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchCorporateAccountsIfEmpty();
      });
    }
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _fetchCorporateAccountsIfEmpty();
    }
  }

  void _fetchCorporateAccountsIfEmpty() {
    final posVm = context.read<PosViewModel>();
    if (posVm.isCorpAccountsLoading) return;
    // Empty list + cached "loaded once" would skip GET in VM; force so newly added server accounts can appear.
    posVm.fetchCorporateAccounts(
      silent: false,
      forceRefresh: posVm.corporateAccounts.isEmpty,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TextInputFormatter> _gccPlateInputFormatters(
    AddCustomerViewModel vm, {
    required bool isCorporate,
  }) {
    final isBike =
        isCorporate ? vm.isCorpBike : vm.isNormalBike;
    if (isBike) {
      return [
        UpperCaseTextFormatter(),
        saudiBikePlateInputFormatter(
          onRejectedDigitBeyondFour: _toastPlateMaxFourDigitsAfterLetters,
          onRejectedLetterBeyondTwo: _toastPlateMaxTwoLettersBeforeDigits,
        ),
      ];
    }
    final countryCode =
        isCorporate ? vm.corpPlateCountry : vm.normalPlateCountry;
    return [
      UpperCaseTextFormatter(),
      gccPlateInputFormatter(
        countryCode: countryCode,
        onRejectedDigitBeyondFour: _toastPlateMaxFourDigitsAfterLetters,
        onRejectedLetterBeyondThree: _toastPlateMaxThreeLettersBeforeDigits,
      ),
    ];
  }

  String? _validateGccPlate(
    String? value,
    AddCustomerViewModel vm, {
    required bool isCorporate,
    required String requiredMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isBike =
        isCorporate ? vm.isCorpBike : vm.isNormalBike;
    if (isBike) {
      return validateSaudiBikePlateInput(
        value,
        emptyMessage: requiredMessage,
        twoLettersMessage: l10n.posAddCustomerValidationBikePlateTwoLetters,
        fourDigitsMessage: l10n.posAddCustomerValidationBikePlateFourDigits,
        letterCharsMessage: l10n.posInvoiceDetailsPlateSaudiLetterChars,
      );
    }
    return validateGccPlateInput(
      value,
      countryCode: isCorporate ? vm.corpPlateCountry : vm.normalPlateCountry,
      emirate: isCorporate ? vm.corpPlateEmirate : vm.normalPlateEmirate,
      emptyMessage: requiredMessage,
      saudiThreeLettersMessage: l10n.posInvoiceDetailsPlateSaudiThreeLetters,
      saudiDigitsMessage: l10n.posInvoiceDetailsPlateSaudiDigits,
      saudiLetterCharsMessage: l10n.posInvoiceDetailsPlateSaudiLetterChars,
      gccFormatMessage: l10n.posGccPlateValidationGccFormat,
      emirateRequiredMessage: l10n.posGccPlateValidationEmirateRequired,
    );
  }

  Widget _buildVehicleKindSelector({
    required PosAddCustomerVehicleKind selected,
    required ValueChanged<PosAddCustomerVehicleKind> onChanged,
    required bool enabled,
    bool isTablet = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = TextStyle(
      fontSize: isTablet ? 13 : 12,
      fontWeight: FontWeight.w600,
      color: enabled ? const Color(0xFF1E2124) : Colors.grey.shade500,
    );

    Widget radioOption({
      required PosAddCustomerVehicleKind kind,
      required String label,
      required IconData icon,
    }) {
      return InkWell(
        onTap: enabled ? () => onChanged(kind) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<PosAddCustomerVehicleKind>(
                value: kind,
                groupValue: selected,
                onChanged: enabled
                    ? (value) {
                        if (value != null) onChanged(value);
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
                size: isTablet ? 18 : 16,
                color: enabled
                    ? AppColors.secondaryLight
                    : Colors.grey.shade400,
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
        SizedBox(width: isTablet ? 28 : 20),
        radioOption(
          kind: PosAddCustomerVehicleKind.bike,
          label: l10n.posAddCustomerVehicleKindBike,
          icon: Icons.two_wheeler_outlined,
        ),
      ],
    );
  }

  Widget _buildNormalGccPlateCountrySelector(
    AddCustomerViewModel vm, {
    bool isTablet = false,
  }) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => GccPlateCountrySelector(
        countryCode: vm.normalPlateCountry,
        onCountryChanged: (code) => vm.setNormalPlateCountry(code),
        emirate: vm.normalPlateEmirate,
        onEmirateChanged: (e) =>
            vm.setNormalPlateCountry(vm.normalPlateCountry, emirate: e),
        isTablet: isTablet,
      ),
    );
  }

  Widget _buildCorpGccPlateCountrySelector(
    AddCustomerViewModel vm, {
    bool isTablet = false,
    bool enabled = true,
  }) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => GccPlateCountrySelector(
        countryCode: vm.corpPlateCountry,
        onCountryChanged: (code) => vm.setCorpPlateCountry(code),
        emirate: vm.corpPlateEmirate,
        onEmirateChanged: (e) =>
            vm.setCorpPlateCountry(vm.corpPlateCountry, emirate: e),
        isTablet: isTablet,
        enabled: enabled,
      ),
    );
  }

  void _toastPlateMaxFourDigitsAfterLetters() {
    if (!mounted) return;
    ToastService.showError(
      context,
      l10n.posAddCustomerValidationVehiclePlateMaxFourDigits,
    );
  }

  void _toastPlateMaxThreeLettersBeforeDigits() {
    if (!mounted) return;
    ToastService.showError(
      context,
      l10n.posAddCustomerValidationVehiclePlateMaxThreeLetters,
    );
  }

  void _toastPlateMaxTwoLettersBeforeDigits() {
    if (!mounted) return;
    ToastService.showError(
      context,
      l10n.posAddCustomerValidationBikePlateMaxTwoLetters,
    );
  }

  String _vehicleLabelWithArabic(String value) {
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    if (!isArabic) return value;
    final ar = _makeArabicMap[value];
    if (ar == null || ar.isEmpty) return value;
    return '$ar - $value';
  }

  /// Extra bottom padding so focused fields scroll above the software keyboard.
  EdgeInsets _fieldScrollPadding(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return EdgeInsets.fromLTRB(16, 20, 16, 100 + kb);
  }

  double _addCustomerDropdownMenuMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return math.min(340.0, math.max(160.0, (h - kb) * 0.42));
  }

  double _addCustomerAutocompleteMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return math.min(280.0, math.max(120.0, (h - kb) * 0.36));
  }

  bool _isNormalTabDirty(AddCustomerViewModel vm) {
    bool t(String s) => s.trim().isNotEmpty;
    if (t(vm.nameController.text)) return true;
    if (AddCustomerViewModel.digitsOnlyPhone(
      vm.mobileController.text,
    ).isNotEmpty) {
      return true;
    }
    if (t(vm.vatController.text)) return true;
    if (t(vm.vehicleNumberController.text)) return true;
    if (t(vm.vinNumberController.text)) return true;
    if (t(vm.makeController.text)) return true;
    if (t(vm.modelController.text)) return true;
    if (t(vm.odoMeterController.text)) return true;
    if (vm.normalVehicleYear != null) return true;
    return false;
  }

  bool _isCorporateTabDirty(AddCustomerViewModel vm) {
    bool t(String s) => s.trim().isNotEmpty;
    if (vm.selectedCorporate != null) return true;
    if (t(vm.corpVehicleNumberController.text)) return true;
    if (t(vm.corpVinNumberController.text)) return true;
    if (t(vm.corpMakeController.text)) return true;
    if (t(vm.corpModelController.text)) return true;
    if (t(vm.corpOdoMeterController.text)) return true;
    if (vm.corpVehicleYear != null) return true;
    return false;
  }

  bool _isTabDirty(AddCustomerViewModel vm, int tabIndex) {
    if (tabIndex == 0) return _isNormalTabDirty(vm);
    return _isCorporateTabDirty(vm);
  }

  Future<void> _onCustomerTypeSegmentTapped(
    AddCustomerViewModel vm,
    int newIndex,
  ) async {
    if (newIndex == _tabController.index) return;
    if (_isTabDirty(vm, _tabController.index)) {
      final ok =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final screenW = MediaQuery.sizeOf(ctx).width;
              final dialogW = screenW >= 420
                  ? 380.0
                  : (screenW - 48).clamp(280.0, 380.0);
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: Colors.white,
                child: Container(
                  width: dialogW,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change customer type',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Switching customer type will clear all information you have entered '
                        'on this screen. Do you want to continue?',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.secondaryLight,
                                elevation: 0,
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.onPrimaryLight,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ) ??
          false;
      if (!ok || !context.mounted) return;
      vm.clearAllFields();
    }
    _tabController.animateTo(newIndex);
    if (newIndex == 1) {
      _fetchCorporateAccountsIfEmpty();
    }
  }

  Widget _buildCustomerTypeSegmentBar(bool isTablet, AddCustomerViewModel vm) {
    final pad = EdgeInsets.symmetric(horizontal: isTablet ? 20 : 12);
    return Padding(
      padding: pad,
      child: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          final selectedId = _tabController.index == 0 ? 'normal' : 'corporate';
          return PosSegmentedListTabs(
            layout: PosSegmentedTabLayout.expanded,
            containerColor: Colors.white,
            unselectedTabColor: Colors.white,
            tabVerticalPadding: isTablet ? 9 : 8,
            tabs: [
              PosSegmentedTab(
                id: 'normal',
                label: l10n.posAddCustomerTabNormal,
              ),
              PosSegmentedTab(
                id: 'corporate',
                label: l10n.posAddCustomerTabCorporate,
              ),
            ],
            selectedId: selectedId,
            onSelected: (id) {
              final newIndex = id == 'normal' ? 0 : 1;
              _onCustomerTypeSegmentTapped(vm, newIndex);
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(bool isTablet, AddCustomerViewModel vm) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F6),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 20 : 12,
            8,
            isTablet ? 20 : 12,
            10,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildClearDataButton(isTablet: isTablet, vm: vm),
              ),
              SizedBox(width: isTablet ? 12 : 10),
              Expanded(
                child: _buildSaveButton(isTablet: isTablet, vm: vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearDataButton({
    required bool isTablet,
    required AddCustomerViewModel vm,
  }) {
    return SizedBox(
      height: isTablet ? 44 : 40,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_tabController.index == 0) {
            vm.clearNormalCustomerFields();
          } else {
            vm.clearCorporateCustomerFields();
          }
          if (_tabController.index == 0) {
            _normalFormKey.currentState?.reset();
          } else {
            _corporateFormKey.currentState?.reset();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryLight,
          foregroundColor: AppColors.onSecondaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          ),
        ),
        child: Text(
          'Clear data',
          style: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 13 : 12,
            color: AppColors.onSecondaryLight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChangeNotifierProvider(
      create: (context) => AddCustomerViewModel(context),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AddCustomerViewModel>();
          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: const Color(0xFFFBF9F6),
            appBar: PosScreenAppBar(title: l10n.posAddCustomerTitle),
            body: Column(
              children: [
                SizedBox(height: isTablet ? 8 : 6),

                _buildCustomerTypeSegmentBar(isTablet, vm),
                SizedBox(height: isTablet ? 8 : 6),

                // Tab Content (swipe disabled so tab changes always go through confirmation)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildNormalCustomerForm(isTablet, vm),
                      _buildCorporateCustomerForm(isTablet, vm),
                    ],
                  ),
                ),
                _buildBottomActionBar(isTablet, vm),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Fleet vehicle picker for corporate tab — optional; manual entry still allowed.
  Widget _buildCorporateFleetVehicleDropdown(
    AddCustomerViewModel vm, {
    required bool isTablet,
  }) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.corporateFleetVehiclesLoading) {
          return Container(
            height: isTablet ? 42 : 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 10 : 9),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                l10n.posAddCustomerFleetVehiclesLoading,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _fieldHintColor,
                  fontSize: isTablet ? 11 : 10,
                ),
              ),
            ),
          );
        }

        final fleet = vm.corporateFleetVehicles;
        final selectedId = vm.selectedCorporateFleetVehicleId;
        final dropdownValue =
            selectedId != null && fleet.any((v) => v.id == selectedId)
            ? selectedId
            : null;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 9),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : 8,
            vertical: isTablet ? 0 : 0,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: dropdownValue,
              isExpanded: true,
              menuMaxHeight: _addCustomerDropdownMenuMaxHeight(context),
              hint: Text(
                fleet.isEmpty
                    ? l10n.posAddCustomerNoFleetVehicles
                    : l10n.posAddCustomerSelectFleetVehicle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _fieldHintColor,
                  fontSize: isTablet ? 13 : 12,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
                size: isTablet ? 21 : 20,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    l10n.posAddCustomerFleetVehicleManual,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 12 : 11,
                    ),
                  ),
                ),
                ...fleet.map((v) {
                  final label = v.label.trim().isNotEmpty
                      ? v.label
                      : (v.plateDisplay ?? v.plateNo);
                  return DropdownMenuItem<String?>(
                    value: v.id,
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 12 : 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) => vm.selectCorporateFleetVehicle(value),
            ),
          ),
        );
      },
    );
  }

  /// Name + mobile.
  Widget _buildCustomerInformationSection(
    AddCustomerViewModel vm, {
    required bool isTablet,
    /// Corporate contacts may use non-KSA numbers — do not cap at 9 Saudi digits.
    bool relaxedCorporateMobile = false,
    /// Corporate account contact — name and mobile are account-managed (read-only).
    bool lockCorporateContact = false,
  }) {
    final fieldGap = isTablet ? 10.0 : 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.posAddCustomerSectionCustomerInfo,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 8.0 : 6.0),
        ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final lock = lockCorporateContact;
            if (isTablet) {
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      l10n.posAddCustomerFieldCustomerName,
                      vm.nameController,
                      Icons.person_outline,
                      isTablet: isTablet,
                      readOnly: lock,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomerHistoryAutocompleteField(
                      l10n.posDetailsMobile,
                      vm.mobileController,
                      Icons.phone_android_outlined,
                      vm: vm,
                      isTablet: isTablet,
                      readOnly: lock,
                      searchKind: _CustomerHistorySearchKind.mobile,
                      keyboardType: TextInputType.phone,
                      relaxedCorporateMobile: relaxedCorporateMobile,
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  l10n.posAddCustomerFieldCustomerName,
                  vm.nameController,
                  Icons.person_outline,
                  isTablet: isTablet,
                  readOnly: lock,
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: fieldGap),
                _buildCustomerHistoryAutocompleteField(
                  l10n.posDetailsMobile,
                  vm.mobileController,
                  Icons.phone_android_outlined,
                  vm: vm,
                  isTablet: isTablet,
                  readOnly: lock,
                  searchKind: _CustomerHistorySearchKind.mobile,
                  keyboardType: TextInputType.phone,
                  relaxedCorporateMobile: relaxedCorporateMobile,
                ),
              ],
            );
          },
        ),
        SizedBox(height: fieldGap),
        ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            if (lockCorporateContact) return const SizedBox.shrink();
            return _buildTextField(
              l10n.posAddCustomerFieldVatNumber,
              vm.vatController,
              Icons.receipt_long_outlined,
              isTablet: isTablet,
              keyboardType: TextInputType.text,
              inputFormatters: [EnglishNumberFormatter()],
            );
          },
        ),
        SizedBox(height: fieldGap),
      ],
    );
  }

  // ── Normal Customer Form ──
  Widget _buildNormalCustomerForm(bool isTablet, AddCustomerViewModel vm) {
    final hPad = isTablet ? 20.0 : 12.0;
    final fieldGap = isTablet ? 10.0 : 8.0;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16 + bottomInset),
      child: Form(
        key: _normalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerInformationSection(
              vm,
              isTablet: isTablet,
            ),

            _buildSectionHeader(
              l10n.posAddCustomerSectionVehicleInfo,
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8.0 : 6.0),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => _buildVehicleKindSelector(
                selected: vm.normalVehicleKind,
                onChanged: vm.setNormalVehicleKind,
                enabled: true,
                isTablet: isTablet,
              ),
            ),
            SizedBox(height: fieldGap),
            if (isTablet) ...[
              ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  final isBike = vm.isNormalBike;
                  final showUaeEmirate =
                      !isBike && vm.normalPlateCountry == 'AE';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isBike) ...[
                        Expanded(
                          flex: showUaeEmirate ? 3 : 2,
                          child: _buildNormalGccPlateCountrySelector(
                            vm,
                            isTablet: isTablet,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: isBike
                            ? 4
                            : (showUaeEmirate ? 2 : 3),
                        child: _buildCustomerHistoryAutocompleteField(
                          vm: vm,
                          l10n.posAddCustomerFieldVehicleNumber,
                          vm.vehicleNumberController,
                          Icons.confirmation_number_outlined,
                          isTablet: isTablet,
                          enableSuggestions: false,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters:
                              _gccPlateInputFormatters(vm, isCorporate: false),
                          validator: (value) => _validateGccPlate(
                            value,
                            vm,
                            isCorporate: false,
                            requiredMessage:
                                l10n.posAddCustomerValidationVehicleRequired,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          l10n.posAddCustomerFieldVin,
                          vm.vinNumberController,
                          Icons.tag_outlined,
                          isTablet: isTablet,
                          enableSuggestions: false,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(17),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            if (value.trim().length > 17) {
                              return l10n.posAddCustomerValidationVinMax;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: fieldGap),
              Row(
                children: [
                  Expanded(
                    child: _buildVehicleAutocompleteField(
                      vm: vm,
                      type: VehicleLookupType.make,
                      l10n.posAddCustomerFieldMake,
                      vm.makeController,
                      Icons.directions_car_outlined,
                      dependentModelController: vm.modelController,
                      isTablet: isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVehicleAutocompleteField(
                      vm: vm,
                      type: VehicleLookupType.model,
                      l10n.posAddCustomerFieldModel,
                      vm.modelController,
                      Icons.model_training_outlined,
                      makeController: vm.makeController,
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldGap),
              Row(
                children: [
                  Expanded(
                    child: _buildVehicleYearDropdown(
                      vm,
                      isCorporate: false,
                      isTablet: isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      l10n.posAddCustomerFieldOdometer,
                      vm.odoMeterController,
                      Icons.speed_outlined,
                      keyboardType: TextInputType.number,
                      isTablet: isTablet,
                      enableSuggestions: false,
                      autocorrect: false,
                      inputFormatters: [EnglishNumberFormatter()],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (!RegExp(r'^[0-9٠-٩۰-۹०-९]+$').hasMatch(value)) {
                          return l10n
                              .posAddCustomerValidationInvalidNumberShort;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  if (vm.isNormalBike) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNormalGccPlateCountrySelector(
                        vm,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: fieldGap),
                    ],
                  );
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ListenableBuilder(
                      listenable: vm,
                      builder: (context, _) =>
                          _buildCustomerHistoryAutocompleteField(
                        vm: vm,
                        l10n.posAddCustomerFieldVehicleNumber,
                        vm.vehicleNumberController,
                        Icons.confirmation_number_outlined,
                        isTablet: isTablet,
                        enableSuggestions: false,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters:
                            _gccPlateInputFormatters(vm, isCorporate: false),
                        validator: (value) => _validateGccPlate(
                          value,
                          vm,
                          isCorporate: false,
                          requiredMessage:
                              l10n.posAddCustomerValidationVehicleRequired,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      l10n.posAddCustomerFieldVin,
                      vm.vinNumberController,
                      Icons.tag_outlined,
                      isTablet: isTablet,
                      enableSuggestions: false,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(17),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (value.trim().length > 17) {
                          return l10n.posAddCustomerValidationVinMax;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldGap),
              _buildVehicleAutocompleteField(
                vm: vm,
                type: VehicleLookupType.make,
                l10n.posAddCustomerFieldMake,
                vm.makeController,
                Icons.directions_car_outlined,
                isTablet: isTablet,
                dependentModelController: vm.modelController,
              ),
              SizedBox(height: fieldGap),
              _buildVehicleAutocompleteField(
                l10n.posAddCustomerFieldModel,
                vm.modelController,
                Icons.model_training_outlined,
                vm: vm,
                type: VehicleLookupType.model,
                makeController: vm.makeController,
                isTablet: isTablet,
              ),
              SizedBox(height: fieldGap),
              _buildVehicleYearDropdown(
                vm,
                isCorporate: false,
                isTablet: isTablet,
              ),
              SizedBox(height: fieldGap),
              _buildTextField(
                l10n.posAddCustomerFieldOdometer,
                vm.odoMeterController,
                Icons.speed_outlined,
                keyboardType: TextInputType.number,
                isTablet: isTablet,
                enableSuggestions: false,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (int.tryParse(value) == null) {
                    return l10n.posAddCustomerValidationInvalidNumber;
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Corporate Customer Form ──
  Widget _buildCorporateCustomerForm(bool isTablet, AddCustomerViewModel vm) {
    final hPad = isTablet ? 20.0 : 12.0;
    final fieldGap = isTablet ? 10.0 : 8.0;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16 + bottomInset),
      child: Form(
        key: _corporateFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Corporate Dropdown
            _buildSectionHeader(
              l10n.posAddCustomerSectionCorporateAccount,
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8.0 : 6.0),
            Consumer<PosViewModel>(
              builder: (context, posVm, child) {
                if (posVm.isCorpAccountsLoading) {
                  return Container(
                    height: isTablet ? 42 : 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: PosShimmer(
                        child: PosShimmerBox(width: 110, height: 14, radius: 7),
                      ),
                    ),
                  );
                }

                final accounts = _dedupeCorporateAccountsById(
                  posVm.corporateAccounts,
                );
                vm.reconcileCorporateDropdownSelection(accounts);
                vm.tryHydrateCorporateAccountFromPosVm(accounts);
                final selectedId = vm.selectedCorporate;
                final dropdownValue =
                    selectedId != null &&
                        accounts.any((c) => c.id == selectedId)
                    ? selectedId
                    : null;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 10,
                    vertical: isTablet ? 2 : 0,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      menuMaxHeight: _addCustomerDropdownMenuMaxHeight(context),
                      hint: Text(
                        accounts.isEmpty
                            ? l10n.posAddCustomerNoCorporateFound
                            : l10n.posAddCustomerSelectCorporate,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _fieldHintColor,
                          fontSize: isTablet ? 12 : 11,
                        ),
                      ),
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400,
                        size: isTablet ? 21 : 20,
                      ),
                      items: accounts.map((corp) {
                        return DropdownMenuItem<String>(
                          value: corp.id,
                          child: LocalizedApiText(
                            corp.companyName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 12 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: accounts.isEmpty
                          ? null
                          : (value) {
                              if (value != null) {
                                final corpData = accounts.firstWhere(
                                  (corp) => corp.id == value,
                                );
                                vm.setCorporate(value, corpData);
                              }
                            },
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: isTablet ? 10.0 : 8.0),

            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => _buildCustomerInformationSection(
                vm,
                isTablet: isTablet,
                relaxedCorporateMobile: true,
                lockCorporateContact: vm.isCorporateContactLocked,
              ),
            ),
            SizedBox(height: isTablet ? 10.0 : 8.0),

            // Auto-filled fields (read-only)
            if (vm.selectedCorporateData != null) ...[
              _buildSectionHeader(
                l10n.posAddCustomerSectionCompanyDetails,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 12.0 : 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildReadOnlyField(
                      l10n.posAddCustomerFieldCompanyName,
                      vm.selectedCorporateData!.companyName,
                      Icons.business,
                      isTablet: isTablet,
                      maxValueLines: 2,
                      valueOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: _buildReadOnlyField(
                      l10n.posAddCustomerFieldVatNumber,
                      vm.selectedCorporateData!.effectiveVatNumber ??
                          l10n.posAddCustomerFieldNA,
                      Icons.receipt_long_outlined,
                      isTablet: isTablet,
                      maxValueLines: 2,
                      valueOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: _buildReadOnlyField(
                      l10n.posAddCustomerFieldBillingAddress,
                      vm.selectedCorporateData!.billingAddress ??
                          vm.selectedCorporateData!.address ??
                          l10n.posAddCustomerFieldNA,
                      Icons.location_on_outlined,
                      isTablet: isTablet,
                      maxValueLines: 3,
                      valueOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 10.0 : 8.0),
            ],

            // Vehicle Section
            _buildSectionHeader(
              l10n.posAddCustomerSectionVehicleInfo,
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8.0 : 6.0),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => _buildVehicleKindSelector(
                selected: vm.corpVehicleKind,
                onChanged: vm.setCorpVehicleKind,
                enabled: !vm.isCorporateFleetVehicleSelected,
                isTablet: isTablet,
              ),
            ),
            SizedBox(height: fieldGap),
            if (vm.selectedCorporateData != null)
              _buildCorporateFleetVehicleDropdown(vm, isTablet: isTablet),
            if (vm.selectedCorporateData != null)
              SizedBox(height: isTablet ? 8.0 : 6.0),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) {
                final fleetLocked = vm.isCorporateFleetVehicleSelected;
                final isBike = vm.isCorpBike;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isTablet) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isBike) ...[
                    Expanded(
                      flex: vm.corpPlateCountry == 'AE' ? 3 : 2,
                      child: _buildCorpGccPlateCountrySelector(
                        vm,
                        isTablet: isTablet,
                        enabled: !fleetLocked,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: isBike
                        ? 4
                        : (vm.corpPlateCountry == 'AE' ? 2 : 3),
                    child: _buildTextField(
                      l10n.posAddCustomerFieldVehicleNumber,
                      vm.corpVehicleNumberController,
                      Icons.confirmation_number_outlined,
                      isTablet: isTablet,
                      readOnly: fleetLocked,
                      enableSuggestions: false,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters:
                          _gccPlateInputFormatters(vm, isCorporate: true),
                      validator: (value) => _validateGccPlate(
                        value,
                        vm,
                        isCorporate: true,
                        requiredMessage:
                            l10n.posAddCustomerValidationRequired,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildVehicleAutocompleteField(
                      vm: vm,
                      type: VehicleLookupType.make,
                      l10n.posAddCustomerFieldMake,
                      vm.corpMakeController,
                      Icons.directions_car_outlined,
                      dependentModelController: vm.corpModelController,
                      isTablet: isTablet,
                      readOnly: fleetLocked,
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildVehicleYearDropdown(
                      vm,
                      isCorporate: true,
                      isTablet: isTablet,
                      readOnly: fleetLocked,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      l10n.posAddCustomerFieldVin,
                      vm.corpVinNumberController,
                      Icons.tag_outlined,
                      isTablet: isTablet,
                      enableSuggestions: false,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(17),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (value.trim().length > 17) {
                          return l10n.posAddCustomerValidationVinMax;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldGap),
              Row(
                children: [
                  Expanded(
                    child: _buildVehicleAutocompleteField(
                      vm: vm,
                      type: VehicleLookupType.model,
                      l10n.posAddCustomerFieldModel,
                      vm.corpModelController,
                      Icons.model_training_outlined,
                      makeController: vm.corpMakeController,
                      isTablet: isTablet,
                      readOnly: fleetLocked,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      l10n.posAddCustomerFieldOdometer,
                      vm.corpOdoMeterController,
                      Icons.speed_outlined,
                      keyboardType: TextInputType.number,
                      isTablet: isTablet,
                      enableSuggestions: false,
                      autocorrect: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (int.tryParse(value) == null) {
                          return l10n
                              .posAddCustomerValidationInvalidNumberShort;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (!isBike) ...[
                _buildCorpGccPlateCountrySelector(
                  vm,
                  isTablet: isTablet,
                  enabled: !fleetLocked,
                ),
                SizedBox(height: fieldGap),
              ],
              _buildTextField(
                l10n.posAddCustomerFieldVehicleNumber,
                vm.corpVehicleNumberController,
                Icons.confirmation_number_outlined,
                isTablet: isTablet,
                readOnly: fleetLocked,
                enableSuggestions: false,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                inputFormatters:
                    _gccPlateInputFormatters(vm, isCorporate: true),
                validator: (value) => _validateGccPlate(
                  value,
                  vm,
                  isCorporate: true,
                  requiredMessage:
                      l10n.posAddCustomerValidationVehicleRequired,
                ),
              ),
              SizedBox(height: fieldGap),
              _buildVehicleAutocompleteField(
                vm: vm,
                type: VehicleLookupType.make,
                l10n.posAddCustomerFieldMake,
                vm.corpMakeController,
                Icons.directions_car_outlined,
                dependentModelController: vm.corpModelController,
                isTablet: isTablet,
                readOnly: fleetLocked,
              ),
              SizedBox(height: fieldGap),
              _buildVehicleAutocompleteField(
                vm: vm,
                type: VehicleLookupType.model,
                l10n.posAddCustomerFieldModel,
                vm.corpModelController,
                Icons.model_training_outlined,
                makeController: vm.corpMakeController,
                isTablet: isTablet,
                readOnly: fleetLocked,
              ),
              SizedBox(height: fieldGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildVehicleYearDropdown(
                      vm,
                      isCorporate: true,
                      isTablet: isTablet,
                      readOnly: fleetLocked,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      l10n.posAddCustomerFieldVin,
                      vm.corpVinNumberController,
                      Icons.tag_outlined,
                      isTablet: isTablet,
                      enableSuggestions: false,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(17),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (value.trim().length > 17) {
                          return l10n.posAddCustomerValidationVinMax;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldGap),
              _buildTextField(
                l10n.posAddCustomerFieldOdometer,
                vm.corpOdoMeterController,
                Icons.speed_outlined,
                keyboardType: TextInputType.number,
                isTablet: isTablet,
                enableSuggestions: false,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (int.tryParse(value) == null) {
                    return l10n.posAddCustomerValidationInvalidNumber;
                  }
                  return null;
                },
              ),
            ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ──

  Widget _buildVehicleYearDropdown(
    AddCustomerViewModel vm, {
    required bool isCorporate,
    required bool isTablet,
    bool readOnly = false,
  }) {
    final years = vehicleModelYearChoices();
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final menuMaxH = math.min(
      240.0,
      math.max(
        140.0,
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            0.42,
      ),
    );
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final raw = isCorporate ? vm.corpVehicleYear : vm.normalVehicleYear;
        final selected = raw != null && years.contains(raw) ? raw : null;

        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          crossAxisUnconstrained: false,
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            elevation: const WidgetStatePropertyAll(6),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 6),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maximumSize: WidgetStatePropertyAll(Size.fromHeight(menuMaxH)),
          ),
          builder: (context, controller, _) {
            return InkWell(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              onTap: readOnly
                  ? null
                  : () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
              child: InputDecorator(
                isFocused: controller.isOpen,
                decoration: InputDecoration(
                  labelText: l10n.posAddCustomerFieldYear,
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: isTablet ? 20 : 18,
                    color: Colors.grey.shade400,
                  ),
                  suffixIcon: readOnly
                      ? Icon(
                          Icons.lock_outline,
                          size: isTablet ? 16 : 15,
                          color: Colors.grey.shade400,
                        )
                      : Icon(
                          controller.isOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: Colors.grey.shade500,
                        ),
                  filled: true,
                  fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(
                    isTablet ? 8 : 6,
                    isTablet ? 10 : 8,
                    isTablet ? 8 : 6,
                    isTablet ? 10 : 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                    fontSize: isTablet ? 12 : 11,
                  ),
                ),
                child: Text(
                  selected == null ? '' : _localizeDigitsForLocale(selected),
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryLight,
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
          menuChildren: years.map((y) {
            final isSelected = y == selected;
            return MenuItemButton(
              style: ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size(isTablet ? 200 : 160, 36),
                ),
                backgroundColor: WidgetStatePropertyAll(
                  isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.18)
                      : Colors.white,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              onPressed: () {
                if (isCorporate) {
                  vm.setCorpVehicleYear(y);
                } else {
                  vm.setNormalVehicleYear(y);
                }
              },
              child: Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  _localizeDigitsForLocale(y),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {bool isTablet = false}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: isTablet ? 14 : 13,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 12 : 11,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isTablet = false,
    bool readOnly = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool enableSuggestions = true,
    bool autocorrect = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final effectiveHint = hintText ?? label;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      scrollPadding: _fieldScrollPadding(context),
      hintLocales: appKeyboardHintLocales(context),
      textCapitalization: textCapitalization,
      validator: (val) {
        if (val == null || val.isEmpty) return validator?.call(val);
        return validator?.call(EnglishNumberFormatter.convert(val));
      },
      textAlign: isAr ? TextAlign.right : TextAlign.left,
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      inputFormatters: [
        EnglishNumberFormatter(),
        if (keyboardType == TextInputType.number ||
            keyboardType == TextInputType.phone)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹०-९]')),
        ...?inputFormatters,
      ],
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: isTablet ? 12 : 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: effectiveHint,
        hintTextDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        alignLabelWithHint: true,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.grey,
          fontSize: isTablet ? 12 : 11,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: _fieldHintColor,
          fontSize: isTablet ? 12 : 11,
        ),
        prefixIcon: Icon(
          icon,
          size: isTablet ? 18 : 16,
          color: Colors.grey.shade400,
        ),
        suffixIcon: readOnly
            ? Icon(
                Icons.lock_outline,
                size: isTablet ? 15 : 14,
                color: Colors.grey.shade400,
              )
            : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(
          isTablet ? 8 : 6,
          isTablet ? 10 : 8,
          isTablet ? 8 : 6,
          isTablet ? 10 : 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontSize: 10, height: 1),
      ),
    );
  }

  Widget _buildVehicleAutocompleteField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required AddCustomerViewModel vm,
    required VehicleLookupType type,
    TextEditingController? makeController,
    TextEditingController? dependentModelController,
    bool isTablet = false,
    bool readOnly = false,
  }) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final makeText = makeController?.text.trim() ?? '';
    final hasSelectedMake = vm.hasExactMake(makeText);
    final lookupKey =
        'vehlookup_${type.name}_${vm.customerPrefillRebuildToken}';

    if (type == VehicleLookupType.make) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.loadMakes();
      });
    } else if (hasSelectedMake) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.loadModelsForMake(makeText);
      });
    }

    return KeyedSubtree(
      key: ValueKey(lookupKey),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: controller.text),
        optionsBuilder: (textEditingValue) {
          final q = textEditingValue.text;
          if (type == VehicleLookupType.make) {
            return vm.makeSuggestions(q);
          }
          final selectedMake = (makeController?.text ?? '').trim();
          if (!vm.hasExactMake(selectedMake)) {
            return const Iterable<String>.empty();
          }
          return vm.modelSuggestions(make: selectedMake, query: q);
        },
        onSelected: readOnly
            ? (_) {}
            : (selection) {
          final previous = controller.text.trim();
          controller.text = selection;
          if (type == VehicleLookupType.make &&
              dependentModelController != null &&
              previous.toLowerCase() != selection.toLowerCase()) {
            dependentModelController.clear();
            if (mounted) setState(() {});
          }
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            readOnly: readOnly,
            scrollPadding: _fieldScrollPadding(context),
            hintLocales: appKeyboardHintLocales(context),
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isTablet ? 13 : 13,
              fontWeight: FontWeight.w500,
            ),
            onChanged: readOnly
                ? null
                : (value) {
              final previous = controller.text.trim();
              controller.text = value;
              if (type == VehicleLookupType.make &&
                  dependentModelController != null &&
                  previous.toLowerCase() != value.trim().toLowerCase()) {
                dependentModelController.clear();
                if (mounted) setState(() {});
              }
              if (type == VehicleLookupType.make) {
                // Makes are local KSA catalog values; no network refresh needed while typing.
              } else if (vm.hasExactMake((makeController?.text ?? '').trim())) {
                final typedMake = (makeController?.text ?? '').trim();
                vm.loadModelsForMake(typedMake);
              }
            },
            decoration: InputDecoration(
              labelText: label,
              hintText: label,
              hintTextDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              alignLabelWithHint: true,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey,
                fontSize: isTablet ? 13 : 12,
              ),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: _fieldHintColor,
                fontSize: isTablet ? 13 : 12,
              ),
              prefixIcon: Icon(
                icon,
                size: isTablet ? 20 : 18,
                color: Colors.grey.shade400,
              ),
              suffixIcon: readOnly
                  ? Icon(
                      Icons.lock_outline,
                      size: isTablet ? 16 : 15,
                      color: Colors.grey.shade400,
                    )
                  : (type == VehicleLookupType.model &&
                          !vm.hasExactMake((makeController?.text ?? '').trim())
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.info_outline,
                            size: isTablet ? 17 : 15,
                            color: Colors.grey.shade400,
                          ),
                        )
                      : null),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(
                isTablet ? 10 : 8,
                isTablet ? 12 : 10,
                isTablet ? 10 : 8,
                isTablet ? 12 : 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: isAr ? Alignment.topRight : Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 420 : 320,
                  maxHeight: _addCustomerAutocompleteMaxHeight(context),
                ),
                child: ListView.builder(
                  primary: false,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: LocalizedApiText(
                          type == VehicleLookupType.make
                              ? _vehicleLabelWithArabic(option)
                              : option,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          textDirection: isAr
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: isTablet ? 12 : 11,
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w600,
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

  /// Saudi +966 only (no country picker).
  Widget _mobileCountryDialPrefix(
    AddCustomerViewModel vm, {
    required bool isTablet,
    bool enabled = true,
  }) {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: isTablet ? 13 : 12,
      color: AppColors.secondaryLight,
    );
    final dial = vm.mobileDialCountry;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dial.flagEmoji,
              style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1),
            ),
            const SizedBox(width: 6),
            Text('+${dial.dialDigits}', style: textStyle.copyWith(height: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHistoryAutocompleteField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required AddCustomerViewModel vm,
    TextInputType keyboardType = TextInputType.text,
    bool isTablet = false,
    bool readOnly = false,
    _CustomerHistorySearchKind searchKind = _CustomerHistorySearchKind.vehicle,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool enableSuggestions = true,
    bool autocorrect = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool relaxedCorporateMobile = false,
  }) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    String displayForOption(SearchedCustomer option) {
      switch (searchKind) {
        case _CustomerHistorySearchKind.mobile:
          return option.mobile;
        case _CustomerHistorySearchKind.vehicle:
          final plate = (vm.historyVehicleSnapshot(option)?.resolvedPlate ?? '')
              .trim();
          return plate.isNotEmpty
              ? formatVehiclePlateLettersFirst(plate)
              : option.mobile;
      }
    }

    Future<Iterable<SearchedCustomer>> optionsFor(TextEditingValue tev) async {
      switch (searchKind) {
        case _CustomerHistorySearchKind.vehicle:
          final q = tev.text.trim();
          if (q.length < 2) return vm.historyFocusHints;
          return vm.fetchCustomerHistoryByVehicleOptions(q);
        case _CustomerHistorySearchKind.mobile:
          final d = AddCustomerViewModel.digitsOnlyPhone(tev.text);
          if (d.length < 3) return vm.historyFocusHints;
          return vm.fetchCustomerHistoryByMobileOptions(tev.text);
      }
    }

    void onChangedQuery(String value) {
      if (readOnly) return;
      controller.text = value;
    }

    final mobileKeySuffix = searchKind == _CustomerHistorySearchKind.mobile &&
            relaxedCorporateMobile
        ? '_corp_${vm.selectedCorporate ?? "none"}'
        : '';
    return KeyedSubtree(
      key: ValueKey(
        'custhist_${searchKind.name}_${vm.customerPrefillRebuildToken}$mobileKeySuffix',
      ),
      child: Autocomplete<SearchedCustomer>(
        displayStringForOption: displayForOption,
        initialValue: TextEditingValue(text: controller.text),
        optionsBuilder: optionsFor,
        onSelected: (selection) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            vm.prefillFromCustomer(selection);
          });
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              final List<TextInputFormatter> formatters;
              if (searchKind == _CustomerHistorySearchKind.mobile) {
                formatters = relaxedCorporateMobile
                    ? [
                        EnglishNumberFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                        LengthLimitingTextInputFormatter(20),
                      ]
                    : [
                        EnglishNumberFormatter(),
                        PosAddCustomerNationalMobileFormatter(
                          vm.mobileDialCountry,
                        ),
                      ];
              } else {
                formatters = [
                  EnglishNumberFormatter(),
                  if (keyboardType == TextInputType.number ||
                      keyboardType == TextInputType.phone)
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9٠-٩۰-۹०-९]'),
                    ),
                  ...?inputFormatters,
                ];
              }

              final String? Function(String?)? effectiveValidator =
                  searchKind == _CustomerHistorySearchKind.mobile
                  ? (v) {
                      final raw = (v ?? '').trim();
                      if (raw.isEmpty) return null;
                      if (relaxedCorporateMobile) {
                        final digits = AddCustomerViewModel.digitsOnlyPhone(
                          raw,
                        );
                        if (digits.length < 7) {
                          return l10n.posAddCustomerValidationMobileRequired;
                        }
                        return null;
                      }
                      return vm.validateNationalMobileInput(
                        raw: v,
                        messageEmpty:
                            l10n.posAddCustomerValidationMobileRequired,
                        messageInvalidSaudi:
                            l10n.posAddCustomerValidationMobileSaudi,
                      );
                    }
                  : validator;

              InputDecoration decoration;
              if (searchKind == _CustomerHistorySearchKind.mobile) {
                // Match [Icon] prefix slot height on [_buildTextField] (48dp default).
                const prefixSlotH = kMinInteractiveDimension;
                final dialPrefixWidth = isTablet ? 114.0 : 102.0;
                decoration = InputDecoration(
                  labelText: label,
                  hintText: vm.mobileDialCountry.inputHintSample,
                  hintTextDirection: TextDirection.ltr,
                  alignLabelWithHint: true,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                    fontSize: isTablet ? 12 : 11,
                  ),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: _fieldHintColor,
                    fontSize: isTablet ? 12 : 11,
                  ),
                  prefixIcon: SizedBox(
                    width: dialPrefixWidth,
                    height: prefixSlotH,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: isTablet ? 8 : 6,
                        ),
                        child: _mobileCountryDialPrefix(
                          vm,
                          isTablet: isTablet,
                          enabled: !readOnly,
                        ),
                      ),
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: dialPrefixWidth,
                    maxWidth: dialPrefixWidth,
                    minHeight: prefixSlotH,
                    maxHeight: prefixSlotH,
                  ),
                  suffixIcon: readOnly
                      ? Icon(
                          Icons.lock_outline,
                          size: isTablet ? 15 : 14,
                          color: Colors.grey.shade400,
                        )
                      : null,
                  filled: true,
                  fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(
                    isTablet ? 8 : 6,
                    isTablet ? 10 : 8,
                    isTablet ? 8 : 6,
                    isTablet ? 10 : 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  errorStyle: const TextStyle(fontSize: 10, height: 1),
                );
              } else {
                decoration = InputDecoration(
                  labelText: label,
                  hintText: label,
                  hintTextDirection: isAr
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  alignLabelWithHint: true,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                    fontSize: isTablet ? 12 : 11,
                  ),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: _fieldHintColor,
                    fontSize: isTablet ? 12 : 11,
                  ),
                  prefixIcon: Icon(
                    icon,
                    size: isTablet ? 18 : 16,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(
                    isTablet ? 8 : 6,
                    isTablet ? 10 : 8,
                    isTablet ? 8 : 6,
                    isTablet ? 10 : 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    borderSide: BorderSide.none,
                  ),
                  errorStyle: const TextStyle(fontSize: 11, height: 1),
                );
              }

              return _CustomerHistoryFieldFocusLoader(
                focusNode: focusNode,
                textEditingController: textController,
                vm: vm,
                child: TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  scrollPadding: _fieldScrollPadding(context),
                  keyboardType: searchKind == _CustomerHistorySearchKind.mobile
                      ? TextInputType.phone
                      : keyboardType,
                  hintLocales: appKeyboardHintLocales(context),
                  textCapitalization: textCapitalization,
                  validator: effectiveValidator,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  textDirection: searchKind == _CustomerHistorySearchKind.mobile
                      ? TextDirection.ltr
                      : (isAr ? TextDirection.rtl : TextDirection.ltr),
                  inputFormatters: formatters,
                  enableSuggestions: enableSuggestions,
                  autocorrect: autocorrect,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isTablet ? 12 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: onChangedQuery,
                  decoration: decoration,
                ),
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: isAr ? Alignment.topRight : Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 480 : 320,
                  maxHeight: _addCustomerAutocompleteMaxHeight(context),
                ),
                child: ListView.builder(
                  primary: false,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final vehicle = vm.historyVehicleSnapshot(option);
                    final plate = (vehicle?.resolvedPlate ?? '').trim();
                    final customerName = option.name;
                    final make = vehicle?.make ?? '';
                    final model = vehicle?.model ?? '';
                    final hasMakeModel = make.isNotEmpty;

                    late final String titleText;
                    late final Widget subtitleRow;

                    switch (searchKind) {
                      case _CustomerHistorySearchKind.mobile:
                        titleText = EnglishNumberFormatter.convert(
                          option.mobile.trim(),
                        );
                        final subParts = <String>[];
                        if (customerName.trim().isNotEmpty) {
                          subParts.add(customerName.trim());
                        }
                        if (plate.isNotEmpty) {
                          subParts.add(_localizedPlateOrDigits(plate));
                        }
                        subtitleRow = LocalizedApiText(
                          subParts.join(' · '),
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          textDirection: isAr
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: isTablet ? 12 : 11,
                            color: Colors.grey.shade600,
                          ),
                        );
                        break;
                      case _CustomerHistorySearchKind.vehicle:
                        titleText = plate.isNotEmpty
                            ? formatVehiclePlateLettersFirst(plate)
                            : option.mobile;
                        subtitleRow = Row(
                          children: [
                            Flexible(
                              child: LocalizedApiText(
                                customerName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: isTablet ? 12 : 11,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasMakeModel) ...[
                              Text(
                                ' • ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: isTablet ? 12 : 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Flexible(
                                child: LocalizedApiText(
                                  '$make $model'.trim(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: isTablet ? 12 : 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        );
                        break;
                    }

                    return InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        onSelected(option);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              searchKind == _CustomerHistorySearchKind.mobile
                                  ? titleText
                                  : _localizedPlateOrDigits(titleText),
                              textAlign: searchKind ==
                                      _CustomerHistorySearchKind.mobile
                                  ? TextAlign.left
                                  : (isAr ? TextAlign.right : TextAlign.left),
                              textDirection: searchKind ==
                                      _CustomerHistorySearchKind.mobile
                                  ? TextDirection.ltr
                                  : (isAr ? TextDirection.rtl : TextDirection.ltr),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: isTablet ? 12 : 11,
                                color: AppColors.secondaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            subtitleRow,
                          ],
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

  Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon, {
    bool isTablet = false,
    int? maxValueLines,
    TextOverflow? valueOverflow,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 9 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(isTablet ? 10 : 9),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: isTablet ? 18 : 16, color: Colors.grey.shade400),
          SizedBox(width: isTablet ? 8 : 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey,
                    fontSize: isTablet ? 10 : 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                LocalizedApiText(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 12 : 12,
                    color: AppColors.secondaryLight,
                  ),
                  maxLines: maxValueLines,
                  overflow: valueOverflow,
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: isTablet ? 15 : 15,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton({
    bool isTablet = false,
    required AddCustomerViewModel vm,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 44 : 40,
      child: ElevatedButton(
        onPressed: () {
          final isNormal = _tabController.index == 0;

          if (isNormal) {
            if (!_normalFormKey.currentState!.validate()) return;
          } else {
            if (!_corporateFormKey.currentState!.validate()) return;
          }

          vm.saveAndProceed(
            isNormal: isNormal,
            onSuccess: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PosDepartmentView(
                    initialDepartmentId: context
                        .read<PosViewModel>()
                        .editDepartmentId,
                  ),
                ),
              );
            },
            onError: (message) {
              if (context.mounted) {
                ToastService.showError(context, message);
              }
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.secondaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          ),
        ),
        child: Text(
          l10n.posAddCustomerSaveButton,
          style: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 13 : 12,
          ),
        ),
      ),
    );
  }
}

/// Loads a few customer rows when history fields gain focus so [Autocomplete]
/// shows suggestions before the user types (same search API + limit).
class _CustomerHistoryFieldFocusLoader extends StatefulWidget {
  const _CustomerHistoryFieldFocusLoader({
    required this.focusNode,
    required this.textEditingController,
    required this.vm,
    required this.child,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final AddCustomerViewModel vm;
  final Widget child;

  @override
  State<_CustomerHistoryFieldFocusLoader> createState() =>
      _CustomerHistoryFieldFocusLoaderState();
}

class _CustomerHistoryFieldFocusLoaderState
    extends State<_CustomerHistoryFieldFocusLoader> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _CustomerHistoryFieldFocusLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.textEditingController != widget.textEditingController) {
      // New Autocomplete internals after KeyedSubtree key change — prompt refresh if focused.
      if (widget.focusNode.hasFocus &&
          widget.textEditingController.text.trim().isEmpty) {
        _afterHintsLoaded();
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _kickAutocompleteRebuild() {
    // RawAutocomplete listens to TextEditingController; no public refresh API.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    widget.textEditingController.notifyListeners();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) return;
    if (widget.textEditingController.text.trim().isNotEmpty) return;
    widget.vm.loadCustomerHistoryFocusHints().whenComplete(() {
      if (!mounted || !widget.focusNode.hasFocus) return;
      _kickAutocompleteRebuild();
    });
  }

  void _afterHintsLoaded() {
    widget.vm.loadCustomerHistoryFocusHints().whenComplete(() {
      if (!mounted || !widget.focusNode.hasFocus) return;
      _kickAutocompleteRebuild();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum VehicleLookupType { make, model }

/// Forces all typed / pasted text to uppercase in any [TextField].
/// Usage: add to `inputFormatters: [UpperCaseTextFormatter()]`
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
