import '../l10n/app_localizations.dart';

/// Localize known workshop role slugs / display names.
String ownerLocalizeRoleName(AppLocalizations l10n, String name) {
  switch (name.trim().toLowerCase().replaceAll(' ', '_')) {
    case 'locker_collector':
    case 'lockercollector':
      return l10n.ownerRoleNameLockerCollector;
    case 'locker_supervisor':
    case 'lockersupervisor':
      return l10n.ownerRoleNameLockerSupervisor;
    case 'manager':
      return l10n.ownerRoleNameManager;
    case 'cashier':
      return l10n.ownerRoleNameCashier;
    case 'technician':
      return l10n.ownerRoleNameTechnician;
    case 'supervisor':
      return l10n.ownerRoleNameSupervisor;
    case 'team_leader':
    case 'teamleader':
      return l10n.ownerRoleNameTeamLeader;
    case 'staff':
      return l10n.ownerEmpRoleStaff;
    default:
      return name;
  }
}

/// Localize permission action chips (view / approve / …).
String ownerLocalizePermAction(AppLocalizations l10n, String action) {
  switch (action.trim().toLowerCase()) {
    case 'view':
      return l10n.ownerPermActionView;
    case 'approve':
      return l10n.ownerPermActionApprove;
    case 'reject':
      return l10n.ownerPermActionReject;
    case 'create':
      return l10n.ownerPermActionCreate;
    case 'edit':
      return l10n.ownerPermActionEdit;
    case 'delete':
      return l10n.ownerPermActionDelete;
    case 'add':
      return l10n.ownerPermActionAdd;
    case 'export':
      return l10n.ownerPermActionExport;
    case 'issue':
      return l10n.ownerPermActionIssue;
    default:
      return action;
  }
}

/// Localize permission section titles and node labels (English UI catalog).
String ownerLocalizePermLabel(AppLocalizations l10n, String label) {
  switch (label.trim()) {
    case 'CONTROL':
      return l10n.ownerPermSecControl;
    case 'OPERATIONS':
      return l10n.ownerPermSecOperations;
    case 'ACCOUNTING':
      return l10n.ownerPermSecAccounting;
    case 'Dashboard':
      return l10n.ownerPermDashboard;
    case 'Approvals Queue (Page Access)':
      return l10n.ownerPermApprovalsQueue;
    case 'Top-up requests':
      return l10n.ownerPermTopUpRequests;
    case 'Expense requests':
      return l10n.ownerPermExpenseRequests;
    case 'Supplier invoices':
      return l10n.ownerPermSupplierInvoices;
    case 'Sales returns':
    case 'Sales Returns':
      return l10n.ownerPermSalesReturns;
    case 'Employees':
      return l10n.ownerPermEmployees;
    case 'Branch Portals':
      return l10n.ownerPermBranchPortals;
    case 'Access Permissions':
      return l10n.ownerPermAccessPermissions;
    case 'Roles & Permissions':
      return l10n.ownerPermRolesPermissions;
    case 'Departments tab':
      return l10n.ownerPermDepartmentsTab;
    case 'Products tab':
      return l10n.ownerPermProductsTab;
    case 'Services tab':
      return l10n.ownerPermServicesTab;
    case 'Categories tab':
      return l10n.ownerPermCategoriesTab;
    case 'Master Catalog (Page Access)':
      return l10n.ownerPermMasterCatalog;
    case 'Departments':
      return l10n.ownerPermDepartments;
    case 'Categories':
      return l10n.ownerPermCategories;
    case 'Products':
      return l10n.ownerPermProducts;
    case 'Services':
      return l10n.ownerPermServices;
    case 'Manage Inventory':
      return l10n.ownerPermManageInventory;
    case 'Purchase Invoices (Page Access)':
      return l10n.ownerPermPurchaseInvoicesPage;
    case 'Invoices':
      return l10n.ownerPermInvoices;
    case 'Price Report':
      return l10n.ownerPermPriceReport;
    case 'Suppliers list':
      return l10n.ownerPermSuppliersList;
    case 'Purchase history':
      return l10n.ownerPermPurchaseHistory;
    case 'Filter Affiliated Suppliers':
      return l10n.ownerPermFilterAffiliated;
    case 'Reports':
      return l10n.ownerPermReports;
    case 'Orders':
      return l10n.ownerPermOrders;
    case 'Daily Sales':
      return l10n.ownerPermDailySales;
    case 'By Technician':
      return l10n.ownerPermByTechnician;
    case 'By Customer':
      return l10n.ownerPermByCustomer;
    case 'By Product':
      return l10n.ownerPermByProduct;
    case 'By Department':
      return l10n.ownerPermByDepartment;
    case 'By Branch':
      return l10n.ownerPermByBranch;
    case 'By Cashier':
      return l10n.ownerPermByCashier;
    case 'POS Monitoring':
      return l10n.ownerPermPosMonitoring;
    case 'Locker Management':
      return l10n.ownerPermLockerManagement;
    case 'My Petty Cash':
      return l10n.ownerPermMyPettyCash;
    case 'Promo Codes':
      return l10n.ownerPermPromoCodes;
    case 'Corporate Management':
      return l10n.ownerPermCorporate;
    case 'Commissions (Page Access)':
      return l10n.ownerPermCommissionsPage;
    case 'Ledger':
      return l10n.ownerPermLedger;
    case 'Rules':
      return l10n.ownerPermRules;
    case 'Chart of Accounts (Page Access)':
      return l10n.ownerPermCoaPage;
    case 'Chart of Accounts':
      return l10n.ownerPermCoa;
    case 'Trial Balance':
      return l10n.ownerPermTrialBalance;
    case 'P&L':
      return l10n.ownerPermPnl;
    case 'Balance Sheet':
      return l10n.ownerPermBalanceSheet;
    case 'Transactions':
      return l10n.ownerPermTransactions;
    case 'Journal Entries':
      return l10n.ownerPermJournalEntries;
    case 'Purchases':
      return l10n.ownerPermPurchases;
    case 'Expenses':
      return l10n.ownerPermExpenses;
    case 'Receipts':
      return l10n.ownerPermReceipts;
    case 'Payments':
      return l10n.ownerPermPayments;
    case 'Advances':
      return l10n.ownerPermAdvances;
    case 'Payroll Run':
      return l10n.ownerPermPayrollRun;
    case 'Approval Limits':
      return l10n.ownerPermApprovalLimits;
    default:
      return label;
  }
}
