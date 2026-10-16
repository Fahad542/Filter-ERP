// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuAllApps => 'ALL Apps';

  @override
  String get menuSubtitle => 'Please choose one of these apps';

  @override
  String get menuSuperAdminPortal => 'Super Admin\nPortal';

  @override
  String get menuWorkshopOwner => 'Workshop\nOwner';

  @override
  String get menuTechnicianApp => 'Technician\nApp';

  @override
  String get menuWorkshopPosApp => 'Workshop\nPOS App';

  @override
  String get menuWorkshopPosAppPlain => 'Workshop POS App';

  @override
  String get menuLockerPortal => 'Locker\nPortal';

  @override
  String get menuSupplier => 'Supplier';

  @override
  String get menuNoPortalsAvailable => 'No apps are available at the moment.';

  @override
  String get menuLoadingApps => 'Loading apps…';

  @override
  String get menuPortalComingSoon =>
      'This portal is not available in the app yet.';

  @override
  String get menuVersion => 'Version: 1.0.1';

  @override
  String get ownerShellHome => 'Home';

  @override
  String get ownerShellBranches => 'Branches';

  @override
  String get ownerShellDepartments => 'Departments';

  @override
  String get ownerShellEmployees => 'Employees';

  @override
  String get ownerShellCorporate => 'Corporate';

  @override
  String get ownerShellInventory => 'Inventory';

  @override
  String get ownerShellPosMonitoring => 'POS Monitoring';

  @override
  String get ownerShellSuppliers => 'Suppliers';

  @override
  String get ownerShellAccounting => 'Accounting';

  @override
  String get ownerShellPromoCodes => 'Promo Codes';

  @override
  String get ownerShellApprovals => 'Approvals';

  @override
  String get ownerShellNotifications => 'Notifications';

  @override
  String get ownerShellLogout => 'Logout';

  @override
  String get ownerShellRoleLabel => 'Workshop Owner';

  @override
  String get ownerShellVersion => 'v1.0.1 • Workshop OS';

  @override
  String get ownerShellLogoutTitle => 'Logout';

  @override
  String get ownerShellLogoutBody =>
      'Are you sure you want to logout from your account?';

  @override
  String get ownerShellLogoutCancel => 'Cancel';

  @override
  String get ownerShellLogoutConfirm => 'Logout';

  @override
  String get ownerShellDashboard => 'Dashboard';

  @override
  String get ownerShellMasterCatalog => 'Master Catalog';

  @override
  String get ownerShellManageInventory => 'Manage Inventory';

  @override
  String get ownerShellPurchaseInvoices => 'Purchase Invoices';

  @override
  String get ownerShellApprovalsQueue => 'Approvals Queue';

  @override
  String get ownerShellSalesReturns => 'Sales Returns';

  @override
  String get ownerShellChartOfAccountPnL => 'Chart of Account (P&L)';

  @override
  String get ownerShellChartOfAccountExpense => 'Chart of Account (Expense)';

  @override
  String get ownerShellCommissions => 'Commissions';

  @override
  String get ownerShellDiscounts => 'Discounts';

  @override
  String get ownerShellSuppliersPurchases => 'Suppliers & Purchases';

  @override
  String get ownerShellFilterAffiliatedSuppliers =>
      'Filter Affiliated Suppliers';

  @override
  String get ownerShellNonAffiliatedSuppliers => 'Non-Affiliated Suppliers';

  @override
  String get ownerShellLockerManagement => 'Locker Management';

  @override
  String get ownerShellMyPettyCash => 'My Petty Cash';

  @override
  String get ownerShellCorporateManagement => 'Corporate Management';

  @override
  String get ownerShellChartOfAccounts => 'Chart of Accounts';

  @override
  String get ownerShellCashBank => 'Cash & Bank';

  @override
  String get ownerShellTransactions => 'Transactions';

  @override
  String get ownerShellJournalEntries => 'Journal Entries';

  @override
  String get ownerShellExpenseEntries => 'Expense Entries';

  @override
  String get ownerShellReceipts => 'Receipts';

  @override
  String get ownerShellPayments => 'Payments';

  @override
  String get ownerShellAdvances => 'Advances';

  @override
  String get ownerShellPayrollRun => 'Payroll Run';

  @override
  String get ownerShellApprovalLimits => 'Approval Limits';

  @override
  String get ownerShellLedger => 'Ledger';

  @override
  String get ownerShellBranchesAccess => 'Branches & Access';

  @override
  String get ownerBottomDepartments => 'Departments';

  @override
  String get lockerDefaultUser => 'Owner';

  @override
  String get billingDashboardTitle => 'Billing Dashboard';

  @override
  String get billingGenerateTitle => 'Generate Bills';

  @override
  String get billingMonthlyTitle => 'Monthly Bills';

  @override
  String get billingOverdueTitle => 'Overdue Payments';

  @override
  String get billingDefaultTitle => 'Billing';

  @override
  String get billingSummaryTotalBilled => 'Total Billed';

  @override
  String get billingSummaryTotalReceived => 'Total Received';

  @override
  String get billingSummaryOutstanding => 'Outstanding';

  @override
  String get billingSummaryOverdue => 'Overdue';

  @override
  String get billingQuickActions => 'Quick Actions';

  @override
  String get billingRecentActivity => 'Recent Billing Activity';

  @override
  String get billingSeeAll => 'See All';

  @override
  String get billingNoRecentActivity => 'No recent activity';

  @override
  String get billingActionGenerate => 'Generate Bills';

  @override
  String get billingActionViewAll => 'View All Bills';

  @override
  String get billingActionRecordPayment => 'Record Payment';

  @override
  String get billingActionSendReminders => 'Send Reminders';

  @override
  String get billingGeneratorStep1 => 'Step 1: Select Billing Period';

  @override
  String get billingGeneratorStep2 => 'Step 2: Preview Eligible Invoices';

  @override
  String get billingGeneratorPendingInvoices =>
      'Pending Invoices: 15 • Est. Total: SAR 12,450';

  @override
  String get billingGeneratorPostAll => 'Generate & Post All';

  @override
  String billingPeriodLabel(String month, String year) {
    return 'Billing Period: $month/$year';
  }

  @override
  String get billingStatusPaid => 'Paid';

  @override
  String get billingStatusOverdue => 'Overdue';

  @override
  String get billingStatusPartiallyPaid => 'Partially Paid';

  @override
  String get billingStatusPending => 'Pending';

  @override
  String get branchManagementTitle => 'Branches';

  @override
  String get branchSearchHint => 'Search branches…';

  @override
  String get branchAddButton => 'Add Branch';

  @override
  String get branchEditButton => 'Edit';

  @override
  String get branchDeleteButton => 'Delete';

  @override
  String get branchNoBranches => 'No branches found';

  @override
  String get branchStatusActive => 'Active';

  @override
  String get branchStatusInactive => 'Inactive';

  @override
  String get branchFormTitleAdd => 'Add Branch';

  @override
  String get branchFormTitleEdit => 'Edit Branch';

  @override
  String get branchFormNameLabel => 'Branch Name';

  @override
  String get branchFormNameHint => 'Enter branch name';

  @override
  String get branchFormAddressLabel => 'Address';

  @override
  String get branchFormAddressHint => 'Search address…';

  @override
  String get branchFormLatLabel => 'GPS Latitude';

  @override
  String get branchFormLngLabel => 'GPS Longitude';

  @override
  String get branchFormStatusLabel => 'Active';

  @override
  String get branchFormSaveButton => 'Save Branch';

  @override
  String get branchFormUpdateButton => 'Update Branch';

  @override
  String get branchFormValidationError =>
      'Branch Name and Address are required';

  @override
  String get branchCreateSuccess => 'Branch Created Successfully';

  @override
  String get branchUpdateSuccess => 'Branch Updated Successfully';

  @override
  String get branchDeleteSuccess => 'Branch Deleted Successfully';

  @override
  String get branchSaveError => 'Failed to save branch';

  @override
  String get branchDeleteError => 'Failed to delete branch';

  @override
  String get branchDeleteConfirmTitle => 'Delete Branch';

  @override
  String get branchDeleteConfirmBody =>
      'Are you sure you want to delete this branch?';

  @override
  String get branchDeleteConfirmCancel => 'Cancel';

  @override
  String get branchDeleteConfirmDelete => 'Delete';

  @override
  String get lockerPortalTitle => 'Locker Portal';

  @override
  String get lockerPortalSubtitle => 'Secure asset management for your branch';

  @override
  String get lockerPortalAppBarTitle => 'LOCKER DASHBOARD';

  @override
  String get lockerSecureAssetManagement => 'SECURE ASSET MANAGEMENT';

  @override
  String get lockerEmail => 'Email';

  @override
  String get lockerEmailHint => 'Enter your email';

  @override
  String get lockerEmailRequired => 'Email is required';

  @override
  String get lockerPassword => 'Password';

  @override
  String get lockerPasswordHint => 'Enter your password';

  @override
  String get lockerPasswordRequired => 'Password is required';

  @override
  String get lockerForgotPassword => 'Forgot Password?';

  @override
  String get lockerContinue => 'Continue';

  @override
  String get lockerLoadingDashboard => 'Loading dashboard…';

  @override
  String get lockerFailedLoadDashboard => 'Failed to load dashboard';

  @override
  String get lockerUnexpectedError => 'An unexpected error occurred.';

  @override
  String get lockerRetry => 'Retry';

  @override
  String get lockerRefresh => 'Refresh';

  @override
  String get lockerSupervisorTab => 'SUPERVISOR';

  @override
  String get lockerCollectorTab => 'COLLECTOR';

  @override
  String get lockerLogOut => 'Log Out';

  @override
  String get lockerLogOutConfirm =>
      'Are you sure you want to log out of the Locker Portal?';

  @override
  String get lockerCancel => 'Cancel';

  @override
  String get lockerLogOutButton => 'Log Out';

  @override
  String get lockerWelcomeBack => 'WELCOME BACK';

  @override
  String get lockerRoleSupervisor => 'SUPERVISOR';

  @override
  String get lockerRoleManager => 'MANAGER';

  @override
  String get lockerRoleWorkshopOwner => 'WORKSHOP OWNER';

  @override
  String get lockerRoleWorkshopSupervisor => 'WORKSHOP SUPERVISOR';

  @override
  String get lockerRoleCollector => 'COLLECTOR';

  @override
  String get lockerRoleCollectionOfficer => 'COLLECTION OFFICER';

  @override
  String get lockerRoleWorkshopCollector => 'WORKSHOP COLLECTOR';

  @override
  String get lockerSupervisorOverview => 'SUPERVISOR OVERVIEW';

  @override
  String get lockerMyPerformance => 'MY PERFORMANCE';

  @override
  String get lockerKpiPending => 'PENDING';

  @override
  String get lockerKpiAwaiting => 'AWAITING';

  @override
  String get lockerKpiOverdue => 'OVERDUE';

  @override
  String get lockerKpiVariance => 'VARIANCE';

  @override
  String get lockerKpiOpenAssignments => 'OPEN ASSIGNMENTS';

  @override
  String get lockerKpiPendingApproval => 'PENDING APPROVAL';

  @override
  String get lockerKpiTodaysCollections => 'TODAY\'S COLLECTIONS';

  @override
  String get lockerKpiMonthlyCollected => 'MONTHLY COLLECTED';

  @override
  String get lockerCoreOperations => 'CORE OPERATIONS';

  @override
  String get lockerManageAllRequests => 'Manage All Requests';

  @override
  String get lockerStartCollection => 'Start Collection';

  @override
  String get lockerAssignOfficers => 'Assign Officers';

  @override
  String get lockerManageVarianceRequests => 'Manage Variance Requests';

  @override
  String get lockerFinancialAnalytics => 'Financial Analytics';

  @override
  String get lockerSearchHint => 'Search requests…';

  @override
  String get lockerLoadingRequests => 'Loading requests…';

  @override
  String get lockerNoRequestsFound => 'No requests found';

  @override
  String get lockerAdjustFilters => 'Try adjusting your search or filters.';

  @override
  String get lockerLockedCashAsset => 'LOCKED CASH ASSET';

  @override
  String get lockerTapToCollect => 'TAP TO COLLECT';

  @override
  String get lockerStatusAssigned => 'ASSIGNED';

  @override
  String get lockerStatusAwaiting => 'AWAITING';

  @override
  String get lockerStatusCollected => 'COLLECTED';

  @override
  String get lockerStatusApproved => 'APPROVED';

  @override
  String get lockerStatusRejected => 'REJECTED';

  @override
  String get lockerStatusMatched => 'MATCHED';

  @override
  String get lockerLoadingRequest => 'Loading request…';

  @override
  String get lockerFailedLoadDetails => 'Failed to load request details';

  @override
  String get lockerSystemStatus => 'SYSTEM STATUS';

  @override
  String get lockerTotalSecuredAsset => 'TOTAL SECURED ASSET';

  @override
  String get lockerCounterClosing => 'COUNTER CLOSING';

  @override
  String get lockerPhysicalCash => 'PHYSICAL CASH';

  @override
  String get lockerSystemTotal => 'SYSTEM TOTAL';

  @override
  String get lockerDifference => 'DIFFERENCE';

  @override
  String get lockerCollectionRecord => 'COLLECTION RECORD';

  @override
  String get lockerReceived => 'RECEIVED';

  @override
  String get lockerInternalData => 'INTERNAL DATA';

  @override
  String get lockerSourceBranch => 'SOURCE BRANCH';

  @override
  String get lockerCashier => 'CASHIER';

  @override
  String get lockerCashierIdentity => 'CASHIER';

  @override
  String get lockerShiftCloseTime => 'SHIFT CLOSE TIME';

  @override
  String get lockerSessionOpened => 'SESSION OPENED';

  @override
  String get lockerSessionClosed => 'SESSION CLOSED';

  @override
  String get lockerAssignedOfficer => 'ASSIGNED OFFICER';

  @override
  String get lockerAssignCollectionOfficer => 'Assign Collection Officer';

  @override
  String get lockerProceedToCollection => 'Proceed to Collection';

  @override
  String get lockerGenerateAuditPdf => 'Generate Audit PDF';

  @override
  String get lockerCollectionPendingApproval =>
      'Collection is pending supervisor approval.';

  @override
  String get lockerPendingSupervisorApproval => 'Pending supervisor approval';

  @override
  String get lockerCollectedSuccessfully => 'Collection recorded successfully';

  @override
  String get lockerVarianceApproved => 'Variance approved';

  @override
  String get lockerVarianceRejectedBanner => 'Variance rejected';

  @override
  String get lockerVarianceDifferenceReview =>
      'There is a variance in this collection. Please review and approve or reject.';

  @override
  String get lockerApproveVariance => 'Variance approved successfully';

  @override
  String get lockerApprove => 'Approve';

  @override
  String get lockerReject => 'Reject';

  @override
  String get lockerRejectVarianceTitle => 'Reject Variance';

  @override
  String get lockerRejectVarianceBody =>
      'Provide an optional reason for rejecting this variance.';

  @override
  String get lockerRejectionReasonHint => 'Enter rejection reason (optional)';

  @override
  String get lockerConfirmReject => 'Confirm Reject';

  @override
  String get corporateFieldMobileMobile => 'Mobile';

  @override
  String get corporateFieldTaxId => 'Tax ID (VAT)';

  @override
  String get corporateFieldStatus => 'Status';

  @override
  String get corporateSaveChanges => 'Save Changes';

  @override
  String get corporateStatusPending => 'Pending';

  @override
  String get corporateStatusActive => 'Active';

  @override
  String get corporateStatusRejected => 'Rejected';

  @override
  String get corporateCreateSuccess => 'Corporate Account Created Successfully';

  @override
  String get corporateCreateError => 'Failed to create corporate account';

  @override
  String get corporateUpdateSuccess => 'Corporate Account Updated Successfully';

  @override
  String get corporateUpdateError => 'Failed to update corporate account';

  @override
  String get corporateUserCreateSuccess =>
      'Corporate User Created Successfully';

  @override
  String get corporateUserCreateError => 'Failed to create corporate user';

  @override
  String get corporateValidationRequired =>
      'Please fill in all required fields';

  @override
  String get corporateValidationBranch => 'Please select at least one branch';

  @override
  String get corporateValidationCompanyName => 'Company name is required';

  @override
  String get dashboardAllBranches => 'All Branches';

  @override
  String get dashboardViewingDataFor => 'Viewing Data For';

  @override
  String get dashboardAllBranchesAggregated => 'All Branches Aggregated';

  @override
  String get dashboardSelectBranch => 'Select Branch';

  @override
  String get dashboardKpiTotalSalesToday => 'Total Sales Today';

  @override
  String get dashboardKpiThisMonth => 'This Month';

  @override
  String get dashboardKpiPendingInvoices => 'Pending Invoices';

  @override
  String get dashboardKpiLowStockAlerts => 'Low Stock Alerts';

  @override
  String get dashboardKpiTodaysSales => 'Today\'s Sales';

  @override
  String get dashboardKpiActiveOrders => 'Active Orders';

  @override
  String get dashboardKpiTechWorkload => 'Tech Workload';

  @override
  String get dashboardKpiPendingApproval => 'Pending Approval';

  @override
  String get dashboardPendingApprovalsTitle => 'Pending Approvals';

  @override
  String get dashboardViewAll => 'View All';

  @override
  String get dashboardNoPendingApprovals =>
      'No pending petty-cash approvals right now.';

  @override
  String dashboardMoreApprovals(int count) {
    return '+$count more in Approvals';
  }

  @override
  String get dashboardBranchPerformance => 'Branch Performance';

  @override
  String get dashboardBranchHighlights => 'Branch Highlights';

  @override
  String get dashboardBranchStatus => 'Branch Status';

  @override
  String get dashboardTotalStaff => 'Total Staff';

  @override
  String get dashboardSalesTarget => 'Sales Target';

  @override
  String get dashboardSalesTargetValue => '85% Achieved';

  @override
  String get branchPerformanceListTitle => 'Branch Performance';

  @override
  String get branchPerformanceNoBranches => 'No branches yet.';

  @override
  String get deptMgmtTitle => 'Department Management';

  @override
  String get deptMgmtSearchHint => 'Search by Department Name...';

  @override
  String get deptMgmtAddButton => 'Add New Department';

  @override
  String get deptMgmtNoDepartments => 'No departments found.';

  @override
  String get deptMgmtLabelDepartment => 'Department';

  @override
  String get deptMgmtMenuEdit => 'Edit';

  @override
  String get deptMgmtMenuDelete => 'Delete';

  @override
  String get deptMgmtConfirmDeleteTitle => 'Confirm Deletion';

  @override
  String deptMgmtConfirmDeleteBody(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get deptMgmtCancel => 'Cancel';

  @override
  String get deptMgmtDelete => 'Delete';

  @override
  String get deptMgmtStatusActive => 'ACTIVE';

  @override
  String get deptMgmtStatusInactive => 'INACTIVE';

  @override
  String get deptMgmtSheetAddTitle => 'Add Department';

  @override
  String get deptMgmtSheetUpdateTitle => 'Update Department';

  @override
  String get deptMgmtSheetAddSubtitle =>
      'Enter the name of the new department.';

  @override
  String get deptMgmtSheetUpdateSubtitle =>
      'Modify existing department details.';

  @override
  String get deptMgmtFieldName => 'Department Name';

  @override
  String get deptMgmtFieldActiveStatus => 'Active Status';

  @override
  String get deptMgmtSheetAddButton => 'Add Department';

  @override
  String get deptMgmtSheetUpdateButton => 'Update Department';

  @override
  String get deptMgmtValidationNameRequired => 'Department Name is required';

  @override
  String get deptMgmtCreateSuccess => 'Department Created Successfully';

  @override
  String get deptMgmtUpdateSuccess => 'Department Updated Successfully';

  @override
  String get deptMgmtDeleteSuccess => 'Department Deleted Successfully';

  @override
  String get deptMgmtSaveError => 'Failed to save department';

  @override
  String get deptMgmtDeleteError => 'Failed to delete department';

  @override
  String get empMgmtTitle => 'Employee Management';

  @override
  String get empMgmtSearchHint => 'Search by Name, Email or Mobile...';

  @override
  String get empMgmtAddButton => 'Add Employee';

  @override
  String get empMgmtFilterAllBranches => 'All Branches';

  @override
  String get empMgmtNoEmployees => 'No employees found.';

  @override
  String empMgmtLastSeen(String time) {
    return 'Last seen: $time';
  }

  @override
  String get empMgmtInfoBranch => 'BRANCH';

  @override
  String get empMgmtInfoDept => 'DEPT';

  @override
  String get empMgmtInfoRoleType => 'ROLE TYPE';

  @override
  String get empMgmtInfoTechType => 'TECH TYPE';

  @override
  String get empMgmtInfoSalary => 'SALARY';

  @override
  String get empMgmtInfoCommission => 'COMMISSION';

  @override
  String get empMgmtInfoUnknown => 'Unknown';

  @override
  String get empMgmtInfoNone => 'None';

  @override
  String get empMgmtMenuEdit => 'Edit';

  @override
  String get empMgmtMenuDelete => 'Delete';

  @override
  String get empMgmtDeleteTitle => 'Delete Employee';

  @override
  String empMgmtDeleteBody(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get empMgmtDeleteCancel => 'Cancel';

  @override
  String get empMgmtDeleteConfirm => 'Delete';

  @override
  String get empMgmtSheetAddTitle => 'Add New Employee';

  @override
  String get empMgmtSheetUpdateTitle => 'Update Employee';

  @override
  String get empMgmtSheetAddSubtitle =>
      'Provide detailed Information to register a new member.';

  @override
  String get empMgmtSheetUpdateSubtitle => 'Modify existing employee details.';

  @override
  String get empMgmtFieldRole => 'Role';

  @override
  String get empMgmtFieldFullName => 'Full Name';

  @override
  String get empMgmtFieldMobile => 'Mobile Number';

  @override
  String get empMgmtFieldEmail => 'Email Address';

  @override
  String get empMgmtFieldPassword => 'Password';

  @override
  String get empMgmtFieldPasswordOptional => 'Password (Optional)';

  @override
  String get empMgmtFieldBranch => 'Assign to Branch';

  @override
  String get empMgmtFieldDepartment => 'Assign Department';

  @override
  String get empMgmtFieldAddress => 'Address';

  @override
  String get empMgmtFieldOpeningBalance => 'Opening Balance';

  @override
  String get empMgmtFieldBaseSalary => 'Base Salary';

  @override
  String get empMgmtFieldCommission => 'Commission %';

  @override
  String get empMgmtFieldActiveStatus => 'Active Status';

  @override
  String get empMgmtSectionTechSpecifics => 'Technician Specifics';

  @override
  String get empMgmtSectionSalary => 'Salary & Commission';

  @override
  String get empMgmtSectionAvailability => 'Availability';

  @override
  String get empMgmtToggleWorkshop => 'Workshop Technician';

  @override
  String get empMgmtToggleOnCall => 'On-Call Technician';

  @override
  String get empMgmtNoAddressFound => 'No addresses found';

  @override
  String get empMgmtSaveButton => 'Save Employee';

  @override
  String get empMgmtUpdateButton => 'Update Employee';

  @override
  String get empMgmtRoleTechnician => 'Technician';

  @override
  String get empMgmtRoleCashier => 'Cashier';

  @override
  String get empMgmtRoleSupplier => 'Supplier';

  @override
  String get empMgmtValidationRequired =>
      'Please fill in all required text fields.';

  @override
  String get empMgmtValidationTechType =>
      'Please select at least one technician type.';

  @override
  String get empMgmtValidationNoBranch =>
      'Please create a branch first to assign this employee.';

  @override
  String get empMgmtValidationNoBranchCashier =>
      'Please create a branch first to assign this cashier.';

  @override
  String get empMgmtValidationNoDepartment =>
      'Please create a department first to assign this employee.';

  @override
  String get empMgmtValidationSupplierRequired =>
      'Please fill in all required fields';

  @override
  String get empMgmtApiNotIntegrated =>
      'Only Technician, Cashier, and Supplier creation APIs are integrated.';

  @override
  String get empMgmtTechnicianCreateSuccess =>
      'Technician Created Successfully';

  @override
  String get empMgmtTechnicianUpdateSuccess =>
      'Technician Updated Successfully';

  @override
  String get empMgmtTechnicianCreateError => 'Failed to create technician';

  @override
  String get empMgmtCashierCreateSuccess => 'Cashier Created Successfully';

  @override
  String get empMgmtCashierUpdateSuccess => 'Cashier Updated Successfully';

  @override
  String get empMgmtCashierCreateError => 'Failed to create cashier';

  @override
  String get empMgmtSupplierCreateSuccess => 'Supplier Created Successfully';

  @override
  String get empMgmtSupplierCreateError => 'Failed to create supplier';

  @override
  String get empMgmtDeleteSuccess => 'Employee Deleted Successfully';

  @override
  String get empMgmtDeleteError => 'Failed to delete employee';

  @override
  String get empStatusAvailable => 'AVAILABLE';

  @override
  String get empStatusOnline => 'ONLINE';

  @override
  String get empStatusBusy => 'BUSY';

  @override
  String get empStatusOffline => 'OFFLINE';

  @override
  String get empLastSeenNever => 'Never';

  @override
  String get empLastSeenJustNow => 'Just now';

  @override
  String empLastSeenMinutes(int m) {
    return '${m}m ago';
  }

  @override
  String empLastSeenHours(int h) {
    return '${h}h ago';
  }

  @override
  String empLastSeenDays(int d) {
    return '${d}d ago';
  }

  @override
  String get empTechTypeWorkshop => 'WORKSHOP';

  @override
  String get empTechTypeBoth => 'BOTH';

  @override
  String get empTechTypeOnCall => 'ON-CALL';

  @override
  String get empRoleTechnician => 'TECHNICIAN';

  @override
  String get empRoleCashier => 'CASHIER';

  @override
  String get empRoleSupplier => 'SUPPLIER';

  @override
  String get posAddCustomerTitle => 'Add New Order';

  @override
  String get posAddCustomerTabNormal => 'Normal Customer';

  @override
  String get posAddCustomerTabCorporate => 'Corporate Customer';

  @override
  String get posAddCustomerSectionVehicleInfo => 'Vehicle Information';

  @override
  String get posAddCustomerSectionCompanyDetails =>
      'Company Details (Auto-filled)';

  @override
  String get posAddCustomerSectionCorporateAccount => 'Corporate Account';

  @override
  String get posAddCustomerFieldVehicleNumber => 'Vehicle Number';

  @override
  String get posAddCustomerFieldVin => 'VIN';

  @override
  String get posAddCustomerFieldMake => 'Make';

  @override
  String get posAddCustomerFieldModel => 'Model';

  @override
  String get posAddCustomerFieldYear => 'Year';

  @override
  String get posAddCustomerFieldOdometer => 'Odometer';

  @override
  String get posAddCustomerFieldCompanyName => 'Company Name';

  @override
  String get posAddCustomerFieldVatNumber => 'VAT Number';

  @override
  String get posAddCustomerFieldBillingAddress => 'Billing Address';

  @override
  String get posAddCustomerSelectCorporate => 'Select Corporate Account';

  @override
  String get posAddCustomerNoCorporateFound => 'No Corporate Accounts Found';

  @override
  String get posAddCustomerSaveButton => 'Save & Proceed to Department';

  @override
  String get posAddCustomerFieldNA => 'N/A';

  @override
  String get posAddCustomerSectionCustomerInfo => 'Customer Information';

  @override
  String get posAddCustomerFieldCustomerName => 'Customer Name';

  @override
  String get posAddCustomerValidationVehicleRequired =>
      'Please enter vehicle number';

  @override
  String get posAddCustomerValidationVehiclePlateMaxFourDigits =>
      'Saudi plates allow at most 4 digits after the 3 letters';

  @override
  String get posAddCustomerValidationVehiclePlateMaxThreeLetters =>
      'Saudi plates allow exactly 3 letters before the digits';

  @override
  String get posAddCustomerVehicleKindCar => 'Car';

  @override
  String get posAddCustomerVehicleKindBike => 'Bike';

  @override
  String get posAddCustomerValidationBikePlateTwoLetters =>
      'Bike plates need exactly 2 letters before the 4 digits';

  @override
  String get posAddCustomerValidationBikePlateFourDigits =>
      'Bike plates need exactly 4 digits after the 2 letters';

  @override
  String get posAddCustomerValidationBikePlateMaxTwoLetters =>
      'Bike plates allow at most 2 letters before the digits';

  @override
  String get posGccPlateCountryLabel => 'Plate country';

  @override
  String get posGccPlateEmirateLabel => 'Emirate';

  @override
  String get posGccPlateValidationGccFormat =>
      'Enter letters and digits (e.g. ABC - 1234)';

  @override
  String get posGccPlateValidationEmirateRequired =>
      'Select emirate for UAE plates';

  @override
  String get posAddCustomerFleetVehiclesLoading => 'Loading fleet vehicles…';

  @override
  String get posAddCustomerNoFleetVehicles =>
      'No fleet vehicles on this account';

  @override
  String get posAddCustomerSelectFleetVehicle => 'Select fleet vehicle';

  @override
  String get posAddCustomerFleetVehicleManual => 'Enter plate manually';

  @override
  String get posAddCustomerValidationRequired => 'Required';

  @override
  String get posAddCustomerValidationVinMax => 'Max 17 characters';

  @override
  String get posAddCustomerValidationInvalidNumber =>
      'Please enter a valid number';

  @override
  String get posAddCustomerValidationInvalidNumberShort => 'Invalid number';

  @override
  String get posAddCustomerValidationMobileRequired => 'Enter mobile number';

  @override
  String get posAddCustomerValidationMobileSaudi =>
      'Enter a valid Saudi number (e.g. 05X XXX XXXX)';

  @override
  String get posAddCustomerValidationMobilePakistan =>
      'Enter a valid Pakistan mobile (e.g. 03XX XXXXXXX)';

  @override
  String get posMonitoringTitle => 'POS Monitoring';

  @override
  String get posMonitoringLiveCounters => 'Live Counters';

  @override
  String get posMonitoringClosingReports => 'Closing Reports';

  @override
  String get posMonitoringSummaryLiveCounters => 'Live Counters';

  @override
  String get posMonitoringSummaryOpenOrders => 'Open Orders';

  @override
  String get posMonitoringSummaryTodaySales => 'Today Sales';

  @override
  String get posMonitoringNoLiveCounters => 'No active live counters';

  @override
  String get posMonitoringNoClosingReports => 'No closing reports available';

  @override
  String get posMonitoringStatusOpen => 'OPEN';

  @override
  String get posMonitoringStatusClosing => 'CLOSING';

  @override
  String get posMonitoringStatusClosed => 'CLOSED';

  @override
  String get posMonitoringStatShiftSales => 'SHIFT SALES';

  @override
  String get posMonitoringStatOpenOrders => 'OPEN ORDERS';

  @override
  String get posMonitoringStatElapsed => 'ELAPSED';

  @override
  String posMonitoringElapsedFormat(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String get posMonitoringClosed => 'Closed';

  @override
  String get posMonitoringTableCategory => 'Category';

  @override
  String get posMonitoringTableSystem => 'System';

  @override
  String get posMonitoringTablePhysical => 'Physical';

  @override
  String get posMonitoringTableDiff => 'Diff';

  @override
  String get posMonitoringTableTotalSales => 'Total Sales';

  @override
  String get posMonitoringRowCash => 'Cash';

  @override
  String get posMonitoringRowBank => 'Bank/Cards';

  @override
  String get posMonitoringRowCorporate => 'Corporate';

  @override
  String get posMonitoringRowTamara => 'Tamara';

  @override
  String get posMonitoringRowTabby => 'Tabby';

  @override
  String get posMonitoringDiffShort => 'SHORT';

  @override
  String get posMonitoringDiffExcess => 'EXCESS';

  @override
  String get posMonitoringDiffBalanced => 'BALANCED';

  @override
  String posMonitoringDiffShortSymbol(String amount) {
    return '− SAR $amount';
  }

  @override
  String posMonitoringDiffExcessSymbol(String amount) {
    return '+ SAR $amount';
  }

  @override
  String get posMonitoringDiffNone => '—';

  @override
  String get posMonitoringBackendWarning =>
      '⚠ Full breakdown unavailable — deploy latest backend to see per-category data';

  @override
  String posMonitoringAmountSar(String amount) {
    return 'SAR $amount';
  }

  @override
  String get promoTitle => 'Promo Codes';

  @override
  String get promoNewButton => 'New Promo';

  @override
  String get promoNoCodesFound => 'No promo codes found';

  @override
  String get promoMenuEdit => 'Edit';

  @override
  String get promoMenuDelete => 'Delete';

  @override
  String promoDiscountOff(String value, String unit) {
    return '$value $unit OFF';
  }

  @override
  String get promoUnitPercent => '%';

  @override
  String get promoUnitSar => 'SAR';

  @override
  String get promoStatUsage => 'Usage';

  @override
  String get promoStatMinOrder => 'Min Order';

  @override
  String get promoStatValidTill => 'Valid Till';

  @override
  String promoMinOrderAmount(String amount) {
    return 'SAR $amount';
  }

  @override
  String get promoDeleteConfirmTitle => 'Confirm Deletion';

  @override
  String promoDeleteConfirmBody(String code) {
    return 'Are you sure you want to delete \"$code\"? This action cannot be undone.';
  }

  @override
  String get promoDeleteCancel => 'Cancel';

  @override
  String get promoDeleteConfirm => 'Delete';

  @override
  String get promoSheetCreateTitle => 'Create Promo Code';

  @override
  String get promoSheetUpdateTitle => 'Update Promo Code';

  @override
  String get promoSheetCreateSubtitle =>
      'Configure a new discount code for customers.';

  @override
  String get promoSheetUpdateSubtitle => 'Modify existing promo code details.';

  @override
  String get promoFieldCode => 'Promo Code (e.g., SUMMER20)';

  @override
  String get promoFieldDiscountValue => 'Discount Value';

  @override
  String get promoFieldUsageLimit => 'Usage Limit';

  @override
  String get promoFieldMinOrder => 'Min Order (SAR)';

  @override
  String get promoFieldDescription => 'Description';

  @override
  String get promoFieldValidFrom => 'Valid From';

  @override
  String get promoFieldValidTo => 'Valid To';

  @override
  String get promoTypeFixed => 'Fixed Amount';

  @override
  String get promoTypePercent => 'Percentage (%)';

  @override
  String get promoSubmitCreate => 'Create Promo';

  @override
  String get promoSubmitUpdate => 'Update Promo';

  @override
  String get promoValidationRequired =>
      'Please fill required fields (Code, Value)';

  @override
  String get promoCreateSuccess => 'Promo Code created successfully!';

  @override
  String get promoUpdateSuccess => 'Promo Code updated successfully!';

  @override
  String get promoDeleteSuccess => 'Promo Code deleted successfully!';

  @override
  String get promoCreateError => 'Failed to process promo code';

  @override
  String get promoDeleteError => 'Failed to delete promo code';

  @override
  String get lockerVarianceRejected => 'Variance rejected';

  @override
  String get lockerSelectOfficer => 'SELECT OFFICER';

  @override
  String get lockerSelectOfficerSubtitle =>
      'Choose a field officer to assign to this collection request.';

  @override
  String get lockerOfficersLoadError => 'Could not load officers.';

  @override
  String get lockerAssignedTo => 'Assigned to';

  @override
  String get lockerLoaderAuditReport => 'Locker Audit Report';

  @override
  String get lockerGeneratedAt => 'Generated at';

  @override
  String get lockerPage => 'Page';

  @override
  String get lockerOf => 'of';

  @override
  String get lockerRequestInformation => 'REQUEST INFORMATION';

  @override
  String get lockerPosSession => 'POS SESSION';

  @override
  String get lockerOpenedAt => 'Opened At';

  @override
  String get lockerClosedAt => 'Closed At';

  @override
  String get lockerSessionStatus => 'Session Status';

  @override
  String get lockerReceivedAmount => 'Received Amount';

  @override
  String get lockerNotes => 'Notes';

  @override
  String get lockerAuditFootnote =>
      'This report is system-generated and serves as an official audit record.';

  @override
  String lockerAuditFootnoteAmounts(String currency) {
    return 'All amounts are in $currency.';
  }

  @override
  String lockerCurrencyPrefix(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get lockerSarCurrency => 'SAR';

  @override
  String get lockerLoadingVariance => 'Loading variance approvals…';

  @override
  String get lockerFailedLoadVariance => 'Failed to load variance approvals';

  @override
  String get lockerAllClear => 'All Clear!';

  @override
  String get lockerNoPendingVariance =>
      'No pending variance approvals at this time.';

  @override
  String get lockerVarianceReviewBanner =>
      'These collections have a cash variance and require your approval.';

  @override
  String get lockerShortLabel => 'SHORT';

  @override
  String get lockerOverLabel => 'OVER';

  @override
  String get lockerApproveVarianceTitle => 'Approve Variance';

  @override
  String lockerApproveVarianceConfirm(
    String type,
    String amount,
    String branch,
  ) {
    return 'Approve $type variance of SAR $amount for $branch?';
  }

  @override
  String get lockerApproveSuccess => 'Variance approved successfully';

  @override
  String get lockerRejectSuccess => 'Variance rejected';

  @override
  String get lockerRejectVarianceDialogTitle => 'Reject Variance';

  @override
  String lockerRejectingFor(String branch) {
    return 'Rejecting variance for $branch.';
  }

  @override
  String get lockerRejectionReasonOptional => 'Reason (optional)';

  @override
  String get lockerShortVariance => 'SHORT';

  @override
  String get lockerOverVariance => 'OVER';

  @override
  String get lockerCashierLabel => 'CASHIER';

  @override
  String get lockerOfficerLabel => 'OFFICER';

  @override
  String get lockerExpected => 'EXPECTED';

  @override
  String get lockerReceivedLabel => 'RECEIVED';

  @override
  String get lockerDiffLabel => 'DIFF';

  @override
  String get lockerRecordCollectionTitle => 'RECORD COLLECTION';

  @override
  String get lockerExpectedAmount => 'EXPECTED AMOUNT';

  @override
  String get lockerVerifiedReceivedAmount => 'VERIFIED RECEIVED AMOUNT';

  @override
  String get lockerLockedAmount => 'LOCKED AMOUNT';

  @override
  String get lockerReceivedAmountLabel => 'RECEIVED AMOUNT';

  @override
  String get lockerCollectionNotes => 'COLLECTION NOTES';

  @override
  String get lockerCollectionNotesHint =>
      'Enter any remarks or reason for difference…';

  @override
  String get lockerCollectionEvidence => 'COLLECTION EVIDENCE';

  @override
  String get lockerCapturePhoto => 'CAPTURE PHOTO';

  @override
  String get lockerAttachLogs => 'ATTACH LOGS';

  @override
  String get lockerConfirmFinalise => 'CONFIRM & FINALISE ASSET';

  @override
  String get lockerSuccessPendingApproval => 'PENDING APPROVAL';

  @override
  String get lockerSuccessCollectionRecorded => 'COLLECTION RECORDED';

  @override
  String get lockerStatusReview => 'REVIEW';

  @override
  String get lockerStatusOk => 'OK';

  @override
  String get lockerStatusLabel => 'STATUS';

  @override
  String get lockerDone => 'DONE';

  @override
  String get lockerNotificationsTitle => 'NOTIFICATIONS';

  @override
  String get lockerSessionExpired => 'Session expired. Please log in again.';

  @override
  String get lockerSomethingWentWrong => 'Something went wrong.';

  @override
  String get lockerCouldNotRefresh => 'Could not refresh.';

  @override
  String get lockerNoNotificationsYet => 'No notifications yet.';

  @override
  String get lockerTryAgain => 'TRY AGAIN';

  @override
  String get lockerFinancialReports => 'FINANCIAL REPORTS';

  @override
  String get lockerTabHistory => 'HISTORY';

  @override
  String get lockerTabAnalytics => 'ANALYTICS';

  @override
  String get lockerSearchByRefOrOfficer => 'Search by Ref or Officer…';

  @override
  String get lockerAuditLogs => 'AUDIT LOGS';

  @override
  String lockerRecordsCount(int count) {
    return '$count records';
  }

  @override
  String get lockerExportPdf => 'PDF';

  @override
  String get lockerExportExcel => 'EXCEL';

  @override
  String get lockerDifferencesSummary => 'DIFFERENCES SUMMARY';

  @override
  String get lockerTotalShort => 'TOTAL SHORT';

  @override
  String get lockerTotalOver => 'TOTAL OVER';

  @override
  String get lockerNetDifference => 'NET DIFFERENCE';

  @override
  String get lockerTotalCollections => 'TOTAL COLLECTIONS';

  @override
  String get lockerMyCollectionPerformance => 'MY COLLECTION PERFORMANCE';

  @override
  String get lockerCollectionPerformance => 'COLLECTION PERFORMANCE';

  @override
  String get lockerOfficerComplianceRatings => 'OFFICER COMPLIANCE RATINGS';

  @override
  String get lockerNoComplianceData => 'No compliance data for this period.';

  @override
  String get lockerNoResultsMatchFilters => 'No results match your filters.';

  @override
  String get lockerNoAuditLogsFound => 'No audit logs found.';

  @override
  String get lockerAnErrorOccurred => 'An error occurred.';

  @override
  String get lockerAllRecords => 'All records';

  @override
  String get lockerFilterSearch => 'Search';

  @override
  String get lockerFilterBranch => 'Branch';

  @override
  String get lockerFilterByBranch => 'Filter by Branch…';

  @override
  String get lockerLoadingBranches => 'Loading branches…';

  @override
  String get lockerSortBy => 'SORT BY';

  @override
  String get lockerSortDate => 'Date';

  @override
  String get lockerSortReceivedAmount => 'Received Amount';

  @override
  String get lockerSortDifference => 'Difference';

  @override
  String get lockerSortAsc => 'ASC';

  @override
  String get lockerSortDesc => 'DESC';

  @override
  String get lockerSelectDateRange => 'Select Date Range';

  @override
  String get lockerDateFrom => 'FROM';

  @override
  String get lockerDateTo => 'TO';

  @override
  String get lockerTapToSet => 'Tap to set';

  @override
  String get lockerApplyFilter => 'Apply';

  @override
  String get lockerClearFilters => 'CLEAR';

  @override
  String get lockerNoData => 'No data';

  @override
  String get lockerWeeklyCollectionVolume => 'WEEKLY COLLECTION VOLUME';

  @override
  String get lockerTransactionRef => 'TRANSACTION REF';

  @override
  String get lockerReceivedFundLabel => 'RECEIVED FUND';

  @override
  String get lockerOneCollection => '1 collection';

  @override
  String lockerNCollections(int count) {
    return '$count collections';
  }

  @override
  String get lockerStoragePermissionRequired => 'Storage Permission Required';

  @override
  String get lockerStoragePermissionBody =>
      'Storage permission is required to save exported files. Please enable it in app settings.';

  @override
  String get lockerOpenSettings => 'Open Settings';

  @override
  String get lockerFinancialHistoryPdfTitle => 'Locker Financial History';

  @override
  String get lockerPdfGenerated => 'Generated';

  @override
  String get lockerPdfTotal => 'Total';

  @override
  String get lockerPdfRecords => 'records';

  @override
  String get lockerPdfRef => 'REF';

  @override
  String get lockerPdfDate => 'DATE';

  @override
  String get lockerPdfBranch => 'BRANCH';

  @override
  String get lockerPdfReceived => 'RECEIVED';

  @override
  String get lockerPdfExpected => 'EXPECTED';

  @override
  String get lockerPdfDiff => 'DIFF';

  @override
  String get lockerPdfStatus => 'STATUS';

  @override
  String get lockerPdfExportFailed => 'PDF export failed';

  @override
  String get lockerExcelSheetName => 'Locker History';

  @override
  String get lockerExcelOfficer => 'Officer';

  @override
  String get lockerExcelReceivedSar => 'Received (SAR)';

  @override
  String get lockerExcelExpectedSar => 'Expected (SAR)';

  @override
  String get lockerExcelDiffSar => 'Difference (SAR)';

  @override
  String get lockerExcelRequestRef => 'Request Ref';

  @override
  String get lockerExcelExportFailed => 'Excel export failed';

  @override
  String get accountingTitle => 'Accounting';

  @override
  String get accountingTabPayables => 'Payables';

  @override
  String get accountingTabReceivables => 'Receivables';

  @override
  String get accountingTabExpenses => 'Expenses';

  @override
  String get accountingTabAdvances => 'Advances';

  @override
  String get accountingPayables => 'Payables';

  @override
  String get accountingReceivables => 'Receivables';

  @override
  String get accountingOverdue => 'Overdue';

  @override
  String get accountingNoEntries => 'No entries found';

  @override
  String accountingRefPrefix(String ref, String date) {
    return 'Ref: $ref • $date';
  }

  @override
  String get accountingStatusOverdue => 'OVERDUE';

  @override
  String get accountingStatusSettled => 'SETTLED';

  @override
  String get accountingStatusPending => 'PENDING';

  @override
  String get accountingLoadingError => 'Failed to load accounting data';

  @override
  String accountingAmountLabel(String amount) {
    return 'SAR $amount';
  }

  @override
  String get approvalsTitle => 'Approvals';

  @override
  String get approvalsQueueLabel => 'Queue';

  @override
  String get approvalsStatusLabel => 'Status';

  @override
  String get approvalsQueueAll => 'All';

  @override
  String get approvalsQueueTopUps => 'Top-ups';

  @override
  String get approvalsQueueExpenses => 'Expenses';

  @override
  String get approvalsStatusAll => 'All';

  @override
  String get approvalsStatusPending => 'Pending';

  @override
  String get approvalsStatusApproved => 'Approved';

  @override
  String get approvalsStatusRejected => 'Rejected';

  @override
  String get approvalsEmptyExpenses => 'No expense approvals';

  @override
  String get approvalsEmptyPettyCash => 'No petty cash requests';

  @override
  String get approvalsEmptySubtitle => 'No records for this queue and status.';

  @override
  String get approvalsNoAddressesFound => 'No addresses found.';

  @override
  String get approvalsLoadingError => 'Failed to load approvals';

  @override
  String get approvalsApproveConfirm => 'Approve this request?';

  @override
  String get approvalsRejectTitle => 'Reject Request';

  @override
  String get approvalsRejectHint => 'Enter rejection reason (optional)';

  @override
  String get approvalsConfirmReject => 'Confirm Reject';

  @override
  String get approvalsCancel => 'Cancel';

  @override
  String get ownerLoginTitle => 'Workshop Owner';

  @override
  String get ownerLoginSubtitle => 'Sign in to your dashboard';

  @override
  String get ownerLoginEmail => 'Email';

  @override
  String get ownerLoginEmailHint => 'Enter your email';

  @override
  String get ownerLoginEmailRequired => 'Please enter your email';

  @override
  String get ownerLoginPassword => 'Password';

  @override
  String get ownerLoginPasswordHint => 'Enter your password';

  @override
  String get ownerLoginPasswordRequired => 'Please enter your password';

  @override
  String get ownerLoginForgotPassword => 'Forgot Password?';

  @override
  String get ownerLoginSignIn => 'Sign In';

  @override
  String get ownerLoginSuccess => 'Login successful';

  @override
  String get ownerLoginFailed => 'Login failed';

  @override
  String get ownerLoginNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get ownerRegisterTitle => 'Create Account';

  @override
  String get ownerRegisterSubtitle => 'Register your workshop';

  @override
  String get ownerRegisterWorkshopName => 'Workshop Name';

  @override
  String get ownerRegisterWorkshopNameHint => 'Enter workshop name';

  @override
  String get ownerRegisterOwnerName => 'Owner Name';

  @override
  String get ownerRegisterOwnerNameHint => 'Enter full name';

  @override
  String get ownerRegisterEmail => 'Email Address';

  @override
  String get ownerRegisterEmailHint => 'Enter email address';

  @override
  String get ownerRegisterMobile => 'Mobile Number';

  @override
  String get ownerRegisterMobileHint => '+966...';

  @override
  String get ownerRegisterTaxId => 'Tax ID';

  @override
  String get ownerRegisterTaxIdHint => 'Enter Tax ID';

  @override
  String get ownerRegisterAddress => 'Address';

  @override
  String get ownerRegisterAddressHint => 'Search and select full address';

  @override
  String get ownerRegisterPassword => 'Password';

  @override
  String get ownerRegisterPasswordHint => 'Create a password';

  @override
  String get ownerRegisterButton => 'Register';

  @override
  String get ownerRegisterSuccess => 'Registration successful. Please login.';

  @override
  String get ownerRegisterFailed => 'Registration failed';

  @override
  String get ownerRegisterFieldRequired => 'Required';

  @override
  String get ownerRegisterHaveAccount => 'Already have an account? Sign in';

  @override
  String get corporateManagementTitle => 'Corporate Management';

  @override
  String get corporateSearchHint => 'Search by Company or VAT...';

  @override
  String get corporateAddButton => 'Add Corporate';

  @override
  String get corporateNoneFound => 'No corporate customers found.';

  @override
  String corporateVatLabel(String vat) {
    return 'VAT: $vat';
  }

  @override
  String get corporateVehiclesLabel => 'VEHICLES';

  @override
  String get corporateRevenueLabel => 'REVENUE';

  @override
  String get corporateAddUser => 'Add User';

  @override
  String get corporateEdit => 'Edit';

  @override
  String get corporateRegisterTitle => 'Register Corporate Partner';

  @override
  String get corporateRegisterSubtitle =>
      'Fill in the details to create a new corporate account.';

  @override
  String get corporateFieldCompanyName => 'Company Name';

  @override
  String get corporateFieldCustomerName => 'Customer Name';

  @override
  String get corporateFieldMobile => 'Mobile Number';

  @override
  String get corporateFieldVat => 'VAT Number';

  @override
  String get corporateFieldEmail => 'Email Address';

  @override
  String get corporateFieldPassword => 'Password';

  @override
  String get corporateFieldReferral => 'Referral';

  @override
  String get corporateSelectBranches => 'Select Branches';

  @override
  String corporateSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get corporateNoBranches => 'No branches found';

  @override
  String get corporateCreateButton => 'Create Partner';

  @override
  String get corporateAddUserTitle => 'Add Corporate User';

  @override
  String get corporateAddUserSubtitle =>
      'Create credentials for a user associated with this corporate account.';

  @override
  String get corporateUserFieldName => 'Full Name';

  @override
  String get corporateUserFieldEmail => 'Email Address';

  @override
  String get corporateUserFieldPassword => 'Password';

  @override
  String get corporateCreateUserButton => 'Create User';

  @override
  String get corporateEditTitle => 'Edit Corporate Account';

  @override
  String get corporateEditSubtitle =>
      'Update the details below. Only changed fields will be sent.';

  @override
  String get invTitle => 'Inventory & Products';

  @override
  String get invTabProducts => 'PRODUCTS';

  @override
  String get invTabServices => 'SERVICES';

  @override
  String get invTabCategory => 'CATEGORY';

  @override
  String get invAddProduct => 'Add Product';

  @override
  String get invAddService => 'Add Service';

  @override
  String get invAddCategory => 'Add Category';

  @override
  String get invAdd => 'Add';

  @override
  String get invSearchProductsHint => 'Search by name or category...';

  @override
  String get invSearchServicesHint => 'Search services...';

  @override
  String get invSearchCategoriesHint => 'Search categories...';

  @override
  String get invNoProductsFound => 'No products found.';

  @override
  String get invNoServicesFound => 'No services found.';

  @override
  String get invNoCategoriesFound => 'No categories found.';

  @override
  String get invNoProductsMatchSearch =>
      'No products found matching your search.';

  @override
  String get invNoServicesMatchSearch =>
      'No services found matching your search.';

  @override
  String get invNoCategoriesMatchSearch =>
      'No categories found matching your search.';

  @override
  String get invMetricStock => 'STOCK';

  @override
  String get invMetricPurchase => 'PURCHASE';

  @override
  String get invMetricRetail => 'RETAIL';

  @override
  String get invMetricPrice => 'PRICE';

  @override
  String get invMetricCorpRange => 'CORP RANGE';

  @override
  String get invMetricCorporate => 'CORPORATE';

  @override
  String get invEditTooltip => 'Edit';

  @override
  String get invDeleteTooltip => 'Delete';

  @override
  String get invMenuEdit => 'Edit';

  @override
  String get invMenuDelete => 'Delete';

  @override
  String get invConfirmDeleteTitle => 'Confirm Deletion';

  @override
  String invConfirmDeleteBody(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get invCancel => 'Cancel';

  @override
  String get invConfirm => 'Confirm';

  @override
  String get invCategoryTabProducts => 'Products';

  @override
  String get invCategoryTabServices => 'Services';

  @override
  String get invCreateProduct => 'Create Product';

  @override
  String get invUpdateProduct => 'Update Product';

  @override
  String get invCreateProductSubtitle =>
      'Enter product details to add to inventory.';

  @override
  String get invUpdateProductSubtitle => 'Modify existing product details.';

  @override
  String get invFieldBranch => 'Branch';

  @override
  String get invFieldDepartment => 'Department';

  @override
  String get invFieldCategory => 'Category';

  @override
  String get invFieldProductName => 'Product Name';

  @override
  String get invFieldStockQty => 'Stock Quantity';

  @override
  String get invFieldUnit => 'Unit';

  @override
  String get invFieldCriticalStock => 'Critical Stock Point';

  @override
  String get invSectionPricing => 'Pricing Details';

  @override
  String get invFieldPurchasePrice => 'Purchase Price';

  @override
  String get invFieldSalePrice => 'Sale Price';

  @override
  String get invFieldMinCorpPrice => 'Min Corp Price';

  @override
  String get invFieldMaxCorpPrice => 'Max Corp Price';

  @override
  String get invToggleDecimal => 'Allow Decimal Point';

  @override
  String get invToggleActive => 'Active Status';

  @override
  String get invSaveProduct => 'Save Product';

  @override
  String get invProductCreateSuccess => 'Product Created Successfully';

  @override
  String get invProductUpdateSuccess => 'Product Updated Successfully';

  @override
  String get invProductCreateError => 'Failed to create product';

  @override
  String get invProductDeleteSuccess => 'Product Deleted Successfully';

  @override
  String get invProductDeleteError => 'Failed to delete product';

  @override
  String get invValidationFillRequired => 'Please fill in all required fields.';

  @override
  String get invValidationSelectDepartment => 'Please select a department.';

  @override
  String get invValidationCreateCategory => 'Please create a category first.';

  @override
  String get invValidationSelectBranch => 'Please select a branch.';

  @override
  String get invCreateService => 'Create Service';

  @override
  String get invUpdateService => 'Update Service';

  @override
  String get invCreateServiceSubtitle => 'Enter service details.';

  @override
  String get invUpdateServiceSubtitle => 'Modify existing service details.';

  @override
  String get invFieldServiceName => 'Service Name';

  @override
  String get invFieldServicePrice => 'Service Price';

  @override
  String get invTogglePriceEditable => 'Cashier can change price on POS';

  @override
  String get invSaveService => 'Save Service';

  @override
  String get invServiceCreateSuccess => 'Service Created Successfully';

  @override
  String get invServiceUpdateSuccess => 'Service Updated Successfully';

  @override
  String get invServiceCreateError => 'Failed to create service';

  @override
  String get invServiceDeleteSuccess => 'Service Deleted Successfully';

  @override
  String get invServiceDeleteError => 'Failed to delete service';

  @override
  String get invValidationFillServiceRequired =>
      'Please fill in required fields.';

  @override
  String get invCreateCategory => 'Create Category';

  @override
  String get invUpdateCategory => 'Update Category';

  @override
  String get invCreateCategorySubtitle => 'Enter details for the new category.';

  @override
  String get invUpdateCategorySubtitle => 'Modify existing category details.';

  @override
  String get invFieldCategoryName => 'Category Name';

  @override
  String get invSaveCategory => 'Save Category';

  @override
  String get invCategoryCreateSuccess => 'Category Created Successfully';

  @override
  String get invCategoryUpdateSuccess => 'Category Updated Successfully';

  @override
  String get invCategoryCreateError => 'Failed to create category';

  @override
  String get invCategoryDeleteSuccess => 'Category Deleted Successfully';

  @override
  String get invCategoryDeleteError => 'Failed to delete category';

  @override
  String get invCreateSubCategory => 'Create Sub Category';

  @override
  String get invCreateSubCategorySubtitle =>
      'Enter details for the new sub category.';

  @override
  String get invFieldSubCategoryName => 'Sub Category Name';

  @override
  String get invSaveSubCategory => 'Save Sub Category';

  @override
  String get invSubCategoryCreateSuccess => 'Sub Category Created Successfully';

  @override
  String get invSubCategoryUpdateSuccess => 'Sub Category Updated Successfully';

  @override
  String get invSubCategoryCreateError => 'Failed to create sub category';

  @override
  String get invSubCategoryDeleteSuccess => 'Sub Category Deleted Successfully';

  @override
  String get invSubCategoryDeleteError => 'Failed to delete sub category';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifMarkRead => 'Mark all as read';

  @override
  String get notifEmpty => 'No notifications yet.';

  @override
  String notifTimeMinutes(int m) {
    return '${m}m ago';
  }

  @override
  String notifTimeHours(int h) {
    return '${h}h ago';
  }

  @override
  String notifTimeDays(int d) {
    return '${d}d ago';
  }

  @override
  String get notifTypeExpense => 'expense';

  @override
  String get notifTypeStock => 'stock';

  @override
  String get notifTypePayment => 'payment';

  @override
  String get notifTypeLocker => 'locker';

  @override
  String get notifTypeInvoice => 'invoice';

  @override
  String get reportsTitle => 'Reports & Analytics';

  @override
  String get reportsFinancialOverview => 'Financial Overview';

  @override
  String get reportsOperationalPerformance => 'Operational Performance';

  @override
  String get reportsInventoryValuation => 'Inventory Valuation';

  @override
  String get reportsTotalRevenue => 'Total Revenue';

  @override
  String get reportsNoDataThisWeek => 'No data for this week';

  @override
  String reportsTotalJobs(int count) {
    return 'Total Jobs: $count';
  }

  @override
  String get reportsCommissionLabel => 'Commission';

  @override
  String get reportsStockValueCost => 'Stock Value (Cost)';

  @override
  String get reportsPotentialProfit => 'Potential Profit';

  @override
  String get reportsActiveSkus => 'Active SKUs';

  @override
  String reportsItemsUnit(int count) {
    return '$count Items';
  }

  @override
  String reportsAmountSar(String amount) {
    return 'SAR $amount';
  }

  @override
  String get reportsNoOperationalData => 'No operational performance data';

  @override
  String reportsRevChangePositive(String pct) {
    return '+$pct%';
  }

  @override
  String reportsRevChangeNegative(String pct) {
    return '$pct%';
  }

  @override
  String get posCurrentShiftTitle => 'Current Shift';

  @override
  String get posCurrentShiftDetails => 'SHIFT DETAILS';

  @override
  String get posCurrentShiftNoActiveSession => 'No active session.';

  @override
  String get posCurrentShiftNoActiveShiftFound => 'No active shift found.';

  @override
  String get posCurrentShiftRetry => 'Retry';

  @override
  String get posCurrentShiftSessionExpiredError =>
      'Session expired. Please sign in again.';

  @override
  String posCurrentShiftFetchError(String error) {
    return 'Failed to fetch shift details: $error';
  }

  @override
  String get posCurrentShiftLabelCashier => 'Cashier';

  @override
  String get posCurrentShiftLabelSessionId => 'Session ID';

  @override
  String get posCurrentShiftLabelBranch => 'Branch';

  @override
  String get posCurrentShiftLabelElapsedTime => 'Elapsed Time';

  @override
  String get posCurrentShiftLabelOpenedAt => 'Opened At';

  @override
  String get posCurrentShiftLabelBranchAddress => 'Branch Address';

  @override
  String get posBroadcastTitle => 'BROADCAST';

  @override
  String get posBroadcastHeading => 'Technician broadcasts';

  @override
  String get posBroadcastNoActive => 'No active broadcasts';

  @override
  String posBroadcastCountActive(int count, String window) {
    return '$count active · $window per item';
  }

  @override
  String get posBroadcastRetry => 'Retry';

  @override
  String get posBroadcastLabelSoon => 'Soon';

  @override
  String get posBroadcastLabelClosed => 'Closed';

  @override
  String get posBroadcastLabelRemaining => 'remaining';

  @override
  String get posBroadcastLabelExpired => 'Expired';

  @override
  String posBroadcastWindow(String m, String s) {
    return '$m:$s window';
  }

  @override
  String get posBroadcastTypeOnCall => 'On call';

  @override
  String get posBroadcastTypeWorkshop => 'Workshop';

  @override
  String get posBroadcastSessionExpired =>
      'Session expired. Please sign in again.';

  @override
  String get posCorporateBookingsTitle => 'Corporate Bookings';

  @override
  String get posCorporateFilterAll => 'All';

  @override
  String get posCorporateFilterToday => 'Today';

  @override
  String get posCorporateFilterPending => 'Pending';

  @override
  String get posCorporateFilterApprove => 'Approve';

  @override
  String get posCorporateFilterCancelled => 'Cancelled';

  @override
  String get posCorporateSearchHint => 'Search plate, booking code, company...';

  @override
  String get posCorporateNoBookingsTitle => 'No Bookings Found';

  @override
  String get posCorporateNoBookingsSubtitle =>
      'There are no corporate bookings for the selected filter.';

  @override
  String get posCorporateCardLabelVehicle => 'Vehicle';

  @override
  String get posCorporateCardLabelPlate => 'Plate';

  @override
  String get posCorporateCardLabelDepartment => 'Department';

  @override
  String get posCorporateCardLabelDate => 'Date';

  @override
  String get posCorporateCardLabelCompany => 'Company';

  @override
  String get posCorporateActionDetails => 'Details';

  @override
  String get posCorporateActionReject => 'Reject';

  @override
  String get posCorporateActionApprove => 'Approve';

  @override
  String get posCorporateActionContinue => 'Continue';

  @override
  String get posCorporateActionApproveBooking => 'Approve Booking';

  @override
  String get posCorporateActionClose => 'Close';

  @override
  String get posCorporateActionSubmitReason => 'Submit Reason';

  @override
  String get posCorporateActionCancel => 'Cancel';

  @override
  String get posCorporateDialogDetailsTitle => 'Corporate Booking Details';

  @override
  String get posCorporateDialogRejectTitle => 'Booking Details';

  @override
  String posCorporateDialogRejectBody(String action, String company) {
    return 'Please provide a reason to $action this booking for $company. This information will be sent back to the corporate portal.';
  }

  @override
  String get posCorporateDialogReasonLabel => 'Reason';

  @override
  String get posCorporateDialogReasonHint => 'Enter your reason here...';

  @override
  String posCorporateDialogReasonRequired(String action) {
    return 'Please provide a reason to $action.';
  }

  @override
  String get posCorporateDetailsSectionBooking => 'Booking Details';

  @override
  String get posCorporateDetailsSectionVehicle => 'Vehicle Information';

  @override
  String get posCorporateDetailsSectionProducts => 'Requested Products';

  @override
  String get posCorporateDetailsBookingId => 'Booking ID';

  @override
  String get posCorporateDetailsScheduledTime => 'Scheduled Time';

  @override
  String get posCorporateDetailsDepartment => 'Department';

  @override
  String get posCorporateDetailsRejectionReason => 'Rejection reason';

  @override
  String get posCorporateDetailsVehicleName => 'Vehicle Name';

  @override
  String get posCorporateDetailsLicensePlate => 'License Plate';

  @override
  String get posCorporateDetailsNoProducts =>
      'No specific products requested. Open matching department.';

  @override
  String posCorporateDetailsQty(String qty) {
    return 'Qty: $qty';
  }

  @override
  String posCorporateDetailsProductId(String id) {
    return 'Product ID: $id';
  }

  @override
  String get posCorporateApproveError => 'Failed to approve booking';

  @override
  String get posCorporateRejectSuccess => 'Booking Rejected. Portal updated.';

  @override
  String get posCorporateRejectError => 'Failed to reject booking';

  @override
  String get posCorporateNoMatchingOrder =>
      'No matching order found for this booking yet. Please refresh and try again.';

  @override
  String get posCorporateLoadError => 'Failed to load bookings';

  @override
  String get posCorporateAuthTokenNotFound => 'Authentication token not found';

  @override
  String get posCorporateStatusCancelled => 'Cancelled';

  @override
  String get posCorporateStatusRejected => 'Rejected';

  @override
  String get posCorporateStatusPending => 'Pending';

  @override
  String get posCorporateStatusApproved => 'Approved';

  @override
  String get posCorporateStatusInProgress => 'In Progress';

  @override
  String get posCorporateStatusCompleted => 'Completed';

  @override
  String get posCorporateStatusWaitingApproval => 'Waiting Approval';

  @override
  String get posBroadcastActionReject => 'Reject';

  @override
  String get ownerCommonSearchHint => 'Search...';

  @override
  String get ownerBottomHome => 'Home';

  @override
  String get ownerBottomReports => 'Reports';

  @override
  String get ownerBottomBilling => 'Billing';

  @override
  String get ownerBottomProfile => 'Profile';

  @override
  String get ownerDashboardRoleLabel => 'WORKSHOP OWNER';

  @override
  String get ownerMonthlySales => 'Monthly Sales';

  @override
  String get ownerCurrencySar => 'SAR';

  @override
  String ownerCurrencyAmount(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get pettyCashQueueCashierExpense => 'CASHIER EXPENSE';

  @override
  String get pettyCashQueueFundRequest => 'FUND REQUEST';

  @override
  String get pettyCashRequestLabel => 'Petty cash request';

  @override
  String get pettyCashApprove => 'Approve';

  @override
  String get pettyCashReject => 'Reject';

  @override
  String get pettyCashConfirmReject => 'Confirm Reject';

  @override
  String get pettyCashRejectRequestTitle => 'Reject Request';

  @override
  String get pettyCashRejectRequestBody =>
      'Please provide a reason for rejection.';

  @override
  String get pettyCashRejectReasonHint => 'e.g. Budget not approved';

  @override
  String get pettyCashRejectReasonRequired => 'Please enter a rejection reason';

  @override
  String get pettyCashRequestApprovedSuccess => 'Request approved successfully';

  @override
  String get pettyCashRequestApproveFailed => 'Failed to approve request';

  @override
  String get pettyCashRequestRejectedSuccess => 'Request rejected successfully';

  @override
  String get pettyCashRequestRejectFailed => 'Failed to reject request';

  @override
  String get pettyCashStatusPending => 'PENDING';

  @override
  String get pettyCashStatusApproved => 'APPROVED';

  @override
  String get pettyCashStatusRejected => 'REJECTED';

  @override
  String pettyCashStatusFallback(String status) {
    return '$status';
  }

  @override
  String get posLoginAppName => 'POS System';

  @override
  String get posLoginTitle => 'Sign in to continue';

  @override
  String get posLoginEmail => 'Email';

  @override
  String get posLoginEmailHint => 'Enter your email';

  @override
  String get posLoginEmailRequired => 'Please enter email';

  @override
  String get posLoginPassword => 'Password';

  @override
  String get posLoginPasswordHint => 'Enter your password';

  @override
  String get posLoginPasswordRequired => 'Please enter password';

  @override
  String get posLoginForgotPassword => 'Forgot Password?';

  @override
  String get posLoginSignIn => 'Sign In';

  @override
  String get posLoginSuccess => 'Login successful';

  @override
  String get posLoginFailed => 'Login failed';

  @override
  String get posLoginResetPasswordTitle => 'Reset Password';

  @override
  String get posLoginResetPasswordSubtitle =>
      'Enter your email or mobile number and we\'ll send you a reset link.';

  @override
  String get posLoginResetPasswordEmailLabel => 'Email';

  @override
  String get posLoginResetPasswordEmailHint => 'Enter your email';

  @override
  String get posLoginResetPasswordSendButton => 'Send Reset Link';

  @override
  String get posLoginResetPasswordSentSuccess =>
      'Reset link sent! Check your inbox.';

  @override
  String get posLoginPreviousShiftAutoClosed =>
      'Previous shift was automatically closed. New shift started.';

  @override
  String get posLoginSessionExpiredError =>
      'Session expired. Please sign in again.';

  @override
  String get posYourJobsTitle => 'Your Jobs';

  @override
  String get posYourJobsNoDepartments => 'No departments selected.';

  @override
  String get posYourJobsDeptInvoiceTitle => 'Department-wise Invoice';

  @override
  String posYourJobsItems(int count) {
    return '$count items';
  }

  @override
  String get posYourJobsGrandTotal => 'Grand Total';

  @override
  String get posYourJobsSaveDraft => 'Save Draft';

  @override
  String get posYourJobsPlaceOrder => 'Place Order';

  @override
  String get posYourJobsAssignTechnicians => 'Assign Technicians';

  @override
  String get posYourJobsAddInventory => 'Add Inventory';

  @override
  String posYourJobsAmountSar(String amount) {
    return 'SAR $amount';
  }

  @override
  String get posInvSalesTitle => 'Inventory Sales';

  @override
  String get posInvSalesRefreshTooltip => 'Refresh';

  @override
  String get posInvSalesPeriodLabel => 'Period';

  @override
  String get posInvSalesPresetToday => 'Today';

  @override
  String get posInvSalesPresetYesterday => 'Yesterday';

  @override
  String get posInvSalesPresetLast7 => 'Last 7 days';

  @override
  String get posInvSalesPresetLast30 => 'Last 30 days';

  @override
  String get posInvSalesPresetThisMonth => 'This month';

  @override
  String get posInvSalesPresetCustom => 'Custom';

  @override
  String get posInvSalesFromLabel => 'From (y-MM-dd)';

  @override
  String get posInvSalesToLabel => 'To (y-MM-dd)';

  @override
  String get posInvSalesLoadButton => 'Load';

  @override
  String get posInvSalesLoadingButton => 'Loading…';

  @override
  String get posInvSalesStatTotalUnits => 'Total units sold';

  @override
  String get posInvSalesStatUniqueProducts => 'Unique products';

  @override
  String get posInvSalesStatDaysActive => 'Days with activity';

  @override
  String get posInvSalesDismissTooltip => 'Dismiss';

  @override
  String get posInvSalesNoSalesTitle => 'No sales in this period';

  @override
  String get posInvSalesNoSalesSubtitle =>
      'API returned successfully with no matching lines (200 + empty list).';

  @override
  String get posInvSalesRetry => 'Retry';

  @override
  String get posInvSalesColProduct => 'PRODUCT';

  @override
  String get posInvSalesColSku => 'SKU / CODE';

  @override
  String get posInvSalesColQty => 'SOLD QTY';

  @override
  String posInvSalesDayLines(int count) {
    return '$count line';
  }

  @override
  String posInvSalesDayLinesPlural(int count) {
    return '$count lines';
  }

  @override
  String posInvSalesDaySummary(String lines, String qty) {
    return '$lines · $qty units';
  }

  @override
  String get posInvSalesSessionExpiredError =>
      'Session expired. Please sign in again.';

  @override
  String get posInvSalesErrStartBeforeEnd =>
      'Start date must be on or before end date.';

  @override
  String posInvSalesErrRangeExceeded(int days) {
    return 'Date range cannot exceed $days days.';
  }

  @override
  String get moreMenuPettyCash => 'Petty Cash';

  @override
  String get moreMenuPromoCode => 'Promo Code';

  @override
  String get moreMenuStoreClosing => 'Store Closing';

  @override
  String get moreMenuSalesReturn => 'Sales Return';

  @override
  String get posOrdersTitle => 'Orders';

  @override
  String get posOrdersSearchHint => 'Search orders...';

  @override
  String get posOrdersTabletSearchHint => 'Search plate, name, ID...';

  @override
  String get posOrdersTabAll => 'All';

  @override
  String get posOrdersTabPending => 'Pending';

  @override
  String get posOrdersTabCompleted => 'Completed';

  @override
  String get posOrdersNoOrdersFound => 'No orders found';

  @override
  String get posOrdersSearchNoMatch => 'No orders match your search.';

  @override
  String get posOrdersNoPendingOrders => 'No pending orders found';

  @override
  String get posOrdersNoCompletedOrders => 'No completed orders found';

  @override
  String get posOrdersNewOrder => 'New Order';

  @override
  String get posOrdersNoOrderSelected => 'No Order Selected';

  @override
  String get posOrdersSelectFromList =>
      'Select an order from the list on the left to view details';

  @override
  String get posOrdersAddDepartment => 'ADD DEPARTMENT';

  @override
  String get posOrdersAddCustomerDetails => 'Add customer details';

  @override
  String get posOrdersSelectPaymentMethod => 'Select payment';

  @override
  String get posOrdersSelectYourPaymentMethod => 'Select your payment method';

  @override
  String get posOrdersCustomerDetailsSaved => 'Customer details saved';

  @override
  String get posOrdersPaymentMethodSaved => 'Payment method saved';

  @override
  String get posOrdersStatusRejected => 'REJECTED';

  @override
  String get posOrdersStatusCancelled => 'CANCELLED';

  @override
  String get posOrdersStatusComplete => 'COMPLETE';

  @override
  String get posOrdersStatusEdited => 'EDITED';

  @override
  String get posOrdersStatusInProgress => 'IN PROGRESS';

  @override
  String get posOrdersStatusPending => 'PENDING';

  @override
  String get posOrdersStatusUnapproved => 'UNAPPROVED';

  @override
  String get posOrdersStatusWaitingApproval => 'WAITING APPROVAL';

  @override
  String get posOrdersStatusCorpApproved => 'CORP APPROVED';

  @override
  String get posOrdersAssignTechnicians => 'Assign Technicians';

  @override
  String get posOrdersCancelBtn => 'Cancel';

  @override
  String get posOrdersMarkComplete => 'Mark Complete';

  @override
  String get posOrdersDeleteJob => 'Delete Job';

  @override
  String get posOrdersEditBtn => 'Edit';

  @override
  String get posOrdersCancelledBtn => 'Cancelled';

  @override
  String get posOrdersProductsServices => 'Products & Services';

  @override
  String get posOrdersSendForApproval => 'Send for Approval';

  @override
  String get posOrdersGenerateInvoice => 'Generate Invoice';

  @override
  String get posOrdersRequestPayment => 'Request Payment';

  @override
  String get posOrdersPaymentReceived => 'Payment received';

  @override
  String get posOrdersPaymentMethodLocked =>
      'Payment method is locked after payment — customer details can still be edited.';

  @override
  String posOrdersPaidAmount(String amount) {
    return 'Paid $amount SAR';
  }

  @override
  String posOrdersPaidVia(String method) {
    return 'via $method';
  }

  @override
  String posOrdersPrepaidAmountMismatch(String paid) {
    return 'Order total changed. It must match the paid amount ($paid SAR) before you can generate the invoice.';
  }

  @override
  String get posOrdersRequestPaymentSuccess =>
      'Payment recorded for this order';

  @override
  String get posSoftPosConnectionNotStable =>
      'SoftPOS is offline. Open the SoftPOS app and keep it online, then try again.';

  @override
  String get posOrdersOrderSummary => 'ORDER SUMMARY';

  @override
  String get posOrdersOrderPromo => 'ORDER PROMO';

  @override
  String get posOrdersGrandTotal => 'Grand total';

  @override
  String get posOrdersNoTechniciansAssigned => 'No technicians assigned';

  @override
  String get posOrdersNoProducts => 'No products or services';

  @override
  String get posOrdersDeptPromo => 'Dept promo';

  @override
  String get posOrdersDeptDiscount => 'Dept discount';

  @override
  String get posOrdersOrderDiscount => 'Order discount';

  @override
  String get posOrdersLineDiscount => 'Line discount';

  @override
  String get posOrdersTotalBeforeVat => 'Total before VAT';

  @override
  String get posOrdersTotalAfterDiscount => 'Total after discount';

  @override
  String get posOrdersNoPlate => 'No Plate';

  @override
  String get posOrdersSplitPayment => 'Split Payment';

  @override
  String get posOrdersPayment => 'Payment';

  @override
  String get posOrdersInvoiceTotal => 'Invoice Total';

  @override
  String get posOrdersConfirmAmounts => 'Confirm amounts';

  @override
  String get posOrdersAmountSar => 'Amount (SAR)';

  @override
  String get posOrdersCancelDialog => 'Cancel';

  @override
  String get posOrdersNoDepartmentsAvailable =>
      'No departments available to add.';

  @override
  String get posOrdersJobIdMissing => 'Job ID missing.';

  @override
  String get posOrdersJobNoLineItems => 'This job has no line items.';

  @override
  String get posOrdersTechnicianRequired =>
      'Technician assignment is required.';

  @override
  String get posOrdersJobNotReadyForInvoice =>
      'Order is not ready for invoicing.';

  @override
  String get posOrdersSelectCustomerAndPayment =>
      'Select customer type and payment method first.';

  @override
  String get posOrdersDeleteJobTitle => 'Delete Job';

  @override
  String get posOrdersNoBtn => 'NO';

  @override
  String get posOrdersYesDeleteBtn => 'YES, DELETE';

  @override
  String get posReviewFinalReview => 'Final Review';

  @override
  String get posReviewInvoiceReady => 'Invoice Ready';

  @override
  String get posReviewBilling => 'Billing';

  @override
  String get posReviewVehicle => 'Vehicle';

  @override
  String get posReviewInvoiceDetails => 'Invoice details';

  @override
  String get posReviewCustomerDetails => 'Customer details';

  @override
  String get posReviewConfirmBillingAndVehicle =>
      'Confirm billing contact and vehicle before creating the invoice.';

  @override
  String get posReviewConfirmBillingOnly =>
      'Confirm billing contact before creating the invoice.';

  @override
  String get posReviewCustomerNameLabel => 'Customer name';

  @override
  String get posReviewMobileLabel => 'Mobile';

  @override
  String get posReviewVatLabel => 'VAT';

  @override
  String get posReviewPlateNumberLabel => 'Plate number';

  @override
  String get posReviewOdometerLabel => 'Odometer';

  @override
  String get posReviewMakeLabel => 'Make';

  @override
  String get posReviewModelLabel => 'Model';

  @override
  String get posReviewYearLabel => 'Year';

  @override
  String get posReviewVinLabel => 'VIN';

  @override
  String get posReviewRequiredError => 'Required';

  @override
  String get posReviewPlateRequiredError => 'Plate is required';

  @override
  String get posReviewInvalidYearError => 'Invalid year';

  @override
  String get posReviewCancelBtn => 'Cancel';

  @override
  String get posReviewContinueBtn => 'Continue';

  @override
  String get posReviewCorporateCustomerQuestion => 'Corporate Customer?';

  @override
  String get posReviewIsCorporateCustomer => 'Is this a corporate customer?';

  @override
  String get posReviewYesCorporate => 'Yes — Corporate';

  @override
  String get posReviewNoIndividual => 'No — Individual';

  @override
  String get posReviewPaymentMethod =>
      'Payment Method (Select multiple if splitting)';

  @override
  String get posReviewPaymentMethodCorporate => 'Payment Method';

  @override
  String get posReviewCompleteAndGenerateInvoice =>
      'Complete Order & Generate Invoice';

  @override
  String get posReviewInvoiceGeneratedLocked => 'Invoice Generated & Locked';

  @override
  String get posReviewNoFurtherEdits => 'No further edits allowed';

  @override
  String get posReviewCommissionsCredited => 'Commissions Credited';

  @override
  String get posReviewPrintInvoice => 'Print Invoice & Receipt';

  @override
  String get posReviewCommissionsNote =>
      'Commissions have been credited to technician accounts.';

  @override
  String posReviewOrderNo(Object id) {
    return 'Order #$id';
  }

  @override
  String get posReviewSplitPayment => 'Split Payment';

  @override
  String get posReviewInvoiceTotal => 'Invoice Total';

  @override
  String get posReviewConfirmAmounts => 'Confirm amounts';

  @override
  String get posReviewAmountSar => 'Amount (SAR)';

  @override
  String get posReviewCancelDialogBtn => 'Cancel';

  @override
  String get posReviewEmployeesPayment => 'Employees (payment)';

  @override
  String get posReviewSelectEmployee => 'Select employee';

  @override
  String get posReviewEmployeeInstructions =>
      'One employee for the Employees payment line. Tap the selected card again to clear.';

  @override
  String get posReviewCouldNotLoadEmployees =>
      'Could not load branch employees.';

  @override
  String get posReviewRetry => 'Retry';

  @override
  String get posReviewNoBranchEmployees => 'No branch employees listed.';

  @override
  String get posReviewGrossAmountExclVat => 'Gross Amount (Excl. VAT)';

  @override
  String get posReviewItemDiscounts => 'Item Discounts';

  @override
  String get posReviewInvoiceDiscount => 'Invoice Discount';

  @override
  String posReviewPromoDiscount(Object code) {
    return 'Promo Discount ($code)';
  }

  @override
  String get posReviewPromoDiscountNoCode => 'Promo Discount';

  @override
  String get posReviewPriceAfterDiscount => 'Price after discount';

  @override
  String get posReviewPriceAfterPromo => 'Price after promo';

  @override
  String get posReviewDiscount => 'Discount';

  @override
  String posReviewTaxPct(Object pct) {
    return 'Tax ($pct%)';
  }

  @override
  String get posReviewTotalAmount => 'Total amount';

  @override
  String get posReviewNoDeptData => 'No departmental data found.';

  @override
  String get posReviewDepartmentCol => 'Department';

  @override
  String get posReviewJobIdCol => 'Job ID';

  @override
  String get posReviewStatusCol => 'Status';

  @override
  String get posReviewProductServiceCol => 'Product / Service';

  @override
  String get posReviewQtyCol => 'Qty';

  @override
  String get posReviewAmountSarCol => 'Amount (SAR)';

  @override
  String get posReviewNoLineItems => 'No line items';

  @override
  String get posReviewGrossExclVat => 'Gross (Excl. VAT)';

  @override
  String get posReviewItemLineDiscounts => 'Item / line discounts';

  @override
  String posReviewVatPct(Object pct) {
    return 'VAT ($pct%)';
  }

  @override
  String get posReviewDepartmentTotal => 'Department total';

  @override
  String get posReviewOrderSummary => 'ORDER SUMMARY';

  @override
  String get posReviewTotalTaxable => 'Total Taxable Amount';

  @override
  String get posReviewVat15 => 'VAT (15%)';

  @override
  String get posReviewLineNetNote =>
      'Line totals are net of item-level discounts.';

  @override
  String get posReviewInvoicePromoNote =>
      'Invoice and promo discounts apply to the taxable subtotal.';

  @override
  String get posReviewConfirmAmountsNote =>
      'Confirm all amounts match the job before generating the invoice.';

  @override
  String get posReviewAssignedTechnicians => 'ASSIGNED TECHNICIANS';

  @override
  String posReviewJobHash(Object id) {
    return 'Job #$id';
  }

  @override
  String get posReviewNoTechAssigned => 'No technician assigned';

  @override
  String posReviewCommissionLabel(Object amount) {
    return 'Commission: $amount';
  }

  @override
  String get posReviewTotal => 'TOTAL';

  @override
  String get posReviewDone => 'Done';

  @override
  String get posReviewCorporateMustBeApproved =>
      'Corporate order must be approved before invoicing.';

  @override
  String get posReviewOrderNotReadyForInvoicing =>
      'Order is not ready for invoicing.';

  @override
  String get posReviewIndicateCorporate =>
      'Please indicate if this is a corporate customer.';

  @override
  String get posReviewSelectPaymentMethod => 'Please select a payment method.';

  @override
  String get posReviewSelectAtLeastOnePayment =>
      'Please select at least one payment method.';

  @override
  String get posReviewSelectOneEmployee =>
      'Select one employee for the Employees payment.';

  @override
  String posReviewSplitAmountsMustEqual(Object current, Object total) {
    return 'Split amounts must equal the total ($total SAR). Currently: $current SAR.';
  }

  @override
  String get posReviewFillRequiredInvoiceDetails =>
      'Please fill in the required invoice details.';

  @override
  String get posReviewInvoiceNotLoaded => 'Invoice could not be loaded.';

  @override
  String get posDetailsTitle => 'Order Details';

  @override
  String get posDetailsCustomerSection => 'Customer';

  @override
  String get posDetailsVehicleSection => 'Vehicle';

  @override
  String get posDetailsVehicleNo => 'Vehicle no.';

  @override
  String get posDetailsCustomer => 'Customer';

  @override
  String get posDetailsMobile => 'Mobile';

  @override
  String get posDetailsVat => 'VAT';

  @override
  String get posDetailsMakeModel => 'Make/Model';

  @override
  String get posDetailsPlate => 'Plate';

  @override
  String get posDetailsOdometer => 'Odometer';

  @override
  String posDetailsOdometerKm(Object reading) {
    return '$reading km';
  }

  @override
  String get posDetailsJobsSection => 'Jobs';

  @override
  String get posDetailsNoJobsFound => 'No jobs found';

  @override
  String posDetailsJobTitle(Object num, Object status) {
    return 'Job $num • $status';
  }

  @override
  String get posDetailsDepartment => 'Department';

  @override
  String get posDetailsTechnician => 'Technician';

  @override
  String get posDetailsSubtotal => 'Subtotal';

  @override
  String get posDetailsVat15 => 'VAT';

  @override
  String get posDetailsTotal => 'Total';

  @override
  String posDetailsItems(Object count) {
    return 'Items ($count)';
  }

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodBankTransfer => 'Bank Transfer';

  @override
  String get paymentMethodMonthlyBilling => 'Monthly billing';

  @override
  String get paymentMethodWallet => 'Wallet';

  @override
  String get paymentMethodTabby => 'Tabby';

  @override
  String get paymentMethodTamara => 'Tamara';

  @override
  String get paymentMethodEmployees => 'Employees';

  @override
  String get suppliersTitle => 'Suppliers & Purchases';

  @override
  String get suppliersTabSuppliers => 'Suppliers';

  @override
  String get suppliersTabPurchaseOrders => 'Purchase Orders';

  @override
  String get suppliersFabAddSupplier => 'Add Supplier';

  @override
  String get suppliersFabNewPurchase => 'New Purchase';

  @override
  String get suppliersStatSuppliers => 'Suppliers';

  @override
  String get suppliersStatOutstanding => 'Outstanding';

  @override
  String get suppliersStatPendingPos => 'Pending POs';

  @override
  String get suppliersNoSuppliersFound => 'No suppliers found';

  @override
  String get suppliersInternalBadge => 'INTERNAL';

  @override
  String get suppliersOutstandingLabel => 'Outstanding';

  @override
  String suppliersAmountSar(String amount) {
    return 'SAR $amount';
  }

  @override
  String suppliersAmountCurrency(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get suppliersUnknown => 'Unknown';

  @override
  String get suppliersStatusPending => 'PENDING';

  @override
  String get suppliersStatusApproved => 'APPROVED';

  @override
  String get suppliersStatusRejected => 'REJECTED';

  @override
  String get suppliersPoStep1Title => 'Select Supplier';

  @override
  String get suppliersPoStep1Subtitle =>
      'Choose from your registered suppliers.';

  @override
  String get suppliersPoStep2Title => 'Add Items';

  @override
  String suppliersPoStep2Subtitle(String name) {
    return 'Supplier: $name';
  }

  @override
  String get suppliersPoStep3Title => 'Confirm Order';

  @override
  String get suppliersPoStep3Subtitle =>
      'Review before submitting for approval.';

  @override
  String get suppliersPoStepSelect => 'Select Supplier';

  @override
  String get suppliersPoStepAddItems => 'Add Items';

  @override
  String get suppliersPoStepConfirm => 'Confirm';

  @override
  String get suppliersPoAddItem => 'Add Item';

  @override
  String get suppliersPoItemProductName => 'Product Name';

  @override
  String get suppliersPoItemProductHint => 'e.g. Engine Oil';

  @override
  String get suppliersPoItemQty => 'Qty';

  @override
  String get suppliersPoItemUnitPrice => 'Unit Price';

  @override
  String get suppliersPoConfirmSupplier => 'Supplier';

  @override
  String suppliersPoConfirmItems(int count) {
    return '$count items';
  }

  @override
  String get suppliersPoConfirmStatus => 'Status';

  @override
  String get suppliersPoConfirmStatusValue => 'Pending Approval';

  @override
  String get suppliersPoConfirmNote =>
      'This PO will be submitted for manager approval before stock is updated.';

  @override
  String get suppliersPoNavNext => 'Next';

  @override
  String get suppliersPoNavSubmit => 'Submit';

  @override
  String get suppliersPoNavBack => 'Back';

  @override
  String get suppliersAddSheetTitle => 'Register New Supplier';

  @override
  String get suppliersAddSheetSubtitle =>
      'Provide details to add a new supplier.';

  @override
  String get suppliersAddFieldName => 'Supplier Name';

  @override
  String get suppliersAddFieldEmail => 'Email Address';

  @override
  String get suppliersAddFieldMobile => 'Mobile Number';

  @override
  String get suppliersAddFieldAddress => 'Address';

  @override
  String get suppliersAddFieldOpeningBalance => 'Opening Balance';

  @override
  String get suppliersAddFieldPassword => 'Password';

  @override
  String get suppliersAddSaveButton => 'Save Supplier';

  @override
  String get suppliersValidationRequired =>
      'Please fill in all required fields';

  @override
  String get suppliersCreateSuccess => 'Supplier Created Successfully';

  @override
  String get suppliersCreateError => 'Failed to create supplier';

  @override
  String get suppliersPoValidationEmpty => 'Please add at least one item';

  @override
  String get suppliersPoValidationItemDetails =>
      'Please fill all item details properly';

  @override
  String get suppliersPoValidationInvalidSupplier =>
      'Invalid supplier selected';

  @override
  String get suppliersPoCreateSuccess => 'Purchase Order Created Successfully';

  @override
  String get suppliersPoCreateError => 'Failed to create purchase order';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsRoleLabel => 'Workshop Owner';

  @override
  String get settingsMultiBranchBadge => 'MULTI-BRANCH ACCESS';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionBusiness => 'Business';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsTogglePushNotif => 'Push Notifications';

  @override
  String get settingsTogglePushNotifSub => 'Receive in-app notifications';

  @override
  String get settingsToggleEmailAlerts => 'Email Alerts';

  @override
  String get settingsToggleEmailAlertsSub => 'Get critical alerts via email';

  @override
  String get settingsToggleStockAlerts => 'Stock Alerts';

  @override
  String get settingsToggleStockAlertsSub => 'Notify when stock is critical';

  @override
  String get settingsToggleLockerAlerts => 'Locker Difference Alerts';

  @override
  String get settingsToggleLockerAlertsSub => 'Notify on EOD locker variance';

  @override
  String get settingsToggleBiometric => 'Biometric Login';

  @override
  String get settingsToggleBiometricSub => 'Use fingerprint or face ID';

  @override
  String get settingsNavChangePassword => 'Change Password';

  @override
  String get settingsNavTwoFactor => 'Two-Factor Authentication';

  @override
  String get settingsNavWorkshopProfile => 'Workshop Profile';

  @override
  String get settingsNavBranchMgmt => 'Branch Management';

  @override
  String get settingsNavCommissionRules => 'Commission Rules';

  @override
  String get settingsNavVatSettings => 'VAT Settings';

  @override
  String get settingsNavHelp => 'Help & Documentation';

  @override
  String get settingsNavContactSupport => 'Contact Support';

  @override
  String get settingsNavReportIssue => 'Report an Issue';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsLogoutDialogTitle => 'Log out';

  @override
  String get settingsLogoutDialogBody =>
      'Are you sure you want to log out from your account?';

  @override
  String get settingsLogoutDialogCancel => 'Cancel';

  @override
  String get settingsLogoutDialogConfirm => 'Log out';

  @override
  String get settingsVersionLabel => 'Filter Workshop OS • Version 1.0.1';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageLabel => 'App Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageArabic => 'Arabic';

  @override
  String get posCommonAll => 'All';

  @override
  String get posCommonProducts => 'Products';

  @override
  String get posCommonServices => 'Services';

  @override
  String get posCommonRetry => 'Retry';

  @override
  String get posCommonSave => 'Save';

  @override
  String get posCommonSar => 'SAR';

  @override
  String get posCommonPending => 'Pending';

  @override
  String get posCommonApproved => 'Approved';

  @override
  String get posCommonRejected => 'Rejected';

  @override
  String get posPettyCashTitle => 'Petty Cash';

  @override
  String get posPettyCashExpenseTab => 'Expense';

  @override
  String get posPettyCashFundTab => 'Fund';

  @override
  String get posPettyCashHistoryTab => 'History';

  @override
  String get posPettyCashSecureWallet => 'SECURE WALLET';

  @override
  String get posPettyCashAvailable => 'Available Petty Cash';

  @override
  String get posPettyCashLowBalanceMessage =>
      'Petty cash balance is low. Please request fund.';

  @override
  String get posPettyCashRequestFund => 'Request Fund';

  @override
  String get posPettyCashExpenseDetails => 'Expense Details';

  @override
  String get posPettyCashAmountSar => 'Amount (SAR)';

  @override
  String get posPettyCashExpenseCategory => 'Expense Category';

  @override
  String get posPettyCashEmployeeSalaryAdvance => 'Employee (Salary advance)';

  @override
  String get posPettyCashDescriptionNotes => 'Description / Notes';

  @override
  String get posPettyCashEnterDetailsHint => 'Enter details...';

  @override
  String get posPettyCashProofOfExpense => 'Proof of Expense';

  @override
  String get posPettyCashExpenseSubmitted =>
      'Expense submitted – pending approval';

  @override
  String get posPettyCashSubmitExpense => 'Submit Expense';

  @override
  String get posPettyCashFundRequest => 'Fund Request';

  @override
  String get posPettyCashRequestedAmountSar => 'Requested Amount (SAR)';

  @override
  String get posPettyCashReasonForRequest => 'Reason for Request';

  @override
  String get posPettyCashReasonHint => 'Explain why you need more funds...';

  @override
  String get posPettyCashFundRequestSubmitted =>
      'Fund request submitted – pending approval';

  @override
  String get posPettyCashSubmitRequest => 'Submit Request';

  @override
  String get posPettyCashSelectCategory => 'Select category';

  @override
  String get posPettyCashSearchCategory => 'Search category…';

  @override
  String get posPettyCashNoCategoryMatches => 'No category matches';

  @override
  String get posPettyCashNoEmployees => 'No employees on file';

  @override
  String get posPettyCashSelectEmployee => 'Select employee';

  @override
  String get posPettyCashSearchEmployee => 'Search employee…';

  @override
  String get posPettyCashNoEmployeeMatches => 'No employee matches';

  @override
  String get posPettyCashSelectDate => 'Select date';

  @override
  String get posPettyCashFrom => 'From:';

  @override
  String get posPettyCashTo => 'To:';

  @override
  String get posPettyCashAllCategories => 'All categories';

  @override
  String get posPettyCashReset => 'Reset';

  @override
  String get posPettyCashHistoryTitle => 'Expense & fund history';

  @override
  String get posPettyCashNoHistory => 'No history for this filter.';

  @override
  String get posPettyCashLoadMore => 'Load more';

  @override
  String posPettyCashEmployeePrefix(Object name) {
    return 'Employee: $name';
  }

  @override
  String posPettyCashRejectionPrefix(Object reason) {
    return 'Rejection: $reason';
  }

  @override
  String get posPettyCashTapUploadReceipt => 'Tap to upload receipt';

  @override
  String get posPettyCashRequestStatus => 'Request Status';

  @override
  String get posPettyCashPendingUpper => 'PENDING';

  @override
  String get posPettyCashRequestedAmount => 'Requested Amount';

  @override
  String get posPettyCashReason => 'Reason';

  @override
  String get posPettyCashRequestDate => 'Request Date';

  @override
  String get posPettyCashPendingReviewMessage =>
      'Your request is currently being reviewed by administration. You will be notified once it is approved.';

  @override
  String get posPettyCashSubmitNewRequest => 'Submit New Request';

  @override
  String get posPettyCashValidAmountError => 'Please enter a valid amount';

  @override
  String get posPettyCashSelectCategoryError => 'Please select a category';

  @override
  String get posPettyCashSelectEmployeeError =>
      'Please select an employee for Salary Advances';

  @override
  String get posPettyCashSubmitExpenseError =>
      'Failed to submit expense. Check balance or try again.';

  @override
  String get posPettyCashReasonError => 'Please enter a reason';

  @override
  String get posPettyCashSubmitRequestError => 'Failed to submit fund request';

  @override
  String get posPettyCashTokenNotFound => 'Token not found';

  @override
  String get posPettyCashLowBalanceError => 'Low balance - request fund first';

  @override
  String get posProductAddTechnician => 'Add Technician';

  @override
  String get posProductAddProducts => 'Add Products';

  @override
  String posProductItemsCount(Object count) {
    return '$count items';
  }

  @override
  String get posProductGrandTotal => 'Grand Total';

  @override
  String get posProductViewInvoice => 'View Invoice';

  @override
  String get posProductOrderItems => 'Order Items';

  @override
  String get posProductNoItemsInvoice => 'No items in invoice';

  @override
  String get posProductGrossAmountExclVat => 'Gross Amount (Excl. VAT)';

  @override
  String get posProductLineDiscount => 'Line discount';

  @override
  String get posProductPriceAfterLineDiscount => 'Price after line discount';

  @override
  String get posProductTotalDiscountApplied => 'Total discount applied';

  @override
  String get posProductPriceAfterTotalDiscount => 'Price after total discount';

  @override
  String get posProductAddPromoCode => 'Add Promo Code';

  @override
  String posProductPromoLabel(Object code) {
    return 'Promo: $code';
  }

  @override
  String get posProductPromoDiscount => 'Promo discount';

  @override
  String get posProductPriceAfterPromo => 'Price after promo';

  @override
  String get posProductVat15 => 'VAT (15%)';

  @override
  String get posProductTotal => 'Total';

  @override
  String get posProductTotalAmount => 'Total amount';

  @override
  String get posProductEmployeesUpper => 'EMPLOYEES';

  @override
  String get posProductSelectEmployeePayment =>
      'Select one employee for Employees payment (shown with type). Saves with your order.';

  @override
  String get posProductSelectEmployeePaymentShort =>
      'Select one employee for Employees payment (with type).';

  @override
  String get posProductNewOrderId => '#NEW-ORDER';

  @override
  String get posProductWalkInCustomer => 'Walk-in Customer';

  @override
  String get posProductNoVehicleDetails => 'No Vehicle Details';

  @override
  String get posProductNoPhone => 'No Phone';

  @override
  String get posProductDraft => 'Draft';

  @override
  String get posProductNoItemsAdded => 'No items added';

  @override
  String get posProductPendingAssignment => 'pending assignment';

  @override
  String get posProductCompleteSuccess =>
      'Order marked as completed successfully';

  @override
  String get posProductCompleteError => 'Failed to complete job';

  @override
  String get posProductMarkComplete => 'Mark as Complete';

  @override
  String get posProductSaveDraft => 'Save Draft';

  @override
  String get posProductForwardTechnician => 'Forward to Technician';

  @override
  String get posProductSearchHint => 'Search products & services...';

  @override
  String get posProductNoSearchMatch => 'No products match your search.';

  @override
  String get posProductDepartmentNotFound => 'Department not found';

  @override
  String get posProductAddDepartment => 'Add Department';

  @override
  String get posProductNoServicesFound => 'No services found';

  @override
  String get posProductNoProductsFound => 'No products found';

  @override
  String get posProductEditServicePriceTitle => 'Price for this order';

  @override
  String get posProductEditServicePriceHint =>
      'VAT-inclusive unit price (SAR), cart only';

  @override
  String get posProductEditServicePriceSave => 'Done';

  @override
  String get posProductEditServicePriceInvalid => 'Enter a valid price';

  @override
  String get posProductEditServicePriceSuccess => 'Price applied to this order';

  @override
  String get posProductEditServicePriceError => 'Could not update price';

  @override
  String get posProductBranchRequiredForPriceEdit =>
      'Select a branch to edit catalog prices';

  @override
  String posProductUnitLabel(Object unit) {
    return 'Unit: $unit';
  }

  @override
  String get posProductDiscountShort => 'Dis.';

  @override
  String get posProductTotalDiscount => 'Total discount';

  @override
  String get posProductCouldNotLoadEmployees => 'Could not load employees.';

  @override
  String get posProductNoBranchEmployees => 'No branch employees.';

  @override
  String get posProductsFailedLoad => 'Failed to load products';

  @override
  String posProductsBranchLabel(Object branch) {
    return 'Branch: $branch';
  }

  @override
  String get posHomeTitleFilter => 'Filter ';

  @override
  String get posHomeTitlePos => 'POS';

  @override
  String get posHomeSubtitle =>
      'Search by customer number, vehicle number,phone number or customer name';

  @override
  String get posHomeSearchHint => 'Search by name, mobile, or vehicle plate...';

  @override
  String get posHomeNewWalkIn => 'New walk-in';

  @override
  String get posHomeCorporateBooking => 'Corporate booking';

  @override
  String posHomeBranchPrefix(String branch) {
    return 'Branch: $branch';
  }

  @override
  String get posHomeRecentSearches => 'Recent Searches';

  @override
  String get posHomeSearchResults => 'Search results';

  @override
  String get posHomeNoVehicle => 'No Vehicle';

  @override
  String get posHomeNoResults => 'No results found';

  @override
  String get posHomeNoResultsHint =>
      'Try searching with a different name or number';

  @override
  String get posHomePromoCodes => 'Promo codes';

  @override
  String posHomePromoPercentOff(String value) {
    return '$value% OFF';
  }

  @override
  String posHomePromoAmountOff(String value) {
    return 'SAR $value OFF';
  }

  @override
  String posHomePromoPercentTitle(String value) {
    return '$value% off your booking';
  }

  @override
  String posHomePromoAmountTitle(String value) {
    return 'SAR $value off your booking';
  }

  @override
  String posHomePromoPercentBody(String value) {
    return 'New customers get $value% off their first service';
  }

  @override
  String posHomePromoAmountBody(String value) {
    return 'New customers get SAR $value off their first service';
  }

  @override
  String get posHomeSeeDetails => 'See details';

  @override
  String get posHomeTechnicianLabel => 'Technician';

  @override
  String get posCatalogSyncData => 'Sync data';

  @override
  String get posCatalogSyncing => 'Syncing catalog…';

  @override
  String get posCatalogSyncSuccess => 'Catalog updated';

  @override
  String get posCatalogSyncFailed => 'Could not sync catalog';

  @override
  String get posCatalogSyncEmptyHint =>
      'No local data yet. Tap Sync data in the menu to download from the server.';

  @override
  String get posDeptSelectTitle => 'Select Depart';

  @override
  String get posDeptAddTitle => 'Add Department';

  @override
  String get posDeptNoneFound => 'No departs found';

  @override
  String get posDeptAlreadyOnOrder =>
      'This department is already on this order.';

  @override
  String posDeptSelectedCount(int count) {
    return '$count departments selected';
  }

  @override
  String get posDeptAddToOrder => 'Add to order';

  @override
  String get posDeptOrderPlaced => 'Order Placed';

  @override
  String get posDeptSelectAtLeastOne =>
      'Select at least one department to add.';

  @override
  String get posDeptVehicleRequired =>
      'Please add vehicle number first (Add Customer)';

  @override
  String get posDeptChangeDeptTitle => 'Change Department?';

  @override
  String get posDeptChangeDeptBody =>
      'Do you really want to change your department?';

  @override
  String get posDeptChangeDeptRefresh => 'Your invoice data will be refreshed.';

  @override
  String get posDeptChangeDeptCancel => 'Cancel';

  @override
  String get posDeptChangeDeptContinue => 'Continue';

  @override
  String get posDeptRetry => 'Retry';

  @override
  String get posCustomerHistoryTitle => 'Customer History';

  @override
  String get posCustomerPastOrders => 'Past Orders';

  @override
  String get posCustomerNoHistory =>
      'No order history found for this customer.';

  @override
  String posCustomerVat(String vat) {
    return 'VAT: $vat';
  }

  @override
  String posCustomerOrderId(String id) {
    return 'Order #$id';
  }

  @override
  String posCustomerInvoice(String no) {
    return 'Invoice: $no';
  }

  @override
  String posCustomerVin(String vin) {
    return 'VIN $vin';
  }

  @override
  String posCustomerMoreItems(int count) {
    return '+$count more items';
  }

  @override
  String posCustomerAmountSar(String amount) {
    return 'SAR $amount';
  }

  @override
  String get posCustomerTypeRegular => 'REGULAR';

  @override
  String get posCustomerTypeCorporate => 'CORPORATE';

  @override
  String posProductStockInStock(int count) {
    return 'In Stock ($count)';
  }

  @override
  String posProductStockLow(int count) {
    return 'Low ($count)';
  }

  @override
  String get posProductStockOut => 'Out of Stock';

  @override
  String get posProductStockInfinite => 'Infinite';

  @override
  String get posProductStockService => 'Service';

  @override
  String get posOrderStatusInvoiced => 'Invoiced';

  @override
  String get posOrderStatusCompleted => 'Completed';

  @override
  String get posOrderStatusPending => 'Pending';

  @override
  String get posOrderStatusWaiting => 'Waiting';

  @override
  String get posOrderStatusDraft => 'Draft';

  @override
  String get posOrderStatusInProgress => 'In Progress';

  @override
  String get posOrderStatusAccepted => 'Accepted';

  @override
  String get posSearchHistoryNoVehicle => 'No Vehicle';

  @override
  String get posSearchHistoryNa => 'N/A';

  @override
  String get posSearchHistoryContinue => 'Continue Order';

  @override
  String get posSearchHistoryHistory => 'History';

  @override
  String get posSearchHistorySalesReturn => 'Sales Return';

  @override
  String get posNavHome => 'Home';

  @override
  String get posNavProducts => 'Products';

  @override
  String get posNavOrders => 'Orders';

  @override
  String get posNavStoreClosing => 'Store Closing';

  @override
  String get posNavClosingHistory => 'Closing History';

  @override
  String get posClosingHistorySubtitle => 'Your past store closings';

  @override
  String get posClosingHistoryEmpty => 'No store closings yet';

  @override
  String get posClosingHistoryRetry => 'Retry';

  @override
  String get posClosingHistoryClosedBadge => 'Closed';

  @override
  String get posClosingHistoryBranchFallback => 'Branch';

  @override
  String get posClosingHistorySystemTotal => 'System';

  @override
  String get posClosingHistoryPhysicalTotal => 'Physical';

  @override
  String get posClosingHistoryDifference => 'Difference';

  @override
  String get posClosingHistoryDetailTitle => 'Closing details';

  @override
  String get posClosingHistoryOpened => 'Opened';

  @override
  String get posClosingHistoryClosed => 'Closed';

  @override
  String get posClosingHistoryBuckets => 'Payment buckets';

  @override
  String get posClosingHistoryTabAll => 'All';

  @override
  String get posClosingHistoryTabBalanced => 'Balanced';

  @override
  String get posClosingHistoryTabShort => 'Short';

  @override
  String get posClosingHistoryCommission => 'Commission';

  @override
  String get posClosingHistoryTotalCommission => 'Total commission';

  @override
  String get posClosingHistoryTotalSales => 'Total sales';

  @override
  String get posClosingHistoryFrom => 'From';

  @override
  String get posClosingHistoryTo => 'To';

  @override
  String get posNavSalaries => 'Salaries';

  @override
  String get posNavCashCollection => 'Cash Collection';

  @override
  String get posCashCollectionPending => 'Pending';

  @override
  String get posCashCollectionCollected => 'Collected';

  @override
  String get posCashCollectionExpected => 'Expected';

  @override
  String get posCashCollectionBalance => 'Balance';

  @override
  String get posCashCollectionEmpty => 'No cash collections in this range';

  @override
  String get posStoreClosingCommissionTitle => 'Shift commission';

  @override
  String posStoreClosingCommissionEarned(
    String amount,
    String percent,
    String sales,
  ) {
    return 'You earned $amount SAR this shift ($percent% of $sales SAR sales)';
  }

  @override
  String get posPromoViewTitle => 'Promo Code';

  @override
  String get posPromoViewEntryTitle => 'Apply Promo Code';

  @override
  String get posPromoViewEntrySubtitle =>
      'Check the validity of a customer provided code.';

  @override
  String get posPromoViewCheckValidity => 'Check Validity';

  @override
  String get posPromoViewAvailableTitle => 'Available Promotions';

  @override
  String get posPromoViewNoPromos => 'No promotions available';

  @override
  String get posPromoViewCheckConditions => 'Check Conditions';

  @override
  String get posPromoViewRemoveTooltip => 'Remove promo';

  @override
  String posPromoResultStore(String value) {
    return 'Store: $value';
  }

  @override
  String posPromoResultProducts(String value) {
    return 'Products: $value';
  }

  @override
  String posPromoResultPeriod(String value) {
    return 'Period: $value';
  }

  @override
  String get posPromoDialogTitle => 'Apply Promo Code';

  @override
  String get posPromoDialogSubtitle =>
      'Select any promo code below to apply discount instantly.';

  @override
  String get posPromoDialogNoCodesAvailable => 'No promo codes available.';

  @override
  String get posPromoDialogOrEnterManually => 'Or enter code manually';

  @override
  String get posPromoDialogHintText => 'e.g. SAVE10';

  @override
  String get posPromoDialogRemovePromo => 'Remove Promo';

  @override
  String get posPromoDialogValidCode => 'Valid Promo Code';

  @override
  String get posPromoDialogLabelDiscount => 'Discount:';

  @override
  String get posPromoDialogLabelStore => 'Store:';

  @override
  String get posPromoDialogLabelProducts => 'Products:';

  @override
  String get posPromoDialogLabelValidity => 'Validity:';

  @override
  String get posPromoDialogCancel => 'Cancel';

  @override
  String get posPromoDialogCheckCode => 'Check Code';

  @override
  String get posPromoDialogApplyDiscount => 'Apply Discount';

  @override
  String posPromoDiscountPercent(String value) {
    return '$value% Discount';
  }

  @override
  String posPromoDiscountSar(String value) {
    return 'SAR $value Discount';
  }

  @override
  String get posPromoAllBranches => 'All Branches';

  @override
  String get posPromoAllProducts => 'All Products';

  @override
  String get posPromoNoExpiry => 'No Expiry';

  @override
  String get posPromoInvalidCode => 'Invalid Promo Code';

  @override
  String get posPromoInvalidExpired => 'Invalid or Expired Promo Code';

  @override
  String get posTechAssignTitle => 'Technician Assignment';

  @override
  String get posTechAssignSearchHint => 'Search technicians...';

  @override
  String get posTechAssignShowAll => 'Show all';

  @override
  String get posTechAssignOnlineOnly => 'Online only';

  @override
  String get posTechAssignLoading => 'Loading technicians…';

  @override
  String get posTechAssignNoResults => 'No technicians found';

  @override
  String posTechAssignErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get posTechAssignRetry => 'Retry';

  @override
  String get posTechAssignStatusOnline => 'Online';

  @override
  String posTechAssignStatusLastSeen(String time) {
    return 'Last seen: $time';
  }

  @override
  String posTechAssignSlots(int used, int total) {
    return 'Slots: $used/$total';
  }

  @override
  String get posTechAssignBroadcast => 'Broadcast';

  @override
  String posTechAssignWait(String label) {
    return 'Wait $label';
  }

  @override
  String get posTechAssignSave => 'Save Technicians';

  @override
  String get posTechAssignSuccessEmpty =>
      'All technicians removed from this job';

  @override
  String get posTechAssignSuccess => 'Technicians assigned successfully';

  @override
  String get posTechAssignFailNoJob => 'Job not found for this assignment.';

  @override
  String get posTechAssignFailGetId => 'Failed to get order ID';

  @override
  String get posTechAssignFailEditId => 'Failed to get job ID for edit';

  @override
  String get posTechAssignFailGeneric => 'Failed to assign technicians';

  @override
  String get posTechAssignUnlockFail =>
      'Could not unlock job to change technicians. Try again.';

  @override
  String get posTechLastSeenNever => 'Never';

  @override
  String get posTechLastSeenJustNow => 'Just now';

  @override
  String posTechLastSeenMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String posTechLastSeenHours(int count) {
    return '${count}h ago';
  }

  @override
  String posTechLastSeenDays(int count) {
    return '${count}d ago';
  }

  @override
  String get posTechViewTitle => 'Technicians';

  @override
  String get posTechViewSearchHint => 'Search technicians...';

  @override
  String get posTechViewTabAll => 'All';

  @override
  String get posTechViewTabOffline => 'Offline';

  @override
  String get posTechViewTabOnline => 'Online';

  @override
  String get posTechViewNoTechnicians => 'No technicians found';

  @override
  String get posTechViewNoOnline => 'No online technicians';

  @override
  String get posTechViewNoOffline => 'No offline technicians';

  @override
  String get posTechViewErrorRetry => 'Retry';

  @override
  String posTechViewErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get posTechCardOnlineNow => 'Online now';

  @override
  String posTechCardLastSeen(String time) {
    return 'Last seen: $time';
  }

  @override
  String get posTechCardNoDepartment => 'No department';

  @override
  String posTechCardSlots(int used, int total) {
    return 'Slots $used/$total';
  }

  @override
  String get posTechPresenceOnline => 'Technician marked online';

  @override
  String get posTechPresenceOffline => 'Technician marked offline';

  @override
  String get storeClosingPhysicalDrawerCount => 'Physical Drawer Count';

  @override
  String get storeClosingEnterAmounts =>
      'Enter the physical amounts you have counted for each payment category.';

  @override
  String get storeClosingLabelPhysicalCash => 'Physical Cash Amount';

  @override
  String get storeClosingLabelBankCard => 'Bank / Card Slips';

  @override
  String get storeClosingLabelCorporate => 'Corporate Invoices';

  @override
  String get storeClosingLabelTamara => 'Tamara Credits';

  @override
  String get storeClosingLabelTabby => 'Tabby Credits';

  @override
  String get storeClosingLabelNotes => 'Notes (Optional)';

  @override
  String get storeClosingTotalPhysical => 'Total Physical Sum';

  @override
  String storeClosingExpectedSar(String sar, String amount) {
    return 'Expected: $sar $amount';
  }

  @override
  String get storeClosingShiftBalanced => 'Shift Balanced';

  @override
  String get storeClosingDiscrepancy => 'Discrepancy Detected';

  @override
  String get storeClosingShiftClosedOk => 'Shift closed successfully.';

  @override
  String get storeClosingPositiveDiff => 'Positive diff = system > physical.';

  @override
  String get storeClosingClosingId => 'Closing ID';

  @override
  String get storeClosingTotalDiff => 'Total Difference';

  @override
  String get storeClosingSystemTotalSales => 'System Total Sales';

  @override
  String get posOrdersTotalInclVat => 'Total (incl. VAT)';

  @override
  String get currencySymbol => 'SAR';

  @override
  String get currencySymbolAr => 'ر.س';

  @override
  String get toastSuccess => 'Success';

  @override
  String get toastError => 'Error';

  @override
  String get toastInfo => 'Info';

  @override
  String get posCommonGoBack => 'Go Back';

  @override
  String get posCommonConfirmCancel => 'Confirm Cancel';

  @override
  String get posCommonCancelledByCashier => 'Cancelled by cashier';

  @override
  String get posThermalPrinterTitle => 'Thermal Printer (Wi-Fi)';

  @override
  String get posThermalPrinterIpLabel => 'Printer IP';

  @override
  String get posThermalPrinterIpHint => 'e.g. 192.168.8.55';

  @override
  String get posThermalPrinterIpEnterPlaceholder => 'Enter your IP';

  @override
  String get posThermalPrinterPortLabel => 'Port';

  @override
  String get posThermalPrinterPortHelper =>
      '9100 for most Epson network receipt printers';

  @override
  String get posThermalPrinterSaved => 'Printer address saved.';

  @override
  String get posCommonCancel => 'Cancel';

  @override
  String get posOrdersCancelOrderTitle => 'Cancel Order';

  @override
  String get posOrdersCancelOrderBody =>
      'Are you sure you want to cancel this order?';

  @override
  String get posTechCardOnCall => 'On call';

  @override
  String get posTechCardNotAvailable => 'Not available';

  @override
  String get posTechCardWorkshopDuty => 'Workshop Duty';

  @override
  String get posTechCardOnCallDuty => 'On Call Duty';

  @override
  String get storeClosingCounterReconciliation => 'Counter Reconciliation';

  @override
  String get storeClosingReconciliationSummary => 'Reconciliation Summary';

  @override
  String get storeClosingShiftClosingStatus => 'Shift Closing Status';

  @override
  String get storeClosingCashier => 'Cashier';

  @override
  String get storeClosingBranch => 'Branch';

  @override
  String get storeClosingMainBranch => 'Main Branch';

  @override
  String get storeClosingOthersEmployee => 'Others / Employee';

  @override
  String get posCommonAddNotesHint => 'Add notes...';

  @override
  String get storeClosingCashAccount => 'Cash Account';

  @override
  String get storeClosingBankCards => 'Bank / Cards';

  @override
  String get storeClosingOthers => 'Others';

  @override
  String get storeClosingCategory => 'Category';

  @override
  String get storeClosingSystem => 'System';

  @override
  String get storeClosingPhysicalCol => 'Physical';

  @override
  String get storeClosingDiff => 'Diff';

  @override
  String get storeClosingBalanced => 'Balanced';

  @override
  String get storeClosingShort => 'Short';

  @override
  String get storeClosingExcess => 'Excess';

  @override
  String get storeClosingSummary => 'Summary';

  @override
  String get storeClosingAmountCol => 'Amount';

  @override
  String get storeClosingTotalSalesReturn => 'Total Sales Return';

  @override
  String get storeClosingBeforeReturns => 'Before Returns';

  @override
  String get storeClosingGrandTotal => 'Grand Total';

  @override
  String get storeClosingCloseShift => 'Close Shift';

  @override
  String get storeClosingGenerateReport => 'Generate Report';

  @override
  String get storeClosingFinalLogout => 'Final Logout';

  @override
  String get storeClosingLogOut => 'Log Out';

  @override
  String get storeClosingLogOutBody =>
      'Are you sure you want to log out and close the shift?';

  @override
  String get storeClosingLogOutCancel => 'Cancel';

  @override
  String get posHomeTabletRequired => 'Tablet Required';

  @override
  String get posHomeLandscapeRequired =>
      'Please rotate your device to landscape mode to use the POS system.';

  @override
  String get posNavOrdersHub => 'Orders Hub';

  @override
  String get posNavBroadcastTechnician => 'Broadcast Technician';

  @override
  String get posNavInventorySales => 'Inventory Sales';

  @override
  String get posNavTakeaway => 'Takeaway';

  @override
  String get posCustomerInvoiceLoadError => 'Could not load invoice';

  @override
  String get posCustomerLoading => 'Loading…';

  @override
  String get posCustomerPrintInvoice => 'Print Invoice';

  @override
  String get posCommonNotAvailable => 'N/A';

  @override
  String get posCommonDash => '—';

  @override
  String get posCurrentShiftDefaultCashier => 'Cashier';

  @override
  String get posCurrentShiftDefaultStatus => 'Active';

  @override
  String get posCurrentShiftCredentialsError =>
      'User credentials or token missing.';

  @override
  String get posDeptAuthError => 'No authentication token found';

  @override
  String get posDeptLoadError => 'Failed to load departments';

  @override
  String get posPaymentsChooseMethod => 'Choose at least one payment method.';

  @override
  String get posPaymentsLineMinimum =>
      'Each payment line must be at least 0.01 SAR.';

  @override
  String posPaymentsSplitMismatch(String payable, String current) {
    return 'Split totals must equal the order payable amount ($payable SAR). Currently: $current SAR.';
  }

  @override
  String get posSessionExpiredSignIn => 'Session expired. Sign in again.';

  @override
  String get posPaymentSelectionSaveError =>
      'Could not save payment selection.';

  @override
  String get posPaymentSelectionClearError => 'Could not clear saved payment.';

  @override
  String get posBillingEditLocked =>
      'Billing cannot be edited after an invoice exists.';

  @override
  String get posBillingCustomerMobileRequired =>
      'Customer name and mobile are required.';

  @override
  String get posBillingSaveError => 'Failed to update billing details';

  @override
  String get posBillingClearEmployeePaymentError =>
      'Could not clear saved payment for employee customer.';

  @override
  String get posCorporateAccountRequired => 'Please select a corporate account';

  @override
  String get posDepartmentSelectAtLeastOne => 'Select at least one department';

  @override
  String get posAuthTokenMissing => 'Authentication token not found';

  @override
  String get posVehiclePlateRequired => 'Vehicle plate is required';

  @override
  String get posOrderCreated => 'Order created';

  @override
  String get posCorporateAccountMissing =>
      'Corporate account is missing for this corporate draft.';

  @override
  String get posCorporateContactRequired =>
      'Contact name is required for corporate quote';

  @override
  String posUnitPriceInvalid(String name) {
    return 'Enter a valid unit price for $name';
  }

  @override
  String get posLineDepartmentRequired => 'Each line needs a department';

  @override
  String get posNoLineItemsToSave => 'No line items to save';

  @override
  String posDepartmentJobMissing(String departmentId) {
    return 'No job for department $departmentId. Use “Add departments” or refresh orders.';
  }

  @override
  String posPricingSaveFailed(String departmentId) {
    return 'Failed to save pricing for department $departmentId';
  }

  @override
  String get posEditContextMissing => 'Edit context missing. Please try again.';

  @override
  String get posNoChangesToSave => 'No changes to save';

  @override
  String get posUnlockJobFailed => 'Could not unlock this job for editing';

  @override
  String get posUnlockJobFailedRetry =>
      'Could not unlock this job for editing. Please try again.';

  @override
  String get posOrderUpdateSuccess => 'Order updated successfully';

  @override
  String get posOrderUpdateFailed => 'Failed to update order';

  @override
  String get posAuthInfoMissing => 'Authentication information missing';

  @override
  String get posProductsFetchFailed => 'Failed to fetch products';

  @override
  String get posServiceOnlyOnce =>
      'Services can only be booked once per order.';

  @override
  String posStockLimitExceeded(String stock) {
    return 'Cannot exceed available stock limit ($stock)';
  }

  @override
  String get posOrdersFetchFailed => 'Failed to fetch orders';

  @override
  String get posDepartmentStarted => 'Department started';

  @override
  String get posDepartmentStartFailed => 'Failed to start department';

  @override
  String get posOrderDetailsMissing => 'Order details not found';

  @override
  String get posCorporateApprovalSent => 'Sent for corporate approval';

  @override
  String get posCorporateApprovalFailed => 'Failed to send for approval';

  @override
  String get posVehicleNumberRequiredForBilling =>
      'vehicleNumber is required when sending vehicle fields. Add the plate under Add Customer.';

  @override
  String get posInvoiceJobNotReady =>
      'Job is not ready to invoice. Add billable lines and technicians first.';

  @override
  String get posFinalizeEditedJobFailed =>
      'Could not finalize edited job before invoice.';

  @override
  String get posInvoiceCustomerRequired =>
      'Customer name and mobile are required before invoice. Complete the billing prompt or update customer';

  @override
  String get posInvoiceVehiclePlateRequired =>
      'Vehicle plate is required before invoice. Add it under Add Customer (billing), then try again.';

  @override
  String get posInvoicePaymentRequired =>
      'Payment method is required before generating invoice.';

  @override
  String get posInvoicePaymentSaveFailed =>
      'Invoice created, but failed to save payment.';

  @override
  String get posInvoiceSaved => 'Invoice saved';

  @override
  String get posJobProductsRequired =>
      'Please add products/services before completing the job.';

  @override
  String get posBroadcastSaveOrderFirst =>
      'Save the order first before broadcasting.';

  @override
  String posBroadcastWait(String wait) {
    return 'Please wait $wait before broadcasting this department again.';
  }

  @override
  String get posBroadcastFailed => 'Broadcast failed';

  @override
  String get posBroadcastSent => 'Broadcast sent to technicians';

  @override
  String get posBroadcastCancelFailed => 'Cancel broadcast failed';

  @override
  String get posBroadcastCancelled => 'Broadcast cancelled';

  @override
  String get posOrderCancelSuccess => 'Order cancelled successfully';

  @override
  String get posCancelReasonRequired => 'Cancellation reason is required';

  @override
  String get posCancelOrderFailed => 'Failed to cancel order';

  @override
  String get posCancelledByCashier => 'Cancelled by cashier';

  @override
  String get posJobCancelled => 'Job cancelled';

  @override
  String get posJobCancelFailed => 'Failed to cancel job';

  @override
  String get posDepartmentsAdded => 'Departments added';

  @override
  String get posDepartmentsAddFailed => 'Failed to add departments';

  @override
  String posDetailsCreated(Object date) {
    return 'Created: $date';
  }

  @override
  String posDetailsOrderNo(Object id) {
    return 'Order #$id';
  }

  @override
  String get posShellTabletRequired => 'Tablet required';

  @override
  String get posShellTabletMessage =>
      'Workshop POS opens only on tablet devices.';

  @override
  String get posShellLandscapeTitle => 'Landscape required';

  @override
  String get posShellLandscapeMessage =>
      'Rotate the tablet to landscape mode to use Workshop POS.';

  @override
  String get posOrdersInvoiceSavedNoReceipt =>
      'Invoice was saved, but receipt details were not returned. The order should appear as invoiced after refresh.';

  @override
  String get posOrdersSelectBranchEmployeeCustomer =>
      'Select the branch employee customer first.';

  @override
  String posOrdersSplitAmountsMustEqualTotal(Object total) {
    return 'Split amounts must equal total ($total SAR).';
  }

  @override
  String get posHomeTitleWorkshop => 'Workshop ';

  @override
  String get posInvSalesStatDistinctItems => 'Distinct items';

  @override
  String get posInvSalesStatUniqueServices => 'Unique services';

  @override
  String get posInvSalesStartDate => 'START DATE';

  @override
  String get posInvSalesEndDate => 'END DATE';

  @override
  String get posInvSalesStartTime => 'START TIME';

  @override
  String get posInvSalesEndTime => 'END TIME';

  @override
  String get posInvSalesClear => 'Clear';

  @override
  String get posInvSalesApply => 'Apply';

  @override
  String get posInvSalesNoSalesSubtitleFriendly =>
      'Try selecting a different date range to see activity.';

  @override
  String get posInvSalesByItemPeriod => 'SALES BY ITEM (PERIOD)';

  @override
  String posInvSalesItemsCount(int count) {
    return '$count ITEMS';
  }

  @override
  String get posInvSalesColItemName => 'ITEM NAME';

  @override
  String get posInvSalesColDepartment => 'DEPARTMENT';

  @override
  String get posInvSalesColType => 'TYPE';

  @override
  String get posInvSalesColSkuShort => 'SKU';

  @override
  String get posInvSalesColQtyShort => 'QTY';

  @override
  String get posInvSalesErrStartTimeBeforeEndSameRange =>
      'Start time must be on or before end time (same calendar range).';

  @override
  String get posInvSalesErrEndTimeAfterStartSameRange =>
      'End time must be on or after start time (same calendar range).';

  @override
  String get posInvSalesErrStartTimeBeforeEndRange =>
      'Start time must be on or before end time for this date range.';

  @override
  String get moreMenuBarrierLabel => 'More Menu';

  @override
  String get posSalesReturnTitle => 'Sales Return';

  @override
  String posSalesReturnMobileTitle(String invoiceNo) {
    return 'Return - $invoiceNo';
  }

  @override
  String get posSalesReturnResults => 'Results';

  @override
  String get posSalesReturnSearchHint => 'e.g. INV-123 or Name/Phone';

  @override
  String posSalesReturnNoInvoicesFound(String query) {
    return 'No invoices found for \"$query\"';
  }

  @override
  String get posSalesReturnSelectInvoiceTitle => 'Select an Invoice';

  @override
  String get posSalesReturnSelectInvoiceBody =>
      'Search and select an invoice from the left\nto initiate its sales return process.';

  @override
  String get posSalesReturnWalkInCustomer => 'Walk-in Customer';

  @override
  String get posSalesReturnTotal => 'Total';

  @override
  String get posSalesReturnSelectItems => 'Select Items to Return';

  @override
  String posSalesReturnSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get posSalesReturnProof => 'Return Proof';

  @override
  String get posSalesReturnOptional => 'Optional';

  @override
  String get posSalesReturnCancel => 'Cancel';

  @override
  String get posSalesReturnSubmit => 'Submit Return';

  @override
  String get posSalesReturnQty => 'Return Qty';

  @override
  String get posSalesReturnReasonHint => 'Select Return Reason';

  @override
  String get posSalesReturnUploadProof => 'Tap to upload proof image';

  @override
  String get posSalesReturnUploadFormats => 'JPG, PNG up to 5MB';

  @override
  String posSalesReturnLinePrice(String qty, String price) {
    return '${qty}x @ SAR $price';
  }

  @override
  String posSalesReturnSarAmount(String amount) {
    return 'SAR $amount';
  }

  @override
  String get posSalesReturnReasonDefective => 'Defective Product/Service';

  @override
  String get posSalesReturnReasonCancellation => 'Customer Cancellation';

  @override
  String get posSalesReturnReasonWrongItem => 'Wrong Item / Service';

  @override
  String get posSalesReturnReasonOther => 'Other';

  @override
  String get posSalesReturnErrorFetchInvoices =>
      'Error fetching invoices. Ensure customer ID is correct.';

  @override
  String get posSalesReturnErrorSelectItem =>
      'Please select at least one item to return';

  @override
  String get posSalesReturnErrorQty =>
      'Enter return quantity (at least 1) for each selected item before submitting.';

  @override
  String get posSalesReturnItemFullyReturned =>
      'Already returned — no quantity left for this item.';

  @override
  String get posSalesReturnItemPendingApproval =>
      'Return pending workshop approval — check Returns List.';

  @override
  String posSalesReturnQtyAvailable(num qty) {
    return '$qty available to return';
  }

  @override
  String get posSalesReturnSuccessSubmitted =>
      'Sales return submitted for workshop approval. Check Returns List for status.';

  @override
  String get posSalesReturnStatusPending => 'Waiting for approval';

  @override
  String get posSalesReturnStatusCompleted => 'Approved';

  @override
  String get posSalesReturnStatusRejected => 'Rejected';

  @override
  String get posSalesReturnStatusLabel => 'Status';

  @override
  String get posSalesReturnRejectionReasonLabel => 'Rejection reason';

  @override
  String get posSalesReturnCreditNoteLabel => 'Credit note';

  @override
  String posSalesReturnErrorSubmit(String error) {
    return 'Failed to submit request: $error';
  }

  @override
  String get posSalesReturnErrorNoValidLines => 'No valid return lines';

  @override
  String get posSalesReturnTokenNotFound => 'Token not found';

  @override
  String get posSalesReturnAuthTokenNotFound =>
      'Authentication token not found';

  @override
  String get posSalesReturnListTitle => 'Returns List';

  @override
  String get posSalesReturnListFailedLoad => 'Failed to load returns';

  @override
  String get posSalesReturnListNoReturns => 'No sales returns found';

  @override
  String posSalesReturnListInvoiceLabel(String invoiceNo) {
    return 'Invoice: $invoiceNo';
  }

  @override
  String get posSalesReturnRefundAmount => 'Refund Amount';

  @override
  String get posSalesReturnDetailsTitle => 'Return Details';

  @override
  String get posSalesReturnDetailsSubtitle => 'Full transaction summary';

  @override
  String get posSalesReturnItemsReturned => 'Items Returned';

  @override
  String get posSalesReturnCloseDetails => 'Close Details';

  @override
  String get posSalesReturnNoLabel => 'Return No';

  @override
  String get posSalesReturnInvoiceNoLabel => 'Invoice No';

  @override
  String get posSalesReturnOrderIdLabel => 'Order ID';

  @override
  String get posSalesReturnCustomerLabel => 'Customer';

  @override
  String get posSalesReturnTotalRefund => 'Total Refund';

  @override
  String get posSalesReturnReasonLabel => 'Return Reason';

  @override
  String posSalesReturnItemId(String itemId) {
    return 'Item ID: $itemId';
  }

  @override
  String posSalesReturnItemQty(String qty) {
    return 'Qty: $qty';
  }

  @override
  String get posSalesReturnListVmFailedFetch => 'Failed to fetch returns';

  @override
  String get posStoreClosingTitle => 'Store Closing';

  @override
  String get posStoreClosingCounterReconciliation => 'Counter Reconciliation';

  @override
  String get posStoreClosingSummaryTitle => 'RECONCILIATION SUMMARY';

  @override
  String get posStoreClosingShiftStatus => 'Shift Closing Status';

  @override
  String get posStoreClosingCashier => 'Cashier';

  @override
  String get posStoreClosingBranch => 'Branch';

  @override
  String get posStoreClosingMainBranch => 'Main Branch';

  @override
  String get posStoreClosingSessionStart => 'Session Start';

  @override
  String get posStoreClosingSessionEnd => 'Session End';

  @override
  String get posStoreClosingDepartmentSales => 'Department Sales';

  @override
  String get posStoreClosingDepartmentCol => 'DEPARTMENT';

  @override
  String get posStoreClosingOrdersCol => 'ORDERS';

  @override
  String get posStoreClosingRevenueCol => 'REVENUE (SAR)';

  @override
  String get posStoreClosingDepartmentSearch =>
      'Search department, orders, revenue…';

  @override
  String get posStoreClosingDepartmentEmpty =>
      'No department sales for this shift yet.';

  @override
  String get posStoreClosingDepartmentNoMatch => 'No rows match your search.';

  @override
  String get posStoreClosingPhysicalDrawerCount => 'Physical Drawer Count';

  @override
  String get posStoreClosingPhysicalDrawerHint =>
      'Enter the physical amounts you have counted for each payment category.';

  @override
  String get posStoreClosingPhysicalCashAmount => 'Physical Cash Amount';

  @override
  String get posStoreClosingBankCardSlips => 'Bank / Card Slips';

  @override
  String get posStoreClosingCorporateInvoices => 'Corporate Invoices';

  @override
  String get posStoreClosingTamaraCredits => 'Tamara Credits';

  @override
  String get posStoreClosingTabbyCredits => 'Tabby Credits';

  @override
  String get posStoreClosingOthersEmployeeSales => 'Others (Employee sales)';

  @override
  String get posStoreClosingNotesOptional => 'Notes (Optional)';

  @override
  String get posStoreClosingTotalPhysicalSum => 'Total Physical Sum';

  @override
  String posStoreClosingExpectedAmount(String amount) {
    return 'Expected: SAR $amount';
  }

  @override
  String get posStoreClosingAddNotesHint => 'Add notes here...';

  @override
  String get posStoreClosingShiftBalanced => 'Shift Balanced';

  @override
  String get posStoreClosingDiscrepancyDetected => 'Discrepancy Detected';

  @override
  String get posStoreClosingShiftClosedSuccessfully =>
      'Shift closed successfully.';

  @override
  String get posStoreClosingGrossNetExplanation =>
      'System column is gross POS settled amounts. Diff compares each bucket’s expected net (after sales returns) to physical, not (gross − physical). Positive diff = system higher than physical.';

  @override
  String get posStoreClosingPositiveDiff =>
      'Positive diff = system > physical.';

  @override
  String get posStoreClosingClosingId => 'Closing ID';

  @override
  String get posStoreClosingCashAccount => 'Cash Account';

  @override
  String get posStoreClosingBankCards => 'Bank / Cards';

  @override
  String get posStoreClosingCorporate => 'Corporate';

  @override
  String get posStoreClosingTamara => 'Tamara';

  @override
  String get posStoreClosingTabby => 'Tabby';

  @override
  String get posStoreClosingOthers => 'Others';

  @override
  String get posStoreClosingCategory => 'Category';

  @override
  String get posStoreClosingSystem => 'System';

  @override
  String get posStoreClosingGross => '(gross)';

  @override
  String get posStoreClosingPhysical => 'Physical';

  @override
  String get posStoreClosingDiff => 'Diff';

  @override
  String get posStoreClosingNet => '(net)';

  @override
  String get posStoreClosingLessSalesReturn => 'Less: Total sales return';

  @override
  String get posStoreClosingGrandTotal => 'Grand Total';

  @override
  String get posStoreClosingCloseShift => 'Close Shift';

  @override
  String get posStoreClosingPrinterHint =>
      'Tap: Wi‑Fi thermal print. Long‑press: printer IP / port.';

  @override
  String get posStoreClosingSaveSuccess => 'save successfully';

  @override
  String get posStoreClosingReceiptSent => 'Receipt sent to Wi‑Fi printer.';

  @override
  String get posStoreClosingPrint => 'Print';

  @override
  String get posStoreClosingViewPdf => 'PDF';

  @override
  String get posStoreClosingPdfPreviewError => 'Could not load closing report.';

  @override
  String get posStoreClosingFinalLogout => 'Final Logout';

  @override
  String get posStoreClosingLogout => 'Log out';

  @override
  String get posStoreClosingLogoutConfirm =>
      'Are you sure you want to log out from your account?';

  @override
  String get posStoreClosingCancel => 'Cancel';

  @override
  String get posStoreClosingVmSuccess => 'Shift closed successfully!';

  @override
  String posStoreClosingVmFailed(String error) {
    return 'Failed to close shift: $error';
  }

  @override
  String get posStoreClosingVmCounterFailed => 'Counter closing failed';

  @override
  String get posStoreClosingPdfTitle => 'Store Closing Report';

  @override
  String get posStoreClosingPdfCategory => 'Category';

  @override
  String get posStoreClosingPdfSystem => 'System';

  @override
  String get posStoreClosingPdfPhysical => 'Physical';

  @override
  String get posStoreClosingPdfDifference => 'Difference';

  @override
  String get posTechnicianTitle => 'Technicians';

  @override
  String get posTechnicianAssignmentTitle => 'Technician Assignment';

  @override
  String get posTechnicianSearchHint => 'Search technicians...';

  @override
  String posTechnicianErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get posTechnicianOnlineOnly => 'Online Only';

  @override
  String get posTechnicianShowAll => 'Show All';

  @override
  String get posTechnicianLoading => 'Loading technicians…';

  @override
  String posTechnicianLastSeen(String time) {
    return 'Last seen: $time';
  }

  @override
  String posTechnicianSlots(int used, int total) {
    return 'Slots: $used/$total';
  }

  @override
  String posTechnicianWait(String duration) {
    return 'Wait $duration';
  }

  @override
  String get posTechnicianBroadcast => 'Broadcast';

  @override
  String get posTechnicianSave => 'Save Technicians';

  @override
  String get posTechnicianAssignSuccess => 'Technicians assigned successfully';

  @override
  String get posTechnicianRemoveSuccess =>
      'All technicians removed from this job';

  @override
  String get posTechnicianAssignFailed => 'Failed to assign technicians';

  @override
  String get posTechnicianFailedJobEdit => 'Failed to get job ID for edit';

  @override
  String get posTechnicianFailedOrderId => 'Failed to get order ID';

  @override
  String get posTechnicianJobNotFound => 'Job not found for this assignment.';

  @override
  String get posTechnicianUnlockFailed =>
      'Could not unlock job to change technicians. Try again.';

  @override
  String get posTechnicianGeneral => 'General';

  @override
  String get posTechnicianTokenNotFound => 'Token not found';

  @override
  String get posTechnicianFetchFailed => 'Failed to fetch technicians';

  @override
  String get posTechnicianOldAssignWarning =>
      'Technician was not assigned. The server may still count old assignments on this job.';

  @override
  String get posTechnicianAddOnlyWarning =>
      'Cannot apply removals: server treats assign as add-only. Backend must sync employeeIds to the full desired list (or honor sync: true).';

  @override
  String get posTechnicianNoneAssignedWarning =>
      'No technicians were assigned. The server may still count cancelled assignments on this job.';

  @override
  String get posTechnicianOnlineFirst =>
      'Mark this technician online before changing workshop or on-call duty.';

  @override
  String get posTechnicianNotSignedIn => 'Not signed in';

  @override
  String get posTechnicianDutyFailed => 'Failed to update duty';

  @override
  String get posTechnicianDutyUpdated => 'Duty updated';

  @override
  String get posTechnicianStatusFailed => 'Failed to update status';

  @override
  String get posTechnicianMarkedOnline => 'Technician marked online';

  @override
  String get posTechnicianMarkedOffline => 'Technician marked offline';

  @override
  String get posTakeawayTitle => 'Takeaway';

  @override
  String get posTakeawayRetry => 'Retry';

  @override
  String get posTakeawaySearchHint => 'Search products & services...';

  @override
  String get posTakeawayRefresh => 'Refresh';

  @override
  String get posTakeawayAll => 'All';

  @override
  String get posTakeawayOrderItems => 'Order Items';

  @override
  String get posTakeawayNoItems => 'No items in invoice';

  @override
  String get posTakeawayGrossExVat => 'Gross Amount (Excl. VAT)';

  @override
  String get posTakeawayLineDiscount => 'Line discount';

  @override
  String get posTakeawayPriceAfterLineDiscount => 'Price after line discount';

  @override
  String get posTakeawayTotalDiscount => 'Total discount';

  @override
  String get posTakeawayAmount => 'amount';

  @override
  String get posTakeawayPercent => 'percent';

  @override
  String get posTakeawayTotalDiscountApplied => 'Total discount applied';

  @override
  String get posTakeawayPriceAfterTotalDiscount => 'Price after total discount';

  @override
  String get posTakeawayAddPromoCode => 'Add Promo Code';

  @override
  String posTakeawayPromoApplied(String code) {
    return 'Promo: $code';
  }

  @override
  String get posTakeawayPromoDiscount => 'Promo discount';

  @override
  String get posTakeawayPriceAfterPromo => 'Price after promo';

  @override
  String get posTakeawayVat15 => 'VAT (15%)';

  @override
  String get posTakeawayTotal => 'Total';

  @override
  String get posTakeawayAddCustomerDetails => 'Add customer details';

  @override
  String get posTakeawayCustomerAndPayment => 'Customer details';

  @override
  String get posTakeawayCheckoutDetailsTitle => 'Customer details';

  @override
  String get posTakeawayCheckoutSaved => 'Customer and payment saved';

  @override
  String get posTakeawayBranchEmployeeBilling => 'Branch employee billing';

  @override
  String get posTakeawayNoBranchEmployees => 'No staff found for this branch.';

  @override
  String get posTakeawaySelectEmployee => 'Select employee';

  @override
  String get posTakeawaySelectEmployeeRequired => 'Select an employee';

  @override
  String get posTakeawayCustomerName => 'Customer name';

  @override
  String get posTakeawayCustomerMobile => 'Mobile';

  @override
  String get posTakeawayCustomerVat => 'VAT (optional)';

  @override
  String get posTakeawaySelectPayment => 'Select payment';

  @override
  String get posTakeawayGenerateInvoice => 'Generate Invoice';

  @override
  String get posTakeawayNoProductsFound => 'No products found';

  @override
  String get posTakeawayNoProductsMatch => 'No products match your search.';

  @override
  String posTakeawayUnit(String unit) {
    return 'Unit: $unit';
  }

  @override
  String posTakeawayItemsCount(int count) {
    return '$count items';
  }

  @override
  String get posTakeawayGrandTotal => 'Grand Total';

  @override
  String get posTakeawayCustomerSaved => 'Customer details saved';

  @override
  String get posTakeawayPaymentSaved => 'Payment method saved';

  @override
  String get posTakeawayCustomerRequired =>
      'Customer name and mobile number are required.';

  @override
  String get posTakeawaySelectPaymentFirst => 'Select payment method first.';

  @override
  String get posTakeawayValidPaymentAmounts =>
      'Add valid payment amounts to continue.';

  @override
  String get posTakeawayInvoiceFailed => 'Failed to generate invoice';

  @override
  String get posTakeawayInactive => 'Inactive';

  @override
  String posTakeawayInStock(String qty) {
    return 'In Stock ($qty)';
  }

  @override
  String posTakeawayLowStock(String qty) {
    return 'Low ($qty)';
  }

  @override
  String get posTakeawayOutOfStock => 'Out of Stock';

  @override
  String get posTakeawayDis => 'Dis.';

  @override
  String get posTakeawayNotLoggedIn => 'Not logged in';

  @override
  String get posTakeawayCartEmpty => 'Cart is empty.';

  @override
  String get posTakeawayWalkInCustomer => 'Walk-in Customer';

  @override
  String get posTakeawayNoInvoiceResponse => 'No invoice in response';

  @override
  String get posTakeawayCheckoutFailed => 'Checkout failed';

  @override
  String posCommonSarAmount(String amount) {
    return 'SAR $amount';
  }

  @override
  String posCommonQtyX(String qty) {
    return 'x$qty';
  }

  @override
  String get posPromoTitle => 'Promo Code';

  @override
  String get posPromoAvailablePromotions => 'Available Promotions';

  @override
  String get posPromoNoPromotionsAvailable => 'No promotions available';

  @override
  String get posPromoApplyPromoCode => 'Apply Promo Code';

  @override
  String get posPromoSelectPromoBelow => 'Select a promo below';

  @override
  String get posPromoNoPromoCodesAvailable => 'No promo codes available';

  @override
  String get posPromoEnterCodeManually => 'Enter code manually';

  @override
  String get posPromoExampleSave10 => 'Enter promo code';

  @override
  String get posPromoRemoveItemConfirmTitle => 'Remove item?';

  @override
  String posPromoRemoveItemConfirmBody(String itemName, String promoCode) {
    return 'Removing \"$itemName\" will remove promo \"$promoCode\" because promo conditions will no longer be met.';
  }

  @override
  String get posPromoRemoveItemConfirmAction => 'Remove item & promo';

  @override
  String get posPromoRemovePromo => 'Remove Promo';

  @override
  String get posPromoRemovePromoLower => 'remove promo';

  @override
  String get posPromoValidPromoCode => 'Valid promo code';

  @override
  String get posPromoDiscountLabel => 'Discount';

  @override
  String get posPromoStoreLabel => 'Store';

  @override
  String get posPromoProductsLabel => 'Products';

  @override
  String get posPromoValidityLabel => 'Validity';

  @override
  String get posPromoCheckCode => 'Check Code';

  @override
  String get posPromoApplyDiscount => 'Apply Discount';

  @override
  String get posPromoCheckDescription =>
      'Check the promo code details and conditions.';

  @override
  String get posPromoCheckValidity => 'Check validity';

  @override
  String get posPromoCheckConditions => 'Check conditions';

  @override
  String get posProductInvalidQuantity => 'Invalid quantity';

  @override
  String get posProductQuantity => 'Quantity';

  @override
  String get posProductInventory => 'Inventory';

  @override
  String get posProductItems => 'Items';

  @override
  String get posProductNoItemsInInvoice => 'No items in invoice';

  @override
  String get posProductGrossExclVat => 'Gross excl. VAT';

  @override
  String get posProductPromoPrefix => 'Promo:';

  @override
  String get posProductSave => 'Save';

  @override
  String get posProductOrderCompletedSuccess => 'Order completed successfully';

  @override
  String get posProductFailedCompleteJob => 'Failed to complete job';

  @override
  String get posProductNoProductsMatch => 'No products match your search';

  @override
  String get posProductProductsTitle => 'Products';

  @override
  String get posProductServicesTitle => 'Services';

  @override
  String get posProductUnitPrefix => 'Unit';

  @override
  String get posProductDiscountAbbrev => 'Disc.';

  @override
  String get posPettyCashTabExpense => 'Expense';

  @override
  String get posPettyCashTabFund => 'Fund';

  @override
  String get posPettyCashTabHistory => 'History';

  @override
  String get posPettyCashTabNoCash => 'Non Cash';

  @override
  String get posPettyCashNoCashDetails => 'Non cash expense';

  @override
  String get posPettyCashDate => 'Date';

  @override
  String get posPettyCashBillNo => 'Bill no';

  @override
  String get posPettyCashBillNoHint => 'Enter bill number';

  @override
  String get posPettyCashSupplier => 'Supplier';

  @override
  String get posPettyCashSelectSupplier => 'Select or enter supplier';

  @override
  String get posPettyCashSearchSupplier => 'Search supplier';

  @override
  String get posPettyCashNoSupplierMatches => 'No supplier matches';

  @override
  String get posPettyCashLoadingSuppliers => 'Loading suppliers…';

  @override
  String get posPettyCashOtherSupplier => 'Other supplier name';

  @override
  String get posPettyCashOtherSupplierHint => 'If supplier is not in the list';

  @override
  String get posPettyCashDepartmentName => 'Department name';

  @override
  String get posPettyCashDepartmentHint => 'Enter department';

  @override
  String get posPettyCashSelectDepartment => 'Select department';

  @override
  String get posPettyCashSearchDepartment => 'Search department';

  @override
  String get posPettyCashNoDepartmentMatches => 'No department matches';

  @override
  String get posPettyCashLoadingDepartments => 'Loading departments…';

  @override
  String get posPettyCashExpenseList => 'Expense list';

  @override
  String get posPettyCashSelectExpenseType => 'Select expense';

  @override
  String get posPettyCashSearchExpenseType => 'Search expense';

  @override
  String get posPettyCashNoExpenseTypeMatches => 'No expense matches';

  @override
  String get posPettyCashRemarks => 'Remarks';

  @override
  String get posPettyCashRemarksHint => 'Enter remarks';

  @override
  String get posPettyCashPhotos => 'Photos';

  @override
  String get posPettyCashAddPhotos => 'Add photos from camera or gallery';

  @override
  String get posPettyCashSubmitNoCash => 'Submit non cash expense';

  @override
  String get posPettyCashNoCashSubmittedPending =>
      'Request submitted successfully';

  @override
  String get posPettyCashAvailablePettyCash => 'Available Petty Cash';

  @override
  String get posPettyCashLowBalanceWarning => 'Low balance warning';

  @override
  String get posPettyCashExpenseSubmittedPending =>
      'Expense submitted for approval.';

  @override
  String get posPettyCashFundRequestSubmittedPending =>
      'Fund request submitted for approval.';

  @override
  String get posCommonSelectDate => 'Select date';

  @override
  String get posCommonFrom => 'From';

  @override
  String get posCommonTo => 'To';

  @override
  String get posCommonReset => 'Reset';

  @override
  String get posPettyCashExpenseFundHistory => 'Expense & Fund History';

  @override
  String get posPettyCashNoHistoryForFilter =>
      'No history found for this filter';

  @override
  String get posPettyCashPendingExplanation =>
      'This request is pending approval.';

  @override
  String get posProductsBranchPrefix => 'Branch:';

  @override
  String get posProductsFailedLoadProducts => 'Failed to load products';

  @override
  String get posNavInventory => 'Inventory';

  @override
  String get posNavSalesReturn => 'Sales Return';

  @override
  String get posNavReturnsList => 'Returns List';

  @override
  String get posNavPettyCash => 'Petty Cash';

  @override
  String get posNavPromoCodes => 'Promo Codes';

  @override
  String get posNavTechnicians => 'Technicians';

  @override
  String get posNavCurrentShift => 'Current Shift';

  @override
  String get posShellVersion => 'Version 1.0.1';

  @override
  String get posOrdersHubTitle => 'Orders Hub';

  @override
  String get posOrdersRefreshOrders => 'Refresh orders';

  @override
  String get posOrdersSearchPlateNameId => 'Search plate, name, ID...';

  @override
  String get posOrdersProductsAndServices => 'Products & Services';

  @override
  String get posOrdersEdit => 'Edit';

  @override
  String get posOrdersCancelled => 'Cancelled';

  @override
  String get posOrdersNoProductsOrServices => 'No products or services';

  @override
  String get posOrdersMaintenanceChecklistTitle => 'Maintenance checklist';

  @override
  String get posOrdersMaintenanceChecklistDescription =>
      'These items appear on the printed invoice when checked.';

  @override
  String get posOrdersChecklistSaved => 'Maintenance checklist saved.';

  @override
  String get posOrdersPleaseSignInAgain => 'Please sign in again.';

  @override
  String get posSessionClosedLoggedOut =>
      'Your shift session was already closed, so you have been logged out.';

  @override
  String posOrdersQtyWithoutVat(String qty, String price) {
    return 'Qty $qty × $price Without VAT';
  }

  @override
  String get posOrdersChecklistOptional => 'Checklist (optional)';

  @override
  String get posOrdersChecklistSelectAll => 'Select all';

  @override
  String get posOrdersChecklistClearAll => 'Clear all';

  @override
  String get posOrdersEditCustomerDetails => 'Edit customer details';

  @override
  String get posOrdersCustomerAndPayment => 'Customer & payment';

  @override
  String get posOrdersCheckoutDetailsTitle => 'Customer & payment';

  @override
  String get posOrdersCheckoutSaved => 'Customer and payment saved';

  @override
  String get posOrdersTotalDiscount => 'Total discount';

  @override
  String get posOrdersNoFurtherEditsAllowed => 'No further edits allowed';

  @override
  String get posOrdersPrintInvoiceReceipt => 'Print Invoice & Receipt';

  @override
  String get posOrdersNoTechnicianCommissions => 'No technician commissions.';

  @override
  String get posOrdersTechnicianCommission => 'TECHNICIAN COMMISSION';

  @override
  String get posOrdersAssignedTechnicians => 'ASSIGNED TECHNICIANS';

  @override
  String get posOrdersNoTechnicianAssigned => 'No technician assigned';

  @override
  String get posInvoiceDetailsTitle => 'Invoice details';

  @override
  String get posInvoiceDetailsCustomerDetails => 'Customer details';

  @override
  String get posInvoiceDetailsConfirmVehicle =>
      'Confirm billing contact and vehicle before creating the invoice.';

  @override
  String get posInvoiceDetailsConfirmContact =>
      'Confirm billing contact before creating the invoice.';

  @override
  String get posInvoiceDetailsBranchEmployee => 'Customer is a branch employee';

  @override
  String get posInvoiceDetailsPickStaff =>
      'Pick from staff list to fill name and mobile.';

  @override
  String get posInvoiceDetailsLoadingEmployees => 'Loading employees…';

  @override
  String get posInvoiceDetailsNoEmployees =>
      'No employees listed for this branch.';

  @override
  String get posInvoiceDetailsEmployee => 'Employee';

  @override
  String get posInvoiceDetailsChooseEmployee => 'Choose employee';

  @override
  String get posInvoiceDetailsCustomerName => 'Customer name';

  @override
  String get posInvoiceDetailsRequired => 'Required';

  @override
  String get posInvoiceDetailsMobile => 'Mobile';

  @override
  String get posInvoiceDetailsVat => 'VAT';

  @override
  String get posInvoiceDetailsPlateNumber => 'Plate number';

  @override
  String get posInvoiceDetailsPlateRequired => 'Plate is required';

  @override
  String get posInvoiceDetailsPlateSaudiLength =>
      'Saudi plate: exactly 3 letters and 1 to 4 digits';

  @override
  String get posInvoiceDetailsPlateSaudiDigits =>
      'Saudi plate needs 1 to 4 digits (after the 3 letters)';

  @override
  String get posInvoiceDetailsPlateSaudiThreeLetters =>
      'Saudi plate needs exactly 3 letters';

  @override
  String get posInvoiceDetailsPlateSaudiLetterChars =>
      'Saudi plate letters must be valid (Latin or Arabic)';

  @override
  String get posInvoiceDetailsOdometer => 'Odometer';

  @override
  String get posInvoiceDetailsMake => 'Make';

  @override
  String get posInvoiceDetailsModel => 'Model';

  @override
  String get posInvoiceDetailsYear => 'Year';

  @override
  String get posInvoiceDetailsInvalidYear => 'Invalid year';

  @override
  String get posInvoiceDetailsVin => 'VIN';

  @override
  String get posInvoiceDetailsSaveProceed => 'Save & Continue to Invoice';

  @override
  String get posPaymentMethodTitle => 'Payment method';

  @override
  String get posPaymentMethodDescription =>
      'Select customer type, then choose how this invoice will be paid.';

  @override
  String get posPaymentCustomerType => 'Customer type';

  @override
  String get posPaymentIndividual => 'Individual';

  @override
  String get posPaymentCorporate => 'Corporate';

  @override
  String get posPaymentTapCustomerFirst =>
      'Tap Individual or Corporate first. Then choose Cash, Card, Tabby, etc.';

  @override
  String get posPaymentCorporateMulti =>
      'Corporate payment (multi-select to split)';

  @override
  String get posPaymentMulti => 'Payment (multi-select to split)';

  @override
  String get posPaymentAmountByMethod => 'Amount by payment method';

  @override
  String posPaymentRemaining(String amount) {
    return 'Remaining: $amount SAR';
  }

  @override
  String posPaymentAmountLabel(String method) {
    return '$method amount';
  }

  @override
  String get posPaymentClearSaved => 'Clear saved payment';

  @override
  String get posPaymentCash => 'Cash';

  @override
  String get posPaymentCard => 'Card';

  @override
  String get posPaymentTapToPay => 'Tap to Pay';

  @override
  String get posPaymentBankTransfer => 'Bank Transfer';

  @override
  String get posPaymentTamara => 'Tamara';

  @override
  String get posPaymentTabby => 'Tabby';

  @override
  String get posPaymentWallet => 'Wallet';

  @override
  String get posPaymentMonthlyBilling => 'Monthly Billing';

  @override
  String get posPaymentEmployees => 'Employees';

  @override
  String get posProductNoOrdersFound => 'No orders found';

  @override
  String get posProductOutOfStock => 'Out of stock';

  @override
  String get posProductLowStock => 'Low';

  @override
  String get posProductInStock => 'In stock';

  @override
  String get posProductOtherOils => 'Other Oils';

  @override
  String get posProductOtherOilFilters => 'Other Oil Filters';

  @override
  String get posProductGearOil => 'Gear Oil';

  @override
  String get posProductOilChangeDepartment => 'Oil Change Department';

  @override
  String get posTechOnlineNow => 'Online now';

  @override
  String get posTechNotAvailable => 'Not available';

  @override
  String get posTechWorkshopDuty => 'Workshop Duty';

  @override
  String get posTechOnCallDuty => 'On-Call Duty';

  @override
  String get posTechActive => 'Active';

  @override
  String get posCommonDone => 'Done';

  @override
  String get posCommonPrint => 'Print';

  @override
  String get posOrdersCorpBadge => 'CORP';

  @override
  String posSearchHistoryPlateLabel(Object plate) {
    return 'Plate: $plate';
  }

  @override
  String posSearchHistoryOrderLabel(Object orderNumber) {
    return 'Order: #$orderNumber';
  }

  @override
  String get posOrdersSelectedDepartments => 'Selected departments';

  @override
  String get posOrdersDeptNotReturnedInPayload =>
      'Departments not returned in order list payload.';

  @override
  String posOrdersTechnicianLabel(Object name) {
    return 'Technician: $name';
  }

  @override
  String get posOrdersTechnicianNone => 'None';

  @override
  String get posOrdersWaitingCorporateApproval => 'Waiting corporate approval';

  @override
  String posOrdersRejectedByCorporateReason(Object reason) {
    return 'Rejected by corporate: $reason';
  }

  @override
  String get posOrdersRejectedByCorporate => 'Rejected by corporate';

  @override
  String get posOrdersEditOrder => 'Edit Order';

  @override
  String get posOrdersCancelOrder => 'Cancel Order';

  @override
  String get posOrdersGenInvoice => 'Gen. Invoice';

  @override
  String get posOrdersInvoice => 'Invoice';

  @override
  String get posOrdersAddDept => 'Add Dept.';

  @override
  String get posDetailsWalkIn => 'Walk-in';

  @override
  String posDetailsOrderHash(Object id) {
    return 'Order #$id';
  }

  @override
  String posDetailsJobId(Object id) {
    return 'Job ID: $id';
  }

  @override
  String get posDetailsNoItemsInDept => 'No items bound to this department.';

  @override
  String posDetailsQtyLabel(Object qty) {
    return 'Qty: $qty';
  }

  @override
  String posDetailsSarEa(Object price) {
    return 'SAR $price / ea';
  }

  @override
  String get posDetailsActive => 'ACTIVE';

  @override
  String get posOrdersConfirmCompletion => 'Confirm Completion';

  @override
  String get posJobApproved => 'Job Approved!';

  @override
  String get posJobTechnicianCommissionLogged =>
      'Technician commission has been logged.';

  @override
  String get posJobTechnicianLabel => 'TECHNICIAN';

  @override
  String get posJobCommissionLabel => 'COMMISSION';

  @override
  String get posDutyNotApplicable => 'Not applicable';

  @override
  String get posDutyUnavailableOffline => 'Unavailable while offline';

  @override
  String get posDutyActive => 'Active';

  @override
  String posProductStockLabel(Object count) {
    return 'Stock: $count';
  }

  @override
  String get posProductSearchItemOrService => 'Search item or service';

  @override
  String get posProductIncVat => 'Inc. VAT';

  @override
  String get posOrdersJobBadge => 'JOB';

  @override
  String get posReceiptSimplifiedTaxInvoice => 'Simplified Tax Invoice';

  @override
  String get posReceiptBranch => 'Branch';

  @override
  String get posReceiptAddress => 'Address';

  @override
  String get posReceiptVatNumber => 'VAT Number';

  @override
  String get posReceiptInvoiceNo => 'Invoice No';

  @override
  String get posReceiptDate => 'Date';

  @override
  String get posReceiptCounter => 'Counter';

  @override
  String get posReceiptCashier => 'Cashier';

  @override
  String get posReceiptItem => 'Item';

  @override
  String get posReceiptQty => 'Qty';

  @override
  String get posReceiptUnitPrice => 'Unit Price';

  @override
  String get posReceiptTotal => 'Total';

  @override
  String get posReceiptTotalExcludingVat => 'Total (Excluding VAT)';

  @override
  String get posReceiptTotalTaxableAmountExclVat =>
      'Total Taxable Amount (Excluding VAT)';

  @override
  String get posReceiptTotalVat15 => 'Total VAT 15%';

  @override
  String get posReceiptTotalAmountDue => 'Total Amount Due';

  @override
  String get posReceiptNextOilChangeOdometer => 'Next oil change odometer';

  @override
  String get posReceiptCustomerDetails => 'Customer details';

  @override
  String get posReceiptName => 'Name';

  @override
  String get posReceiptMobile => 'Mobile';

  @override
  String get posReceiptVehicleNo => 'Vehicle No';

  @override
  String get posReceiptOdometer => 'Odometer';

  @override
  String get posReceiptMaintenanceChecklist => 'Maintenance checklist';

  @override
  String get posReceiptThankYou => 'Thank you';

  @override
  String get posThermalPrinterInvalidHost =>
      'Enter a valid printer IP or hostname.';

  @override
  String get posThermalPrinterInvalidPort => 'Enter a valid port (1–65535).';

  @override
  String get posThermalPrinterSaveFailed => 'Could not save settings.';

  @override
  String get posOrdersDeleteJobBody =>
      'Are you sure you want to delete this job? This action cannot be undone.';

  @override
  String get posOrdersJobCannotBeEdited => 'This job cannot be edited.';

  @override
  String posOrdersItemCount(Object count) {
    return '$count items';
  }

  @override
  String posOrdersTechnicianCount(Object count) {
    return '$count technicians';
  }

  @override
  String posOrdersVatPercent(Object pct) {
    return 'VAT ($pct%)';
  }

  @override
  String posOrdersDeptCount(Object count) {
    return '$count dept';
  }

  @override
  String posOrdersDeptNames(Object names) {
    return 'Dept: $names';
  }

  @override
  String get posOrdersRejectedCorporateReadOnly =>
      'Rejected corporate orders are read-only. Remove the order from the list.';

  @override
  String get posOrdersPleaseAddVehicleFirst =>
      'Please add vehicle number first (Add Customer)';

  @override
  String get posOrdersThisJobNoLineItems => 'This job has no line items.';

  @override
  String posOrdersDeptPromoWithName(Object name) {
    return 'Dept promo ($name)';
  }

  @override
  String posOrdersDeptDiscountPercent(Object percent) {
    return 'Dept discount ($percent%)';
  }

  @override
  String get posOrdersStatusDraft => 'DRAFT';

  @override
  String get posOrdersEditPayment => 'Edit payment';

  @override
  String get posReviewTechnicianFallback => 'Technician';

  @override
  String get posReviewItemFallback => 'Item';

  @override
  String get posReviewInvoiceCouldNotLoad => 'Invoice could not be loaded.';

  @override
  String get posReviewVehicleNoLabel => 'Vehicle no.';

  @override
  String get posReviewCustomerLabel => 'Customer';

  @override
  String get posReviewDiscountsApplyTaxableSubtotal =>
      'Invoice and promo discounts apply to the taxable subtotal.';

  @override
  String get posPaymentMethodTitleSplit =>
      'Payment Method (Select multiple if splitting)';

  @override
  String posReviewCorporatePayment(Object method) {
    return 'Corporate — $method';
  }

  @override
  String get posPaymentChangeCustomerTitle => 'Change customer';

  @override
  String get posPaymentChangeCustomerBody =>
      'Do you really want to change the customer? Your payment choices for this customer type will be cleared.';

  @override
  String get posPaymentChangeCustomerButton => 'Change customer';

  @override
  String posOrdersExceedsBy(String amount) {
    return 'Exceeds total by $amount';
  }

  @override
  String get posReviewUnitExclVat => 'Unit (Excl. VAT)';

  @override
  String get posReviewGrossBeforeVat => 'Gross Before VAT';

  @override
  String get posReviewTotalBeforeVat => 'Total Before VAT';

  @override
  String get posCommonQty => 'Qty';

  @override
  String get posCommonTech => 'Tech';

  @override
  String get posNavPurchaseOrder => 'Purchase Order';

  @override
  String get posPoTabCreate => 'Create';

  @override
  String get posPoTabHistory => 'History';

  @override
  String get posPoTabIncoming => 'Incoming';

  @override
  String get posPoDate => 'Date';

  @override
  String get posPoReference => 'Reference';

  @override
  String get posPoReferenceLoading => 'Generating reference…';

  @override
  String get posPoSupplier => 'Supplier';

  @override
  String get posPoSelectSupplier => 'Select supplier';

  @override
  String get posPoDescription => 'Description';

  @override
  String get posPoDescriptionHint => 'Optional notes for this purchase order';

  @override
  String get posPoLineItems => 'Line items';

  @override
  String posPoAvailableProductsCount(int count) {
    return '$count products';
  }

  @override
  String get posPoProductColumn => 'Product';

  @override
  String get posPoSearchProductHint => 'Search product...';

  @override
  String get posPoSearchProduct => 'Search product from branch stock';

  @override
  String get posPoItemDescription => 'Item description';

  @override
  String get posPoQty => 'Qty';

  @override
  String get posPoAddLine => 'Add line';

  @override
  String get posPoSubmit => 'Send to supplier';

  @override
  String get posPoSubmitSuccess => 'Purchase order sent to supplier';

  @override
  String get posPoNoHistory => 'No purchase orders yet';

  @override
  String get posPoNoIncoming => 'No incoming supplier invoices';

  @override
  String get posPoReceive => 'Receive';

  @override
  String get posPoReceivedQty => 'Received qty';

  @override
  String get posPoReceivedQtyHint =>
      'Leave blank to use invoice qty for each line';

  @override
  String get posPoInvoiceQty => 'Invoice qty';

  @override
  String get posPoConfirmReceive => 'Confirm receive';

  @override
  String get posPoReceiveSuccess => 'Goods received — branch inventory updated';

  @override
  String get corporateKpiTotal => 'Total';

  @override
  String get corporateMobileLabel => 'Mobile';

  @override
  String get corporateVatShortLabel => 'VAT';

  @override
  String get corporateCreditLimitLabel => 'Credit Limit';

  @override
  String get corporateDueBalanceLabel => 'Due Balance';

  @override
  String get corporateBranchesLabel => 'Branches';

  @override
  String get corporateCancelButton => 'Cancel';

  @override
  String get corporateSubmitButton => 'Submit';

  @override
  String get approvalsQueueSupplierInvoices => 'Supplier Invoices';

  @override
  String get ownerDashboardSubtitle => 'Dashboard';

  @override
  String get ownerDashboardGrossMarginProfit => 'Gross Profit';

  @override
  String get ownerDashboardGrossMarginSubtitle => 'Revenue − COGS';

  @override
  String get ownerDashboardPendingApprovalsKpi => 'Pending Approvals';

  @override
  String get ownerDashboardLowStockProducts => 'Low Stock Products';

  @override
  String ownerDashboardLowStockAlertSingular(int count) {
    return '$count low stock alert — open inventory to review';
  }

  @override
  String ownerDashboardLowStockAlertPlural(int count) {
    return '$count low stock alerts — open inventory to review';
  }

  @override
  String get ownerDashboardQuickActions => 'Quick Actions';

  @override
  String get ownerDashboardActionEmployeesTitle => 'Employee Management';

  @override
  String get ownerDashboardActionEmployeesSubtitle => 'Manage staff & roles';

  @override
  String get ownerDashboardActionDeptProductsTitle => 'Dept & Products';

  @override
  String get ownerDashboardActionDeptProductsSubtitle =>
      'Catalog & departments';

  @override
  String get ownerDashboardActionApprovalsTitle => 'Approvals Queue';

  @override
  String get ownerDashboardActionApprovalsSubtitle => 'Review pending items';

  @override
  String get ownerDashboardActionSuppliersTitle => 'Suppliers & Purchases';

  @override
  String get ownerDashboardActionSuppliersSubtitle => 'Orders & suppliers';

  @override
  String ownerDashboardScreenNotConnected(String title) {
    return '$title screen is not connected yet';
  }

  @override
  String get ownerReportsTitle => 'Reports';

  @override
  String get ownerReportsTabOrders => 'Orders';

  @override
  String get ownerReportsTabDailySales => 'Daily Sales';

  @override
  String get ownerReportsTabByTechnician => 'By Technician';

  @override
  String get ownerReportsTabByCustomer => 'By Customer';

  @override
  String get ownerReportsTabByProduct => 'By Product';

  @override
  String get ownerReportsTabByDepartment => 'By Department';

  @override
  String get ownerReportsTabByBranch => 'By Branch';

  @override
  String get ownerReportsTabByCashier => 'By Cashier';

  @override
  String get ownerReportsKpiTotalRevenue => 'Total Revenue';

  @override
  String get ownerReportsKpiRevenueChange => 'Revenue Change';

  @override
  String get ownerReportsKpiRevenueChangeSubtitle => 'vs previous period';

  @override
  String get ownerReportsKpiStockValue => 'Stock Value';

  @override
  String ownerReportsKpiStockValueSubtitle(int count) {
    return '$count SKUs on hand';
  }

  @override
  String get ownerReportsKpiPotentialProfit => 'Potential Profit';

  @override
  String get ownerReportsPaymentAll => 'All';

  @override
  String get ownerReportsPaymentCash => 'Cash';

  @override
  String get ownerReportsPaymentCard => 'Card';

  @override
  String get ownerReportsPaymentBankTransfer => 'Bank Transfer';

  @override
  String get ownerReportsSearchHintOrders => 'Search invoice, customer, plate…';

  @override
  String get ownerReportsSearchHintDailySales => 'Search day, date, amount…';

  @override
  String get ownerReportsSearchHintTechnician =>
      'Search technician, jobs, revenue…';

  @override
  String get ownerReportsSearchHintCustomer => 'Search phone, plate, orders…';

  @override
  String get ownerReportsSearchHintProduct => 'Search product, type, qty…';

  @override
  String get ownerReportsSearchHintDepartment => 'Search department, orders…';

  @override
  String get ownerReportsSearchHintBranch => 'Search branch, orders…';

  @override
  String get ownerReportsSearchHintCashier => 'Search cashier, orders…';

  @override
  String get ownerReportsSearchHintDefault => 'Search…';

  @override
  String get ownerReportsErrorNoConnection => 'No Connection';

  @override
  String get ownerReportsErrorGeneric => 'Something went wrong';

  @override
  String get ownerReportsTryAgain => 'Try Again';

  @override
  String get ownerReportsRetry => 'Retry';

  @override
  String get ownerPettyCashTitle => 'Petty Cash';

  @override
  String get ownerPettyCashKpiTotalFloat => 'Total Staff Float';

  @override
  String ownerPettyCashKpiTotalFloatSubtitle(int count) {
    return '$count staff wallets';
  }

  @override
  String get ownerPettyCashKpiPendingRequests => 'Pending Requests';

  @override
  String ownerPettyCashKpiPendingRequestsSubtitle(int count) {
    return '$count awaiting action';
  }

  @override
  String get ownerPettyCashTabWallets => 'Staff Wallets';

  @override
  String get ownerPettyCashTabRequests => 'All Requests';

  @override
  String get ownerPettyCashTabReport => 'Report';

  @override
  String get ownerPettyCashIssueButton => 'Issue Petty Cash';

  @override
  String get ownerPettyCashEmptyWallets => 'No staff wallets found';

  @override
  String get ownerPettyCashEmptyRequests => 'No requests yet';

  @override
  String get ownerPettyCashStaffMemberLabel => 'Staff Member *';

  @override
  String get ownerPettyCashSelectStaffHint => 'Select staff';

  @override
  String get ownerPettyCashNoStaffAvailable => 'No staff available';

  @override
  String get ownerPettyCashBranchLabel => 'Branch *';

  @override
  String get ownerPettyCashSelectBranchHint => 'Select branch';

  @override
  String get ownerPettyCashNoBranches => 'No branches';

  @override
  String get ownerPettyCashAmountLabel => 'Amount (SAR) *';

  @override
  String get ownerPettyCashPayFromLabel => 'Pay From (Cash/Bank) *';

  @override
  String get ownerPettyCashSelectAccountHint => 'Select account';

  @override
  String get ownerPettyCashNoAccounts => 'No cash/bank accounts';

  @override
  String get ownerPettyCashNoteLabel => 'Note';

  @override
  String get ownerPettyCashNoteHint => 'Optional note...';

  @override
  String get ownerPettyCashIssuing => 'Issuing…';

  @override
  String get ownerPettyCashIssueNow => 'Issue Now';

  @override
  String get ownerPettyCashCancel => 'Cancel';

  @override
  String get ownerPettyCashEnterValidAmount => 'Enter a valid amount.';

  @override
  String get ownerPettyCashIssuedDefault => 'Petty cash issued';

  @override
  String get ownerPettyCashRegisterDialogTitle => 'Petty Cash Wallet Register';

  @override
  String ownerPettyCashStaffBranchLabel(String branch) {
    return 'Staff · $branch';
  }

  @override
  String get ownerPettyCashCurrentBalance => 'CURRENT BALANCE';

  @override
  String get ownerPettyCashWalletTag => '— · Petty Cash Wallet';

  @override
  String get ownerPettyCashRegisterSectionTitle =>
      'Wallet Register — Top-ups & Expenses';

  @override
  String get ownerPettyCashNoRegisterEntries =>
      'No wallet register yet.\nIssue petty cash or approve a fund top-up to create one.';

  @override
  String get ownerEmployeesTitle => 'Employees';

  @override
  String get ownerEmployeesKpiTotalStaff => 'Total Staff';

  @override
  String get ownerEmployeesKpiOnDuty => 'On Workshop Duty';

  @override
  String get ownerEmployeesKpiOnCall => 'On-Call';

  @override
  String get ownerEmployeesTabEmployees => 'Employees';

  @override
  String get ownerEmployeesTabRoles => 'Roles';

  @override
  String get ownerEmployeesSearchHint => 'Search by name, role, phone…';

  @override
  String get ownerEmployeesCreateRole => 'Create Role';

  @override
  String get ownerEmployeesAddEmployee => 'Add Employee';

  @override
  String get ownerEmployeesEmptyFiltered => 'No employees match your search';

  @override
  String get ownerEmployeesEmptyDefault => 'No employees yet';

  @override
  String get ownerEmployeesClearSearch => 'Clear search';

  @override
  String get ownerInventoryTitle => 'Inventory Management';

  @override
  String get ownerInventoryKpiTotalProducts => 'Total Products';

  @override
  String get ownerInventoryKpiLowStock => 'Low Stock';

  @override
  String get ownerInventoryKpiInvValue => 'Inv. Value';

  @override
  String get ownerInventoryTabStock => 'Stock';

  @override
  String get ownerInventoryTabUomProfiles => 'UOM Profiles';

  @override
  String get ownerInventoryTabValue => 'Value';

  @override
  String get ownerSalesReturnsTitle => 'Sales Returns';

  @override
  String get ownerSalesReturnsStatusAll => 'All';

  @override
  String get ownerSalesReturnsStatusApproved => 'Approved';

  @override
  String get ownerSalesReturnsStatusPending => 'Pending';

  @override
  String get ownerSalesReturnsStatusRejected => 'Rejected';

  @override
  String get ownerSalesReturnsKpiShownReturns => 'Shown Returns';

  @override
  String get ownerSalesReturnsKpiShownAmount => 'Shown Amount';

  @override
  String get ownerSalesReturnsSearchHint => 'Search invoice #';

  @override
  String get ownerSalesReturnsEmptyTitle => 'No returns found';

  @override
  String get ownerSalesReturnsEmptySearchBody =>
      'Try a different invoice # or\nwidening the date range.';

  @override
  String get ownerSalesReturnsEmptyDefaultBody =>
      'Try widening the date range or\nswitching status to All.';

  @override
  String get ownerSalesReturnsClearFilters => 'Clear all filters';

  @override
  String get ownerSalesReturnsTypeCash => 'Cash';

  @override
  String get ownerSalesReturnsTypeCreditNote => 'Credit Note';

  @override
  String get ownerSalesReturnsTypeExchange => 'Exchange';

  @override
  String get ownerPosMonitoringTitle => 'POS Monitoring';

  @override
  String get ownerPosMonitoringKpiSalesInRange => 'Sales in range';

  @override
  String get ownerPosMonitoringKpiLiveCounters => 'Live Counters';

  @override
  String get ownerPosMonitoringKpiOpenOrders => 'Open Orders';

  @override
  String get ownerPosMonitoringTabLive => 'Live Counters';

  @override
  String get ownerPosMonitoringTabClosing => 'Closing Reports';

  @override
  String get ownerPosMonitoringEmptyLive => 'No active live counters';

  @override
  String get ownerPosMonitoringEmptyClosing => 'No closing reports available';

  @override
  String get ownerPosMonitoringStatShiftSales => 'SHIFT SALES';

  @override
  String get ownerPosMonitoringStatOpenOrders => 'OPEN ORDERS';

  @override
  String get ownerPosMonitoringStatElapsed => 'ELAPSED';

  @override
  String get ownerPosMonitoringStart => 'Start ';

  @override
  String get ownerPosMonitoringEnd => 'End ';

  @override
  String get ownerPosMonitoringStillOpen => 'still open · counter active';

  @override
  String get ownerPosMonitoringStarted => 'Started ';

  @override
  String get ownerPosMonitoringEnded => 'Ended ';

  @override
  String get ownerPosMonitoringShort => 'SHORT';

  @override
  String get ownerPosMonitoringExcess => 'EXCESS';

  @override
  String get ownerPosMonitoringBalanced => 'BALANCED';

  @override
  String get ownerPosMonitoringCategory => 'Category';

  @override
  String get ownerPosMonitoringSystem => 'System';

  @override
  String get ownerPosMonitoringPhysical => 'Physical';

  @override
  String get ownerPosMonitoringDiff => 'Diff';

  @override
  String get ownerPosMonitoringCash => 'Cash';

  @override
  String get ownerPosMonitoringBankCards => 'Bank/Cards';

  @override
  String get ownerPosMonitoringCorporate => 'Corporate';

  @override
  String get ownerPosMonitoringTamara => 'Tamara';

  @override
  String get ownerPosMonitoringTabby => 'Tabby';

  @override
  String get ownerPosMonitoringOthersEmployees => 'Others (Employees)';

  @override
  String get ownerPosMonitoringTotalSales => 'Total Sales';

  @override
  String get ownerPosMonitoringBreakdownUnavailable =>
      '⚠ Full breakdown unavailable — deploy latest backend to see per-category data';

  @override
  String get ownerSettingsTitle => 'Settings';

  @override
  String get ownerSettingsLogout => 'Logout';

  @override
  String get ownerSettingsVersionFooter => 'Filter Workshop OS • Version 1.0.1';

  @override
  String get ownerSettingsLogoutDialogTitle => 'Log out';

  @override
  String get ownerSettingsLogoutDialogBody =>
      'Are you sure you want to log out from your account?';

  @override
  String get ownerSettingsCancel => 'Cancel';

  @override
  String get ownerSettingsLogoutConfirm => 'Log out';

  @override
  String get ownerSettingsAdminFallback => 'Admin';

  @override
  String get ownerSettingsWorkshopProfile => 'WORKSHOP PROFILE';

  @override
  String get ownerSettingsEdit => 'Edit';

  @override
  String get ownerSettingsFieldWorkshopName => 'Workshop Name';

  @override
  String get ownerSettingsFieldOwnerName => 'Owner Name';

  @override
  String get ownerSettingsFieldMobile => 'Mobile';

  @override
  String get ownerSettingsFieldEmail => 'Email';

  @override
  String get ownerSettingsFieldAddress => 'Address';

  @override
  String get ownerSettingsFieldCurrency => 'Currency';

  @override
  String get ownerSettingsFieldVat => 'VAT';

  @override
  String get ownerSettingsInclusive => 'Inclusive';

  @override
  String get ownerSettingsExclusive => 'Exclusive';

  @override
  String get ownerSettingsReadOnly => 'READ ONLY';

  @override
  String get ownerSettingsSaveChanges => 'Save Changes';

  @override
  String get ownerSettingsProfileUpdated => 'Profile updated successfully';

  @override
  String get ownerCatalogTabDepartments => 'Departments';

  @override
  String get ownerCatalogTabProducts => 'Products';

  @override
  String get ownerCatalogTabServices => 'Services';

  @override
  String get ownerCatalogTabCategories => 'Categories';

  @override
  String get ownerCatalogSearchDepartments => 'Search departments...';

  @override
  String get ownerCatalogRequestDepartment => 'Request Department';

  @override
  String get ownerCatalogRequestProduct => 'Request Product';

  @override
  String get ownerCatalogRequestCategory => 'Request Category';

  @override
  String get ownerCatalogMasterDepartment => 'Master Department';

  @override
  String get ownerCatalogAdd => 'Add';

  @override
  String ownerCatalogAdded(int count) {
    return 'Added ($count)';
  }

  @override
  String ownerCatalogNotAdded(int count) {
    return 'Not added ($count)';
  }

  @override
  String get ownerCatalogSelected => 'Selected: ';

  @override
  String get ownerCatalogSelectAll => 'Select all';

  @override
  String get ownerCatalogClear => 'Clear';

  @override
  String get ownerCatalogAddToBranches => 'Add to branches...';

  @override
  String ownerLowStockCritical(String level, String unit) {
    return 'Critical: $level $unit';
  }

  @override
  String ownerLowStockQty(String qty, String unit) {
    return '$qty $unit';
  }

  @override
  String get ownerUnitLiter => 'liter';

  @override
  String get ownerUnitPiece => 'piece';

  @override
  String get ownerUnitPcs => 'pcs';

  @override
  String get ownerUnitKg => 'kg';

  @override
  String get ownerUnitMl => 'ml';

  @override
  String get ownerUnitBox => 'box';

  @override
  String get ownerUnitSet => 'set';

  @override
  String get ownerSettingsStatusApproved => 'APPROVED';

  @override
  String get ownerSettingsStatusPending => 'PENDING';

  @override
  String get ownerSettingsStatusRejected => 'REJECTED';

  @override
  String get ownerSettingsStatusActive => 'ACTIVE';

  @override
  String get ownerPurchaseInvoicesTitle => 'Purchase Invoices';

  @override
  String get ownerPurchaseInvoicesNew => 'New Invoice';

  @override
  String get ownerPurchaseInvoicesPriceReport => 'Price Report';

  @override
  String get ownerPurchaseInvoicesKpiPayable => 'Accounts Payable';

  @override
  String get ownerPurchaseInvoicesKpiPayableSub => 'Owed to vendors';

  @override
  String get ownerPurchaseInvoicesKpiTotal => 'Total Invoices';

  @override
  String get ownerPurchaseInvoicesKpiTotalSub => 'All time';

  @override
  String get ownerPurchaseInvoicesSearchHint =>
      'Search invoice #, vendor, ref…';

  @override
  String get ownerPurchaseInvoicesEmpty => 'No invoices found';

  @override
  String ownerPurchaseInvoicesDue(String date) {
    return 'Due $date';
  }

  @override
  String get ownerPurchaseInvoicesStockUpdated => 'Stock updated';

  @override
  String get ownerPurchaseInvoicesStockPending => 'Stock pending';

  @override
  String get ownerPurchaseInvoicesPaid => 'Paid';

  @override
  String get ownerPurchaseInvoicesPartial => 'Partial';

  @override
  String get ownerPurchaseInvoicesUnpaid => 'Unpaid';

  @override
  String get ownerPurchaseInvoicesInvoice => 'Invoice';

  @override
  String get ownerPurchaseInvoicesUnknownVendor => 'Unknown vendor';

  @override
  String get ownerPurchaseInvoicesAllVendors => 'All Vendors';

  @override
  String get ownerPurchaseInvoicesAllProducts => 'All Products';

  @override
  String get ownerPurchaseInvoicesStatusAll => 'All';

  @override
  String get ownerPurchaseInvoicesStatusPending => 'Pending';

  @override
  String get ownerPurchaseInvoicesStatusApproved => 'Approved';

  @override
  String get ownerPurchaseInvoicesStatusDelivered => 'Delivered';

  @override
  String get ownerPurchaseInvoicesStatusCompleted => 'Completed';

  @override
  String get ownerPurchaseInvoicesStatusDraft => 'Draft';

  @override
  String get ownerPurchaseInvoicesStatusRejected => 'Rejected';

  @override
  String get ownerCommonAllDepts => 'All Depts';

  @override
  String get ownerCommonAllDepartments => 'All departments';

  @override
  String get ownerCommonFree => 'Free';

  @override
  String get ownerCommonQty => 'Qty';

  @override
  String get ownerCommonSelectAll => 'Select all';

  @override
  String get ownerCommonApprove => 'Approve';

  @override
  String get ownerCommonReject => 'Reject';

  @override
  String get ownerCommonPending => 'pending';

  @override
  String get ownerCommonActive => 'active';

  @override
  String get ownerCommonInactive => 'Inactive';

  @override
  String get ownerCommonInvoice => 'Invoice';

  @override
  String get ownerCommonStartDate => 'Start date';

  @override
  String get ownerCommonEndDate => 'End date';

  @override
  String get ownerCommonFrom => 'From';

  @override
  String get ownerCommonTo => 'To';

  @override
  String get ownerCatalogSearchProducts => 'Search products...';

  @override
  String get ownerCatalogSearchServices => 'Search services...';

  @override
  String get ownerCatalogSearchCategories => 'Search categories...';

  @override
  String get ownerCatalogRequestService => 'Request Service';

  @override
  String get ownerInventorySearchHint => 'Search name or SKU…';

  @override
  String get ownerInventoryLowStockFilter => 'Low Stock';

  @override
  String ownerInventoryProductsCount(int count) {
    return '$count products';
  }

  @override
  String get ownerInventoryNoProducts => 'No products found';

  @override
  String get ownerInventoryCritical => 'Critical';

  @override
  String get ownerInventoryCriticalDash => 'Critical —';

  @override
  String ownerInventoryCriticalValue(String value) {
    return 'Critical $value';
  }

  @override
  String get ownerInventoryAdjust => 'Adjust';

  @override
  String get ownerInventoryRequest => 'Request';

  @override
  String ownerInventoryCurrentOpening(
    String current,
    String unit,
    String opening,
  ) {
    return 'Current $current $unit · Opening $opening';
  }

  @override
  String get ownerInventoryCriticalStockLevel => 'Critical stock level';

  @override
  String get ownerInventoryManualAdjustTitle => 'Manual Inventory Adjustment';

  @override
  String get ownerInventoryApplyAdjustment => 'Apply Adjustment';

  @override
  String get ownerInventoryManualAdjust => 'Manual Adjust';

  @override
  String get ownerApprovalsRequestedBy => 'Requested by';

  @override
  String get ownerApprovalsReference => 'Reference #';

  @override
  String get ownerApprovalsBranch => 'Branch';

  @override
  String get ownerApprovalsDetails => 'Details';

  @override
  String get ownerApprovalsRequestedAt => 'Requested at';

  @override
  String get ownerApprovalsRejectTitle => 'Reject Request';

  @override
  String get ownerApprovalsApproveExpense => 'Approve Expense';

  @override
  String get ownerApprovalsApproveTopUp => 'Approve Top-up';

  @override
  String get ownerApprovalsApproveWalletExpense => 'Approve Wallet Expense';

  @override
  String get ownerApprovalsApproveWalletTopUp => 'Approve Wallet Top-up';

  @override
  String get ownerPnLTitle => 'P&L';

  @override
  String get ownerPnLRevenue => 'REVENUE';

  @override
  String get ownerPnLCogs => 'COST OF GOODS SOLD';

  @override
  String get ownerPnLOperatingExpenses => 'OPERATING EXPENSES';

  @override
  String get ownerPnLTotalRevenue => 'Total Revenue';

  @override
  String get ownerPnLTotalCogs => 'Total Cost of Goods Sold';

  @override
  String get ownerPnLGrossProfit => 'Gross Profit';

  @override
  String get ownerExpenseTitle => 'Expense';

  @override
  String get ownerExpenseSearchHint => 'Search code or name';

  @override
  String ownerExpenseAccountsCount(int count) {
    return '$count accounts';
  }

  @override
  String get ownerExpenseAutoLinked => 'Auto-linked';

  @override
  String get ownerExpenseOperating => 'Operating Expense';

  @override
  String get ownerExpenseSharedDebit => 'Shared · Debit';

  @override
  String get ownerCommissionsTitle => 'Commissions';

  @override
  String get ownerCommissionsTabRules => 'Rules';

  @override
  String get ownerCommissionsTabPending => 'Pending';

  @override
  String get ownerCommissionsTabLedger => 'Ledger';

  @override
  String get ownerCommissionsPendingEmployees => 'Pending Employees';

  @override
  String get ownerCommissionsTotalPaid => 'Total Paid';

  @override
  String get ownerCommissionsTotalAccrued => 'Total Accrued';

  @override
  String get ownerCommissionsAllEmployees => 'All Employees';

  @override
  String get ownerCommissionsAllStatus => 'All Status';

  @override
  String ownerCommissionsSelectAllAccrued(int count) {
    return 'Select All Accrued ($count)';
  }

  @override
  String get ownerCommissionsAccrued => 'accrued';

  @override
  String get ownerCommissionsRate => 'RATE';

  @override
  String get ownerCommissionsDate => 'DATE';

  @override
  String get ownerCommissionsJobCard => 'JOB CARD';

  @override
  String get ownerCommissionsPay => 'Pay';

  @override
  String get ownerDiscountsTitle => 'Discounts';

  @override
  String get ownerDiscountsTotal => 'Total Discount';

  @override
  String get ownerDiscountsLineItem => 'Line / Item Discount';

  @override
  String get ownerDiscountsInvoices => 'Discounted Invoices';

  @override
  String get ownerDiscountsEmptyTitle => 'No discounted invoices found';

  @override
  String get ownerDiscountsEmptyBody => 'Try widening the date range';

  @override
  String get ownerSuppliersTitle => 'Suppliers & Purchases';

  @override
  String get ownerSuppliersTabSuppliers => 'Suppliers';

  @override
  String get ownerSuppliersTabHistory => 'Purchase History';

  @override
  String get ownerSuppliersSearchHint => 'Search suppliers (name, phone, VAT)';

  @override
  String get ownerSuppliersAdd => 'Add Supplier';

  @override
  String get ownerSuppliersRole => 'Supplier';

  @override
  String get ownerSuppliersCr => 'CR';

  @override
  String get ownerSuppliersVat => 'VAT';

  @override
  String get ownerAffiliatedTitle => 'Affiliated Suppliers';

  @override
  String get ownerAffiliatedActive => 'Active Suppliers';

  @override
  String get ownerAffiliatedTotal => 'Total Suppliers';

  @override
  String get ownerAffiliatedPayable => 'Aggregate Payable';

  @override
  String ownerAffiliatedOpening(String amount) {
    return 'Opening $amount';
  }

  @override
  String ownerAffiliatedSNo(int n) {
    return 'S.No. $n #';
  }

  @override
  String get ownerAffiliatedAdd => 'Add new supplier +';

  @override
  String get ownerNonAffiliatedTitle => 'Non-Affiliated Suppliers';

  @override
  String get ownerNonAffiliatedAdd => 'Add new non-affiliated supplier +';

  @override
  String get ownerLockerTitle => 'Locker Management';

  @override
  String get ownerLockerAssigned => 'Assigned to Officer';

  @override
  String get ownerLockerPendingPickups => 'Pending Pickups';

  @override
  String get ownerLockerVaultBalance => 'Locker Vault Balance';

  @override
  String get ownerLockerTabRequests => 'Requests';

  @override
  String get ownerLockerTabCollections => 'Collections';

  @override
  String get ownerLockerTabDeposits => 'Deposits';

  @override
  String get ownerLockerTabPettyCash => 'Petty Cash';

  @override
  String get ownerLockerRecentCollections => 'Recent collections';

  @override
  String get ownerLockerColCashier => 'CASHIER';

  @override
  String get ownerLockerColBranch => 'BRANCH';

  @override
  String get ownerLockerColReference => 'REFERENCE';

  @override
  String get ownerPettyClosingBalance => 'Closing Balance';

  @override
  String get ownerPettyTotalCredit => 'Total Credit';

  @override
  String get ownerPettyTotalDebit => 'Total Debit';

  @override
  String get ownerPettyAccountCategory => 'Account category';

  @override
  String get ownerPettyAllCategories => 'All categories';

  @override
  String get ownerPettyUserEmployee => 'User / employee';

  @override
  String get ownerPettyAllEmployees => 'All employees';

  @override
  String get ownerPettyStatement => 'Statement';

  @override
  String get ownerPettyOpeningBalance => 'Opening balance';

  @override
  String get ownerPettyNoTransactions => 'No transactions in this period';

  @override
  String ownerPettyFromTo(String from, String to) {
    return 'From $from · To $to';
  }

  @override
  String get ownerReportsColInvoice => 'INVOICE';

  @override
  String get ownerReportsColOrderType => 'ORDER TYPE';

  @override
  String get ownerReportsColStatus => 'STATUS';

  @override
  String get ownerReportsColTotalSar => 'TOTAL (SAR)';

  @override
  String get ownerReportsColTotalSarAr => 'TOTAL (ر.س)';

  @override
  String get ownerReportsEmptyOrdersSearch =>
      'No invoiced orders match your search.';

  @override
  String get ownerReportsEmptyOrdersScope =>
      'No invoiced orders in this scope.';

  @override
  String get ownerReportsNoInvoiceYet =>
      'This order does not have an invoice yet.';

  @override
  String get ownerReportsCouldNotLoadInvoice => 'Could not load invoice.';

  @override
  String get ownerReportsFailedOpenInvoice =>
      'Failed to open invoice. Please try again.';

  @override
  String get ownerReportsStatusInvoiced => 'INVOICED';

  @override
  String get ownerReportsOrderWalkIn => 'Walk In';

  @override
  String get ownerReportsColCashier => 'CASHIER';

  @override
  String get ownerReportsColTotalOrders => 'TOTAL ORDERS';

  @override
  String get ownerReportsColTotalRevenue => 'TOTAL REVENUE (SAR)';

  @override
  String get ownerReportsColBranch => 'BRANCH';

  @override
  String get ownerReportsColCompletedOrders => 'COMPLETED ORDERS';

  @override
  String get ownerReportsColRevenue => 'REVENUE (SAR)';

  @override
  String get ownerReportsColDepartment => 'DEPARTMENT';

  @override
  String get ownerReportsColOrders => 'ORDERS';

  @override
  String get ownerReportsColProductService => 'PRODUCT / SERVICE';

  @override
  String get ownerReportsColType => 'TYPE';

  @override
  String get ownerReportsColQty => 'QTY';

  @override
  String get ownerReportsColPhone => 'PHONE NUMBER';

  @override
  String get ownerReportsColPlate => 'PLATE NUMBER';

  @override
  String get ownerReportsColTechnician => 'TECHNICIAN';

  @override
  String get ownerReportsColCompletedJobs => 'COMPLETED JOBS';

  @override
  String get ownerReportsColCommission => 'COMMISSION (SAR)';

  @override
  String get ownerReportsColDay => 'DAY';

  @override
  String get ownerReportsColDate => 'DATE';

  @override
  String get ownerCatalogAllTypes => 'All types';

  @override
  String get ownerCatalogTypeProduct => 'Product';

  @override
  String get ownerCatalogTypeService => 'Service';

  @override
  String get ownerCatalogDepartmentSuffix => 'Department';

  @override
  String get ownerPurchaseQtyUnit => 'QTY / UNIT';

  @override
  String get ownerPurchaseUnitPrice => 'UNIT PRICE';

  @override
  String get ownerPurchaseLineTotal => 'LINE TOTAL';

  @override
  String get ownerPurchaseTaxVat => 'TAX (VAT)';

  @override
  String get ownerPurchaseGrandTotal => 'GRAND TOTAL';

  @override
  String get ownerPurchaseHistoryTotal => 'Total';

  @override
  String ownerPurchaseHistoryItems(String count) {
    return '$count items';
  }

  @override
  String get ownerCommissionsNewRule => 'New Rule';

  @override
  String get ownerCommissionsRulesHeading => 'Commission Rules';

  @override
  String get ownerCommissionsRulesHint =>
      'Priority engine: smaller priority value wins. Falls back to employee default percent if nothing matches.';

  @override
  String get ownerCommissionsSearchRules => 'Search rules';

  @override
  String get ownerCommissionsNoRulesYet =>
      'No commission rules yet — start by creating one';

  @override
  String get ownerCommissionsPendingPayoutByEmployee =>
      'Pending Payout by Employee';

  @override
  String get ownerCommissionsNoPendingPayouts => 'No pending payouts.';

  @override
  String ownerCommissionsEntriesAmount(String count, String amount) {
    return '$count entries · $amount';
  }

  @override
  String get ownerCommissionsSelectedForPayout => 'Selected for Payout';

  @override
  String get ownerCommissionsNoEntriesMatch =>
      'No commission entries match these filters.';

  @override
  String get ownerInventoryUomExplainer =>
      'Create reusable packing rules — e.g. 1 Box = 12 Liter. Link a profile to each product. Stock is stored in workshop units.';

  @override
  String get ownerInventoryLinkProfileTitle => 'Link Profile to Product';

  @override
  String get ownerInventoryLinkProfileSubtitle =>
      'Assign a packing profile to each product';

  @override
  String get ownerInventoryNewProfile => 'New Profile';

  @override
  String get ownerInventoryNoProfilesYet =>
      'No profiles yet — create one to get started';

  @override
  String ownerInventoryLinkedProducts(String count) {
    return '$count linked products';
  }

  @override
  String get ownerInventoryLink => 'Link';

  @override
  String get ownerInventoryChange => 'Change';

  @override
  String get ownerCommonDelete => 'Delete';

  @override
  String get ownerCommonSku => 'SKU';

  @override
  String get ownerCommonCancel => 'Cancel';

  @override
  String get ownerCommonRetry => 'Retry';

  @override
  String get ownerCommonActiveLabel => 'Active';

  @override
  String get ownerCommonEdit => 'Edit';

  @override
  String get ownerAffiliatedAddTitle => 'Add Affiliated Supplier(s)';

  @override
  String get ownerAffiliatedHideLinked => 'Hide already linked suppliers';

  @override
  String get ownerAffiliatedCouldNotLoadBranches => 'Could not load branches';

  @override
  String get ownerAffiliatedCouldNotLoadSuppliers =>
      'Could not load suppliers. Pull down to retry';

  @override
  String get ownerAffiliatedNoRegistered => 'No registered suppliers found';

  @override
  String get ownerAffiliatedLinked => 'Linked';

  @override
  String get ownerAffiliatedOpeningBal => 'OPENING BAL.';

  @override
  String get ownerAffiliatedAsOfDate => 'AS OF DATE';

  @override
  String get ownerAffiliatedDefaultBranch => 'DEFAULT BRANCH';

  @override
  String get ownerAffiliatedSearchRegistered => 'SEARCH REGISTERED SUPPLIERS';

  @override
  String get ownerAffiliatedSearchHint => 'Search supplier, mobile, VAT or CR';

  @override
  String get ownerAffiliatedLoadingBranches => 'Loading branches…';

  @override
  String get ownerAffiliatedAdding => 'Adding…';

  @override
  String ownerAffiliatedAddCount(String count) {
    return 'Add supplier(s) $count';
  }

  @override
  String get ownerLockerCashInTransit => 'Cash in Transit — Locker';

  @override
  String get ownerLockerCashierClosings =>
      'Cashier closings awaiting an officer';

  @override
  String get ownerLockerOnTheWay => 'On-the-way collections';

  @override
  String get ownerLockerOverdue => 'Overdue (>24h)';

  @override
  String get ownerLockerOverdueSubtitle => 'Open longer than 24h';

  @override
  String get ownerLockerPendingApprovals => 'Pending Approvals';

  @override
  String get ownerLockerPendingApprovalsSubtitle =>
      'Variance awaiting supervisor';

  @override
  String get ownerLockerCollectedToday => 'Collected Today';

  @override
  String get ownerLockerMonthlyCollected => 'Monthly Collected';

  @override
  String get ownerLockerOpenShiftVariance => 'Open-Shift Variance';

  @override
  String get ownerLockerOpenShiftSubtitle => 'Sum of |cashDiff| on open shifts';

  @override
  String get ownerLockerTabStaff => 'Staff';

  @override
  String get ownerLockerSupervisors => 'Locker supervisors';

  @override
  String get ownerLockerCollectionOfficers => 'Collection officers';

  @override
  String get ownerLockerNoCollectors => 'No collectors created yet';

  @override
  String get ownerLockerNoSupervisor => 'No supervisor created yet';

  @override
  String get ownerLockerColName => 'NAME';

  @override
  String get ownerLockerColEmail => 'EMAIL';

  @override
  String get ownerLockerColMobile => 'MOBILE';

  @override
  String get ownerLockerColStatus => 'STATUS';

  @override
  String get ownerLockerRecentRequests => 'Recent collection requests';

  @override
  String get ownerLockerBankDeposits => 'Bank deposits (locker → bank)';

  @override
  String get ownerLockerPettyIssued => 'Petty cash issued from locker';

  @override
  String get ownerDiscountsClearFilters => 'Clear all filters';

  @override
  String get ownerDiscountsSheetDepartment => 'Department';

  @override
  String get ownerDiscountsSheetTotal => 'Total discount';

  @override
  String get ownerDiscountsInvoiceDiscount => 'Invoice Discount';

  @override
  String get ownerDiscountsPromoCode => 'Promo Code';

  @override
  String get ownerRolesWorkshopRoles => 'Workshop Roles';

  @override
  String get ownerRolesEmpty =>
      'No custom roles yet. Tap Create Role to bundle permissions you can assign to employees.';

  @override
  String ownerRolesPermissionsCount(String count) {
    return '$count permissions';
  }

  @override
  String get ownerRolesPortalWorkshop => 'workshop';

  @override
  String get ownerRolesPortalCashier => 'cashier';

  @override
  String get ownerRolesPortalTechnician => 'technician';

  @override
  String get ownerRolesAndPermissions => 'Roles & Permissions';

  @override
  String ownerRolesDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? Any employees assigned to this role will lose its permissions.';
  }

  @override
  String get ownerRolesSaveChanges => 'Save Changes';

  @override
  String get ownerInventoryFormulaLabel => 'Formula: ';

  @override
  String ownerInventoryFormulaBody(String currency) {
    return 'for each product in scope, line value = current stock × purchase price. The KPI total is the sum of all line values (displayed rounded to the nearest $currency).';
  }

  @override
  String get ownerInventoryScopeLabel => 'Scope: ';

  @override
  String ownerInventoryScopeBody(String branch) {
    return '$branch. Current stock uses branch on-hand quantity when set; otherwise adoption opening qty. Purchase price is the branch/catalog purchase price on each row.';
  }

  @override
  String ownerInventoryScopeBodyShort(String branch) {
    return '$branch. Current stock is branch on-hand when present; otherwise adoption opening qty.';
  }

  @override
  String get ownerInventoryKpiCount => 'KPI count';

  @override
  String get ownerCommonAllBranches => 'All branches';

  @override
  String ownerInventoryPctOfTotal(String pct) {
    return '$pct% of total';
  }

  @override
  String get ownerInventoryValueCalcTitle =>
      'Total inventory value — calculation';

  @override
  String get ownerInventoryTotalExact => 'Total (exact)';

  @override
  String get ownerInventoryKpiRounded => 'KPI display (rounded)';

  @override
  String get ownerInventorySkusInList => 'SKUs in list';

  @override
  String get ownerInventorySkusWithStock => 'SKUs with stock > 0';

  @override
  String get ownerInventorySkusWithValue => 'SKUs with value > 0';

  @override
  String get ownerPurchaseFormTitle => 'New Purchase Invoice';

  @override
  String get ownerPurchaseFormSettingUp => 'Setting up invoice…';

  @override
  String get ownerPurchaseFormSupplierVendor => 'Supplier / Vendor *';

  @override
  String get ownerPurchaseFormBranch => 'Branch *';

  @override
  String get ownerPurchaseFormIssueDate => 'Issue date';

  @override
  String get ownerPurchaseFormDueDate => 'Due date';

  @override
  String get ownerPurchaseFormDays => 'Days';

  @override
  String get ownerPurchaseFormDaysSuffix => 'days';

  @override
  String ownerPurchaseFormDueLabel(String date) {
    return 'Due: $date';
  }

  @override
  String get ownerPurchaseFormRefOptional => 'Ref # (Optional)';

  @override
  String get ownerPurchaseFormVendorInv => 'Vendor inv #';

  @override
  String get ownerPurchaseFormDescOptional => 'Invoice description (optional)';

  @override
  String get ownerPurchaseFormLineItems => 'Line Items';

  @override
  String get ownerPurchaseFormAddLine => 'Add line';

  @override
  String ownerPurchaseFormItemN(String n) {
    return 'Item $n';
  }

  @override
  String get ownerPurchaseFormProduct => 'Product';

  @override
  String get ownerPurchaseFormSearchProduct => 'Search product…';

  @override
  String get ownerPurchaseFormCreate => 'Create Invoice';

  @override
  String get ownerPurchaseFormSaveDraft => 'Save Draft';

  @override
  String get ownerPurchaseFormSelectSupplier => 'Select supplier';

  @override
  String get ownerPurchaseFormSelectBranch => 'Select branch';

  @override
  String get ownerPurchaseFormNoBranches => 'No branches available';

  @override
  String get ownerPurchaseFormAccount => 'Account';

  @override
  String get ownerPurchaseFormDescription => 'Description';

  @override
  String get ownerPurchaseFormDescriptionHint => 'Description…';

  @override
  String get ownerPurchaseFormQty => 'QTY';

  @override
  String get ownerPurchaseFormUom => 'UOM';

  @override
  String get ownerPurchaseFormUnitPriceExVat => 'Unit Price (Ex VAT)';

  @override
  String get ownerPurchaseFormTaxCode => 'Tax Code';

  @override
  String get ownerPurchaseFormTotalExVat => 'Total (Ex VAT)';

  @override
  String get ownerPurchaseFormTax => 'Tax';

  @override
  String get ownerPurchaseFormTotalIncl => 'Total (Incl.)';

  @override
  String ownerPurchaseFormLastFromSupplier(String amount) {
    return 'Last from supplier: $amount';
  }

  @override
  String get ownerPurchaseFormSubtotal => 'Subtotal:';

  @override
  String get ownerPurchaseFormTotalTaxVat => 'Total Tax (VAT):';

  @override
  String get ownerPurchaseFormGrandTotal => 'Grand Total:';

  @override
  String get ownerPurchaseFormInvoiceDiscount => 'Invoice Discount';

  @override
  String ownerPurchaseFormFreight(String currency) {
    return 'Freight ($currency)';
  }

  @override
  String get ownerPurchaseFormNotes => 'Notes';

  @override
  String get ownerPurchaseFormInternalNotes => 'Internal notes';

  @override
  String get ownerPurchaseFormColDescription => 'Column — Description';

  @override
  String get ownerPurchaseFormColDiscount => 'Column — Discount';

  @override
  String get ownerPurchaseFormAmountsTaxInclusive =>
      'Amounts are tax inclusive';

  @override
  String get ownerPurchaseFormUpdateLastPrice =>
      'Update last purchase price for all products on save (master catalog)';

  @override
  String get ownerPurchaseFormSavedDraft => 'Saved as draft';

  @override
  String get ownerPurchaseFormCreated => 'Purchase Invoice Created!';

  @override
  String get ownerPurchaseFormCreateFailed =>
      'Failed to create invoice. Please try again.';

  @override
  String get ownerPurchaseFormDiscountType => 'Discount type';

  @override
  String ownerPurchaseFormFixedAmount(String currency) {
    return 'Fixed ($currency)';
  }

  @override
  String get ownerPurchaseFormPercent => 'Percent (%)';

  @override
  String get ownerPurchaseFormDueType => 'Due type';

  @override
  String get ownerPurchaseFormDueNet => 'Net';

  @override
  String get ownerPurchaseFormDueEom => 'EOM';

  @override
  String get ownerPurchaseFormDueCustom => 'Custom';

  @override
  String get ownerPurchaseFormApCreates => 'Creates ';

  @override
  String get ownerPurchaseFormApLabel => 'Accounts Payable';

  @override
  String get ownerPurchaseFormApAfter =>
      '. After goods received, click \"Update Stock\" in the list.';

  @override
  String ownerPurchaseFormProductPriceMeta(String unit, String price) {
    return '$unit · $price';
  }

  @override
  String get ownerCommissionsEditRule => 'Edit Commission Rule';

  @override
  String get ownerCommissionsNewRuleTitle => 'New Commission Rule';

  @override
  String get ownerCommissionsPriority => 'Priority *';

  @override
  String get ownerCommissionsStatus => 'Status';

  @override
  String get ownerCommissionsService => 'Service *';

  @override
  String get ownerCommissionsCustomService => 'Custom service name (no link)';

  @override
  String get ownerCommissionsServiceNameHint =>
      'Service name (e.g. Oil Change)';

  @override
  String get ownerCommissionsEmployeeRole => 'Employee role';

  @override
  String get ownerCommissionsRoleHint => 'Role';

  @override
  String get ownerCommissionsType => 'Type';

  @override
  String get ownerCommissionsTypePercentage => 'Percentage of total (%)';

  @override
  String ownerCommissionsTypeFixed(String currency) {
    return 'Fixed amount per job ($currency)';
  }

  @override
  String get ownerCommissionsValuePercent => 'Value (%)';

  @override
  String ownerCommissionsValueSar(String currency) {
    return 'Value ($currency)';
  }

  @override
  String get ownerCommissionsNotes => 'Notes';

  @override
  String get ownerCommissionsCreateRule => 'Create Rule';

  @override
  String get ownerCommissionsSaveRule => 'Save Rule';

  @override
  String get ownerAddSupplierTitle => 'Add Supplier to Workshop';

  @override
  String get ownerAddSupplierSearchHint => 'Search all registered suppliers...';

  @override
  String get ownerAddSupplierWorkshopOnly => 'Workshop-only';

  @override
  String ownerAddSupplierAddSelected(String count) {
    return 'Add Selected ($count)';
  }

  @override
  String get ownerAddSupplierPickerHint =>
      'Pick on-platform suppliers below (they can use the supplier portal), or add a workshop-only vendor who has no login.';

  @override
  String get ownerAddSupplierWorkshopOnlyTitle => 'Add workshop-only supplier';

  @override
  String get ownerAddSupplierWorkshopOnlyHint =>
      'This vendor is stored for your workshop only. They are not given a supplier portal account. To link an on-platform supplier that can log in, use the list above and Add Selected.';

  @override
  String get ownerAddSupplierName => 'Name *';

  @override
  String get ownerAddSupplierCompanyHint => 'Company name';

  @override
  String get ownerAddSupplierMobile => 'Mobile';

  @override
  String get ownerAddSupplierVatNumber => 'VAT number';

  @override
  String get ownerAddSupplierAddress => 'Address';

  @override
  String get ownerAddSupplierNotes => 'Notes';

  @override
  String get ownerAddSupplierBack => 'Back';

  @override
  String get ownerAddSupplierAddToWorkshop => 'Add to workshop';

  @override
  String get ownerAddSupplierSelect => 'Select';

  @override
  String get ownerAddSupplierSelected => 'Selected';

  @override
  String get ownerAddSupplierColSupplier => 'SUPPLIER';

  @override
  String get ownerAddSupplierColContact => 'CONTACT';

  @override
  String get ownerAddSupplierColAction => 'ACTION';

  @override
  String get ownerAddSupplierNoMatch => 'No suppliers match your search';

  @override
  String ownerAddSupplierCrValue(String label, String value) {
    return '$label $value';
  }

  @override
  String get ownerNonAffiliatedAddTitle => 'Add Non-Affiliated Supplier';

  @override
  String get ownerNonAffiliatedEditTitle => 'Edit Non-Affiliated Supplier';

  @override
  String get ownerNonAffiliatedSupplierName => 'Supplier name *';

  @override
  String get ownerNonAffiliatedNameHint => 'e.g. Local Trading Co.';

  @override
  String get ownerNonAffiliatedContactPerson => 'Contact person';

  @override
  String get ownerNonAffiliatedPhone => 'Phone';

  @override
  String get ownerNonAffiliatedEmail => 'Email';

  @override
  String get ownerNonAffiliatedVatId => 'VAT ID';

  @override
  String get ownerNonAffiliatedCrNumber => 'CR Number';

  @override
  String get ownerNonAffiliatedAddress => 'Address';

  @override
  String ownerNonAffiliatedOpeningBalanceSar(String currency) {
    return 'Opening balance ($currency)';
  }

  @override
  String get ownerNonAffiliatedAsOfDate => 'As of date';

  @override
  String get ownerNonAffiliatedDateHint => 'DD/MM/YYYY';

  @override
  String get ownerNonAffiliatedAddSupplier => 'Add supplier';

  @override
  String get ownerNonAffiliatedRequired => 'Required';

  @override
  String get ownerNonAffiliatedUpdateFailed =>
      'Update failed. Please try again.';

  @override
  String get ownerNonAffiliatedAddFailed =>
      'Could not add supplier. Please try again.';

  @override
  String ownerNonAffiliatedNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String get ownerRolesCreateTitle => 'Create Workshop Role';

  @override
  String get ownerRolesEditTitle => 'Edit Role';

  @override
  String get ownerRolesFieldPortal => 'PORTAL';

  @override
  String get ownerRolesFieldRoleName => 'ROLE NAME';

  @override
  String get ownerRolesFieldDescription => 'DESCRIPTION';

  @override
  String get ownerRolesFieldBranchAccess => 'BRANCH ACCESS';

  @override
  String get ownerRolesPermissionsTitle => 'Permissions';

  @override
  String ownerRolesSelectedCount(String selected, String total) {
    return '$selected / $total selected';
  }

  @override
  String ownerRolesSectionCount(String selected, String total) {
    return '$selected/$total';
  }

  @override
  String get ownerRolesPickRoleName => '— Pick a role name —';

  @override
  String get ownerRolesTypeCustomName => 'Type a custom name';

  @override
  String get ownerRolesSelectPortal => 'Select portal';

  @override
  String get ownerRolesSelectBranchAccess => 'Select branch access';

  @override
  String get ownerRolesAllBranchesNoRestriction =>
      'All Branches (no restriction)';

  @override
  String get ownerRolesSpecificBranches => 'Specific Branches...';

  @override
  String get ownerRolesCustomName => 'Custom name…';

  @override
  String get ownerRolesDeleteTitle => 'Delete Role';

  @override
  String get ownerRoleNameLockerCollector => 'Locker Collector';

  @override
  String get ownerRoleNameLockerSupervisor => 'Locker Supervisor';

  @override
  String get ownerRoleNameManager => 'Manager';

  @override
  String get ownerRoleNameCashier => 'Cashier';

  @override
  String get ownerRoleNameTechnician => 'Technician';

  @override
  String get ownerRoleNameSupervisor => 'Supervisor';

  @override
  String get ownerRoleNameTeamLeader => 'Team Leader';

  @override
  String get ownerPermActionView => 'view';

  @override
  String get ownerPermActionApprove => 'approve';

  @override
  String get ownerPermActionReject => 'reject';

  @override
  String get ownerPermActionCreate => 'create';

  @override
  String get ownerPermActionEdit => 'edit';

  @override
  String get ownerPermActionDelete => 'delete';

  @override
  String get ownerPermActionAdd => 'add';

  @override
  String get ownerPermActionExport => 'export';

  @override
  String get ownerPermActionIssue => 'issue';

  @override
  String get ownerPermSecControl => 'CONTROL';

  @override
  String get ownerPermSecOperations => 'OPERATIONS';

  @override
  String get ownerPermSecAccounting => 'ACCOUNTING';

  @override
  String get ownerPermDashboard => 'Dashboard';

  @override
  String get ownerPermApprovalsQueue => 'Approvals Queue (Page Access)';

  @override
  String get ownerPermTopUpRequests => 'Top-up requests';

  @override
  String get ownerPermExpenseRequests => 'Expense requests';

  @override
  String get ownerPermSupplierInvoices => 'Supplier invoices';

  @override
  String get ownerPermSalesReturns => 'Sales returns';

  @override
  String get ownerPermEmployees => 'Employees';

  @override
  String get ownerPermBranchPortals => 'Branch Portals';

  @override
  String get ownerPermAccessPermissions => 'Access Permissions';

  @override
  String get ownerPermRolesPermissions => 'Roles & Permissions';

  @override
  String get ownerPermDepartmentsTab => 'Departments tab';

  @override
  String get ownerPermProductsTab => 'Products tab';

  @override
  String get ownerPermServicesTab => 'Services tab';

  @override
  String get ownerPermCategoriesTab => 'Categories tab';

  @override
  String get ownerPermMasterCatalog => 'Master Catalog (Page Access)';

  @override
  String get ownerPermDepartments => 'Departments';

  @override
  String get ownerPermCategories => 'Categories';

  @override
  String get ownerPermProducts => 'Products';

  @override
  String get ownerPermServices => 'Services';

  @override
  String get ownerPermManageInventory => 'Manage Inventory';

  @override
  String get ownerPermPurchaseInvoicesPage => 'Purchase Invoices (Page Access)';

  @override
  String get ownerPermInvoices => 'Invoices';

  @override
  String get ownerPermPriceReport => 'Price Report';

  @override
  String get ownerPermSuppliersList => 'Suppliers list';

  @override
  String get ownerPermPurchaseHistory => 'Purchase history';

  @override
  String get ownerPermFilterAffiliated => 'Filter Affiliated Suppliers';

  @override
  String get ownerPermReports => 'Reports';

  @override
  String get ownerPermOrders => 'Orders';

  @override
  String get ownerPermDailySales => 'Daily Sales';

  @override
  String get ownerPermByTechnician => 'By Technician';

  @override
  String get ownerPermByCustomer => 'By Customer';

  @override
  String get ownerPermByProduct => 'By Product';

  @override
  String get ownerPermByDepartment => 'By Department';

  @override
  String get ownerPermByBranch => 'By Branch';

  @override
  String get ownerPermByCashier => 'By Cashier';

  @override
  String get ownerPermPosMonitoring => 'POS Monitoring';

  @override
  String get ownerPermLockerManagement => 'Locker Management';

  @override
  String get ownerPermMyPettyCash => 'My Petty Cash';

  @override
  String get ownerPermPromoCodes => 'Promo Codes';

  @override
  String get ownerPermCorporate => 'Corporate Management';

  @override
  String get ownerPermCommissionsPage => 'Commissions (Page Access)';

  @override
  String get ownerPermLedger => 'Ledger';

  @override
  String get ownerPermRules => 'Rules';

  @override
  String get ownerPermCoaPage => 'Chart of Accounts (Page Access)';

  @override
  String get ownerPermCoa => 'Chart of Accounts';

  @override
  String get ownerPermTrialBalance => 'Trial Balance';

  @override
  String get ownerPermPnl => 'P&L';

  @override
  String get ownerPermBalanceSheet => 'Balance Sheet';

  @override
  String get ownerPermTransactions => 'Transactions';

  @override
  String get ownerPermJournalEntries => 'Journal Entries';

  @override
  String get ownerPermPurchases => 'Purchases';

  @override
  String get ownerPermExpenses => 'Expenses';

  @override
  String get ownerPermReceipts => 'Receipts';

  @override
  String get ownerPermPayments => 'Payments';

  @override
  String get ownerPermAdvances => 'Advances';

  @override
  String get ownerPermPayrollRun => 'Payroll Run';

  @override
  String get ownerPermApprovalLimits => 'Approval Limits';

  @override
  String get ownerEmpFormAddTitle => 'Add New Employee';

  @override
  String get ownerEmpFormEditTitle => 'Edit Employee';

  @override
  String get ownerEmpFormBasicInfo => 'Basic Information';

  @override
  String get ownerEmpFormFullName => 'Full Name';

  @override
  String get ownerEmpFormMobile => 'Mobile';

  @override
  String get ownerEmpFormEmail => 'Email';

  @override
  String get ownerEmpFormIqama => 'Iqama / CNIC';

  @override
  String get ownerEmpFormBranch => 'Branch';

  @override
  String get ownerEmpFormSelectBranch => 'Select Branch';

  @override
  String get ownerEmpFormNoBranches => 'No branches';

  @override
  String get ownerEmpFormRole => 'Role';

  @override
  String get ownerEmpFormSelectRole => 'Select role';

  @override
  String get ownerEmpFormRoleHint =>
      'Job title — controls which workshop sub-flow they\'re slotted into.';

  @override
  String get ownerEmpFormDepartments => 'Departments';

  @override
  String get ownerEmpFormDepartmentsSuffix =>
      ' (Workshop departments this technician can work in)';

  @override
  String get ownerEmpFormTechSettings => 'Technician Settings';

  @override
  String get ownerEmpFormIsTechnician => 'This employee is a Technician';

  @override
  String get ownerEmpFormTechType => 'Technician Type';

  @override
  String get ownerEmpFormTechTypeHint =>
      'Default for new technicians: both Workshop and On-Call are enabled.';

  @override
  String get ownerEmpFormWorkshop => 'Workshop';

  @override
  String get ownerEmpFormOnCall => 'On-Call';

  @override
  String get ownerEmpFormFinancial => 'Financial';

  @override
  String ownerEmpFormBasicSalary(String currency) {
    return 'Basic Salary ($currency)';
  }

  @override
  String get ownerEmpFormCommissionPct => 'Commission %';

  @override
  String get ownerEmpFormCommissionType => 'Commission Type';

  @override
  String get ownerEmpFormSelectType => 'Select type';

  @override
  String get ownerEmpFormStatus => 'Status';

  @override
  String get ownerEmpFormSelectStatus => 'Select status';

  @override
  String get ownerEmpFormInitialPassword => 'Initial Password';

  @override
  String get ownerEmpFormPasswordHint =>
      'Password (optional — a temporary password is generated if blank)';

  @override
  String get ownerEmpFormPasswordPlaceholder => 'Leave blank to auto-generate';

  @override
  String get ownerEmpFormSave => 'Save';

  @override
  String get ownerEmpFormMobileHint => '05XXXXXXXX';

  @override
  String get ownerEmpRoleStaff => 'Staff';

  @override
  String get ownerEmpCommOfRevenue => '% of Revenue';

  @override
  String get ownerEmpCommOfProfit => '% of Profit';

  @override
  String get ownerEmpCommFixed => 'Fixed Amount';

  @override
  String get ownerEmpCommOfService => '% of Service';

  @override
  String get ownerEmpCommFixedPerOrder => 'Fixed per Order';

  @override
  String get ownerEmpFormNoDepartments =>
      'No departments found. Create one first.';

  @override
  String get ownerEmpMenuResetPassword => 'Reset Password';

  @override
  String get ownerEmpMenuPermissions => 'Permissions';

  @override
  String get ownerEmpResetTitle => 'Reset Password';

  @override
  String get ownerEmpResetNewPassword => 'New Password';

  @override
  String get ownerEmpResetHint => 'Enter new password';

  @override
  String get ownerEmpAssignRoleTitle => 'Assign Role';

  @override
  String get ownerEmpAssignRoleEmpty =>
      'No custom roles available. Create a role first from the Roles tab.';

  @override
  String get ownerEmpColName => 'Name';

  @override
  String get ownerEmpColRole => 'Role';

  @override
  String get ownerEmpColAssignedRole => 'Assigned Role';

  @override
  String get ownerEmpColDepartment => 'Department';

  @override
  String get ownerEmpColBranch => 'Branch';

  @override
  String get ownerEmpColPhone => 'Phone';

  @override
  String get ownerEmpColCommission => 'Commission %';

  @override
  String get ownerEmpColWorkshopDuty => 'Workshop Duty';

  @override
  String get ownerEmpColStatus => 'Status';

  @override
  String get ownerEmpColActions => 'Actions';

  @override
  String get ownerCommonClose => 'Close';

  @override
  String get ownerEmpDutyOff => 'Off';

  @override
  String get techPortalTitle => 'Technician Portal';

  @override
  String get techPortalSubtitle => 'Sign in to your workspace';

  @override
  String get techLoginInvalidCreds => 'Invalid email or password';

  @override
  String get techLoginNoPortalAccess =>
      'This account does not have Technician portal access. Use the correct portal for your role.';

  @override
  String get techLoginSuccess => 'Login Successful';

  @override
  String get techLoginEmailRequired => 'Please enter your email';

  @override
  String get techLoginEmailInvalid => 'Please enter a valid email';

  @override
  String get techLoginPasswordRequired => 'Please enter your password';

  @override
  String get techDashWelcomeBack => 'Welcome Back,';

  @override
  String get techDashPerformance => 'PERFORMANCE';

  @override
  String get techDashDutyMode => 'DUTY MODE';

  @override
  String get techDashOfflineTitle => 'You are currently offline';

  @override
  String get techDashOfflineBody =>
      'The cashier has set your status to offline. Workshop and on-call duties are unavailable until you are marked online again.';

  @override
  String get techDashWorkshopDutyHint => '(In-house)';

  @override
  String get techDashOnCallDutyHint => '(Emergency)';

  @override
  String get techDashDutyHelp =>
      'Turn workshop or on-call duty on for the jobs you want to receive. Only one can be active at a time.';

  @override
  String get techDashRevenueEarned => 'Revenue Earned';

  @override
  String get techDashJobsCompleted => 'Jobs Completed';

  @override
  String get techDashCommissionEarned => 'Commission Earned';

  @override
  String get techDashTodayRevenue => 'Today\'s Revenue';

  @override
  String get techDashViewAssignedOrders => 'VIEW ASSIGNED ORDERS';

  @override
  String get techShellAssignedOrders => 'Assigned Orders';

  @override
  String get techShellSalaries => 'Salaries';

  @override
  String get techShellTechnicianRole => 'Technician';

  @override
  String techVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get techOrdersTitle => 'ASSIGNED ORDERS';

  @override
  String get techOrdersSearchHint => 'Search order ID, plate or customer';

  @override
  String techOrdersShowingMatches(
    String count,
    String currency,
    String amount,
  ) {
    return 'Showing $count match(es) · $currency $amount commission';
  }

  @override
  String techOrdersTotalCommission(
    String count,
    String currency,
    String amount,
  ) {
    return 'Total commission: $currency $amount · $count job(s)';
  }

  @override
  String get techOrdersNoSearchMatch => 'No orders match your search';

  @override
  String get techOrdersNoJobsInRange => 'No invoiced jobs in this range';

  @override
  String get techOrdersSearchHintEmpty =>
      'Try order ID, plate number or customer name';

  @override
  String get techOrdersEmptyHint =>
      'Completed jobs appear here after the cashier generates the invoice';

  @override
  String get techOrdersCommission => 'Commission';

  @override
  String get techOrdersCustomer => 'Customer';

  @override
  String get techOrdersVehicle => 'Vehicle';

  @override
  String get techOrdersDepartment => 'Department';

  @override
  String get techOrdersGeneral => 'General';

  @override
  String get techOrdersOrderValue => 'Order value';

  @override
  String get techOrdersViewDetails => 'View Details';

  @override
  String get techOrderDetailsTitle => 'ORDER DETAILS';

  @override
  String get techOrderDetailsPlateNo => 'Plate No';

  @override
  String get techOrderDetailsServiceType => 'Service Type';

  @override
  String get techOrderDetailsStandardService => 'Standard Service';

  @override
  String get techOrderDetailsCompletedAt => 'Completed At';

  @override
  String get techOrderDetailsServices => 'Services';

  @override
  String get techOrderDetailsProducts => 'Products';

  @override
  String get techOrderDetailsYourCommission => 'YOUR COMMISSION';

  @override
  String get techBroadcastOverlayTitle => 'NEW BROADCAST JOB';

  @override
  String get techBroadcastOverlayOnCall => 'On-call broadcast';

  @override
  String get techBroadcastOverlayWorkshop => 'Workshop broadcast';

  @override
  String get techBroadcastOverlayDecline => 'DECLINE';

  @override
  String get techBroadcastOverlayAccept => 'ACCEPT JOB';

  @override
  String get techBroadcastCouldNotDecline => 'Could not decline';

  @override
  String get techBroadcastCouldNotAccept => 'Could not accept job';

  @override
  String get techBroadcastListTitle => 'Technician broadcasts';

  @override
  String get techBroadcastNoActive => 'No active broadcasts';

  @override
  String techBroadcastCountActive(String count, String window) {
    return '$count active · $window per item';
  }

  @override
  String techBroadcastWindow(String m, String s) {
    return '$m:$s window';
  }

  @override
  String get techBroadcastLabel => 'BROADCAST';

  @override
  String get techBroadcastOnCall => 'On call';

  @override
  String get techBroadcastWorkshop => 'Workshop';

  @override
  String get techBroadcastSoon => 'Soon';

  @override
  String get techBroadcastClosed => 'Closed';

  @override
  String get techBroadcastRemaining => 'remaining';

  @override
  String get techBroadcastExpired => 'Expired';

  @override
  String get techBroadcastReject => 'Reject';

  @override
  String get techBroadcastAccept => 'Accept';

  @override
  String get techCommSearchHint => 'Search order ID or invoice no.';

  @override
  String get techCommNoSearchMatch => 'No commissions match your search';

  @override
  String get techCommNoneFound => 'No commissions found';

  @override
  String get techCommSearchEmptyHint => 'Try order ID or invoice number';

  @override
  String get techCommEmptyHint =>
      'Completed jobs in this date range will appear here';

  @override
  String get techCommTitle => 'COMMISSION';

  @override
  String get techCommCreditedWallet => 'Credited to wallet';

  @override
  String get techSalariesTab => 'Salaries';

  @override
  String get techAdvancesTab => 'Advances';

  @override
  String get techSalariesNoneInRange => 'No salary payments in this range';

  @override
  String get techAdvancesNoneInRange => 'No advance transactions in this range';

  @override
  String get techTryDifferentDateRange => 'Try a different date range';

  @override
  String techBalanceLabel(String currency, String amount) {
    return 'Balance: $currency $amount';
  }

  @override
  String get techSelectedDateRange => 'Selected date range';

  @override
  String get techAdvanceLabel => 'ADVANCE';

  @override
  String get techDeductedLabel => 'DEDUCTED';

  @override
  String techTotalReceived(String currency, String amount) {
    return 'Total received: $currency $amount';
  }

  @override
  String get techSalariesTitle => 'SALARIES';

  @override
  String techPaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get techNetCash => 'Net cash';

  @override
  String get techBasicSalary => 'Basic salary';

  @override
  String get techAdvanceDeduction => 'Advance deduction';

  @override
  String get techPenalties => 'Penalties';

  @override
  String get techGrossPayable => 'Gross payable';

  @override
  String get techTotalDeductions => 'Total deductions';

  @override
  String get techNetPaid => 'Net paid';

  @override
  String techPaidFrom(String name) {
    return 'Paid from: $name';
  }

  @override
  String techMethod(String method) {
    return 'Method: $method';
  }

  @override
  String techPenaltyNote(String note) {
    return 'Penalty note: $note';
  }

  @override
  String techYouAckedSalary(String status) {
    return 'You $status this salary';
  }

  @override
  String get techPerfCommissionTimeline => 'COMMISSION TIMELINE';

  @override
  String get techPerfRecentJobs => 'RECENT JOBS';

  @override
  String get techPerfDailyPerformance => 'DAILY PERFORMANCE';

  @override
  String get techPerfTotalJobs => 'TOTAL JOBS';

  @override
  String get techPerfTotalCommission => 'TOTAL COMMISSION';

  @override
  String get techPerfDailyCommission => 'Daily commission';

  @override
  String get techPerfNoCommissionMonth => 'No commission data for this month';

  @override
  String get techPerfNoRecentJobs => 'No recent jobs found';

  @override
  String get techPerfSeeAll => 'See All';

  @override
  String get techRecentJobsTitle => 'RECENT JOBS';

  @override
  String get techNotificationsTitle => 'NOTIFICATIONS';

  @override
  String get techNotificationsEmptyTitle => 'No New Alerts';

  @override
  String get techNotificationsEmptyBody => 'You are all caught up!';

  @override
  String get techProfileTitle => 'MY PROFILE';

  @override
  String get techProfileBasicInfo => 'Basic Information';

  @override
  String get techProfileEmail => 'Email';

  @override
  String get techProfileMobile => 'Mobile';

  @override
  String get techProfileDutyDetails => 'Duty Details';

  @override
  String get techProfileType => 'Type';

  @override
  String get techProfileDutyMode => 'Duty Mode';

  @override
  String get techProfileCommission => 'Commission';

  @override
  String get techProfileAssociations => 'Associations';

  @override
  String get techProfileWorkshop => 'Workshop';

  @override
  String get techProfileBranch => 'Branch';

  @override
  String get techProfileDepartments => 'Departments';

  @override
  String get techProfileNA => 'N/A';

  @override
  String get techProfileTechnicianName => 'Technician Name';

  @override
  String techProfileRoleId(String id) {
    return 'Technician • ID: $id';
  }

  @override
  String get techProfileStandard => 'STANDARD';

  @override
  String techProfileFooter(String version) {
    return 'Technician Portal • Version $version';
  }

  @override
  String get techChatTitle => 'CHAT';

  @override
  String get techChatMyChats => 'My Chats';

  @override
  String get techChatMembers => 'Members';

  @override
  String get techChatSearchChats => 'Search chats';

  @override
  String get techChatSearchMembers => 'Search members';

  @override
  String get techChatNoChatsYet => 'No chats yet';

  @override
  String get techChatNoChatsHint =>
      'Start a conversation from Members,\nthen it will appear here';

  @override
  String get techChatNoMembers => 'No members found';

  @override
  String get techChatTryDifferentSearch => 'Try a different search';

  @override
  String get techChatStartConversation => 'Start a conversation';

  @override
  String get techChatGroup => 'Group';

  @override
  String get techChatWorkshopTeam => 'Workshop team';

  @override
  String get techChatTypeMessage => 'Type a message';

  @override
  String get techChatNewGroup => 'New group';

  @override
  String get techChatGroupName => 'Group name';

  @override
  String get techChatSearchMembersToAdd => 'Search members to add';

  @override
  String get techChatCreating => 'Creating…';

  @override
  String get techChatCreateGroup => 'Create group';

  @override
  String get techChatGroupNameRequired => 'Group name is required';

  @override
  String get techChatSelectMember => 'Select at least one member';

  @override
  String get techChatTyping => 'typing…';

  @override
  String get techMonthTitle => 'MONTH';

  @override
  String get techMonthApply => 'Apply';

  @override
  String get techMonthJan => 'Jan';

  @override
  String get techMonthFeb => 'Feb';

  @override
  String get techMonthMar => 'Mar';

  @override
  String get techMonthApr => 'Apr';

  @override
  String get techMonthMay => 'May';

  @override
  String get techMonthJun => 'Jun';

  @override
  String get techMonthJul => 'Jul';

  @override
  String get techMonthAug => 'Aug';

  @override
  String get techMonthSep => 'Sep';

  @override
  String get techMonthOct => 'Oct';

  @override
  String get techMonthNov => 'Nov';

  @override
  String get techMonthDec => 'Dec';

  @override
  String get techOfflineAskCashier =>
      'You are offline. Ask the cashier to mark you online.';

  @override
  String get techNotSignedIn => 'Not signed in';

  @override
  String get techCouldNotSubmitResponse => 'Could not submit response';

  @override
  String get techJobAccepted => 'Job accepted';

  @override
  String get techBroadcastDeclined => 'Broadcast declined';

  @override
  String get techNotifCommissionCredited => 'Commission Credited';

  @override
  String techNotifCommissionCreditedBody(
    String currency,
    String amount,
    String orderId,
  ) {
    return '$currency $amount added to your daily earnings for $orderId';
  }

  @override
  String get techAckAccepted => 'accepted';

  @override
  String get techAckRejected => 'rejected';

  @override
  String techMoneyAmount(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get lockerNavDashboard => 'Dashboard';

  @override
  String get lockerNavPendingRequests => 'Pending Requests';

  @override
  String get lockerNavRecordCollection => 'Record Collection';

  @override
  String get lockerNavApprovals => 'Approvals';

  @override
  String get lockerNavDepositToBank => 'Deposit to Bank';

  @override
  String get lockerNavIssuePettyCash => 'Issue Petty Cash';

  @override
  String get lockerNavPettyCashIssueLog => 'Petty Cash Issue Log';

  @override
  String get lockerNavExpenses => 'Expenses';

  @override
  String get lockerNavCollectionsHistory => 'Collections History';

  @override
  String get lockerNavCollectionHistory => 'Collection History';

  @override
  String get lockerNavDifferencesReport => 'Differences Report';

  @override
  String get lockerNavAssignedRequests => 'Assigned Requests';

  @override
  String get lockerNavDifferencesHistory => 'Differences History';

  @override
  String get lockerFooterPortal => 'Locker Portal';

  @override
  String lockerComingSoon(String feature) {
    return '$feature — coming soon';
  }

  @override
  String get lockerQuickActions => 'Quick Actions';

  @override
  String get lockerRecentCollections => 'Recent Collections';

  @override
  String get lockerViewAll => 'View All';

  @override
  String get lockerNoRecentCollections => 'No recent collections';

  @override
  String get lockerLabelRequested => 'REQUESTED';

  @override
  String get lockerLabelExpected => 'EXPECTED';

  @override
  String get lockerLabelReceived => 'RECEIVED';

  @override
  String get lockerLabelDifference => 'DIFFERENCE';

  @override
  String get lockerLabelRequest => 'REQUEST';

  @override
  String get lockerSelectRequest => 'Select request…';

  @override
  String get lockerLabelBranch => 'BRANCH';

  @override
  String get lockerLabelCashier => 'CASHIER';

  @override
  String get lockerLabelOfficer => 'OFFICER';

  @override
  String get lockerLabelCounterClosing => 'COUNTER CLOSING';

  @override
  String get lockerCashHelper =>
      'Enter the cash amount actually received from the cashier.';

  @override
  String get lockerLabelCash => 'CASH';

  @override
  String get lockerPayBank => 'Bank';

  @override
  String get lockerPayTabby => 'Tabby';

  @override
  String get lockerPayTamara => 'Tamara';

  @override
  String get lockerPayCorporate => 'Corporate';

  @override
  String get lockerTapToAddPhoto => 'Tap to add photo';

  @override
  String get lockerCameraOrGallery => 'Camera or Gallery';

  @override
  String get lockerRetakeChange => 'Retake / Change';

  @override
  String get lockerAddPhoto => 'ADD PHOTO';

  @override
  String get lockerTakePhoto => 'Take Photo';

  @override
  String get lockerOpenCamera => 'Open camera';

  @override
  String get lockerChooseGallery => 'Choose from Gallery';

  @override
  String get lockerPickExistingPhoto => 'Pick an existing photo';

  @override
  String get lockerTabVariance => 'Variance';

  @override
  String get lockerTabPettyCashFunds => 'Petty Cash Funds';

  @override
  String get lockerNoPendingFundRequests => 'No pending fund requests';

  @override
  String get lockerFundApproved => 'Fund request approved';

  @override
  String get lockerFundRejected => 'Fund request rejected';

  @override
  String get lockerRejectFundRequest => 'Reject Fund Request';

  @override
  String get lockerProvideRejectionReason =>
      'Please provide a reason for rejection.';

  @override
  String get lockerRejectionReason => 'Rejection reason';

  @override
  String get lockerReasonRequired => 'Reason is required';

  @override
  String get lockerFallbackCashier => 'Cashier';

  @override
  String get lockerTitleCollectionsHistory => 'Collections History';

  @override
  String get lockerKpiTotalExpected => 'TOTAL EXPECTED';

  @override
  String get lockerKpiTotalReceived => 'TOTAL RECEIVED';

  @override
  String get lockerKpiNetDifference => 'NET DIFFERENCE';

  @override
  String get lockerClearAll => 'Clear all';

  @override
  String get lockerFilterAll => 'All';

  @override
  String get lockerSortExpectedAmount => 'Expected Amount';

  @override
  String get lockerStatusPending => 'Pending';

  @override
  String get lockerTitleMyPending => 'My Pending Requests';

  @override
  String get lockerTitleMyCollections => 'My Collections';

  @override
  String get lockerTitleAllCollections => 'All Collections';

  @override
  String get lockerTitleAssignOfficers => 'Assign Officers';

  @override
  String get lockerTitlePendingRequests => 'Pending Requests';

  @override
  String get lockerTitleRequests => 'Requests';

  @override
  String lockerMinSar(String currency) {
    return 'MIN ($currency)';
  }

  @override
  String lockerMaxSar(String currency) {
    return 'MAX ($currency)';
  }

  @override
  String get lockerAny => 'Any';

  @override
  String get lockerTotalExpectedFiltered => 'TOTAL EXPECTED (FILTERED)';

  @override
  String get lockerApproveAndForward => 'Approve & forward';

  @override
  String get lockerApproveAndRecord => 'Approve & record';

  @override
  String get lockerFilterPending => 'PENDING';

  @override
  String get lockerFilterAssigned => 'ASSIGNED';

  @override
  String get lockerFilterCollected => 'COLLECTED';

  @override
  String get lockerFilterCompleted => 'COMPLETED';

  @override
  String get lockerTodaysCollected => 'Today\'s Collected';

  @override
  String lockerOverdueCount(String count) {
    return '$count overdue';
  }

  @override
  String get lockerCollectionsToday => 'collections today';

  @override
  String get lockerThisMonthApproved => 'This month (approved)';

  @override
  String get lockerQaPendingRequests => 'Pending Requests';

  @override
  String get lockerQaPendingRequestsSub =>
      'Review and assign cashiers\' closing requests';

  @override
  String get lockerQaRecordCollection => 'Record Collection';

  @override
  String get lockerQaRecordCollectionSub => 'Collect cash and record amounts';

  @override
  String get lockerQaApprovals => 'Approvals';

  @override
  String get lockerQaApprovalsSub => 'Approve variance and fund requests';

  @override
  String get lockerQaCollectionHistory => 'Collection History';

  @override
  String get lockerQaCollectionHistorySub => 'View past collections';

  @override
  String get lockerQaDepositBank => 'Deposit to Bank';

  @override
  String get lockerQaDepositBankSub => 'Transfer vault cash to bank';

  @override
  String get lockerQaIssuePettyCash => 'Issue Petty Cash';

  @override
  String get lockerQaIssuePettyCashSub => 'Issue float to cashiers';

  @override
  String get lockerQaExpenses => 'Expenses';

  @override
  String get lockerQaExpensesSub => 'Record locker expenses';

  @override
  String get lockerQaDifferencesReport => 'Differences Report';

  @override
  String get lockerQaDifferencesReportSub => 'Shorts and overs overview';

  @override
  String get lockerQaAssignedRequests => 'Assigned Requests';

  @override
  String get lockerQaAssignedRequestsSub => 'Requests assigned to you';

  @override
  String get lockerQaDifferencesHistory => 'Differences History';

  @override
  String get lockerQaDifferencesHistorySub => 'Your variance history';

  @override
  String get lockerPettyIssueTitle => 'Issue Petty Cash';

  @override
  String get lockerVaultBalance => 'Locker Vault Balance';

  @override
  String get lockerIssueFloat => 'Issue Float';

  @override
  String get lockerFailedToLoad => 'Failed to load';

  @override
  String get lockerAnUnexpectedError => 'An unexpected error occurred.';

  @override
  String get lockerNoFloatsYet => 'No floats issued yet';

  @override
  String get lockerNoDescription => 'No description';

  @override
  String lockerAmountLabel(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get lockerIssueDate => 'Issue Date';

  @override
  String get lockerReferenceOptional => 'Reference (optional)';

  @override
  String get lockerWeeklyFloatHint => 'Weekly float / top-up note';

  @override
  String get lockerSelectCashier => 'Select cashier...';

  @override
  String get lockerRequired => 'Required';

  @override
  String get lockerInvalidAmount => 'Invalid amount';

  @override
  String get lockerExceedsVault => 'Exceeds vault balance';

  @override
  String get lockerPleaseSelectCashier => 'Please select a cashier';

  @override
  String get lockerIssueAndPostGl => 'Issue & Post GL';

  @override
  String get lockerRecentFloatsIssued => 'Recent petty cash floats issued';

  @override
  String get lockerFloatIssuedSuccess => 'Float issued successfully';

  @override
  String get lockerPettyCashFloatDefault => 'Petty cash float';

  @override
  String get lockerPettyIssueLogTitle => 'Petty Cash Issue Log';

  @override
  String get lockerKpiLockerVault => 'LOCKER VAULT';

  @override
  String get lockerKpiTotalIssued => 'TOTAL ISSUED';

  @override
  String get lockerKpiIssueCount => 'ISSUE COUNT';

  @override
  String get lockerKpiAverageIssue => 'AVERAGE ISSUE';

  @override
  String get lockerNoPettyIssues => 'No petty cash issues in this range';

  @override
  String get lockerAllBranches => 'All branches';

  @override
  String get lockerAllCashiers => 'All cashiers';

  @override
  String get lockerIssuedFloats => 'ISSUED FLOATS';

  @override
  String lockerRecordCount(String count) {
    return '$count record(s)';
  }

  @override
  String get lockerDateLabel => 'DATE';

  @override
  String get lockerReferenceLabel => 'REFERENCE';

  @override
  String get lockerJeLabel => 'JE';

  @override
  String get lockerPettyCashTitle => 'Petty Cash';

  @override
  String get lockerNewRequest => 'New Request';

  @override
  String get lockerNoPettyRequestsYet => 'No petty cash requests yet.';

  @override
  String get lockerPurpose => 'Purpose';

  @override
  String get lockerDate => 'Date';

  @override
  String get lockerSubmitRequest => 'Submit request';

  @override
  String get lockerEnterValidAmount => 'Enter a valid amount';

  @override
  String get lockerDepositTitle => 'DEPOSIT TO BANK';

  @override
  String get lockerSlowConnection => 'Slow connection — still working…';

  @override
  String get lockerNoBankRegisters => 'No bank registers configured';

  @override
  String get lockerDepositAndPostGl => 'Deposit & Post GL';

  @override
  String get lockerRecentBankDeposits => 'Recent locker → bank deposits';

  @override
  String get lockerNoDepositsYet => 'No deposits yet';

  @override
  String get lockerBankDeposit => 'Bank deposit';

  @override
  String get lockerFailedToLoadTitle => 'Failed to Load';

  @override
  String get lockerCashInTransit => 'Cash in Transit — Locker';

  @override
  String get lockerAmountMustBePositive => 'Amount must be greater than 0';

  @override
  String get lockerAmountExceedsVault => 'Amount exceeds vault balance';

  @override
  String lockerDepositPostedSuccess(String journalId) {
    return 'Deposit posted successfully. GL entry recorded (Journal #$journalId).';
  }

  @override
  String get lockerExpensesTitle => 'Expenses';

  @override
  String get lockerExpensesSubmitted => 'Expenses submitted for approval';

  @override
  String get lockerViewProof => 'View proof';

  @override
  String get lockerAddLine => 'Add line';

  @override
  String lockerSubmitLines(String count) {
    return 'Submit $count line(s)';
  }

  @override
  String get lockerSubmitting => 'Submitting…';

  @override
  String get lockerVaultBalanceDialog => 'Vault balance';

  @override
  String get lockerExceedVaultBody =>
      'Total exceeds vault balance. Submit anyway?';

  @override
  String get lockerSubmitAnyway => 'Submit anyway';

  @override
  String lockerLineSelectBranch(String n) {
    return 'Line $n: select a branch';
  }

  @override
  String lockerLineSelectCategory(String n) {
    return 'Line $n: select a category';
  }

  @override
  String lockerLineEnterAmount(String n) {
    return 'Line $n: enter a valid amount';
  }

  @override
  String get lockerDifferencesTitle => 'Differences Report';

  @override
  String get lockerChipAll => 'All';

  @override
  String get lockerChipShort => 'Short';

  @override
  String get lockerChipOver => 'Over';

  @override
  String get lockerChipPending => 'Pending';

  @override
  String get lockerPendingApproval => 'Pending Approval';

  @override
  String get lockerNoDifferences => 'No differences found';

  @override
  String get lockerLoginFailed => 'Login failed. Please try again.';

  @override
  String get lockerLoginNoAccess =>
      'This account does not have locker portal access. Ask your workshop admin to create a locker user.';

  @override
  String get lockerLoginUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get lockerNoRequestSelected => 'No request selected.';

  @override
  String get lockerFailedLoadRequests => 'Failed to load requests.';

  @override
  String get lockerFailedLoadRequestDetails =>
      'Failed to load request details.';

  @override
  String get lockerCouldNotLoadOfficers => 'Could not load officers.';

  @override
  String get lockerAssignmentFailed => 'Assignment failed.';

  @override
  String get lockerNotAuthenticated => 'Not authenticated.';

  @override
  String get lockerOperationFailed => 'Operation failed.';

  @override
  String lockerBadRequest(String detail) {
    return 'Bad request: $detail';
  }

  @override
  String get lockerFailedLoadSession => 'Failed to load session.';

  @override
  String get lockerFailedLoadData => 'Failed to load data.';

  @override
  String get lockerFailedIssueFloat => 'Failed to issue float.';

  @override
  String get lockerAttachPhotoHint =>
      'Attach a photo as proof of collection (optional).';

  @override
  String get lockerCashCollected => 'Cash collected';

  @override
  String get lockerOverMinusShort => 'Over − Short';

  @override
  String get lockerNetShort => 'Net Short';

  @override
  String get lockerNetOver => 'Net Over';

  @override
  String get lockerBalanced => 'Balanced';

  @override
  String get lockerCashShortage => 'Cash shortage';

  @override
  String get lockerCashSurplus => 'Cash surplus';

  @override
  String get lockerVarianceRecords => 'VARIANCE RECORDS';

  @override
  String lockerRecordsOfTotal(String visible, String total) {
    return '$visible of $total records';
  }

  @override
  String lockerRequestsInRange(String count) {
    return '$count request(s) in range';
  }

  @override
  String get lockerBankRegister => 'Bank Register';

  @override
  String get lockerSelectBankRegister => 'Select bank register…';

  @override
  String get lockerBankSlipHint => 'Bank slip / transfer reference (optional)';

  @override
  String get lockerKpiBankRegisters => 'Bank Registers';

  @override
  String get lockerKpiRecentDeposits => 'Recent Deposits';

  @override
  String get lockerTabRecordExpenses => 'Record expenses';

  @override
  String get lockerTabExpensesLog => 'Expenses log';

  @override
  String get lockerPostedExpenses => 'POSTED EXPENSES';

  @override
  String get lockerPostedCount => 'POSTED COUNT';

  @override
  String get lockerExpenseLines => 'Expense lines';

  @override
  String lockerLineN(String n) {
    return 'Line $n';
  }

  @override
  String get lockerCategoryLabel => 'CATEGORY';

  @override
  String get lockerProofUrlOptional => 'PROOF URL (OPTIONAL)';

  @override
  String get lockerStatusPosted => 'Posted';

  @override
  String get lockerSelectCategory => 'Select category';

  @override
  String get lockerSelectedPeriod => 'Selected period';

  @override
  String get lockerAcrossBranches => 'Across branches';

  @override
  String get lockerPerIssue => 'Per issue';

  @override
  String get lockerRequestDetailsTitle => 'REQUEST DETAILS';

  @override
  String get lockerSampleOfficeSupplies => 'Office supplies';

  @override
  String get lockerSampleBranchMainRiyadh => 'Main — Riyadh';

  @override
  String get lockerFallbackUser => 'User';

  @override
  String get lockerStatusUnknown => 'Unknown';

  @override
  String get lockerPosStatusOpen => 'OPEN';

  @override
  String get lockerPosStatusClosed => 'CLOSED';

  @override
  String get lockerTryAgainGeneric => 'Something went wrong. Please try again.';

  @override
  String get ownerDashboardTotalSales => 'Total Sales';

  @override
  String get ownerDashboardTotalSalesSubtitle =>
      'Selected period · all branches';
}
