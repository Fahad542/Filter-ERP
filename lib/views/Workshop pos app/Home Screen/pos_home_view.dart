import 'dart:async';
import 'package:flutter/material.dart';
import '../../../utils/app_arabic_font_fallbacks.dart';
import 'package:provider/provider.dart';
import '../../../services/cashier_open_session_guard.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../Add Customer Screen/pos_add_customer_view.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../utils/app_formatters.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../utils/toast_service.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../services/session_service.dart';
import '../../../models/customer_search_model.dart';
import '../../../models/create_invoice_model.dart';
import '../../../models/invoiced_orders_model.dart';
import 'package:http/http.dart' as http;

import '../../../data/network/api_constants.dart';
import '../../../services/invoice_auto_dispatch.dart';
import '../../../services/whatsapp_invoice_share.dart';
import '../../../services/invoice_dialog_launcher.dart';
import '../Sales Return/sales_return_view_model.dart';
import '../Sales Return/pos_sales_return_view.dart';
import 'pos_view_model.dart';
import '../Corporate Bookings/pos_corporate_bookings_view.dart';
import '../Promo/promo_view_model.dart';
import '../Promo/promo_promotion_card.dart' show showPromoDetailsDialog;

/// Push a screen from POS Home and reset the home search when the user returns.
Future<T?> pushFromPosHome<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(
    context,
    MaterialPageRoute(builder: (_) => page),
  ).whenComplete(() {
    if (context.mounted) {
      context.read<PosViewModel>().clearHomeSearch();
    }
  });
}

/// Sales returns are branch-scoped even when customer history is project-wide.
const kPosSalesReturnWrongBranchMessage =
    'This order does not belong to your branch.';

Future<bool> _salesReturnAllowedForOrder(
  BuildContext context,
  SearchedCustomerOrder? order,
) async {
  if (order == null) return true;
  final orderBranchId = (order.branchId ?? '').trim();
  if (orderBranchId.isEmpty) return true;

  final user = await context.read<SessionService>().getUser();
  final cashierBranchId = user?.branchId?.trim() ?? '';
  if (cashierBranchId.isEmpty) return true;

  if (orderBranchId != cashierBranchId) {
    if (context.mounted) {
      ToastService.showError(context, kPosSalesReturnWrongBranchMessage);
    }
    return false;
  }
  return true;
}

/// Open Sales Return immediately; resolve invoice number in the background when missing.
Future<void> openSalesReturnFromPosHome(
  BuildContext context, {
  SearchedCustomerOrder? latestOrder,
  SearchedCustomer? customer,
}) async {
  if (!await _salesReturnAllowedForOrder(context, latestOrder)) {
    return;
  }

  final returnVm = context.read<SalesReturnViewModel>();
  final posVm = context.read<PosViewModel>();
  returnVm.clearSearchResults();

  final orderId = (latestOrder?.id ?? '').trim();
  var invoiceNo = (latestOrder?.invoiceNo ?? '').trim();

  if (invoiceNo.isEmpty && orderId.isNotEmpty) {
    invoiceNo = posVm.invoiceNoForOrder(orderId) ?? '';
  }
  if (invoiceNo.isEmpty && customer != null) {
    for (final o in customer.orders) {
      final inv = (o.invoiceNo ?? '').trim();
      if (orderId.isNotEmpty && o.id == orderId && inv.isNotEmpty) {
        invoiceNo = inv;
        break;
      }
    }
    if (invoiceNo.isEmpty) {
      for (final o in customer.orders) {
        final inv = (o.invoiceNo ?? '').trim();
        if (inv.isNotEmpty) {
          invoiceNo = inv;
          break;
        }
      }
    }
  }

  if (invoiceNo.isNotEmpty) {
    returnVm.searchController.value = TextEditingValue(
      text: invoiceNo,
      selection: TextSelection.collapsed(offset: invoiceNo.length),
    );
  } else {
    returnVm.searchController.clear();
  }

  unawaited(
    pushFromPosHome(
      context,
      const PosSalesReturnView(showBackButton: true),
    ),
  );

  if (invoiceNo.isNotEmpty) {
    unawaited(returnVm.searchInvoice());
  } else if (orderId.isNotEmpty) {
    unawaited(_resolveAndSearchSalesReturnInvoice(context, orderId));
  }
}

Future<void> _resolveAndSearchSalesReturnInvoice(
  BuildContext context,
  String orderId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final returnVm = context.read<SalesReturnViewModel>();
  try {
    final token = await context.read<SessionService>().getToken();
    if (token == null) throw Exception('Token not found');
    final response = await context
        .read<PosRepository>()
        .getInvoiceByOrder(orderId, token);
    if (!context.mounted) return;
    final invoiceNo = (response.invoice?.invoiceNo ?? '').trim();
    if (invoiceNo.isEmpty) {
      ToastService.showError(context, l10n.posCustomerInvoiceLoadError);
      return;
    }
    returnVm.searchController.value = TextEditingValue(
      text: invoiceNo,
      selection: TextSelection.collapsed(offset: invoiceNo.length),
    );
    await returnVm.searchInvoice();
  } catch (_) {
    if (context.mounted) {
      ToastService.showError(context, l10n.posCustomerInvoiceLoadError);
    }
  }
}

class PosHomeView extends StatefulWidget {
  const PosHomeView({super.key});

  @override
  State<PosHomeView> createState() => _PosHomeViewState();
}

class _PosHomeViewState extends State<PosHomeView>
    with SingleTickerProviderStateMixin {
  // ── Animation ─────────────────────────────────────────────────────────────
  // One AnimationController drives both FadeTransition and SizeTransition.
  // FadeTransition is GPU-composited (no layout pass per frame).
  // SizeTransition reclaims the space so search results expand naturally.
  // 220 ms matches the typical Android soft-keyboard slide duration.
  late final AnimationController _headerAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1.0, // start fully visible
  );
  late final Animation<double> _headerFade = CurvedAnimation(
    parent: _headerAnim,
    curve: Curves.easeInOut,
  );
  late final PageController _promoPageController = PageController();
  Timer? _promoAutoSlide;
  int _promoPageIndex = 0;

  bool _keyboardWasOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        CashierOpenSessionGuard.instance.ensureOpenOrSignOut(context: context),
      );
      unawaited(context.read<PromoViewModel>().ensurePromoCatalogLoaded());
      _startPromoAutoSlide();
    });
  }

  void _startPromoAutoSlide() {
    _promoAutoSlide?.cancel();
    _promoAutoSlide = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final promos = context.read<PromoViewModel>().availablePromotions;
      if (promos.length < 2 || !_promoPageController.hasClients) return;
      final next = (_promoPageIndex + 1) % promos.length;
      _promoPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _promoAutoSlide?.cancel();
    _promoPageController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Drive animation from MediaQuery — no setState, only AnimationController.
    // This means zero extra widget-tree rebuilds from keyboard changes.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardOpen == _keyboardWasOpen) return;
    _keyboardWasOpen = keyboardOpen;
    if (keyboardOpen) {
      _headerAnim.reverse(); // hide header
    } else {
      _headerAnim.forward(); // restore header
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final vm = context.watch<PosViewModel>();
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: PosTabletLayout.textScaler(context)),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        appBar: PosAppBar(
          userName: vm.cashierName,
          infoTitle: vm.workshopName,
          infoBranch: l10n.posHomeBranchPrefix(vm.branchName),
          infoTime: AppTranslationService.localizeDigitsForLanguage(
            DateFormat(
              'dd MMM yyyy · hh:mm a',
              langCode,
            ).format(DateTime.now()),
            langCode,
          ),
          onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: wrapPosShellRailBody(
                context,
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {},
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.only(top: keyboardOpen ? 8 : 0),
                          child: const SizedBox.shrink(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 18,
                          ),
                          child: Column(
                            children: [
                              FadeTransition(
                                opacity: _headerFade,
                                child: SizeTransition(
                                  sizeFactor: _headerFade,
                                  axisAlignment: -1,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: langCode == 'ar'
                                          ? (isTablet ? 14 : 12)
                                          : (isTablet ? 12 : 10),
                                      bottom: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        alignPosBodyToAppBarCenter(
                                          context,
                                          SizedBox(
                                            width: double.infinity,
                                            child: _buildHomeTitle(
                                              l10n,
                                              langCode,
                                              isTablet,
                                            ),
                                          ),
                                        ),
                                        _buildHomePromoSlider(
                                          context,
                                          isTablet,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _buildCustomerHistorySearchBar(
                                context,
                                vm,
                                l10n,
                              ),
                              _buildCustomerHistorySuggestions(context, vm),
                              FadeTransition(
                                opacity: _headerFade,
                                child: SizeTransition(
                                  sizeFactor: _headerFade,
                                  axisAlignment: -1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2,
                                      bottom: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildActionChip(
                                          context: context,
                                          icon: Icons.add,
                                          label: l10n.posHomeNewWalkIn,
                                          onTap: () {
                                            context
                                                .read<PosViewModel>()
                                                .clearCustomerData();
                                            pushFromPosHome(
                                              context,
                                              const PosAddCustomerView(
                                                initialTab: 0,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActionChip(
                                          context: context,
                                          icon: Icons.business,
                                          label: l10n.posHomeCorporateBooking,
                                          onTap: () {
                                            pushFromPosHome(
                                              context,
                                              const PosCorporateBookingsView(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (vm.homeCustomerSearchActive)
                        ..._buildSearchResultSlivers(context, isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHistorySuggestions(
    BuildContext context,
    PosViewModel vm,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final suggestions = vm.homeSearchSuggestions;
    if (suggestions.isEmpty && !vm.isSuggestingCustomer) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 248),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: vm.isSuggestingCustomer && suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                ),
                itemBuilder: (context, index) {
                  final customer = suggestions[index];
                  final plate = (customer.vehicleSnapshot?.resolvedPlate ?? '')
                      .trim();
                  final plateDisplay = plate.isEmpty
                      ? ''
                      : formatVehiclePlateLettersFirst(plate);
                  final subtitleParts = <String>[
                    if (customer.mobile.trim().isNotEmpty) customer.mobile.trim(),
                    if (plateDisplay.isNotEmpty) plateDisplay,
                  ];
                  return InkWell(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      vm.selectHomeSearchSuggestion(customer);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.16,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_search_rounded,
                              size: 18,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name.trim().isEmpty
                                      ? (isAr ? 'عميل' : 'Customer')
                                      : customer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                if (subtitleParts.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitleParts.join('  •  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.south_west_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHomeTitle(
    AppLocalizations l10n,
    String langCode,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: l10n.posHomeTitleFilter,
                style: langCode == 'ar'
                    ? appArabicTextStyle(
                        color: AppColors.primaryLight,
                        fontSize: isTablet ? 26 : 24,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      )
                    : AppTextStyles.h1.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: isTablet ? 26 : 24,
                        fontWeight: FontWeight.w700,
                      ),
              ),
              TextSpan(
                text: langCode == 'ar'
                    ? ' ${l10n.posHomeTitlePos}'
                    : l10n.posHomeTitlePos,
                style: langCode == 'ar'
                    ? appArabicTextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: isTablet ? 26 : 24,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      )
                    : AppTextStyles.h1.copyWith(
                        color: AppColors.secondaryLight,
                        fontSize: isTablet ? 26 : 24,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.posHomeSubtitle,
          style: langCode == 'ar'
              ? appArabicTextStyle(
                  color: Colors.grey,
                  fontSize: 12.5,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                )
              : AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                  fontSize: 12.5,
                  height: 1.1,
                ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildHomePromoSlider(BuildContext context, bool isTablet) {
    return Consumer<PromoViewModel>(
      builder: (context, promoVm, _) {
        if (promoVm.isLoadingPromos && promoVm.availablePromotions.isEmpty) {
          final height = isTablet ? 164.0 : 142.0;
          return SizedBox(
            height: height,
            width: double.infinity,
            child: const PosShimmer(
              child: SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                ),
              ),
            ),
          );
        }

        final promos = promoVm.availablePromotions;
        if (promos.isEmpty) {
          return const SizedBox.shrink();
        }

        final overflowTop = isTablet ? 22.0 : 18.0;
        final cardHeight = isTablet ? 138.0 : 122.0;
        return Column(
          children: [
            SizedBox(
              height: overflowTop + cardHeight,
              width: double.infinity,
              child: PageView.builder(
                controller: _promoPageController,
                clipBehavior: Clip.none,
                itemCount: promos.length,
                onPageChanged: (index) {
                  setState(() => _promoPageIndex = index);
                },
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  return _HomePromoBanner(
                    promo: promo,
                    isTablet: isTablet,
                    overflowTop: overflowTop,
                    onTap: () => showPromoDetailsDialog(context, promo),
                  );
                },
              ),
            ),
            if (promos.length > 1) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(promos.length, (index) {
                  final active = index == _promoPageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.secondaryLight
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _runExactCustomerSearch(BuildContext context, PosViewModel vm) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final ok = await vm.searchCustomerHistoryExact();
    if (!context.mounted) return;
    if (ok) return;
    final hint = vm.errorMessage;
    if (hint == 'incomplete_mobile') {
      ToastService.showError(
        context,
        isAr
            ? 'يرجى إدخال رقم الجوال كاملاً'
            : 'Enter the full mobile number',
      );
    } else if (hint == 'incomplete_plate') {
      ToastService.showError(
        context,
        isAr
            ? 'يرجى إدخال رقم اللوحة كاملاً'
            : 'Enter the full vehicle plate',
      );
    } else if (hint == 'incomplete_name') {
      ToastService.showError(
        context,
        isAr
            ? 'يرجى إدخال اسم العميل (حرفان على الأقل)'
            : 'Enter at least 2 letters of the customer name',
      );
    } else {
      ToastService.showError(
        context,
        isAr
            ? 'يرجى إدخال اسم العميل أو رقم الجوال أو اللوحة'
            : 'Enter a customer name, mobile, or plate number',
      );
    }
  }

  Widget _buildCustomerHistorySearchBar(
    BuildContext context,
    PosViewModel vm,
    AppLocalizations l10n,
  ) {
    return PosWorkshopSearchBar(
      controller: vm.homeSearchController,
      focusNode: vm.homeSearchFocusNode,
      hintText: l10n.posHomeSearchHint,
      inputFormatters: [EnglishNumberFormatter()],
      onChanged: vm.handleSearchDebounce,
      onSubmitted: (_) => _runExactCustomerSearch(context, vm),
      onClear: vm.clearHomeSearch,
    );
  }

  List<Widget> _buildSearchResultSlivers(BuildContext context, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<PosViewModel>();
    final hPad = EdgeInsets.symmetric(horizontal: isTablet ? 18 : 16);

        if (vm.isSearchingCustomer) {
          return [
            _CustomerSearchShimmerList(
              isTablet: isTablet,
              padding: hPad,
            ),
          ];
        }

        if (vm.homeSearchApplied && vm.homeInvoiceRows.isNotEmpty) {
          final langCode = Localizations.localeOf(context).languageCode;
          final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          Widget buildInvoiceCard(int index) {
            final row = vm.homeInvoiceRows[index];
            final customer = row.customer;
            final order = row.order;
            final make = (order.vehicleMake ?? '').trim();
            final model = (order.vehicleModel ?? '').trim();
            final plateRaw = (order.plateNumber ?? '').trim();
            final rawVehicle = (make.isNotEmpty || model.isNotEmpty)
                ? '$make $model'.trim()
                : l10n.posHomeNoVehicle;
            final plateDisplay = plateRaw.isEmpty
                ? l10n.posCommonNotAvailable
                : formatVehiclePlateLettersFirst(plateRaw);
            final rawStatus = order.status.trim().isEmpty
                ? l10n.posCommonNotAvailable
                : order.status.toUpperCase();

            return PosTranslatedSearchHistoryItem(
              shrinkWrap: true,
              langCode: langCode,
              rawVehicle: rawVehicle,
              plate: plateDisplay,
              rawCustomer: order.customerName.trim().isNotEmpty
                  ? order.customerName
                  : customer.name,
              phone: customer.mobile,
              lastVisit: AppTranslationService.localizeDigitsForLanguage(
                vm.formatDate(order.createdAt),
                langCode,
              ),
              rawLastService: rawStatus,
              technicianName: () {
                if (order.technicianDisplay.trim().isNotEmpty) {
                  return order.technicianDisplay;
                }
                for (final o in customer.orders) {
                  if (o.id == order.id && o.technicianDisplay.trim().isNotEmpty) {
                    return o.technicianDisplay;
                  }
                }
                return langCode == 'ar'
                    ? 'لا يوجد فني معين'
                    : 'No technician assigned';
              }(),
              orderNumber: order.id,
              isCorporate: customer.customerType.toLowerCase() == 'corporate',
              onContinue: () {
                final posVm = context.read<PosViewModel>();
                final isCorporateCustomer =
                    customer.customerType.toLowerCase() == 'corporate';
                posVm.clearCart();
                posVm.clearEditOrderContext(notify: false);
                posVm.setCustomerData(
                  name: customer.name,
                  vat: customer.taxId ?? '',
                  mobile: customer.mobile,
                  vehicleNumber: plateRaw,
                  vinNumber: '',
                  make: make,
                  model: model,
                  odometer: 0,
                  previousOrderId: order.id,
                  vehicleYear: '',
                );
                pushFromPosHome(
                  context,
                  PosAddCustomerView(
                    initialTab: isCorporateCustomer ? 1 : 0,
                  ),
                );
              },
              onPrintInvoice: () => _printHomeInvoice(
                context,
                customer: customer,
                order: order,
              ),
              onDownloadInvoice: () => _sendHomeInvoiceWhatsApp(
                context,
                customer: customer,
                order: order,
              ),
              onSeeInvoiceDetails: () => _showHomeInvoiceDetails(
                context,
                customer: customer,
                order: order,
              ),
              onSalesReturn: () => openSalesReturnFromPosHome(
                context,
                latestOrder: SearchedCustomerOrder(
                  id: order.id,
                  status: order.status,
                  source: 'history',
                  odometerReading: 0,
                  createdAt: order.createdAt,
                  invoiceNo: order.invoiceNo,
                  branchId: order.branchId,
                  branchName: order.branchName,
                  workshopId: order.workshopId,
                  workshopName: order.workshopName,
                  technicianNames: order.technicianNames,
                ),
                customer: customer,
              ),
            );
          }

          final availableW = MediaQuery.sizeOf(context).width -
              (isTablet ? 36 : 32) -
              PosShellRailLayout.bodyRailOf(context);
          final crossAxisCount = !isTablet
              ? 1
              : availableW >= 980
              ? 3
              : availableW >= 640
              ? 2
              : 1;
          final gap = keyboardOpen ? 7.0 : 9.0;

              final heading = Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 0 : 5,
                  keyboardOpen ? 2 : 6,
                  isTablet ? 0 : 5,
                  keyboardOpen ? 6 : 10,
                ),
                child: Text(
                  l10n.posHomeSearchResults,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: keyboardOpen
                        ? (isTablet ? 13 : 11.5)
                        : (isTablet ? 14.5 : 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              );

              Widget buildGrid() {
                if (crossAxisCount == 1) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: gap),
                        child: buildInvoiceCard(index),
                      ),
                      childCount: vm.homeInvoiceRows.length,
                    ),
                  );
                }
                final rows = vm.homeInvoiceRows;
                final rowCount = (rows.length / crossAxisCount).ceil();
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, rowIndex) {
                    final start = rowIndex * crossAxisCount;
                    final end = (start + crossAxisCount).clamp(
                      0,
                      rows.length,
                    );
                    final indices = List.generate(
                      end - start,
                      (i) => start + i,
                    );
                    return Padding(
                      padding: EdgeInsets.only(bottom: gap),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < indices.length; i++) ...[
                              if (i > 0) SizedBox(width: gap),
                              Expanded(child: buildInvoiceCard(indices[i])),
                            ],
                            for (
                              int i = indices.length;
                              i < crossAxisCount;
                              i++
                            ) ...[
                              SizedBox(width: gap),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ],
                        ),
                      ),
                    );
                  }, childCount: rowCount),
                );
              }

          return [
            SliverPadding(
              padding: hPad,
              sliver: SliverToBoxAdapter(child: heading),
            ),
            SliverPadding(
              padding: hPad.copyWith(bottom: keyboardOpen ? 16 : 20),
              sliver: buildGrid(),
            ),
          ];
        }

        if (vm.homeSearchApplied &&
            vm.homeSearchController.text.trim().isNotEmpty &&
            !vm.isSearchingCustomer) {
          return [
            SliverPadding(
              padding: hPad.add(const EdgeInsets.symmetric(vertical: 16)),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_outlined,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.posHomeNoResults,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.posHomeNoResultsHint,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        return const [];
  }

  Future<void> _printHomeInvoice(
    BuildContext context, {
    required SearchedCustomer customer,
    required InvoicedOrder order,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final posVm = context.read<PosViewModel>();
    final response = await posVm.fetchInvoiceByOrder(order.id);
    if (!context.mounted) return;
    if (response != null &&
        response.success &&
        response.invoice != null) {
      final inv = invoiceWithMergedCustomerTax(
        response.invoice!,
        customer.taxId,
      );
      InvoiceAutoDispatch.dispatchPrintOnly(
        invoice: inv,
        paymentMethodText: invoiceDialogPaymentMethodText(inv),
      );
      ToastService.showSuccess(
        context,
        isAr
            ? 'جارٍ إرسال الفاتورة للطابعة…'
            : 'Sending invoice to printer…',
      );
      return;
    }
    ToastService.showError(
      context,
      response?.message.isNotEmpty == true
          ? response!.message
          : AppLocalizations.of(context)!.posCustomerInvoiceLoadError,
    );
  }

  Future<void> _showHomeInvoiceDetails(
    BuildContext context, {
    required SearchedCustomer customer,
    required InvoicedOrder order,
  }) async {
    final posVm = context.read<PosViewModel>();
    final response = await posVm.fetchInvoiceByOrder(order.id);
    if (!context.mounted) return;
    if (response == null || !response.success || response.invoice == null) {
      ToastService.showError(
        context,
        response?.message.isNotEmpty == true
            ? response!.message
            : AppLocalizations.of(context)!.posCustomerInvoiceLoadError,
      );
      return;
    }
    final inv = invoiceWithMergedCustomerTax(
      response.invoice!,
      customer.taxId,
    );
    if (!context.mounted) return;
    final paymentText = invoiceDialogPaymentMethodText(inv);
    await showInvoiceDialogAfterPrintPrefetch(
      context: context,
      invoice: inv,
      paymentMethodText: paymentText,
      barrierDismissible: true,
      builder: (ctx) => InvoiceDialog(
        invoice: inv,
      ),
    );
  }

  Future<WhatsAppClientApp?> _pickWhatsAppClient(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return showDialog<WhatsAppClientApp>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'إرسال عبر واتساب' : 'Send via WhatsApp',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'أي تطبيق واتساب تريد استخدامه؟ سيتم إرسال ملف PDF للفاتورة إلى رقم العميل.'
                      : 'Which WhatsApp app should send it? The invoice PDF will go to the customer’s number.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, WhatsAppClientApp.personal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.secondaryLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAr ? 'واتساب' : 'WhatsApp',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, WhatsAppClientApp.business),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAr ? 'واتساب للأعمال' : 'WhatsApp Business',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      isAr ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Public `/pdf` the old customer-history WhatsApp message linked to.
  String? _legacyPublicInvoicePdfUrl(Invoice invoice) {
    final publicUrl = invoice.publicInvoiceUrl?.trim();
    if (publicUrl != null &&
        publicUrl.isNotEmpty &&
        (publicUrl.startsWith('http://') || publicUrl.startsWith('https://'))) {
      return publicUrl.endsWith('/pdf')
          ? publicUrl
          : '${publicUrl.replaceAll(RegExp(r'/+$'), '')}/pdf';
    }
    final publicPath = invoice.publicInvoicePath?.trim();
    if (publicPath == null || publicPath.isEmpty) return null;
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = publicPath.startsWith('/') ? publicPath : '/$publicPath';
    return path.endsWith('/pdf') ? '$base$path' : '$base$path/pdf';
  }

  Future<void> _sendHomeInvoiceWhatsApp(
    BuildContext context, {
    required SearchedCustomer customer,
    required InvoicedOrder order,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final app = await _pickWhatsAppClient(context);
    if (app == null || !context.mounted) return;

    final phone = () {
      final wa = customer.whatsapp?.trim() ?? '';
      if (wa.isNotEmpty) return wa;
      if (customer.mobile.trim().isNotEmpty) return customer.mobile.trim();
      return '';
    }();
    if (WhatsappInvoiceShare.phoneDigits(phone) == null) {
      ToastService.showError(
        context,
        isAr
            ? 'لا يوجد رقم واتساب / جوال صالح للعميل'
            : 'Customer has no valid WhatsApp / mobile number',
      );
      return;
    }

    final nav = Navigator.of(context, rootNavigator: true);
    var loaderOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr
                          ? 'جاري تجهيز ملف الفاتورة…'
                          : 'Preparing invoice PDF…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    void closeLoader() {
      if (!loaderOpen) return;
      loaderOpen = false;
      if (nav.canPop()) nav.pop();
    }

    final posVm = context.read<PosViewModel>();
    try {
      // Same scope as View Invoice (any branch) — not the branch-locked public-link API.
      final response = await posVm.fetchInvoiceByOrder(order.id);
      if (!context.mounted) {
        closeLoader();
        return;
      }
      if (response == null ||
          !response.success ||
          response.invoice == null) {
        closeLoader();
        ToastService.showError(
          context,
          response?.message.isNotEmpty == true
              ? response!.message
              : (isAr
                  ? 'تعذر تجهيز الفاتورة'
                  : 'Could not prepare the invoice'),
        );
        return;
      }

      // Same public PDF the old WhatsApp link opened — not the newer local A4 layout.
      final pdfUrl = _legacyPublicInvoicePdfUrl(response.invoice!);
      if (pdfUrl == null) {
        closeLoader();
        ToastService.showError(
          context,
          isAr
              ? 'رابط الفاتورة غير متوفر على الخادم'
              : 'Invoice link is not available from the server',
        );
        return;
      }
      final res = await http
          .get(Uri.parse(pdfUrl))
          .timeout(const Duration(seconds: 45));
      final bytes = res.bodyBytes;
      final isPdf = res.statusCode == 200 &&
          bytes.length > 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;
      if (!context.mounted) {
        closeLoader();
        return;
      }
      if (!isPdf) {
        closeLoader();
        ToastService.showError(
          context,
          isAr ? 'تعذر تنزيل ملف الفاتورة' : 'Could not download the invoice PDF',
        );
        return;
      }

      final invoiceNo = order.invoiceNo.trim().isNotEmpty
          ? order.invoiceNo.trim()
          : order.id;

      closeLoader();
      final opened = await WhatsappInvoiceShare.shareDownloadedPdf(
        bytes: bytes,
        filename: 'invoice-$invoiceNo.pdf',
        phoneRaw: phone,
        app: app,
        caption: isAr ? 'إليك فاتورتك' : 'Here is your invoice',
      );
      if (!context.mounted) return;
      if (!opened) {
        final wantsBusiness = app == WhatsAppClientApp.business;
        ToastService.showError(
          context,
          isAr
              ? (wantsBusiness
                  ? 'تعذر فتح واتساب للأعمال. تأكد أن واتساب للأعمال مثبت.'
                  : 'تعذر فتح واتساب. تأكد أن التطبيق مثبت.')
              : (wantsBusiness
                  ? 'Could not open WhatsApp Business. Make sure WhatsApp Business is installed.'
                  : 'Could not open WhatsApp. Make sure the app is installed.'),
        );
      }
    } catch (e) {
      closeLoader();
      if (!context.mounted) return;
      ToastService.showError(
        context,
        isAr ? 'تعذر إرسال الفاتورة: $e' : 'Could not send invoice: $e',
      );
    }
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    // Reverting to previous compact style as requested
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.secondaryLight),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: AppColors.secondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Async-translating wrapper for SearchHistoryItem.
//
// WHY: SearchHistoryItem accepts plain String fields. API data arrives in
// English and must be translated to Arabic on the fly when the locale is Arabic.
// Using FutureBuilder here keeps the translation logic out of pos_widgets.dart
// and out of the ViewModel — each card translates independently, shows the
// raw (English) string instantly via initialData, then updates once the
// translation resolves. Re-renders automatically on locale switch because the
// ValueKey changes (langCode is part of the key).
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerSearchShimmerList extends StatelessWidget {
  final bool isTablet;
  final EdgeInsetsGeometry padding;

  const _CustomerSearchShimmerList({
    required this.isTablet,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final gap = keyboardOpen ? 12.0 : 16.0;
    final availableW = MediaQuery.sizeOf(context).width -
        (isTablet ? 36 : 32) -
        PosShellRailLayout.bodyRailOf(context);
    final crossAxisCount = !isTablet
        ? 1
        : availableW >= 980
            ? 3
            : availableW >= 640
                ? 2
                : 1;
    final count = crossAxisCount * 4;
    final resolved = padding.resolve(Directionality.of(context)).add(
          EdgeInsets.only(top: keyboardOpen ? 8 : 14, bottom: 16),
        );

    if (crossAxisCount == 1) {
      return SliverPadding(
        padding: resolved,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: const _ShimmerCard(),
            ),
            childCount: count,
          ),
        ),
      );
    }

    final rowCount = (count / crossAxisCount).ceil();
    return SliverPadding(
      padding: resolved,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, rowIndex) {
            final start = rowIndex * crossAxisCount;
            final end = (start + crossAxisCount).clamp(0, count);
            final n = end - start;
            return Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < n; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      const Expanded(child: _ShimmerCard()),
                    ],
                    for (int i = n; i < crossAxisCount; i++) ...[
                      SizedBox(width: gap),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
            );
          },
          childCount: rowCount,
        ),
      ),
    );
  }
}

/// Skeleton matching [SearchHistoryItem] compact layout (avatar, lines, ⋮, 2 buttons).
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PosShimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PosShimmerCircle(size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: PosShimmerBox(width: 110, height: 11, radius: 6),
                          ),
                          const SizedBox(width: 8),
                          PosShimmerBox(width: 16, height: 16, radius: 4),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const PosShimmerBox(width: 140, height: 9, radius: 5),
                      const SizedBox(height: 10),
                      const PosShimmerBox(width: 150, height: 20, radius: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 28,
                    radius: 10,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 28,
                    radius: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PosTranslatedSearchHistoryItem extends StatelessWidget {
  const PosTranslatedSearchHistoryItem({
    super.key,
    required this.langCode,
    required this.rawVehicle,
    required this.plate,
    required this.rawCustomer,
    required this.phone,
    required this.lastVisit,
    required this.rawLastService,
    required this.isCorporate,
    this.orderNumber,
    this.technicianName,
    this.onContinue,
    this.onViewHistory,
    this.onPrintInvoice,
    this.onDownloadInvoice,
    this.onSeeInvoiceDetails,
    this.onSalesReturn,
    this.shrinkWrap = false,
  });

  final String langCode;
  final String rawVehicle;
  final String plate;
  final String rawCustomer;
  final String phone;
  final String lastVisit;
  final String rawLastService;
  final String? technicianName;
  final bool isCorporate;
  final String? orderNumber;
  final VoidCallback? onContinue;
  final VoidCallback? onViewHistory;
  final VoidCallback? onPrintInvoice;
  final VoidCallback? onDownloadInvoice;
  final VoidCallback? onSeeInvoiceDetails;
  final VoidCallback? onSalesReturn;
  final bool shrinkWrap;

  String _instantStatus(String status) {
    if (langCode != 'ar') return status;
    switch (status.trim().toLowerCase().replaceAll('_', ' ')) {
      case 'invoiced':
        return 'مفوتر';
      case 'completed':
      case 'complete':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'draft':
        return 'مسودة';
      case 'in progress':
      case 'inprogress':
        return 'قيد التنفيذ';
      case 'cancelled':
      case 'canceled':
        return 'ملغي';
      default:
        return AppTranslationService.localizeDigitsForLanguage(
          status,
          langCode,
        );
    }
  }

  Future<_TranslatedStrings> _translate() async {
    final results = await Future.wait([
      AppTranslationService.localizedDynamicValueForLanguage(
        rawVehicle,
        langCode,
      ),
      AppTranslationService.localizedDynamicValueForLanguage(
        rawCustomer,
        langCode,
      ),
      AppTranslationService.localizedStatusForLanguage(
        rawLastService,
        langCode,
      ),
    ]);
    return _TranslatedStrings(
      vehicle: results[0],
      customer: results[1],
      lastService: results[2],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TranslatedStrings>(
      // Key ensures translation re-runs when the locale changes.
      key: ValueKey<String>(
        '$langCode::$rawVehicle::$rawCustomer::$rawLastService',
      ),
      future: _translate(),
      initialData: _TranslatedStrings(
        vehicle: AppTranslationService.localizeDigitsForLanguage(
          rawVehicle,
          langCode,
        ),
        customer: rawCustomer,
        lastService: _instantStatus(rawLastService),
      ),
      builder: (context, snapshot) {
        final t = snapshot.data!;
        return SearchHistoryItem(
          vehicle: t.vehicle,
          plate: plate,
          customer: t.customer,
          phone: phone,
          lastVisit: lastVisit,
          lastService: t.lastService,
          technicianName: technicianName,
          orderNumber: orderNumber,
          isCorporate: isCorporate,
          compactLayout: true,
          shrinkWrap: shrinkWrap,
          onContinue: onContinue,
          onViewHistory: onViewHistory,
          onPrintInvoice: onPrintInvoice,
          onDownloadInvoice: onDownloadInvoice,
          onSeeInvoiceDetails: onSeeInvoiceDetails,
          onSalesReturn: onSalesReturn,
        );
      },
    );
  }
}

class _HomePromoBanner extends StatelessWidget {
  const _HomePromoBanner({
    required this.promo,
    required this.isTablet,
    required this.overflowTop,
    required this.onTap,
  });

  final AvailablePromotion promo;
  final bool isTablet;
  final double overflowTop;
  final VoidCallback onTap;

  String _discountValue() {
    return promo.discount.toStringAsFixed(promo.discount % 1 == 0 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final value = _discountValue();
    final headline = promo.isPercent
        ? l10n.posHomePromoPercentOff(value)
        : l10n.posHomePromoAmountOff(value);
    final title = promo.isPercent
        ? l10n.posHomePromoPercentTitle(value)
        : l10n.posHomePromoAmountTitle(value);
    final rawDesc = promo.description.trim();
    final isGenericDesc = rawDesc.isEmpty ||
        rawDesc.toLowerCase() == 'promotional discount';
    final body = isGenericDesc
        ? (promo.isPercent
            ? l10n.posHomePromoPercentBody(value)
            : l10n.posHomePromoAmountBody(value))
        : rawDesc;

    final textStyle = isAr
        ? (double size, FontWeight weight, Color color) => appArabicTextStyle(
              color: color,
              fontSize: size,
              fontWeight: weight,
              height: 1.25,
            )
        : (double size, FontWeight weight, Color color) => TextStyle(
              color: color,
              fontSize: size,
              fontWeight: weight,
              height: 1.2,
            );

    final textAlign = isAr ? TextAlign.right : TextAlign.left;
    final cross = CrossAxisAlignment.start;
    final validity = promo.validityPeriod.trim().isEmpty
        ? (isAr ? 'بدون تاريخ انتهاء' : 'No expiry')
        : promo.validityPeriod.trim();
    final unit = promo.isPercent ? '%' : (isAr ? 'ر.س' : 'SAR');
    final imageWidth = isTablet ? 164.0 : 128.0;
    final imageBoxHeight = overflowTop + (isTablet ? 138.0 : 122.0) - 8;
    final headPeek = isTablet ? 16.0 : 13.0;

    Widget ticketChip(IconData icon, String text) {
      if (text.trim().isEmpty) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 10 : 8,
          vertical: isTablet ? 6 : 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF1E2124)),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 168 : 120),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle(
                  isTablet ? 12 : 11,
                  FontWeight.w800,
                  const Color(0xFF1E2124),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final heroBadge = Container(
      width: isTablet ? 76 : 64,
      height: isTablet ? 76 : 64,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: textStyle(
              isTablet ? 24 : 20,
              FontWeight.w900,
              Colors.white,
            ).copyWith(height: 1),
          ),
          const SizedBox(height: 2),
          Text(
            promo.isPercent
                ? (isAr ? 'خصم' : 'OFF')
                : unit,
            style: textStyle(
              isTablet ? 12 : 11,
              FontWeight.w800,
              const Color(0xFFF6C244),
            ),
          ),
        ],
      ),
    );

    final copy = Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: cross,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              headline,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle(
                isTablet ? 13 : 11.5,
                FontWeight.w800,
                const Color(0xFF5A4300),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle(
                isTablet ? 18 : 16,
                FontWeight.w900,
                const Color(0xFF161616),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle(
                isTablet ? 13 : 11.5,
                FontWeight.w500,
                const Color(0xFF3F3F3F),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              children: [
                ticketChip(Icons.confirmation_number_rounded, promo.code),
                ticketChip(Icons.calendar_month_rounded, validity),
                Material(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 14 : 12,
                        vertical: isTablet ? 8 : 7,
                      ),
                      child: Text(
                        l10n.posHomeSeeDetails,
                        style: textStyle(
                          isTablet ? 12 : 11,
                          FontWeight.w800,
                          Colors.white,
                        ),
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: overflowTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(28),
              elevation: 0,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isAr ? imageWidth : (isTablet ? 14 : 12),
                          isTablet ? 12 : 10,
                          isAr ? (isTablet ? 14 : 12) : imageWidth,
                          isTablet ? 12 : 10,
                        ),
                        child: Row(
                          textDirection: isAr
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          children: [heroBadge, copy],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: overflowTop - headPeek,
          right: isAr ? null : 14,
          left: isAr ? 14 : null,
          width: imageWidth,
          height: imageBoxHeight,
          child: Image.asset(
            'assets/images/pos_promo_banner_person_v2.png',
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }
}

class _TranslatedStrings {
  const _TranslatedStrings({
    required this.vehicle,
    required this.customer,
    required this.lastService,
  });
  final String vehicle;
  final String customer;
  final String lastService;
}
