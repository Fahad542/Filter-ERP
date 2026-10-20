import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:filter_service_providers/services/cashier_open_session_guard.dart';
import 'package:filter_service_providers/services/cashier_realtime_session_guard.dart';
import 'package:filter_service_providers/services/softpos_access_service.dart';
import 'package:filter_service_providers/views/Workshop pos app/Home Screen/pos_view_model.dart';
import 'package:filter_service_providers/views/Workshop pos app/Technician Screen/technician_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20pos%20app/Broadcast/cashier_broadcast_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20pos%20app/Broadcast/pos_cashier_broadcast_view.dart';
import 'package:filter_service_providers/views/Workshop%20pos%20app/AI%20Orders/ai_orders_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20pos%20app/AI%20Orders/pos_ai_orders_view.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_arabic_font_fallbacks.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/pos_catalog_sync_app_bar_button.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shell_left_menu_rail.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../Home Screen/pos_home_view.dart';
import '../Order Screen/pos_orders_view.dart';
import '../Petty Cash/petty_cash_view_model.dart';
import '../Petty Cash/pos_petty_cash_view.dart';
import '../Product Grid/pos_product_grid_view.dart';
import '../Product Grid/product_grid_view_model.dart';
import '../Promo/pos_promo_view.dart';
import '../Promo/promo_view_model.dart';
import '../Sales Return/pos_sales_return_view.dart';
import '../Sales Return/pos_sales_return_list_view.dart';
import '../Sales Return/sales_return_list_view_model.dart';
import '../Store Closing/pos_store_closing_view.dart';
import '../Store Closing/store_closing_view_model.dart';
import '../Store Closing/pos_closing_history_view.dart';
import '../Salaries/pos_salaries_view.dart';
import '../Salaries/pos_salaries_view_model.dart';
import '../Cash Collection/pos_cash_collection_view.dart';
import '../Cash Collection/cash_collection_view_model.dart';
import '../NFC Adjustments/pos_nfc_adjustments_view.dart';
import '../Technician Screen/pos_technician_view.dart';
import '../Takeaway/pos_takeaway_view.dart';
import '../Takeaway/takeaway_view_model.dart';
import '../Inventory Sales/inventory_sales_view_model.dart';
import '../Inventory Sales/pos_inventory_sales_view.dart';
import '../Corporate Bookings/pos_corporate_bookings_view.dart';
import '../Purchase Order/pos_purchase_order_view.dart';
import '../Purchase Order/purchase_order_view_model.dart';
// import '../../utils/app_colors.dart';
// import '../../utils/app_text_styles.dart';
// import '../Workshop pos app/Home Screen/pos_home_view.dart';
// import '../Workshop pos app/Product Screen/pos_products_view.dart';
// import '../Workshop pos app/Order Screen/pos_orders_view.dart';
// import '../Workshop pos app/Technician Screen/pos_technician_view.dart';
//
// import '../Workshop pos app/Petty Cash/pos_petty_cash_view.dart';
// import '../Workshop pos app/Promo/pos_promo_view.dart';
// import '../Workshop pos app/Petty Cash/petty_cash_view_model.dart';
// import '../Workshop pos app/Store Closing/pos_store_closing_view.dart';
// import '../Workshop pos app/Sales Return/pos_sales_return_view.dart';
// import '../Workshop pos app/Store Closing/store_closing_view_model.dart';
// import '../../widgets/pos_widgets.dart';

/// Selects the Orders tab and returns to [PosShell].
///
/// Always resets the **root** navigator to a single [PosShell] at the Orders tab.
/// The previous `while (canPop) pop()` logic could leave the wrong screen (e.g. only
/// [PosDepartmentView] after it replaced the shell) or an empty stack, which made the
/// app fall back to [MenuView] while the session token was still valid.
void navigateToPosShellOrdersTab(BuildContext context) {
  final posVm = context.read<PosViewModel>();
  final wasAlreadyOnOrdersTab = posVm.shellSelectedIndex == 2;
  posVm.setShellSelectedIndex(2);

  // Already inside POS — only switch tab (do not wipe the navigator stack).
  if (context.findAncestorWidgetOfExactType<PosShell>() != null) {
    // Tab-change listener runs prepare when switching from another tab; if we
    // were already on Orders, refresh focus here.
    if (wasAlreadyOnOrdersTab) {
      unawaited(posVm.prepareOrdersHubForVisit());
    }
    return;
  }

  final nav = Navigator.of(context, rootNavigator: true);
  nav.pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(
      builder: (_) => const PosShell(
        initialIndex: 2,
        bootstrapCatalogSync: false,
      ),
    ),
    (route) => false,
  );
}

/// Cashier broadcast list tab (active technician broadcasts).
void navigateToPosShellBroadcastTab(BuildContext context) {
  final posVm = context.read<PosViewModel>();
  posVm.setShellSelectedIndex(10);
  final nav = Navigator.of(context, rootNavigator: true);
  nav.pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(
      builder: (_) => const PosShell(
        initialIndex: 10,
        bootstrapCatalogSync: false,
      ),
    ),
        (route) => false,
  );
}

class PosShell extends StatefulWidget {
  final int initialIndex;

  /// When false, opening this shell (e.g. jump to Orders after walk-in) does not
  /// re-run catalog sync — sync stays on login / drawer "Sync data" only.
  final bool bootstrapCatalogSync;

  const PosShell({
    super.key,
    this.initialIndex = 0,
    this.bootstrapCatalogSync = true,
  });

  @override
  State<PosShell> createState() => _PosShellState();
}

class _PosShellState extends State<PosShell> with WidgetsBindingObserver {
  bool _didBootstrapShell = false;
  bool _shellIndexListenerAttached = false;
  int _lastShellFetchIndex = -1;
  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> _ordersSideMenuOpen = ValueNotifier<bool>(false);

  /// Only tabs the user has opened are built — avoids IndexedStack eagerly mounting
  /// every shell tab (each had initState/network calls before first visit).
  final Set<int> _shellTabsBuilt = {};

  /// Stable element identity per tab — reduces semantics/layout churn inside [IndexedStack].
  List<GlobalKey> _shellTabKeys = [];

  void _ensureShellTabKeys() {
    final count = _screens.length;
    if (_shellTabKeys.length == count) return;
    _shellTabKeys = List<GlobalKey>.generate(
      count,
      (i) => GlobalKey(debugLabel: 'pos_shell_tab_$i'),
    );
  }

  int _clampShellIndex(int index) {
    if (_screens.isEmpty) return 0;
    return index.clamp(0, _screens.length - 1);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shellTabsBuilt.add(_clampShellIndex(widget.initialIndex));
    _ensureShellTabKeys();
    PosShellScaffoldRegistry.attach(_shellScaffoldKey);
    PosShellScaffoldRegistry.attachOrdersSideMenu(_ordersSideMenuOpen);
    _lockPosLandscape();
    CashierRealtimeSessionGuard.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_shellIndexListenerAttached) {
      try {
        context.read<PosViewModel>().removeListener(_onShellSelectedIndexChanged);
      } catch (_) {}
      _shellIndexListenerAttached = false;
    }
    _unlockOrientationForOtherPortals();
    PosShellScaffoldRegistry.detach(_shellScaffoldKey);
    PosShellScaffoldRegistry.detachOrdersSideMenu(_ordersSideMenuOpen);
    _ordersSideMenuOpen.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(CashierRealtimeSessionGuard.instance.ensureConnected());
    }
  }

  void _onShellSelectedIndexChanged() {
    if (!mounted) return;
    final idx = context.read<PosViewModel>().shellSelectedIndex;
    if (idx < 0 || idx >= _screens.length) return;
    if (idx != kPosShellOrdersTabIndex && _ordersSideMenuOpen.value) {
      _ordersSideMenuOpen.value = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final needsBuild = !_shellTabsBuilt.contains(idx);
      if (needsBuild) {
        setState(() => _shellTabsBuilt.add(idx));
      }
      if (_lastShellFetchIndex != idx) {
        _lastShellFetchIndex = idx;
        _triggerVisitFetch(context, idx);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shellIndexListenerAttached) {
      context.read<PosViewModel>().addListener(_onShellSelectedIndexChanged);
      _shellIndexListenerAttached = true;
    }
    if (_didBootstrapShell) return;
    _didBootstrapShell = true;
    final idx = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final posVm = context.read<PosViewModel>();
      final promoVm = context.read<PromoViewModel>();
      posVm.setPromoRevalidateHook(
        ({required bool isMainTab}) =>
            promoVm.revalidateAllActivePromos(posVm, isMainTab: isMainTab),
      );
      posVm.setPromoRemoveHook(
        ({required bool isMainTab, String? departmentId}) {
          promoVm.removeAppliedPromo(
            posVm,
            isMainTab: isMainTab,
            departmentId: departmentId,
          );
        },
      );
      if (idx != 0) {
        posVm.setShellSelectedIndex(idx);
      }
      _lastShellFetchIndex = idx;
      _triggerVisitFetch(context, idx);
      if (widget.bootstrapCatalogSync) {
        unawaited(PosCatalogSyncButton.syncCatalogAfterLogin(context));
      }
      unawaited(context.read<AiOrdersViewModel>().bootstrap());
    });
  }

  List<Widget> get _screens => const [
    PosHomeView(),
    PosProductGridView(
      isReadOnly: false,
      showBackButton: false,
      isMainTab: true,
      resizeForKeyboard: false,
    ),
    PosOrdersView(),
    PosStoreClosingView(),
    PosPettyCashView(),
    PosPromoView(),
    PosTechnicianView(),
    PosSalesReturnView(),
    PosSalesReturnListView(),
    PosTakeawayView(),
    PosCashierBroadcastView(),
    PosInventorySalesView(),
    PosCorporateBookingsView(showBackButton: false),
    PosPurchaseOrderView(),
    PosClosingHistoryView(),
    PosSalariesView(),
    PosCashCollectionView(),
    PosAiOrdersView(),
    PosNfcAdjustmentsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTabletDevice(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isTablet) {
      final l10n = AppLocalizations.of(context)!;
      return _PosDeviceRestrictionView(
        title: l10n.posShellTabletRequired,
        message: l10n.posShellTabletMessage,
      );
    }

    if (!isLandscape) {
      final l10n = AppLocalizations.of(context)!;
      return _PosDeviceRestrictionView(
        title: l10n.posShellLandscapeTitle,
        message: l10n.posShellLandscapeMessage,
      );
    }

    /// [context.watch] on broad ViewModels rebuilds every cart/order tick and
    /// rebuilds all [IndexedStack] tabs — triggers semantics races on inactive tabs.
    _ensureShellTabKeys();
    final currentIndex =
    context.select((PosViewModel vm) => vm.shellSelectedIndex);
    final isReconciled =
    context.select((StoreClosingViewModel s) => s.isReconciled);

    // Safety check: Ensure index is within bounds of children
    final validIndex = _clampShellIndex(currentIndex);
    if (validIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PosViewModel>().setShellSelectedIndex(validIndex);
      });
    }
    final isStoreClosingTab = validIndex == 3;
    final isLockedInStoreClosing = isStoreClosingTab && isReconciled;

    final hideBottomBar =
        [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14].contains(validIndex) ||
            isLockedInStoreClosing;

    final isOrdersTab = validIndex == kPosShellOrdersTabIndex;
    final showLeftMenuRail =
        !isLockedInStoreClosing && !isOrdersTab;
    final railWidth =
        showLeftMenuRail ? kPosShellLeftMenuRailTotalWidth : 0.0;
    void onRailSelectTab(int index) {
      _ordersSideMenuOpen.value = false;
      setState(() => _shellTabsBuilt.add(index));
      _lastShellFetchIndex = index;
      context.read<PosViewModel>().setShellSelectedIndex(index);
      _triggerVisitFetch(context, index);
    }

    final stackBody = ListenableBuilder(
      listenable: SoftPosAccessService.instance,
      builder: (context, _) {
        if (validIndex == kPosShellNfcAdjustmentsTabIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<PosViewModel>().setShellSelectedIndex(0);
          });
        }
        final railEntries = (!isLockedInStoreClosing &&
                (showLeftMenuRail || isOrdersTab))
            ? buildPosShellRailNavEntries(AppLocalizations.of(context)!)
            : const <PosShellRailNavEntry>[];

        return ValueListenableBuilder<bool>(
          valueListenable: _ordersSideMenuOpen,
          builder: (context, ordersMenuOpen, _) {
            final showOrdersOverlayRail =
                isOrdersTab && !isLockedInStoreClosing && ordersMenuOpen;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                PosShellRailLayout(
                  bodyRailPadding: railWidth,
                  sideMenuActive: showLeftMenuRail,
                  child: KeyedSubtree(
                    key: _shellTabKeys[validIndex],
                    child: _screens[validIndex],
                  ),
                ),
                if (showLeftMenuRail)
                  PositionedDirectional(
                    start: 0,
                    top: posAppBarTotalHeight(context),
                    bottom: 0,
                    width: kPosShellLeftMenuRailTotalWidth,
                    child: PosShellLeftMenuRail(
                      selectedIndex: validIndex,
                      entries: railEntries,
                      onSelectTab: onRailSelectTab,
                    ),
                  ),
                if (showOrdersOverlayRail) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: PosShellScaffoldRegistry.closeOrdersSideMenu,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 0,
                    top: posAppBarTotalHeight(context),
                    bottom: 0,
                    width: kPosShellLeftMenuRailTotalWidth,
                    child: PosShellLeftMenuRail(
                      selectedIndex: validIndex,
                      entries: railEntries,
                      onSelectTab: onRailSelectTab,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    return PopScope(
      canPop: !isLockedInStoreClosing,
      onPopInvoked: (didPop) {
        if (!didPop && isLockedInStoreClosing) {
          // If we are locked on Store Closing, do not pop
        }
      },
      child: Scaffold(
        key: _shellScaffoldKey,
        drawer: isLockedInStoreClosing ? null : _buildDrawer(isTablet),
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: PosTabletLayout.textScaler(context),
          ),
          child: stackBody,
        ),
        bottomNavigationBar: hideBottomBar || isTablet
            ? const SizedBox.shrink()
            : PosBottomBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() => _shellTabsBuilt.add(index));
            _lastShellFetchIndex = index;
            context.read<PosViewModel>().setShellSelectedIndex(index);
            _triggerVisitFetch(context, index);
          },
        ),
      ),
    );
  }

  bool _isTabletDevice(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  void _lockPosLandscape() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _unlockOrientationForOtherPortals() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _triggerVisitFetch(BuildContext context, int index) {
    if (index == 0) {
      context.read<PosViewModel>().clearHomeSearch();
    } else if (index == 1) {
      final posVm = context.read<PosViewModel>();
      final gridVm = context.read<ProductGridViewModel>();

      // Reset all filters
      posVm.initMainProductsTab();
      gridVm.setDepartment('All');
      gridVm.setCategory('All');
      gridVm.setSubCategory('All');
      gridVm.clearSearch();
    } else if (index == 2) {
      context.read<ProductGridViewModel>().clearSearch();
      unawaited(() async {
        final open = await CashierOpenSessionGuard.instance
            .ensureOpenOrSignOut(context: context);
        if (!context.mounted || !open) return;
        final vm = context.read<PosViewModel>();
        // Skip the network call when the list was already refreshed in the
        // last few seconds (typical case: walk-in / invoice flow just fired
        // a silent fetch, then the cashier navigates to the Orders tab).
        // Pull-to-refresh and the explicit refresh icon still call
        // [refreshOrdersScreen] directly and always re-fetch.
        await vm.prepareOrdersHubForVisit();
      }());
    } else if (index == 3) {
      unawaited(
        CashierOpenSessionGuard.instance.ensureOpenOrSignOut(context: context),
      );
    } else if (index == 6) {
      final vm = context.read<TechnicianViewModel>();
      if (vm.technicians.isEmpty) {
        vm.fetchTechnicians();
      }
    } else if (index == 4) {
      // Always fetch for Petty Cash as per user request
      context.read<PettyCashViewModel>().initPettyCash();
    } else if (index == 5) {
      context.read<PromoViewModel>().fetchAvailablePromos();
    } else if (index == 8) {
      context.read<SalesReturnListViewModel>().fetchReturns(refresh: true);
    } else if (index == 9) {
      context.read<TakeawayViewModel>().loadCatalog();
    } else if (index == 10) {
      context.read<CashierBroadcastViewModel>().fetchActive();
    } else if (index == 11) {
      context.read<InventorySalesViewModel>().fetch();
    } else if (index == 13) {
      context.read<PurchaseOrderViewModel>().init();
    } else if (index == 15) {
      context.read<PosSalariesViewModel>().fetchAll();
    } else if (index == 16) {
      context.read<CashCollectionViewModel>().load(refresh: true);
    } else if (index == 17) {
      final aiVm = context.read<AiOrdersViewModel>();
      unawaited(aiVm.fetchList());
      unawaited(aiVm.fetchUnbilledCount(silent: true));
    } else if (index == 18) {
      unawaited(context.read<PosViewModel>().fetchOrders(silent: true));
    }
  }

  // --- DRAWER IMPLEMENTATION ---

  Widget _buildDrawer(bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final compact = PosTabletLayout.compactLandscapeChrome(context);
    final itemGap = compact ? 7.0 : (isTablet ? 6.0 : 6.0);

    return Drawer(
      width: compact ? 218 : (isTablet ? 224 : 200),
      backgroundColor: AppColors.secondaryLight,
      child: Column(
        children: [
          _PosShellDrawerHeader(isTablet: isTablet),
          Expanded(
            child: ListenableBuilder(
              listenable: SoftPosAccessService.instance,
              builder: (context, _) {
                return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : (isTablet ? 14 : 12),
                vertical: compact ? 12 : (isTablet ? 12 : 10),
              ),
              children: [
                _buildDrawerItem(
                    0, l10n.posNavHome, Icons.home_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    12,
                    l10n.posCorporateBookingsTitle,
                    Icons.business_center_rounded,
                    isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    2, l10n.posNavOrdersHub, Icons.receipt_long_outlined, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    17,
                    'AI Orders',
                    Icons.videocam_outlined,
                    isTablet),
                if (isSoftPosUiEnabled) ...[
                  SizedBox(height: itemGap),
                  _buildDrawerItem(
                      18,
                      'Soft POS\nAdjustment',
                      Icons.nfc_rounded,
                      isTablet),
                ],
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    9,
                    l10n.posNavTakeaway,
                    Icons.takeout_dining_rounded,
                    isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    10,
                    l10n.posNavBroadcastTechnician,
                    Icons.podcasts_rounded,
                    isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    1, l10n.posNavInventory, Icons.inventory_2_outlined, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                  11,
                  l10n.posNavInventorySales,
                  Icons.query_stats_rounded,
                  isTablet,
                ),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    13,
                    l10n.posNavPurchaseOrder,
                    Icons.shopping_cart_checkout_outlined,
                    isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    7, l10n.posNavSalesReturn, Icons.assignment_return_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    8, l10n.posNavReturnsList, Icons.list_alt_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    4, l10n.posNavPettyCash, Icons.payments_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    5, l10n.posNavPromoCodes, Icons.local_offer_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    6, l10n.posNavTechnicians, Icons.engineering_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    15, l10n.posNavSalaries, Icons.account_balance_wallet_outlined, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    16, l10n.posNavCashCollection, Icons.payments_outlined, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    14, l10n.posNavClosingHistory, Icons.history_rounded, isTablet),
                SizedBox(height: itemGap),
                _buildDrawerItem(
                    3, l10n.posNavStoreClosing, Icons.store_rounded, isTablet),
                SizedBox(height: itemGap),
              ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 12,
              0,
              compact ? 14 : 12,
              compact ? 10 : 8,
            ),
            child: const PosCatalogSyncButton(forDrawer: true),
          ),
          _buildDrawerFooter(isTablet),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon, bool isTablet,
      {bool isLogout = false}) {
    final compact = PosTabletLayout.compactLandscapeChrome(context);
    final isSelected =
        context.select((PosViewModel vm) => vm.shellSelectedIndex) == index;
    final posVm = context.read<PosViewModel>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (index < _screens.length) {
            setState(() => _shellTabsBuilt.add(index));
            _lastShellFetchIndex = index;
            posVm.setShellSelectedIndex(index);
            _triggerVisitFetch(context, index);
            Navigator.pop(context); // Close drawer
          }
        },
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 12,
            vertical: compact ? 10 : (isTablet ? 10 : 8),
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 12 : 12),
            boxShadow: isSelected && isTablet
                ? [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 19 : 18,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              SizedBox(width: compact ? 12 : 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? localeFontWeight(context, FontWeight.w800) : FontWeight.w500,
                    fontSize: compact ? 13 : (isTablet ? 13.5 : 12),
                    height: 1.15,
                    letterSpacing: compact ? 0.1 : 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(bool isTablet) {
    final compact = PosTabletLayout.compactLandscapeChrome(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 14,
        compact ? 10 : 8,
        compact ? 14 : 14,
        compact ? 14 : (isTablet ? 14 : 14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: Colors.white24, size: compact ? 13 : 14),
          SizedBox(width: compact ? 4 : 5),
          Text(
            AppLocalizations.of(context)!.posShellVersion,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: compact ? 10 : (isTablet ? 10.5 : 10),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawer profile header — refreshes translated names without [notifyListeners]
/// (rebuilding the shell body closes an open drawer, especially on Orders Hub).
class _PosShellDrawerHeader extends StatefulWidget {
  const _PosShellDrawerHeader({required this.isTablet});

  final bool isTablet;

  @override
  State<_PosShellDrawerHeader> createState() => _PosShellDrawerHeaderState();
}

class _PosShellDrawerHeaderState extends State<_PosShellDrawerHeader> {
  String? _syncedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHeaderLocale());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_syncedLocale != lang) {
      _syncedLocale = lang;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncHeaderLocale());
    }
  }

  Future<void> _syncHeaderLocale() async {
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    await context.read<PosViewModel>().retranslateWithLocale(
          lang,
          notify: false,
        );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final compact = PosTabletLayout.compactLandscapeChrome(context);
    final posVm = context.read<PosViewModel>();
    final userName = posVm.cashierName;
    final workshopName = posVm.workshopName;
    final branchName = posVm.branchName;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 14,
        compact ? 38 : (widget.isTablet ? 44 : 38),
        compact ? 14 : 12,
        compact ? 12 : (widget.isTablet ? 12 : 12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.isTablet ? 10 : 10),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=FCC247&color=23262D',
                width: compact ? 42 : (widget.isTablet ? 44 : 38),
                height: compact ? 42 : (widget.isTablet ? 44 : 38),
              ),
            ),
          ),
          SizedBox(width: compact ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: localeFontWeight(context, FontWeight.w900),
                    fontSize: compact ? 14.5 : (widget.isTablet ? 15 : 14),
                  ),
                ),
                SizedBox(height: compact ? 4 : 3),
                Text(
                  workshopName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                if (branchName.isNotEmpty)
                  Text(
                    '${AppLocalizations.of(context)!.posProductsBranchPrefix} $branchName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
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

class _PosDeviceRestrictionView extends StatelessWidget {
  final String title;
  final String message;

  const _PosDeviceRestrictionView({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.screen_lock_rotation_rounded,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}