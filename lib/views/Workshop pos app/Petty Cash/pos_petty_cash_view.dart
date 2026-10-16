import 'package:flutter/material.dart';
import '../../../services/currency_helper.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/app_keyboard_locale.dart';
import '../../../utils/toast_service.dart';
import '../Home Screen/pos_view_model.dart';
import '../../../models/petty_cash_model.dart';
import '../../../models/expense_category_model.dart'; // Added
import '../../../models/cashier_expense_models.dart';
import '../../../models/department_model.dart';
import '../../../models/purchase_order_models.dart';
import '../../../widgets/pos_menu_dropdown.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;

import '../More Tab/pos_more_view.dart'; // Added
import '../Promo/promo_code_dialog.dart'; // Added
import 'petty_cash_view_model.dart';
import '../../../constants/petty_cash_expense_categories.dart';
import '../../../services/LocalizedApiText.dart';

class PosPettyCashView extends StatefulWidget {
  const PosPettyCashView({super.key});

  @override
  State<PosPettyCashView> createState() => _PosPettyCashViewState();
}

class _PosPettyCashViewState extends State<PosPettyCashView>
    with SingleTickerProviderStateMixin {
  static Color get _fieldHintColor => Colors.grey.shade500;

  late TabController _tabController;
  late final FocusNode _noCashSupplierFocus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _noCashSupplierFocus = FocusNode();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (!mounted) return;

    final index = _tabController.index;
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<PettyCashViewModel>();
    vm.setIsRequestingFunds(index == 2);
    if (index == 1) {
      Future.microtask(() {
        if (mounted) {
          context.read<PettyCashViewModel>().fetchNoCashLookups();
        }
      });
    }
    if (index == 3 && !vm.expenseHistoryLoading) {
        Future.microtask(() {
          if (mounted) {
            context.read<PettyCashViewModel>().fetchExpenseHistory(refresh: true);
          }
        });
      }
      vm.fetchWalletBalance();
    });
  }

  Widget _buildActiveTabContent(PettyCashViewModel vm, bool isTablet) {
    switch (_tabController.index) {
      case 0:
        return _buildExpenseForm(vm, isTablet);
      case 1:
        return _buildNoCashForm(vm, isTablet);
      case 2:
        return _buildFundTabContent(vm, isTablet);
      case 3:
        return _buildExpenseHistoryTab(vm, isTablet);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _noCashSupplierFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ToastService.showError(context, message);
  }

  Widget _buildFundTabContent(PettyCashViewModel vm, bool isTablet) {
    if (vm.showPendingRequestStatus &&
        vm.fundRequests.any((r) => r.status == PettyCashStatus.pending)) {
      return _buildPendingStatusCard(
        vm.fundRequests.lastWhere(
          (r) => r.status == PettyCashStatus.pending,
        ),
        isTablet,
      );
    }
    return _buildRequestForm(vm, isTablet);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final vm = Provider.of<PettyCashViewModel>(context);

    return Scaffold(
      // Parent [PosShell] Scaffold already resizes for the keyboard; inner resize
      // causes double inset, huge gap, and content jumping to the top.
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PosScreenAppBar(
        title: l10n.posPettyCashTitle,
        showBackButton: false,
        showHamburger: true,
        onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
      ),
      body: wrapPosShellRailBody(
        context,
        vm.isPettyCashLoading
            ? _PettyCashLoadingShimmer(isTablet: isTablet)
            : Builder(
                builder: (context) {
                  // Extra bottom space so focused dropdown fields can scroll
                  // above the keyboard and still show their option list.
                  final view = View.of(context);
                  final keyboard =
                      view.viewInsets.bottom / view.devicePixelRatio;
                  final bottomPad =
                      (isTablet ? 10.0 : 6.0) + keyboard + (keyboard > 0 ? 220.0 : 0.0);
                  return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 10 : 6,
                  isTablet ? 8 : 6,
                  isTablet ? 10 : 6,
                  bottomPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (rest of children)
                    // Balance Header
                    _buildBalanceCard(vm, isTablet),
                    const SizedBox(height: 8),

                    if (vm.isLowPettyCashBalance) ...[
                      _buildLowBalanceWarning(vm, isTablet),
                      const SizedBox(height: 9),
                    ],

                    PosSegmentedListTabs(
                      layout: PosSegmentedTabLayout.expanded,
                      tabVerticalPadding: isTablet ? 10 : 8,
                      tabs: [
                        PosSegmentedTab(
                          id: '0',
                          label: l10n.posPettyCashTabExpense,
                        ),
                        PosSegmentedTab(
                          id: '1',
                          label: l10n.posPettyCashTabNoCash,
                        ),
                        PosSegmentedTab(
                          id: '2',
                          label: l10n.posPettyCashTabFund,
                        ),
                        PosSegmentedTab(
                          id: '3',
                          label: l10n.posPettyCashTabHistory,
                        ),
                      ],
                      selectedId: '${_tabController.index}',
                      onSelected: (id) {
                        final index = int.tryParse(id) ?? 0;
                        if (_tabController.index != index) {
                          _tabController.animateTo(index);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildActiveTabContent(vm, isTablet),
                    const SizedBox(height: 10),
                  ],
                ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBalanceCard(PettyCashViewModel vm, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondaryLight,
            AppColors.secondaryLight.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: isTablet ? 72 : 58,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primaryLight,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.posPettyCashSecureWallet.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.posPettyCashAvailablePettyCash,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    CurrencyHelper.symbol(context),
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: isTablet ? 16 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vm.pettyCashBalance.toStringAsFixed(2),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLowBalanceWarning(PettyCashViewModel vm, bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.posPettyCashLowBalanceWarning,
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(2);
              vm.setIsRequestingFunds(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              AppLocalizations.of(context)!.posPettyCashRequestFund,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm(PettyCashViewModel vm, bool isTablet) {
    return Column(
      key: const ValueKey('expense_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          AppLocalizations.of(context)!.posPettyCashExpenseDetails,
          Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          AppLocalizations.of(context)!.posPettyCashAmountSar,
                        ),
                        _buildTextField(
                          vm.amountController,
                          '0.00',
                          Icons.payments_outlined,
                          const TextInputType.numberWithOptions(decimal: true),
                          currencyPrefix: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          AppLocalizations.of(context)!.posPettyCashExpenseCategory,
                        ),
                        _buildDropdown(vm, isTablet),
                      ],
                    ),
                  ),
                ],
              ),
              if (vm.selectedCategory?.requiresEmployeeSelection == true) ...[
                SizedBox(height: isTablet ? 10 : 8),
                if (vm.branchEmployeesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: PosShimmer(
                        child: PosShimmerBox(width: 120, height: 18, radius: 9),
                      ),
                    ),
                  )
                else ...[
                  _buildLabel(
                    AppLocalizations.of(context)!.posPettyCashEmployeeSalaryAdvance,
                  ),
                  _buildEmployeeDropdown(vm, isTablet),
                ],
              ],
              const SizedBox(height: 10),

              _buildLabel(
                AppLocalizations.of(context)!.posPettyCashDescriptionNotes,
              ),
              _buildTextField(
                vm.notesController,
                AppLocalizations.of(context)!.posPettyCashEnterDetailsHint,
                Icons.notes,
                TextInputType.text,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        _buildSectionTitle(
          AppLocalizations.of(context)!.posPettyCashProofOfExpense,
          Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 8),
        _buildImagePicker(vm),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: isTablet ? 44 : 40,
          child: ElevatedButton(
            onPressed: vm.isExpenseSubmitting
                ? null
                : () {
                    vm
                        .submitExpenseAction((error) {
                          if (mounted) _showError(error);
                        })
                        .then((success) {
                          if (success && mounted) {
                            ToastService.showSuccess(
                              context,
                              AppLocalizations.of(
                                context,
                              )!.posPettyCashExpenseSubmittedPending,
                            );
                          }
                        });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              disabledBackgroundColor: AppColors.secondaryLight,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
              shadowColor: AppColors.secondaryLight.withOpacity(0.4),
            ),
            child: vm.isExpenseSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.posPettyCashSubmitExpense,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 13 : 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCashForm(PettyCashViewModel vm, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final dateLabel = DateFormat('dd MMM yyyy').format(vm.noCashDate);
    return Column(
      key: const ValueKey('no_cash_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          l10n.posPettyCashNoCashDetails,
          Icons.money_off_csred_outlined,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.posPettyCashDate),
                        _buildDateField(
                          label: dateLabel,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: vm.noCashDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                            );
                            if (picked != null) vm.setNoCashDate(picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.posPettyCashBillNo),
                        _buildTextField(
                          vm.noCashBillNoController,
                          l10n.posPettyCashBillNoHint,
                          Icons.receipt_outlined,
                          TextInputType.text,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.posPettyCashDepartmentName),
                        PosMenuDropdown<String>(
                          isTablet: isTablet,
                          searchable: true,
                          searchHint: l10n.posPettyCashSearchDepartment,
                          emptySearchLabel: l10n.posPettyCashNoDepartmentMatches,
                          placeholder: vm.noCashDepartmentsLoading
                              ? l10n.posPettyCashLoadingDepartments
                              : l10n.posPettyCashSelectDepartment,
                          prefixIcon: Icons.apartment_outlined,
                          value: vm.selectedNoCashDepartment?.id,
                          enabled: vm.noCashDepartments.isNotEmpty,
                          options: vm.noCashDepartments
                              .map(
                                (d) => PosMenuDropdownOption<String>(
                                  value: d.id,
                                  label: d.name,
                                  searchLabel: d.name,
                                ),
                              )
                              .toList(),
                          onChanged: vm.noCashDepartments.isEmpty
                              ? null
                              : (id) {
                                  Department? match;
                                  for (final d in vm.noCashDepartments) {
                                    if (d.id == id) {
                                      match = d;
                                      break;
                                    }
                                  }
                                  vm.setNoCashDepartment(match);
                                },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.posPettyCashExpenseList),
                        PosMenuDropdown<String>(
                          isTablet: isTablet,
                          searchable: true,
                          searchHint: l10n.posPettyCashSearchExpenseType,
                          emptySearchLabel: l10n.posPettyCashNoExpenseTypeMatches,
                          placeholder: l10n.posPettyCashSelectExpenseType,
                          prefixIcon: Icons.category_outlined,
                          value: vm.selectedNoCashExpenseType,
                          options: noCashExpenseTypes
                              .map(
                                (type) => PosMenuDropdownOption<String>(
                                  value: type,
                                  label: noCashExpenseTypeLabel(type, lang),
                                  searchLabel: noCashExpenseTypeLabel(type, lang),
                                ),
                              )
                              .toList(),
                          onChanged: vm.setNoCashExpenseType,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.posPettyCashSupplier),
                        _buildSupplierNameField(vm, isTablet),
                      ],
                    ),
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.posPettyCashAmountSar),
                        _buildTextField(
                          vm.noCashAmountController,
                          '0.00',
                          Icons.payments_outlined,
                          const TextInputType.numberWithOptions(decimal: true),
                          currencyPrefix: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildLabel(l10n.posPettyCashRemarks),
              _buildTextField(
                vm.noCashRemarksController,
                l10n.posPettyCashRemarksHint,
                Icons.notes,
                TextInputType.text,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildSectionTitle(
          l10n.posPettyCashPhotos,
          Icons.photo_library_outlined,
        ),
        const SizedBox(height: 8),
        _buildNoCashImagePicker(vm, isTablet),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: isTablet ? 44 : 40,
          child: ElevatedButton(
            onPressed: vm.isNoCashSubmitting
                ? null
                : () {
                    vm.submitNoCashAction((error) {
                      if (mounted) _showError(error);
                    }).then((success) {
                      if (success && mounted) {
                        ToastService.showSuccess(
                          context,
                          l10n.posPettyCashNoCashSubmittedPending,
                        );
                      }
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              disabledBackgroundColor: AppColors.secondaryLight,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
              shadowColor: AppColors.secondaryLight.withOpacity(0.4),
            ),
            child: vm.isNoCashSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        l10n.posPettyCashSubmitNoCash,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 13 : 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierNameField(PettyCashViewModel vm, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final radius = isTablet ? 10.0 : 9.0;
    return RawAutocomplete<PoAffiliatedSupplier>(
      textEditingController: vm.noCashOtherSupplierController,
      focusNode: _noCashSupplierFocus,
      displayStringForOption: (s) => s.supplierName,
      optionsBuilder: (tev) {
        final q = tev.text.trim().toLowerCase();
        if (q.isEmpty) return vm.noCashSuppliers;
        return vm.noCashSuppliers.where(
          (s) => s.supplierName.toLowerCase().contains(q),
        );
      },
      onSelected: vm.setNoCashSupplier,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return SizedBox(
          height: PosMenuDropdown.fieldHeight(tablet: isTablet),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: vm.onNoCashSupplierNameChanged,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) {},
            onSubmitted: (_) {
              onFieldSubmitted();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            decoration: InputDecoration(
              hintText: vm.noCashSuppliersLoading
                  ? l10n.posPettyCashLoadingSuppliers
                  : l10n.posPettyCashSelectSupplier,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: _fieldHintColor,
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.storefront_outlined,
                color: Colors.grey.shade400,
                size: isTablet ? 18 : 16,
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 10 : 8,
                vertical: isTablet ? 8 : 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(
                  color: AppColors.primaryLight,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final view = View.of(context);
        final kb = view.viewInsets.bottom / view.devicePixelRatio;
        final maxH = (view.physicalSize.height / view.devicePixelRatio - kb - 220)
            .clamp(120.0, 220.0);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxH,
                minWidth: 220,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option.supplierName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
  }) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final radius = isTablet ? 10.0 : 9.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: PosMenuDropdown.fieldHeight(tablet: isTablet),
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: isTablet ? 18 : 16,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isTablet ? 12 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCashImagePicker(PettyCashViewModel vm, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.noCashImages.isNotEmpty)
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.noCashImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        vm.noCashImages[index],
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => vm.removeNoCashImage(index),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (vm.noCashImages.isNotEmpty) const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showNoCashImageSourceSheet(vm),
          child: Container(
            height: 66,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DottedContainer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.secondaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.posPettyCashAddPhotos,
                    style: TextStyle(
                      color: AppColors.secondaryLight.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNoCashImageSourceSheet(PettyCashViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.secondaryLight,
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Open camera'),
              onTap: () {
                Navigator.pop(sheetContext);
                vm.addNoCashImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.secondaryLight,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Pick one or more photos'),
              onTap: () {
                Navigator.pop(sheetContext);
                vm.addNoCashImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm(PettyCashViewModel vm, bool isTablet) {
    return Column(
      key: const ValueKey('request_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          AppLocalizations.of(context)!.posPettyCashFundRequest,
          Icons.add_circle_outline_rounded,
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(
                AppLocalizations.of(context)!.posPettyCashRequestedAmountSar,
              ),
              _buildTextField(
                vm.requestAmountController,
                '0.00',
                Icons.payments_outlined,
                TextInputType.number,
                currencyPrefix: true,
              ),
              const SizedBox(height: 10),

              _buildLabel(
                AppLocalizations.of(context)!.posPettyCashReasonForRequest,
              ),
              _buildTextField(
                vm.reasonController,
                AppLocalizations.of(context)!.posPettyCashReasonHint,
                Icons.help_outline,
                TextInputType.text,
                maxLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: isTablet ? 44 : 40,
          child: ElevatedButton(
            onPressed: vm.isRequestSubmitting
                ? null
                : () {
                    vm.submitRequestAction(
                      (error) {
                        if (mounted) _showError(error);
                      },
                      () {
                        if (mounted)
                          ToastService.showSuccess(
                            context,
                            AppLocalizations.of(
                              context,
                            )!.posPettyCashFundRequestSubmittedPending,
                          );
                      },
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              disabledBackgroundColor: AppColors.secondaryLight,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
              shadowColor: AppColors.secondaryLight.withOpacity(0.4),
            ),
            child: vm.isRequestSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: isTablet ? 21 : 18),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.posPettyCashSubmitRequest,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 13 : 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: AppColors.secondaryLight.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2124),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDropdown(PettyCashViewModel vm, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return PosMenuDropdown<String>(
      isTablet: isTablet,
      searchable: true,
      searchHint: l10n.posPettyCashSearchCategory,
      emptySearchLabel: l10n.posPettyCashNoCategoryMatches,
      placeholder: l10n.posPettyCashSelectCategory,
      prefixIcon: Icons.category_outlined,
      value: vm.selectedCategory?.id,
      options: vm.expenseCategories
          .map(
            (cat) => PosMenuDropdownOption<String>(
              value: cat.id,
              label: _expenseCategoryLabel(cat.name),
              searchLabel: _expenseCategoryLabel(cat.name),
            ),
          )
          .toList(),
      onChanged: vm.expenseCategories.isEmpty
          ? null
          : (id) {
              ExpenseCategory? cat;
              for (final c in vm.expenseCategories) {
                if (c.id == id) {
                  cat = c;
                  break;
                }
              }
              vm.setCategory(cat);
            },
    );
  }

  Widget _buildEmployeeDropdown(PettyCashViewModel vm, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return PosMenuDropdown<String>(
      isTablet: isTablet,
      searchable: true,
      searchHint: l10n.posPettyCashSearchEmployee,
      emptySearchLabel: l10n.posPettyCashNoEmployeeMatches,
      placeholder: vm.branchEmployees.isEmpty
          ? l10n.posPettyCashNoEmployees
          : l10n.posPettyCashSelectEmployee,
      prefixIcon: Icons.person_outline_rounded,
      value: vm.selectedBranchEmployee?.id,
      enabled: vm.branchEmployees.isNotEmpty,
      options: vm.branchEmployees
          .map(
            (e) {
              final name = e.name.isNotEmpty ? e.name : e.id;
              final type = e.employeeTypeDisplay;
              final label = type.isEmpty ? name : '$name · $type';
              return PosMenuDropdownOption<String>(
                value: e.id,
                label: label,
                searchLabel: [
                  e.name,
                  e.mobile ?? '',
                  e.employeeType ?? '',
                  type,
                ].where((s) => s.trim().isNotEmpty).join(' '),
                child: LocalizedApiText(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          )
          .toList(),
      onChanged: vm.branchEmployees.isEmpty
          ? null
          : (id) {
              BranchEmployee? employee;
              for (final e in vm.branchEmployees) {
                if (e.id == id) {
                  employee = e;
                  break;
                }
              }
              vm.setBranchEmployee(employee);
            },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    TextInputType type, {
    int maxLines = 1,
    bool currencyPrefix = false,
  }) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final radius = isTablet ? 10.0 : 9.0;
    final singleLine = maxLines == 1;
    final fieldHeight = singleLine
        ? PosMenuDropdown.fieldHeight(tablet: isTablet)
        : null;

    final field = TextField(
      controller: controller,
      keyboardType: type,
      inputFormatters: currencyPrefix
          ? [
              EnglishNumberFormatter(),
              const DecimalQtyTextInputFormatter(maxFractionDigits: 2),
            ]
          : null,
      hintLocales: appKeyboardHintLocales(context),
      maxLines: maxLines,
      textInputAction: TextInputAction.done,
      onTapOutside: (_) {},
      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      scrollPadding: EdgeInsets.fromLTRB(12, 12, 12, kb + 100),
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: isTablet ? 12 : 11,
        fontWeight: FontWeight.w600,
        height: singleLine ? 1.1 : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: _fieldHintColor,
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: currencyPrefix
            ? Padding(
                padding: EdgeInsets.only(
                  left: isTablet ? 10 : 8,
                  right: isTablet ? 4 : 2,
                ),
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  child: Text(
                    'SAR',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight.withValues(alpha: 0.62),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              )
            : Icon(
                icon,
                color: Colors.grey.shade400,
                size: isTablet ? 18 : 16,
              ),
        prefixIconConstraints: currencyPrefix
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 10 : 8,
          vertical: singleLine ? (isTablet ? 8 : 7) : (isTablet ? 10 : 8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );

    if (fieldHeight == null) return field;
    return SizedBox(height: fieldHeight, child: field);
  }

  String _expenseCategoryLabel(String name) =>
      pettyCashExpenseCategoryLabel(
        name,
        Localizations.localeOf(context).languageCode,
      );

  String _historyStatusLabel(String key) {
    switch (key) {
      case 'all':
        return AppLocalizations.of(context)!.posCommonAll;
      case 'pending':
        return AppLocalizations.of(context)!.posCommonPending;
      case 'approved':
        return AppLocalizations.of(context)!.posCommonApproved;
      case 'rejected':
        return AppLocalizations.of(context)!.posCommonRejected;
      default:
        return key;
    }
  }

  Future<void> _pickHistoryFromDate(PettyCashViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.expenseHistoryFromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    vm.setExpenseHistoryDateRange(from: picked, to: vm.expenseHistoryToDate);
  }

  Future<void> _pickHistoryToDate(PettyCashViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.expenseHistoryToDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    vm.setExpenseHistoryDateRange(from: vm.expenseHistoryFromDate, to: picked);
  }

  List<PosMenuDropdownOption<String>> _historyStatusOptions() {
    const statusKeys = ['all', 'pending', 'approved', 'rejected'];
    return statusKeys
        .map(
          (k) => PosMenuDropdownOption<String>(
            value: k,
            label: _historyStatusLabel(k),
          ),
        )
        .toList();
  }

  List<PosMenuDropdownOption<String?>> _historyCategoryOptions(PettyCashViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PosMenuDropdownOption<String?>(
        value: null,
        label: l10n.posPettyCashAllCategories,
      ),
      ...vm.expenseCategories.map(
        (c) => PosMenuDropdownOption<String?>(
          value: c.id,
          label: _expenseCategoryLabel(c.name),
        ),
      ),
    ];
  }

  Widget _buildHistoryFilters(PettyCashViewModel vm, bool isTablet) {
    String fmt(DateTime? d) => d == null
        ? AppLocalizations.of(context)!.posCommonSelectDate
        : DateFormat('yyyy-MM-dd').format(d);

    final radius = isTablet ? 10.0 : 9.0;
    final fieldHeight = PosMenuDropdown.fieldHeight(tablet: isTablet, compact: true);

    Widget filterField({
      required IconData icon,
      required String text,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: fieldHeight,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, size: isTablet ? 16 : 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isTablet ? 11 : 10,
                      color: _fieldHintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: isTablet ? 16 : 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget dateField({
      required String prefix,
      required DateTime? value,
      required VoidCallback onTap,
    }) {
      return filterField(
        icon: Icons.calendar_today_outlined,
        text: '$prefix ${fmt(value)}',
        onTap: onTap,
      );
    }

    final hasFilters =
        vm.expenseHistoryFromDate != null ||
        vm.expenseHistoryToDate != null ||
        vm.expenseHistoryCategoryId != null ||
        vm.expenseHistoryStatusFilter != 'all';

    return Container(
      padding: EdgeInsets.all(isTablet ? 10 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 18,
            child: dateField(
              prefix: AppLocalizations.of(context)!.posCommonFrom,
              value: vm.expenseHistoryFromDate,
              onTap: () => _pickHistoryFromDate(vm),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 18,
            child: dateField(
              prefix: AppLocalizations.of(context)!.posCommonTo,
              value: vm.expenseHistoryToDate,
              onTap: () => _pickHistoryToDate(vm),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 22,
            child: PosMenuDropdown<String?>(
              isTablet: isTablet,
              compact: true,
              placeholder: AppLocalizations.of(context)!.posPettyCashAllCategories,
              prefixIcon: Icons.category_outlined,
              value: vm.expenseHistoryCategoryId,
              options: _historyCategoryOptions(vm),
              onChanged: vm.setExpenseHistoryCategoryId,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 18,
            child: PosMenuDropdown<String>(
              isTablet: isTablet,
              compact: true,
              placeholder: AppLocalizations.of(context)!.posCommonAll,
              prefixIcon: Icons.flag_outlined,
              value: vm.expenseHistoryStatusFilter,
              options: _historyStatusOptions(),
              onChanged: (value) {
                if (value != null) vm.setExpenseHistoryStatusFilter(value);
              },
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: vm.clearExpenseHistoryFilters,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.posCommonReset,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseHistoryTab(PettyCashViewModel vm, bool isTablet) {
    return Column(
      key: const ValueKey('expense_history_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          AppLocalizations.of(context)!.posPettyCashExpenseFundHistory,
          Icons.history_rounded,
        ),
        const SizedBox(height: 8),
        _buildHistoryFilters(vm, isTablet),
        const SizedBox(height: 10),
        _buildExpenseHistoryListBody(vm, isTablet),
      ],
    );
  }

  String _historyFormattedDate(DateTime? date) {
    if (date == null) return '—';
    final lang = Localizations.localeOf(context).languageCode;
    return DateFormat(
      'MMM dd, yyyy • hh:mm a',
      lang == 'ar' ? 'ar' : 'en',
    ).format(date.toLocal());
  }

  ({Color background, Color foreground}) _historyStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (
          background: const Color(0xFFEA580C),
          foreground: Colors.white,
        );
      case 'approved':
        return (
          background: const Color(0xFF15803D),
          foreground: Colors.white,
        );
      case 'rejected':
        return (
          background: const Color(0xFFB42318),
          foreground: Colors.white,
        );
      default:
        return (
          background: Colors.grey.shade700,
          foreground: Colors.white,
        );
    }
  }

  Widget _buildExpenseHistoryListBody(
    PettyCashViewModel vm,
    bool isTablet,
  ) {
    if (vm.expenseHistoryLoading && vm.expenseHistory.isEmpty) {
      return _PettyCashHistoryShimmer(isTablet: isTablet);
    }

    if (vm.expenseHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.posPettyCashNoHistoryForFilter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final columns = isTablet ? (isLandscape ? 3 : 2) : 1;
    final cardExtent = isTablet ? (isLandscape ? 124.0 : 128.0) : 112.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: cardExtent,
          ),
          itemCount: vm.expenseHistory.length,
          itemBuilder: (_, index) =>
              _buildHistoryCard(vm.expenseHistory[index], isTablet),
        ),
        if (vm.expenseHistoryHasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: vm.expenseHistoryLoading
                  ? const PosShimmer(
                      child: PosShimmerBox(width: 42, height: 14, radius: 7),
                    )
                  : TextButton(
                      onPressed: () =>
                          vm.fetchExpenseHistory(refresh: false),
                      child: Text(
                        AppLocalizations.of(context)!.posPettyCashLoadMore,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(CashierExpenseHistoryEntry e, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final st = e.status.toLowerCase();
    final statusLabel = _historyStatusLabel(st);
    final statusColors = _historyStatusColors(st);

    final kind = e.kind.toLowerCase();
    final isFund = kind.contains('fund');
    final kindBadge = e.kind.toLowerCase() == 'no_cash'
        ? 'NON CASH'
        : e.kind.replaceAll('_', ' ').toUpperCase();
    final title = (e.category ?? '').trim().isNotEmpty
        ? _expenseCategoryLabel(e.category!)
        : (isFund ? l10n.posPettyCashFundRequest : l10n.posPettyCashExpenseDetails);
    final formattedDate = _historyFormattedDate(e.createdAt);

    final footerText = (e.rejectionReason ?? '').trim().isNotEmpty
        ? e.rejectionReason!.trim()
        : (e.description ?? '').trim();
    final hasFooter = footerText.isNotEmpty;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 10 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      kindBadge,
                      style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColors.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Icon(
                        isFund
                            ? Icons.account_balance_wallet_outlined
                            : Icons.receipt_long_rounded,
                        color: AppColors.secondaryLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isLandscape ? 12 : 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D3139),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isLandscape ? 10 : 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((e.employeeName ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${l10n.posPettyCashEmployeePrefix} ${e.employeeName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isLandscape ? 9.5 : 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if ((st == 'approved' || st == 'rejected') &&
                              (e.approvedBy ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              st == 'approved'
                                  ? 'Approved by ${e.approvedBy!.trim()} · ${e.approvedByRoleLabel ?? 'Admin'}'
                                  : 'Rejected by ${e.approvedBy!.trim()} · ${e.approvedByRoleLabel ?? 'Admin'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isLandscape ? 9 : 9.5,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.posPettyCashAmountSar,
                          style: TextStyle(
                            fontSize: isLandscape ? 8.5 : 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyHelper.format(context, e.amount),
                          style: TextStyle(
                            fontSize: isLandscape ? 13 : 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasFooter) ...[
                SizedBox(height: isLandscape ? 4 : 5),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: LocalizedApiText(
                        footerText,
                        style: TextStyle(
                          fontSize: isLandscape ? 9.5 : 10.5,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(PettyCashViewModel vm) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(vm),
      child: Container(
        height: 66,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: vm.selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(vm.selectedImage!, fit: BoxFit.cover),
              )
            : DottedContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.secondaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.posPettyCashTapUploadReceipt,
                      style: TextStyle(
                        color: AppColors.secondaryLight.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showImageSourceSheet(PettyCashViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.secondaryLight),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Open camera'),
              onTap: () {
                Navigator.pop(sheetContext);
                vm.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.secondaryLight),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Pick an existing photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                vm.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingStatusCard(FundRequest request, bool isTablet) {
    return Container(
      key: const ValueKey('pending_request_card'),
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                AppLocalizations.of(context)!.posPettyCashRequestStatus,
                Icons.info_outline,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.posCommonPending.toUpperCase(),
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            Icons.account_balance_wallet_outlined,
            AppLocalizations.of(context)!.posPettyCashRequestedAmount,
            CurrencyHelper.format(context, request.amount),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.help_outline,
            AppLocalizations.of(context)!.posPettyCashReason,
            request.reason,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            AppLocalizations.of(context)!.posPettyCashRequestDate,
            '${request.date.day}/${request.date.month}/${request.date.year}',
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.posPettyCashPendingExplanation,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => context
                  .read<PettyCashViewModel>()
                  .setShowPendingRequestStatus(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.posPettyCashSubmitNewRequest,
                style: TextStyle(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryLight.withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.secondaryLight.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PettyCashLoadingShimmer extends StatelessWidget {
  const _PettyCashLoadingShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isTablet ? 10 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 8),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const PosShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(width: 118, height: 20, radius: 8, dark: true),
                  SizedBox(height: 10),
                  PosShimmerLine(width: 150, height: 10, dark: true),
                  SizedBox(height: 6),
                  PosShimmerLine(width: 98, height: 22, radius: 10, dark: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: PosShimmer(
              child: Row(
                children: [
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: isTablet ? 42 : 38,
                      radius: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: isTablet ? 42 : 38,
                      radius: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: isTablet ? 42 : 38,
                      radius: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: PosShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PosShimmerLine(width: 140, height: 12),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PosShimmerBox(
                          width: double.infinity,
                          height: isTablet ? 42 : 38,
                          radius: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PosShimmerBox(
                          width: double.infinity,
                          height: isTablet ? 42 : 38,
                          radius: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PosShimmerBox(
                    width: double.infinity,
                    height: isTablet ? 62 : 56,
                    radius: 10,
                  ),
                  const SizedBox(height: 12),
                  PosShimmerBox(
                    width: double.infinity,
                    height: isTablet ? 42 : 38,
                    radius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PettyCashHistoryShimmer extends StatelessWidget {
  const _PettyCashHistoryShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? (isLandscape ? 3 : 2) : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: isTablet ? (isLandscape ? 124.0 : 128.0) : 112.0,
      ),
      itemCount: isTablet ? 6 : 4,
      itemBuilder: (_, __) => Container(
        padding: EdgeInsets.all(isTablet ? 7 : 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const PosShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PosShimmerBox(width: 72, height: 18, radius: 8),
                  Spacer(),
                  PosShimmerBox(width: 56, height: 18, radius: 8),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  PosShimmerBox(width: 30, height: 30, radius: 9),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosShimmerLine(width: double.infinity, height: 12),
                        SizedBox(height: 5),
                        PosShimmerLine(width: 108, height: 9),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              PosShimmerLine(width: 112, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
