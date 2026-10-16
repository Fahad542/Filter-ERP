// App switches (API URL / env / package / display name): edit [app_config.dart].
import 'package:filter_service_providers/services/owner_data_service.dart';
import 'package:filter_service_providers/views/Locker%20App/Collector/locker_collector_dashboard_view.dart';
import 'package:filter_service_providers/views/Locker%20App/Supervisor/locker_supervisor_dashboard_view.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Billing/billing_management_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Branches/branch_management_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Dashboard/owner_dashboard_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Inventory/inventory_management_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_management_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20owner/SuppliersAndPurchases/suppliers_view_model.dart';
import 'package:filter_service_providers/views/Workshop%20owner/owner_shell.dart';
import 'package:filter_service_providers/views/Workshop%20pos%20app/Department/department_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'views/Workshop pos app/More Tab/settings_view_model.dart';
import 'views/Workshop pos app/Home Screen/pos_view_model.dart';
import 'services/cashier_realtime_session_guard.dart';
import 'services/cashier_session_helper.dart';
import 'utils/app_navigation.dart';
import 'views/Menu/menu_view.dart';
import 'utils/app_theme.dart';
import 'utils/app_arabic_font_fallbacks.dart';
import 'utils/toast_service.dart';
import 'data/repositories/auth_repository.dart';
import 'services/session_service.dart';
import 'services/catalog_sync_service.dart';
import 'views/Workshop pos app/Login/login_view_model.dart';
import 'views/Workshop pos app/Navbar/pos_shell.dart';
import 'views/Technician App/technician_shell.dart';
import 'data/repositories/pos_repository.dart';
import 'data/repositories/ai_orders_repository.dart';
import 'data/repositories/owner_repository.dart';
import 'data/repositories/technician_repository.dart';
import 'views/Workshop pos app/AI Orders/ai_orders_view_model.dart';
import 'data/network/base_api_service.dart';
import 'views/Workshop pos app/Technician Screen/technician_view_model.dart';
import 'views/Workshop pos app/Corporate Bookings/corporate_booking_view_model.dart';
import 'views/Workshop pos app/Notifications/notifications_view_model.dart';
import 'views/Workshop pos app/Petty Cash/petty_cash_view_model.dart';
import 'views/Workshop pos app/Store Closing/store_closing_view_model.dart';
import 'views/Workshop pos app/Store Closing/closing_history_view_model.dart';
import 'views/Workshop pos app/Salaries/pos_salaries_view_model.dart';
import 'views/Workshop pos app/Cash Collection/cash_collection_view_model.dart';
import 'views/Workshop pos app/Current Shift/current_shift_view_model.dart';
import 'views/Workshop pos app/Promo/promo_view_model.dart';
import 'views/Workshop pos app/Product Grid/product_grid_view_model.dart';
import 'views/Workshop pos app/Sales Return/sales_return_view_model.dart';
import 'views/Workshop pos app/Sales Return/sales_return_list_view_model.dart';
import 'views/Workshop pos app/Takeaway/takeaway_view_model.dart';
import 'views/Workshop pos app/Broadcast/cashier_broadcast_view_model.dart';
import 'views/Workshop pos app/Inventory Sales/inventory_sales_view_model.dart';
import 'views/Workshop pos app/Purchase Order/purchase_order_view_model.dart';
import 'views/Workshop owner/Employees/employee_management_view_model.dart';
import 'views/Workshop owner/Corporate/corporate_management_view_model.dart';
import 'views/Workshop owner/Auth/owner_login_view_model.dart';
import 'views/Super Admin/Auth/super_admin_login_view_model.dart';
import 'views/Super Admin/Departments/super_admin_departments_view_model.dart';
import 'views/Workshop owner/Promo/owner_promo_view_model.dart';
import 'views/Technician App/technician_view_model.dart';
import 'views/Technician App/Chat/tech_platform_chat_view_model.dart';
import 'views/Technician App/Orders/broadcast_overlay.dart';
import 'views/Locker App/locker_view_model.dart';
import 'views/Workshop owner/POS Monitoring/pos_monitoring_view_model.dart';
import 'package:filter_service_providers/utils/restart_widget.dart';
import 'services/thermal_esc_pos_profile_warmup.dart';
import 'services/fcm_notification_service.dart';
import 'services/fcm_background_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'utils/app_google_fonts_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureBundledGoogleFonts();
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);
  await FcmNotificationService.initialize();
  warmThermalEscPosCapabilityProfile();
  runApp(const RestartWidget(child: MyApp()));
}

Future<String?> _resolveStartScreen(SessionService session) async {
  final lastPortal = await session.getLastPortal();
  if (lastPortal == null) return null;
  final isLoggedIn = await session.isLoggedIn(role: lastPortal);
  return isLoggedIn ? lastPortal : null;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late Future<String?> _startScreenFuture;

  @override
  void initState() {
    super.initState();
    AppNavigation.navigatorKey = _navigatorKey;
    CashierRealtimeSessionGuard.instance.start();

    BaseApiService.setUnauthorizedHandler(_handleUnauthorizedResponse);
    _startScreenFuture = _resolveStartScreen(SessionService());
  }

  Future<void> _handleUnauthorizedResponse() async {
    final sessionService = SessionService();
    final portal = await sessionService.getLastPortal();

    if (portal == 'cashier') {
      await CashierRealtimeSessionGuard.instance.disconnect();
      await CashierSessionHelper.releaseServerSession(
        sessionService: sessionService,
      );
      await sessionService.clearSession(role: 'cashier');
      await AppNavigation.toCashierLogin();
      return;
    }

    if (portal != null && portal.isNotEmpty) {
      await sessionService.clearSession(role: portal);
    } else {
      await sessionService.clearAllSessions();
    }

    await AppNavigation.toPortalMenu();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<SessionService>(create: (_) => SessionService()),
        Provider<OwnerRepository>(create: (_) => OwnerRepository()),
        Provider<TechnicianRepository>(create: (_) => TechnicianRepository()),
        ChangeNotifierProvider<SettingsViewModel>(create: (_) => SettingsViewModel()),
        Provider<PosRepository>(create: (_) => PosRepository()),
        Provider<AiOrdersRepository>(create: (_) => AiOrdersRepository()),
        ChangeNotifierProvider<CatalogSyncService>(
          create: (context) => CatalogSyncService(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
        ),
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(
            authRepository: context.read<AuthRepository>(),
            sessionService: context.read<SessionService>(),
          ),
        ),

        ChangeNotifierProxyProvider3<PosRepository, SessionService,
            CatalogSyncService, DepartmentViewModel>(
          create: (context) => DepartmentViewModel(
            departmentRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
            catalogSync: context.read<CatalogSyncService>(),
          ),
          update: (context, deptRepo, sessionService, catalogSync, previous) =>
              previous ??
              DepartmentViewModel(
                departmentRepository: deptRepo,
                sessionService: sessionService,
                catalogSync: catalogSync,
              ),
        ),
        ChangeNotifierProxyProvider3<PosRepository, SessionService,
            CatalogSyncService, PosViewModel>(
          create: (context) => PosViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
            catalogSync: context.read<CatalogSyncService>(),
          ),
          update: (context, posRepo, sessionService, catalogSync, previous) =>
              previous ??
              PosViewModel(
                posRepository: posRepo,
                sessionService: sessionService,
                catalogSync: catalogSync,
              ),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService,
            TechnicianViewModel>(
          create: (context) => TechnicianViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
          previous ??
              TechnicianViewModel(
                  posRepository: posRepo, sessionService: sessionService),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService, CorporateBookingViewModel>(
          create: (context) => CorporateBookingViewModel(
            repository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
          previous ?? CorporateBookingViewModel(repository: posRepo, sessionService: sessionService),
        ),
        ChangeNotifierProxyProvider2<AiOrdersRepository, SessionService,
            NotificationsViewModel>(
          create: (context) => NotificationsViewModel(
            repository: context.read<AiOrdersRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, repo, sessionService, previous) =>
              previous ??
              NotificationsViewModel(
                repository: repo,
                sessionService: sessionService,
              ),
        ),
        ChangeNotifierProxyProvider2<AiOrdersRepository, SessionService,
            AiOrdersViewModel>(
          create: (context) => AiOrdersViewModel(
            repository: context.read<AiOrdersRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, repo, sessionService, previous) =>
              previous ??
              AiOrdersViewModel(
                repository: repo,
                sessionService: sessionService,
              ),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService, PettyCashViewModel>(
          create: (context) => PettyCashViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
          previous ?? PettyCashViewModel(posRepository: posRepo, sessionService: sessionService),
        ),
        ChangeNotifierProvider<StoreClosingViewModel>(
          create: (_) => StoreClosingViewModel(),
        ),
        ChangeNotifierProvider<ClosingHistoryViewModel>(
          create: (_) => ClosingHistoryViewModel(),
        ),
        ChangeNotifierProvider<PosSalariesViewModel>(
          create: (_) => PosSalariesViewModel(),
        ),
        ChangeNotifierProvider<CashCollectionViewModel>(
          create: (_) => CashCollectionViewModel(),
        ),
        ChangeNotifierProvider<CurrentShiftViewModel>(
          create: (context) => CurrentShiftViewModel(
            authRepository: context.read<AuthRepository>(),
            sessionService: context.read<SessionService>(),
          ),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService, PromoViewModel>(
          create: (context) => PromoViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
          previous ?? PromoViewModel(posRepository: posRepo, sessionService: sessionService),
        ),
        ChangeNotifierProvider<ProductGridViewModel>(
          create: (_) => ProductGridViewModel(),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService, SalesReturnViewModel>(
          create: (context) => SalesReturnViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
          previous ?? SalesReturnViewModel(posRepository: posRepo, sessionService: sessionService),
        ),

        ChangeNotifierProxyProvider2<PosRepository, SessionService, SalesReturnListViewModel>(
          create: (context) => SalesReturnListViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
          previous ?? SalesReturnListViewModel(posRepository: posRepo, sessionService: sessionService),
        ),
        ChangeNotifierProxyProvider3<PosRepository, SessionService,
            CatalogSyncService, TakeawayViewModel>(
          create: (context) => TakeawayViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
            catalogSync: context.read<CatalogSyncService>(),
          ),
          update: (context, posRepo, sessionService, catalogSync, previous) =>
              previous ??
              TakeawayViewModel(
                posRepository: posRepo,
                sessionService: sessionService,
                catalogSync: catalogSync,
              ),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService, CashierBroadcastViewModel>(
          create: (context) => CashierBroadcastViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
              previous ??
              CashierBroadcastViewModel(
                posRepository: posRepo,
                sessionService: sessionService,
              ),
        ),
        ChangeNotifierProxyProvider2<PosRepository, SessionService, InventorySalesViewModel>(
          create: (context) => InventorySalesViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, posRepo, sessionService, previous) =>
              previous ??
              InventorySalesViewModel(
                posRepository: posRepo,
                sessionService: sessionService,
              ),
        ),
        ChangeNotifierProxyProvider3<PosRepository, SessionService, CatalogSyncService, PurchaseOrderViewModel>(
          create: (context) => PurchaseOrderViewModel(
            posRepository: context.read<PosRepository>(),
            sessionService: context.read<SessionService>(),
            catalogSync: context.read<CatalogSyncService>(),
          ),
          update: (context, posRepo, sessionService, catalogSync, previous) =>
              previous ??
              PurchaseOrderViewModel(
                posRepository: posRepo,
                sessionService: sessionService,
                catalogSync: catalogSync,
              ),
        ),

        ChangeNotifierProxyProvider3<OwnerRepository, SessionService, SettingsViewModel, OwnerDataService>(
          create: (context) => OwnerDataService(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, settings, previous) =>
          previous ?? OwnerDataService(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
            settingsViewModel: settings,
          ),
        ),

        ChangeNotifierProxyProvider4<OwnerRepository, SessionService, OwnerDataService, SettingsViewModel, OwnerDashboardViewModel>(
          create: (context) => OwnerDashboardViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
            ownerDataService: context.read<OwnerDataService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, ownerData, settings, previous) =>
          previous ?? OwnerDashboardViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
            ownerDataService: ownerData,
            settingsViewModel: settings,
          ),
        ),
        ChangeNotifierProxyProvider4<OwnerRepository, SessionService, OwnerDataService, SettingsViewModel, BranchManagementViewModel>(
          create: (context) => BranchManagementViewModel(
            ownerRepository:   context.read<OwnerRepository>(),
            sessionService:    context.read<SessionService>(),
            ownerDataService:  context.read<OwnerDataService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, ownerData, settings, previous) =>
          previous ?? BranchManagementViewModel(
            ownerRepository:   ownerRepo,
            sessionService:    sessionService,
            ownerDataService:  ownerData,
            settingsViewModel: settings,
          ),
        ),
        ChangeNotifierProxyProvider4<OwnerRepository, SessionService, OwnerDataService, SettingsViewModel, EmployeeManagementViewModel>(
          create: (context) => EmployeeManagementViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
            ownerDataService: context.read<OwnerDataService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, ownerData, settings, previous) =>
          previous ?? EmployeeManagementViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
            ownerDataService: ownerData,
            settingsViewModel: settings,
          ),
        ),
        ChangeNotifierProxyProvider2<OwnerRepository, SessionService, CorporateManagementViewModel>(
          create: (context) => CorporateManagementViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, ownerRepo, sessionService, previous) =>
          previous ?? CorporateManagementViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
          ),
        ),
        ChangeNotifierProxyProvider4<OwnerRepository, SessionService, OwnerDataService, SettingsViewModel, InventoryManagementViewModel>(
          create: (context) => InventoryManagementViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
            ownerDataService: context.read<OwnerDataService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, ownerData, settings, previous) =>
          previous ?? InventoryManagementViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
            ownerDataService: ownerData,
            settingsViewModel: settings,
          ),
        ),
        ChangeNotifierProxyProvider3<OwnerRepository, SessionService, SettingsViewModel, BillingManagementViewModel>(
          create: (context) => BillingManagementViewModel(
            ownerRepository:   context.read<OwnerRepository>(),
            sessionService:    context.read<SessionService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, settings, previous) =>
          previous ?? BillingManagementViewModel(
            ownerRepository:   ownerRepo,
            sessionService:    sessionService,
            settingsViewModel: settings,
          ),
        ),

        ChangeNotifierProxyProvider2<OwnerRepository, SessionService, SuppliersViewModel>(
          create: (context) => SuppliersViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, ownerRepo, sessionService, previous) =>
          previous ?? SuppliersViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
          ),
        ),
        ChangeNotifierProxyProvider4<OwnerRepository, SessionService, OwnerDataService, SettingsViewModel, ReportsManagementViewModel>(
          create: (context) => ReportsManagementViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
            ownerDataService: context.read<OwnerDataService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, ownerData, settings, previous) =>
          previous ?? ReportsManagementViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
            ownerDataService: ownerData,
            settingsViewModel: settings,
          ),
        ),
        ChangeNotifierProxyProvider4<OwnerRepository, SessionService, OwnerDataService, SettingsViewModel, PosMonitoringViewModel>(
          create: (context) => PosMonitoringViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
            ownerDataService: context.read<OwnerDataService>(),
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, ownerRepo, sessionService, ownerData, settings, previous) =>
          previous ?? PosMonitoringViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
            ownerDataService: ownerData,
            settingsViewModel: settings,
          ),
        ),
        ChangeNotifierProxyProvider2<OwnerRepository, SessionService, OwnerPromoViewModel>(
          create: (context) => OwnerPromoViewModel(
            ownerRepository: context.read<OwnerRepository>(),
            sessionService: context.read<SessionService>(),
          ),
          update: (context, ownerRepo, sessionService, previous) =>
          previous ?? OwnerPromoViewModel(
            ownerRepository: ownerRepo,
            sessionService: sessionService,
          ),
        ),
        ChangeNotifierProvider<TechAppViewModel>(
          create: (context) => TechAppViewModel(
            repository: context.read<TechnicianRepository>(),
            sessionService: context.read<SessionService>(),
          ),
        ),
        ChangeNotifierProvider<TechPlatformChatViewModel>(
          create: (_) => TechPlatformChatViewModel(),
        ),
        ChangeNotifierProvider<LockerViewModel>(
          create: (_) => LockerViewModel()..init(),
        ),
        ChangeNotifierProvider<OwnerLoginViewModel>(
          create: (context) => OwnerLoginViewModel(
            authRepository: context.read<AuthRepository>(),
            sessionService: context.read<SessionService>(),
          ),
        ),
        ChangeNotifierProvider<SuperAdminLoginViewModel>(
          create: (context) => SuperAdminLoginViewModel(
            authRepository: context.read<AuthRepository>(),
            sessionService: context.read<SessionService>(),
          ),
        ),
        ChangeNotifierProvider<SuperAdminDepartmentsViewModel>(
          create: (_) => SuperAdminDepartmentsViewModel(),
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: ToastService.scaffoldMessengerKey,
            title: 'Filter ERP',
            debugShowCheckedModeBanner: false,
            // Theme Configuration
            theme: AppTheme.lightThemeFor(settings.locale),
            darkTheme: AppTheme.darkThemeFor(settings.locale),
            themeMode: settings.themeMode,

            // Localization Configuration
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],

            /// Technician broadcast modal above any screen (tabs + pushed routes) when active.
            builder: (context, child) {
              final stack = Stack(
                fit: StackFit.expand,
                children: [
                  if (child != null) child,
                  const BroadcastOverlay(),
                ],
              );
              final locale = settings.locale;
              final isArabic = appUsesArabicPrimaryFont(locale);
              return DefaultTextStyle.merge(
                style: applyAppLocaleTypography(
                  context,
                  TextStyle(
                    fontFamily: isArabic ? kArabicFontFamily : kLatinFontFamily,
                    fontFamilyFallback: isArabic
                        ? appArabicPrimaryFontFallbacks()
                        : appLatinPrimaryFontFallbacks(),
                  ),
                ),
                child: stack,
              );
            },

            home: FutureBuilder<String?>(
              future: _startScreenFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                switch (snapshot.data) {
                  case 'owner':
                    return const OwnerShell();
                  case 'cashier':
                    return const PosShell();
                  case 'tech':
                    return const TechShell();
                  case 'locker_supervisor':
                    return const LockerSupervisorDashboardView();
                  case 'locker_collector':
                    return const LockerCollectorDashboardView();
                  case 'locker':
                    return const LockerSupervisorDashboardView();
                  default:
                    return const MenuView();
                }
              },
            ),
          );
        },
      ),
    );
  }
}