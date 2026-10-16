import '../../app_config.dart';

class ApiConstants {
  /// Effective API host.
  ///
  /// Priority:
  /// 1. `--dart-define=FILTER_API_BASE_URL=...` (CI / one-off)
  /// 2. [AppConfig.apiBaseUrl] from `lib/app_config.dart` (edit that file)
  static String get baseUrl {
    const fromDefine = String.fromEnvironment(
      'FILTER_API_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return AppConfig.apiBaseUrl;
  }

  static String get environmentLabel {
    final host = Uri.tryParse(baseUrl)?.host.toLowerCase() ??
        baseUrl.toLowerCase();
    if (host.contains('railway')) return 'Staging';
    if (host.contains('filtercarservices') ||
        host.contains('77filtercarservice')) {
      return 'Production';
    }
    if (host.contains('localhost') ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.')) {
      return 'Local';
    }
    return AppConfig.environmentName;
  }

  static String get cashierInvoicePdfUploadUrl => '$baseUrl/cashier/invoice-pdf-upload';
  static const String invoicePublicQrViewBaseUrl = '';

  //// workshop pos ////
  static const String loginEndpoint = '/auth/cashier/login';
  static const String cashierLogoutEndpoint = '/auth/cashier/logout';
  static const String servicesEndpoint = '/services';
  static const String walkInCustomerEndpoint = '/cashier/walk-in-order';
  static const String cashierWalkInCorporateUnapprovedEndpoint = '/cashier/walk-in-corporate/unapproved';
  static String cashierWalkInCorporateSendForApprovalEndpoint(String orderId) => '/cashier/walk-in-corporate/order/$orderId/send-for-approval';
  static String cashierWalkInCorporateStartDepartmentEndpoint(String orderId) => '/cashier/walk-in-corporate/order/$orderId/start-department';
  static String cashierOrderDetailEndpoint(String orderId) => '/cashier/order/$orderId';
  static String assignTechnicianEndpoint(String jobId) =>'/cashier/job/$jobId/assign';
  static const bool cashierAssignSendSyncReplace = true;
  static String cashierJobBroadcastEndpoint(String jobId) => '/cashier/jobs/$jobId/broadcast';
  static String cashierJobBroadcastCancelEndpoint(String jobId) => '/cashier/jobs/$jobId/broadcast/cancel';
  static const String cashierBroadcastsActiveEndpoint = '/cashier/broadcasts/active';
  static String cashierCompleteJobEndpoint(String jobId) => '/cashier/job/$jobId/complete-cashier';
  static String cashierJobPricingEndpoint(String jobId) => '/cashier/job/$jobId/pricing';
  static String cashierCompleteReadyEndpoint(String jobId) => '/cashier/job/$jobId/complete-ready';
  static String cashierJobMarkEditedEndpoint(String jobId) => '/cashier/job/$jobId/mark-edited';
  static const String cashierOrdersEndpoint = '/cashier/orders';
  static const String cashierSoftPosAdjustmentsEndpoint =
      '/cashier/softpos-adjustments';
  static const String cashierSoftPosAccessEndpoint = '/cashier/softpos-access';
  static const String cashierSoftPosTerminalsEndpoint =
      '/cashier/softpos-terminals';
  static const String cashierSoftPosBindingEndpoint =
      '/cashier/softpos-binding';
  static const String cashierSoftPosPaymentRequestEndpoint =
      '/cashier/softpos/payment-request';
  static const String cashierSoftPosPaymentCancelEndpoint =
      '/cashier/softpos/payment-cancel';
  static String cashierSoftPosPaymentRequestStatusEndpoint(String requestId) =>
      '/cashier/softpos/payment-request/$requestId';
  static String cancelOrderEndpoint(String orderId) => '/cashier/order/$orderId/cancel';
  static String cashierOrderBillingEndpoint(String orderId) => '/cashier/order/$orderId/billing';
  static String cashierOrderPaymentMethodEndpoint(String orderId) => '/cashier/order/$orderId/payment-method';
  static String cashierOrderRecordPrepaymentEndpoint(String orderId) => '/cashier/order/$orderId/record-prepayment';
  static String cashierOrderMaintenanceChecklistEndpoint(String orderId) => '/cashier/order/$orderId/maintenance-checklist';
  static String cashierOrderJobsEndpoint(String orderId) => '/cashier/order/$orderId/jobs';
  static const String cashierTechniciansEndpoint = '/cashier/technicians';
  static String cashierTechnicianOnlineStatusEndpoint(String employeeId) => '/cashier/technicians/$employeeId/online-status';
  static String cashierTechnicianDutyStatusEndpoint(String employeeId) => '/cashier/technicians/$employeeId/duty-status';

  /// PATCH — cancel a single job before invoice.
  static String cashierJobCancelEndpoint(String jobId) => '/cashier/job/$jobId/cancel';
  static String editOrderEndpoint(String orderId, String jobId) => '/cashier/order/$orderId/job/$jobId/edit';
  static String invoicedOrdersEndpoint(String customerId) => '/cashier/orders/invoiced/$customerId';
  static String invoicedOrderByInvoiceNoEndpoint(String invoiceNo) => '/cashier/orders/invoiced/by-invoice/${Uri.encodeComponent(invoiceNo)}';
  static const String searchCustomerEndpoint = '/cashier/customers/search';
  static const String openSessionEndpoint = '/cashier/session/open';
  static const String closeSessionEndpoint = '/cashier/session/close';
  static const String currentSessionEndpoint = '/cashier/session/current';
  static const String createInvoiceEndpoint = '/cashier/invoice/create';
  static String invoicePaymentEndpoint(String orderId) => '/cashier/invoice/$orderId/payment';
  static const String getInvoiceByOrderEndpoint = '/cashier/invoice/by-order';
  static const String getInvoicePublicLinkByOrderEndpoint =
      '/cashier/invoice/by-order/public-link';
  static const String submitSalesReturnEndpoint = '/cashier/return/submit';
  static const String salesReturnListEndpoint = '/cashier/return/list';
  static const String promoCodeApplyEndpoint = '/cashier/promo-code/apply';
  static const String referralCodeApplyEndpoint = '/cashier/referral-code/apply';
  static String cashierOrderReferralEndpoint(String orderId) =>
      '/cashier/order/$orderId/referral';
  static const String expenseCategoriesEndpoint = '/cashier/expense-categories';
  static const String cashierEmployeesEndpoint = '/cashier/employees';
  /// Deprecated for new code — backend aliases to [cashierEmployeesEndpoint]; kept for compatibility.
  static const String expenseBranchEmployeesEndpoint = '/cashier/expense/branch-employees';
  static const String expenseHistoryEndpoint = '/cashier/expense/history';
  static const String expenseSubmitEndpoint = '/cashier/expense/submit';
  static const String pettyCashRequestFundEndpoint = '/cashier/petty-cash/request';
  static const String walletBalanceEndpoint = '/cashier/wallet/balance';
  static const String cashierCorporateAccountsEndpoint = '/cashier/corporate-accounts';
  static String cashierCorporateAccountVehiclesEndpoint(String corporateAccountId) => '/cashier/corporate-accounts/$corporateAccountId/vehicles';
  static String cashierCorporateAccountProductsEndpoint(String corporateAccountId) => '/cashier/corporate-accounts/$corporateAccountId/products';
  static String cashierCorporateAccountCatalogEndpoint(String corporateAccountId) => '/cashier/corporate-accounts/$corporateAccountId/catalog';
  static const String corporateBookingsEndpoint = '/cashier/corporate-bookings';
  static String cashierCorporateBookingDetailEndpoint(String bookingId) =>
      '/cashier/corporate-bookings/$bookingId';
  static String corporateWalkInOrderEndpoint(String orderId) => '/corporate/walk-in-orders/$orderId';
  static const String corporateProductsEndpoint = '/corporate/products';
  static String approveCorporateBookingEndpoint(String id) => '/cashier/corporate-bookings/$id/approve';
  static String rejectCorporateBookingEndpoint(String id) => '/cashier/corporate-bookings/$id/reject';
  static const String storeClosingEndpoint = '/cashier/store-closing';
  static const String counterClosingEndpoint = '/cashier/counter-closing';
  static const String closingHistoryEndpoint = '/cashier/closing-history';
  static const String cashCollectionEndpoint = '/cashier/cash-collection';
  static const String cashierSalaryPaymentsEndpoint = '/cashier/salary-payments';
  static const String cashierSalaryAdvancesEndpoint = '/cashier/salary-advances';
  static String cashierSalaryPaymentAckEndpoint(String paymentId) =>
      '/cashier/salary-payments/$paymentId/ack';
  static const String cashierPromoCodesEndpoint = '/cashier/promo-codes';
  static const String cashierTakeawayProductsCatalogEndpoint = '/cashier/takeaway/products-catalog';
  static const String cashierTakeawayCheckoutEndpoint = '/cashier/takeaway/checkout';
  static const String cashierInventorySalesEndpoint = '/cashier/inventory-sales';

  ///// workshop-owner //////
  static const String adminLoginEndpoint = '/auth/workshop/login';
  static const String adminRegisterEndpoint = '/auth/workshop/register';
  static const String supplierLoginEndpoint = '/auth/supplier/login';
  static const String corporateRegisterEndpoint = '/auth/corporate/register';
  static const String createBranchEndpoint = '/workshop-staff/branch/create';
  static const String getBranchesEndpoint = '/workshop-staff/branches';
  static const String deleteBranchEndpoint = '/workshop-staff/branch';
  static const String deleteDepartmentEndpoint = '/workshop-staff/department';
  static const String createProductEndpoint = '/workshop-staff/product/create';
  static const String updateProductEndpoint = '/workshop-staff/product';
  static const String createCategoryEndpoint = '/workshop-staff/category/create';
  static const String createSubCategoryEndpoint = '/workshop-products/sub-categories';
  static const String createDepartmentEndpoint = '/workshop-staff/department/create';
  static const String billingDashboardEndpoint = '/workshop-staff/billing-dashboard';
  static const String reportsAnalyticsEndpoint = '/workshop-staff/reports-analytics';
  static const String createCorporateUserEndpoint = '/workshop-staff/corporate-user/create';
  static const String corporateCustomersEndpoint = '/workshop-staff/corporate-customers';
  static const String createTechnicianEndpoint = '/workshop-staff/technician/create';
  static const String createCashierEndpoint = '/workshop-staff/cashier/create';
  static const String createSupplierEndpoint = '/workshop-staff/supplier/create';
  static const String departmentsEndpoint = '/workshop-staff/departments';
  static const String getProductsCategoriesEndpoint = '/workshop-products/categories';
  static const String categoriesEndpoint = '/workshop-staff/categories';
  static const String getSubCategoriesEndpoint = '/workshop-staff/sub-categories';
  static const String rolesEndpoint = '/workshop-staff/permissions/roles';
  static String roleByIdEndpoint(String id) => '/workshop-staff/permissions/roles/$id';
  static const String techniciansEndpoint = '/workshop-staff/technicians';
  static String workshopStaffTechnicianByIdEndpoint(String id) => '/workshop-staff/technician/$id';
  static const String employeesEndpoint = '/workshop-staff/employees';
  static const String referrersEndpoint = '/workshop-staff/referrers';
  static const String productsEndpoint = '/workshop-catalog/my/products';
  static const String productUnitsEndpoint = '/workshop-staff/product-units';
  static const String workshopServicesEndpoint = '/workshop-products/services';
  static String branchCatalogEndpoint(String branchId) => '/workshop-staff/branches/$branchId/catalog';
  static String branchServiceSellingPriceEndpoint(String branchId, String serviceId) => '/workshop-staff/branches/$branchId/services/$serviceId/selling-price';
  static const String dashboardEndpoint = '/workshop-staff/dashboard';
  static const String promoCodesEndpoint = '/workshop-staff/promo-codes';
  static const String createPromoCodeEndpoint = '/workshop-staff/promo-code/create';
  static String workshopPromoCodeByIdEndpoint(String id) => '/workshop-staff/promo-code/$id';

  static const String mobileDashboardEndpoint = '/workshop-staff/mobile-dashboard';
  static const String catalogDepartmentsEndpoint = '/workshop-catalog/my/departments';
  static const String catalogCategoriesEndpoint = '/workshop-catalog/my/categories';
  static const String workshopProfileEndpoint = '/workshop-staff/workshop/profile';
  static const String lockerManagementOverviewEndpoint = '/workshop-staff/locker-management/overview';

  static String localPurchaseInvoicesEndpoint({
    int limit = 100,
    int offset = 0,
    String? branchId,
  }) {
    final q = StringBuffer(
      '/workshop-suppliers/local/purchase-invoices?limit=$limit&offset=$offset',
    );
    if (branchId != null && branchId.isNotEmpty) {
      q.write('&branchId=${Uri.encodeQueryComponent(branchId)}');
    }
    return q.toString();
  }
  static const String createSupplierPurchaseInvoiceEndpoint =
      '/workshop-staff/supplier-purchase-invoices';
  static String supplierLastPurchasePricesEndpoint(String supplierId, String branchId) =>
      '/workshop-staff/suppliers/$supplierId/last-purchase-prices?branchId=$branchId';
  static String supplierUomRulesEndpoint(String supplierId, String branchId) =>
      '/workshop-staff/suppliers/$supplierId/product-uom-rules?branchId=$branchId';
  static String supplierPurchaseInvoicesEndpoint({
    int limit = 100,
    int offset = 0,
    String? branchId,
  }) {
    final q = StringBuffer(
      '/workshop-staff/supplier-purchase-invoices?limit=$limit&offset=$offset',
    );
    if (branchId != null && branchId.isNotEmpty) {
      q.write('&branchId=${Uri.encodeQueryComponent(branchId)}');
    }
    return q.toString();
  }
  static String suppliersLocalEndpoint({int limit = 500, int offset = 0}) =>
      '/workshop-suppliers/local?limit=$limit&offset=$offset';
  static const String nonAffiliatedSuppliersEndpoint = '/workshop-suppliers/local';
  static String nonAffiliatedSupplierByIdEndpoint(String id) =>
      '/workshop-suppliers/local/$id';
  static String nonAffiliatedSupplierLedgerEndpoint(
    String id, {
    required String from,
    required String to,
  }) =>
      '/workshop-suppliers/local/$id/ledger?from=$from&to=$to';
  static String supplierSalesInvoicesEndpoint({
    int limit = 100,
    int offset = 0,
    String? branchId,
  }) {
    final q = StringBuffer(
      '/workshop-staff/supplier-sales-invoices?limit=$limit&offset=$offset',
    );
    if (branchId != null && branchId.isNotEmpty) {
      q.write('&branchId=${Uri.encodeQueryComponent(branchId)}');
    }
    return q.toString();
  }
  static const String salesReturnsEndpoint = '/workshop-staff/sales-returns';
  static const String affiliatedPurchaseReturnsEndpoint =
      '/workshop-staff/affiliated-purchase-returns';
  static String affiliatedPurchaseReturnApproveEndpoint(String returnId) =>
      '/workshop-staff/affiliated-purchase-returns/$returnId/approve';
  static const String adminWalletApprovalsEndpoint =
      '/workshop-staff/admin-wallet-approvals';
  static const String masterProductPreviewDepsEndpoint =
      '/workshop-catalog/products/preview-dependencies';
  static const String discountsEndpoint = '/workshop-staff/discounts';
  static const String createServiceEndpoint = '/workshop-staff/product/create';
  static const String masterMyProductsEndpoint = '/workshop-catalog/my/products?isActive=true';
  static const String masterMyServicesEndpoint = '/workshop-catalog/my/services?isActive=true';
  static const String masterAddProductsToBranchesEndpoint =
      '/workshop-catalog/branches/products';
  static const String masterServicePreviewDepsEndpoint =
      '/workshop-catalog/services/preview-dependencies';
  static const String masterAddServicesToBranchesEndpoint =
      '/workshop-catalog/branches/services';
  static const String masterAddDepartmentsToBranchesEndpoint =
      '/workshop-catalog/branches/departments';
  static const String masterAddCategoriesToBranchesEndpoint =
      '/workshop-catalog/branches/categories';
  static const String linkSuppliersEndpoint = '/workshop-staff/suppliers/link';
  static String workshopSuppliersEndpoint({int limit = 500, int offset = 0}) =>
      '/workshop-staff/suppliers?limit=$limit&offset=$offset';
  static String registeredSuppliersEndpoint({int limit = 500, int offset = 0}) =>
      '/workshop-staff/suppliers/registered?limit=$limit&offset=$offset';
  static const String affiliatedSuppliersEndpoint = '/workshop-suppliers/affiliated';
  static String affiliatedSupplierLedgerEndpoint(
    String supplierId, {
    required String from,
    required String to,
  }) =>
      '/workshop-suppliers/affiliated/$supplierId/ledger?from=$from&to=$to';
  static String affiliatedSupplierActiveEndpoint(String id) =>
      '/workshop-suppliers/affiliated/$id';

  static const String suppliersStatsEndpoint = '/workshop-staff/suppliers-purchases/stats';
  static const String suppliersEndpoint = '/workshop-staff/suppliers';
  static const String accountingSummaryEndpoint = '/workshop-staff/accounting/summary';
  static const String purchaseOrdersEndpoint = '/workshop-staff/purchase-orders';
  static const String accountingTransactionsEndpoint = '/workshop-staff/accounting/transactions';

  /// Chart of Accounts / P&L — same endpoints as filter-web `accountsApi.js`
  static const String accountsListEndpoint = '/accounts';
  static const String accountsBranchesEndpoint = '/accounts/branches';
  static const String accountsProfitLossEndpoint = '/accounts/reports/pl';
  static const String accountsTrialBalanceEndpoint = '/accounts/reports/trial-balance';
  static const String accountsBalanceSheetEndpoint = '/accounts/reports/balance-sheet';

  /// Workshop commissions — same as filter-web `workshopCommissionsApi.js`
  static const String workshopCommissionsSummaryEndpoint =
      '/workshop-staff/commissions/summary';
  static const String workshopCommissionsPendingEndpoint =
      '/workshop-staff/commissions/pending-by-employee';
  static const String workshopCommissionsListEndpoint =
      '/workshop-staff/commissions';
  static const String workshopCommissionsEmployeesEndpoint =
      '/workshop-staff/commissions/employees';
  static const String workshopCommissionsPayoutAccountsEndpoint =
      '/workshop-staff/commissions/payout-accounts';
  static const String workshopCommissionsPayoutEndpoint =
      '/workshop-staff/commissions/payout';
  static const String workshopCommissionsRulesEndpoint =
      '/workshop-staff/commissions/rules';
  static const String workshopCommissionsRuleServicesEndpoint =
      '/workshop-staff/commissions/rule-services';
  static String workshopCommissionRuleEndpoint(String id) =>
      '/workshop-staff/commissions/rules/$id';
  static const String posMonitoringEndpoint = '/workshop-staff/pos-monitoring';
  static const String workshopPettyCashRequestsEndpoint = '/workshop-staff/petty-cash/requests';
  static const String workshopPettyCashHistoryEndpoint = '/workshop-staff/petty-cash/history';
  static String workshopPettyCashApproveEndpoint(String requestId) => '/workshop-staff/petty-cash/$requestId/approve';
  static String workshopPettyCashRejectEndpoint(String requestId) => '/workshop-staff/petty-cash/$requestId/reject';
  static String editCategoryEndpoint(String id) => '/workshop-staff/category/$id';
  static String editCorporateAccountEndpoint(String id) => '/workshop-staff/corporate-account/$id';

  ///// technician /////
  static const String technicianLoginEndpoint = '/auth/technician/login';
  static const String technicianDailyPerformanceEndpoint = '/technician/daily-performance';
  static const String technicianTodayPerformanceEndpoint = '/technician/today-performance';
  static const String technicianDashboardKpisEndpoint = '/technician/dashboard-kpis';
  static const String technicianProfileEndpoint = '/technician/profile';
  static const String technicianOnlineStatusEndpoint = '/technician/online-status';
  static const String technicianDutyStatusEndpoint = '/technician/duty-status';
  static const String technicianAssignedOrdersEndpoint = '/technician/assigned-orders';
  static String technicianOrderDetailsEndpoint(String jobId) => '/technician/orders/$jobId';
  static String technicianCompleteOrderEndpoint(String jobId) => '/technician/orders/$jobId/complete';
  static String technicianAcceptOrderEndpoint(String jobId) => '/technician/orders/$jobId/accept';
  static String technicianCancelOrderEndpoint(String jobId) => '/technician/orders/$jobId/cancel';
  static String technicianStartOrderEndpoint(String jobId) => '/technician/orders/$jobId/start';
  static const String technicianCommissionHistoryEndpoint = '/technician/commission-history';
  static const String technicianSalaryPaymentsEndpoint = '/technician/salary-payments';
  static const String technicianSalaryAdvancesEndpoint = '/technician/salary-advances';
  static String technicianSalaryPaymentAckEndpoint(String paymentId) =>
      '/technician/salary-payments/$paymentId/ack';

  /// Technician platform chat (workshop team — same backend as web technician portal).
  static const String technicianPlatformChatBase = '/technician/platform-chat';
  static const String technicianPlatformChatUnread = '$technicianPlatformChatBase/unread';
  static const String technicianPlatformChatConversations = '$technicianPlatformChatBase/conversations';
  static const String technicianPlatformChatContacts = '$technicianPlatformChatBase/contacts';
  static const String technicianPlatformChatContactsSearch = '$technicianPlatformChatBase/contacts/search';
  static String technicianPlatformChatMessages(String conversationId) =>
      '$technicianPlatformChatBase/conversations/$conversationId/messages';
  static String technicianPlatformChatAck(String conversationId) =>
      '$technicianPlatformChatBase/conversations/$conversationId/ack';

  static const String technicianBroadcastsEndpoint = '/technician/broadcasts';
  static String technicianBroadcastAcceptEndpoint(String jobId) => '/technician/broadcasts/$jobId/accept';
  static String technicianBroadcastRejectEndpoint(String jobId) => '/technician/broadcasts/$jobId/reject';

  //// super admin /////
  static const String superAdminLoginEndpoint = '/auth/admin/login';
  static const String superAdminBrandsEndpoint = '/super-admin/brands';
  static const String superAdminCreateBrandEndpoint = '/super-admin/brand/create';
  static const String superAdminBranchesEndpoint = '/super-admin/branches';
  static const String superAdminUsersEndpoint = '/super-admin/users';
  static const String superAdminProductsEndpoint = '/super-admin/products';
  static const String superAdminDepartmentsEndpoint = '/super-admin/departments';
  static const String superAdminCorporateCustomersEndpoint = '/super-admin/corporate-customers';

  ////// Locker /////
  /// Dedicated locker login — supervisor / collector only (not workshop owner).
  static const String lockerLoginEndpoint = '/auth/locker/login';
  static const String lockerDashboardEndpoint = '/locker/dashboard';
  static const String lockerCollectionRequestsEndpoint = '/locker/collection-requests';
  static String lockerCollectionRequestById(String requestId) => '$lockerCollectionRequestsEndpoint/$requestId';
  static String lockerAssignOfficerEndpoint(String requestId) => '$lockerCollectionRequestsEndpoint/$requestId/assign';
  static const String lockerFieldOfficersEndpoint = '/locker/field-officers';
  static const String lockerRecordCollectionEndpoint = '/locker/record-collection';
  static const String lockerFinancialHistoryEndpoint = '/locker/financial/history';
  static const String lockerFinancialAnalyticsEndpoint = '/locker/financial/analytics';
  static const String lockerApprovalsEndpoint = '/locker/approvals';
  static const String lockerApproveDifferenceEndpoint = '/locker/approve-difference';
  static const String lockerPettyCashFundRequestsEndpoint =
      '/locker/petty-cash/fund-requests';
  static String lockerApprovePettyCashFundRequestEndpoint(String id) =>
      '/locker/petty-cash/fund-requests/$id/approve';
  static String lockerRejectPettyCashFundRequestEndpoint(String id) =>
      '/locker/petty-cash/fund-requests/$id/reject';
  static const String lockerBranchesEndpoint = '/locker/branches';
  static const String lockerBankRegistersEndpoint = '/locker/bank-registers';
  static const String lockerOverviewEndpoint = '/workshop-staff/locker-management/overview';
  static const String lockerCashiersEndpoint = '/locker/cashiers';
  static const String lockerIssuePettyCashEndpoint = '/locker/issue-petty-cash';
  static const String lockerPettyCashIssuesEndpoint = '/locker/petty-cash-issues';
  static const String lockerDepositToBankEndpoint = '/locker/deposit-to-bank';
  static const String lockerExpenseCategoriesEndpoint = '/locker/expense-categories';
  static const String lockerExpensesEndpoint = '/locker/expenses';
  static const String lockerExpensesBulkEndpoint = '/locker/expenses/bulk';

  // Notifications
  static const String lockerNotificationsEndpoint = '/locker/notifications';
  static String lockerGetNotificationsEndpoint(int page, int limit) => '/locker/get_notifications/$page/$limit';
  static const String lockerNotificationsMarkReadEndpoint = '/locker/notifications/mark-read';
  static const String paymentMethodsEndpoint = '/payments/methods';
  static const String paymentIntentsEndpoint = '/payments/intents';
  static String paymentIntentEndpoint(String intentId) => '/payments/intents/$intentId';

  static const String cashierLocalSuppliersEndpoint = '/cashier/local-suppliers';
  static const String cashierDepartmentsEndpoint = '/cashier/departments';

  // Purchase orders (POS cashier)
  static const String cashierPurchaseOrderSuppliersEndpoint = '/cashier/purchase-orders/suppliers';
  static const String cashierPurchaseOrderProductsEndpoint = '/cashier/purchase-orders/products';
  static const String cashierPurchaseOrdersEndpoint = '/cashier/purchase-orders';
  static const String cashierPurchaseOrderNextReferenceEndpoint = '/cashier/purchase-orders/next-reference';
  static String cashierPurchaseOrderDetailEndpoint(String invoiceId) => '/cashier/purchase-orders/$invoiceId';
  static const String cashierIncomingPurchaseInvoicesEndpoint = '/cashier/purchase-orders/incoming-invoices';
  static String cashierIncomingPurchaseInvoiceDetailEndpoint(String invoiceId) => '/cashier/purchase-orders/incoming-invoices/$invoiceId';
  static String cashierReceivePurchaseInvoiceEndpoint(String invoiceId) => '/cashier/purchase-orders/incoming-invoices/$invoiceId/receive';

  /// Public — enabled mobile app launcher portals (no auth).
  static const String publicMobileAppMenuEndpoint = '/public/mobile-app-menu';

  // --- AI Camera / AI Orders (cashier) --------------------------------
  static const String cashierAiOrdersEndpoint = '/cashier/ai-orders';
  static const String cashierAiOrdersUnbilledAlertsEndpoint =
      '/cashier/ai-orders/unbilled-alerts';
  static const String cashierAiOrdersByPlateEndpoint =
      '/cashier/ai-orders/by-plate';
  static const String cashierAiOrdersOpenPosByPlateEndpoint =
      '/cashier/ai-orders/open-pos-by-plate';
  static const String cashierAiOrdersStaffVehiclesEndpoint =
      '/cashier/ai-orders/staff-vehicles';
  static const String cashierAiOrdersSettingsEndpoint =
      '/cashier/ai-orders/settings';
  static String cashierAiOrderDetailEndpoint(String id) =>
      '/cashier/ai-orders/$id';
  static String cashierAiOrderAcknowledgeEndpoint(String id) =>
      '/cashier/ai-orders/$id/acknowledge';
  static String cashierAiOrderLinkOrderEndpoint(String id) =>
      '/cashier/ai-orders/$id/link-order';

  // Workshop notifications (cashier inbox)
  static const String workshopNotificationsInboxEndpoint =
      '/workshop-notifications/inbox';
  static const String workshopNotificationsClearAllEndpoint =
      '/workshop-notifications/clear/all';
  static String workshopNotificationReadEndpoint(String id) =>
      '/workshop-notifications/$id/read';
  static String workshopNotificationDeleteEndpoint(String id) =>
      '/workshop-notifications/$id';
}