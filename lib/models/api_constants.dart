class ApiConstants {

 //static const String baseUrl = 'http://localhost:3000';
  static const String baseUrl = 'https://filterbackend-production.up.railway.app';

  //// workshop pos ////
  static const String loginEndpoint = '/auth/cashier/login';
  static const String servicesEndpoint = '/services';
  static const String walkInCustomerEndpoint = '/cashier/walk-in-order';
  static const String cashierWalkInCorporateUnapprovedEndpoint =
      '/cashier/walk-in-corporate/unapproved';
  static String cashierWalkInCorporateSendForApprovalEndpoint(String orderId) =>
      '/cashier/walk-in-corporate/order/$orderId/send-for-approval';
  static String cashierWalkInCorporateStartDepartmentEndpoint(String orderId) =>
      '/cashier/walk-in-corporate/order/$orderId/start-department';
  static String cashierOrderDetailEndpoint(String orderId) => '/cashier/order/$orderId';
  static String assignTechnicianEndpoint(String jobId) =>
      '/cashier/job/$jobId/assign';

  /// When true, [PosRepository.assignTechnicians] sends `sync: true` so the server should treat
  /// `employeeIds` as the **full desired roster** (remove unliste\],]d, add missing). Required for
  /// “keep Zaid only” after Jabbar+Taha were assigned — add-only APIs return “No new assignments”.
  /// Backend DTO must accept `sync`; set to false if validation rejects unknown fields.
  static const bool cashierAssignSendSyncReplace = true;
  /// Broadcast job to workshop / on-call technicians (plural `jobs` per backend).
  static String cashierJobBroadcastEndpoint(String jobId) =>
      '/cashier/jobs/$jobId/broadcast';
  static String cashierJobBroadcastCancelEndpoint(String jobId) =>
      '/cashier/jobs/$jobId/broadcast/cancel';
  static const String cashierBroadcastsActiveEndpoint =
      '/cashier/broadcasts/active';
  static String cashierCompleteJobEndpoint(String jobId) =>
      '/cashier/job/$jobId/complete-cashier'; // newly added mapping
  static String cashierJobPricingEndpoint(String jobId) =>
      '/cashier/job/$jobId/pricing';
  static String cashierCompleteReadyEndpoint(String jobId) =>
      '/cashier/job/$jobId/complete-ready';
  /// PATCH — transitions a **completed** job to **edited** when the call succeeds.
  ///
  /// **Contract (cashier POS):**
  /// - Opening product grid / technician assign **without** this call is fine.
  /// - **POST /cashier/job/:id/pricing** is rejected while the job is still `completed` — call this
  ///   first when saving real edits (or retry once if pricing returns that error).
  /// - No-op saves: skip pricing POST entirely (client detects unchanged snapshot).
  static String cashierJobMarkEditedEndpoint(String jobId) =>
      '/cashier/job/$jobId/mark-edited';
  static const String cashierOrdersEndpoint = '/cashier/orders';
  static String cancelOrderEndpoint(String orderId) =>
      '/cashier/order/$orderId/cancel';
  /// Standard walk-in only (no corporateAccountId): attach customer / vehicle before invoice.
  static String cashierOrderBillingEndpoint(String orderId) =>
      '/cashier/order/$orderId/billing';
  /// PATCH — cashier payment modal draft (`customerKind` + split `payments`) before invoice create.
  static String cashierOrderPaymentMethodEndpoint(String orderId) =>
      '/cashier/order/$orderId/payment-method';

  /// Six bilingual checklist rows ({ checks: boolean[6] }) before invoicing — printed on invoice.
  static String cashierOrderMaintenanceChecklistEndpoint(String orderId) =>
      '/cashier/order/$orderId/maintenance-checklist';
  /// POST — add pending jobs for extra departments (walk_in / walk_in_corporate only).
  static String cashierOrderJobsEndpoint(String orderId) =>
      '/cashier/order/$orderId/jobs';
  /// GET — cashier assign picker; pass [departmentId] as query param.
  static const String cashierTechniciansEndpoint = '/cashier/technicians';
  /// PATCH body `{ "status": "online" | "offline" }` — [employeeId] = [technicians].[id] from GET.
  static String cashierTechnicianOnlineStatusEndpoint(String employeeId) =>
      '/cashier/technicians/$employeeId/online-status';
  /// PATCH body `{ "dutyMode": "workshop" | "on_call" | "inactive" }`.
  static String cashierTechnicianDutyStatusEndpoint(String employeeId) =>
      '/cashier/technicians/$employeeId/duty-status';
  /// PATCH — cancel a single job before invoice.
  static String cashierJobCancelEndpoint(String jobId) =>
      '/cashier/job/$jobId/cancel';
  static String editOrderEndpoint(String orderId, String jobId) =>
      '/cashier/order/$orderId/job/$jobId/edit';
  static String invoicedOrdersEndpoint(String customerId) =>
      '/cashier/orders/invoiced/$customerId';
  static const String searchCustomerEndpoint = '/cashier/customers/search';
  static const String openSessionEndpoint = '/cashier/session/open';
  static const String closeSessionEndpoint = '/cashier/session/close';
  static const String currentSessionEndpoint = '/cashier/session/current';
  /// POST — creates invoice from completed jobs. Server finalizes `edited` jobs first
  /// via `complete-cashier` with an empty body (recalc only), then includes them; failures
  /// surface the same validation errors (e.g. missing tech/lines).
  static const String createInvoiceEndpoint = '/cashier/invoice/create';
  static String invoicePaymentEndpoint(String orderId) =>
      '/cashier/invoice/$orderId/payment';
  static const String getInvoiceByOrderEndpoint = '/cashier/invoice/by-order';
  static const String submitSalesReturnEndpoint = '/cashier/return/submit';
  static const String salesReturnListEndpoint = '/cashier/return/list';
  static const String promoCodeApplyEndpoint = '/cashier/promo-code/apply';
  static const String expenseCategoriesEndpoint = '/cashier/expense-categories';
  /// Branch employees for cashier POS (payments, petty cash, advances).
  /// Optional query: `?employeeType=staff` | `technician`; omit for all active branch employees.
  static const String cashierEmployeesEndpoint = '/cashier/employees';
  /// Deprecated for new code — backend aliases to [cashierEmployeesEndpoint]; kept for compatibility.
  static const String expenseBranchEmployeesEndpoint = '/cashier/expense/branch-employees';
  static const String expenseHistoryEndpoint = '/cashier/expense/history';
  static const String expenseSubmitEndpoint = '/cashier/expense/submit';
  static const String pettyCashRequestFundEndpoint =
      '/cashier/petty-cash/request';
  static const String walletBalanceEndpoint = '/cashier/wallet/balance';
  static const String cashierCorporateAccountsEndpoint =
      '/cashier/corporate-accounts';
  static String cashierCorporateAccountVehiclesEndpoint(
          String corporateAccountId) =>
      '/cashier/corporate-accounts/$corporateAccountId/vehicles';
  static const String corporateBookingsEndpoint = '/cashier/corporate-bookings';
  static String corporateWalkInOrderEndpoint(String orderId) =>
      '/corporate/walk-in-orders/$orderId';
  static String approveCorporateBookingEndpoint(String id) =>
      '/cashier/corporate-bookings/$id/approve';
  static String rejectCorporateBookingEndpoint(String id) =>
      '/cashier/corporate-bookings/$id/reject';
  static const String storeClosingEndpoint = '/cashier/store-closing';
  static const String counterClosingEndpoint = '/cashier/counter-closing';
  static const String closingHistoryEndpoint = '/cashier/closing-history';
  static const String cashierPromoCodesEndpoint = '/cashier/promo-codes';
  static const String cashierTakeawayProductsCatalogEndpoint =
      '/cashier/takeaway/products-catalog';
  static const String cashierTakeawayCheckoutEndpoint =
      '/cashier/takeaway/checkout';
  /// GET `?from=yyyy-MM-dd&to=yyyy-MM-dd` — product quantities sold per day (cashier).
  ///
  /// Backend may return `{ "sales": [ ... ] }` or a raw JSON array. Each line:
  /// `productName`, optional `sku` / `productId`, `quantitySold` | `qty`, `soldDate` | `saleDate`.
  static const String cashierInventorySalesEndpoint =
      '/cashier/inventory-sales';

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
  static const String techniciansEndpoint = '/workshop-staff/technicians';
  static String workshopStaffTechnicianByIdEndpoint(String id) =>
      '/workshop-staff/technician/$id';
  static const String employeesEndpoint = '/workshop-staff/employees';
  static const String referrersEndpoint = '/workshop-staff/referrers';
  static const String productsEndpoint = '/workshop-staff/products';
  static const String productUnitsEndpoint = '/workshop-staff/product-units';
  static const String workshopServicesEndpoint = '/workshop-products/services';
  static String branchCatalogEndpoint(String branchId) => '/workshop-staff/branches/$branchId/catalog';
  static String branchServiceSellingPriceEndpoint(String branchId, String serviceId) =>
      '/workshop-staff/branches/$branchId/services/$serviceId/selling-price';
  static const String dashboardEndpoint = '/workshop-staff/dashboard';
  static const String promoCodesEndpoint = '/workshop-staff/promo-codes';
  static const String createPromoCodeEndpoint = '/workshop-staff/promo-code/create';


  /// PATCH / DELETE single promo code by id
  static String workshopPromoCodeByIdEndpoint(String id) => '/workshop-staff/promo-code/$id';
  static const String suppliersStatsEndpoint = '/workshop-staff/suppliers-purchases/stats';
  static const String suppliersEndpoint = '/workshop-staff/suppliers';
  static const String accountingSummaryEndpoint = '/workshop-staff/accounting/summary';
  static const String purchaseOrdersEndpoint = '/workshop-staff/purchase-orders';
  static const String accountingTransactionsEndpoint = '/workshop-staff/accounting/transactions';

  /// Chart of Accounts / P&L — same as filter-web `accountsApi.js`
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
  static const String technicianProfileEndpoint = '/technician/profile';
  static const String technicianOnlineStatusEndpoint = '/technician/online-status';
  static const String technicianDutyStatusEndpoint = '/technician/duty-status';
  static const String technicianAssignedOrdersEndpoint = '/technician/assigned-orders';
  static String technicianOrderDetailsEndpoint(String jobId) => '/technician/orders/$jobId';
  static String technicianCompleteOrderEndpoint(String jobId) =>
      '/technician/orders/$jobId/complete';
  static String technicianAcceptOrderEndpoint(String jobId) =>
      '/technician/orders/$jobId/accept';
  static String technicianCancelOrderEndpoint(String jobId) =>
      '/technician/orders/$jobId/cancel';
  static String technicianStartOrderEndpoint(String jobId) =>
      '/technician/orders/$jobId/start';
  static const String technicianCommissionHistoryEndpoint =
      '/technician/commission-history';
  static const String technicianBroadcastsEndpoint = '/technician/broadcasts';
  static String technicianBroadcastAcceptEndpoint(String jobId) =>
      '/technician/broadcasts/$jobId/accept';
  static String technicianBroadcastRejectEndpoint(String jobId) =>
      '/technician/broadcasts/$jobId/reject';

  //// super admin /////
  static const String superAdminLoginEndpoint = '/auth/admin/login';
  static const String superAdminBrandsEndpoint = '/super-admin/brands';
  static const String superAdminCreateBrandEndpoint =
      '/super-admin/brand/create';
  static const String superAdminBranchesEndpoint = '/super-admin/branches';
  static const String superAdminUsersEndpoint = '/super-admin/users';
  static const String superAdminProductsEndpoint = '/super-admin/products';
  static const String superAdminDepartmentsEndpoint =
      '/super-admin/departments';
  static const String superAdminCorporateCustomersEndpoint =
      '/super-admin/corporate-customers';

  // ── Locker ────────────────────────────────────────────────────────────────

  static const String lockerLoginEndpoint = '/auth/locker/login';
  static const String lockerDashboardEndpoint = '/locker/dashboard';
  static const String lockerCollectionRequestsEndpoint =
      '/locker/collection-requests';

  /// Single collection request detail / assignment targets this path + [requestId].
  static String lockerCollectionRequestById(String requestId) =>
      '$lockerCollectionRequestsEndpoint/$requestId';

  /// Assign a field officer to a pending collection request.
  static String lockerAssignOfficerEndpoint(String requestId) =>
      '$lockerCollectionRequestsEndpoint/$requestId/assign';

  static const String lockerFieldOfficersEndpoint = '/locker/field-officers';
  static const String lockerRecordCollectionEndpoint =
      '/locker/record-collection';
  static const String lockerFinancialHistoryEndpoint =
      '/locker/financial/history';
  static const String lockerFinancialAnalyticsEndpoint =
      '/locker/financial/analytics';
  static const String lockerApprovalsEndpoint = '/locker/approvals';
  static const String lockerApproveDifferenceEndpoint =
      '/locker/approve-difference';
  static const String lockerBranchesEndpoint = '/locker/branches';

  // Notifications
  static const String lockerNotificationsEndpoint = '/locker/notifications';

  /// Path-based paginated endpoint: /locker/get_notifications/:page/:limit
  static String lockerGetNotificationsEndpoint(int page, int limit) =>
      '/locker/get_notifications/$page/$limit';

  static const String lockerNotificationsMarkReadEndpoint =
      '/locker/notifications/mark-read';
}