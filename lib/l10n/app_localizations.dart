import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @menuAllApps.
  ///
  /// In en, this message translates to:
  /// **'ALL Apps'**
  String get menuAllApps;

  /// No description provided for @menuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please choose one of these apps'**
  String get menuSubtitle;

  /// No description provided for @menuSuperAdminPortal.
  ///
  /// In en, this message translates to:
  /// **'Super Admin\nPortal'**
  String get menuSuperAdminPortal;

  /// No description provided for @menuWorkshopOwner.
  ///
  /// In en, this message translates to:
  /// **'Workshop\nOwner'**
  String get menuWorkshopOwner;

  /// No description provided for @menuTechnicianApp.
  ///
  /// In en, this message translates to:
  /// **'Technician\nApp'**
  String get menuTechnicianApp;

  /// No description provided for @menuWorkshopPosApp.
  ///
  /// In en, this message translates to:
  /// **'Workshop\nPOS App'**
  String get menuWorkshopPosApp;

  /// No description provided for @menuWorkshopPosAppPlain.
  ///
  /// In en, this message translates to:
  /// **'Workshop POS App'**
  String get menuWorkshopPosAppPlain;

  /// No description provided for @menuLockerPortal.
  ///
  /// In en, this message translates to:
  /// **'Locker\nPortal'**
  String get menuLockerPortal;

  /// No description provided for @menuSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get menuSupplier;

  /// No description provided for @menuNoPortalsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No apps are available at the moment.'**
  String get menuNoPortalsAvailable;

  /// No description provided for @menuLoadingApps.
  ///
  /// In en, this message translates to:
  /// **'Loading apps…'**
  String get menuLoadingApps;

  /// No description provided for @menuPortalComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This portal is not available in the app yet.'**
  String get menuPortalComingSoon;

  /// No description provided for @menuVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: 1.0.1'**
  String get menuVersion;

  /// No description provided for @ownerShellHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get ownerShellHome;

  /// No description provided for @ownerShellBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get ownerShellBranches;

  /// No description provided for @ownerShellDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get ownerShellDepartments;

  /// No description provided for @ownerShellEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get ownerShellEmployees;

  /// No description provided for @ownerShellCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get ownerShellCorporate;

  /// No description provided for @ownerShellInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get ownerShellInventory;

  /// No description provided for @ownerShellPosMonitoring.
  ///
  /// In en, this message translates to:
  /// **'POS Monitoring'**
  String get ownerShellPosMonitoring;

  /// No description provided for @ownerShellSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get ownerShellSuppliers;

  /// No description provided for @ownerShellAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get ownerShellAccounting;

  /// No description provided for @ownerShellPromoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo Codes'**
  String get ownerShellPromoCodes;

  /// No description provided for @ownerShellApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get ownerShellApprovals;

  /// No description provided for @ownerShellNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get ownerShellNotifications;

  /// No description provided for @ownerShellLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get ownerShellLogout;

  /// No description provided for @ownerShellRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Workshop Owner'**
  String get ownerShellRoleLabel;

  /// No description provided for @ownerShellVersion.
  ///
  /// In en, this message translates to:
  /// **'v1.0.1 • Workshop OS'**
  String get ownerShellVersion;

  /// No description provided for @ownerShellLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get ownerShellLogoutTitle;

  /// No description provided for @ownerShellLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get ownerShellLogoutBody;

  /// No description provided for @ownerShellLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerShellLogoutCancel;

  /// No description provided for @ownerShellLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get ownerShellLogoutConfirm;

  /// No description provided for @ownerShellDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get ownerShellDashboard;

  /// No description provided for @ownerShellMasterCatalog.
  ///
  /// In en, this message translates to:
  /// **'Master Catalog'**
  String get ownerShellMasterCatalog;

  /// No description provided for @ownerShellManageInventory.
  ///
  /// In en, this message translates to:
  /// **'Manage Inventory'**
  String get ownerShellManageInventory;

  /// No description provided for @ownerShellPurchaseInvoices.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoices'**
  String get ownerShellPurchaseInvoices;

  /// No description provided for @ownerShellApprovalsQueue.
  ///
  /// In en, this message translates to:
  /// **'Approvals Queue'**
  String get ownerShellApprovalsQueue;

  /// No description provided for @ownerShellSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales Returns'**
  String get ownerShellSalesReturns;

  /// No description provided for @ownerShellChartOfAccountPnL.
  ///
  /// In en, this message translates to:
  /// **'Chart of Account (P&L)'**
  String get ownerShellChartOfAccountPnL;

  /// No description provided for @ownerShellChartOfAccountExpense.
  ///
  /// In en, this message translates to:
  /// **'Chart of Account (Expense)'**
  String get ownerShellChartOfAccountExpense;

  /// No description provided for @ownerShellCommissions.
  ///
  /// In en, this message translates to:
  /// **'Commissions'**
  String get ownerShellCommissions;

  /// No description provided for @ownerShellDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get ownerShellDiscounts;

  /// No description provided for @ownerShellSuppliersPurchases.
  ///
  /// In en, this message translates to:
  /// **'Suppliers & Purchases'**
  String get ownerShellSuppliersPurchases;

  /// No description provided for @ownerShellFilterAffiliatedSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Filter Affiliated Suppliers'**
  String get ownerShellFilterAffiliatedSuppliers;

  /// No description provided for @ownerShellNonAffiliatedSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Non-Affiliated Suppliers'**
  String get ownerShellNonAffiliatedSuppliers;

  /// No description provided for @ownerShellLockerManagement.
  ///
  /// In en, this message translates to:
  /// **'Locker Management'**
  String get ownerShellLockerManagement;

  /// No description provided for @ownerShellMyPettyCash.
  ///
  /// In en, this message translates to:
  /// **'My Petty Cash'**
  String get ownerShellMyPettyCash;

  /// No description provided for @ownerShellCorporateManagement.
  ///
  /// In en, this message translates to:
  /// **'Corporate Management'**
  String get ownerShellCorporateManagement;

  /// No description provided for @ownerShellChartOfAccounts.
  ///
  /// In en, this message translates to:
  /// **'Chart of Accounts'**
  String get ownerShellChartOfAccounts;

  /// No description provided for @ownerShellCashBank.
  ///
  /// In en, this message translates to:
  /// **'Cash & Bank'**
  String get ownerShellCashBank;

  /// No description provided for @ownerShellTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get ownerShellTransactions;

  /// No description provided for @ownerShellJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'Journal Entries'**
  String get ownerShellJournalEntries;

  /// No description provided for @ownerShellExpenseEntries.
  ///
  /// In en, this message translates to:
  /// **'Expense Entries'**
  String get ownerShellExpenseEntries;

  /// No description provided for @ownerShellReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get ownerShellReceipts;

  /// No description provided for @ownerShellPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get ownerShellPayments;

  /// No description provided for @ownerShellAdvances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get ownerShellAdvances;

  /// No description provided for @ownerShellPayrollRun.
  ///
  /// In en, this message translates to:
  /// **'Payroll Run'**
  String get ownerShellPayrollRun;

  /// No description provided for @ownerShellApprovalLimits.
  ///
  /// In en, this message translates to:
  /// **'Approval Limits'**
  String get ownerShellApprovalLimits;

  /// No description provided for @ownerShellLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ownerShellLedger;

  /// No description provided for @ownerShellBranchesAccess.
  ///
  /// In en, this message translates to:
  /// **'Branches & Access'**
  String get ownerShellBranchesAccess;

  /// No description provided for @ownerBottomDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get ownerBottomDepartments;

  /// No description provided for @lockerDefaultUser.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get lockerDefaultUser;

  /// No description provided for @billingDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing Dashboard'**
  String get billingDashboardTitle;

  /// No description provided for @billingGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Bills'**
  String get billingGenerateTitle;

  /// No description provided for @billingMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Bills'**
  String get billingMonthlyTitle;

  /// No description provided for @billingOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue Payments'**
  String get billingOverdueTitle;

  /// No description provided for @billingDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingDefaultTitle;

  /// No description provided for @billingSummaryTotalBilled.
  ///
  /// In en, this message translates to:
  /// **'Total Billed'**
  String get billingSummaryTotalBilled;

  /// No description provided for @billingSummaryTotalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total Received'**
  String get billingSummaryTotalReceived;

  /// No description provided for @billingSummaryOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get billingSummaryOutstanding;

  /// No description provided for @billingSummaryOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billingSummaryOverdue;

  /// No description provided for @billingQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get billingQuickActions;

  /// No description provided for @billingRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Billing Activity'**
  String get billingRecentActivity;

  /// No description provided for @billingSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get billingSeeAll;

  /// No description provided for @billingNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get billingNoRecentActivity;

  /// No description provided for @billingActionGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate Bills'**
  String get billingActionGenerate;

  /// No description provided for @billingActionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All Bills'**
  String get billingActionViewAll;

  /// No description provided for @billingActionRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get billingActionRecordPayment;

  /// No description provided for @billingActionSendReminders.
  ///
  /// In en, this message translates to:
  /// **'Send Reminders'**
  String get billingActionSendReminders;

  /// No description provided for @billingGeneratorStep1.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Select Billing Period'**
  String get billingGeneratorStep1;

  /// No description provided for @billingGeneratorStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Preview Eligible Invoices'**
  String get billingGeneratorStep2;

  /// No description provided for @billingGeneratorPendingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Pending Invoices: 15 • Est. Total: SAR 12,450'**
  String get billingGeneratorPendingInvoices;

  /// No description provided for @billingGeneratorPostAll.
  ///
  /// In en, this message translates to:
  /// **'Generate & Post All'**
  String get billingGeneratorPostAll;

  /// No description provided for @billingPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing Period: {month}/{year}'**
  String billingPeriodLabel(String month, String year);

  /// No description provided for @billingStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billingStatusPaid;

  /// No description provided for @billingStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billingStatusOverdue;

  /// No description provided for @billingStatusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get billingStatusPartiallyPaid;

  /// No description provided for @billingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get billingStatusPending;

  /// No description provided for @branchManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchManagementTitle;

  /// No description provided for @branchSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search branches…'**
  String get branchSearchHint;

  /// No description provided for @branchAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Branch'**
  String get branchAddButton;

  /// No description provided for @branchEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get branchEditButton;

  /// No description provided for @branchDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get branchDeleteButton;

  /// No description provided for @branchNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches found'**
  String get branchNoBranches;

  /// No description provided for @branchStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get branchStatusActive;

  /// No description provided for @branchStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get branchStatusInactive;

  /// No description provided for @branchFormTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Branch'**
  String get branchFormTitleAdd;

  /// No description provided for @branchFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Branch'**
  String get branchFormTitleEdit;

  /// No description provided for @branchFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get branchFormNameLabel;

  /// No description provided for @branchFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter branch name'**
  String get branchFormNameHint;

  /// No description provided for @branchFormAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get branchFormAddressLabel;

  /// No description provided for @branchFormAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Search address…'**
  String get branchFormAddressHint;

  /// No description provided for @branchFormLatLabel.
  ///
  /// In en, this message translates to:
  /// **'GPS Latitude'**
  String get branchFormLatLabel;

  /// No description provided for @branchFormLngLabel.
  ///
  /// In en, this message translates to:
  /// **'GPS Longitude'**
  String get branchFormLngLabel;

  /// No description provided for @branchFormStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get branchFormStatusLabel;

  /// No description provided for @branchFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Branch'**
  String get branchFormSaveButton;

  /// No description provided for @branchFormUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Branch'**
  String get branchFormUpdateButton;

  /// No description provided for @branchFormValidationError.
  ///
  /// In en, this message translates to:
  /// **'Branch Name and Address are required'**
  String get branchFormValidationError;

  /// No description provided for @branchCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Branch Created Successfully'**
  String get branchCreateSuccess;

  /// No description provided for @branchUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Branch Updated Successfully'**
  String get branchUpdateSuccess;

  /// No description provided for @branchDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Branch Deleted Successfully'**
  String get branchDeleteSuccess;

  /// No description provided for @branchSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save branch'**
  String get branchSaveError;

  /// No description provided for @branchDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete branch'**
  String get branchDeleteError;

  /// No description provided for @branchDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Branch'**
  String get branchDeleteConfirmTitle;

  /// No description provided for @branchDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this branch?'**
  String get branchDeleteConfirmBody;

  /// No description provided for @branchDeleteConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get branchDeleteConfirmCancel;

  /// No description provided for @branchDeleteConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get branchDeleteConfirmDelete;

  /// No description provided for @lockerPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Locker Portal'**
  String get lockerPortalTitle;

  /// No description provided for @lockerPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure asset management for your branch'**
  String get lockerPortalSubtitle;

  /// No description provided for @lockerPortalAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'LOCKER DASHBOARD'**
  String get lockerPortalAppBarTitle;

  /// No description provided for @lockerSecureAssetManagement.
  ///
  /// In en, this message translates to:
  /// **'SECURE ASSET MANAGEMENT'**
  String get lockerSecureAssetManagement;

  /// No description provided for @lockerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get lockerEmail;

  /// No description provided for @lockerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get lockerEmailHint;

  /// No description provided for @lockerEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get lockerEmailRequired;

  /// No description provided for @lockerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get lockerPassword;

  /// No description provided for @lockerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get lockerPasswordHint;

  /// No description provided for @lockerPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get lockerPasswordRequired;

  /// No description provided for @lockerForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get lockerForgotPassword;

  /// No description provided for @lockerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get lockerContinue;

  /// No description provided for @lockerLoadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard…'**
  String get lockerLoadingDashboard;

  /// No description provided for @lockerFailedLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get lockerFailedLoadDashboard;

  /// No description provided for @lockerUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get lockerUnexpectedError;

  /// No description provided for @lockerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get lockerRetry;

  /// No description provided for @lockerRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get lockerRefresh;

  /// No description provided for @lockerSupervisorTab.
  ///
  /// In en, this message translates to:
  /// **'SUPERVISOR'**
  String get lockerSupervisorTab;

  /// No description provided for @lockerCollectorTab.
  ///
  /// In en, this message translates to:
  /// **'COLLECTOR'**
  String get lockerCollectorTab;

  /// No description provided for @lockerLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get lockerLogOut;

  /// No description provided for @lockerLogOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the Locker Portal?'**
  String get lockerLogOutConfirm;

  /// No description provided for @lockerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lockerCancel;

  /// No description provided for @lockerLogOutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get lockerLogOutButton;

  /// No description provided for @lockerWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get lockerWelcomeBack;

  /// No description provided for @lockerRoleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'SUPERVISOR'**
  String get lockerRoleSupervisor;

  /// No description provided for @lockerRoleManager.
  ///
  /// In en, this message translates to:
  /// **'MANAGER'**
  String get lockerRoleManager;

  /// No description provided for @lockerRoleWorkshopOwner.
  ///
  /// In en, this message translates to:
  /// **'WORKSHOP OWNER'**
  String get lockerRoleWorkshopOwner;

  /// No description provided for @lockerRoleWorkshopSupervisor.
  ///
  /// In en, this message translates to:
  /// **'WORKSHOP SUPERVISOR'**
  String get lockerRoleWorkshopSupervisor;

  /// No description provided for @lockerRoleCollector.
  ///
  /// In en, this message translates to:
  /// **'COLLECTOR'**
  String get lockerRoleCollector;

  /// No description provided for @lockerRoleCollectionOfficer.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION OFFICER'**
  String get lockerRoleCollectionOfficer;

  /// No description provided for @lockerRoleWorkshopCollector.
  ///
  /// In en, this message translates to:
  /// **'WORKSHOP COLLECTOR'**
  String get lockerRoleWorkshopCollector;

  /// No description provided for @lockerSupervisorOverview.
  ///
  /// In en, this message translates to:
  /// **'SUPERVISOR OVERVIEW'**
  String get lockerSupervisorOverview;

  /// No description provided for @lockerMyPerformance.
  ///
  /// In en, this message translates to:
  /// **'MY PERFORMANCE'**
  String get lockerMyPerformance;

  /// No description provided for @lockerKpiPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get lockerKpiPending;

  /// No description provided for @lockerKpiAwaiting.
  ///
  /// In en, this message translates to:
  /// **'AWAITING'**
  String get lockerKpiAwaiting;

  /// No description provided for @lockerKpiOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get lockerKpiOverdue;

  /// No description provided for @lockerKpiVariance.
  ///
  /// In en, this message translates to:
  /// **'VARIANCE'**
  String get lockerKpiVariance;

  /// No description provided for @lockerKpiOpenAssignments.
  ///
  /// In en, this message translates to:
  /// **'OPEN ASSIGNMENTS'**
  String get lockerKpiOpenAssignments;

  /// No description provided for @lockerKpiPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'PENDING APPROVAL'**
  String get lockerKpiPendingApproval;

  /// No description provided for @lockerKpiTodaysCollections.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S COLLECTIONS'**
  String get lockerKpiTodaysCollections;

  /// No description provided for @lockerKpiMonthlyCollected.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY COLLECTED'**
  String get lockerKpiMonthlyCollected;

  /// No description provided for @lockerCoreOperations.
  ///
  /// In en, this message translates to:
  /// **'CORE OPERATIONS'**
  String get lockerCoreOperations;

  /// No description provided for @lockerManageAllRequests.
  ///
  /// In en, this message translates to:
  /// **'Manage All Requests'**
  String get lockerManageAllRequests;

  /// No description provided for @lockerStartCollection.
  ///
  /// In en, this message translates to:
  /// **'Start Collection'**
  String get lockerStartCollection;

  /// No description provided for @lockerAssignOfficers.
  ///
  /// In en, this message translates to:
  /// **'Assign Officers'**
  String get lockerAssignOfficers;

  /// No description provided for @lockerManageVarianceRequests.
  ///
  /// In en, this message translates to:
  /// **'Manage Variance Requests'**
  String get lockerManageVarianceRequests;

  /// No description provided for @lockerFinancialAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Financial Analytics'**
  String get lockerFinancialAnalytics;

  /// No description provided for @lockerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search requests…'**
  String get lockerSearchHint;

  /// No description provided for @lockerLoadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Loading requests…'**
  String get lockerLoadingRequests;

  /// No description provided for @lockerNoRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No requests found'**
  String get lockerNoRequestsFound;

  /// No description provided for @lockerAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get lockerAdjustFilters;

  /// No description provided for @lockerLockedCashAsset.
  ///
  /// In en, this message translates to:
  /// **'LOCKED CASH ASSET'**
  String get lockerLockedCashAsset;

  /// No description provided for @lockerTapToCollect.
  ///
  /// In en, this message translates to:
  /// **'TAP TO COLLECT'**
  String get lockerTapToCollect;

  /// No description provided for @lockerStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED'**
  String get lockerStatusAssigned;

  /// No description provided for @lockerStatusAwaiting.
  ///
  /// In en, this message translates to:
  /// **'AWAITING'**
  String get lockerStatusAwaiting;

  /// No description provided for @lockerStatusCollected.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get lockerStatusCollected;

  /// No description provided for @lockerStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get lockerStatusApproved;

  /// No description provided for @lockerStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get lockerStatusRejected;

  /// No description provided for @lockerStatusMatched.
  ///
  /// In en, this message translates to:
  /// **'MATCHED'**
  String get lockerStatusMatched;

  /// No description provided for @lockerLoadingRequest.
  ///
  /// In en, this message translates to:
  /// **'Loading request…'**
  String get lockerLoadingRequest;

  /// No description provided for @lockerFailedLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load request details'**
  String get lockerFailedLoadDetails;

  /// No description provided for @lockerSystemStatus.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM STATUS'**
  String get lockerSystemStatus;

  /// No description provided for @lockerTotalSecuredAsset.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SECURED ASSET'**
  String get lockerTotalSecuredAsset;

  /// No description provided for @lockerCounterClosing.
  ///
  /// In en, this message translates to:
  /// **'COUNTER CLOSING'**
  String get lockerCounterClosing;

  /// No description provided for @lockerPhysicalCash.
  ///
  /// In en, this message translates to:
  /// **'PHYSICAL CASH'**
  String get lockerPhysicalCash;

  /// No description provided for @lockerSystemTotal.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM TOTAL'**
  String get lockerSystemTotal;

  /// No description provided for @lockerDifference.
  ///
  /// In en, this message translates to:
  /// **'DIFFERENCE'**
  String get lockerDifference;

  /// No description provided for @lockerCollectionRecord.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION RECORD'**
  String get lockerCollectionRecord;

  /// No description provided for @lockerReceived.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED'**
  String get lockerReceived;

  /// No description provided for @lockerInternalData.
  ///
  /// In en, this message translates to:
  /// **'INTERNAL DATA'**
  String get lockerInternalData;

  /// No description provided for @lockerSourceBranch.
  ///
  /// In en, this message translates to:
  /// **'SOURCE BRANCH'**
  String get lockerSourceBranch;

  /// No description provided for @lockerCashier.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get lockerCashier;

  /// No description provided for @lockerCashierIdentity.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get lockerCashierIdentity;

  /// No description provided for @lockerShiftCloseTime.
  ///
  /// In en, this message translates to:
  /// **'SHIFT CLOSE TIME'**
  String get lockerShiftCloseTime;

  /// No description provided for @lockerSessionOpened.
  ///
  /// In en, this message translates to:
  /// **'SESSION OPENED'**
  String get lockerSessionOpened;

  /// No description provided for @lockerSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'SESSION CLOSED'**
  String get lockerSessionClosed;

  /// No description provided for @lockerAssignedOfficer.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED OFFICER'**
  String get lockerAssignedOfficer;

  /// No description provided for @lockerAssignCollectionOfficer.
  ///
  /// In en, this message translates to:
  /// **'Assign Collection Officer'**
  String get lockerAssignCollectionOfficer;

  /// No description provided for @lockerProceedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Collection'**
  String get lockerProceedToCollection;

  /// No description provided for @lockerGenerateAuditPdf.
  ///
  /// In en, this message translates to:
  /// **'Generate Audit PDF'**
  String get lockerGenerateAuditPdf;

  /// No description provided for @lockerCollectionPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Collection is pending supervisor approval.'**
  String get lockerCollectionPendingApproval;

  /// No description provided for @lockerPendingSupervisorApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending supervisor approval'**
  String get lockerPendingSupervisorApproval;

  /// No description provided for @lockerCollectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Collection recorded successfully'**
  String get lockerCollectedSuccessfully;

  /// No description provided for @lockerVarianceApproved.
  ///
  /// In en, this message translates to:
  /// **'Variance approved'**
  String get lockerVarianceApproved;

  /// No description provided for @lockerVarianceRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Variance rejected'**
  String get lockerVarianceRejectedBanner;

  /// No description provided for @lockerVarianceDifferenceReview.
  ///
  /// In en, this message translates to:
  /// **'There is a variance in this collection. Please review and approve or reject.'**
  String get lockerVarianceDifferenceReview;

  /// No description provided for @lockerApproveVariance.
  ///
  /// In en, this message translates to:
  /// **'Variance approved successfully'**
  String get lockerApproveVariance;

  /// No description provided for @lockerApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get lockerApprove;

  /// No description provided for @lockerReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get lockerReject;

  /// No description provided for @lockerRejectVarianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Variance'**
  String get lockerRejectVarianceTitle;

  /// No description provided for @lockerRejectVarianceBody.
  ///
  /// In en, this message translates to:
  /// **'Provide an optional reason for rejecting this variance.'**
  String get lockerRejectVarianceBody;

  /// No description provided for @lockerRejectionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter rejection reason (optional)'**
  String get lockerRejectionReasonHint;

  /// No description provided for @lockerConfirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get lockerConfirmReject;

  /// No description provided for @corporateFieldMobileMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get corporateFieldMobileMobile;

  /// No description provided for @corporateFieldTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID (VAT)'**
  String get corporateFieldTaxId;

  /// No description provided for @corporateFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get corporateFieldStatus;

  /// No description provided for @corporateSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get corporateSaveChanges;

  /// No description provided for @corporateStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get corporateStatusPending;

  /// No description provided for @corporateStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get corporateStatusActive;

  /// No description provided for @corporateStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get corporateStatusRejected;

  /// No description provided for @corporateCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Corporate Account Created Successfully'**
  String get corporateCreateSuccess;

  /// No description provided for @corporateCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create corporate account'**
  String get corporateCreateError;

  /// No description provided for @corporateUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Corporate Account Updated Successfully'**
  String get corporateUpdateSuccess;

  /// No description provided for @corporateUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update corporate account'**
  String get corporateUpdateError;

  /// No description provided for @corporateUserCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Corporate User Created Successfully'**
  String get corporateUserCreateSuccess;

  /// No description provided for @corporateUserCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create corporate user'**
  String get corporateUserCreateError;

  /// No description provided for @corporateValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get corporateValidationRequired;

  /// No description provided for @corporateValidationBranch.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one branch'**
  String get corporateValidationBranch;

  /// No description provided for @corporateValidationCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get corporateValidationCompanyName;

  /// No description provided for @dashboardAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All Branches'**
  String get dashboardAllBranches;

  /// No description provided for @dashboardViewingDataFor.
  ///
  /// In en, this message translates to:
  /// **'Viewing Data For'**
  String get dashboardViewingDataFor;

  /// No description provided for @dashboardAllBranchesAggregated.
  ///
  /// In en, this message translates to:
  /// **'All Branches Aggregated'**
  String get dashboardAllBranchesAggregated;

  /// No description provided for @dashboardSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select Branch'**
  String get dashboardSelectBranch;

  /// No description provided for @dashboardKpiTotalSalesToday.
  ///
  /// In en, this message translates to:
  /// **'Total Sales Today'**
  String get dashboardKpiTotalSalesToday;

  /// No description provided for @dashboardKpiThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardKpiThisMonth;

  /// No description provided for @dashboardKpiPendingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Pending Invoices'**
  String get dashboardKpiPendingInvoices;

  /// No description provided for @dashboardKpiLowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get dashboardKpiLowStockAlerts;

  /// No description provided for @dashboardKpiTodaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get dashboardKpiTodaysSales;

  /// No description provided for @dashboardKpiActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get dashboardKpiActiveOrders;

  /// No description provided for @dashboardKpiTechWorkload.
  ///
  /// In en, this message translates to:
  /// **'Tech Workload'**
  String get dashboardKpiTechWorkload;

  /// No description provided for @dashboardKpiPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get dashboardKpiPendingApproval;

  /// No description provided for @dashboardPendingApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get dashboardPendingApprovalsTitle;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashboardViewAll;

  /// No description provided for @dashboardNoPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'No pending petty-cash approvals right now.'**
  String get dashboardNoPendingApprovals;

  /// No description provided for @dashboardMoreApprovals.
  ///
  /// In en, this message translates to:
  /// **'+{count} more in Approvals'**
  String dashboardMoreApprovals(int count);

  /// No description provided for @dashboardBranchPerformance.
  ///
  /// In en, this message translates to:
  /// **'Branch Performance'**
  String get dashboardBranchPerformance;

  /// No description provided for @dashboardBranchHighlights.
  ///
  /// In en, this message translates to:
  /// **'Branch Highlights'**
  String get dashboardBranchHighlights;

  /// No description provided for @dashboardBranchStatus.
  ///
  /// In en, this message translates to:
  /// **'Branch Status'**
  String get dashboardBranchStatus;

  /// No description provided for @dashboardTotalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get dashboardTotalStaff;

  /// No description provided for @dashboardSalesTarget.
  ///
  /// In en, this message translates to:
  /// **'Sales Target'**
  String get dashboardSalesTarget;

  /// No description provided for @dashboardSalesTargetValue.
  ///
  /// In en, this message translates to:
  /// **'85% Achieved'**
  String get dashboardSalesTargetValue;

  /// No description provided for @branchPerformanceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch Performance'**
  String get branchPerformanceListTitle;

  /// No description provided for @branchPerformanceNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches yet.'**
  String get branchPerformanceNoBranches;

  /// No description provided for @deptMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Department Management'**
  String get deptMgmtTitle;

  /// No description provided for @deptMgmtSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Department Name...'**
  String get deptMgmtSearchHint;

  /// No description provided for @deptMgmtAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Department'**
  String get deptMgmtAddButton;

  /// No description provided for @deptMgmtNoDepartments.
  ///
  /// In en, this message translates to:
  /// **'No departments found.'**
  String get deptMgmtNoDepartments;

  /// No description provided for @deptMgmtLabelDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get deptMgmtLabelDepartment;

  /// No description provided for @deptMgmtMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deptMgmtMenuEdit;

  /// No description provided for @deptMgmtMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deptMgmtMenuDelete;

  /// No description provided for @deptMgmtConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get deptMgmtConfirmDeleteTitle;

  /// No description provided for @deptMgmtConfirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deptMgmtConfirmDeleteBody(String name);

  /// No description provided for @deptMgmtCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deptMgmtCancel;

  /// No description provided for @deptMgmtDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deptMgmtDelete;

  /// No description provided for @deptMgmtStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get deptMgmtStatusActive;

  /// No description provided for @deptMgmtStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get deptMgmtStatusInactive;

  /// No description provided for @deptMgmtSheetAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get deptMgmtSheetAddTitle;

  /// No description provided for @deptMgmtSheetUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Department'**
  String get deptMgmtSheetUpdateTitle;

  /// No description provided for @deptMgmtSheetAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the new department.'**
  String get deptMgmtSheetAddSubtitle;

  /// No description provided for @deptMgmtSheetUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify existing department details.'**
  String get deptMgmtSheetUpdateSubtitle;

  /// No description provided for @deptMgmtFieldName.
  ///
  /// In en, this message translates to:
  /// **'Department Name'**
  String get deptMgmtFieldName;

  /// No description provided for @deptMgmtFieldActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get deptMgmtFieldActiveStatus;

  /// No description provided for @deptMgmtSheetAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get deptMgmtSheetAddButton;

  /// No description provided for @deptMgmtSheetUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Department'**
  String get deptMgmtSheetUpdateButton;

  /// No description provided for @deptMgmtValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Department Name is required'**
  String get deptMgmtValidationNameRequired;

  /// No description provided for @deptMgmtCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department Created Successfully'**
  String get deptMgmtCreateSuccess;

  /// No description provided for @deptMgmtUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department Updated Successfully'**
  String get deptMgmtUpdateSuccess;

  /// No description provided for @deptMgmtDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department Deleted Successfully'**
  String get deptMgmtDeleteSuccess;

  /// No description provided for @deptMgmtSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save department'**
  String get deptMgmtSaveError;

  /// No description provided for @deptMgmtDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete department'**
  String get deptMgmtDeleteError;

  /// No description provided for @empMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get empMgmtTitle;

  /// No description provided for @empMgmtSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Name, Email or Mobile...'**
  String get empMgmtSearchHint;

  /// No description provided for @empMgmtAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get empMgmtAddButton;

  /// No description provided for @empMgmtFilterAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All Branches'**
  String get empMgmtFilterAllBranches;

  /// No description provided for @empMgmtNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees found.'**
  String get empMgmtNoEmployees;

  /// No description provided for @empMgmtLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {time}'**
  String empMgmtLastSeen(String time);

  /// No description provided for @empMgmtInfoBranch.
  ///
  /// In en, this message translates to:
  /// **'BRANCH'**
  String get empMgmtInfoBranch;

  /// No description provided for @empMgmtInfoDept.
  ///
  /// In en, this message translates to:
  /// **'DEPT'**
  String get empMgmtInfoDept;

  /// No description provided for @empMgmtInfoRoleType.
  ///
  /// In en, this message translates to:
  /// **'ROLE TYPE'**
  String get empMgmtInfoRoleType;

  /// No description provided for @empMgmtInfoTechType.
  ///
  /// In en, this message translates to:
  /// **'TECH TYPE'**
  String get empMgmtInfoTechType;

  /// No description provided for @empMgmtInfoSalary.
  ///
  /// In en, this message translates to:
  /// **'SALARY'**
  String get empMgmtInfoSalary;

  /// No description provided for @empMgmtInfoCommission.
  ///
  /// In en, this message translates to:
  /// **'COMMISSION'**
  String get empMgmtInfoCommission;

  /// No description provided for @empMgmtInfoUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get empMgmtInfoUnknown;

  /// No description provided for @empMgmtInfoNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get empMgmtInfoNone;

  /// No description provided for @empMgmtMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get empMgmtMenuEdit;

  /// No description provided for @empMgmtMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get empMgmtMenuDelete;

  /// No description provided for @empMgmtDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Employee'**
  String get empMgmtDeleteTitle;

  /// No description provided for @empMgmtDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String empMgmtDeleteBody(String name);

  /// No description provided for @empMgmtDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get empMgmtDeleteCancel;

  /// No description provided for @empMgmtDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get empMgmtDeleteConfirm;

  /// No description provided for @empMgmtSheetAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Employee'**
  String get empMgmtSheetAddTitle;

  /// No description provided for @empMgmtSheetUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Employee'**
  String get empMgmtSheetUpdateTitle;

  /// No description provided for @empMgmtSheetAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide detailed Information to register a new member.'**
  String get empMgmtSheetAddSubtitle;

  /// No description provided for @empMgmtSheetUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify existing employee details.'**
  String get empMgmtSheetUpdateSubtitle;

  /// No description provided for @empMgmtFieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get empMgmtFieldRole;

  /// No description provided for @empMgmtFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get empMgmtFieldFullName;

  /// No description provided for @empMgmtFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get empMgmtFieldMobile;

  /// No description provided for @empMgmtFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get empMgmtFieldEmail;

  /// No description provided for @empMgmtFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get empMgmtFieldPassword;

  /// No description provided for @empMgmtFieldPasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'Password (Optional)'**
  String get empMgmtFieldPasswordOptional;

  /// No description provided for @empMgmtFieldBranch.
  ///
  /// In en, this message translates to:
  /// **'Assign to Branch'**
  String get empMgmtFieldBranch;

  /// No description provided for @empMgmtFieldDepartment.
  ///
  /// In en, this message translates to:
  /// **'Assign Department'**
  String get empMgmtFieldDepartment;

  /// No description provided for @empMgmtFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get empMgmtFieldAddress;

  /// No description provided for @empMgmtFieldOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get empMgmtFieldOpeningBalance;

  /// No description provided for @empMgmtFieldBaseSalary.
  ///
  /// In en, this message translates to:
  /// **'Base Salary'**
  String get empMgmtFieldBaseSalary;

  /// No description provided for @empMgmtFieldCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission %'**
  String get empMgmtFieldCommission;

  /// No description provided for @empMgmtFieldActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get empMgmtFieldActiveStatus;

  /// No description provided for @empMgmtSectionTechSpecifics.
  ///
  /// In en, this message translates to:
  /// **'Technician Specifics'**
  String get empMgmtSectionTechSpecifics;

  /// No description provided for @empMgmtSectionSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary & Commission'**
  String get empMgmtSectionSalary;

  /// No description provided for @empMgmtSectionAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get empMgmtSectionAvailability;

  /// No description provided for @empMgmtToggleWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop Technician'**
  String get empMgmtToggleWorkshop;

  /// No description provided for @empMgmtToggleOnCall.
  ///
  /// In en, this message translates to:
  /// **'On-Call Technician'**
  String get empMgmtToggleOnCall;

  /// No description provided for @empMgmtNoAddressFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get empMgmtNoAddressFound;

  /// No description provided for @empMgmtSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Employee'**
  String get empMgmtSaveButton;

  /// No description provided for @empMgmtUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Employee'**
  String get empMgmtUpdateButton;

  /// No description provided for @empMgmtRoleTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get empMgmtRoleTechnician;

  /// No description provided for @empMgmtRoleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get empMgmtRoleCashier;

  /// No description provided for @empMgmtRoleSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get empMgmtRoleSupplier;

  /// No description provided for @empMgmtValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required text fields.'**
  String get empMgmtValidationRequired;

  /// No description provided for @empMgmtValidationTechType.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one technician type.'**
  String get empMgmtValidationTechType;

  /// No description provided for @empMgmtValidationNoBranch.
  ///
  /// In en, this message translates to:
  /// **'Please create a branch first to assign this employee.'**
  String get empMgmtValidationNoBranch;

  /// No description provided for @empMgmtValidationNoBranchCashier.
  ///
  /// In en, this message translates to:
  /// **'Please create a branch first to assign this cashier.'**
  String get empMgmtValidationNoBranchCashier;

  /// No description provided for @empMgmtValidationNoDepartment.
  ///
  /// In en, this message translates to:
  /// **'Please create a department first to assign this employee.'**
  String get empMgmtValidationNoDepartment;

  /// No description provided for @empMgmtValidationSupplierRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get empMgmtValidationSupplierRequired;

  /// No description provided for @empMgmtApiNotIntegrated.
  ///
  /// In en, this message translates to:
  /// **'Only Technician, Cashier, and Supplier creation APIs are integrated.'**
  String get empMgmtApiNotIntegrated;

  /// No description provided for @empMgmtTechnicianCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technician Created Successfully'**
  String get empMgmtTechnicianCreateSuccess;

  /// No description provided for @empMgmtTechnicianUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technician Updated Successfully'**
  String get empMgmtTechnicianUpdateSuccess;

  /// No description provided for @empMgmtTechnicianCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create technician'**
  String get empMgmtTechnicianCreateError;

  /// No description provided for @empMgmtCashierCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cashier Created Successfully'**
  String get empMgmtCashierCreateSuccess;

  /// No description provided for @empMgmtCashierUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cashier Updated Successfully'**
  String get empMgmtCashierUpdateSuccess;

  /// No description provided for @empMgmtCashierCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create cashier'**
  String get empMgmtCashierCreateError;

  /// No description provided for @empMgmtSupplierCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier Created Successfully'**
  String get empMgmtSupplierCreateSuccess;

  /// No description provided for @empMgmtSupplierCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create supplier'**
  String get empMgmtSupplierCreateError;

  /// No description provided for @empMgmtDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee Deleted Successfully'**
  String get empMgmtDeleteSuccess;

  /// No description provided for @empMgmtDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete employee'**
  String get empMgmtDeleteError;

  /// No description provided for @empStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get empStatusAvailable;

  /// No description provided for @empStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get empStatusOnline;

  /// No description provided for @empStatusBusy.
  ///
  /// In en, this message translates to:
  /// **'BUSY'**
  String get empStatusBusy;

  /// No description provided for @empStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get empStatusOffline;

  /// No description provided for @empLastSeenNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get empLastSeenNever;

  /// No description provided for @empLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get empLastSeenJustNow;

  /// No description provided for @empLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m}m ago'**
  String empLastSeenMinutes(int m);

  /// No description provided for @empLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'{h}h ago'**
  String empLastSeenHours(int h);

  /// No description provided for @empLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'{d}d ago'**
  String empLastSeenDays(int d);

  /// No description provided for @empTechTypeWorkshop.
  ///
  /// In en, this message translates to:
  /// **'WORKSHOP'**
  String get empTechTypeWorkshop;

  /// No description provided for @empTechTypeBoth.
  ///
  /// In en, this message translates to:
  /// **'BOTH'**
  String get empTechTypeBoth;

  /// No description provided for @empTechTypeOnCall.
  ///
  /// In en, this message translates to:
  /// **'ON-CALL'**
  String get empTechTypeOnCall;

  /// No description provided for @empRoleTechnician.
  ///
  /// In en, this message translates to:
  /// **'TECHNICIAN'**
  String get empRoleTechnician;

  /// No description provided for @empRoleCashier.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get empRoleCashier;

  /// No description provided for @empRoleSupplier.
  ///
  /// In en, this message translates to:
  /// **'SUPPLIER'**
  String get empRoleSupplier;

  /// No description provided for @posAddCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Order'**
  String get posAddCustomerTitle;

  /// No description provided for @posAddCustomerTabNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Customer'**
  String get posAddCustomerTabNormal;

  /// No description provided for @posAddCustomerTabCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate Customer'**
  String get posAddCustomerTabCorporate;

  /// No description provided for @posAddCustomerSectionVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get posAddCustomerSectionVehicleInfo;

  /// No description provided for @posAddCustomerSectionCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details (Auto-filled)'**
  String get posAddCustomerSectionCompanyDetails;

  /// No description provided for @posAddCustomerSectionCorporateAccount.
  ///
  /// In en, this message translates to:
  /// **'Corporate Account'**
  String get posAddCustomerSectionCorporateAccount;

  /// No description provided for @posAddCustomerFieldVehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get posAddCustomerFieldVehicleNumber;

  /// No description provided for @posAddCustomerFieldVin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get posAddCustomerFieldVin;

  /// No description provided for @posAddCustomerFieldMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get posAddCustomerFieldMake;

  /// No description provided for @posAddCustomerFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get posAddCustomerFieldModel;

  /// No description provided for @posAddCustomerFieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get posAddCustomerFieldYear;

  /// No description provided for @posAddCustomerFieldOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get posAddCustomerFieldOdometer;

  /// No description provided for @posAddCustomerFieldCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get posAddCustomerFieldCompanyName;

  /// No description provided for @posAddCustomerFieldVatNumber.
  ///
  /// In en, this message translates to:
  /// **'VAT Number'**
  String get posAddCustomerFieldVatNumber;

  /// No description provided for @posAddCustomerFieldBillingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get posAddCustomerFieldBillingAddress;

  /// No description provided for @posAddCustomerSelectCorporate.
  ///
  /// In en, this message translates to:
  /// **'Select Corporate Account'**
  String get posAddCustomerSelectCorporate;

  /// No description provided for @posAddCustomerNoCorporateFound.
  ///
  /// In en, this message translates to:
  /// **'No Corporate Accounts Found'**
  String get posAddCustomerNoCorporateFound;

  /// No description provided for @posAddCustomerSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save & Proceed to Department'**
  String get posAddCustomerSaveButton;

  /// No description provided for @posAddCustomerFieldNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get posAddCustomerFieldNA;

  /// No description provided for @posAddCustomerSectionCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get posAddCustomerSectionCustomerInfo;

  /// No description provided for @posAddCustomerFieldCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get posAddCustomerFieldCustomerName;

  /// No description provided for @posAddCustomerValidationVehicleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter vehicle number'**
  String get posAddCustomerValidationVehicleRequired;

  /// No description provided for @posAddCustomerValidationVehiclePlateMaxFourDigits.
  ///
  /// In en, this message translates to:
  /// **'Saudi plates allow at most 4 digits after the 3 letters'**
  String get posAddCustomerValidationVehiclePlateMaxFourDigits;

  /// No description provided for @posAddCustomerValidationVehiclePlateMaxThreeLetters.
  ///
  /// In en, this message translates to:
  /// **'Saudi plates allow exactly 3 letters before the digits'**
  String get posAddCustomerValidationVehiclePlateMaxThreeLetters;

  /// No description provided for @posAddCustomerVehicleKindCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get posAddCustomerVehicleKindCar;

  /// No description provided for @posAddCustomerVehicleKindBike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get posAddCustomerVehicleKindBike;

  /// No description provided for @posAddCustomerValidationBikePlateTwoLetters.
  ///
  /// In en, this message translates to:
  /// **'Bike plates need exactly 2 letters before the 4 digits'**
  String get posAddCustomerValidationBikePlateTwoLetters;

  /// No description provided for @posAddCustomerValidationBikePlateFourDigits.
  ///
  /// In en, this message translates to:
  /// **'Bike plates need exactly 4 digits after the 2 letters'**
  String get posAddCustomerValidationBikePlateFourDigits;

  /// No description provided for @posAddCustomerValidationBikePlateMaxTwoLetters.
  ///
  /// In en, this message translates to:
  /// **'Bike plates allow at most 2 letters before the digits'**
  String get posAddCustomerValidationBikePlateMaxTwoLetters;

  /// No description provided for @posGccPlateCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate country'**
  String get posGccPlateCountryLabel;

  /// No description provided for @posGccPlateEmirateLabel.
  ///
  /// In en, this message translates to:
  /// **'Emirate'**
  String get posGccPlateEmirateLabel;

  /// No description provided for @posGccPlateValidationGccFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter letters and digits (e.g. ABC - 1234)'**
  String get posGccPlateValidationGccFormat;

  /// No description provided for @posGccPlateValidationEmirateRequired.
  ///
  /// In en, this message translates to:
  /// **'Select emirate for UAE plates'**
  String get posGccPlateValidationEmirateRequired;

  /// No description provided for @posAddCustomerFleetVehiclesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading fleet vehicles…'**
  String get posAddCustomerFleetVehiclesLoading;

  /// No description provided for @posAddCustomerNoFleetVehicles.
  ///
  /// In en, this message translates to:
  /// **'No fleet vehicles on this account'**
  String get posAddCustomerNoFleetVehicles;

  /// No description provided for @posAddCustomerSelectFleetVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select fleet vehicle'**
  String get posAddCustomerSelectFleetVehicle;

  /// No description provided for @posAddCustomerFleetVehicleManual.
  ///
  /// In en, this message translates to:
  /// **'Enter plate manually'**
  String get posAddCustomerFleetVehicleManual;

  /// No description provided for @posAddCustomerValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get posAddCustomerValidationRequired;

  /// No description provided for @posAddCustomerValidationVinMax.
  ///
  /// In en, this message translates to:
  /// **'Max 17 characters'**
  String get posAddCustomerValidationVinMax;

  /// No description provided for @posAddCustomerValidationInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get posAddCustomerValidationInvalidNumber;

  /// No description provided for @posAddCustomerValidationInvalidNumberShort.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get posAddCustomerValidationInvalidNumberShort;

  /// No description provided for @posAddCustomerValidationMobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number'**
  String get posAddCustomerValidationMobileRequired;

  /// No description provided for @posAddCustomerValidationMobileSaudi.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Saudi number (e.g. 05X XXX XXXX)'**
  String get posAddCustomerValidationMobileSaudi;

  /// No description provided for @posAddCustomerValidationMobilePakistan.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Pakistan mobile (e.g. 03XX XXXXXXX)'**
  String get posAddCustomerValidationMobilePakistan;

  /// No description provided for @posMonitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'POS Monitoring'**
  String get posMonitoringTitle;

  /// No description provided for @posMonitoringLiveCounters.
  ///
  /// In en, this message translates to:
  /// **'Live Counters'**
  String get posMonitoringLiveCounters;

  /// No description provided for @posMonitoringClosingReports.
  ///
  /// In en, this message translates to:
  /// **'Closing Reports'**
  String get posMonitoringClosingReports;

  /// No description provided for @posMonitoringSummaryLiveCounters.
  ///
  /// In en, this message translates to:
  /// **'Live Counters'**
  String get posMonitoringSummaryLiveCounters;

  /// No description provided for @posMonitoringSummaryOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'Open Orders'**
  String get posMonitoringSummaryOpenOrders;

  /// No description provided for @posMonitoringSummaryTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today Sales'**
  String get posMonitoringSummaryTodaySales;

  /// No description provided for @posMonitoringNoLiveCounters.
  ///
  /// In en, this message translates to:
  /// **'No active live counters'**
  String get posMonitoringNoLiveCounters;

  /// No description provided for @posMonitoringNoClosingReports.
  ///
  /// In en, this message translates to:
  /// **'No closing reports available'**
  String get posMonitoringNoClosingReports;

  /// No description provided for @posMonitoringStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get posMonitoringStatusOpen;

  /// No description provided for @posMonitoringStatusClosing.
  ///
  /// In en, this message translates to:
  /// **'CLOSING'**
  String get posMonitoringStatusClosing;

  /// No description provided for @posMonitoringStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get posMonitoringStatusClosed;

  /// No description provided for @posMonitoringStatShiftSales.
  ///
  /// In en, this message translates to:
  /// **'SHIFT SALES'**
  String get posMonitoringStatShiftSales;

  /// No description provided for @posMonitoringStatOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'OPEN ORDERS'**
  String get posMonitoringStatOpenOrders;

  /// No description provided for @posMonitoringStatElapsed.
  ///
  /// In en, this message translates to:
  /// **'ELAPSED'**
  String get posMonitoringStatElapsed;

  /// No description provided for @posMonitoringElapsedFormat.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String posMonitoringElapsedFormat(int h, int m);

  /// No description provided for @posMonitoringClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get posMonitoringClosed;

  /// No description provided for @posMonitoringTableCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get posMonitoringTableCategory;

  /// No description provided for @posMonitoringTableSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get posMonitoringTableSystem;

  /// No description provided for @posMonitoringTablePhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get posMonitoringTablePhysical;

  /// No description provided for @posMonitoringTableDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get posMonitoringTableDiff;

  /// No description provided for @posMonitoringTableTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get posMonitoringTableTotalSales;

  /// No description provided for @posMonitoringRowCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get posMonitoringRowCash;

  /// No description provided for @posMonitoringRowBank.
  ///
  /// In en, this message translates to:
  /// **'Bank/Cards'**
  String get posMonitoringRowBank;

  /// No description provided for @posMonitoringRowCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get posMonitoringRowCorporate;

  /// No description provided for @posMonitoringRowTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara'**
  String get posMonitoringRowTamara;

  /// No description provided for @posMonitoringRowTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby'**
  String get posMonitoringRowTabby;

  /// No description provided for @posMonitoringDiffShort.
  ///
  /// In en, this message translates to:
  /// **'SHORT'**
  String get posMonitoringDiffShort;

  /// No description provided for @posMonitoringDiffExcess.
  ///
  /// In en, this message translates to:
  /// **'EXCESS'**
  String get posMonitoringDiffExcess;

  /// No description provided for @posMonitoringDiffBalanced.
  ///
  /// In en, this message translates to:
  /// **'BALANCED'**
  String get posMonitoringDiffBalanced;

  /// No description provided for @posMonitoringDiffShortSymbol.
  ///
  /// In en, this message translates to:
  /// **'− SAR {amount}'**
  String posMonitoringDiffShortSymbol(String amount);

  /// No description provided for @posMonitoringDiffExcessSymbol.
  ///
  /// In en, this message translates to:
  /// **'+ SAR {amount}'**
  String posMonitoringDiffExcessSymbol(String amount);

  /// No description provided for @posMonitoringDiffNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get posMonitoringDiffNone;

  /// No description provided for @posMonitoringBackendWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠ Full breakdown unavailable — deploy latest backend to see per-category data'**
  String get posMonitoringBackendWarning;

  /// No description provided for @posMonitoringAmountSar.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String posMonitoringAmountSar(String amount);

  /// No description provided for @promoTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo Codes'**
  String get promoTitle;

  /// No description provided for @promoNewButton.
  ///
  /// In en, this message translates to:
  /// **'New Promo'**
  String get promoNewButton;

  /// No description provided for @promoNoCodesFound.
  ///
  /// In en, this message translates to:
  /// **'No promo codes found'**
  String get promoNoCodesFound;

  /// No description provided for @promoMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get promoMenuEdit;

  /// No description provided for @promoMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get promoMenuDelete;

  /// No description provided for @promoDiscountOff.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} OFF'**
  String promoDiscountOff(String value, String unit);

  /// No description provided for @promoUnitPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get promoUnitPercent;

  /// No description provided for @promoUnitSar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get promoUnitSar;

  /// No description provided for @promoStatUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get promoStatUsage;

  /// No description provided for @promoStatMinOrder.
  ///
  /// In en, this message translates to:
  /// **'Min Order'**
  String get promoStatMinOrder;

  /// No description provided for @promoStatValidTill.
  ///
  /// In en, this message translates to:
  /// **'Valid Till'**
  String get promoStatValidTill;

  /// No description provided for @promoMinOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String promoMinOrderAmount(String amount);

  /// No description provided for @promoDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get promoDeleteConfirmTitle;

  /// No description provided for @promoDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{code}\"? This action cannot be undone.'**
  String promoDeleteConfirmBody(String code);

  /// No description provided for @promoDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get promoDeleteCancel;

  /// No description provided for @promoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get promoDeleteConfirm;

  /// No description provided for @promoSheetCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Promo Code'**
  String get promoSheetCreateTitle;

  /// No description provided for @promoSheetUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Promo Code'**
  String get promoSheetUpdateTitle;

  /// No description provided for @promoSheetCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure a new discount code for customers.'**
  String get promoSheetCreateSubtitle;

  /// No description provided for @promoSheetUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify existing promo code details.'**
  String get promoSheetUpdateSubtitle;

  /// No description provided for @promoFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code (e.g., SUMMER20)'**
  String get promoFieldCode;

  /// No description provided for @promoFieldDiscountValue.
  ///
  /// In en, this message translates to:
  /// **'Discount Value'**
  String get promoFieldDiscountValue;

  /// No description provided for @promoFieldUsageLimit.
  ///
  /// In en, this message translates to:
  /// **'Usage Limit'**
  String get promoFieldUsageLimit;

  /// No description provided for @promoFieldMinOrder.
  ///
  /// In en, this message translates to:
  /// **'Min Order (SAR)'**
  String get promoFieldMinOrder;

  /// No description provided for @promoFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get promoFieldDescription;

  /// No description provided for @promoFieldValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get promoFieldValidFrom;

  /// No description provided for @promoFieldValidTo.
  ///
  /// In en, this message translates to:
  /// **'Valid To'**
  String get promoFieldValidTo;

  /// No description provided for @promoTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get promoTypeFixed;

  /// No description provided for @promoTypePercent.
  ///
  /// In en, this message translates to:
  /// **'Percentage (%)'**
  String get promoTypePercent;

  /// No description provided for @promoSubmitCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Promo'**
  String get promoSubmitCreate;

  /// No description provided for @promoSubmitUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Promo'**
  String get promoSubmitUpdate;

  /// No description provided for @promoValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill required fields (Code, Value)'**
  String get promoValidationRequired;

  /// No description provided for @promoCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promo Code created successfully!'**
  String get promoCreateSuccess;

  /// No description provided for @promoUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promo Code updated successfully!'**
  String get promoUpdateSuccess;

  /// No description provided for @promoDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promo Code deleted successfully!'**
  String get promoDeleteSuccess;

  /// No description provided for @promoCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to process promo code'**
  String get promoCreateError;

  /// No description provided for @promoDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete promo code'**
  String get promoDeleteError;

  /// No description provided for @lockerVarianceRejected.
  ///
  /// In en, this message translates to:
  /// **'Variance rejected'**
  String get lockerVarianceRejected;

  /// No description provided for @lockerSelectOfficer.
  ///
  /// In en, this message translates to:
  /// **'SELECT OFFICER'**
  String get lockerSelectOfficer;

  /// No description provided for @lockerSelectOfficerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a field officer to assign to this collection request.'**
  String get lockerSelectOfficerSubtitle;

  /// No description provided for @lockerOfficersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load officers.'**
  String get lockerOfficersLoadError;

  /// No description provided for @lockerAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get lockerAssignedTo;

  /// No description provided for @lockerLoaderAuditReport.
  ///
  /// In en, this message translates to:
  /// **'Locker Audit Report'**
  String get lockerLoaderAuditReport;

  /// No description provided for @lockerGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated at'**
  String get lockerGeneratedAt;

  /// No description provided for @lockerPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get lockerPage;

  /// No description provided for @lockerOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get lockerOf;

  /// No description provided for @lockerRequestInformation.
  ///
  /// In en, this message translates to:
  /// **'REQUEST INFORMATION'**
  String get lockerRequestInformation;

  /// No description provided for @lockerPosSession.
  ///
  /// In en, this message translates to:
  /// **'POS SESSION'**
  String get lockerPosSession;

  /// No description provided for @lockerOpenedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened At'**
  String get lockerOpenedAt;

  /// No description provided for @lockerClosedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed At'**
  String get lockerClosedAt;

  /// No description provided for @lockerSessionStatus.
  ///
  /// In en, this message translates to:
  /// **'Session Status'**
  String get lockerSessionStatus;

  /// No description provided for @lockerReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received Amount'**
  String get lockerReceivedAmount;

  /// No description provided for @lockerNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get lockerNotes;

  /// No description provided for @lockerAuditFootnote.
  ///
  /// In en, this message translates to:
  /// **'This report is system-generated and serves as an official audit record.'**
  String get lockerAuditFootnote;

  /// No description provided for @lockerAuditFootnoteAmounts.
  ///
  /// In en, this message translates to:
  /// **'All amounts are in {currency}.'**
  String lockerAuditFootnoteAmounts(String currency);

  /// No description provided for @lockerCurrencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount}'**
  String lockerCurrencyPrefix(String currency, String amount);

  /// No description provided for @lockerSarCurrency.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get lockerSarCurrency;

  /// No description provided for @lockerLoadingVariance.
  ///
  /// In en, this message translates to:
  /// **'Loading variance approvals…'**
  String get lockerLoadingVariance;

  /// No description provided for @lockerFailedLoadVariance.
  ///
  /// In en, this message translates to:
  /// **'Failed to load variance approvals'**
  String get lockerFailedLoadVariance;

  /// No description provided for @lockerAllClear.
  ///
  /// In en, this message translates to:
  /// **'All Clear!'**
  String get lockerAllClear;

  /// No description provided for @lockerNoPendingVariance.
  ///
  /// In en, this message translates to:
  /// **'No pending variance approvals at this time.'**
  String get lockerNoPendingVariance;

  /// No description provided for @lockerVarianceReviewBanner.
  ///
  /// In en, this message translates to:
  /// **'These collections have a cash variance and require your approval.'**
  String get lockerVarianceReviewBanner;

  /// No description provided for @lockerShortLabel.
  ///
  /// In en, this message translates to:
  /// **'SHORT'**
  String get lockerShortLabel;

  /// No description provided for @lockerOverLabel.
  ///
  /// In en, this message translates to:
  /// **'OVER'**
  String get lockerOverLabel;

  /// No description provided for @lockerApproveVarianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Variance'**
  String get lockerApproveVarianceTitle;

  /// No description provided for @lockerApproveVarianceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve {type} variance of SAR {amount} for {branch}?'**
  String lockerApproveVarianceConfirm(
    String type,
    String amount,
    String branch,
  );

  /// No description provided for @lockerApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Variance approved successfully'**
  String get lockerApproveSuccess;

  /// No description provided for @lockerRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Variance rejected'**
  String get lockerRejectSuccess;

  /// No description provided for @lockerRejectVarianceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Variance'**
  String get lockerRejectVarianceDialogTitle;

  /// No description provided for @lockerRejectingFor.
  ///
  /// In en, this message translates to:
  /// **'Rejecting variance for {branch}.'**
  String lockerRejectingFor(String branch);

  /// No description provided for @lockerRejectionReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get lockerRejectionReasonOptional;

  /// No description provided for @lockerShortVariance.
  ///
  /// In en, this message translates to:
  /// **'SHORT'**
  String get lockerShortVariance;

  /// No description provided for @lockerOverVariance.
  ///
  /// In en, this message translates to:
  /// **'OVER'**
  String get lockerOverVariance;

  /// No description provided for @lockerCashierLabel.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get lockerCashierLabel;

  /// No description provided for @lockerOfficerLabel.
  ///
  /// In en, this message translates to:
  /// **'OFFICER'**
  String get lockerOfficerLabel;

  /// No description provided for @lockerExpected.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED'**
  String get lockerExpected;

  /// No description provided for @lockerReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED'**
  String get lockerReceivedLabel;

  /// No description provided for @lockerDiffLabel.
  ///
  /// In en, this message translates to:
  /// **'DIFF'**
  String get lockerDiffLabel;

  /// No description provided for @lockerRecordCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'RECORD COLLECTION'**
  String get lockerRecordCollectionTitle;

  /// No description provided for @lockerExpectedAmount.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED AMOUNT'**
  String get lockerExpectedAmount;

  /// No description provided for @lockerVerifiedReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED RECEIVED AMOUNT'**
  String get lockerVerifiedReceivedAmount;

  /// No description provided for @lockerLockedAmount.
  ///
  /// In en, this message translates to:
  /// **'LOCKED AMOUNT'**
  String get lockerLockedAmount;

  /// No description provided for @lockerReceivedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED AMOUNT'**
  String get lockerReceivedAmountLabel;

  /// No description provided for @lockerCollectionNotes.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION NOTES'**
  String get lockerCollectionNotes;

  /// No description provided for @lockerCollectionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any remarks or reason for difference…'**
  String get lockerCollectionNotesHint;

  /// No description provided for @lockerCollectionEvidence.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION EVIDENCE'**
  String get lockerCollectionEvidence;

  /// No description provided for @lockerCapturePhoto.
  ///
  /// In en, this message translates to:
  /// **'CAPTURE PHOTO'**
  String get lockerCapturePhoto;

  /// No description provided for @lockerAttachLogs.
  ///
  /// In en, this message translates to:
  /// **'ATTACH LOGS'**
  String get lockerAttachLogs;

  /// No description provided for @lockerConfirmFinalise.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM & FINALISE ASSET'**
  String get lockerConfirmFinalise;

  /// No description provided for @lockerSuccessPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'PENDING APPROVAL'**
  String get lockerSuccessPendingApproval;

  /// No description provided for @lockerSuccessCollectionRecorded.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION RECORDED'**
  String get lockerSuccessCollectionRecorded;

  /// No description provided for @lockerStatusReview.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get lockerStatusReview;

  /// No description provided for @lockerStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get lockerStatusOk;

  /// No description provided for @lockerStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get lockerStatusLabel;

  /// No description provided for @lockerDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get lockerDone;

  /// No description provided for @lockerNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get lockerNotificationsTitle;

  /// No description provided for @lockerSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get lockerSessionExpired;

  /// No description provided for @lockerSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get lockerSomethingWentWrong;

  /// No description provided for @lockerCouldNotRefresh.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh.'**
  String get lockerCouldNotRefresh;

  /// No description provided for @lockerNoNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get lockerNoNotificationsYet;

  /// No description provided for @lockerTryAgain.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get lockerTryAgain;

  /// No description provided for @lockerFinancialReports.
  ///
  /// In en, this message translates to:
  /// **'FINANCIAL REPORTS'**
  String get lockerFinancialReports;

  /// No description provided for @lockerTabHistory.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get lockerTabHistory;

  /// No description provided for @lockerTabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS'**
  String get lockerTabAnalytics;

  /// No description provided for @lockerSearchByRefOrOfficer.
  ///
  /// In en, this message translates to:
  /// **'Search by Ref or Officer…'**
  String get lockerSearchByRefOrOfficer;

  /// No description provided for @lockerAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'AUDIT LOGS'**
  String get lockerAuditLogs;

  /// No description provided for @lockerRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String lockerRecordsCount(int count);

  /// No description provided for @lockerExportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get lockerExportPdf;

  /// No description provided for @lockerExportExcel.
  ///
  /// In en, this message translates to:
  /// **'EXCEL'**
  String get lockerExportExcel;

  /// No description provided for @lockerDifferencesSummary.
  ///
  /// In en, this message translates to:
  /// **'DIFFERENCES SUMMARY'**
  String get lockerDifferencesSummary;

  /// No description provided for @lockerTotalShort.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SHORT'**
  String get lockerTotalShort;

  /// No description provided for @lockerTotalOver.
  ///
  /// In en, this message translates to:
  /// **'TOTAL OVER'**
  String get lockerTotalOver;

  /// No description provided for @lockerNetDifference.
  ///
  /// In en, this message translates to:
  /// **'NET DIFFERENCE'**
  String get lockerNetDifference;

  /// No description provided for @lockerTotalCollections.
  ///
  /// In en, this message translates to:
  /// **'TOTAL COLLECTIONS'**
  String get lockerTotalCollections;

  /// No description provided for @lockerMyCollectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'MY COLLECTION PERFORMANCE'**
  String get lockerMyCollectionPerformance;

  /// No description provided for @lockerCollectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION PERFORMANCE'**
  String get lockerCollectionPerformance;

  /// No description provided for @lockerOfficerComplianceRatings.
  ///
  /// In en, this message translates to:
  /// **'OFFICER COMPLIANCE RATINGS'**
  String get lockerOfficerComplianceRatings;

  /// No description provided for @lockerNoComplianceData.
  ///
  /// In en, this message translates to:
  /// **'No compliance data for this period.'**
  String get lockerNoComplianceData;

  /// No description provided for @lockerNoResultsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No results match your filters.'**
  String get lockerNoResultsMatchFilters;

  /// No description provided for @lockerNoAuditLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No audit logs found.'**
  String get lockerNoAuditLogsFound;

  /// No description provided for @lockerAnErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get lockerAnErrorOccurred;

  /// No description provided for @lockerAllRecords.
  ///
  /// In en, this message translates to:
  /// **'All records'**
  String get lockerAllRecords;

  /// No description provided for @lockerFilterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get lockerFilterSearch;

  /// No description provided for @lockerFilterBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get lockerFilterBranch;

  /// No description provided for @lockerFilterByBranch.
  ///
  /// In en, this message translates to:
  /// **'Filter by Branch…'**
  String get lockerFilterByBranch;

  /// No description provided for @lockerLoadingBranches.
  ///
  /// In en, this message translates to:
  /// **'Loading branches…'**
  String get lockerLoadingBranches;

  /// No description provided for @lockerSortBy.
  ///
  /// In en, this message translates to:
  /// **'SORT BY'**
  String get lockerSortBy;

  /// No description provided for @lockerSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get lockerSortDate;

  /// No description provided for @lockerSortReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received Amount'**
  String get lockerSortReceivedAmount;

  /// No description provided for @lockerSortDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get lockerSortDifference;

  /// No description provided for @lockerSortAsc.
  ///
  /// In en, this message translates to:
  /// **'ASC'**
  String get lockerSortAsc;

  /// No description provided for @lockerSortDesc.
  ///
  /// In en, this message translates to:
  /// **'DESC'**
  String get lockerSortDesc;

  /// No description provided for @lockerSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get lockerSelectDateRange;

  /// No description provided for @lockerDateFrom.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get lockerDateFrom;

  /// No description provided for @lockerDateTo.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get lockerDateTo;

  /// No description provided for @lockerTapToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get lockerTapToSet;

  /// No description provided for @lockerApplyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get lockerApplyFilter;

  /// No description provided for @lockerClearFilters.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get lockerClearFilters;

  /// No description provided for @lockerNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get lockerNoData;

  /// No description provided for @lockerWeeklyCollectionVolume.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY COLLECTION VOLUME'**
  String get lockerWeeklyCollectionVolume;

  /// No description provided for @lockerTransactionRef.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION REF'**
  String get lockerTransactionRef;

  /// No description provided for @lockerReceivedFundLabel.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED FUND'**
  String get lockerReceivedFundLabel;

  /// No description provided for @lockerOneCollection.
  ///
  /// In en, this message translates to:
  /// **'1 collection'**
  String get lockerOneCollection;

  /// No description provided for @lockerNCollections.
  ///
  /// In en, this message translates to:
  /// **'{count} collections'**
  String lockerNCollections(int count);

  /// No description provided for @lockerStoragePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get lockerStoragePermissionRequired;

  /// No description provided for @lockerStoragePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to save exported files. Please enable it in app settings.'**
  String get lockerStoragePermissionBody;

  /// No description provided for @lockerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get lockerOpenSettings;

  /// No description provided for @lockerFinancialHistoryPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Locker Financial History'**
  String get lockerFinancialHistoryPdfTitle;

  /// No description provided for @lockerPdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get lockerPdfGenerated;

  /// No description provided for @lockerPdfTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get lockerPdfTotal;

  /// No description provided for @lockerPdfRecords.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get lockerPdfRecords;

  /// No description provided for @lockerPdfRef.
  ///
  /// In en, this message translates to:
  /// **'REF'**
  String get lockerPdfRef;

  /// No description provided for @lockerPdfDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get lockerPdfDate;

  /// No description provided for @lockerPdfBranch.
  ///
  /// In en, this message translates to:
  /// **'BRANCH'**
  String get lockerPdfBranch;

  /// No description provided for @lockerPdfReceived.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED'**
  String get lockerPdfReceived;

  /// No description provided for @lockerPdfExpected.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED'**
  String get lockerPdfExpected;

  /// No description provided for @lockerPdfDiff.
  ///
  /// In en, this message translates to:
  /// **'DIFF'**
  String get lockerPdfDiff;

  /// No description provided for @lockerPdfStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get lockerPdfStatus;

  /// No description provided for @lockerPdfExportFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF export failed'**
  String get lockerPdfExportFailed;

  /// No description provided for @lockerExcelSheetName.
  ///
  /// In en, this message translates to:
  /// **'Locker History'**
  String get lockerExcelSheetName;

  /// No description provided for @lockerExcelOfficer.
  ///
  /// In en, this message translates to:
  /// **'Officer'**
  String get lockerExcelOfficer;

  /// No description provided for @lockerExcelReceivedSar.
  ///
  /// In en, this message translates to:
  /// **'Received (SAR)'**
  String get lockerExcelReceivedSar;

  /// No description provided for @lockerExcelExpectedSar.
  ///
  /// In en, this message translates to:
  /// **'Expected (SAR)'**
  String get lockerExcelExpectedSar;

  /// No description provided for @lockerExcelDiffSar.
  ///
  /// In en, this message translates to:
  /// **'Difference (SAR)'**
  String get lockerExcelDiffSar;

  /// No description provided for @lockerExcelRequestRef.
  ///
  /// In en, this message translates to:
  /// **'Request Ref'**
  String get lockerExcelRequestRef;

  /// No description provided for @lockerExcelExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Excel export failed'**
  String get lockerExcelExportFailed;

  /// No description provided for @accountingTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get accountingTitle;

  /// No description provided for @accountingTabPayables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get accountingTabPayables;

  /// No description provided for @accountingTabReceivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get accountingTabReceivables;

  /// No description provided for @accountingTabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get accountingTabExpenses;

  /// No description provided for @accountingTabAdvances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get accountingTabAdvances;

  /// No description provided for @accountingPayables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get accountingPayables;

  /// No description provided for @accountingReceivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get accountingReceivables;

  /// No description provided for @accountingOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get accountingOverdue;

  /// No description provided for @accountingNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries found'**
  String get accountingNoEntries;

  /// No description provided for @accountingRefPrefix.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref} • {date}'**
  String accountingRefPrefix(String ref, String date);

  /// No description provided for @accountingStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get accountingStatusOverdue;

  /// No description provided for @accountingStatusSettled.
  ///
  /// In en, this message translates to:
  /// **'SETTLED'**
  String get accountingStatusSettled;

  /// No description provided for @accountingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get accountingStatusPending;

  /// No description provided for @accountingLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load accounting data'**
  String get accountingLoadingError;

  /// No description provided for @accountingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String accountingAmountLabel(String amount);

  /// No description provided for @approvalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvalsTitle;

  /// No description provided for @approvalsQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get approvalsQueueLabel;

  /// No description provided for @approvalsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get approvalsStatusLabel;

  /// No description provided for @approvalsQueueAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get approvalsQueueAll;

  /// No description provided for @approvalsQueueTopUps.
  ///
  /// In en, this message translates to:
  /// **'Top-ups'**
  String get approvalsQueueTopUps;

  /// No description provided for @approvalsQueueExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get approvalsQueueExpenses;

  /// No description provided for @approvalsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get approvalsStatusAll;

  /// No description provided for @approvalsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get approvalsStatusPending;

  /// No description provided for @approvalsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvalsStatusApproved;

  /// No description provided for @approvalsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get approvalsStatusRejected;

  /// No description provided for @approvalsEmptyExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expense approvals'**
  String get approvalsEmptyExpenses;

  /// No description provided for @approvalsEmptyPettyCash.
  ///
  /// In en, this message translates to:
  /// **'No petty cash requests'**
  String get approvalsEmptyPettyCash;

  /// No description provided for @approvalsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No records for this queue and status.'**
  String get approvalsEmptySubtitle;

  /// No description provided for @approvalsNoAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found.'**
  String get approvalsNoAddressesFound;

  /// No description provided for @approvalsLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load approvals'**
  String get approvalsLoadingError;

  /// No description provided for @approvalsApproveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve this request?'**
  String get approvalsApproveConfirm;

  /// No description provided for @approvalsRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get approvalsRejectTitle;

  /// No description provided for @approvalsRejectHint.
  ///
  /// In en, this message translates to:
  /// **'Enter rejection reason (optional)'**
  String get approvalsRejectHint;

  /// No description provided for @approvalsConfirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get approvalsConfirmReject;

  /// No description provided for @approvalsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get approvalsCancel;

  /// No description provided for @ownerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Workshop Owner'**
  String get ownerLoginTitle;

  /// No description provided for @ownerLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your dashboard'**
  String get ownerLoginSubtitle;

  /// No description provided for @ownerLoginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ownerLoginEmail;

  /// No description provided for @ownerLoginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get ownerLoginEmailHint;

  /// No description provided for @ownerLoginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get ownerLoginEmailRequired;

  /// No description provided for @ownerLoginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get ownerLoginPassword;

  /// No description provided for @ownerLoginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get ownerLoginPasswordHint;

  /// No description provided for @ownerLoginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get ownerLoginPasswordRequired;

  /// No description provided for @ownerLoginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get ownerLoginForgotPassword;

  /// No description provided for @ownerLoginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get ownerLoginSignIn;

  /// No description provided for @ownerLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get ownerLoginSuccess;

  /// No description provided for @ownerLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get ownerLoginFailed;

  /// No description provided for @ownerLoginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get ownerLoginNoAccount;

  /// No description provided for @ownerRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get ownerRegisterTitle;

  /// No description provided for @ownerRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your workshop'**
  String get ownerRegisterSubtitle;

  /// No description provided for @ownerRegisterWorkshopName.
  ///
  /// In en, this message translates to:
  /// **'Workshop Name'**
  String get ownerRegisterWorkshopName;

  /// No description provided for @ownerRegisterWorkshopNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter workshop name'**
  String get ownerRegisterWorkshopNameHint;

  /// No description provided for @ownerRegisterOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerRegisterOwnerName;

  /// No description provided for @ownerRegisterOwnerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get ownerRegisterOwnerNameHint;

  /// No description provided for @ownerRegisterEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get ownerRegisterEmail;

  /// No description provided for @ownerRegisterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get ownerRegisterEmailHint;

  /// No description provided for @ownerRegisterMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get ownerRegisterMobile;

  /// No description provided for @ownerRegisterMobileHint.
  ///
  /// In en, this message translates to:
  /// **'+966...'**
  String get ownerRegisterMobileHint;

  /// No description provided for @ownerRegisterTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get ownerRegisterTaxId;

  /// No description provided for @ownerRegisterTaxIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Tax ID'**
  String get ownerRegisterTaxIdHint;

  /// No description provided for @ownerRegisterAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get ownerRegisterAddress;

  /// No description provided for @ownerRegisterAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Search and select full address'**
  String get ownerRegisterAddressHint;

  /// No description provided for @ownerRegisterPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get ownerRegisterPassword;

  /// No description provided for @ownerRegisterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get ownerRegisterPasswordHint;

  /// No description provided for @ownerRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get ownerRegisterButton;

  /// No description provided for @ownerRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please login.'**
  String get ownerRegisterSuccess;

  /// No description provided for @ownerRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get ownerRegisterFailed;

  /// No description provided for @ownerRegisterFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get ownerRegisterFieldRequired;

  /// No description provided for @ownerRegisterHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get ownerRegisterHaveAccount;

  /// No description provided for @corporateManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Corporate Management'**
  String get corporateManagementTitle;

  /// No description provided for @corporateSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Company or VAT...'**
  String get corporateSearchHint;

  /// No description provided for @corporateAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Corporate'**
  String get corporateAddButton;

  /// No description provided for @corporateNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No corporate customers found.'**
  String get corporateNoneFound;

  /// No description provided for @corporateVatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT: {vat}'**
  String corporateVatLabel(String vat);

  /// No description provided for @corporateVehiclesLabel.
  ///
  /// In en, this message translates to:
  /// **'VEHICLES'**
  String get corporateVehiclesLabel;

  /// No description provided for @corporateRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'REVENUE'**
  String get corporateRevenueLabel;

  /// No description provided for @corporateAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get corporateAddUser;

  /// No description provided for @corporateEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get corporateEdit;

  /// No description provided for @corporateRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Corporate Partner'**
  String get corporateRegisterTitle;

  /// No description provided for @corporateRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details to create a new corporate account.'**
  String get corporateRegisterSubtitle;

  /// No description provided for @corporateFieldCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get corporateFieldCompanyName;

  /// No description provided for @corporateFieldCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get corporateFieldCustomerName;

  /// No description provided for @corporateFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get corporateFieldMobile;

  /// No description provided for @corporateFieldVat.
  ///
  /// In en, this message translates to:
  /// **'VAT Number'**
  String get corporateFieldVat;

  /// No description provided for @corporateFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get corporateFieldEmail;

  /// No description provided for @corporateFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get corporateFieldPassword;

  /// No description provided for @corporateFieldReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get corporateFieldReferral;

  /// No description provided for @corporateSelectBranches.
  ///
  /// In en, this message translates to:
  /// **'Select Branches'**
  String get corporateSelectBranches;

  /// No description provided for @corporateSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String corporateSelectedCount(int count);

  /// No description provided for @corporateNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches found'**
  String get corporateNoBranches;

  /// No description provided for @corporateCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Partner'**
  String get corporateCreateButton;

  /// No description provided for @corporateAddUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Corporate User'**
  String get corporateAddUserTitle;

  /// No description provided for @corporateAddUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create credentials for a user associated with this corporate account.'**
  String get corporateAddUserSubtitle;

  /// No description provided for @corporateUserFieldName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get corporateUserFieldName;

  /// No description provided for @corporateUserFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get corporateUserFieldEmail;

  /// No description provided for @corporateUserFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get corporateUserFieldPassword;

  /// No description provided for @corporateCreateUserButton.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get corporateCreateUserButton;

  /// No description provided for @corporateEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Corporate Account'**
  String get corporateEditTitle;

  /// No description provided for @corporateEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the details below. Only changed fields will be sent.'**
  String get corporateEditSubtitle;

  /// No description provided for @invTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory & Products'**
  String get invTitle;

  /// No description provided for @invTabProducts.
  ///
  /// In en, this message translates to:
  /// **'PRODUCTS'**
  String get invTabProducts;

  /// No description provided for @invTabServices.
  ///
  /// In en, this message translates to:
  /// **'SERVICES'**
  String get invTabServices;

  /// No description provided for @invTabCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get invTabCategory;

  /// No description provided for @invAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get invAddProduct;

  /// No description provided for @invAddService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get invAddService;

  /// No description provided for @invAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get invAddCategory;

  /// No description provided for @invAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get invAdd;

  /// No description provided for @invSearchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or category...'**
  String get invSearchProductsHint;

  /// No description provided for @invSearchServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get invSearchServicesHint;

  /// No description provided for @invSearchCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get invSearchCategoriesHint;

  /// No description provided for @invNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get invNoProductsFound;

  /// No description provided for @invNoServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found.'**
  String get invNoServicesFound;

  /// No description provided for @invNoCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get invNoCategoriesFound;

  /// No description provided for @invNoProductsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No products found matching your search.'**
  String get invNoProductsMatchSearch;

  /// No description provided for @invNoServicesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No services found matching your search.'**
  String get invNoServicesMatchSearch;

  /// No description provided for @invNoCategoriesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No categories found matching your search.'**
  String get invNoCategoriesMatchSearch;

  /// No description provided for @invMetricStock.
  ///
  /// In en, this message translates to:
  /// **'STOCK'**
  String get invMetricStock;

  /// No description provided for @invMetricPurchase.
  ///
  /// In en, this message translates to:
  /// **'PURCHASE'**
  String get invMetricPurchase;

  /// No description provided for @invMetricRetail.
  ///
  /// In en, this message translates to:
  /// **'RETAIL'**
  String get invMetricRetail;

  /// No description provided for @invMetricPrice.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get invMetricPrice;

  /// No description provided for @invMetricCorpRange.
  ///
  /// In en, this message translates to:
  /// **'CORP RANGE'**
  String get invMetricCorpRange;

  /// No description provided for @invMetricCorporate.
  ///
  /// In en, this message translates to:
  /// **'CORPORATE'**
  String get invMetricCorporate;

  /// No description provided for @invEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get invEditTooltip;

  /// No description provided for @invDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get invDeleteTooltip;

  /// No description provided for @invMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get invMenuEdit;

  /// No description provided for @invMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get invMenuDelete;

  /// No description provided for @invConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get invConfirmDeleteTitle;

  /// No description provided for @invConfirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String invConfirmDeleteBody(String name);

  /// No description provided for @invCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get invCancel;

  /// No description provided for @invConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get invConfirm;

  /// No description provided for @invCategoryTabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get invCategoryTabProducts;

  /// No description provided for @invCategoryTabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get invCategoryTabServices;

  /// No description provided for @invCreateProduct.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get invCreateProduct;

  /// No description provided for @invUpdateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get invUpdateProduct;

  /// No description provided for @invCreateProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter product details to add to inventory.'**
  String get invCreateProductSubtitle;

  /// No description provided for @invUpdateProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify existing product details.'**
  String get invUpdateProductSubtitle;

  /// No description provided for @invFieldBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get invFieldBranch;

  /// No description provided for @invFieldDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get invFieldDepartment;

  /// No description provided for @invFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get invFieldCategory;

  /// No description provided for @invFieldProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get invFieldProductName;

  /// No description provided for @invFieldStockQty.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get invFieldStockQty;

  /// No description provided for @invFieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get invFieldUnit;

  /// No description provided for @invFieldCriticalStock.
  ///
  /// In en, this message translates to:
  /// **'Critical Stock Point'**
  String get invFieldCriticalStock;

  /// No description provided for @invSectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing Details'**
  String get invSectionPricing;

  /// No description provided for @invFieldPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get invFieldPurchasePrice;

  /// No description provided for @invFieldSalePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get invFieldSalePrice;

  /// No description provided for @invFieldMinCorpPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Corp Price'**
  String get invFieldMinCorpPrice;

  /// No description provided for @invFieldMaxCorpPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Corp Price'**
  String get invFieldMaxCorpPrice;

  /// No description provided for @invToggleDecimal.
  ///
  /// In en, this message translates to:
  /// **'Allow Decimal Point'**
  String get invToggleDecimal;

  /// No description provided for @invToggleActive.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get invToggleActive;

  /// No description provided for @invSaveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get invSaveProduct;

  /// No description provided for @invProductCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product Created Successfully'**
  String get invProductCreateSuccess;

  /// No description provided for @invProductUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product Updated Successfully'**
  String get invProductUpdateSuccess;

  /// No description provided for @invProductCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create product'**
  String get invProductCreateError;

  /// No description provided for @invProductDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product Deleted Successfully'**
  String get invProductDeleteSuccess;

  /// No description provided for @invProductDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product'**
  String get invProductDeleteError;

  /// No description provided for @invValidationFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get invValidationFillRequired;

  /// No description provided for @invValidationSelectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Please select a department.'**
  String get invValidationSelectDepartment;

  /// No description provided for @invValidationCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Please create a category first.'**
  String get invValidationCreateCategory;

  /// No description provided for @invValidationSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Please select a branch.'**
  String get invValidationSelectBranch;

  /// No description provided for @invCreateService.
  ///
  /// In en, this message translates to:
  /// **'Create Service'**
  String get invCreateService;

  /// No description provided for @invUpdateService.
  ///
  /// In en, this message translates to:
  /// **'Update Service'**
  String get invUpdateService;

  /// No description provided for @invCreateServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter service details.'**
  String get invCreateServiceSubtitle;

  /// No description provided for @invUpdateServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify existing service details.'**
  String get invUpdateServiceSubtitle;

  /// No description provided for @invFieldServiceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get invFieldServiceName;

  /// No description provided for @invFieldServicePrice.
  ///
  /// In en, this message translates to:
  /// **'Service Price'**
  String get invFieldServicePrice;

  /// No description provided for @invTogglePriceEditable.
  ///
  /// In en, this message translates to:
  /// **'Cashier can change price on POS'**
  String get invTogglePriceEditable;

  /// No description provided for @invSaveService.
  ///
  /// In en, this message translates to:
  /// **'Save Service'**
  String get invSaveService;

  /// No description provided for @invServiceCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service Created Successfully'**
  String get invServiceCreateSuccess;

  /// No description provided for @invServiceUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service Updated Successfully'**
  String get invServiceUpdateSuccess;

  /// No description provided for @invServiceCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create service'**
  String get invServiceCreateError;

  /// No description provided for @invServiceDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service Deleted Successfully'**
  String get invServiceDeleteSuccess;

  /// No description provided for @invServiceDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete service'**
  String get invServiceDeleteError;

  /// No description provided for @invValidationFillServiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in required fields.'**
  String get invValidationFillServiceRequired;

  /// No description provided for @invCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get invCreateCategory;

  /// No description provided for @invUpdateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update Category'**
  String get invUpdateCategory;

  /// No description provided for @invCreateCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter details for the new category.'**
  String get invCreateCategorySubtitle;

  /// No description provided for @invUpdateCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify existing category details.'**
  String get invUpdateCategorySubtitle;

  /// No description provided for @invFieldCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get invFieldCategoryName;

  /// No description provided for @invSaveCategory.
  ///
  /// In en, this message translates to:
  /// **'Save Category'**
  String get invSaveCategory;

  /// No description provided for @invCategoryCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category Created Successfully'**
  String get invCategoryCreateSuccess;

  /// No description provided for @invCategoryUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category Updated Successfully'**
  String get invCategoryUpdateSuccess;

  /// No description provided for @invCategoryCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create category'**
  String get invCategoryCreateError;

  /// No description provided for @invCategoryDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category Deleted Successfully'**
  String get invCategoryDeleteSuccess;

  /// No description provided for @invCategoryDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get invCategoryDeleteError;

  /// No description provided for @invCreateSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Sub Category'**
  String get invCreateSubCategory;

  /// No description provided for @invCreateSubCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter details for the new sub category.'**
  String get invCreateSubCategorySubtitle;

  /// No description provided for @invFieldSubCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Sub Category Name'**
  String get invFieldSubCategoryName;

  /// No description provided for @invSaveSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Save Sub Category'**
  String get invSaveSubCategory;

  /// No description provided for @invSubCategoryCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sub Category Created Successfully'**
  String get invSubCategoryCreateSuccess;

  /// No description provided for @invSubCategoryUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sub Category Updated Successfully'**
  String get invSubCategoryUpdateSuccess;

  /// No description provided for @invSubCategoryCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create sub category'**
  String get invSubCategoryCreateError;

  /// No description provided for @invSubCategoryDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sub Category Deleted Successfully'**
  String get invSubCategoryDeleteSuccess;

  /// No description provided for @invSubCategoryDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete sub category'**
  String get invSubCategoryDeleteError;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notifMarkRead;

  /// No description provided for @notifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notifEmpty;

  /// No description provided for @notifTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m}m ago'**
  String notifTimeMinutes(int m);

  /// No description provided for @notifTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{h}h ago'**
  String notifTimeHours(int h);

  /// No description provided for @notifTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{d}d ago'**
  String notifTimeDays(int d);

  /// No description provided for @notifTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'expense'**
  String get notifTypeExpense;

  /// No description provided for @notifTypeStock.
  ///
  /// In en, this message translates to:
  /// **'stock'**
  String get notifTypeStock;

  /// No description provided for @notifTypePayment.
  ///
  /// In en, this message translates to:
  /// **'payment'**
  String get notifTypePayment;

  /// No description provided for @notifTypeLocker.
  ///
  /// In en, this message translates to:
  /// **'locker'**
  String get notifTypeLocker;

  /// No description provided for @notifTypeInvoice.
  ///
  /// In en, this message translates to:
  /// **'invoice'**
  String get notifTypeInvoice;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsTitle;

  /// No description provided for @reportsFinancialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get reportsFinancialOverview;

  /// No description provided for @reportsOperationalPerformance.
  ///
  /// In en, this message translates to:
  /// **'Operational Performance'**
  String get reportsOperationalPerformance;

  /// No description provided for @reportsInventoryValuation.
  ///
  /// In en, this message translates to:
  /// **'Inventory Valuation'**
  String get reportsInventoryValuation;

  /// No description provided for @reportsTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get reportsTotalRevenue;

  /// No description provided for @reportsNoDataThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No data for this week'**
  String get reportsNoDataThisWeek;

  /// No description provided for @reportsTotalJobs.
  ///
  /// In en, this message translates to:
  /// **'Total Jobs: {count}'**
  String reportsTotalJobs(int count);

  /// No description provided for @reportsCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get reportsCommissionLabel;

  /// No description provided for @reportsStockValueCost.
  ///
  /// In en, this message translates to:
  /// **'Stock Value (Cost)'**
  String get reportsStockValueCost;

  /// No description provided for @reportsPotentialProfit.
  ///
  /// In en, this message translates to:
  /// **'Potential Profit'**
  String get reportsPotentialProfit;

  /// No description provided for @reportsActiveSkus.
  ///
  /// In en, this message translates to:
  /// **'Active SKUs'**
  String get reportsActiveSkus;

  /// No description provided for @reportsItemsUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} Items'**
  String reportsItemsUnit(int count);

  /// No description provided for @reportsAmountSar.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String reportsAmountSar(String amount);

  /// No description provided for @reportsNoOperationalData.
  ///
  /// In en, this message translates to:
  /// **'No operational performance data'**
  String get reportsNoOperationalData;

  /// No description provided for @reportsRevChangePositive.
  ///
  /// In en, this message translates to:
  /// **'+{pct}%'**
  String reportsRevChangePositive(String pct);

  /// No description provided for @reportsRevChangeNegative.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String reportsRevChangeNegative(String pct);

  /// No description provided for @posCurrentShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Shift'**
  String get posCurrentShiftTitle;

  /// No description provided for @posCurrentShiftDetails.
  ///
  /// In en, this message translates to:
  /// **'SHIFT DETAILS'**
  String get posCurrentShiftDetails;

  /// No description provided for @posCurrentShiftNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session.'**
  String get posCurrentShiftNoActiveSession;

  /// No description provided for @posCurrentShiftNoActiveShiftFound.
  ///
  /// In en, this message translates to:
  /// **'No active shift found.'**
  String get posCurrentShiftNoActiveShiftFound;

  /// No description provided for @posCurrentShiftRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posCurrentShiftRetry;

  /// No description provided for @posCurrentShiftSessionExpiredError.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get posCurrentShiftSessionExpiredError;

  /// No description provided for @posCurrentShiftFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch shift details: {error}'**
  String posCurrentShiftFetchError(String error);

  /// No description provided for @posCurrentShiftLabelCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get posCurrentShiftLabelCashier;

  /// No description provided for @posCurrentShiftLabelSessionId.
  ///
  /// In en, this message translates to:
  /// **'Session ID'**
  String get posCurrentShiftLabelSessionId;

  /// No description provided for @posCurrentShiftLabelBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get posCurrentShiftLabelBranch;

  /// No description provided for @posCurrentShiftLabelElapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed Time'**
  String get posCurrentShiftLabelElapsedTime;

  /// No description provided for @posCurrentShiftLabelOpenedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened At'**
  String get posCurrentShiftLabelOpenedAt;

  /// No description provided for @posCurrentShiftLabelBranchAddress.
  ///
  /// In en, this message translates to:
  /// **'Branch Address'**
  String get posCurrentShiftLabelBranchAddress;

  /// No description provided for @posBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'BROADCAST'**
  String get posBroadcastTitle;

  /// No description provided for @posBroadcastHeading.
  ///
  /// In en, this message translates to:
  /// **'Technician broadcasts'**
  String get posBroadcastHeading;

  /// No description provided for @posBroadcastNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active broadcasts'**
  String get posBroadcastNoActive;

  /// No description provided for @posBroadcastCountActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active · {window} per item'**
  String posBroadcastCountActive(int count, String window);

  /// No description provided for @posBroadcastRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posBroadcastRetry;

  /// No description provided for @posBroadcastLabelSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get posBroadcastLabelSoon;

  /// No description provided for @posBroadcastLabelClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get posBroadcastLabelClosed;

  /// No description provided for @posBroadcastLabelRemaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get posBroadcastLabelRemaining;

  /// No description provided for @posBroadcastLabelExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get posBroadcastLabelExpired;

  /// No description provided for @posBroadcastWindow.
  ///
  /// In en, this message translates to:
  /// **'{m}:{s} window'**
  String posBroadcastWindow(String m, String s);

  /// No description provided for @posBroadcastTypeOnCall.
  ///
  /// In en, this message translates to:
  /// **'On call'**
  String get posBroadcastTypeOnCall;

  /// No description provided for @posBroadcastTypeWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get posBroadcastTypeWorkshop;

  /// No description provided for @posBroadcastSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get posBroadcastSessionExpired;

  /// No description provided for @posCorporateBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Corporate Bookings'**
  String get posCorporateBookingsTitle;

  /// No description provided for @posCorporateFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posCorporateFilterAll;

  /// No description provided for @posCorporateFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get posCorporateFilterToday;

  /// No description provided for @posCorporateFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posCorporateFilterPending;

  /// No description provided for @posCorporateFilterApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get posCorporateFilterApprove;

  /// No description provided for @posCorporateFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get posCorporateFilterCancelled;

  /// No description provided for @posCorporateSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search plate, booking code, company...'**
  String get posCorporateSearchHint;

  /// No description provided for @posCorporateNoBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Bookings Found'**
  String get posCorporateNoBookingsTitle;

  /// No description provided for @posCorporateNoBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no corporate bookings for the selected filter.'**
  String get posCorporateNoBookingsSubtitle;

  /// No description provided for @posCorporateCardLabelVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get posCorporateCardLabelVehicle;

  /// No description provided for @posCorporateCardLabelPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get posCorporateCardLabelPlate;

  /// No description provided for @posCorporateCardLabelDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get posCorporateCardLabelDepartment;

  /// No description provided for @posCorporateCardLabelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get posCorporateCardLabelDate;

  /// No description provided for @posCorporateCardLabelCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get posCorporateCardLabelCompany;

  /// No description provided for @posCorporateActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get posCorporateActionDetails;

  /// No description provided for @posCorporateActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get posCorporateActionReject;

  /// No description provided for @posCorporateActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get posCorporateActionApprove;

  /// No description provided for @posCorporateActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get posCorporateActionContinue;

  /// No description provided for @posCorporateActionApproveBooking.
  ///
  /// In en, this message translates to:
  /// **'Approve Booking'**
  String get posCorporateActionApproveBooking;

  /// No description provided for @posCorporateActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get posCorporateActionClose;

  /// No description provided for @posCorporateActionSubmitReason.
  ///
  /// In en, this message translates to:
  /// **'Submit Reason'**
  String get posCorporateActionSubmitReason;

  /// No description provided for @posCorporateActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posCorporateActionCancel;

  /// No description provided for @posCorporateDialogDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Corporate Booking Details'**
  String get posCorporateDialogDetailsTitle;

  /// No description provided for @posCorporateDialogRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get posCorporateDialogRejectTitle;

  /// No description provided for @posCorporateDialogRejectBody.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason to {action} this booking for {company}. This information will be sent back to the corporate portal.'**
  String posCorporateDialogRejectBody(String action, String company);

  /// No description provided for @posCorporateDialogReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get posCorporateDialogReasonLabel;

  /// No description provided for @posCorporateDialogReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your reason here...'**
  String get posCorporateDialogReasonHint;

  /// No description provided for @posCorporateDialogReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason to {action}.'**
  String posCorporateDialogReasonRequired(String action);

  /// No description provided for @posCorporateDetailsSectionBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get posCorporateDetailsSectionBooking;

  /// No description provided for @posCorporateDetailsSectionVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get posCorporateDetailsSectionVehicle;

  /// No description provided for @posCorporateDetailsSectionProducts.
  ///
  /// In en, this message translates to:
  /// **'Requested Products'**
  String get posCorporateDetailsSectionProducts;

  /// No description provided for @posCorporateDetailsBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get posCorporateDetailsBookingId;

  /// No description provided for @posCorporateDetailsScheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time'**
  String get posCorporateDetailsScheduledTime;

  /// No description provided for @posCorporateDetailsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get posCorporateDetailsDepartment;

  /// No description provided for @posCorporateDetailsRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get posCorporateDetailsRejectionReason;

  /// No description provided for @posCorporateDetailsVehicleName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Name'**
  String get posCorporateDetailsVehicleName;

  /// No description provided for @posCorporateDetailsLicensePlate.
  ///
  /// In en, this message translates to:
  /// **'License Plate'**
  String get posCorporateDetailsLicensePlate;

  /// No description provided for @posCorporateDetailsNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No specific products requested. Open matching department.'**
  String get posCorporateDetailsNoProducts;

  /// No description provided for @posCorporateDetailsQty.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String posCorporateDetailsQty(String qty);

  /// No description provided for @posCorporateDetailsProductId.
  ///
  /// In en, this message translates to:
  /// **'Product ID: {id}'**
  String posCorporateDetailsProductId(String id);

  /// No description provided for @posCorporateApproveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve booking'**
  String get posCorporateApproveError;

  /// No description provided for @posCorporateRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking Rejected. Portal updated.'**
  String get posCorporateRejectSuccess;

  /// No description provided for @posCorporateRejectError.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject booking'**
  String get posCorporateRejectError;

  /// No description provided for @posCorporateNoMatchingOrder.
  ///
  /// In en, this message translates to:
  /// **'No matching order found for this booking yet. Please refresh and try again.'**
  String get posCorporateNoMatchingOrder;

  /// No description provided for @posCorporateLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bookings'**
  String get posCorporateLoadError;

  /// No description provided for @posCorporateAuthTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found'**
  String get posCorporateAuthTokenNotFound;

  /// No description provided for @posCorporateStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get posCorporateStatusCancelled;

  /// No description provided for @posCorporateStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get posCorporateStatusRejected;

  /// No description provided for @posCorporateStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posCorporateStatusPending;

  /// No description provided for @posCorporateStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get posCorporateStatusApproved;

  /// No description provided for @posCorporateStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get posCorporateStatusInProgress;

  /// No description provided for @posCorporateStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get posCorporateStatusCompleted;

  /// No description provided for @posCorporateStatusWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting Approval'**
  String get posCorporateStatusWaitingApproval;

  /// No description provided for @posBroadcastActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get posBroadcastActionReject;

  /// No description provided for @ownerCommonSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get ownerCommonSearchHint;

  /// No description provided for @ownerBottomHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get ownerBottomHome;

  /// No description provided for @ownerBottomReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get ownerBottomReports;

  /// No description provided for @ownerBottomBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get ownerBottomBilling;

  /// No description provided for @ownerBottomProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get ownerBottomProfile;

  /// No description provided for @ownerDashboardRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'WORKSHOP OWNER'**
  String get ownerDashboardRoleLabel;

  /// No description provided for @ownerMonthlySales.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales'**
  String get ownerMonthlySales;

  /// No description provided for @ownerCurrencySar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get ownerCurrencySar;

  /// No description provided for @ownerCurrencyAmount.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount}'**
  String ownerCurrencyAmount(String currency, String amount);

  /// No description provided for @pettyCashQueueCashierExpense.
  ///
  /// In en, this message translates to:
  /// **'CASHIER EXPENSE'**
  String get pettyCashQueueCashierExpense;

  /// No description provided for @pettyCashQueueFundRequest.
  ///
  /// In en, this message translates to:
  /// **'FUND REQUEST'**
  String get pettyCashQueueFundRequest;

  /// No description provided for @pettyCashRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Petty cash request'**
  String get pettyCashRequestLabel;

  /// No description provided for @pettyCashApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get pettyCashApprove;

  /// No description provided for @pettyCashReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get pettyCashReject;

  /// No description provided for @pettyCashConfirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get pettyCashConfirmReject;

  /// No description provided for @pettyCashRejectRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get pettyCashRejectRequestTitle;

  /// No description provided for @pettyCashRejectRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection.'**
  String get pettyCashRejectRequestBody;

  /// No description provided for @pettyCashRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Budget not approved'**
  String get pettyCashRejectReasonHint;

  /// No description provided for @pettyCashRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a rejection reason'**
  String get pettyCashRejectReasonRequired;

  /// No description provided for @pettyCashRequestApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request approved successfully'**
  String get pettyCashRequestApprovedSuccess;

  /// No description provided for @pettyCashRequestApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve request'**
  String get pettyCashRequestApproveFailed;

  /// No description provided for @pettyCashRequestRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request rejected successfully'**
  String get pettyCashRequestRejectedSuccess;

  /// No description provided for @pettyCashRequestRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject request'**
  String get pettyCashRequestRejectFailed;

  /// No description provided for @pettyCashStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pettyCashStatusPending;

  /// No description provided for @pettyCashStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get pettyCashStatusApproved;

  /// No description provided for @pettyCashStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get pettyCashStatusRejected;

  /// No description provided for @pettyCashStatusFallback.
  ///
  /// In en, this message translates to:
  /// **'{status}'**
  String pettyCashStatusFallback(String status);

  /// No description provided for @posLoginAppName.
  ///
  /// In en, this message translates to:
  /// **'POS System'**
  String get posLoginAppName;

  /// No description provided for @posLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get posLoginTitle;

  /// No description provided for @posLoginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get posLoginEmail;

  /// No description provided for @posLoginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get posLoginEmailHint;

  /// No description provided for @posLoginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get posLoginEmailRequired;

  /// No description provided for @posLoginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get posLoginPassword;

  /// No description provided for @posLoginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get posLoginPasswordHint;

  /// No description provided for @posLoginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get posLoginPasswordRequired;

  /// No description provided for @posLoginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get posLoginForgotPassword;

  /// No description provided for @posLoginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get posLoginSignIn;

  /// No description provided for @posLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get posLoginSuccess;

  /// No description provided for @posLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get posLoginFailed;

  /// No description provided for @posLoginResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get posLoginResetPasswordTitle;

  /// No description provided for @posLoginResetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or mobile number and we\'ll send you a reset link.'**
  String get posLoginResetPasswordSubtitle;

  /// No description provided for @posLoginResetPasswordEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get posLoginResetPasswordEmailLabel;

  /// No description provided for @posLoginResetPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get posLoginResetPasswordEmailHint;

  /// No description provided for @posLoginResetPasswordSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get posLoginResetPasswordSendButton;

  /// No description provided for @posLoginResetPasswordSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your inbox.'**
  String get posLoginResetPasswordSentSuccess;

  /// No description provided for @posLoginPreviousShiftAutoClosed.
  ///
  /// In en, this message translates to:
  /// **'Previous shift was automatically closed. New shift started.'**
  String get posLoginPreviousShiftAutoClosed;

  /// No description provided for @posLoginSessionExpiredError.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get posLoginSessionExpiredError;

  /// No description provided for @posYourJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Jobs'**
  String get posYourJobsTitle;

  /// No description provided for @posYourJobsNoDepartments.
  ///
  /// In en, this message translates to:
  /// **'No departments selected.'**
  String get posYourJobsNoDepartments;

  /// No description provided for @posYourJobsDeptInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Department-wise Invoice'**
  String get posYourJobsDeptInvoiceTitle;

  /// No description provided for @posYourJobsItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String posYourJobsItems(int count);

  /// No description provided for @posYourJobsGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get posYourJobsGrandTotal;

  /// No description provided for @posYourJobsSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get posYourJobsSaveDraft;

  /// No description provided for @posYourJobsPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get posYourJobsPlaceOrder;

  /// No description provided for @posYourJobsAssignTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Assign Technicians'**
  String get posYourJobsAssignTechnicians;

  /// No description provided for @posYourJobsAddInventory.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory'**
  String get posYourJobsAddInventory;

  /// No description provided for @posYourJobsAmountSar.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String posYourJobsAmountSar(String amount);

  /// No description provided for @posInvSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Sales'**
  String get posInvSalesTitle;

  /// No description provided for @posInvSalesRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get posInvSalesRefreshTooltip;

  /// No description provided for @posInvSalesPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get posInvSalesPeriodLabel;

  /// No description provided for @posInvSalesPresetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get posInvSalesPresetToday;

  /// No description provided for @posInvSalesPresetYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get posInvSalesPresetYesterday;

  /// No description provided for @posInvSalesPresetLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get posInvSalesPresetLast7;

  /// No description provided for @posInvSalesPresetLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get posInvSalesPresetLast30;

  /// No description provided for @posInvSalesPresetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get posInvSalesPresetThisMonth;

  /// No description provided for @posInvSalesPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get posInvSalesPresetCustom;

  /// No description provided for @posInvSalesFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From (y-MM-dd)'**
  String get posInvSalesFromLabel;

  /// No description provided for @posInvSalesToLabel.
  ///
  /// In en, this message translates to:
  /// **'To (y-MM-dd)'**
  String get posInvSalesToLabel;

  /// No description provided for @posInvSalesLoadButton.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get posInvSalesLoadButton;

  /// No description provided for @posInvSalesLoadingButton.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get posInvSalesLoadingButton;

  /// No description provided for @posInvSalesStatTotalUnits.
  ///
  /// In en, this message translates to:
  /// **'Total units sold'**
  String get posInvSalesStatTotalUnits;

  /// No description provided for @posInvSalesStatUniqueProducts.
  ///
  /// In en, this message translates to:
  /// **'Unique products'**
  String get posInvSalesStatUniqueProducts;

  /// No description provided for @posInvSalesStatDaysActive.
  ///
  /// In en, this message translates to:
  /// **'Days with activity'**
  String get posInvSalesStatDaysActive;

  /// No description provided for @posInvSalesDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get posInvSalesDismissTooltip;

  /// No description provided for @posInvSalesNoSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get posInvSalesNoSalesTitle;

  /// No description provided for @posInvSalesNoSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'API returned successfully with no matching lines (200 + empty list).'**
  String get posInvSalesNoSalesSubtitle;

  /// No description provided for @posInvSalesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posInvSalesRetry;

  /// No description provided for @posInvSalesColProduct.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT'**
  String get posInvSalesColProduct;

  /// No description provided for @posInvSalesColSku.
  ///
  /// In en, this message translates to:
  /// **'SKU / CODE'**
  String get posInvSalesColSku;

  /// No description provided for @posInvSalesColQty.
  ///
  /// In en, this message translates to:
  /// **'SOLD QTY'**
  String get posInvSalesColQty;

  /// No description provided for @posInvSalesDayLines.
  ///
  /// In en, this message translates to:
  /// **'{count} line'**
  String posInvSalesDayLines(int count);

  /// No description provided for @posInvSalesDayLinesPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String posInvSalesDayLinesPlural(int count);

  /// No description provided for @posInvSalesDaySummary.
  ///
  /// In en, this message translates to:
  /// **'{lines} · {qty} units'**
  String posInvSalesDaySummary(String lines, String qty);

  /// No description provided for @posInvSalesSessionExpiredError.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get posInvSalesSessionExpiredError;

  /// No description provided for @posInvSalesErrStartBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'Start date must be on or before end date.'**
  String get posInvSalesErrStartBeforeEnd;

  /// No description provided for @posInvSalesErrRangeExceeded.
  ///
  /// In en, this message translates to:
  /// **'Date range cannot exceed {days} days.'**
  String posInvSalesErrRangeExceeded(int days);

  /// No description provided for @moreMenuPettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get moreMenuPettyCash;

  /// No description provided for @moreMenuPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get moreMenuPromoCode;

  /// No description provided for @moreMenuStoreClosing.
  ///
  /// In en, this message translates to:
  /// **'Store Closing'**
  String get moreMenuStoreClosing;

  /// No description provided for @moreMenuSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Sales Return'**
  String get moreMenuSalesReturn;

  /// No description provided for @posOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get posOrdersTitle;

  /// No description provided for @posOrdersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get posOrdersSearchHint;

  /// No description provided for @posOrdersTabletSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search plate, name, ID...'**
  String get posOrdersTabletSearchHint;

  /// No description provided for @posOrdersTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posOrdersTabAll;

  /// No description provided for @posOrdersTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posOrdersTabPending;

  /// No description provided for @posOrdersTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get posOrdersTabCompleted;

  /// No description provided for @posOrdersNoOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get posOrdersNoOrdersFound;

  /// No description provided for @posOrdersSearchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No orders match your search.'**
  String get posOrdersSearchNoMatch;

  /// No description provided for @posOrdersNoPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'No pending orders found'**
  String get posOrdersNoPendingOrders;

  /// No description provided for @posOrdersNoCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'No completed orders found'**
  String get posOrdersNoCompletedOrders;

  /// No description provided for @posOrdersNewOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get posOrdersNewOrder;

  /// No description provided for @posOrdersNoOrderSelected.
  ///
  /// In en, this message translates to:
  /// **'No Order Selected'**
  String get posOrdersNoOrderSelected;

  /// No description provided for @posOrdersSelectFromList.
  ///
  /// In en, this message translates to:
  /// **'Select an order from the list on the left to view details'**
  String get posOrdersSelectFromList;

  /// No description provided for @posOrdersAddDepartment.
  ///
  /// In en, this message translates to:
  /// **'ADD DEPARTMENT'**
  String get posOrdersAddDepartment;

  /// No description provided for @posOrdersAddCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Add customer details'**
  String get posOrdersAddCustomerDetails;

  /// No description provided for @posOrdersSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get posOrdersSelectPaymentMethod;

  /// No description provided for @posOrdersSelectYourPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select your payment method'**
  String get posOrdersSelectYourPaymentMethod;

  /// No description provided for @posOrdersCustomerDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer details saved'**
  String get posOrdersCustomerDetailsSaved;

  /// No description provided for @posOrdersPaymentMethodSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get posOrdersPaymentMethodSaved;

  /// No description provided for @posOrdersStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get posOrdersStatusRejected;

  /// No description provided for @posOrdersStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get posOrdersStatusCancelled;

  /// No description provided for @posOrdersStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE'**
  String get posOrdersStatusComplete;

  /// No description provided for @posOrdersStatusEdited.
  ///
  /// In en, this message translates to:
  /// **'EDITED'**
  String get posOrdersStatusEdited;

  /// No description provided for @posOrdersStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get posOrdersStatusInProgress;

  /// No description provided for @posOrdersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get posOrdersStatusPending;

  /// No description provided for @posOrdersStatusUnapproved.
  ///
  /// In en, this message translates to:
  /// **'UNAPPROVED'**
  String get posOrdersStatusUnapproved;

  /// No description provided for @posOrdersStatusWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'WAITING APPROVAL'**
  String get posOrdersStatusWaitingApproval;

  /// No description provided for @posOrdersStatusCorpApproved.
  ///
  /// In en, this message translates to:
  /// **'CORP APPROVED'**
  String get posOrdersStatusCorpApproved;

  /// No description provided for @posOrdersAssignTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Assign Technicians'**
  String get posOrdersAssignTechnicians;

  /// No description provided for @posOrdersCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posOrdersCancelBtn;

  /// No description provided for @posOrdersMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get posOrdersMarkComplete;

  /// No description provided for @posOrdersDeleteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Job'**
  String get posOrdersDeleteJob;

  /// No description provided for @posOrdersEditBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get posOrdersEditBtn;

  /// No description provided for @posOrdersCancelledBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get posOrdersCancelledBtn;

  /// No description provided for @posOrdersProductsServices.
  ///
  /// In en, this message translates to:
  /// **'Products & Services'**
  String get posOrdersProductsServices;

  /// No description provided for @posOrdersSendForApproval.
  ///
  /// In en, this message translates to:
  /// **'Send for Approval'**
  String get posOrdersSendForApproval;

  /// No description provided for @posOrdersGenerateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get posOrdersGenerateInvoice;

  /// No description provided for @posOrdersRequestPayment.
  ///
  /// In en, this message translates to:
  /// **'Request Payment'**
  String get posOrdersRequestPayment;

  /// No description provided for @posOrdersPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get posOrdersPaymentReceived;

  /// No description provided for @posOrdersPaymentMethodLocked.
  ///
  /// In en, this message translates to:
  /// **'Payment method is locked after payment — customer details can still be edited.'**
  String get posOrdersPaymentMethodLocked;

  /// No description provided for @posOrdersPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount} SAR'**
  String posOrdersPaidAmount(String amount);

  /// No description provided for @posOrdersPaidVia.
  ///
  /// In en, this message translates to:
  /// **'via {method}'**
  String posOrdersPaidVia(String method);

  /// No description provided for @posOrdersPrepaidAmountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Order total changed. It must match the paid amount ({paid} SAR) before you can generate the invoice.'**
  String posOrdersPrepaidAmountMismatch(String paid);

  /// No description provided for @posOrdersRequestPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded for this order'**
  String get posOrdersRequestPaymentSuccess;

  /// No description provided for @posSoftPosConnectionNotStable.
  ///
  /// In en, this message translates to:
  /// **'SoftPOS is offline. Open the SoftPOS app and keep it online, then try again.'**
  String get posSoftPosConnectionNotStable;

  /// No description provided for @posOrdersOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'ORDER SUMMARY'**
  String get posOrdersOrderSummary;

  /// No description provided for @posOrdersOrderPromo.
  ///
  /// In en, this message translates to:
  /// **'ORDER PROMO'**
  String get posOrdersOrderPromo;

  /// No description provided for @posOrdersGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get posOrdersGrandTotal;

  /// No description provided for @posOrdersNoTechniciansAssigned.
  ///
  /// In en, this message translates to:
  /// **'No technicians assigned'**
  String get posOrdersNoTechniciansAssigned;

  /// No description provided for @posOrdersNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products or services'**
  String get posOrdersNoProducts;

  /// No description provided for @posOrdersDeptPromo.
  ///
  /// In en, this message translates to:
  /// **'Dept promo'**
  String get posOrdersDeptPromo;

  /// No description provided for @posOrdersDeptDiscount.
  ///
  /// In en, this message translates to:
  /// **'Dept discount'**
  String get posOrdersDeptDiscount;

  /// No description provided for @posOrdersOrderDiscount.
  ///
  /// In en, this message translates to:
  /// **'Order discount'**
  String get posOrdersOrderDiscount;

  /// No description provided for @posOrdersLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line discount'**
  String get posOrdersLineDiscount;

  /// No description provided for @posOrdersTotalBeforeVat.
  ///
  /// In en, this message translates to:
  /// **'Total before VAT'**
  String get posOrdersTotalBeforeVat;

  /// No description provided for @posOrdersTotalAfterDiscount.
  ///
  /// In en, this message translates to:
  /// **'Total after discount'**
  String get posOrdersTotalAfterDiscount;

  /// No description provided for @posOrdersNoPlate.
  ///
  /// In en, this message translates to:
  /// **'No Plate'**
  String get posOrdersNoPlate;

  /// No description provided for @posOrdersSplitPayment.
  ///
  /// In en, this message translates to:
  /// **'Split Payment'**
  String get posOrdersSplitPayment;

  /// No description provided for @posOrdersPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get posOrdersPayment;

  /// No description provided for @posOrdersInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Invoice Total'**
  String get posOrdersInvoiceTotal;

  /// No description provided for @posOrdersConfirmAmounts.
  ///
  /// In en, this message translates to:
  /// **'Confirm amounts'**
  String get posOrdersConfirmAmounts;

  /// No description provided for @posOrdersAmountSar.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR)'**
  String get posOrdersAmountSar;

  /// No description provided for @posOrdersCancelDialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posOrdersCancelDialog;

  /// No description provided for @posOrdersNoDepartmentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No departments available to add.'**
  String get posOrdersNoDepartmentsAvailable;

  /// No description provided for @posOrdersJobIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Job ID missing.'**
  String get posOrdersJobIdMissing;

  /// No description provided for @posOrdersJobNoLineItems.
  ///
  /// In en, this message translates to:
  /// **'This job has no line items.'**
  String get posOrdersJobNoLineItems;

  /// No description provided for @posOrdersTechnicianRequired.
  ///
  /// In en, this message translates to:
  /// **'Technician assignment is required.'**
  String get posOrdersTechnicianRequired;

  /// No description provided for @posOrdersJobNotReadyForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Order is not ready for invoicing.'**
  String get posOrdersJobNotReadyForInvoice;

  /// No description provided for @posOrdersSelectCustomerAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Select customer type and payment method first.'**
  String get posOrdersSelectCustomerAndPayment;

  /// No description provided for @posOrdersDeleteJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Job'**
  String get posOrdersDeleteJobTitle;

  /// No description provided for @posOrdersNoBtn.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get posOrdersNoBtn;

  /// No description provided for @posOrdersYesDeleteBtn.
  ///
  /// In en, this message translates to:
  /// **'YES, DELETE'**
  String get posOrdersYesDeleteBtn;

  /// No description provided for @posReviewFinalReview.
  ///
  /// In en, this message translates to:
  /// **'Final Review'**
  String get posReviewFinalReview;

  /// No description provided for @posReviewInvoiceReady.
  ///
  /// In en, this message translates to:
  /// **'Invoice Ready'**
  String get posReviewInvoiceReady;

  /// No description provided for @posReviewBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get posReviewBilling;

  /// No description provided for @posReviewVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get posReviewVehicle;

  /// No description provided for @posReviewInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice details'**
  String get posReviewInvoiceDetails;

  /// No description provided for @posReviewCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get posReviewCustomerDetails;

  /// No description provided for @posReviewConfirmBillingAndVehicle.
  ///
  /// In en, this message translates to:
  /// **'Confirm billing contact and vehicle before creating the invoice.'**
  String get posReviewConfirmBillingAndVehicle;

  /// No description provided for @posReviewConfirmBillingOnly.
  ///
  /// In en, this message translates to:
  /// **'Confirm billing contact before creating the invoice.'**
  String get posReviewConfirmBillingOnly;

  /// No description provided for @posReviewCustomerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get posReviewCustomerNameLabel;

  /// No description provided for @posReviewMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get posReviewMobileLabel;

  /// No description provided for @posReviewVatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get posReviewVatLabel;

  /// No description provided for @posReviewPlateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get posReviewPlateNumberLabel;

  /// No description provided for @posReviewOdometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get posReviewOdometerLabel;

  /// No description provided for @posReviewMakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get posReviewMakeLabel;

  /// No description provided for @posReviewModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get posReviewModelLabel;

  /// No description provided for @posReviewYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get posReviewYearLabel;

  /// No description provided for @posReviewVinLabel.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get posReviewVinLabel;

  /// No description provided for @posReviewRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get posReviewRequiredError;

  /// No description provided for @posReviewPlateRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Plate is required'**
  String get posReviewPlateRequiredError;

  /// No description provided for @posReviewInvalidYearError.
  ///
  /// In en, this message translates to:
  /// **'Invalid year'**
  String get posReviewInvalidYearError;

  /// No description provided for @posReviewCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posReviewCancelBtn;

  /// No description provided for @posReviewContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get posReviewContinueBtn;

  /// No description provided for @posReviewCorporateCustomerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Corporate Customer?'**
  String get posReviewCorporateCustomerQuestion;

  /// No description provided for @posReviewIsCorporateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Is this a corporate customer?'**
  String get posReviewIsCorporateCustomer;

  /// No description provided for @posReviewYesCorporate.
  ///
  /// In en, this message translates to:
  /// **'Yes — Corporate'**
  String get posReviewYesCorporate;

  /// No description provided for @posReviewNoIndividual.
  ///
  /// In en, this message translates to:
  /// **'No — Individual'**
  String get posReviewNoIndividual;

  /// No description provided for @posReviewPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method (Select multiple if splitting)'**
  String get posReviewPaymentMethod;

  /// No description provided for @posReviewPaymentMethodCorporate.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get posReviewPaymentMethodCorporate;

  /// No description provided for @posReviewCompleteAndGenerateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Complete Order & Generate Invoice'**
  String get posReviewCompleteAndGenerateInvoice;

  /// No description provided for @posReviewInvoiceGeneratedLocked.
  ///
  /// In en, this message translates to:
  /// **'Invoice Generated & Locked'**
  String get posReviewInvoiceGeneratedLocked;

  /// No description provided for @posReviewNoFurtherEdits.
  ///
  /// In en, this message translates to:
  /// **'No further edits allowed'**
  String get posReviewNoFurtherEdits;

  /// No description provided for @posReviewCommissionsCredited.
  ///
  /// In en, this message translates to:
  /// **'Commissions Credited'**
  String get posReviewCommissionsCredited;

  /// No description provided for @posReviewPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice & Receipt'**
  String get posReviewPrintInvoice;

  /// No description provided for @posReviewCommissionsNote.
  ///
  /// In en, this message translates to:
  /// **'Commissions have been credited to technician accounts.'**
  String get posReviewCommissionsNote;

  /// No description provided for @posReviewOrderNo.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String posReviewOrderNo(Object id);

  /// No description provided for @posReviewSplitPayment.
  ///
  /// In en, this message translates to:
  /// **'Split Payment'**
  String get posReviewSplitPayment;

  /// No description provided for @posReviewInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Invoice Total'**
  String get posReviewInvoiceTotal;

  /// No description provided for @posReviewConfirmAmounts.
  ///
  /// In en, this message translates to:
  /// **'Confirm amounts'**
  String get posReviewConfirmAmounts;

  /// No description provided for @posReviewAmountSar.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR)'**
  String get posReviewAmountSar;

  /// No description provided for @posReviewCancelDialogBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posReviewCancelDialogBtn;

  /// No description provided for @posReviewEmployeesPayment.
  ///
  /// In en, this message translates to:
  /// **'Employees (payment)'**
  String get posReviewEmployeesPayment;

  /// No description provided for @posReviewSelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select employee'**
  String get posReviewSelectEmployee;

  /// No description provided for @posReviewEmployeeInstructions.
  ///
  /// In en, this message translates to:
  /// **'One employee for the Employees payment line. Tap the selected card again to clear.'**
  String get posReviewEmployeeInstructions;

  /// No description provided for @posReviewCouldNotLoadEmployees.
  ///
  /// In en, this message translates to:
  /// **'Could not load branch employees.'**
  String get posReviewCouldNotLoadEmployees;

  /// No description provided for @posReviewRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posReviewRetry;

  /// No description provided for @posReviewNoBranchEmployees.
  ///
  /// In en, this message translates to:
  /// **'No branch employees listed.'**
  String get posReviewNoBranchEmployees;

  /// No description provided for @posReviewGrossAmountExclVat.
  ///
  /// In en, this message translates to:
  /// **'Gross Amount (Excl. VAT)'**
  String get posReviewGrossAmountExclVat;

  /// No description provided for @posReviewItemDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Item Discounts'**
  String get posReviewItemDiscounts;

  /// No description provided for @posReviewInvoiceDiscount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount'**
  String get posReviewInvoiceDiscount;

  /// No description provided for @posReviewPromoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo Discount ({code})'**
  String posReviewPromoDiscount(Object code);

  /// No description provided for @posReviewPromoDiscountNoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Discount'**
  String get posReviewPromoDiscountNoCode;

  /// No description provided for @posReviewPriceAfterDiscount.
  ///
  /// In en, this message translates to:
  /// **'Price after discount'**
  String get posReviewPriceAfterDiscount;

  /// No description provided for @posReviewPriceAfterPromo.
  ///
  /// In en, this message translates to:
  /// **'Price after promo'**
  String get posReviewPriceAfterPromo;

  /// No description provided for @posReviewDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get posReviewDiscount;

  /// No description provided for @posReviewTaxPct.
  ///
  /// In en, this message translates to:
  /// **'Tax ({pct}%)'**
  String posReviewTaxPct(Object pct);

  /// No description provided for @posReviewTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get posReviewTotalAmount;

  /// No description provided for @posReviewNoDeptData.
  ///
  /// In en, this message translates to:
  /// **'No departmental data found.'**
  String get posReviewNoDeptData;

  /// No description provided for @posReviewDepartmentCol.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get posReviewDepartmentCol;

  /// No description provided for @posReviewJobIdCol.
  ///
  /// In en, this message translates to:
  /// **'Job ID'**
  String get posReviewJobIdCol;

  /// No description provided for @posReviewStatusCol.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get posReviewStatusCol;

  /// No description provided for @posReviewProductServiceCol.
  ///
  /// In en, this message translates to:
  /// **'Product / Service'**
  String get posReviewProductServiceCol;

  /// No description provided for @posReviewQtyCol.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get posReviewQtyCol;

  /// No description provided for @posReviewAmountSarCol.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR)'**
  String get posReviewAmountSarCol;

  /// No description provided for @posReviewNoLineItems.
  ///
  /// In en, this message translates to:
  /// **'No line items'**
  String get posReviewNoLineItems;

  /// No description provided for @posReviewGrossExclVat.
  ///
  /// In en, this message translates to:
  /// **'Gross (Excl. VAT)'**
  String get posReviewGrossExclVat;

  /// No description provided for @posReviewItemLineDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Item / line discounts'**
  String get posReviewItemLineDiscounts;

  /// No description provided for @posReviewVatPct.
  ///
  /// In en, this message translates to:
  /// **'VAT ({pct}%)'**
  String posReviewVatPct(Object pct);

  /// No description provided for @posReviewDepartmentTotal.
  ///
  /// In en, this message translates to:
  /// **'Department total'**
  String get posReviewDepartmentTotal;

  /// No description provided for @posReviewOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'ORDER SUMMARY'**
  String get posReviewOrderSummary;

  /// No description provided for @posReviewTotalTaxable.
  ///
  /// In en, this message translates to:
  /// **'Total Taxable Amount'**
  String get posReviewTotalTaxable;

  /// No description provided for @posReviewVat15.
  ///
  /// In en, this message translates to:
  /// **'VAT (15%)'**
  String get posReviewVat15;

  /// No description provided for @posReviewLineNetNote.
  ///
  /// In en, this message translates to:
  /// **'Line totals are net of item-level discounts.'**
  String get posReviewLineNetNote;

  /// No description provided for @posReviewInvoicePromoNote.
  ///
  /// In en, this message translates to:
  /// **'Invoice and promo discounts apply to the taxable subtotal.'**
  String get posReviewInvoicePromoNote;

  /// No description provided for @posReviewConfirmAmountsNote.
  ///
  /// In en, this message translates to:
  /// **'Confirm all amounts match the job before generating the invoice.'**
  String get posReviewConfirmAmountsNote;

  /// No description provided for @posReviewAssignedTechnicians.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED TECHNICIANS'**
  String get posReviewAssignedTechnicians;

  /// No description provided for @posReviewJobHash.
  ///
  /// In en, this message translates to:
  /// **'Job #{id}'**
  String posReviewJobHash(Object id);

  /// No description provided for @posReviewNoTechAssigned.
  ///
  /// In en, this message translates to:
  /// **'No technician assigned'**
  String get posReviewNoTechAssigned;

  /// No description provided for @posReviewCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commission: {amount}'**
  String posReviewCommissionLabel(Object amount);

  /// No description provided for @posReviewTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get posReviewTotal;

  /// No description provided for @posReviewDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get posReviewDone;

  /// No description provided for @posReviewCorporateMustBeApproved.
  ///
  /// In en, this message translates to:
  /// **'Corporate order must be approved before invoicing.'**
  String get posReviewCorporateMustBeApproved;

  /// No description provided for @posReviewOrderNotReadyForInvoicing.
  ///
  /// In en, this message translates to:
  /// **'Order is not ready for invoicing.'**
  String get posReviewOrderNotReadyForInvoicing;

  /// No description provided for @posReviewIndicateCorporate.
  ///
  /// In en, this message translates to:
  /// **'Please indicate if this is a corporate customer.'**
  String get posReviewIndicateCorporate;

  /// No description provided for @posReviewSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method.'**
  String get posReviewSelectPaymentMethod;

  /// No description provided for @posReviewSelectAtLeastOnePayment.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one payment method.'**
  String get posReviewSelectAtLeastOnePayment;

  /// No description provided for @posReviewSelectOneEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select one employee for the Employees payment.'**
  String get posReviewSelectOneEmployee;

  /// No description provided for @posReviewSplitAmountsMustEqual.
  ///
  /// In en, this message translates to:
  /// **'Split amounts must equal the total ({total} SAR). Currently: {current} SAR.'**
  String posReviewSplitAmountsMustEqual(Object current, Object total);

  /// No description provided for @posReviewFillRequiredInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the required invoice details.'**
  String get posReviewFillRequiredInvoiceDetails;

  /// No description provided for @posReviewInvoiceNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Invoice could not be loaded.'**
  String get posReviewInvoiceNotLoaded;

  /// No description provided for @posDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get posDetailsTitle;

  /// No description provided for @posDetailsCustomerSection.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get posDetailsCustomerSection;

  /// No description provided for @posDetailsVehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get posDetailsVehicleSection;

  /// No description provided for @posDetailsVehicleNo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle no.'**
  String get posDetailsVehicleNo;

  /// No description provided for @posDetailsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get posDetailsCustomer;

  /// No description provided for @posDetailsMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get posDetailsMobile;

  /// No description provided for @posDetailsVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get posDetailsVat;

  /// No description provided for @posDetailsMakeModel.
  ///
  /// In en, this message translates to:
  /// **'Make/Model'**
  String get posDetailsMakeModel;

  /// No description provided for @posDetailsPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get posDetailsPlate;

  /// No description provided for @posDetailsOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get posDetailsOdometer;

  /// No description provided for @posDetailsOdometerKm.
  ///
  /// In en, this message translates to:
  /// **'{reading} km'**
  String posDetailsOdometerKm(Object reading);

  /// No description provided for @posDetailsJobsSection.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get posDetailsJobsSection;

  /// No description provided for @posDetailsNoJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get posDetailsNoJobsFound;

  /// No description provided for @posDetailsJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job {num} • {status}'**
  String posDetailsJobTitle(Object num, Object status);

  /// No description provided for @posDetailsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get posDetailsDepartment;

  /// No description provided for @posDetailsTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get posDetailsTechnician;

  /// No description provided for @posDetailsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get posDetailsSubtotal;

  /// No description provided for @posDetailsVat15.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get posDetailsVat15;

  /// No description provided for @posDetailsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posDetailsTotal;

  /// No description provided for @posDetailsItems.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String posDetailsItems(Object count);

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodMonthlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Monthly billing'**
  String get paymentMethodMonthlyBilling;

  /// No description provided for @paymentMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get paymentMethodWallet;

  /// No description provided for @paymentMethodTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby'**
  String get paymentMethodTabby;

  /// No description provided for @paymentMethodTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara'**
  String get paymentMethodTamara;

  /// No description provided for @paymentMethodEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get paymentMethodEmployees;

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers & Purchases'**
  String get suppliersTitle;

  /// No description provided for @suppliersTabSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTabSuppliers;

  /// No description provided for @suppliersTabPurchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Purchase Orders'**
  String get suppliersTabPurchaseOrders;

  /// No description provided for @suppliersFabAddSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get suppliersFabAddSupplier;

  /// No description provided for @suppliersFabNewPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase'**
  String get suppliersFabNewPurchase;

  /// No description provided for @suppliersStatSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersStatSuppliers;

  /// No description provided for @suppliersStatOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get suppliersStatOutstanding;

  /// No description provided for @suppliersStatPendingPos.
  ///
  /// In en, this message translates to:
  /// **'Pending POs'**
  String get suppliersStatPendingPos;

  /// No description provided for @suppliersNoSuppliersFound.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found'**
  String get suppliersNoSuppliersFound;

  /// No description provided for @suppliersInternalBadge.
  ///
  /// In en, this message translates to:
  /// **'INTERNAL'**
  String get suppliersInternalBadge;

  /// No description provided for @suppliersOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get suppliersOutstandingLabel;

  /// No description provided for @suppliersAmountSar.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String suppliersAmountSar(String amount);

  /// No description provided for @suppliersAmountCurrency.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount}'**
  String suppliersAmountCurrency(String currency, String amount);

  /// No description provided for @suppliersUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get suppliersUnknown;

  /// No description provided for @suppliersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get suppliersStatusPending;

  /// No description provided for @suppliersStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get suppliersStatusApproved;

  /// No description provided for @suppliersStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get suppliersStatusRejected;

  /// No description provided for @suppliersPoStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get suppliersPoStep1Title;

  /// No description provided for @suppliersPoStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose from your registered suppliers.'**
  String get suppliersPoStep1Subtitle;

  /// No description provided for @suppliersPoStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get suppliersPoStep2Title;

  /// No description provided for @suppliersPoStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name}'**
  String suppliersPoStep2Subtitle(String name);

  /// No description provided for @suppliersPoStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get suppliersPoStep3Title;

  /// No description provided for @suppliersPoStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review before submitting for approval.'**
  String get suppliersPoStep3Subtitle;

  /// No description provided for @suppliersPoStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get suppliersPoStepSelect;

  /// No description provided for @suppliersPoStepAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get suppliersPoStepAddItems;

  /// No description provided for @suppliersPoStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get suppliersPoStepConfirm;

  /// No description provided for @suppliersPoAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get suppliersPoAddItem;

  /// No description provided for @suppliersPoItemProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get suppliersPoItemProductName;

  /// No description provided for @suppliersPoItemProductHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Engine Oil'**
  String get suppliersPoItemProductHint;

  /// No description provided for @suppliersPoItemQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get suppliersPoItemQty;

  /// No description provided for @suppliersPoItemUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get suppliersPoItemUnitPrice;

  /// No description provided for @suppliersPoConfirmSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get suppliersPoConfirmSupplier;

  /// No description provided for @suppliersPoConfirmItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String suppliersPoConfirmItems(int count);

  /// No description provided for @suppliersPoConfirmStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get suppliersPoConfirmStatus;

  /// No description provided for @suppliersPoConfirmStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get suppliersPoConfirmStatusValue;

  /// No description provided for @suppliersPoConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'This PO will be submitted for manager approval before stock is updated.'**
  String get suppliersPoConfirmNote;

  /// No description provided for @suppliersPoNavNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get suppliersPoNavNext;

  /// No description provided for @suppliersPoNavSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get suppliersPoNavSubmit;

  /// No description provided for @suppliersPoNavBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get suppliersPoNavBack;

  /// No description provided for @suppliersAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Register New Supplier'**
  String get suppliersAddSheetTitle;

  /// No description provided for @suppliersAddSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide details to add a new supplier.'**
  String get suppliersAddSheetSubtitle;

  /// No description provided for @suppliersAddFieldName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get suppliersAddFieldName;

  /// No description provided for @suppliersAddFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get suppliersAddFieldEmail;

  /// No description provided for @suppliersAddFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get suppliersAddFieldMobile;

  /// No description provided for @suppliersAddFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get suppliersAddFieldAddress;

  /// No description provided for @suppliersAddFieldOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get suppliersAddFieldOpeningBalance;

  /// No description provided for @suppliersAddFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get suppliersAddFieldPassword;

  /// No description provided for @suppliersAddSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Supplier'**
  String get suppliersAddSaveButton;

  /// No description provided for @suppliersValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get suppliersValidationRequired;

  /// No description provided for @suppliersCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier Created Successfully'**
  String get suppliersCreateSuccess;

  /// No description provided for @suppliersCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create supplier'**
  String get suppliersCreateError;

  /// No description provided for @suppliersPoValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one item'**
  String get suppliersPoValidationEmpty;

  /// No description provided for @suppliersPoValidationItemDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill all item details properly'**
  String get suppliersPoValidationItemDetails;

  /// No description provided for @suppliersPoValidationInvalidSupplier.
  ///
  /// In en, this message translates to:
  /// **'Invalid supplier selected'**
  String get suppliersPoValidationInvalidSupplier;

  /// No description provided for @suppliersPoCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase Order Created Successfully'**
  String get suppliersPoCreateSuccess;

  /// No description provided for @suppliersPoCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create purchase order'**
  String get suppliersPoCreateError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Workshop Owner'**
  String get settingsRoleLabel;

  /// No description provided for @settingsMultiBranchBadge.
  ///
  /// In en, this message translates to:
  /// **'MULTI-BRANCH ACCESS'**
  String get settingsMultiBranchBadge;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get settingsSectionBusiness;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsTogglePushNotif.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsTogglePushNotif;

  /// No description provided for @settingsTogglePushNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Receive in-app notifications'**
  String get settingsTogglePushNotifSub;

  /// No description provided for @settingsToggleEmailAlerts.
  ///
  /// In en, this message translates to:
  /// **'Email Alerts'**
  String get settingsToggleEmailAlerts;

  /// No description provided for @settingsToggleEmailAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Get critical alerts via email'**
  String get settingsToggleEmailAlertsSub;

  /// No description provided for @settingsToggleStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Stock Alerts'**
  String get settingsToggleStockAlerts;

  /// No description provided for @settingsToggleStockAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Notify when stock is critical'**
  String get settingsToggleStockAlertsSub;

  /// No description provided for @settingsToggleLockerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Locker Difference Alerts'**
  String get settingsToggleLockerAlerts;

  /// No description provided for @settingsToggleLockerAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Notify on EOD locker variance'**
  String get settingsToggleLockerAlertsSub;

  /// No description provided for @settingsToggleBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get settingsToggleBiometric;

  /// No description provided for @settingsToggleBiometricSub.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face ID'**
  String get settingsToggleBiometricSub;

  /// No description provided for @settingsNavChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsNavChangePassword;

  /// No description provided for @settingsNavTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get settingsNavTwoFactor;

  /// No description provided for @settingsNavWorkshopProfile.
  ///
  /// In en, this message translates to:
  /// **'Workshop Profile'**
  String get settingsNavWorkshopProfile;

  /// No description provided for @settingsNavBranchMgmt.
  ///
  /// In en, this message translates to:
  /// **'Branch Management'**
  String get settingsNavBranchMgmt;

  /// No description provided for @settingsNavCommissionRules.
  ///
  /// In en, this message translates to:
  /// **'Commission Rules'**
  String get settingsNavCommissionRules;

  /// No description provided for @settingsNavVatSettings.
  ///
  /// In en, this message translates to:
  /// **'VAT Settings'**
  String get settingsNavVatSettings;

  /// No description provided for @settingsNavHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Documentation'**
  String get settingsNavHelp;

  /// No description provided for @settingsNavContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settingsNavContactSupport;

  /// No description provided for @settingsNavReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get settingsNavReportIssue;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutDialogTitle;

  /// No description provided for @settingsLogoutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from your account?'**
  String get settingsLogoutDialogBody;

  /// No description provided for @settingsLogoutDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsLogoutDialogCancel;

  /// No description provided for @settingsLogoutDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutDialogConfirm;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter Workshop OS • Version 1.0.1'**
  String get settingsVersionLabel;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get settingsLanguageArabic;

  /// No description provided for @posCommonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posCommonAll;

  /// No description provided for @posCommonProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get posCommonProducts;

  /// No description provided for @posCommonServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get posCommonServices;

  /// No description provided for @posCommonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posCommonRetry;

  /// No description provided for @posCommonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get posCommonSave;

  /// No description provided for @posCommonSar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get posCommonSar;

  /// No description provided for @posCommonPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posCommonPending;

  /// No description provided for @posCommonApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get posCommonApproved;

  /// No description provided for @posCommonRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get posCommonRejected;

  /// No description provided for @posPettyCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get posPettyCashTitle;

  /// No description provided for @posPettyCashExpenseTab.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get posPettyCashExpenseTab;

  /// No description provided for @posPettyCashFundTab.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get posPettyCashFundTab;

  /// No description provided for @posPettyCashHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get posPettyCashHistoryTab;

  /// No description provided for @posPettyCashSecureWallet.
  ///
  /// In en, this message translates to:
  /// **'SECURE WALLET'**
  String get posPettyCashSecureWallet;

  /// No description provided for @posPettyCashAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available Petty Cash'**
  String get posPettyCashAvailable;

  /// No description provided for @posPettyCashLowBalanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Petty cash balance is low. Please request fund.'**
  String get posPettyCashLowBalanceMessage;

  /// No description provided for @posPettyCashRequestFund.
  ///
  /// In en, this message translates to:
  /// **'Request Fund'**
  String get posPettyCashRequestFund;

  /// No description provided for @posPettyCashExpenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get posPettyCashExpenseDetails;

  /// No description provided for @posPettyCashAmountSar.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR)'**
  String get posPettyCashAmountSar;

  /// No description provided for @posPettyCashExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense Category'**
  String get posPettyCashExpenseCategory;

  /// No description provided for @posPettyCashEmployeeSalaryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Employee (Salary advance)'**
  String get posPettyCashEmployeeSalaryAdvance;

  /// No description provided for @posPettyCashDescriptionNotes.
  ///
  /// In en, this message translates to:
  /// **'Description / Notes'**
  String get posPettyCashDescriptionNotes;

  /// No description provided for @posPettyCashEnterDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter details...'**
  String get posPettyCashEnterDetailsHint;

  /// No description provided for @posPettyCashProofOfExpense.
  ///
  /// In en, this message translates to:
  /// **'Proof of Expense'**
  String get posPettyCashProofOfExpense;

  /// No description provided for @posPettyCashExpenseSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Expense submitted – pending approval'**
  String get posPettyCashExpenseSubmitted;

  /// No description provided for @posPettyCashSubmitExpense.
  ///
  /// In en, this message translates to:
  /// **'Submit Expense'**
  String get posPettyCashSubmitExpense;

  /// No description provided for @posPettyCashFundRequest.
  ///
  /// In en, this message translates to:
  /// **'Fund Request'**
  String get posPettyCashFundRequest;

  /// No description provided for @posPettyCashRequestedAmountSar.
  ///
  /// In en, this message translates to:
  /// **'Requested Amount (SAR)'**
  String get posPettyCashRequestedAmountSar;

  /// No description provided for @posPettyCashReasonForRequest.
  ///
  /// In en, this message translates to:
  /// **'Reason for Request'**
  String get posPettyCashReasonForRequest;

  /// No description provided for @posPettyCashReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why you need more funds...'**
  String get posPettyCashReasonHint;

  /// No description provided for @posPettyCashFundRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Fund request submitted – pending approval'**
  String get posPettyCashFundRequestSubmitted;

  /// No description provided for @posPettyCashSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get posPettyCashSubmitRequest;

  /// No description provided for @posPettyCashSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get posPettyCashSelectCategory;

  /// No description provided for @posPettyCashSearchCategory.
  ///
  /// In en, this message translates to:
  /// **'Search category…'**
  String get posPettyCashSearchCategory;

  /// No description provided for @posPettyCashNoCategoryMatches.
  ///
  /// In en, this message translates to:
  /// **'No category matches'**
  String get posPettyCashNoCategoryMatches;

  /// No description provided for @posPettyCashNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees on file'**
  String get posPettyCashNoEmployees;

  /// No description provided for @posPettyCashSelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select employee'**
  String get posPettyCashSelectEmployee;

  /// No description provided for @posPettyCashSearchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search employee…'**
  String get posPettyCashSearchEmployee;

  /// No description provided for @posPettyCashNoEmployeeMatches.
  ///
  /// In en, this message translates to:
  /// **'No employee matches'**
  String get posPettyCashNoEmployeeMatches;

  /// No description provided for @posPettyCashSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get posPettyCashSelectDate;

  /// No description provided for @posPettyCashFrom.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get posPettyCashFrom;

  /// No description provided for @posPettyCashTo.
  ///
  /// In en, this message translates to:
  /// **'To:'**
  String get posPettyCashTo;

  /// No description provided for @posPettyCashAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get posPettyCashAllCategories;

  /// No description provided for @posPettyCashReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get posPettyCashReset;

  /// No description provided for @posPettyCashHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense & fund history'**
  String get posPettyCashHistoryTitle;

  /// No description provided for @posPettyCashNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history for this filter.'**
  String get posPettyCashNoHistory;

  /// No description provided for @posPettyCashLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get posPettyCashLoadMore;

  /// No description provided for @posPettyCashEmployeePrefix.
  ///
  /// In en, this message translates to:
  /// **'Employee: {name}'**
  String posPettyCashEmployeePrefix(Object name);

  /// No description provided for @posPettyCashRejectionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rejection: {reason}'**
  String posPettyCashRejectionPrefix(Object reason);

  /// No description provided for @posPettyCashTapUploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload receipt'**
  String get posPettyCashTapUploadReceipt;

  /// No description provided for @posPettyCashRequestStatus.
  ///
  /// In en, this message translates to:
  /// **'Request Status'**
  String get posPettyCashRequestStatus;

  /// No description provided for @posPettyCashPendingUpper.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get posPettyCashPendingUpper;

  /// No description provided for @posPettyCashRequestedAmount.
  ///
  /// In en, this message translates to:
  /// **'Requested Amount'**
  String get posPettyCashRequestedAmount;

  /// No description provided for @posPettyCashReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get posPettyCashReason;

  /// No description provided for @posPettyCashRequestDate.
  ///
  /// In en, this message translates to:
  /// **'Request Date'**
  String get posPettyCashRequestDate;

  /// No description provided for @posPettyCashPendingReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request is currently being reviewed by administration. You will be notified once it is approved.'**
  String get posPettyCashPendingReviewMessage;

  /// No description provided for @posPettyCashSubmitNewRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit New Request'**
  String get posPettyCashSubmitNewRequest;

  /// No description provided for @posPettyCashValidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get posPettyCashValidAmountError;

  /// No description provided for @posPettyCashSelectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get posPettyCashSelectCategoryError;

  /// No description provided for @posPettyCashSelectEmployeeError.
  ///
  /// In en, this message translates to:
  /// **'Please select an employee for Salary Advances'**
  String get posPettyCashSelectEmployeeError;

  /// No description provided for @posPettyCashSubmitExpenseError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit expense. Check balance or try again.'**
  String get posPettyCashSubmitExpenseError;

  /// No description provided for @posPettyCashReasonError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason'**
  String get posPettyCashReasonError;

  /// No description provided for @posPettyCashSubmitRequestError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit fund request'**
  String get posPettyCashSubmitRequestError;

  /// No description provided for @posPettyCashTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Token not found'**
  String get posPettyCashTokenNotFound;

  /// No description provided for @posPettyCashLowBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Low balance - request fund first'**
  String get posPettyCashLowBalanceError;

  /// No description provided for @posProductAddTechnician.
  ///
  /// In en, this message translates to:
  /// **'Add Technician'**
  String get posProductAddTechnician;

  /// No description provided for @posProductAddProducts.
  ///
  /// In en, this message translates to:
  /// **'Add Products'**
  String get posProductAddProducts;

  /// No description provided for @posProductItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String posProductItemsCount(Object count);

  /// No description provided for @posProductGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get posProductGrandTotal;

  /// No description provided for @posProductViewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get posProductViewInvoice;

  /// No description provided for @posProductOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get posProductOrderItems;

  /// No description provided for @posProductNoItemsInvoice.
  ///
  /// In en, this message translates to:
  /// **'No items in invoice'**
  String get posProductNoItemsInvoice;

  /// No description provided for @posProductGrossAmountExclVat.
  ///
  /// In en, this message translates to:
  /// **'Gross Amount (Excl. VAT)'**
  String get posProductGrossAmountExclVat;

  /// No description provided for @posProductLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line discount'**
  String get posProductLineDiscount;

  /// No description provided for @posProductPriceAfterLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Price after line discount'**
  String get posProductPriceAfterLineDiscount;

  /// No description provided for @posProductTotalDiscountApplied.
  ///
  /// In en, this message translates to:
  /// **'Total discount applied'**
  String get posProductTotalDiscountApplied;

  /// No description provided for @posProductPriceAfterTotalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Price after total discount'**
  String get posProductPriceAfterTotalDiscount;

  /// No description provided for @posProductAddPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Add Promo Code'**
  String get posProductAddPromoCode;

  /// No description provided for @posProductPromoLabel.
  ///
  /// In en, this message translates to:
  /// **'Promo: {code}'**
  String posProductPromoLabel(Object code);

  /// No description provided for @posProductPromoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo discount'**
  String get posProductPromoDiscount;

  /// No description provided for @posProductPriceAfterPromo.
  ///
  /// In en, this message translates to:
  /// **'Price after promo'**
  String get posProductPriceAfterPromo;

  /// No description provided for @posProductVat15.
  ///
  /// In en, this message translates to:
  /// **'VAT (15%)'**
  String get posProductVat15;

  /// No description provided for @posProductTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posProductTotal;

  /// No description provided for @posProductTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get posProductTotalAmount;

  /// No description provided for @posProductEmployeesUpper.
  ///
  /// In en, this message translates to:
  /// **'EMPLOYEES'**
  String get posProductEmployeesUpper;

  /// No description provided for @posProductSelectEmployeePayment.
  ///
  /// In en, this message translates to:
  /// **'Select one employee for Employees payment (shown with type). Saves with your order.'**
  String get posProductSelectEmployeePayment;

  /// No description provided for @posProductSelectEmployeePaymentShort.
  ///
  /// In en, this message translates to:
  /// **'Select one employee for Employees payment (with type).'**
  String get posProductSelectEmployeePaymentShort;

  /// No description provided for @posProductNewOrderId.
  ///
  /// In en, this message translates to:
  /// **'#NEW-ORDER'**
  String get posProductNewOrderId;

  /// No description provided for @posProductWalkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get posProductWalkInCustomer;

  /// No description provided for @posProductNoVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'No Vehicle Details'**
  String get posProductNoVehicleDetails;

  /// No description provided for @posProductNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No Phone'**
  String get posProductNoPhone;

  /// No description provided for @posProductDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get posProductDraft;

  /// No description provided for @posProductNoItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'No items added'**
  String get posProductNoItemsAdded;

  /// No description provided for @posProductPendingAssignment.
  ///
  /// In en, this message translates to:
  /// **'pending assignment'**
  String get posProductPendingAssignment;

  /// No description provided for @posProductCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order marked as completed successfully'**
  String get posProductCompleteSuccess;

  /// No description provided for @posProductCompleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete job'**
  String get posProductCompleteError;

  /// No description provided for @posProductMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get posProductMarkComplete;

  /// No description provided for @posProductSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get posProductSaveDraft;

  /// No description provided for @posProductForwardTechnician.
  ///
  /// In en, this message translates to:
  /// **'Forward to Technician'**
  String get posProductForwardTechnician;

  /// No description provided for @posProductSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products & services...'**
  String get posProductSearchHint;

  /// No description provided for @posProductNoSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get posProductNoSearchMatch;

  /// No description provided for @posProductDepartmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Department not found'**
  String get posProductDepartmentNotFound;

  /// No description provided for @posProductAddDepartment.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get posProductAddDepartment;

  /// No description provided for @posProductNoServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get posProductNoServicesFound;

  /// No description provided for @posProductNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get posProductNoProductsFound;

  /// No description provided for @posProductEditServicePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price for this order'**
  String get posProductEditServicePriceTitle;

  /// No description provided for @posProductEditServicePriceHint.
  ///
  /// In en, this message translates to:
  /// **'VAT-inclusive unit price (SAR), cart only'**
  String get posProductEditServicePriceHint;

  /// No description provided for @posProductEditServicePriceSave.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get posProductEditServicePriceSave;

  /// No description provided for @posProductEditServicePriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get posProductEditServicePriceInvalid;

  /// No description provided for @posProductEditServicePriceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Price applied to this order'**
  String get posProductEditServicePriceSuccess;

  /// No description provided for @posProductEditServicePriceError.
  ///
  /// In en, this message translates to:
  /// **'Could not update price'**
  String get posProductEditServicePriceError;

  /// No description provided for @posProductBranchRequiredForPriceEdit.
  ///
  /// In en, this message translates to:
  /// **'Select a branch to edit catalog prices'**
  String get posProductBranchRequiredForPriceEdit;

  /// No description provided for @posProductUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit: {unit}'**
  String posProductUnitLabel(Object unit);

  /// No description provided for @posProductDiscountShort.
  ///
  /// In en, this message translates to:
  /// **'Dis.'**
  String get posProductDiscountShort;

  /// No description provided for @posProductTotalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Total discount'**
  String get posProductTotalDiscount;

  /// No description provided for @posProductCouldNotLoadEmployees.
  ///
  /// In en, this message translates to:
  /// **'Could not load employees.'**
  String get posProductCouldNotLoadEmployees;

  /// No description provided for @posProductNoBranchEmployees.
  ///
  /// In en, this message translates to:
  /// **'No branch employees.'**
  String get posProductNoBranchEmployees;

  /// No description provided for @posProductsFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get posProductsFailedLoad;

  /// No description provided for @posProductsBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch: {branch}'**
  String posProductsBranchLabel(Object branch);

  /// No description provided for @posHomeTitleFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter '**
  String get posHomeTitleFilter;

  /// No description provided for @posHomeTitlePos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get posHomeTitlePos;

  /// No description provided for @posHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search by customer number, vehicle number,phone number or customer name'**
  String get posHomeSubtitle;

  /// No description provided for @posHomeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, mobile, or vehicle plate...'**
  String get posHomeSearchHint;

  /// No description provided for @posHomeNewWalkIn.
  ///
  /// In en, this message translates to:
  /// **'New walk-in'**
  String get posHomeNewWalkIn;

  /// No description provided for @posHomeCorporateBooking.
  ///
  /// In en, this message translates to:
  /// **'Corporate booking'**
  String get posHomeCorporateBooking;

  /// No description provided for @posHomeBranchPrefix.
  ///
  /// In en, this message translates to:
  /// **'Branch: {branch}'**
  String posHomeBranchPrefix(String branch);

  /// No description provided for @posHomeRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get posHomeRecentSearches;

  /// No description provided for @posHomeSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get posHomeSearchResults;

  /// No description provided for @posHomeNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No Vehicle'**
  String get posHomeNoVehicle;

  /// No description provided for @posHomeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get posHomeNoResults;

  /// No description provided for @posHomeNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try searching with a different name or number'**
  String get posHomeNoResultsHint;

  /// No description provided for @posHomePromoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo codes'**
  String get posHomePromoCodes;

  /// No description provided for @posHomePromoPercentOff.
  ///
  /// In en, this message translates to:
  /// **'{value}% OFF'**
  String posHomePromoPercentOff(String value);

  /// No description provided for @posHomePromoAmountOff.
  ///
  /// In en, this message translates to:
  /// **'SAR {value} OFF'**
  String posHomePromoAmountOff(String value);

  /// No description provided for @posHomePromoPercentTitle.
  ///
  /// In en, this message translates to:
  /// **'{value}% off your booking'**
  String posHomePromoPercentTitle(String value);

  /// No description provided for @posHomePromoAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'SAR {value} off your booking'**
  String posHomePromoAmountTitle(String value);

  /// No description provided for @posHomePromoPercentBody.
  ///
  /// In en, this message translates to:
  /// **'New customers get {value}% off their first service'**
  String posHomePromoPercentBody(String value);

  /// No description provided for @posHomePromoAmountBody.
  ///
  /// In en, this message translates to:
  /// **'New customers get SAR {value} off their first service'**
  String posHomePromoAmountBody(String value);

  /// No description provided for @posHomeSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'See details'**
  String get posHomeSeeDetails;

  /// No description provided for @posHomeTechnicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get posHomeTechnicianLabel;

  /// No description provided for @posCatalogSyncData.
  ///
  /// In en, this message translates to:
  /// **'Sync data'**
  String get posCatalogSyncData;

  /// No description provided for @posCatalogSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing catalog…'**
  String get posCatalogSyncing;

  /// No description provided for @posCatalogSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Catalog updated'**
  String get posCatalogSyncSuccess;

  /// No description provided for @posCatalogSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync catalog'**
  String get posCatalogSyncFailed;

  /// No description provided for @posCatalogSyncEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No local data yet. Tap Sync data in the menu to download from the server.'**
  String get posCatalogSyncEmptyHint;

  /// No description provided for @posDeptSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Depart'**
  String get posDeptSelectTitle;

  /// No description provided for @posDeptAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get posDeptAddTitle;

  /// No description provided for @posDeptNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No departs found'**
  String get posDeptNoneFound;

  /// No description provided for @posDeptAlreadyOnOrder.
  ///
  /// In en, this message translates to:
  /// **'This department is already on this order.'**
  String get posDeptAlreadyOnOrder;

  /// No description provided for @posDeptSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} departments selected'**
  String posDeptSelectedCount(int count);

  /// No description provided for @posDeptAddToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to order'**
  String get posDeptAddToOrder;

  /// No description provided for @posDeptOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get posDeptOrderPlaced;

  /// No description provided for @posDeptSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one department to add.'**
  String get posDeptSelectAtLeastOne;

  /// No description provided for @posDeptVehicleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add vehicle number first (Add Customer)'**
  String get posDeptVehicleRequired;

  /// No description provided for @posDeptChangeDeptTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Department?'**
  String get posDeptChangeDeptTitle;

  /// No description provided for @posDeptChangeDeptBody.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to change your department?'**
  String get posDeptChangeDeptBody;

  /// No description provided for @posDeptChangeDeptRefresh.
  ///
  /// In en, this message translates to:
  /// **'Your invoice data will be refreshed.'**
  String get posDeptChangeDeptRefresh;

  /// No description provided for @posDeptChangeDeptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posDeptChangeDeptCancel;

  /// No description provided for @posDeptChangeDeptContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get posDeptChangeDeptContinue;

  /// No description provided for @posDeptRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posDeptRetry;

  /// No description provided for @posCustomerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer History'**
  String get posCustomerHistoryTitle;

  /// No description provided for @posCustomerPastOrders.
  ///
  /// In en, this message translates to:
  /// **'Past Orders'**
  String get posCustomerPastOrders;

  /// No description provided for @posCustomerNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No order history found for this customer.'**
  String get posCustomerNoHistory;

  /// No description provided for @posCustomerVat.
  ///
  /// In en, this message translates to:
  /// **'VAT: {vat}'**
  String posCustomerVat(String vat);

  /// No description provided for @posCustomerOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String posCustomerOrderId(String id);

  /// No description provided for @posCustomerInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice: {no}'**
  String posCustomerInvoice(String no);

  /// No description provided for @posCustomerVin.
  ///
  /// In en, this message translates to:
  /// **'VIN {vin}'**
  String posCustomerVin(String vin);

  /// No description provided for @posCustomerMoreItems.
  ///
  /// In en, this message translates to:
  /// **'+{count} more items'**
  String posCustomerMoreItems(int count);

  /// No description provided for @posCustomerAmountSar.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String posCustomerAmountSar(String amount);

  /// No description provided for @posCustomerTypeRegular.
  ///
  /// In en, this message translates to:
  /// **'REGULAR'**
  String get posCustomerTypeRegular;

  /// No description provided for @posCustomerTypeCorporate.
  ///
  /// In en, this message translates to:
  /// **'CORPORATE'**
  String get posCustomerTypeCorporate;

  /// No description provided for @posProductStockInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock ({count})'**
  String posProductStockInStock(int count);

  /// No description provided for @posProductStockLow.
  ///
  /// In en, this message translates to:
  /// **'Low ({count})'**
  String posProductStockLow(int count);

  /// No description provided for @posProductStockOut.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get posProductStockOut;

  /// No description provided for @posProductStockInfinite.
  ///
  /// In en, this message translates to:
  /// **'Infinite'**
  String get posProductStockInfinite;

  /// No description provided for @posProductStockService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get posProductStockService;

  /// No description provided for @posOrderStatusInvoiced.
  ///
  /// In en, this message translates to:
  /// **'Invoiced'**
  String get posOrderStatusInvoiced;

  /// No description provided for @posOrderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get posOrderStatusCompleted;

  /// No description provided for @posOrderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posOrderStatusPending;

  /// No description provided for @posOrderStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get posOrderStatusWaiting;

  /// No description provided for @posOrderStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get posOrderStatusDraft;

  /// No description provided for @posOrderStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get posOrderStatusInProgress;

  /// No description provided for @posOrderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get posOrderStatusAccepted;

  /// No description provided for @posSearchHistoryNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No Vehicle'**
  String get posSearchHistoryNoVehicle;

  /// No description provided for @posSearchHistoryNa.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get posSearchHistoryNa;

  /// No description provided for @posSearchHistoryContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Order'**
  String get posSearchHistoryContinue;

  /// No description provided for @posSearchHistoryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get posSearchHistoryHistory;

  /// No description provided for @posSearchHistorySalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Sales Return'**
  String get posSearchHistorySalesReturn;

  /// No description provided for @posNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get posNavHome;

  /// No description provided for @posNavProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get posNavProducts;

  /// No description provided for @posNavOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get posNavOrders;

  /// No description provided for @posNavStoreClosing.
  ///
  /// In en, this message translates to:
  /// **'Store Closing'**
  String get posNavStoreClosing;

  /// No description provided for @posNavClosingHistory.
  ///
  /// In en, this message translates to:
  /// **'Closing History'**
  String get posNavClosingHistory;

  /// No description provided for @posClosingHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your past store closings'**
  String get posClosingHistorySubtitle;

  /// No description provided for @posClosingHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No store closings yet'**
  String get posClosingHistoryEmpty;

  /// No description provided for @posClosingHistoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posClosingHistoryRetry;

  /// No description provided for @posClosingHistoryClosedBadge.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get posClosingHistoryClosedBadge;

  /// No description provided for @posClosingHistoryBranchFallback.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get posClosingHistoryBranchFallback;

  /// No description provided for @posClosingHistorySystemTotal.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get posClosingHistorySystemTotal;

  /// No description provided for @posClosingHistoryPhysicalTotal.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get posClosingHistoryPhysicalTotal;

  /// No description provided for @posClosingHistoryDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get posClosingHistoryDifference;

  /// No description provided for @posClosingHistoryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Closing details'**
  String get posClosingHistoryDetailTitle;

  /// No description provided for @posClosingHistoryOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get posClosingHistoryOpened;

  /// No description provided for @posClosingHistoryClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get posClosingHistoryClosed;

  /// No description provided for @posClosingHistoryBuckets.
  ///
  /// In en, this message translates to:
  /// **'Payment buckets'**
  String get posClosingHistoryBuckets;

  /// No description provided for @posClosingHistoryTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posClosingHistoryTabAll;

  /// No description provided for @posClosingHistoryTabBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get posClosingHistoryTabBalanced;

  /// No description provided for @posClosingHistoryTabShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get posClosingHistoryTabShort;

  /// No description provided for @posClosingHistoryCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get posClosingHistoryCommission;

  /// No description provided for @posClosingHistoryTotalCommission.
  ///
  /// In en, this message translates to:
  /// **'Total commission'**
  String get posClosingHistoryTotalCommission;

  /// No description provided for @posClosingHistoryTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get posClosingHistoryTotalSales;

  /// No description provided for @posClosingHistoryFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get posClosingHistoryFrom;

  /// No description provided for @posClosingHistoryTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get posClosingHistoryTo;

  /// No description provided for @posNavSalaries.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get posNavSalaries;

  /// No description provided for @posNavCashCollection.
  ///
  /// In en, this message translates to:
  /// **'Cash Collection'**
  String get posNavCashCollection;

  /// No description provided for @posCashCollectionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get posCashCollectionPending;

  /// No description provided for @posCashCollectionCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get posCashCollectionCollected;

  /// No description provided for @posCashCollectionExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get posCashCollectionExpected;

  /// No description provided for @posCashCollectionBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get posCashCollectionBalance;

  /// No description provided for @posCashCollectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cash collections in this range'**
  String get posCashCollectionEmpty;

  /// No description provided for @posStoreClosingCommissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift commission'**
  String get posStoreClosingCommissionTitle;

  /// No description provided for @posStoreClosingCommissionEarned.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount} SAR this shift ({percent}% of {sales} SAR sales)'**
  String posStoreClosingCommissionEarned(
    String amount,
    String percent,
    String sales,
  );

  /// No description provided for @posPromoViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get posPromoViewTitle;

  /// No description provided for @posPromoViewEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo Code'**
  String get posPromoViewEntryTitle;

  /// No description provided for @posPromoViewEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the validity of a customer provided code.'**
  String get posPromoViewEntrySubtitle;

  /// No description provided for @posPromoViewCheckValidity.
  ///
  /// In en, this message translates to:
  /// **'Check Validity'**
  String get posPromoViewCheckValidity;

  /// No description provided for @posPromoViewAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Promotions'**
  String get posPromoViewAvailableTitle;

  /// No description provided for @posPromoViewNoPromos.
  ///
  /// In en, this message translates to:
  /// **'No promotions available'**
  String get posPromoViewNoPromos;

  /// No description provided for @posPromoViewCheckConditions.
  ///
  /// In en, this message translates to:
  /// **'Check Conditions'**
  String get posPromoViewCheckConditions;

  /// No description provided for @posPromoViewRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove promo'**
  String get posPromoViewRemoveTooltip;

  /// No description provided for @posPromoResultStore.
  ///
  /// In en, this message translates to:
  /// **'Store: {value}'**
  String posPromoResultStore(String value);

  /// No description provided for @posPromoResultProducts.
  ///
  /// In en, this message translates to:
  /// **'Products: {value}'**
  String posPromoResultProducts(String value);

  /// No description provided for @posPromoResultPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {value}'**
  String posPromoResultPeriod(String value);

  /// No description provided for @posPromoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo Code'**
  String get posPromoDialogTitle;

  /// No description provided for @posPromoDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select any promo code below to apply discount instantly.'**
  String get posPromoDialogSubtitle;

  /// No description provided for @posPromoDialogNoCodesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No promo codes available.'**
  String get posPromoDialogNoCodesAvailable;

  /// No description provided for @posPromoDialogOrEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter code manually'**
  String get posPromoDialogOrEnterManually;

  /// No description provided for @posPromoDialogHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g. SAVE10'**
  String get posPromoDialogHintText;

  /// No description provided for @posPromoDialogRemovePromo.
  ///
  /// In en, this message translates to:
  /// **'Remove Promo'**
  String get posPromoDialogRemovePromo;

  /// No description provided for @posPromoDialogValidCode.
  ///
  /// In en, this message translates to:
  /// **'Valid Promo Code'**
  String get posPromoDialogValidCode;

  /// No description provided for @posPromoDialogLabelDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount:'**
  String get posPromoDialogLabelDiscount;

  /// No description provided for @posPromoDialogLabelStore.
  ///
  /// In en, this message translates to:
  /// **'Store:'**
  String get posPromoDialogLabelStore;

  /// No description provided for @posPromoDialogLabelProducts.
  ///
  /// In en, this message translates to:
  /// **'Products:'**
  String get posPromoDialogLabelProducts;

  /// No description provided for @posPromoDialogLabelValidity.
  ///
  /// In en, this message translates to:
  /// **'Validity:'**
  String get posPromoDialogLabelValidity;

  /// No description provided for @posPromoDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posPromoDialogCancel;

  /// No description provided for @posPromoDialogCheckCode.
  ///
  /// In en, this message translates to:
  /// **'Check Code'**
  String get posPromoDialogCheckCode;

  /// No description provided for @posPromoDialogApplyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount'**
  String get posPromoDialogApplyDiscount;

  /// No description provided for @posPromoDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}% Discount'**
  String posPromoDiscountPercent(String value);

  /// No description provided for @posPromoDiscountSar.
  ///
  /// In en, this message translates to:
  /// **'SAR {value} Discount'**
  String posPromoDiscountSar(String value);

  /// No description provided for @posPromoAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All Branches'**
  String get posPromoAllBranches;

  /// No description provided for @posPromoAllProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get posPromoAllProducts;

  /// No description provided for @posPromoNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No Expiry'**
  String get posPromoNoExpiry;

  /// No description provided for @posPromoInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Promo Code'**
  String get posPromoInvalidCode;

  /// No description provided for @posPromoInvalidExpired.
  ///
  /// In en, this message translates to:
  /// **'Invalid or Expired Promo Code'**
  String get posPromoInvalidExpired;

  /// No description provided for @posTechAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Assignment'**
  String get posTechAssignTitle;

  /// No description provided for @posTechAssignSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search technicians...'**
  String get posTechAssignSearchHint;

  /// No description provided for @posTechAssignShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get posTechAssignShowAll;

  /// No description provided for @posTechAssignOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get posTechAssignOnlineOnly;

  /// No description provided for @posTechAssignLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading technicians…'**
  String get posTechAssignLoading;

  /// No description provided for @posTechAssignNoResults.
  ///
  /// In en, this message translates to:
  /// **'No technicians found'**
  String get posTechAssignNoResults;

  /// No description provided for @posTechAssignErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String posTechAssignErrorPrefix(String message);

  /// No description provided for @posTechAssignRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posTechAssignRetry;

  /// No description provided for @posTechAssignStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get posTechAssignStatusOnline;

  /// No description provided for @posTechAssignStatusLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {time}'**
  String posTechAssignStatusLastSeen(String time);

  /// No description provided for @posTechAssignSlots.
  ///
  /// In en, this message translates to:
  /// **'Slots: {used}/{total}'**
  String posTechAssignSlots(int used, int total);

  /// No description provided for @posTechAssignBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get posTechAssignBroadcast;

  /// No description provided for @posTechAssignWait.
  ///
  /// In en, this message translates to:
  /// **'Wait {label}'**
  String posTechAssignWait(String label);

  /// No description provided for @posTechAssignSave.
  ///
  /// In en, this message translates to:
  /// **'Save Technicians'**
  String get posTechAssignSave;

  /// No description provided for @posTechAssignSuccessEmpty.
  ///
  /// In en, this message translates to:
  /// **'All technicians removed from this job'**
  String get posTechAssignSuccessEmpty;

  /// No description provided for @posTechAssignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technicians assigned successfully'**
  String get posTechAssignSuccess;

  /// No description provided for @posTechAssignFailNoJob.
  ///
  /// In en, this message translates to:
  /// **'Job not found for this assignment.'**
  String get posTechAssignFailNoJob;

  /// No description provided for @posTechAssignFailGetId.
  ///
  /// In en, this message translates to:
  /// **'Failed to get order ID'**
  String get posTechAssignFailGetId;

  /// No description provided for @posTechAssignFailEditId.
  ///
  /// In en, this message translates to:
  /// **'Failed to get job ID for edit'**
  String get posTechAssignFailEditId;

  /// No description provided for @posTechAssignFailGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign technicians'**
  String get posTechAssignFailGeneric;

  /// No description provided for @posTechAssignUnlockFail.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock job to change technicians. Try again.'**
  String get posTechAssignUnlockFail;

  /// No description provided for @posTechLastSeenNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get posTechLastSeenNever;

  /// No description provided for @posTechLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get posTechLastSeenJustNow;

  /// No description provided for @posTechLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String posTechLastSeenMinutes(int count);

  /// No description provided for @posTechLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String posTechLastSeenHours(int count);

  /// No description provided for @posTechLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String posTechLastSeenDays(int count);

  /// No description provided for @posTechViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get posTechViewTitle;

  /// No description provided for @posTechViewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search technicians...'**
  String get posTechViewSearchHint;

  /// No description provided for @posTechViewTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posTechViewTabAll;

  /// No description provided for @posTechViewTabOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get posTechViewTabOffline;

  /// No description provided for @posTechViewTabOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get posTechViewTabOnline;

  /// No description provided for @posTechViewNoTechnicians.
  ///
  /// In en, this message translates to:
  /// **'No technicians found'**
  String get posTechViewNoTechnicians;

  /// No description provided for @posTechViewNoOnline.
  ///
  /// In en, this message translates to:
  /// **'No online technicians'**
  String get posTechViewNoOnline;

  /// No description provided for @posTechViewNoOffline.
  ///
  /// In en, this message translates to:
  /// **'No offline technicians'**
  String get posTechViewNoOffline;

  /// No description provided for @posTechViewErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posTechViewErrorRetry;

  /// No description provided for @posTechViewErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String posTechViewErrorPrefix(String message);

  /// No description provided for @posTechCardOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get posTechCardOnlineNow;

  /// No description provided for @posTechCardLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {time}'**
  String posTechCardLastSeen(String time);

  /// No description provided for @posTechCardNoDepartment.
  ///
  /// In en, this message translates to:
  /// **'No department'**
  String get posTechCardNoDepartment;

  /// No description provided for @posTechCardSlots.
  ///
  /// In en, this message translates to:
  /// **'Slots {used}/{total}'**
  String posTechCardSlots(int used, int total);

  /// No description provided for @posTechPresenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Technician marked online'**
  String get posTechPresenceOnline;

  /// No description provided for @posTechPresenceOffline.
  ///
  /// In en, this message translates to:
  /// **'Technician marked offline'**
  String get posTechPresenceOffline;

  /// No description provided for @storeClosingPhysicalDrawerCount.
  ///
  /// In en, this message translates to:
  /// **'Physical Drawer Count'**
  String get storeClosingPhysicalDrawerCount;

  /// No description provided for @storeClosingEnterAmounts.
  ///
  /// In en, this message translates to:
  /// **'Enter the physical amounts you have counted for each payment category.'**
  String get storeClosingEnterAmounts;

  /// No description provided for @storeClosingLabelPhysicalCash.
  ///
  /// In en, this message translates to:
  /// **'Physical Cash Amount'**
  String get storeClosingLabelPhysicalCash;

  /// No description provided for @storeClosingLabelBankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank / Card Slips'**
  String get storeClosingLabelBankCard;

  /// No description provided for @storeClosingLabelCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate Invoices'**
  String get storeClosingLabelCorporate;

  /// No description provided for @storeClosingLabelTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara Credits'**
  String get storeClosingLabelTamara;

  /// No description provided for @storeClosingLabelTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby Credits'**
  String get storeClosingLabelTabby;

  /// No description provided for @storeClosingLabelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get storeClosingLabelNotes;

  /// No description provided for @storeClosingTotalPhysical.
  ///
  /// In en, this message translates to:
  /// **'Total Physical Sum'**
  String get storeClosingTotalPhysical;

  /// No description provided for @storeClosingExpectedSar.
  ///
  /// In en, this message translates to:
  /// **'Expected: {sar} {amount}'**
  String storeClosingExpectedSar(String sar, String amount);

  /// No description provided for @storeClosingShiftBalanced.
  ///
  /// In en, this message translates to:
  /// **'Shift Balanced'**
  String get storeClosingShiftBalanced;

  /// No description provided for @storeClosingDiscrepancy.
  ///
  /// In en, this message translates to:
  /// **'Discrepancy Detected'**
  String get storeClosingDiscrepancy;

  /// No description provided for @storeClosingShiftClosedOk.
  ///
  /// In en, this message translates to:
  /// **'Shift closed successfully.'**
  String get storeClosingShiftClosedOk;

  /// No description provided for @storeClosingPositiveDiff.
  ///
  /// In en, this message translates to:
  /// **'Positive diff = system > physical.'**
  String get storeClosingPositiveDiff;

  /// No description provided for @storeClosingClosingId.
  ///
  /// In en, this message translates to:
  /// **'Closing ID'**
  String get storeClosingClosingId;

  /// No description provided for @storeClosingTotalDiff.
  ///
  /// In en, this message translates to:
  /// **'Total Difference'**
  String get storeClosingTotalDiff;

  /// No description provided for @storeClosingSystemTotalSales.
  ///
  /// In en, this message translates to:
  /// **'System Total Sales'**
  String get storeClosingSystemTotalSales;

  /// No description provided for @posOrdersTotalInclVat.
  ///
  /// In en, this message translates to:
  /// **'Total (incl. VAT)'**
  String get posOrdersTotalInclVat;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currencySymbol;

  /// No description provided for @currencySymbolAr.
  ///
  /// In en, this message translates to:
  /// **'ر.س'**
  String get currencySymbolAr;

  /// No description provided for @toastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get toastSuccess;

  /// No description provided for @toastError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get toastError;

  /// No description provided for @toastInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get toastInfo;

  /// No description provided for @posCommonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get posCommonGoBack;

  /// No description provided for @posCommonConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancel'**
  String get posCommonConfirmCancel;

  /// No description provided for @posCommonCancelledByCashier.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by cashier'**
  String get posCommonCancelledByCashier;

  /// No description provided for @posThermalPrinterTitle.
  ///
  /// In en, this message translates to:
  /// **'Thermal Printer (Wi-Fi)'**
  String get posThermalPrinterTitle;

  /// No description provided for @posThermalPrinterIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Printer IP'**
  String get posThermalPrinterIpLabel;

  /// No description provided for @posThermalPrinterIpHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.8.55'**
  String get posThermalPrinterIpHint;

  /// No description provided for @posThermalPrinterIpEnterPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your IP'**
  String get posThermalPrinterIpEnterPlaceholder;

  /// No description provided for @posThermalPrinterPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get posThermalPrinterPortLabel;

  /// No description provided for @posThermalPrinterPortHelper.
  ///
  /// In en, this message translates to:
  /// **'9100 for most Epson network receipt printers'**
  String get posThermalPrinterPortHelper;

  /// No description provided for @posThermalPrinterSaved.
  ///
  /// In en, this message translates to:
  /// **'Printer address saved.'**
  String get posThermalPrinterSaved;

  /// No description provided for @posCommonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posCommonCancel;

  /// No description provided for @posOrdersCancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get posOrdersCancelOrderTitle;

  /// No description provided for @posOrdersCancelOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get posOrdersCancelOrderBody;

  /// No description provided for @posTechCardOnCall.
  ///
  /// In en, this message translates to:
  /// **'On call'**
  String get posTechCardOnCall;

  /// No description provided for @posTechCardNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get posTechCardNotAvailable;

  /// No description provided for @posTechCardWorkshopDuty.
  ///
  /// In en, this message translates to:
  /// **'Workshop Duty'**
  String get posTechCardWorkshopDuty;

  /// No description provided for @posTechCardOnCallDuty.
  ///
  /// In en, this message translates to:
  /// **'On Call Duty'**
  String get posTechCardOnCallDuty;

  /// No description provided for @storeClosingCounterReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Counter Reconciliation'**
  String get storeClosingCounterReconciliation;

  /// No description provided for @storeClosingReconciliationSummary.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation Summary'**
  String get storeClosingReconciliationSummary;

  /// No description provided for @storeClosingShiftClosingStatus.
  ///
  /// In en, this message translates to:
  /// **'Shift Closing Status'**
  String get storeClosingShiftClosingStatus;

  /// No description provided for @storeClosingCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get storeClosingCashier;

  /// No description provided for @storeClosingBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get storeClosingBranch;

  /// No description provided for @storeClosingMainBranch.
  ///
  /// In en, this message translates to:
  /// **'Main Branch'**
  String get storeClosingMainBranch;

  /// No description provided for @storeClosingOthersEmployee.
  ///
  /// In en, this message translates to:
  /// **'Others / Employee'**
  String get storeClosingOthersEmployee;

  /// No description provided for @posCommonAddNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get posCommonAddNotesHint;

  /// No description provided for @storeClosingCashAccount.
  ///
  /// In en, this message translates to:
  /// **'Cash Account'**
  String get storeClosingCashAccount;

  /// No description provided for @storeClosingBankCards.
  ///
  /// In en, this message translates to:
  /// **'Bank / Cards'**
  String get storeClosingBankCards;

  /// No description provided for @storeClosingOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get storeClosingOthers;

  /// No description provided for @storeClosingCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get storeClosingCategory;

  /// No description provided for @storeClosingSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get storeClosingSystem;

  /// No description provided for @storeClosingPhysicalCol.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get storeClosingPhysicalCol;

  /// No description provided for @storeClosingDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get storeClosingDiff;

  /// No description provided for @storeClosingBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get storeClosingBalanced;

  /// No description provided for @storeClosingShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get storeClosingShort;

  /// No description provided for @storeClosingExcess.
  ///
  /// In en, this message translates to:
  /// **'Excess'**
  String get storeClosingExcess;

  /// No description provided for @storeClosingSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get storeClosingSummary;

  /// No description provided for @storeClosingAmountCol.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get storeClosingAmountCol;

  /// No description provided for @storeClosingTotalSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Total Sales Return'**
  String get storeClosingTotalSalesReturn;

  /// No description provided for @storeClosingBeforeReturns.
  ///
  /// In en, this message translates to:
  /// **'Before Returns'**
  String get storeClosingBeforeReturns;

  /// No description provided for @storeClosingGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get storeClosingGrandTotal;

  /// No description provided for @storeClosingCloseShift.
  ///
  /// In en, this message translates to:
  /// **'Close Shift'**
  String get storeClosingCloseShift;

  /// No description provided for @storeClosingGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get storeClosingGenerateReport;

  /// No description provided for @storeClosingFinalLogout.
  ///
  /// In en, this message translates to:
  /// **'Final Logout'**
  String get storeClosingFinalLogout;

  /// No description provided for @storeClosingLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get storeClosingLogOut;

  /// No description provided for @storeClosingLogOutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out and close the shift?'**
  String get storeClosingLogOutBody;

  /// No description provided for @storeClosingLogOutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storeClosingLogOutCancel;

  /// No description provided for @posHomeTabletRequired.
  ///
  /// In en, this message translates to:
  /// **'Tablet Required'**
  String get posHomeTabletRequired;

  /// No description provided for @posHomeLandscapeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please rotate your device to landscape mode to use the POS system.'**
  String get posHomeLandscapeRequired;

  /// No description provided for @posNavOrdersHub.
  ///
  /// In en, this message translates to:
  /// **'Orders Hub'**
  String get posNavOrdersHub;

  /// No description provided for @posNavBroadcastTechnician.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Technician'**
  String get posNavBroadcastTechnician;

  /// No description provided for @posNavInventorySales.
  ///
  /// In en, this message translates to:
  /// **'Inventory Sales'**
  String get posNavInventorySales;

  /// No description provided for @posNavTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get posNavTakeaway;

  /// No description provided for @posCustomerInvoiceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load invoice'**
  String get posCustomerInvoiceLoadError;

  /// No description provided for @posCustomerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get posCustomerLoading;

  /// No description provided for @posCustomerPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get posCustomerPrintInvoice;

  /// No description provided for @posCommonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get posCommonNotAvailable;

  /// No description provided for @posCommonDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get posCommonDash;

  /// No description provided for @posCurrentShiftDefaultCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get posCurrentShiftDefaultCashier;

  /// No description provided for @posCurrentShiftDefaultStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get posCurrentShiftDefaultStatus;

  /// No description provided for @posCurrentShiftCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'User credentials or token missing.'**
  String get posCurrentShiftCredentialsError;

  /// No description provided for @posDeptAuthError.
  ///
  /// In en, this message translates to:
  /// **'No authentication token found'**
  String get posDeptAuthError;

  /// No description provided for @posDeptLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load departments'**
  String get posDeptLoadError;

  /// No description provided for @posPaymentsChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one payment method.'**
  String get posPaymentsChooseMethod;

  /// No description provided for @posPaymentsLineMinimum.
  ///
  /// In en, this message translates to:
  /// **'Each payment line must be at least 0.01 SAR.'**
  String get posPaymentsLineMinimum;

  /// No description provided for @posPaymentsEnterSelectedAmounts.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount for each selected payment method.'**
  String get posPaymentsEnterSelectedAmounts;

  /// No description provided for @posPaymentsSplitMismatch.
  ///
  /// In en, this message translates to:
  /// **'Split totals must equal the order payable amount ({payable} SAR). Currently: {current} SAR.'**
  String posPaymentsSplitMismatch(String payable, String current);

  /// No description provided for @posSessionExpiredSignIn.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again.'**
  String get posSessionExpiredSignIn;

  /// No description provided for @posPaymentSelectionSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save payment selection.'**
  String get posPaymentSelectionSaveError;

  /// No description provided for @posPaymentSelectionClearError.
  ///
  /// In en, this message translates to:
  /// **'Could not clear saved payment.'**
  String get posPaymentSelectionClearError;

  /// No description provided for @posBillingEditLocked.
  ///
  /// In en, this message translates to:
  /// **'Billing cannot be edited after an invoice exists.'**
  String get posBillingEditLocked;

  /// No description provided for @posBillingCustomerMobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name and mobile are required.'**
  String get posBillingCustomerMobileRequired;

  /// No description provided for @posBillingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update billing details'**
  String get posBillingSaveError;

  /// No description provided for @posBillingClearEmployeePaymentError.
  ///
  /// In en, this message translates to:
  /// **'Could not clear saved payment for employee customer.'**
  String get posBillingClearEmployeePaymentError;

  /// No description provided for @posCorporateAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a corporate account'**
  String get posCorporateAccountRequired;

  /// No description provided for @posDepartmentSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one department'**
  String get posDepartmentSelectAtLeastOne;

  /// No description provided for @posAuthTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found'**
  String get posAuthTokenMissing;

  /// No description provided for @posVehiclePlateRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle plate is required'**
  String get posVehiclePlateRequired;

  /// No description provided for @posOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order created'**
  String get posOrderCreated;

  /// No description provided for @posCorporateAccountMissing.
  ///
  /// In en, this message translates to:
  /// **'Corporate account is missing for this corporate draft.'**
  String get posCorporateAccountMissing;

  /// No description provided for @posCorporateContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact name is required for corporate quote'**
  String get posCorporateContactRequired;

  /// No description provided for @posUnitPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid unit price for {name}'**
  String posUnitPriceInvalid(String name);

  /// No description provided for @posLineDepartmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Each line needs a department'**
  String get posLineDepartmentRequired;

  /// No description provided for @posNoLineItemsToSave.
  ///
  /// In en, this message translates to:
  /// **'No line items to save'**
  String get posNoLineItemsToSave;

  /// No description provided for @posDepartmentJobMissing.
  ///
  /// In en, this message translates to:
  /// **'No job for department {departmentId}. Use “Add departments” or refresh orders.'**
  String posDepartmentJobMissing(String departmentId);

  /// No description provided for @posPricingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save pricing for department {departmentId}'**
  String posPricingSaveFailed(String departmentId);

  /// No description provided for @posEditContextMissing.
  ///
  /// In en, this message translates to:
  /// **'Edit context missing. Please try again.'**
  String get posEditContextMissing;

  /// No description provided for @posNoChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get posNoChangesToSave;

  /// No description provided for @posUnlockJobFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock this job for editing'**
  String get posUnlockJobFailed;

  /// No description provided for @posUnlockJobFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock this job for editing. Please try again.'**
  String get posUnlockJobFailedRetry;

  /// No description provided for @posOrderUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order updated successfully'**
  String get posOrderUpdateSuccess;

  /// No description provided for @posOrderUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order'**
  String get posOrderUpdateFailed;

  /// No description provided for @posAuthInfoMissing.
  ///
  /// In en, this message translates to:
  /// **'Authentication information missing'**
  String get posAuthInfoMissing;

  /// No description provided for @posProductsFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch products'**
  String get posProductsFetchFailed;

  /// No description provided for @posServiceOnlyOnce.
  ///
  /// In en, this message translates to:
  /// **'Services can only be booked once per order.'**
  String get posServiceOnlyOnce;

  /// No description provided for @posStockLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed available stock limit ({stock})'**
  String posStockLimitExceeded(String stock);

  /// No description provided for @posOrdersFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch orders'**
  String get posOrdersFetchFailed;

  /// No description provided for @posDepartmentStarted.
  ///
  /// In en, this message translates to:
  /// **'Department started'**
  String get posDepartmentStarted;

  /// No description provided for @posDepartmentStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start department'**
  String get posDepartmentStartFailed;

  /// No description provided for @posOrderDetailsMissing.
  ///
  /// In en, this message translates to:
  /// **'Order details not found'**
  String get posOrderDetailsMissing;

  /// No description provided for @posCorporateApprovalSent.
  ///
  /// In en, this message translates to:
  /// **'Sent for corporate approval'**
  String get posCorporateApprovalSent;

  /// No description provided for @posCorporateApprovalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send for approval'**
  String get posCorporateApprovalFailed;

  /// No description provided for @posVehicleNumberRequiredForBilling.
  ///
  /// In en, this message translates to:
  /// **'vehicleNumber is required when sending vehicle fields. Add the plate under Add Customer.'**
  String get posVehicleNumberRequiredForBilling;

  /// No description provided for @posInvoiceJobNotReady.
  ///
  /// In en, this message translates to:
  /// **'Job is not ready to invoice. Add billable lines and technicians first.'**
  String get posInvoiceJobNotReady;

  /// No description provided for @posFinalizeEditedJobFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finalize edited job before invoice.'**
  String get posFinalizeEditedJobFailed;

  /// No description provided for @posInvoiceCustomerRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name and mobile are required before invoice. Complete the billing prompt or update customer'**
  String get posInvoiceCustomerRequired;

  /// No description provided for @posInvoiceVehiclePlateRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle plate is required before invoice. Add it under Add Customer (billing), then try again.'**
  String get posInvoiceVehiclePlateRequired;

  /// No description provided for @posInvoicePaymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment method is required before generating invoice.'**
  String get posInvoicePaymentRequired;

  /// No description provided for @posInvoicePaymentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Invoice created, but failed to save payment.'**
  String get posInvoicePaymentSaveFailed;

  /// No description provided for @posInvoiceSaved.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved'**
  String get posInvoiceSaved;

  /// No description provided for @posJobProductsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add products/services before completing the job.'**
  String get posJobProductsRequired;

  /// No description provided for @posBroadcastSaveOrderFirst.
  ///
  /// In en, this message translates to:
  /// **'Save the order first before broadcasting.'**
  String get posBroadcastSaveOrderFirst;

  /// No description provided for @posBroadcastWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait {wait} before broadcasting this department again.'**
  String posBroadcastWait(String wait);

  /// No description provided for @posBroadcastFailed.
  ///
  /// In en, this message translates to:
  /// **'Broadcast failed'**
  String get posBroadcastFailed;

  /// No description provided for @posBroadcastSent.
  ///
  /// In en, this message translates to:
  /// **'Broadcast sent to technicians'**
  String get posBroadcastSent;

  /// No description provided for @posBroadcastCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancel broadcast failed'**
  String get posBroadcastCancelFailed;

  /// No description provided for @posBroadcastCancelled.
  ///
  /// In en, this message translates to:
  /// **'Broadcast cancelled'**
  String get posBroadcastCancelled;

  /// No description provided for @posOrderCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get posOrderCancelSuccess;

  /// No description provided for @posCancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason is required'**
  String get posCancelReasonRequired;

  /// No description provided for @posCancelOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order'**
  String get posCancelOrderFailed;

  /// No description provided for @posCancelledByCashier.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by cashier'**
  String get posCancelledByCashier;

  /// No description provided for @posJobCancelled.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled'**
  String get posJobCancelled;

  /// No description provided for @posJobCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel job'**
  String get posJobCancelFailed;

  /// No description provided for @posDepartmentsAdded.
  ///
  /// In en, this message translates to:
  /// **'Departments added'**
  String get posDepartmentsAdded;

  /// No description provided for @posDepartmentsAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add departments'**
  String get posDepartmentsAddFailed;

  /// No description provided for @posDetailsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String posDetailsCreated(Object date);

  /// No description provided for @posDetailsOrderNo.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String posDetailsOrderNo(Object id);

  /// No description provided for @posShellTabletRequired.
  ///
  /// In en, this message translates to:
  /// **'Tablet required'**
  String get posShellTabletRequired;

  /// No description provided for @posShellTabletMessage.
  ///
  /// In en, this message translates to:
  /// **'Workshop POS opens only on tablet devices.'**
  String get posShellTabletMessage;

  /// No description provided for @posShellLandscapeTitle.
  ///
  /// In en, this message translates to:
  /// **'Landscape required'**
  String get posShellLandscapeTitle;

  /// No description provided for @posShellLandscapeMessage.
  ///
  /// In en, this message translates to:
  /// **'Rotate the tablet to landscape mode to use Workshop POS.'**
  String get posShellLandscapeMessage;

  /// No description provided for @posOrdersInvoiceSavedNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'Invoice was saved, but receipt details were not returned. The order should appear as invoiced after refresh.'**
  String get posOrdersInvoiceSavedNoReceipt;

  /// No description provided for @posOrdersSelectBranchEmployeeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select the branch employee customer first.'**
  String get posOrdersSelectBranchEmployeeCustomer;

  /// No description provided for @posOrdersSplitAmountsMustEqualTotal.
  ///
  /// In en, this message translates to:
  /// **'Split amounts must equal total ({total} SAR).'**
  String posOrdersSplitAmountsMustEqualTotal(Object total);

  /// No description provided for @posHomeTitleWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop '**
  String get posHomeTitleWorkshop;

  /// No description provided for @posInvSalesStatDistinctItems.
  ///
  /// In en, this message translates to:
  /// **'Distinct items'**
  String get posInvSalesStatDistinctItems;

  /// No description provided for @posInvSalesStatUniqueServices.
  ///
  /// In en, this message translates to:
  /// **'Unique services'**
  String get posInvSalesStatUniqueServices;

  /// No description provided for @posInvSalesStartDate.
  ///
  /// In en, this message translates to:
  /// **'START DATE'**
  String get posInvSalesStartDate;

  /// No description provided for @posInvSalesEndDate.
  ///
  /// In en, this message translates to:
  /// **'END DATE'**
  String get posInvSalesEndDate;

  /// No description provided for @posInvSalesStartTime.
  ///
  /// In en, this message translates to:
  /// **'START TIME'**
  String get posInvSalesStartTime;

  /// No description provided for @posInvSalesEndTime.
  ///
  /// In en, this message translates to:
  /// **'END TIME'**
  String get posInvSalesEndTime;

  /// No description provided for @posInvSalesClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get posInvSalesClear;

  /// No description provided for @posInvSalesApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get posInvSalesApply;

  /// No description provided for @posInvSalesNoSalesSubtitleFriendly.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different date range to see activity.'**
  String get posInvSalesNoSalesSubtitleFriendly;

  /// No description provided for @posInvSalesByItemPeriod.
  ///
  /// In en, this message translates to:
  /// **'SALES BY ITEM (PERIOD)'**
  String get posInvSalesByItemPeriod;

  /// No description provided for @posInvSalesItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ITEMS'**
  String posInvSalesItemsCount(int count);

  /// No description provided for @posInvSalesColItemName.
  ///
  /// In en, this message translates to:
  /// **'ITEM NAME'**
  String get posInvSalesColItemName;

  /// No description provided for @posInvSalesColDepartment.
  ///
  /// In en, this message translates to:
  /// **'DEPARTMENT'**
  String get posInvSalesColDepartment;

  /// No description provided for @posInvSalesColType.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get posInvSalesColType;

  /// No description provided for @posInvSalesColSkuShort.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get posInvSalesColSkuShort;

  /// No description provided for @posInvSalesColQtyShort.
  ///
  /// In en, this message translates to:
  /// **'QTY'**
  String get posInvSalesColQtyShort;

  /// No description provided for @posInvSalesErrStartTimeBeforeEndSameRange.
  ///
  /// In en, this message translates to:
  /// **'Start time must be on or before end time (same calendar range).'**
  String get posInvSalesErrStartTimeBeforeEndSameRange;

  /// No description provided for @posInvSalesErrEndTimeAfterStartSameRange.
  ///
  /// In en, this message translates to:
  /// **'End time must be on or after start time (same calendar range).'**
  String get posInvSalesErrEndTimeAfterStartSameRange;

  /// No description provided for @posInvSalesErrStartTimeBeforeEndRange.
  ///
  /// In en, this message translates to:
  /// **'Start time must be on or before end time for this date range.'**
  String get posInvSalesErrStartTimeBeforeEndRange;

  /// No description provided for @moreMenuBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'More Menu'**
  String get moreMenuBarrierLabel;

  /// No description provided for @posSalesReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales Return'**
  String get posSalesReturnTitle;

  /// No description provided for @posSalesReturnMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Return - {invoiceNo}'**
  String posSalesReturnMobileTitle(String invoiceNo);

  /// No description provided for @posSalesReturnResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get posSalesReturnResults;

  /// No description provided for @posSalesReturnSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. INV-123 or Name/Phone'**
  String get posSalesReturnSearchHint;

  /// No description provided for @posSalesReturnNoInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found for \"{query}\"'**
  String posSalesReturnNoInvoicesFound(String query);

  /// No description provided for @posSalesReturnSelectInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an Invoice'**
  String get posSalesReturnSelectInvoiceTitle;

  /// No description provided for @posSalesReturnSelectInvoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Search and select an invoice from the left\nto initiate its sales return process.'**
  String get posSalesReturnSelectInvoiceBody;

  /// No description provided for @posSalesReturnWalkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get posSalesReturnWalkInCustomer;

  /// No description provided for @posSalesReturnTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posSalesReturnTotal;

  /// No description provided for @posSalesReturnSelectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items to Return'**
  String get posSalesReturnSelectItems;

  /// No description provided for @posSalesReturnSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String posSalesReturnSelectedCount(int count);

  /// No description provided for @posSalesReturnProof.
  ///
  /// In en, this message translates to:
  /// **'Return Proof'**
  String get posSalesReturnProof;

  /// No description provided for @posSalesReturnOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get posSalesReturnOptional;

  /// No description provided for @posSalesReturnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posSalesReturnCancel;

  /// No description provided for @posSalesReturnSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Return'**
  String get posSalesReturnSubmit;

  /// No description provided for @posSalesReturnQty.
  ///
  /// In en, this message translates to:
  /// **'Return Qty'**
  String get posSalesReturnQty;

  /// No description provided for @posSalesReturnReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Select Return Reason'**
  String get posSalesReturnReasonHint;

  /// No description provided for @posSalesReturnUploadProof.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload proof image'**
  String get posSalesReturnUploadProof;

  /// No description provided for @posSalesReturnUploadFormats.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG up to 5MB'**
  String get posSalesReturnUploadFormats;

  /// No description provided for @posSalesReturnLinePrice.
  ///
  /// In en, this message translates to:
  /// **'{qty}x @ SAR {price}'**
  String posSalesReturnLinePrice(String qty, String price);

  /// No description provided for @posSalesReturnSarAmount.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String posSalesReturnSarAmount(String amount);

  /// No description provided for @posSalesReturnReasonDefective.
  ///
  /// In en, this message translates to:
  /// **'Defective Product/Service'**
  String get posSalesReturnReasonDefective;

  /// No description provided for @posSalesReturnReasonCancellation.
  ///
  /// In en, this message translates to:
  /// **'Customer Cancellation'**
  String get posSalesReturnReasonCancellation;

  /// No description provided for @posSalesReturnReasonWrongItem.
  ///
  /// In en, this message translates to:
  /// **'Wrong Item / Service'**
  String get posSalesReturnReasonWrongItem;

  /// No description provided for @posSalesReturnReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get posSalesReturnReasonOther;

  /// No description provided for @posSalesReturnErrorFetchInvoices.
  ///
  /// In en, this message translates to:
  /// **'Error fetching invoices. Ensure customer ID is correct.'**
  String get posSalesReturnErrorFetchInvoices;

  /// No description provided for @posSalesReturnErrorSelectItem.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one item to return'**
  String get posSalesReturnErrorSelectItem;

  /// No description provided for @posSalesReturnErrorQty.
  ///
  /// In en, this message translates to:
  /// **'Enter return quantity (at least 1) for each selected item before submitting.'**
  String get posSalesReturnErrorQty;

  /// No description provided for @posSalesReturnItemFullyReturned.
  ///
  /// In en, this message translates to:
  /// **'Already returned — no quantity left for this item.'**
  String get posSalesReturnItemFullyReturned;

  /// No description provided for @posSalesReturnItemPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Return pending workshop approval — check Returns List.'**
  String get posSalesReturnItemPendingApproval;

  /// No description provided for @posSalesReturnQtyAvailable.
  ///
  /// In en, this message translates to:
  /// **'{qty} available to return'**
  String posSalesReturnQtyAvailable(num qty);

  /// No description provided for @posSalesReturnSuccessSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sales return submitted for workshop approval. Check Returns List for status.'**
  String get posSalesReturnSuccessSubmitted;

  /// No description provided for @posSalesReturnStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get posSalesReturnStatusPending;

  /// No description provided for @posSalesReturnStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get posSalesReturnStatusCompleted;

  /// No description provided for @posSalesReturnStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get posSalesReturnStatusRejected;

  /// No description provided for @posSalesReturnStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get posSalesReturnStatusLabel;

  /// No description provided for @posSalesReturnRejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get posSalesReturnRejectionReasonLabel;

  /// No description provided for @posSalesReturnCreditNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit note'**
  String get posSalesReturnCreditNoteLabel;

  /// No description provided for @posSalesReturnErrorSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request: {error}'**
  String posSalesReturnErrorSubmit(String error);

  /// No description provided for @posSalesReturnErrorNoValidLines.
  ///
  /// In en, this message translates to:
  /// **'No valid return lines'**
  String get posSalesReturnErrorNoValidLines;

  /// No description provided for @posSalesReturnTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Token not found'**
  String get posSalesReturnTokenNotFound;

  /// No description provided for @posSalesReturnAuthTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found'**
  String get posSalesReturnAuthTokenNotFound;

  /// No description provided for @posSalesReturnListTitle.
  ///
  /// In en, this message translates to:
  /// **'Returns List'**
  String get posSalesReturnListTitle;

  /// No description provided for @posSalesReturnListFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load returns'**
  String get posSalesReturnListFailedLoad;

  /// No description provided for @posSalesReturnListNoReturns.
  ///
  /// In en, this message translates to:
  /// **'No sales returns found'**
  String get posSalesReturnListNoReturns;

  /// No description provided for @posSalesReturnListInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice: {invoiceNo}'**
  String posSalesReturnListInvoiceLabel(String invoiceNo);

  /// No description provided for @posSalesReturnRefundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount'**
  String get posSalesReturnRefundAmount;

  /// No description provided for @posSalesReturnDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Details'**
  String get posSalesReturnDetailsTitle;

  /// No description provided for @posSalesReturnDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full transaction summary'**
  String get posSalesReturnDetailsSubtitle;

  /// No description provided for @posSalesReturnItemsReturned.
  ///
  /// In en, this message translates to:
  /// **'Items Returned'**
  String get posSalesReturnItemsReturned;

  /// No description provided for @posSalesReturnCloseDetails.
  ///
  /// In en, this message translates to:
  /// **'Close Details'**
  String get posSalesReturnCloseDetails;

  /// No description provided for @posSalesReturnNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Return No'**
  String get posSalesReturnNoLabel;

  /// No description provided for @posSalesReturnInvoiceNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice No'**
  String get posSalesReturnInvoiceNoLabel;

  /// No description provided for @posSalesReturnOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get posSalesReturnOrderIdLabel;

  /// No description provided for @posSalesReturnCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get posSalesReturnCustomerLabel;

  /// No description provided for @posSalesReturnTotalRefund.
  ///
  /// In en, this message translates to:
  /// **'Total Refund'**
  String get posSalesReturnTotalRefund;

  /// No description provided for @posSalesReturnReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Return Reason'**
  String get posSalesReturnReasonLabel;

  /// No description provided for @posSalesReturnItemId.
  ///
  /// In en, this message translates to:
  /// **'Item ID: {itemId}'**
  String posSalesReturnItemId(String itemId);

  /// No description provided for @posSalesReturnItemQty.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String posSalesReturnItemQty(String qty);

  /// No description provided for @posSalesReturnListVmFailedFetch.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch returns'**
  String get posSalesReturnListVmFailedFetch;

  /// No description provided for @posStoreClosingTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Closing'**
  String get posStoreClosingTitle;

  /// No description provided for @posStoreClosingCounterReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Counter Reconciliation'**
  String get posStoreClosingCounterReconciliation;

  /// No description provided for @posStoreClosingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'RECONCILIATION SUMMARY'**
  String get posStoreClosingSummaryTitle;

  /// No description provided for @posStoreClosingShiftStatus.
  ///
  /// In en, this message translates to:
  /// **'Shift Closing Status'**
  String get posStoreClosingShiftStatus;

  /// No description provided for @posStoreClosingCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get posStoreClosingCashier;

  /// No description provided for @posStoreClosingBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get posStoreClosingBranch;

  /// No description provided for @posStoreClosingMainBranch.
  ///
  /// In en, this message translates to:
  /// **'Main Branch'**
  String get posStoreClosingMainBranch;

  /// No description provided for @posStoreClosingSessionStart.
  ///
  /// In en, this message translates to:
  /// **'Session Start'**
  String get posStoreClosingSessionStart;

  /// No description provided for @posStoreClosingSessionEnd.
  ///
  /// In en, this message translates to:
  /// **'Session End'**
  String get posStoreClosingSessionEnd;

  /// No description provided for @posStoreClosingDepartmentSales.
  ///
  /// In en, this message translates to:
  /// **'Department Sales'**
  String get posStoreClosingDepartmentSales;

  /// No description provided for @posStoreClosingDepartmentCol.
  ///
  /// In en, this message translates to:
  /// **'DEPARTMENT'**
  String get posStoreClosingDepartmentCol;

  /// No description provided for @posStoreClosingOrdersCol.
  ///
  /// In en, this message translates to:
  /// **'ORDERS'**
  String get posStoreClosingOrdersCol;

  /// No description provided for @posStoreClosingRevenueCol.
  ///
  /// In en, this message translates to:
  /// **'REVENUE (SAR)'**
  String get posStoreClosingRevenueCol;

  /// No description provided for @posStoreClosingDepartmentSearch.
  ///
  /// In en, this message translates to:
  /// **'Search department, orders, revenue…'**
  String get posStoreClosingDepartmentSearch;

  /// No description provided for @posStoreClosingDepartmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No department sales for this shift yet.'**
  String get posStoreClosingDepartmentEmpty;

  /// No description provided for @posStoreClosingDepartmentNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No rows match your search.'**
  String get posStoreClosingDepartmentNoMatch;

  /// No description provided for @posStoreClosingPhysicalDrawerCount.
  ///
  /// In en, this message translates to:
  /// **'Physical Drawer Count'**
  String get posStoreClosingPhysicalDrawerCount;

  /// No description provided for @posStoreClosingPhysicalDrawerHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the physical amounts you have counted for each payment category.'**
  String get posStoreClosingPhysicalDrawerHint;

  /// No description provided for @posStoreClosingPhysicalCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Physical Cash Amount'**
  String get posStoreClosingPhysicalCashAmount;

  /// No description provided for @posStoreClosingBankCardSlips.
  ///
  /// In en, this message translates to:
  /// **'Bank / Card Slips'**
  String get posStoreClosingBankCardSlips;

  /// No description provided for @posStoreClosingCorporateInvoices.
  ///
  /// In en, this message translates to:
  /// **'Corporate Invoices'**
  String get posStoreClosingCorporateInvoices;

  /// No description provided for @posStoreClosingTamaraCredits.
  ///
  /// In en, this message translates to:
  /// **'Tamara Credits'**
  String get posStoreClosingTamaraCredits;

  /// No description provided for @posStoreClosingTabbyCredits.
  ///
  /// In en, this message translates to:
  /// **'Tabby Credits'**
  String get posStoreClosingTabbyCredits;

  /// No description provided for @posStoreClosingOthersEmployeeSales.
  ///
  /// In en, this message translates to:
  /// **'Others (Employee sales)'**
  String get posStoreClosingOthersEmployeeSales;

  /// No description provided for @posStoreClosingNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get posStoreClosingNotesOptional;

  /// No description provided for @posStoreClosingTotalPhysicalSum.
  ///
  /// In en, this message translates to:
  /// **'Total Physical Sum'**
  String get posStoreClosingTotalPhysicalSum;

  /// No description provided for @posStoreClosingExpectedAmount.
  ///
  /// In en, this message translates to:
  /// **'Expected: SAR {amount}'**
  String posStoreClosingExpectedAmount(String amount);

  /// No description provided for @posStoreClosingAddNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes here...'**
  String get posStoreClosingAddNotesHint;

  /// No description provided for @posStoreClosingShiftBalanced.
  ///
  /// In en, this message translates to:
  /// **'Shift Balanced'**
  String get posStoreClosingShiftBalanced;

  /// No description provided for @posStoreClosingDiscrepancyDetected.
  ///
  /// In en, this message translates to:
  /// **'Discrepancy Detected'**
  String get posStoreClosingDiscrepancyDetected;

  /// No description provided for @posStoreClosingShiftClosedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shift closed successfully.'**
  String get posStoreClosingShiftClosedSuccessfully;

  /// No description provided for @posStoreClosingGrossNetExplanation.
  ///
  /// In en, this message translates to:
  /// **'System column is gross POS settled amounts. Diff compares each bucket’s expected net (after sales returns) to physical, not (gross − physical). Positive diff = system higher than physical.'**
  String get posStoreClosingGrossNetExplanation;

  /// No description provided for @posStoreClosingPositiveDiff.
  ///
  /// In en, this message translates to:
  /// **'Positive diff = system > physical.'**
  String get posStoreClosingPositiveDiff;

  /// No description provided for @posStoreClosingClosingId.
  ///
  /// In en, this message translates to:
  /// **'Closing ID'**
  String get posStoreClosingClosingId;

  /// No description provided for @posStoreClosingCashAccount.
  ///
  /// In en, this message translates to:
  /// **'Cash Account'**
  String get posStoreClosingCashAccount;

  /// No description provided for @posStoreClosingBankCards.
  ///
  /// In en, this message translates to:
  /// **'Bank / Cards'**
  String get posStoreClosingBankCards;

  /// No description provided for @posStoreClosingCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get posStoreClosingCorporate;

  /// No description provided for @posStoreClosingTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara'**
  String get posStoreClosingTamara;

  /// No description provided for @posStoreClosingTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby'**
  String get posStoreClosingTabby;

  /// No description provided for @posStoreClosingOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get posStoreClosingOthers;

  /// No description provided for @posStoreClosingCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get posStoreClosingCategory;

  /// No description provided for @posStoreClosingSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get posStoreClosingSystem;

  /// No description provided for @posStoreClosingGross.
  ///
  /// In en, this message translates to:
  /// **'(gross)'**
  String get posStoreClosingGross;

  /// No description provided for @posStoreClosingPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get posStoreClosingPhysical;

  /// No description provided for @posStoreClosingDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get posStoreClosingDiff;

  /// No description provided for @posStoreClosingNet.
  ///
  /// In en, this message translates to:
  /// **'(net)'**
  String get posStoreClosingNet;

  /// No description provided for @posStoreClosingLessSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Less: Total sales return'**
  String get posStoreClosingLessSalesReturn;

  /// No description provided for @posStoreClosingGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get posStoreClosingGrandTotal;

  /// No description provided for @posStoreClosingCloseShift.
  ///
  /// In en, this message translates to:
  /// **'Close Shift'**
  String get posStoreClosingCloseShift;

  /// No description provided for @posStoreClosingPrinterHint.
  ///
  /// In en, this message translates to:
  /// **'Tap: Wi‑Fi thermal print. Long‑press: printer IP / port.'**
  String get posStoreClosingPrinterHint;

  /// No description provided for @posStoreClosingSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'save successfully'**
  String get posStoreClosingSaveSuccess;

  /// No description provided for @posStoreClosingReceiptSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to Wi‑Fi printer.'**
  String get posStoreClosingReceiptSent;

  /// No description provided for @posStoreClosingPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get posStoreClosingPrint;

  /// No description provided for @posStoreClosingViewPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get posStoreClosingViewPdf;

  /// No description provided for @posStoreClosingPdfPreviewError.
  ///
  /// In en, this message translates to:
  /// **'Could not load closing report.'**
  String get posStoreClosingPdfPreviewError;

  /// No description provided for @posStoreClosingFinalLogout.
  ///
  /// In en, this message translates to:
  /// **'Final Logout'**
  String get posStoreClosingFinalLogout;

  /// No description provided for @posStoreClosingLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get posStoreClosingLogout;

  /// No description provided for @posStoreClosingLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from your account?'**
  String get posStoreClosingLogoutConfirm;

  /// No description provided for @posStoreClosingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get posStoreClosingCancel;

  /// No description provided for @posStoreClosingVmSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shift closed successfully!'**
  String get posStoreClosingVmSuccess;

  /// No description provided for @posStoreClosingVmFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to close shift: {error}'**
  String posStoreClosingVmFailed(String error);

  /// No description provided for @posStoreClosingVmCounterFailed.
  ///
  /// In en, this message translates to:
  /// **'Counter closing failed'**
  String get posStoreClosingVmCounterFailed;

  /// No description provided for @posStoreClosingPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Closing Report'**
  String get posStoreClosingPdfTitle;

  /// No description provided for @posStoreClosingPdfCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get posStoreClosingPdfCategory;

  /// No description provided for @posStoreClosingPdfSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get posStoreClosingPdfSystem;

  /// No description provided for @posStoreClosingPdfPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get posStoreClosingPdfPhysical;

  /// No description provided for @posStoreClosingPdfDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get posStoreClosingPdfDifference;

  /// No description provided for @posTechnicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get posTechnicianTitle;

  /// No description provided for @posTechnicianAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Assignment'**
  String get posTechnicianAssignmentTitle;

  /// No description provided for @posTechnicianSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search technicians...'**
  String get posTechnicianSearchHint;

  /// No description provided for @posTechnicianErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String posTechnicianErrorPrefix(String message);

  /// No description provided for @posTechnicianOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online Only'**
  String get posTechnicianOnlineOnly;

  /// No description provided for @posTechnicianShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get posTechnicianShowAll;

  /// No description provided for @posTechnicianLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading technicians…'**
  String get posTechnicianLoading;

  /// No description provided for @posTechnicianLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {time}'**
  String posTechnicianLastSeen(String time);

  /// No description provided for @posTechnicianSlots.
  ///
  /// In en, this message translates to:
  /// **'Slots: {used}/{total}'**
  String posTechnicianSlots(int used, int total);

  /// No description provided for @posTechnicianWait.
  ///
  /// In en, this message translates to:
  /// **'Wait {duration}'**
  String posTechnicianWait(String duration);

  /// No description provided for @posTechnicianBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get posTechnicianBroadcast;

  /// No description provided for @posTechnicianSave.
  ///
  /// In en, this message translates to:
  /// **'Save Technicians'**
  String get posTechnicianSave;

  /// No description provided for @posTechnicianAssignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technicians assigned successfully'**
  String get posTechnicianAssignSuccess;

  /// No description provided for @posTechnicianRemoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'All technicians removed from this job'**
  String get posTechnicianRemoveSuccess;

  /// No description provided for @posTechnicianAssignFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign technicians'**
  String get posTechnicianAssignFailed;

  /// No description provided for @posTechnicianFailedJobEdit.
  ///
  /// In en, this message translates to:
  /// **'Failed to get job ID for edit'**
  String get posTechnicianFailedJobEdit;

  /// No description provided for @posTechnicianFailedOrderId.
  ///
  /// In en, this message translates to:
  /// **'Failed to get order ID'**
  String get posTechnicianFailedOrderId;

  /// No description provided for @posTechnicianJobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found for this assignment.'**
  String get posTechnicianJobNotFound;

  /// No description provided for @posTechnicianUnlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock job to change technicians. Try again.'**
  String get posTechnicianUnlockFailed;

  /// No description provided for @posTechnicianGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get posTechnicianGeneral;

  /// No description provided for @posTechnicianTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Token not found'**
  String get posTechnicianTokenNotFound;

  /// No description provided for @posTechnicianFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch technicians'**
  String get posTechnicianFetchFailed;

  /// No description provided for @posTechnicianOldAssignWarning.
  ///
  /// In en, this message translates to:
  /// **'Technician was not assigned. The server may still count old assignments on this job.'**
  String get posTechnicianOldAssignWarning;

  /// No description provided for @posTechnicianAddOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'Cannot apply removals: server treats assign as add-only. Backend must sync employeeIds to the full desired list (or honor sync: true).'**
  String get posTechnicianAddOnlyWarning;

  /// No description provided for @posTechnicianNoneAssignedWarning.
  ///
  /// In en, this message translates to:
  /// **'No technicians were assigned. The server may still count cancelled assignments on this job.'**
  String get posTechnicianNoneAssignedWarning;

  /// No description provided for @posTechnicianOnlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Mark this technician online before changing workshop or on-call duty.'**
  String get posTechnicianOnlineFirst;

  /// No description provided for @posTechnicianNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get posTechnicianNotSignedIn;

  /// No description provided for @posTechnicianDutyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update duty'**
  String get posTechnicianDutyFailed;

  /// No description provided for @posTechnicianDutyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Duty updated'**
  String get posTechnicianDutyUpdated;

  /// No description provided for @posTechnicianStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get posTechnicianStatusFailed;

  /// No description provided for @posTechnicianMarkedOnline.
  ///
  /// In en, this message translates to:
  /// **'Technician marked online'**
  String get posTechnicianMarkedOnline;

  /// No description provided for @posTechnicianMarkedOffline.
  ///
  /// In en, this message translates to:
  /// **'Technician marked offline'**
  String get posTechnicianMarkedOffline;

  /// No description provided for @posTakeawayTitle.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get posTakeawayTitle;

  /// No description provided for @posTakeawayRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get posTakeawayRetry;

  /// No description provided for @posTakeawaySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products & services...'**
  String get posTakeawaySearchHint;

  /// No description provided for @posTakeawayRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get posTakeawayRefresh;

  /// No description provided for @posTakeawayAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get posTakeawayAll;

  /// No description provided for @posTakeawayOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get posTakeawayOrderItems;

  /// No description provided for @posTakeawayNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items in invoice'**
  String get posTakeawayNoItems;

  /// No description provided for @posTakeawayGrossExVat.
  ///
  /// In en, this message translates to:
  /// **'Gross Amount (Excl. VAT)'**
  String get posTakeawayGrossExVat;

  /// No description provided for @posTakeawayLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line discount'**
  String get posTakeawayLineDiscount;

  /// No description provided for @posTakeawayPriceAfterLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Price after line discount'**
  String get posTakeawayPriceAfterLineDiscount;

  /// No description provided for @posTakeawayTotalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Total discount'**
  String get posTakeawayTotalDiscount;

  /// No description provided for @posTakeawayAmount.
  ///
  /// In en, this message translates to:
  /// **'amount'**
  String get posTakeawayAmount;

  /// No description provided for @posTakeawayPercent.
  ///
  /// In en, this message translates to:
  /// **'percent'**
  String get posTakeawayPercent;

  /// No description provided for @posTakeawayTotalDiscountApplied.
  ///
  /// In en, this message translates to:
  /// **'Total discount applied'**
  String get posTakeawayTotalDiscountApplied;

  /// No description provided for @posTakeawayPriceAfterTotalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Price after total discount'**
  String get posTakeawayPriceAfterTotalDiscount;

  /// No description provided for @posTakeawayAddPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Add Promo Code'**
  String get posTakeawayAddPromoCode;

  /// No description provided for @posTakeawayPromoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo: {code}'**
  String posTakeawayPromoApplied(String code);

  /// No description provided for @posTakeawayPromoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo discount'**
  String get posTakeawayPromoDiscount;

  /// No description provided for @posTakeawayPriceAfterPromo.
  ///
  /// In en, this message translates to:
  /// **'Price after promo'**
  String get posTakeawayPriceAfterPromo;

  /// No description provided for @posTakeawayVat15.
  ///
  /// In en, this message translates to:
  /// **'VAT (15%)'**
  String get posTakeawayVat15;

  /// No description provided for @posTakeawayTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posTakeawayTotal;

  /// No description provided for @posTakeawayAddCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Add customer details'**
  String get posTakeawayAddCustomerDetails;

  /// No description provided for @posTakeawayCustomerAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get posTakeawayCustomerAndPayment;

  /// No description provided for @posTakeawayCheckoutDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get posTakeawayCheckoutDetailsTitle;

  /// No description provided for @posTakeawayCheckoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer and payment saved'**
  String get posTakeawayCheckoutSaved;

  /// No description provided for @posTakeawayBranchEmployeeBilling.
  ///
  /// In en, this message translates to:
  /// **'Branch employee billing'**
  String get posTakeawayBranchEmployeeBilling;

  /// No description provided for @posTakeawayNoBranchEmployees.
  ///
  /// In en, this message translates to:
  /// **'No staff found for this branch.'**
  String get posTakeawayNoBranchEmployees;

  /// No description provided for @posTakeawaySelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select employee'**
  String get posTakeawaySelectEmployee;

  /// No description provided for @posTakeawaySelectEmployeeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an employee'**
  String get posTakeawaySelectEmployeeRequired;

  /// No description provided for @posTakeawayCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get posTakeawayCustomerName;

  /// No description provided for @posTakeawayCustomerMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get posTakeawayCustomerMobile;

  /// No description provided for @posTakeawayCustomerVat.
  ///
  /// In en, this message translates to:
  /// **'VAT (optional)'**
  String get posTakeawayCustomerVat;

  /// No description provided for @posTakeawaySelectPayment.
  ///
  /// In en, this message translates to:
  /// **'Select payment'**
  String get posTakeawaySelectPayment;

  /// No description provided for @posTakeawayGenerateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get posTakeawayGenerateInvoice;

  /// No description provided for @posTakeawayNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get posTakeawayNoProductsFound;

  /// No description provided for @posTakeawayNoProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get posTakeawayNoProductsMatch;

  /// No description provided for @posTakeawayUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit: {unit}'**
  String posTakeawayUnit(String unit);

  /// No description provided for @posTakeawayItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String posTakeawayItemsCount(int count);

  /// No description provided for @posTakeawayGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get posTakeawayGrandTotal;

  /// No description provided for @posTakeawayCustomerSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer details saved'**
  String get posTakeawayCustomerSaved;

  /// No description provided for @posTakeawayPaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get posTakeawayPaymentSaved;

  /// No description provided for @posTakeawayCustomerRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name and mobile number are required.'**
  String get posTakeawayCustomerRequired;

  /// No description provided for @posTakeawaySelectPaymentFirst.
  ///
  /// In en, this message translates to:
  /// **'Select payment method first.'**
  String get posTakeawaySelectPaymentFirst;

  /// No description provided for @posTakeawayValidPaymentAmounts.
  ///
  /// In en, this message translates to:
  /// **'Add valid payment amounts to continue.'**
  String get posTakeawayValidPaymentAmounts;

  /// No description provided for @posTakeawayInvoiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate invoice'**
  String get posTakeawayInvoiceFailed;

  /// No description provided for @posTakeawayInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get posTakeawayInactive;

  /// No description provided for @posTakeawayInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock ({qty})'**
  String posTakeawayInStock(String qty);

  /// No description provided for @posTakeawayLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low ({qty})'**
  String posTakeawayLowStock(String qty);

  /// No description provided for @posTakeawayOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get posTakeawayOutOfStock;

  /// No description provided for @posTakeawayDis.
  ///
  /// In en, this message translates to:
  /// **'Dis.'**
  String get posTakeawayDis;

  /// No description provided for @posTakeawayNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get posTakeawayNotLoggedIn;

  /// No description provided for @posTakeawayCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty.'**
  String get posTakeawayCartEmpty;

  /// No description provided for @posTakeawayWalkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get posTakeawayWalkInCustomer;

  /// No description provided for @posTakeawayNoInvoiceResponse.
  ///
  /// In en, this message translates to:
  /// **'No invoice in response'**
  String get posTakeawayNoInvoiceResponse;

  /// No description provided for @posTakeawayCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Checkout failed'**
  String get posTakeawayCheckoutFailed;

  /// No description provided for @posCommonSarAmount.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount}'**
  String posCommonSarAmount(String amount);

  /// No description provided for @posCommonQtyX.
  ///
  /// In en, this message translates to:
  /// **'x{qty}'**
  String posCommonQtyX(String qty);

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get posPromoTitle;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Available Promotions'**
  String get posPromoAvailablePromotions;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'No promotions available'**
  String get posPromoNoPromotionsAvailable;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo Code'**
  String get posPromoApplyPromoCode;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Select a promo below'**
  String get posPromoSelectPromoBelow;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'No promo codes available'**
  String get posPromoNoPromoCodesAvailable;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get posPromoEnterCodeManually;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get posPromoExampleSave10;

  /// POS cart — confirm removing a line that invalidates an applied promo.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get posPromoRemoveItemConfirmTitle;

  /// POS cart — body when removing item breaks promo.
  ///
  /// In en, this message translates to:
  /// **'Removing \"{itemName}\" will remove promo \"{promoCode}\" because promo conditions will no longer be met.'**
  String posPromoRemoveItemConfirmBody(String itemName, String promoCode);

  /// POS cart — confirm remove item and clear promo.
  ///
  /// In en, this message translates to:
  /// **'Remove item & promo'**
  String get posPromoRemoveItemConfirmAction;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Remove Promo'**
  String get posPromoRemovePromo;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'remove promo'**
  String get posPromoRemovePromoLower;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Valid promo code'**
  String get posPromoValidPromoCode;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get posPromoDiscountLabel;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get posPromoStoreLabel;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get posPromoProductsLabel;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get posPromoValidityLabel;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Check Code'**
  String get posPromoCheckCode;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount'**
  String get posPromoApplyDiscount;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Check the promo code details and conditions.'**
  String get posPromoCheckDescription;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Check validity'**
  String get posPromoCheckValidity;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Check conditions'**
  String get posPromoCheckConditions;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get posProductInvalidQuantity;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get posProductQuantity;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get posProductInventory;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get posProductItems;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'No items in invoice'**
  String get posProductNoItemsInInvoice;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Gross excl. VAT'**
  String get posProductGrossExclVat;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Promo:'**
  String get posProductPromoPrefix;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get posProductSave;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Order completed successfully'**
  String get posProductOrderCompletedSuccess;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete job'**
  String get posProductFailedCompleteJob;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'No products match your search'**
  String get posProductNoProductsMatch;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get posProductProductsTitle;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get posProductServicesTitle;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get posProductUnitPrefix;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Disc.'**
  String get posProductDiscountAbbrev;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get posPettyCashTabExpense;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get posPettyCashTabFund;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get posPettyCashTabHistory;

  /// POS petty cash tab for expenses that do not deduct wallet.
  ///
  /// In en, this message translates to:
  /// **'Non Cash'**
  String get posPettyCashTabNoCash;

  /// No description provided for @posPettyCashNoCashDetails.
  ///
  /// In en, this message translates to:
  /// **'Non cash expense'**
  String get posPettyCashNoCashDetails;

  /// No description provided for @posPettyCashDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get posPettyCashDate;

  /// No description provided for @posPettyCashBillNo.
  ///
  /// In en, this message translates to:
  /// **'Bill no'**
  String get posPettyCashBillNo;

  /// No description provided for @posPettyCashBillNoHint.
  ///
  /// In en, this message translates to:
  /// **'Enter bill number'**
  String get posPettyCashBillNoHint;

  /// No description provided for @posPettyCashSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get posPettyCashSupplier;

  /// No description provided for @posPettyCashSelectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select or enter supplier'**
  String get posPettyCashSelectSupplier;

  /// No description provided for @posPettyCashSearchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search supplier'**
  String get posPettyCashSearchSupplier;

  /// No description provided for @posPettyCashNoSupplierMatches.
  ///
  /// In en, this message translates to:
  /// **'No supplier matches'**
  String get posPettyCashNoSupplierMatches;

  /// No description provided for @posPettyCashLoadingSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Loading suppliers…'**
  String get posPettyCashLoadingSuppliers;

  /// No description provided for @posPettyCashOtherSupplier.
  ///
  /// In en, this message translates to:
  /// **'Other supplier name'**
  String get posPettyCashOtherSupplier;

  /// No description provided for @posPettyCashOtherSupplierHint.
  ///
  /// In en, this message translates to:
  /// **'If supplier is not in the list'**
  String get posPettyCashOtherSupplierHint;

  /// No description provided for @posPettyCashDepartmentName.
  ///
  /// In en, this message translates to:
  /// **'Department name'**
  String get posPettyCashDepartmentName;

  /// No description provided for @posPettyCashDepartmentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter department'**
  String get posPettyCashDepartmentHint;

  /// No description provided for @posPettyCashSelectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Select department'**
  String get posPettyCashSelectDepartment;

  /// No description provided for @posPettyCashSearchDepartment.
  ///
  /// In en, this message translates to:
  /// **'Search department'**
  String get posPettyCashSearchDepartment;

  /// No description provided for @posPettyCashNoDepartmentMatches.
  ///
  /// In en, this message translates to:
  /// **'No department matches'**
  String get posPettyCashNoDepartmentMatches;

  /// No description provided for @posPettyCashLoadingDepartments.
  ///
  /// In en, this message translates to:
  /// **'Loading departments…'**
  String get posPettyCashLoadingDepartments;

  /// No description provided for @posPettyCashExpenseList.
  ///
  /// In en, this message translates to:
  /// **'Expense list'**
  String get posPettyCashExpenseList;

  /// No description provided for @posPettyCashSelectExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Select expense'**
  String get posPettyCashSelectExpenseType;

  /// No description provided for @posPettyCashSearchExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Search expense'**
  String get posPettyCashSearchExpenseType;

  /// No description provided for @posPettyCashNoExpenseTypeMatches.
  ///
  /// In en, this message translates to:
  /// **'No expense matches'**
  String get posPettyCashNoExpenseTypeMatches;

  /// No description provided for @posPettyCashRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get posPettyCashRemarks;

  /// No description provided for @posPettyCashRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'Enter remarks'**
  String get posPettyCashRemarksHint;

  /// No description provided for @posPettyCashPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get posPettyCashPhotos;

  /// No description provided for @posPettyCashAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos from camera or gallery'**
  String get posPettyCashAddPhotos;

  /// No description provided for @posPettyCashSubmitNoCash.
  ///
  /// In en, this message translates to:
  /// **'Submit non cash expense'**
  String get posPettyCashSubmitNoCash;

  /// No description provided for @posPettyCashNoCashSubmittedPending.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully'**
  String get posPettyCashNoCashSubmittedPending;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Available Petty Cash'**
  String get posPettyCashAvailablePettyCash;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Low balance warning'**
  String get posPettyCashLowBalanceWarning;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Expense submitted for approval.'**
  String get posPettyCashExpenseSubmittedPending;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Fund request submitted for approval.'**
  String get posPettyCashFundRequestSubmittedPending;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get posCommonSelectDate;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get posCommonFrom;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get posCommonTo;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get posCommonReset;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'Expense & Fund History'**
  String get posPettyCashExpenseFundHistory;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'No history found for this filter'**
  String get posPettyCashNoHistoryForFilter;

  /// POS UI translation key.
  ///
  /// In en, this message translates to:
  /// **'This request is pending approval.'**
  String get posPettyCashPendingExplanation;

  /// No description provided for @posProductsBranchPrefix.
  ///
  /// In en, this message translates to:
  /// **'Branch:'**
  String get posProductsBranchPrefix;

  /// No description provided for @posProductsFailedLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get posProductsFailedLoadProducts;

  /// No description provided for @posNavInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get posNavInventory;

  /// No description provided for @posNavSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Sales Return'**
  String get posNavSalesReturn;

  /// No description provided for @posNavReturnsList.
  ///
  /// In en, this message translates to:
  /// **'Returns List'**
  String get posNavReturnsList;

  /// No description provided for @posNavPettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get posNavPettyCash;

  /// No description provided for @posNavPromoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo Codes'**
  String get posNavPromoCodes;

  /// No description provided for @posNavTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get posNavTechnicians;

  /// No description provided for @posNavCurrentShift.
  ///
  /// In en, this message translates to:
  /// **'Current Shift'**
  String get posNavCurrentShift;

  /// No description provided for @posShellVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.1'**
  String get posShellVersion;

  /// No description provided for @posOrdersHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders Hub'**
  String get posOrdersHubTitle;

  /// No description provided for @posOrdersRefreshOrders.
  ///
  /// In en, this message translates to:
  /// **'Refresh orders'**
  String get posOrdersRefreshOrders;

  /// No description provided for @posOrdersSearchPlateNameId.
  ///
  /// In en, this message translates to:
  /// **'Search plate, name, ID...'**
  String get posOrdersSearchPlateNameId;

  /// No description provided for @posOrdersProductsAndServices.
  ///
  /// In en, this message translates to:
  /// **'Products & Services'**
  String get posOrdersProductsAndServices;

  /// No description provided for @posOrdersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get posOrdersEdit;

  /// No description provided for @posOrdersCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get posOrdersCancelled;

  /// No description provided for @posOrdersNoProductsOrServices.
  ///
  /// In en, this message translates to:
  /// **'No products or services'**
  String get posOrdersNoProductsOrServices;

  /// No description provided for @posOrdersMaintenanceChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance checklist'**
  String get posOrdersMaintenanceChecklistTitle;

  /// No description provided for @posOrdersMaintenanceChecklistDescription.
  ///
  /// In en, this message translates to:
  /// **'These items appear on the printed invoice when checked.'**
  String get posOrdersMaintenanceChecklistDescription;

  /// No description provided for @posOrdersChecklistSaved.
  ///
  /// In en, this message translates to:
  /// **'Maintenance checklist saved.'**
  String get posOrdersChecklistSaved;

  /// No description provided for @posOrdersPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get posOrdersPleaseSignInAgain;

  /// No description provided for @posSessionClosedLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Your shift session was already closed, so you have been logged out.'**
  String get posSessionClosedLoggedOut;

  /// No description provided for @posOrdersQtyWithoutVat.
  ///
  /// In en, this message translates to:
  /// **'Qty {qty} × {price} Without VAT'**
  String posOrdersQtyWithoutVat(String qty, String price);

  /// No description provided for @posOrdersChecklistOptional.
  ///
  /// In en, this message translates to:
  /// **'Select checklist'**
  String get posOrdersChecklistOptional;

  /// No description provided for @posOrdersChecklistSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get posOrdersChecklistSelectAll;

  /// No description provided for @posOrdersChecklistClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get posOrdersChecklistClearAll;

  /// No description provided for @posOrdersEditCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit customer details'**
  String get posOrdersEditCustomerDetails;

  /// No description provided for @posOrdersCustomerAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Customer & payment'**
  String get posOrdersCustomerAndPayment;

  /// No description provided for @posOrdersCheckoutDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer & payment'**
  String get posOrdersCheckoutDetailsTitle;

  /// No description provided for @posOrdersCheckoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer and payment saved'**
  String get posOrdersCheckoutSaved;

  /// No description provided for @posOrdersTotalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Total discount'**
  String get posOrdersTotalDiscount;

  /// No description provided for @posOrdersNoFurtherEditsAllowed.
  ///
  /// In en, this message translates to:
  /// **'No further edits allowed'**
  String get posOrdersNoFurtherEditsAllowed;

  /// No description provided for @posOrdersPrintInvoiceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice & Receipt'**
  String get posOrdersPrintInvoiceReceipt;

  /// No description provided for @posOrdersNoTechnicianCommissions.
  ///
  /// In en, this message translates to:
  /// **'No technician commissions.'**
  String get posOrdersNoTechnicianCommissions;

  /// No description provided for @posOrdersTechnicianCommission.
  ///
  /// In en, this message translates to:
  /// **'TECHNICIAN COMMISSION'**
  String get posOrdersTechnicianCommission;

  /// No description provided for @posOrdersAssignedTechnicians.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED TECHNICIANS'**
  String get posOrdersAssignedTechnicians;

  /// No description provided for @posOrdersNoTechnicianAssigned.
  ///
  /// In en, this message translates to:
  /// **'No technician assigned'**
  String get posOrdersNoTechnicianAssigned;

  /// No description provided for @posInvoiceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice details'**
  String get posInvoiceDetailsTitle;

  /// No description provided for @posInvoiceDetailsCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get posInvoiceDetailsCustomerDetails;

  /// No description provided for @posInvoiceDetailsConfirmVehicle.
  ///
  /// In en, this message translates to:
  /// **'Confirm billing contact and vehicle before creating the invoice.'**
  String get posInvoiceDetailsConfirmVehicle;

  /// No description provided for @posInvoiceDetailsConfirmContact.
  ///
  /// In en, this message translates to:
  /// **'Confirm billing contact before creating the invoice.'**
  String get posInvoiceDetailsConfirmContact;

  /// No description provided for @posInvoiceDetailsBranchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Customer is a branch employee'**
  String get posInvoiceDetailsBranchEmployee;

  /// No description provided for @posInvoiceDetailsPickStaff.
  ///
  /// In en, this message translates to:
  /// **'Pick from staff list to fill name and mobile.'**
  String get posInvoiceDetailsPickStaff;

  /// No description provided for @posInvoiceDetailsLoadingEmployees.
  ///
  /// In en, this message translates to:
  /// **'Loading employees…'**
  String get posInvoiceDetailsLoadingEmployees;

  /// No description provided for @posInvoiceDetailsNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees listed for this branch.'**
  String get posInvoiceDetailsNoEmployees;

  /// No description provided for @posInvoiceDetailsEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get posInvoiceDetailsEmployee;

  /// No description provided for @posInvoiceDetailsChooseEmployee.
  ///
  /// In en, this message translates to:
  /// **'Choose employee'**
  String get posInvoiceDetailsChooseEmployee;

  /// No description provided for @posInvoiceDetailsCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get posInvoiceDetailsCustomerName;

  /// No description provided for @posInvoiceDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get posInvoiceDetailsRequired;

  /// No description provided for @posInvoiceDetailsMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get posInvoiceDetailsMobile;

  /// No description provided for @posInvoiceDetailsVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get posInvoiceDetailsVat;

  /// No description provided for @posInvoiceDetailsPlateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get posInvoiceDetailsPlateNumber;

  /// No description provided for @posInvoiceDetailsPlateRequired.
  ///
  /// In en, this message translates to:
  /// **'Plate is required'**
  String get posInvoiceDetailsPlateRequired;

  /// No description provided for @posInvoiceDetailsPlateSaudiLength.
  ///
  /// In en, this message translates to:
  /// **'Saudi plate: exactly 3 letters and 1 to 4 digits'**
  String get posInvoiceDetailsPlateSaudiLength;

  /// No description provided for @posInvoiceDetailsPlateSaudiDigits.
  ///
  /// In en, this message translates to:
  /// **'Saudi plate needs 1 to 4 digits (after the 3 letters)'**
  String get posInvoiceDetailsPlateSaudiDigits;

  /// No description provided for @posInvoiceDetailsPlateSaudiThreeLetters.
  ///
  /// In en, this message translates to:
  /// **'Saudi plate needs exactly 3 letters'**
  String get posInvoiceDetailsPlateSaudiThreeLetters;

  /// No description provided for @posInvoiceDetailsPlateSaudiLetterChars.
  ///
  /// In en, this message translates to:
  /// **'Saudi plate letters must be valid (Latin or Arabic)'**
  String get posInvoiceDetailsPlateSaudiLetterChars;

  /// No description provided for @posInvoiceDetailsOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get posInvoiceDetailsOdometer;

  /// No description provided for @posInvoiceDetailsMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get posInvoiceDetailsMake;

  /// No description provided for @posInvoiceDetailsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get posInvoiceDetailsModel;

  /// No description provided for @posInvoiceDetailsYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get posInvoiceDetailsYear;

  /// No description provided for @posInvoiceDetailsInvalidYear.
  ///
  /// In en, this message translates to:
  /// **'Invalid year'**
  String get posInvoiceDetailsInvalidYear;

  /// No description provided for @posInvoiceDetailsVin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get posInvoiceDetailsVin;

  /// No description provided for @posInvoiceDetailsSaveProceed.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue to Invoice'**
  String get posInvoiceDetailsSaveProceed;

  /// No description provided for @posPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get posPaymentMethodTitle;

  /// No description provided for @posPaymentMethodDescription.
  ///
  /// In en, this message translates to:
  /// **'Select customer type, then choose how this invoice will be paid.'**
  String get posPaymentMethodDescription;

  /// No description provided for @posPaymentCustomerType.
  ///
  /// In en, this message translates to:
  /// **'Customer type'**
  String get posPaymentCustomerType;

  /// No description provided for @posPaymentIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get posPaymentIndividual;

  /// No description provided for @posPaymentCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get posPaymentCorporate;

  /// No description provided for @posPaymentTapCustomerFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap Individual or Corporate first. Then choose Cash, Card, Tabby, etc.'**
  String get posPaymentTapCustomerFirst;

  /// No description provided for @posPaymentCorporateMulti.
  ///
  /// In en, this message translates to:
  /// **'Corporate payment (multi-select to split)'**
  String get posPaymentCorporateMulti;

  /// No description provided for @posPaymentMulti.
  ///
  /// In en, this message translates to:
  /// **'Payment (multi-select to split)'**
  String get posPaymentMulti;

  /// No description provided for @posPaymentAmountByMethod.
  ///
  /// In en, this message translates to:
  /// **'Amount by payment method'**
  String get posPaymentAmountByMethod;

  /// No description provided for @posPaymentRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount} SAR'**
  String posPaymentRemaining(String amount);

  /// No description provided for @posPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'{method} amount'**
  String posPaymentAmountLabel(String method);

  /// No description provided for @posPaymentClearSaved.
  ///
  /// In en, this message translates to:
  /// **'Clear saved payment'**
  String get posPaymentClearSaved;

  /// No description provided for @posPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get posPaymentCash;

  /// No description provided for @posPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get posPaymentCard;

  /// No description provided for @posPaymentTapToPay.
  ///
  /// In en, this message translates to:
  /// **'Tap to Pay'**
  String get posPaymentTapToPay;

  /// No description provided for @posPaymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get posPaymentBankTransfer;

  /// No description provided for @posPaymentTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara'**
  String get posPaymentTamara;

  /// No description provided for @posPaymentTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby'**
  String get posPaymentTabby;

  /// No description provided for @posPaymentWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get posPaymentWallet;

  /// No description provided for @posPaymentMonthlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Monthly Billing'**
  String get posPaymentMonthlyBilling;

  /// No description provided for @posPaymentEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get posPaymentEmployees;

  /// No description provided for @posProductNoOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get posProductNoOrdersFound;

  /// No description provided for @posProductOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get posProductOutOfStock;

  /// No description provided for @posProductLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get posProductLowStock;

  /// No description provided for @posProductInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get posProductInStock;

  /// No description provided for @posProductOtherOils.
  ///
  /// In en, this message translates to:
  /// **'Other Oils'**
  String get posProductOtherOils;

  /// No description provided for @posProductOtherOilFilters.
  ///
  /// In en, this message translates to:
  /// **'Other Oil Filters'**
  String get posProductOtherOilFilters;

  /// No description provided for @posProductGearOil.
  ///
  /// In en, this message translates to:
  /// **'Gear Oil'**
  String get posProductGearOil;

  /// No description provided for @posProductOilChangeDepartment.
  ///
  /// In en, this message translates to:
  /// **'Oil Change Department'**
  String get posProductOilChangeDepartment;

  /// No description provided for @posTechOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get posTechOnlineNow;

  /// No description provided for @posTechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get posTechNotAvailable;

  /// No description provided for @posTechWorkshopDuty.
  ///
  /// In en, this message translates to:
  /// **'Workshop Duty'**
  String get posTechWorkshopDuty;

  /// No description provided for @posTechOnCallDuty.
  ///
  /// In en, this message translates to:
  /// **'On-Call Duty'**
  String get posTechOnCallDuty;

  /// No description provided for @posTechActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get posTechActive;

  /// No description provided for @posCommonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get posCommonDone;

  /// No description provided for @posCommonPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get posCommonPrint;

  /// No description provided for @posOrdersCorpBadge.
  ///
  /// In en, this message translates to:
  /// **'CORP'**
  String get posOrdersCorpBadge;

  /// No description provided for @posSearchHistoryPlateLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate: {plate}'**
  String posSearchHistoryPlateLabel(Object plate);

  /// No description provided for @posSearchHistoryOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order: #{orderNumber}'**
  String posSearchHistoryOrderLabel(Object orderNumber);

  /// No description provided for @posOrdersSelectedDepartments.
  ///
  /// In en, this message translates to:
  /// **'Selected departments'**
  String get posOrdersSelectedDepartments;

  /// No description provided for @posOrdersDeptNotReturnedInPayload.
  ///
  /// In en, this message translates to:
  /// **'Departments not returned in order list payload.'**
  String get posOrdersDeptNotReturnedInPayload;

  /// No description provided for @posOrdersTechnicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician: {name}'**
  String posOrdersTechnicianLabel(Object name);

  /// No description provided for @posOrdersTechnicianNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get posOrdersTechnicianNone;

  /// No description provided for @posOrdersWaitingCorporateApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting corporate approval'**
  String get posOrdersWaitingCorporateApproval;

  /// No description provided for @posOrdersRejectedByCorporateReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected by corporate: {reason}'**
  String posOrdersRejectedByCorporateReason(Object reason);

  /// No description provided for @posOrdersRejectedByCorporate.
  ///
  /// In en, this message translates to:
  /// **'Rejected by corporate'**
  String get posOrdersRejectedByCorporate;

  /// No description provided for @posOrdersEditOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get posOrdersEditOrder;

  /// No description provided for @posOrdersCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get posOrdersCancelOrder;

  /// No description provided for @posOrdersGenInvoice.
  ///
  /// In en, this message translates to:
  /// **'Gen. Invoice'**
  String get posOrdersGenInvoice;

  /// No description provided for @posOrdersInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get posOrdersInvoice;

  /// No description provided for @posOrdersAddDept.
  ///
  /// In en, this message translates to:
  /// **'Add Dept.'**
  String get posOrdersAddDept;

  /// No description provided for @posDetailsWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get posDetailsWalkIn;

  /// No description provided for @posDetailsOrderHash.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String posDetailsOrderHash(Object id);

  /// No description provided for @posDetailsJobId.
  ///
  /// In en, this message translates to:
  /// **'Job ID: {id}'**
  String posDetailsJobId(Object id);

  /// No description provided for @posDetailsNoItemsInDept.
  ///
  /// In en, this message translates to:
  /// **'No items bound to this department.'**
  String get posDetailsNoItemsInDept;

  /// No description provided for @posDetailsQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String posDetailsQtyLabel(Object qty);

  /// No description provided for @posDetailsSarEa.
  ///
  /// In en, this message translates to:
  /// **'SAR {price} / ea'**
  String posDetailsSarEa(Object price);

  /// No description provided for @posDetailsActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get posDetailsActive;

  /// No description provided for @posOrdersConfirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get posOrdersConfirmCompletion;

  /// No description provided for @posJobApproved.
  ///
  /// In en, this message translates to:
  /// **'Job Approved!'**
  String get posJobApproved;

  /// No description provided for @posJobTechnicianCommissionLogged.
  ///
  /// In en, this message translates to:
  /// **'Technician commission has been logged.'**
  String get posJobTechnicianCommissionLogged;

  /// No description provided for @posJobTechnicianLabel.
  ///
  /// In en, this message translates to:
  /// **'TECHNICIAN'**
  String get posJobTechnicianLabel;

  /// No description provided for @posJobCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'COMMISSION'**
  String get posJobCommissionLabel;

  /// No description provided for @posDutyNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get posDutyNotApplicable;

  /// No description provided for @posDutyUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Unavailable while offline'**
  String get posDutyUnavailableOffline;

  /// No description provided for @posDutyActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get posDutyActive;

  /// No description provided for @posProductStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String posProductStockLabel(Object count);

  /// No description provided for @posProductSearchItemOrService.
  ///
  /// In en, this message translates to:
  /// **'Search item or service'**
  String get posProductSearchItemOrService;

  /// No description provided for @posProductIncVat.
  ///
  /// In en, this message translates to:
  /// **'Inc. VAT'**
  String get posProductIncVat;

  /// No description provided for @posOrdersJobBadge.
  ///
  /// In en, this message translates to:
  /// **'JOB'**
  String get posOrdersJobBadge;

  /// No description provided for @posReceiptSimplifiedTaxInvoice.
  ///
  /// In en, this message translates to:
  /// **'Simplified Tax Invoice'**
  String get posReceiptSimplifiedTaxInvoice;

  /// No description provided for @posReceiptBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get posReceiptBranch;

  /// No description provided for @posReceiptAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get posReceiptAddress;

  /// No description provided for @posReceiptVatNumber.
  ///
  /// In en, this message translates to:
  /// **'VAT Number'**
  String get posReceiptVatNumber;

  /// No description provided for @posReceiptInvoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice No'**
  String get posReceiptInvoiceNo;

  /// No description provided for @posReceiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get posReceiptDate;

  /// No description provided for @posReceiptCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get posReceiptCounter;

  /// No description provided for @posReceiptCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get posReceiptCashier;

  /// No description provided for @posReceiptItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get posReceiptItem;

  /// No description provided for @posReceiptQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get posReceiptQty;

  /// No description provided for @posReceiptUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get posReceiptUnitPrice;

  /// No description provided for @posReceiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posReceiptTotal;

  /// No description provided for @posReceiptTotalExcludingVat.
  ///
  /// In en, this message translates to:
  /// **'Total (Excluding VAT)'**
  String get posReceiptTotalExcludingVat;

  /// No description provided for @posReceiptTotalTaxableAmountExclVat.
  ///
  /// In en, this message translates to:
  /// **'Total Taxable Amount (Excluding VAT)'**
  String get posReceiptTotalTaxableAmountExclVat;

  /// No description provided for @posReceiptTotalVat15.
  ///
  /// In en, this message translates to:
  /// **'Total VAT 15%'**
  String get posReceiptTotalVat15;

  /// No description provided for @posReceiptTotalAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Total Amount Due'**
  String get posReceiptTotalAmountDue;

  /// No description provided for @posReceiptNextOilChangeOdometer.
  ///
  /// In en, this message translates to:
  /// **'Next oil change odometer'**
  String get posReceiptNextOilChangeOdometer;

  /// No description provided for @posReceiptCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get posReceiptCustomerDetails;

  /// No description provided for @posReceiptName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get posReceiptName;

  /// No description provided for @posReceiptMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get posReceiptMobile;

  /// No description provided for @posReceiptVehicleNo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle No'**
  String get posReceiptVehicleNo;

  /// No description provided for @posReceiptOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get posReceiptOdometer;

  /// No description provided for @posReceiptMaintenanceChecklist.
  ///
  /// In en, this message translates to:
  /// **'Maintenance checklist'**
  String get posReceiptMaintenanceChecklist;

  /// No description provided for @posReceiptThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get posReceiptThankYou;

  /// No description provided for @posThermalPrinterInvalidHost.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid printer IP or hostname.'**
  String get posThermalPrinterInvalidHost;

  /// No description provided for @posThermalPrinterInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port (1–65535).'**
  String get posThermalPrinterInvalidPort;

  /// No description provided for @posThermalPrinterSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings.'**
  String get posThermalPrinterSaveFailed;

  /// No description provided for @posOrdersDeleteJobBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this job? This action cannot be undone.'**
  String get posOrdersDeleteJobBody;

  /// No description provided for @posOrdersJobCannotBeEdited.
  ///
  /// In en, this message translates to:
  /// **'This job cannot be edited.'**
  String get posOrdersJobCannotBeEdited;

  /// No description provided for @posOrdersItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String posOrdersItemCount(Object count);

  /// No description provided for @posOrdersTechnicianCount.
  ///
  /// In en, this message translates to:
  /// **'{count} technicians'**
  String posOrdersTechnicianCount(Object count);

  /// No description provided for @posOrdersVatPercent.
  ///
  /// In en, this message translates to:
  /// **'VAT ({pct}%)'**
  String posOrdersVatPercent(Object pct);

  /// No description provided for @posOrdersDeptCount.
  ///
  /// In en, this message translates to:
  /// **'{count} dept'**
  String posOrdersDeptCount(Object count);

  /// No description provided for @posOrdersDeptNames.
  ///
  /// In en, this message translates to:
  /// **'Dept: {names}'**
  String posOrdersDeptNames(Object names);

  /// No description provided for @posOrdersRejectedCorporateReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Rejected corporate orders are read-only. Remove the order from the list.'**
  String get posOrdersRejectedCorporateReadOnly;

  /// No description provided for @posOrdersPleaseAddVehicleFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add vehicle number first (Add Customer)'**
  String get posOrdersPleaseAddVehicleFirst;

  /// No description provided for @posOrdersThisJobNoLineItems.
  ///
  /// In en, this message translates to:
  /// **'This job has no line items.'**
  String get posOrdersThisJobNoLineItems;

  /// No description provided for @posOrdersDeptPromoWithName.
  ///
  /// In en, this message translates to:
  /// **'Dept promo ({name})'**
  String posOrdersDeptPromoWithName(Object name);

  /// No description provided for @posOrdersDeptDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Dept discount ({percent}%)'**
  String posOrdersDeptDiscountPercent(Object percent);

  /// No description provided for @posOrdersStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get posOrdersStatusDraft;

  /// No description provided for @posOrdersEditPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get posOrdersEditPayment;

  /// No description provided for @posReviewTechnicianFallback.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get posReviewTechnicianFallback;

  /// No description provided for @posReviewItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get posReviewItemFallback;

  /// No description provided for @posReviewInvoiceCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Invoice could not be loaded.'**
  String get posReviewInvoiceCouldNotLoad;

  /// No description provided for @posReviewVehicleNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle no.'**
  String get posReviewVehicleNoLabel;

  /// No description provided for @posReviewCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get posReviewCustomerLabel;

  /// No description provided for @posReviewDiscountsApplyTaxableSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Invoice and promo discounts apply to the taxable subtotal.'**
  String get posReviewDiscountsApplyTaxableSubtotal;

  /// No description provided for @posPaymentMethodTitleSplit.
  ///
  /// In en, this message translates to:
  /// **'Payment Method (Select multiple if splitting)'**
  String get posPaymentMethodTitleSplit;

  /// No description provided for @posReviewCorporatePayment.
  ///
  /// In en, this message translates to:
  /// **'Corporate — {method}'**
  String posReviewCorporatePayment(Object method);

  /// No description provided for @posPaymentChangeCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Change customer'**
  String get posPaymentChangeCustomerTitle;

  /// No description provided for @posPaymentChangeCustomerBody.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to change the customer? Your payment choices for this customer type will be cleared.'**
  String get posPaymentChangeCustomerBody;

  /// No description provided for @posPaymentChangeCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Change customer'**
  String get posPaymentChangeCustomerButton;

  /// Message when payments exceed total.
  ///
  /// In en, this message translates to:
  /// **'Exceeds total by {amount}'**
  String posOrdersExceedsBy(String amount);

  /// Receipt item breakdown: unit price label
  ///
  /// In en, this message translates to:
  /// **'Unit (Excl. VAT)'**
  String get posReviewUnitExclVat;

  /// Receipt item breakdown: gross label
  ///
  /// In en, this message translates to:
  /// **'Gross Before VAT'**
  String get posReviewGrossBeforeVat;

  /// Receipt item breakdown: total label
  ///
  /// In en, this message translates to:
  /// **'Total Before VAT'**
  String get posReviewTotalBeforeVat;

  /// Common quantity abbreviation
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get posCommonQty;

  /// Common technician abbreviation
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get posCommonTech;

  /// No description provided for @posNavPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Purchase Order'**
  String get posNavPurchaseOrder;

  /// No description provided for @posPoTabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get posPoTabCreate;

  /// No description provided for @posPoTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get posPoTabHistory;

  /// No description provided for @posPoTabIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get posPoTabIncoming;

  /// No description provided for @posPoDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get posPoDate;

  /// No description provided for @posPoReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get posPoReference;

  /// No description provided for @posPoReferenceLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating reference…'**
  String get posPoReferenceLoading;

  /// No description provided for @posPoSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get posPoSupplier;

  /// No description provided for @posPoSelectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select supplier'**
  String get posPoSelectSupplier;

  /// No description provided for @posPoDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get posPoDescription;

  /// No description provided for @posPoDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for this purchase order'**
  String get posPoDescriptionHint;

  /// No description provided for @posPoLineItems.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get posPoLineItems;

  /// No description provided for @posPoAvailableProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String posPoAvailableProductsCount(int count);

  /// No description provided for @posPoProductColumn.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get posPoProductColumn;

  /// No description provided for @posPoSearchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get posPoSearchProductHint;

  /// No description provided for @posPoSearchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product from branch stock'**
  String get posPoSearchProduct;

  /// No description provided for @posPoItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Item description'**
  String get posPoItemDescription;

  /// No description provided for @posPoQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get posPoQty;

  /// No description provided for @posPoAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get posPoAddLine;

  /// No description provided for @posPoSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send to supplier'**
  String get posPoSubmit;

  /// No description provided for @posPoSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase order sent to supplier'**
  String get posPoSubmitSuccess;

  /// No description provided for @posPoNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet'**
  String get posPoNoHistory;

  /// No description provided for @posPoNoIncoming.
  ///
  /// In en, this message translates to:
  /// **'No incoming supplier invoices'**
  String get posPoNoIncoming;

  /// No description provided for @posPoReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get posPoReceive;

  /// No description provided for @posPoReceivedQty.
  ///
  /// In en, this message translates to:
  /// **'Received qty'**
  String get posPoReceivedQty;

  /// No description provided for @posPoReceivedQtyHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use invoice qty for each line'**
  String get posPoReceivedQtyHint;

  /// No description provided for @posPoInvoiceQty.
  ///
  /// In en, this message translates to:
  /// **'Invoice qty'**
  String get posPoInvoiceQty;

  /// No description provided for @posPoConfirmReceive.
  ///
  /// In en, this message translates to:
  /// **'Confirm receive'**
  String get posPoConfirmReceive;

  /// No description provided for @posPoReceiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Goods received — branch inventory updated'**
  String get posPoReceiveSuccess;

  /// No description provided for @corporateKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get corporateKpiTotal;

  /// No description provided for @corporateMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get corporateMobileLabel;

  /// No description provided for @corporateVatShortLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get corporateVatShortLabel;

  /// No description provided for @corporateCreditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get corporateCreditLimitLabel;

  /// No description provided for @corporateDueBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Balance'**
  String get corporateDueBalanceLabel;

  /// No description provided for @corporateBranchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get corporateBranchesLabel;

  /// No description provided for @corporateCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get corporateCancelButton;

  /// No description provided for @corporateSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get corporateSubmitButton;

  /// No description provided for @approvalsQueueSupplierInvoices.
  ///
  /// In en, this message translates to:
  /// **'Supplier Invoices'**
  String get approvalsQueueSupplierInvoices;

  /// No description provided for @ownerDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get ownerDashboardSubtitle;

  /// No description provided for @ownerDashboardGrossMarginProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get ownerDashboardGrossMarginProfit;

  /// No description provided for @ownerDashboardGrossMarginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue − COGS'**
  String get ownerDashboardGrossMarginSubtitle;

  /// No description provided for @ownerDashboardPendingApprovalsKpi.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get ownerDashboardPendingApprovalsKpi;

  /// No description provided for @ownerDashboardLowStockProducts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Products'**
  String get ownerDashboardLowStockProducts;

  /// No description provided for @ownerDashboardLowStockAlertSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} low stock alert — open inventory to review'**
  String ownerDashboardLowStockAlertSingular(int count);

  /// No description provided for @ownerDashboardLowStockAlertPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} low stock alerts — open inventory to review'**
  String ownerDashboardLowStockAlertPlural(int count);

  /// No description provided for @ownerDashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get ownerDashboardQuickActions;

  /// No description provided for @ownerDashboardActionEmployeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get ownerDashboardActionEmployeesTitle;

  /// No description provided for @ownerDashboardActionEmployeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage staff & roles'**
  String get ownerDashboardActionEmployeesSubtitle;

  /// No description provided for @ownerDashboardActionDeptProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dept & Products'**
  String get ownerDashboardActionDeptProductsTitle;

  /// No description provided for @ownerDashboardActionDeptProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog & departments'**
  String get ownerDashboardActionDeptProductsSubtitle;

  /// No description provided for @ownerDashboardActionApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals Queue'**
  String get ownerDashboardActionApprovalsTitle;

  /// No description provided for @ownerDashboardActionApprovalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review pending items'**
  String get ownerDashboardActionApprovalsSubtitle;

  /// No description provided for @ownerDashboardActionSuppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers & Purchases'**
  String get ownerDashboardActionSuppliersTitle;

  /// No description provided for @ownerDashboardActionSuppliersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders & suppliers'**
  String get ownerDashboardActionSuppliersSubtitle;

  /// No description provided for @ownerDashboardScreenNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{title} screen is not connected yet'**
  String ownerDashboardScreenNotConnected(String title);

  /// No description provided for @ownerReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get ownerReportsTitle;

  /// No description provided for @ownerReportsTabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ownerReportsTabOrders;

  /// No description provided for @ownerReportsTabDailySales.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales'**
  String get ownerReportsTabDailySales;

  /// No description provided for @ownerReportsTabByTechnician.
  ///
  /// In en, this message translates to:
  /// **'By Technician'**
  String get ownerReportsTabByTechnician;

  /// No description provided for @ownerReportsTabByCustomer.
  ///
  /// In en, this message translates to:
  /// **'By Customer'**
  String get ownerReportsTabByCustomer;

  /// No description provided for @ownerReportsTabByProduct.
  ///
  /// In en, this message translates to:
  /// **'By Product'**
  String get ownerReportsTabByProduct;

  /// No description provided for @ownerReportsTabByDepartment.
  ///
  /// In en, this message translates to:
  /// **'By Department'**
  String get ownerReportsTabByDepartment;

  /// No description provided for @ownerReportsTabByBranch.
  ///
  /// In en, this message translates to:
  /// **'By Branch'**
  String get ownerReportsTabByBranch;

  /// No description provided for @ownerReportsTabByCashier.
  ///
  /// In en, this message translates to:
  /// **'By Cashier'**
  String get ownerReportsTabByCashier;

  /// No description provided for @ownerReportsKpiTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get ownerReportsKpiTotalRevenue;

  /// No description provided for @ownerReportsKpiRevenueChange.
  ///
  /// In en, this message translates to:
  /// **'Revenue Change'**
  String get ownerReportsKpiRevenueChange;

  /// No description provided for @ownerReportsKpiRevenueChangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get ownerReportsKpiRevenueChangeSubtitle;

  /// No description provided for @ownerReportsKpiStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get ownerReportsKpiStockValue;

  /// No description provided for @ownerReportsKpiStockValueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} SKUs on hand'**
  String ownerReportsKpiStockValueSubtitle(int count);

  /// No description provided for @ownerReportsKpiPotentialProfit.
  ///
  /// In en, this message translates to:
  /// **'Potential Profit'**
  String get ownerReportsKpiPotentialProfit;

  /// No description provided for @ownerReportsPaymentAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ownerReportsPaymentAll;

  /// No description provided for @ownerReportsPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get ownerReportsPaymentCash;

  /// No description provided for @ownerReportsPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get ownerReportsPaymentCard;

  /// No description provided for @ownerReportsPaymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get ownerReportsPaymentBankTransfer;

  /// No description provided for @ownerReportsSearchHintOrders.
  ///
  /// In en, this message translates to:
  /// **'Search invoice, customer, plate…'**
  String get ownerReportsSearchHintOrders;

  /// No description provided for @ownerReportsSearchHintDailySales.
  ///
  /// In en, this message translates to:
  /// **'Search day, date, amount…'**
  String get ownerReportsSearchHintDailySales;

  /// No description provided for @ownerReportsSearchHintTechnician.
  ///
  /// In en, this message translates to:
  /// **'Search technician, jobs, revenue…'**
  String get ownerReportsSearchHintTechnician;

  /// No description provided for @ownerReportsSearchHintCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search phone, plate, orders…'**
  String get ownerReportsSearchHintCustomer;

  /// No description provided for @ownerReportsSearchHintProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product, type, qty…'**
  String get ownerReportsSearchHintProduct;

  /// No description provided for @ownerReportsSearchHintDepartment.
  ///
  /// In en, this message translates to:
  /// **'Search department, orders…'**
  String get ownerReportsSearchHintDepartment;

  /// No description provided for @ownerReportsSearchHintBranch.
  ///
  /// In en, this message translates to:
  /// **'Search branch, orders…'**
  String get ownerReportsSearchHintBranch;

  /// No description provided for @ownerReportsSearchHintCashier.
  ///
  /// In en, this message translates to:
  /// **'Search cashier, orders…'**
  String get ownerReportsSearchHintCashier;

  /// No description provided for @ownerReportsSearchHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get ownerReportsSearchHintDefault;

  /// No description provided for @ownerReportsErrorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get ownerReportsErrorNoConnection;

  /// No description provided for @ownerReportsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get ownerReportsErrorGeneric;

  /// No description provided for @ownerReportsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get ownerReportsTryAgain;

  /// No description provided for @ownerReportsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ownerReportsRetry;

  /// No description provided for @ownerPettyCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get ownerPettyCashTitle;

  /// No description provided for @ownerPettyCashKpiTotalFloat.
  ///
  /// In en, this message translates to:
  /// **'Total Staff Float'**
  String get ownerPettyCashKpiTotalFloat;

  /// No description provided for @ownerPettyCashKpiTotalFloatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} staff wallets'**
  String ownerPettyCashKpiTotalFloatSubtitle(int count);

  /// No description provided for @ownerPettyCashKpiPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get ownerPettyCashKpiPendingRequests;

  /// No description provided for @ownerPettyCashKpiPendingRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} awaiting action'**
  String ownerPettyCashKpiPendingRequestsSubtitle(int count);

  /// No description provided for @ownerPettyCashTabWallets.
  ///
  /// In en, this message translates to:
  /// **'Staff Wallets'**
  String get ownerPettyCashTabWallets;

  /// No description provided for @ownerPettyCashTabRequests.
  ///
  /// In en, this message translates to:
  /// **'All Requests'**
  String get ownerPettyCashTabRequests;

  /// No description provided for @ownerPettyCashTabReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get ownerPettyCashTabReport;

  /// No description provided for @ownerPettyCashIssueButton.
  ///
  /// In en, this message translates to:
  /// **'Issue Petty Cash'**
  String get ownerPettyCashIssueButton;

  /// No description provided for @ownerPettyCashEmptyWallets.
  ///
  /// In en, this message translates to:
  /// **'No staff wallets found'**
  String get ownerPettyCashEmptyWallets;

  /// No description provided for @ownerPettyCashEmptyRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get ownerPettyCashEmptyRequests;

  /// No description provided for @ownerPettyCashStaffMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff Member *'**
  String get ownerPettyCashStaffMemberLabel;

  /// No description provided for @ownerPettyCashSelectStaffHint.
  ///
  /// In en, this message translates to:
  /// **'Select staff'**
  String get ownerPettyCashSelectStaffHint;

  /// No description provided for @ownerPettyCashNoStaffAvailable.
  ///
  /// In en, this message translates to:
  /// **'No staff available'**
  String get ownerPettyCashNoStaffAvailable;

  /// No description provided for @ownerPettyCashBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch *'**
  String get ownerPettyCashBranchLabel;

  /// No description provided for @ownerPettyCashSelectBranchHint.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get ownerPettyCashSelectBranchHint;

  /// No description provided for @ownerPettyCashNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches'**
  String get ownerPettyCashNoBranches;

  /// No description provided for @ownerPettyCashAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR) *'**
  String get ownerPettyCashAmountLabel;

  /// No description provided for @ownerPettyCashPayFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay From (Cash/Bank) *'**
  String get ownerPettyCashPayFromLabel;

  /// No description provided for @ownerPettyCashSelectAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get ownerPettyCashSelectAccountHint;

  /// No description provided for @ownerPettyCashNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No cash/bank accounts'**
  String get ownerPettyCashNoAccounts;

  /// No description provided for @ownerPettyCashNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ownerPettyCashNoteLabel;

  /// No description provided for @ownerPettyCashNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note...'**
  String get ownerPettyCashNoteHint;

  /// No description provided for @ownerPettyCashIssuing.
  ///
  /// In en, this message translates to:
  /// **'Issuing…'**
  String get ownerPettyCashIssuing;

  /// No description provided for @ownerPettyCashIssueNow.
  ///
  /// In en, this message translates to:
  /// **'Issue Now'**
  String get ownerPettyCashIssueNow;

  /// No description provided for @ownerPettyCashCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerPettyCashCancel;

  /// No description provided for @ownerPettyCashEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get ownerPettyCashEnterValidAmount;

  /// No description provided for @ownerPettyCashIssuedDefault.
  ///
  /// In en, this message translates to:
  /// **'Petty cash issued'**
  String get ownerPettyCashIssuedDefault;

  /// No description provided for @ownerPettyCashRegisterDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash Wallet Register'**
  String get ownerPettyCashRegisterDialogTitle;

  /// No description provided for @ownerPettyCashStaffBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff · {branch}'**
  String ownerPettyCashStaffBranchLabel(String branch);

  /// No description provided for @ownerPettyCashCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'CURRENT BALANCE'**
  String get ownerPettyCashCurrentBalance;

  /// No description provided for @ownerPettyCashWalletTag.
  ///
  /// In en, this message translates to:
  /// **'— · Petty Cash Wallet'**
  String get ownerPettyCashWalletTag;

  /// No description provided for @ownerPettyCashRegisterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Register — Top-ups & Expenses'**
  String get ownerPettyCashRegisterSectionTitle;

  /// No description provided for @ownerPettyCashNoRegisterEntries.
  ///
  /// In en, this message translates to:
  /// **'No wallet register yet.\nIssue petty cash or approve a fund top-up to create one.'**
  String get ownerPettyCashNoRegisterEntries;

  /// No description provided for @ownerEmployeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get ownerEmployeesTitle;

  /// No description provided for @ownerEmployeesKpiTotalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get ownerEmployeesKpiTotalStaff;

  /// No description provided for @ownerEmployeesKpiOnDuty.
  ///
  /// In en, this message translates to:
  /// **'On Workshop Duty'**
  String get ownerEmployeesKpiOnDuty;

  /// No description provided for @ownerEmployeesKpiOnCall.
  ///
  /// In en, this message translates to:
  /// **'On-Call'**
  String get ownerEmployeesKpiOnCall;

  /// No description provided for @ownerEmployeesTabEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get ownerEmployeesTabEmployees;

  /// No description provided for @ownerEmployeesTabRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get ownerEmployeesTabRoles;

  /// No description provided for @ownerEmployeesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, role, phone…'**
  String get ownerEmployeesSearchHint;

  /// No description provided for @ownerEmployeesCreateRole.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get ownerEmployeesCreateRole;

  /// No description provided for @ownerEmployeesAddEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get ownerEmployeesAddEmployee;

  /// No description provided for @ownerEmployeesEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No employees match your search'**
  String get ownerEmployeesEmptyFiltered;

  /// No description provided for @ownerEmployeesEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No employees yet'**
  String get ownerEmployeesEmptyDefault;

  /// No description provided for @ownerEmployeesClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get ownerEmployeesClearSearch;

  /// No description provided for @ownerInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get ownerInventoryTitle;

  /// No description provided for @ownerInventoryKpiTotalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get ownerInventoryKpiTotalProducts;

  /// No description provided for @ownerInventoryKpiLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get ownerInventoryKpiLowStock;

  /// No description provided for @ownerInventoryKpiInvValue.
  ///
  /// In en, this message translates to:
  /// **'Inv. Value'**
  String get ownerInventoryKpiInvValue;

  /// No description provided for @ownerInventoryTabStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get ownerInventoryTabStock;

  /// No description provided for @ownerInventoryTabUomProfiles.
  ///
  /// In en, this message translates to:
  /// **'UOM Profiles'**
  String get ownerInventoryTabUomProfiles;

  /// No description provided for @ownerInventoryTabValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get ownerInventoryTabValue;

  /// No description provided for @ownerSalesReturnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales Returns'**
  String get ownerSalesReturnsTitle;

  /// No description provided for @ownerSalesReturnsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ownerSalesReturnsStatusAll;

  /// No description provided for @ownerSalesReturnsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get ownerSalesReturnsStatusApproved;

  /// No description provided for @ownerSalesReturnsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ownerSalesReturnsStatusPending;

  /// No description provided for @ownerSalesReturnsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get ownerSalesReturnsStatusRejected;

  /// No description provided for @ownerSalesReturnsKpiShownReturns.
  ///
  /// In en, this message translates to:
  /// **'Shown Returns'**
  String get ownerSalesReturnsKpiShownReturns;

  /// No description provided for @ownerSalesReturnsKpiShownAmount.
  ///
  /// In en, this message translates to:
  /// **'Shown Amount'**
  String get ownerSalesReturnsKpiShownAmount;

  /// No description provided for @ownerSalesReturnsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search invoice #'**
  String get ownerSalesReturnsSearchHint;

  /// No description provided for @ownerSalesReturnsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No returns found'**
  String get ownerSalesReturnsEmptyTitle;

  /// No description provided for @ownerSalesReturnsEmptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different invoice # or\nwidening the date range.'**
  String get ownerSalesReturnsEmptySearchBody;

  /// No description provided for @ownerSalesReturnsEmptyDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Try widening the date range or\nswitching status to All.'**
  String get ownerSalesReturnsEmptyDefaultBody;

  /// No description provided for @ownerSalesReturnsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get ownerSalesReturnsClearFilters;

  /// No description provided for @ownerSalesReturnsTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get ownerSalesReturnsTypeCash;

  /// No description provided for @ownerSalesReturnsTypeCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Credit Note'**
  String get ownerSalesReturnsTypeCreditNote;

  /// No description provided for @ownerSalesReturnsTypeExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get ownerSalesReturnsTypeExchange;

  /// No description provided for @ownerPosMonitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'POS Monitoring'**
  String get ownerPosMonitoringTitle;

  /// No description provided for @ownerPosMonitoringKpiSalesInRange.
  ///
  /// In en, this message translates to:
  /// **'Sales in range'**
  String get ownerPosMonitoringKpiSalesInRange;

  /// No description provided for @ownerPosMonitoringKpiLiveCounters.
  ///
  /// In en, this message translates to:
  /// **'Live Counters'**
  String get ownerPosMonitoringKpiLiveCounters;

  /// No description provided for @ownerPosMonitoringKpiOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'Open Orders'**
  String get ownerPosMonitoringKpiOpenOrders;

  /// No description provided for @ownerPosMonitoringTabLive.
  ///
  /// In en, this message translates to:
  /// **'Live Counters'**
  String get ownerPosMonitoringTabLive;

  /// No description provided for @ownerPosMonitoringTabClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing Reports'**
  String get ownerPosMonitoringTabClosing;

  /// No description provided for @ownerPosMonitoringEmptyLive.
  ///
  /// In en, this message translates to:
  /// **'No active live counters'**
  String get ownerPosMonitoringEmptyLive;

  /// No description provided for @ownerPosMonitoringEmptyClosing.
  ///
  /// In en, this message translates to:
  /// **'No closing reports available'**
  String get ownerPosMonitoringEmptyClosing;

  /// No description provided for @ownerPosMonitoringStatShiftSales.
  ///
  /// In en, this message translates to:
  /// **'SHIFT SALES'**
  String get ownerPosMonitoringStatShiftSales;

  /// No description provided for @ownerPosMonitoringStatOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'OPEN ORDERS'**
  String get ownerPosMonitoringStatOpenOrders;

  /// No description provided for @ownerPosMonitoringStatElapsed.
  ///
  /// In en, this message translates to:
  /// **'ELAPSED'**
  String get ownerPosMonitoringStatElapsed;

  /// No description provided for @ownerPosMonitoringStart.
  ///
  /// In en, this message translates to:
  /// **'Start '**
  String get ownerPosMonitoringStart;

  /// No description provided for @ownerPosMonitoringEnd.
  ///
  /// In en, this message translates to:
  /// **'End '**
  String get ownerPosMonitoringEnd;

  /// No description provided for @ownerPosMonitoringStillOpen.
  ///
  /// In en, this message translates to:
  /// **'still open · counter active'**
  String get ownerPosMonitoringStillOpen;

  /// No description provided for @ownerPosMonitoringStarted.
  ///
  /// In en, this message translates to:
  /// **'Started '**
  String get ownerPosMonitoringStarted;

  /// No description provided for @ownerPosMonitoringEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended '**
  String get ownerPosMonitoringEnded;

  /// No description provided for @ownerPosMonitoringShort.
  ///
  /// In en, this message translates to:
  /// **'SHORT'**
  String get ownerPosMonitoringShort;

  /// No description provided for @ownerPosMonitoringExcess.
  ///
  /// In en, this message translates to:
  /// **'EXCESS'**
  String get ownerPosMonitoringExcess;

  /// No description provided for @ownerPosMonitoringBalanced.
  ///
  /// In en, this message translates to:
  /// **'BALANCED'**
  String get ownerPosMonitoringBalanced;

  /// No description provided for @ownerPosMonitoringCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ownerPosMonitoringCategory;

  /// No description provided for @ownerPosMonitoringSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get ownerPosMonitoringSystem;

  /// No description provided for @ownerPosMonitoringPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get ownerPosMonitoringPhysical;

  /// No description provided for @ownerPosMonitoringDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get ownerPosMonitoringDiff;

  /// No description provided for @ownerPosMonitoringCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get ownerPosMonitoringCash;

  /// No description provided for @ownerPosMonitoringBankCards.
  ///
  /// In en, this message translates to:
  /// **'Bank/Cards'**
  String get ownerPosMonitoringBankCards;

  /// No description provided for @ownerPosMonitoringCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get ownerPosMonitoringCorporate;

  /// No description provided for @ownerPosMonitoringTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara'**
  String get ownerPosMonitoringTamara;

  /// No description provided for @ownerPosMonitoringTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby'**
  String get ownerPosMonitoringTabby;

  /// No description provided for @ownerPosMonitoringOthersEmployees.
  ///
  /// In en, this message translates to:
  /// **'Others (Employees)'**
  String get ownerPosMonitoringOthersEmployees;

  /// No description provided for @ownerPosMonitoringTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get ownerPosMonitoringTotalSales;

  /// No description provided for @ownerPosMonitoringBreakdownUnavailable.
  ///
  /// In en, this message translates to:
  /// **'⚠ Full breakdown unavailable — deploy latest backend to see per-category data'**
  String get ownerPosMonitoringBreakdownUnavailable;

  /// No description provided for @ownerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get ownerSettingsTitle;

  /// No description provided for @ownerSettingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get ownerSettingsLogout;

  /// No description provided for @ownerSettingsVersionFooter.
  ///
  /// In en, this message translates to:
  /// **'Filter Workshop OS • Version 1.0.1'**
  String get ownerSettingsVersionFooter;

  /// No description provided for @ownerSettingsLogoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get ownerSettingsLogoutDialogTitle;

  /// No description provided for @ownerSettingsLogoutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from your account?'**
  String get ownerSettingsLogoutDialogBody;

  /// No description provided for @ownerSettingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerSettingsCancel;

  /// No description provided for @ownerSettingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get ownerSettingsLogoutConfirm;

  /// No description provided for @ownerSettingsAdminFallback.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get ownerSettingsAdminFallback;

  /// No description provided for @ownerSettingsWorkshopProfile.
  ///
  /// In en, this message translates to:
  /// **'WORKSHOP PROFILE'**
  String get ownerSettingsWorkshopProfile;

  /// No description provided for @ownerSettingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get ownerSettingsEdit;

  /// No description provided for @ownerSettingsFieldWorkshopName.
  ///
  /// In en, this message translates to:
  /// **'Workshop Name'**
  String get ownerSettingsFieldWorkshopName;

  /// No description provided for @ownerSettingsFieldOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerSettingsFieldOwnerName;

  /// No description provided for @ownerSettingsFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get ownerSettingsFieldMobile;

  /// No description provided for @ownerSettingsFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ownerSettingsFieldEmail;

  /// No description provided for @ownerSettingsFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get ownerSettingsFieldAddress;

  /// No description provided for @ownerSettingsFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get ownerSettingsFieldCurrency;

  /// No description provided for @ownerSettingsFieldVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get ownerSettingsFieldVat;

  /// No description provided for @ownerSettingsInclusive.
  ///
  /// In en, this message translates to:
  /// **'Inclusive'**
  String get ownerSettingsInclusive;

  /// No description provided for @ownerSettingsExclusive.
  ///
  /// In en, this message translates to:
  /// **'Exclusive'**
  String get ownerSettingsExclusive;

  /// No description provided for @ownerSettingsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'READ ONLY'**
  String get ownerSettingsReadOnly;

  /// No description provided for @ownerSettingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get ownerSettingsSaveChanges;

  /// No description provided for @ownerSettingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get ownerSettingsProfileUpdated;

  /// No description provided for @ownerCatalogTabDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get ownerCatalogTabDepartments;

  /// No description provided for @ownerCatalogTabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get ownerCatalogTabProducts;

  /// No description provided for @ownerCatalogTabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get ownerCatalogTabServices;

  /// No description provided for @ownerCatalogTabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get ownerCatalogTabCategories;

  /// No description provided for @ownerCatalogSearchDepartments.
  ///
  /// In en, this message translates to:
  /// **'Search departments...'**
  String get ownerCatalogSearchDepartments;

  /// No description provided for @ownerCatalogRequestDepartment.
  ///
  /// In en, this message translates to:
  /// **'Request Department'**
  String get ownerCatalogRequestDepartment;

  /// No description provided for @ownerCatalogRequestProduct.
  ///
  /// In en, this message translates to:
  /// **'Request Product'**
  String get ownerCatalogRequestProduct;

  /// No description provided for @ownerCatalogRequestCategory.
  ///
  /// In en, this message translates to:
  /// **'Request Category'**
  String get ownerCatalogRequestCategory;

  /// No description provided for @ownerCatalogMasterDepartment.
  ///
  /// In en, this message translates to:
  /// **'Master Department'**
  String get ownerCatalogMasterDepartment;

  /// No description provided for @ownerCatalogAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get ownerCatalogAdd;

  /// No description provided for @ownerCatalogAdded.
  ///
  /// In en, this message translates to:
  /// **'Added ({count})'**
  String ownerCatalogAdded(int count);

  /// No description provided for @ownerCatalogNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added ({count})'**
  String ownerCatalogNotAdded(int count);

  /// No description provided for @ownerCatalogSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: '**
  String get ownerCatalogSelected;

  /// No description provided for @ownerCatalogSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get ownerCatalogSelectAll;

  /// No description provided for @ownerCatalogClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get ownerCatalogClear;

  /// No description provided for @ownerCatalogAddToBranches.
  ///
  /// In en, this message translates to:
  /// **'Add to branches...'**
  String get ownerCatalogAddToBranches;

  /// No description provided for @ownerLowStockCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical: {level} {unit}'**
  String ownerLowStockCritical(String level, String unit);

  /// No description provided for @ownerLowStockQty.
  ///
  /// In en, this message translates to:
  /// **'{qty} {unit}'**
  String ownerLowStockQty(String qty, String unit);

  /// No description provided for @ownerUnitLiter.
  ///
  /// In en, this message translates to:
  /// **'liter'**
  String get ownerUnitLiter;

  /// No description provided for @ownerUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get ownerUnitPiece;

  /// No description provided for @ownerUnitPcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get ownerUnitPcs;

  /// No description provided for @ownerUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get ownerUnitKg;

  /// No description provided for @ownerUnitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get ownerUnitMl;

  /// No description provided for @ownerUnitBox.
  ///
  /// In en, this message translates to:
  /// **'box'**
  String get ownerUnitBox;

  /// No description provided for @ownerUnitSet.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get ownerUnitSet;

  /// No description provided for @ownerSettingsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get ownerSettingsStatusApproved;

  /// No description provided for @ownerSettingsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get ownerSettingsStatusPending;

  /// No description provided for @ownerSettingsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get ownerSettingsStatusRejected;

  /// No description provided for @ownerSettingsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get ownerSettingsStatusActive;

  /// No description provided for @ownerPurchaseInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoices'**
  String get ownerPurchaseInvoicesTitle;

  /// No description provided for @ownerPurchaseInvoicesNew.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get ownerPurchaseInvoicesNew;

  /// No description provided for @ownerPurchaseInvoicesPriceReport.
  ///
  /// In en, this message translates to:
  /// **'Price Report'**
  String get ownerPurchaseInvoicesPriceReport;

  /// No description provided for @ownerPurchaseInvoicesKpiPayable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Payable'**
  String get ownerPurchaseInvoicesKpiPayable;

  /// No description provided for @ownerPurchaseInvoicesKpiPayableSub.
  ///
  /// In en, this message translates to:
  /// **'Owed to vendors'**
  String get ownerPurchaseInvoicesKpiPayableSub;

  /// No description provided for @ownerPurchaseInvoicesKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get ownerPurchaseInvoicesKpiTotal;

  /// No description provided for @ownerPurchaseInvoicesKpiTotalSub.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get ownerPurchaseInvoicesKpiTotalSub;

  /// No description provided for @ownerPurchaseInvoicesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search invoice #, vendor, ref…'**
  String get ownerPurchaseInvoicesSearchHint;

  /// No description provided for @ownerPurchaseInvoicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get ownerPurchaseInvoicesEmpty;

  /// No description provided for @ownerPurchaseInvoicesDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String ownerPurchaseInvoicesDue(String date);

  /// No description provided for @ownerPurchaseInvoicesStockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get ownerPurchaseInvoicesStockUpdated;

  /// No description provided for @ownerPurchaseInvoicesStockPending.
  ///
  /// In en, this message translates to:
  /// **'Stock pending'**
  String get ownerPurchaseInvoicesStockPending;

  /// No description provided for @ownerPurchaseInvoicesPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ownerPurchaseInvoicesPaid;

  /// No description provided for @ownerPurchaseInvoicesPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get ownerPurchaseInvoicesPartial;

  /// No description provided for @ownerPurchaseInvoicesUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get ownerPurchaseInvoicesUnpaid;

  /// No description provided for @ownerPurchaseInvoicesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get ownerPurchaseInvoicesInvoice;

  /// No description provided for @ownerPurchaseInvoicesUnknownVendor.
  ///
  /// In en, this message translates to:
  /// **'Unknown vendor'**
  String get ownerPurchaseInvoicesUnknownVendor;

  /// No description provided for @ownerPurchaseInvoicesAllVendors.
  ///
  /// In en, this message translates to:
  /// **'All Vendors'**
  String get ownerPurchaseInvoicesAllVendors;

  /// No description provided for @ownerPurchaseInvoicesAllProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get ownerPurchaseInvoicesAllProducts;

  /// No description provided for @ownerPurchaseInvoicesStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ownerPurchaseInvoicesStatusAll;

  /// No description provided for @ownerPurchaseInvoicesStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ownerPurchaseInvoicesStatusPending;

  /// No description provided for @ownerPurchaseInvoicesStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get ownerPurchaseInvoicesStatusApproved;

  /// No description provided for @ownerPurchaseInvoicesStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ownerPurchaseInvoicesStatusDelivered;

  /// No description provided for @ownerPurchaseInvoicesStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ownerPurchaseInvoicesStatusCompleted;

  /// No description provided for @ownerPurchaseInvoicesStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get ownerPurchaseInvoicesStatusDraft;

  /// No description provided for @ownerPurchaseInvoicesStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get ownerPurchaseInvoicesStatusRejected;

  /// No description provided for @ownerCommonAllDepts.
  ///
  /// In en, this message translates to:
  /// **'All Depts'**
  String get ownerCommonAllDepts;

  /// No description provided for @ownerCommonAllDepartments.
  ///
  /// In en, this message translates to:
  /// **'All departments'**
  String get ownerCommonAllDepartments;

  /// No description provided for @ownerCommonFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get ownerCommonFree;

  /// No description provided for @ownerCommonQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get ownerCommonQty;

  /// No description provided for @ownerCommonSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get ownerCommonSelectAll;

  /// No description provided for @ownerCommonApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get ownerCommonApprove;

  /// No description provided for @ownerCommonReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get ownerCommonReject;

  /// No description provided for @ownerCommonPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get ownerCommonPending;

  /// No description provided for @ownerCommonActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get ownerCommonActive;

  /// No description provided for @ownerCommonInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get ownerCommonInactive;

  /// No description provided for @ownerCommonInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get ownerCommonInvoice;

  /// No description provided for @ownerCommonStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get ownerCommonStartDate;

  /// No description provided for @ownerCommonEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get ownerCommonEndDate;

  /// No description provided for @ownerCommonFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get ownerCommonFrom;

  /// No description provided for @ownerCommonTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get ownerCommonTo;

  /// No description provided for @ownerCatalogSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get ownerCatalogSearchProducts;

  /// No description provided for @ownerCatalogSearchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get ownerCatalogSearchServices;

  /// No description provided for @ownerCatalogSearchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get ownerCatalogSearchCategories;

  /// No description provided for @ownerCatalogRequestService.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get ownerCatalogRequestService;

  /// No description provided for @ownerInventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or SKU…'**
  String get ownerInventorySearchHint;

  /// No description provided for @ownerInventoryLowStockFilter.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get ownerInventoryLowStockFilter;

  /// No description provided for @ownerInventoryProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String ownerInventoryProductsCount(int count);

  /// No description provided for @ownerInventoryNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get ownerInventoryNoProducts;

  /// No description provided for @ownerInventoryCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get ownerInventoryCritical;

  /// No description provided for @ownerInventoryCriticalDash.
  ///
  /// In en, this message translates to:
  /// **'Critical —'**
  String get ownerInventoryCriticalDash;

  /// No description provided for @ownerInventoryCriticalValue.
  ///
  /// In en, this message translates to:
  /// **'Critical {value}'**
  String ownerInventoryCriticalValue(String value);

  /// No description provided for @ownerInventoryAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get ownerInventoryAdjust;

  /// No description provided for @ownerInventoryRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get ownerInventoryRequest;

  /// No description provided for @ownerInventoryCurrentOpening.
  ///
  /// In en, this message translates to:
  /// **'Current {current} {unit} · Opening {opening}'**
  String ownerInventoryCurrentOpening(
    String current,
    String unit,
    String opening,
  );

  /// No description provided for @ownerInventoryCriticalStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Critical stock level'**
  String get ownerInventoryCriticalStockLevel;

  /// No description provided for @ownerInventoryManualAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Inventory Adjustment'**
  String get ownerInventoryManualAdjustTitle;

  /// No description provided for @ownerInventoryApplyAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Apply Adjustment'**
  String get ownerInventoryApplyAdjustment;

  /// No description provided for @ownerInventoryManualAdjust.
  ///
  /// In en, this message translates to:
  /// **'Manual Adjust'**
  String get ownerInventoryManualAdjust;

  /// No description provided for @ownerApprovalsRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get ownerApprovalsRequestedBy;

  /// No description provided for @ownerApprovalsReference.
  ///
  /// In en, this message translates to:
  /// **'Reference #'**
  String get ownerApprovalsReference;

  /// No description provided for @ownerApprovalsBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get ownerApprovalsBranch;

  /// No description provided for @ownerApprovalsDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ownerApprovalsDetails;

  /// No description provided for @ownerApprovalsRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested at'**
  String get ownerApprovalsRequestedAt;

  /// No description provided for @ownerApprovalsRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get ownerApprovalsRejectTitle;

  /// No description provided for @ownerApprovalsApproveExpense.
  ///
  /// In en, this message translates to:
  /// **'Approve Expense'**
  String get ownerApprovalsApproveExpense;

  /// No description provided for @ownerApprovalsApproveTopUp.
  ///
  /// In en, this message translates to:
  /// **'Approve Top-up'**
  String get ownerApprovalsApproveTopUp;

  /// No description provided for @ownerApprovalsApproveWalletExpense.
  ///
  /// In en, this message translates to:
  /// **'Approve Wallet Expense'**
  String get ownerApprovalsApproveWalletExpense;

  /// No description provided for @ownerApprovalsApproveWalletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Approve Wallet Top-up'**
  String get ownerApprovalsApproveWalletTopUp;

  /// No description provided for @ownerPnLTitle.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get ownerPnLTitle;

  /// No description provided for @ownerPnLRevenue.
  ///
  /// In en, this message translates to:
  /// **'REVENUE'**
  String get ownerPnLRevenue;

  /// No description provided for @ownerPnLCogs.
  ///
  /// In en, this message translates to:
  /// **'COST OF GOODS SOLD'**
  String get ownerPnLCogs;

  /// No description provided for @ownerPnLOperatingExpenses.
  ///
  /// In en, this message translates to:
  /// **'OPERATING EXPENSES'**
  String get ownerPnLOperatingExpenses;

  /// No description provided for @ownerPnLTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get ownerPnLTotalRevenue;

  /// No description provided for @ownerPnLTotalCogs.
  ///
  /// In en, this message translates to:
  /// **'Total Cost of Goods Sold'**
  String get ownerPnLTotalCogs;

  /// No description provided for @ownerPnLGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get ownerPnLGrossProfit;

  /// No description provided for @ownerExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get ownerExpenseTitle;

  /// No description provided for @ownerExpenseSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search code or name'**
  String get ownerExpenseSearchHint;

  /// No description provided for @ownerExpenseAccountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String ownerExpenseAccountsCount(int count);

  /// No description provided for @ownerExpenseAutoLinked.
  ///
  /// In en, this message translates to:
  /// **'Auto-linked'**
  String get ownerExpenseAutoLinked;

  /// No description provided for @ownerExpenseOperating.
  ///
  /// In en, this message translates to:
  /// **'Operating Expense'**
  String get ownerExpenseOperating;

  /// No description provided for @ownerExpenseSharedDebit.
  ///
  /// In en, this message translates to:
  /// **'Shared · Debit'**
  String get ownerExpenseSharedDebit;

  /// No description provided for @ownerCommissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Commissions'**
  String get ownerCommissionsTitle;

  /// No description provided for @ownerCommissionsTabRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get ownerCommissionsTabRules;

  /// No description provided for @ownerCommissionsTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ownerCommissionsTabPending;

  /// No description provided for @ownerCommissionsTabLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ownerCommissionsTabLedger;

  /// No description provided for @ownerCommissionsPendingEmployees.
  ///
  /// In en, this message translates to:
  /// **'Pending Employees'**
  String get ownerCommissionsPendingEmployees;

  /// No description provided for @ownerCommissionsTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get ownerCommissionsTotalPaid;

  /// No description provided for @ownerCommissionsTotalAccrued.
  ///
  /// In en, this message translates to:
  /// **'Total Accrued'**
  String get ownerCommissionsTotalAccrued;

  /// No description provided for @ownerCommissionsAllEmployees.
  ///
  /// In en, this message translates to:
  /// **'All Employees'**
  String get ownerCommissionsAllEmployees;

  /// No description provided for @ownerCommissionsAllStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get ownerCommissionsAllStatus;

  /// No description provided for @ownerCommissionsSelectAllAccrued.
  ///
  /// In en, this message translates to:
  /// **'Select All Accrued ({count})'**
  String ownerCommissionsSelectAllAccrued(int count);

  /// No description provided for @ownerCommissionsAccrued.
  ///
  /// In en, this message translates to:
  /// **'accrued'**
  String get ownerCommissionsAccrued;

  /// No description provided for @ownerCommissionsRate.
  ///
  /// In en, this message translates to:
  /// **'RATE'**
  String get ownerCommissionsRate;

  /// No description provided for @ownerCommissionsDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get ownerCommissionsDate;

  /// No description provided for @ownerCommissionsJobCard.
  ///
  /// In en, this message translates to:
  /// **'JOB CARD'**
  String get ownerCommissionsJobCard;

  /// No description provided for @ownerCommissionsPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get ownerCommissionsPay;

  /// No description provided for @ownerDiscountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get ownerDiscountsTitle;

  /// No description provided for @ownerDiscountsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Discount'**
  String get ownerDiscountsTotal;

  /// No description provided for @ownerDiscountsLineItem.
  ///
  /// In en, this message translates to:
  /// **'Line / Item Discount'**
  String get ownerDiscountsLineItem;

  /// No description provided for @ownerDiscountsInvoices.
  ///
  /// In en, this message translates to:
  /// **'Discounted Invoices'**
  String get ownerDiscountsInvoices;

  /// No description provided for @ownerDiscountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No discounted invoices found'**
  String get ownerDiscountsEmptyTitle;

  /// No description provided for @ownerDiscountsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try widening the date range'**
  String get ownerDiscountsEmptyBody;

  /// No description provided for @ownerSuppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers & Purchases'**
  String get ownerSuppliersTitle;

  /// No description provided for @ownerSuppliersTabSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get ownerSuppliersTabSuppliers;

  /// No description provided for @ownerSuppliersTabHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get ownerSuppliersTabHistory;

  /// No description provided for @ownerSuppliersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search suppliers (name, phone, VAT)'**
  String get ownerSuppliersSearchHint;

  /// No description provided for @ownerSuppliersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get ownerSuppliersAdd;

  /// No description provided for @ownerSuppliersRole.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get ownerSuppliersRole;

  /// No description provided for @ownerSuppliersCr.
  ///
  /// In en, this message translates to:
  /// **'CR'**
  String get ownerSuppliersCr;

  /// No description provided for @ownerSuppliersVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get ownerSuppliersVat;

  /// No description provided for @ownerAffiliatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Affiliated Suppliers'**
  String get ownerAffiliatedTitle;

  /// No description provided for @ownerAffiliatedActive.
  ///
  /// In en, this message translates to:
  /// **'Active Suppliers'**
  String get ownerAffiliatedActive;

  /// No description provided for @ownerAffiliatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Suppliers'**
  String get ownerAffiliatedTotal;

  /// No description provided for @ownerAffiliatedPayable.
  ///
  /// In en, this message translates to:
  /// **'Aggregate Payable'**
  String get ownerAffiliatedPayable;

  /// No description provided for @ownerAffiliatedOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening {amount}'**
  String ownerAffiliatedOpening(String amount);

  /// No description provided for @ownerAffiliatedSNo.
  ///
  /// In en, this message translates to:
  /// **'S.No. {n} #'**
  String ownerAffiliatedSNo(int n);

  /// No description provided for @ownerAffiliatedAdd.
  ///
  /// In en, this message translates to:
  /// **'Add new supplier +'**
  String get ownerAffiliatedAdd;

  /// No description provided for @ownerNonAffiliatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Non-Affiliated Suppliers'**
  String get ownerNonAffiliatedTitle;

  /// No description provided for @ownerNonAffiliatedAdd.
  ///
  /// In en, this message translates to:
  /// **'Add new non-affiliated supplier +'**
  String get ownerNonAffiliatedAdd;

  /// No description provided for @ownerLockerTitle.
  ///
  /// In en, this message translates to:
  /// **'Locker Management'**
  String get ownerLockerTitle;

  /// No description provided for @ownerLockerAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned to Officer'**
  String get ownerLockerAssigned;

  /// No description provided for @ownerLockerPendingPickups.
  ///
  /// In en, this message translates to:
  /// **'Pending Pickups'**
  String get ownerLockerPendingPickups;

  /// No description provided for @ownerLockerVaultBalance.
  ///
  /// In en, this message translates to:
  /// **'Locker Vault Balance'**
  String get ownerLockerVaultBalance;

  /// No description provided for @ownerLockerTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get ownerLockerTabRequests;

  /// No description provided for @ownerLockerTabCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get ownerLockerTabCollections;

  /// No description provided for @ownerLockerTabDeposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get ownerLockerTabDeposits;

  /// No description provided for @ownerLockerTabPettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get ownerLockerTabPettyCash;

  /// No description provided for @ownerLockerRecentCollections.
  ///
  /// In en, this message translates to:
  /// **'Recent collections'**
  String get ownerLockerRecentCollections;

  /// No description provided for @ownerLockerColCashier.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get ownerLockerColCashier;

  /// No description provided for @ownerLockerColBranch.
  ///
  /// In en, this message translates to:
  /// **'BRANCH'**
  String get ownerLockerColBranch;

  /// No description provided for @ownerLockerColReference.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE'**
  String get ownerLockerColReference;

  /// No description provided for @ownerPettyClosingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get ownerPettyClosingBalance;

  /// No description provided for @ownerPettyTotalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get ownerPettyTotalCredit;

  /// No description provided for @ownerPettyTotalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total Debit'**
  String get ownerPettyTotalDebit;

  /// No description provided for @ownerPettyAccountCategory.
  ///
  /// In en, this message translates to:
  /// **'Account category'**
  String get ownerPettyAccountCategory;

  /// No description provided for @ownerPettyAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get ownerPettyAllCategories;

  /// No description provided for @ownerPettyUserEmployee.
  ///
  /// In en, this message translates to:
  /// **'User / employee'**
  String get ownerPettyUserEmployee;

  /// No description provided for @ownerPettyAllEmployees.
  ///
  /// In en, this message translates to:
  /// **'All employees'**
  String get ownerPettyAllEmployees;

  /// No description provided for @ownerPettyStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get ownerPettyStatement;

  /// No description provided for @ownerPettyOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get ownerPettyOpeningBalance;

  /// No description provided for @ownerPettyNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get ownerPettyNoTransactions;

  /// No description provided for @ownerPettyFromTo.
  ///
  /// In en, this message translates to:
  /// **'From {from} · To {to}'**
  String ownerPettyFromTo(String from, String to);

  /// No description provided for @ownerReportsColInvoice.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get ownerReportsColInvoice;

  /// No description provided for @ownerReportsColOrderType.
  ///
  /// In en, this message translates to:
  /// **'ORDER TYPE'**
  String get ownerReportsColOrderType;

  /// No description provided for @ownerReportsColStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get ownerReportsColStatus;

  /// No description provided for @ownerReportsColTotalSar.
  ///
  /// In en, this message translates to:
  /// **'TOTAL (SAR)'**
  String get ownerReportsColTotalSar;

  /// No description provided for @ownerReportsColTotalSarAr.
  ///
  /// In en, this message translates to:
  /// **'TOTAL (ر.س)'**
  String get ownerReportsColTotalSarAr;

  /// No description provided for @ownerReportsEmptyOrdersSearch.
  ///
  /// In en, this message translates to:
  /// **'No invoiced orders match your search.'**
  String get ownerReportsEmptyOrdersSearch;

  /// No description provided for @ownerReportsEmptyOrdersScope.
  ///
  /// In en, this message translates to:
  /// **'No invoiced orders in this scope.'**
  String get ownerReportsEmptyOrdersScope;

  /// No description provided for @ownerReportsNoInvoiceYet.
  ///
  /// In en, this message translates to:
  /// **'This order does not have an invoice yet.'**
  String get ownerReportsNoInvoiceYet;

  /// No description provided for @ownerReportsCouldNotLoadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Could not load invoice.'**
  String get ownerReportsCouldNotLoadInvoice;

  /// No description provided for @ownerReportsFailedOpenInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to open invoice. Please try again.'**
  String get ownerReportsFailedOpenInvoice;

  /// No description provided for @ownerReportsStatusInvoiced.
  ///
  /// In en, this message translates to:
  /// **'INVOICED'**
  String get ownerReportsStatusInvoiced;

  /// No description provided for @ownerReportsOrderWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk In'**
  String get ownerReportsOrderWalkIn;

  /// No description provided for @ownerReportsColCashier.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get ownerReportsColCashier;

  /// No description provided for @ownerReportsColTotalOrders.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ORDERS'**
  String get ownerReportsColTotalOrders;

  /// No description provided for @ownerReportsColTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'TOTAL REVENUE (SAR)'**
  String get ownerReportsColTotalRevenue;

  /// No description provided for @ownerReportsColBranch.
  ///
  /// In en, this message translates to:
  /// **'BRANCH'**
  String get ownerReportsColBranch;

  /// No description provided for @ownerReportsColCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED ORDERS'**
  String get ownerReportsColCompletedOrders;

  /// No description provided for @ownerReportsColRevenue.
  ///
  /// In en, this message translates to:
  /// **'REVENUE (SAR)'**
  String get ownerReportsColRevenue;

  /// No description provided for @ownerReportsColDepartment.
  ///
  /// In en, this message translates to:
  /// **'DEPARTMENT'**
  String get ownerReportsColDepartment;

  /// No description provided for @ownerReportsColOrders.
  ///
  /// In en, this message translates to:
  /// **'ORDERS'**
  String get ownerReportsColOrders;

  /// No description provided for @ownerReportsColProductService.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT / SERVICE'**
  String get ownerReportsColProductService;

  /// No description provided for @ownerReportsColType.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get ownerReportsColType;

  /// No description provided for @ownerReportsColQty.
  ///
  /// In en, this message translates to:
  /// **'QTY'**
  String get ownerReportsColQty;

  /// No description provided for @ownerReportsColPhone.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get ownerReportsColPhone;

  /// No description provided for @ownerReportsColPlate.
  ///
  /// In en, this message translates to:
  /// **'PLATE NUMBER'**
  String get ownerReportsColPlate;

  /// No description provided for @ownerReportsColTechnician.
  ///
  /// In en, this message translates to:
  /// **'TECHNICIAN'**
  String get ownerReportsColTechnician;

  /// No description provided for @ownerReportsColCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED JOBS'**
  String get ownerReportsColCompletedJobs;

  /// No description provided for @ownerReportsColCommission.
  ///
  /// In en, this message translates to:
  /// **'COMMISSION (SAR)'**
  String get ownerReportsColCommission;

  /// No description provided for @ownerReportsColDay.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get ownerReportsColDay;

  /// No description provided for @ownerReportsColDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get ownerReportsColDate;

  /// No description provided for @ownerCatalogAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get ownerCatalogAllTypes;

  /// No description provided for @ownerCatalogTypeProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get ownerCatalogTypeProduct;

  /// No description provided for @ownerCatalogTypeService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get ownerCatalogTypeService;

  /// No description provided for @ownerCatalogDepartmentSuffix.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get ownerCatalogDepartmentSuffix;

  /// No description provided for @ownerPurchaseQtyUnit.
  ///
  /// In en, this message translates to:
  /// **'QTY / UNIT'**
  String get ownerPurchaseQtyUnit;

  /// No description provided for @ownerPurchaseUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'UNIT PRICE'**
  String get ownerPurchaseUnitPrice;

  /// No description provided for @ownerPurchaseLineTotal.
  ///
  /// In en, this message translates to:
  /// **'LINE TOTAL'**
  String get ownerPurchaseLineTotal;

  /// No description provided for @ownerPurchaseTaxVat.
  ///
  /// In en, this message translates to:
  /// **'TAX (VAT)'**
  String get ownerPurchaseTaxVat;

  /// No description provided for @ownerPurchaseGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'GRAND TOTAL'**
  String get ownerPurchaseGrandTotal;

  /// No description provided for @ownerPurchaseHistoryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ownerPurchaseHistoryTotal;

  /// No description provided for @ownerPurchaseHistoryItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String ownerPurchaseHistoryItems(String count);

  /// No description provided for @ownerCommissionsNewRule.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get ownerCommissionsNewRule;

  /// No description provided for @ownerCommissionsRulesHeading.
  ///
  /// In en, this message translates to:
  /// **'Commission Rules'**
  String get ownerCommissionsRulesHeading;

  /// No description provided for @ownerCommissionsRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Priority engine: smaller priority value wins. Falls back to employee default percent if nothing matches.'**
  String get ownerCommissionsRulesHint;

  /// No description provided for @ownerCommissionsSearchRules.
  ///
  /// In en, this message translates to:
  /// **'Search rules'**
  String get ownerCommissionsSearchRules;

  /// No description provided for @ownerCommissionsNoRulesYet.
  ///
  /// In en, this message translates to:
  /// **'No commission rules yet — start by creating one'**
  String get ownerCommissionsNoRulesYet;

  /// No description provided for @ownerCommissionsPendingPayoutByEmployee.
  ///
  /// In en, this message translates to:
  /// **'Pending Payout by Employee'**
  String get ownerCommissionsPendingPayoutByEmployee;

  /// No description provided for @ownerCommissionsNoPendingPayouts.
  ///
  /// In en, this message translates to:
  /// **'No pending payouts.'**
  String get ownerCommissionsNoPendingPayouts;

  /// No description provided for @ownerCommissionsEntriesAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries · {amount}'**
  String ownerCommissionsEntriesAmount(String count, String amount);

  /// No description provided for @ownerCommissionsSelectedForPayout.
  ///
  /// In en, this message translates to:
  /// **'Selected for Payout'**
  String get ownerCommissionsSelectedForPayout;

  /// No description provided for @ownerCommissionsNoEntriesMatch.
  ///
  /// In en, this message translates to:
  /// **'No commission entries match these filters.'**
  String get ownerCommissionsNoEntriesMatch;

  /// No description provided for @ownerInventoryUomExplainer.
  ///
  /// In en, this message translates to:
  /// **'Create reusable packing rules — e.g. 1 Box = 12 Liter. Link a profile to each product. Stock is stored in workshop units.'**
  String get ownerInventoryUomExplainer;

  /// No description provided for @ownerInventoryLinkProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Profile to Product'**
  String get ownerInventoryLinkProfileTitle;

  /// No description provided for @ownerInventoryLinkProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign a packing profile to each product'**
  String get ownerInventoryLinkProfileSubtitle;

  /// No description provided for @ownerInventoryNewProfile.
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get ownerInventoryNewProfile;

  /// No description provided for @ownerInventoryNoProfilesYet.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet — create one to get started'**
  String get ownerInventoryNoProfilesYet;

  /// No description provided for @ownerInventoryLinkedProducts.
  ///
  /// In en, this message translates to:
  /// **'{count} linked products'**
  String ownerInventoryLinkedProducts(String count);

  /// No description provided for @ownerInventoryLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get ownerInventoryLink;

  /// No description provided for @ownerInventoryChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get ownerInventoryChange;

  /// No description provided for @ownerCommonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ownerCommonDelete;

  /// No description provided for @ownerCommonSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get ownerCommonSku;

  /// No description provided for @ownerCommonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerCommonCancel;

  /// No description provided for @ownerCommonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ownerCommonRetry;

  /// No description provided for @ownerCommonActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ownerCommonActiveLabel;

  /// No description provided for @ownerCommonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get ownerCommonEdit;

  /// No description provided for @ownerAffiliatedAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Affiliated Supplier(s)'**
  String get ownerAffiliatedAddTitle;

  /// No description provided for @ownerAffiliatedHideLinked.
  ///
  /// In en, this message translates to:
  /// **'Hide already linked suppliers'**
  String get ownerAffiliatedHideLinked;

  /// No description provided for @ownerAffiliatedCouldNotLoadBranches.
  ///
  /// In en, this message translates to:
  /// **'Could not load branches'**
  String get ownerAffiliatedCouldNotLoadBranches;

  /// No description provided for @ownerAffiliatedCouldNotLoadSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Could not load suppliers. Pull down to retry'**
  String get ownerAffiliatedCouldNotLoadSuppliers;

  /// No description provided for @ownerAffiliatedNoRegistered.
  ///
  /// In en, this message translates to:
  /// **'No registered suppliers found'**
  String get ownerAffiliatedNoRegistered;

  /// No description provided for @ownerAffiliatedLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get ownerAffiliatedLinked;

  /// No description provided for @ownerAffiliatedOpeningBal.
  ///
  /// In en, this message translates to:
  /// **'OPENING BAL.'**
  String get ownerAffiliatedOpeningBal;

  /// No description provided for @ownerAffiliatedAsOfDate.
  ///
  /// In en, this message translates to:
  /// **'AS OF DATE'**
  String get ownerAffiliatedAsOfDate;

  /// No description provided for @ownerAffiliatedDefaultBranch.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT BRANCH'**
  String get ownerAffiliatedDefaultBranch;

  /// No description provided for @ownerAffiliatedSearchRegistered.
  ///
  /// In en, this message translates to:
  /// **'SEARCH REGISTERED SUPPLIERS'**
  String get ownerAffiliatedSearchRegistered;

  /// No description provided for @ownerAffiliatedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search supplier, mobile, VAT or CR'**
  String get ownerAffiliatedSearchHint;

  /// No description provided for @ownerAffiliatedLoadingBranches.
  ///
  /// In en, this message translates to:
  /// **'Loading branches…'**
  String get ownerAffiliatedLoadingBranches;

  /// No description provided for @ownerAffiliatedAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get ownerAffiliatedAdding;

  /// No description provided for @ownerAffiliatedAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add supplier(s) {count}'**
  String ownerAffiliatedAddCount(String count);

  /// No description provided for @ownerLockerCashInTransit.
  ///
  /// In en, this message translates to:
  /// **'Cash in Transit — Locker'**
  String get ownerLockerCashInTransit;

  /// No description provided for @ownerLockerCashierClosings.
  ///
  /// In en, this message translates to:
  /// **'Cashier closings awaiting an officer'**
  String get ownerLockerCashierClosings;

  /// No description provided for @ownerLockerOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On-the-way collections'**
  String get ownerLockerOnTheWay;

  /// No description provided for @ownerLockerOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue (>24h)'**
  String get ownerLockerOverdue;

  /// No description provided for @ownerLockerOverdueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open longer than 24h'**
  String get ownerLockerOverdueSubtitle;

  /// No description provided for @ownerLockerPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get ownerLockerPendingApprovals;

  /// No description provided for @ownerLockerPendingApprovalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Variance awaiting supervisor'**
  String get ownerLockerPendingApprovalsSubtitle;

  /// No description provided for @ownerLockerCollectedToday.
  ///
  /// In en, this message translates to:
  /// **'Collected Today'**
  String get ownerLockerCollectedToday;

  /// No description provided for @ownerLockerMonthlyCollected.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collected'**
  String get ownerLockerMonthlyCollected;

  /// No description provided for @ownerLockerOpenShiftVariance.
  ///
  /// In en, this message translates to:
  /// **'Open-Shift Variance'**
  String get ownerLockerOpenShiftVariance;

  /// No description provided for @ownerLockerOpenShiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sum of |cashDiff| on open shifts'**
  String get ownerLockerOpenShiftSubtitle;

  /// No description provided for @ownerLockerTabStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get ownerLockerTabStaff;

  /// No description provided for @ownerLockerSupervisors.
  ///
  /// In en, this message translates to:
  /// **'Locker supervisors'**
  String get ownerLockerSupervisors;

  /// No description provided for @ownerLockerCollectionOfficers.
  ///
  /// In en, this message translates to:
  /// **'Collection officers'**
  String get ownerLockerCollectionOfficers;

  /// No description provided for @ownerLockerNoCollectors.
  ///
  /// In en, this message translates to:
  /// **'No collectors created yet'**
  String get ownerLockerNoCollectors;

  /// No description provided for @ownerLockerNoSupervisor.
  ///
  /// In en, this message translates to:
  /// **'No supervisor created yet'**
  String get ownerLockerNoSupervisor;

  /// No description provided for @ownerLockerColName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get ownerLockerColName;

  /// No description provided for @ownerLockerColEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get ownerLockerColEmail;

  /// No description provided for @ownerLockerColMobile.
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get ownerLockerColMobile;

  /// No description provided for @ownerLockerColStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get ownerLockerColStatus;

  /// No description provided for @ownerLockerRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent collection requests'**
  String get ownerLockerRecentRequests;

  /// No description provided for @ownerLockerBankDeposits.
  ///
  /// In en, this message translates to:
  /// **'Bank deposits (locker → bank)'**
  String get ownerLockerBankDeposits;

  /// No description provided for @ownerLockerPettyIssued.
  ///
  /// In en, this message translates to:
  /// **'Petty cash issued from locker'**
  String get ownerLockerPettyIssued;

  /// No description provided for @ownerDiscountsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get ownerDiscountsClearFilters;

  /// No description provided for @ownerDiscountsSheetDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get ownerDiscountsSheetDepartment;

  /// No description provided for @ownerDiscountsSheetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total discount'**
  String get ownerDiscountsSheetTotal;

  /// No description provided for @ownerDiscountsInvoiceDiscount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount'**
  String get ownerDiscountsInvoiceDiscount;

  /// No description provided for @ownerDiscountsPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get ownerDiscountsPromoCode;

  /// No description provided for @ownerRolesWorkshopRoles.
  ///
  /// In en, this message translates to:
  /// **'Workshop Roles'**
  String get ownerRolesWorkshopRoles;

  /// No description provided for @ownerRolesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom roles yet. Tap Create Role to bundle permissions you can assign to employees.'**
  String get ownerRolesEmpty;

  /// No description provided for @ownerRolesPermissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions'**
  String ownerRolesPermissionsCount(String count);

  /// No description provided for @ownerRolesPortalWorkshop.
  ///
  /// In en, this message translates to:
  /// **'workshop'**
  String get ownerRolesPortalWorkshop;

  /// No description provided for @ownerRolesPortalCashier.
  ///
  /// In en, this message translates to:
  /// **'cashier'**
  String get ownerRolesPortalCashier;

  /// No description provided for @ownerRolesPortalTechnician.
  ///
  /// In en, this message translates to:
  /// **'technician'**
  String get ownerRolesPortalTechnician;

  /// No description provided for @ownerRolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get ownerRolesAndPermissions;

  /// No description provided for @ownerRolesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? Any employees assigned to this role will lose its permissions.'**
  String ownerRolesDeleteConfirm(String name);

  /// No description provided for @ownerRolesSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get ownerRolesSaveChanges;

  /// No description provided for @ownerInventoryFormulaLabel.
  ///
  /// In en, this message translates to:
  /// **'Formula: '**
  String get ownerInventoryFormulaLabel;

  /// No description provided for @ownerInventoryFormulaBody.
  ///
  /// In en, this message translates to:
  /// **'for each product in scope, line value = current stock × purchase price. The KPI total is the sum of all line values (displayed rounded to the nearest {currency}).'**
  String ownerInventoryFormulaBody(String currency);

  /// No description provided for @ownerInventoryScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope: '**
  String get ownerInventoryScopeLabel;

  /// No description provided for @ownerInventoryScopeBody.
  ///
  /// In en, this message translates to:
  /// **'{branch}. Current stock uses branch on-hand quantity when set; otherwise adoption opening qty. Purchase price is the branch/catalog purchase price on each row.'**
  String ownerInventoryScopeBody(String branch);

  /// No description provided for @ownerInventoryScopeBodyShort.
  ///
  /// In en, this message translates to:
  /// **'{branch}. Current stock is branch on-hand when present; otherwise adoption opening qty.'**
  String ownerInventoryScopeBodyShort(String branch);

  /// No description provided for @ownerInventoryKpiCount.
  ///
  /// In en, this message translates to:
  /// **'KPI count'**
  String get ownerInventoryKpiCount;

  /// No description provided for @ownerCommonAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get ownerCommonAllBranches;

  /// No description provided for @ownerInventoryPctOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of total'**
  String ownerInventoryPctOfTotal(String pct);

  /// No description provided for @ownerInventoryValueCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Total inventory value — calculation'**
  String get ownerInventoryValueCalcTitle;

  /// No description provided for @ownerInventoryTotalExact.
  ///
  /// In en, this message translates to:
  /// **'Total (exact)'**
  String get ownerInventoryTotalExact;

  /// No description provided for @ownerInventoryKpiRounded.
  ///
  /// In en, this message translates to:
  /// **'KPI display (rounded)'**
  String get ownerInventoryKpiRounded;

  /// No description provided for @ownerInventorySkusInList.
  ///
  /// In en, this message translates to:
  /// **'SKUs in list'**
  String get ownerInventorySkusInList;

  /// No description provided for @ownerInventorySkusWithStock.
  ///
  /// In en, this message translates to:
  /// **'SKUs with stock > 0'**
  String get ownerInventorySkusWithStock;

  /// No description provided for @ownerInventorySkusWithValue.
  ///
  /// In en, this message translates to:
  /// **'SKUs with value > 0'**
  String get ownerInventorySkusWithValue;

  /// No description provided for @ownerPurchaseFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New Purchase Invoice'**
  String get ownerPurchaseFormTitle;

  /// No description provided for @ownerPurchaseFormSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up invoice…'**
  String get ownerPurchaseFormSettingUp;

  /// No description provided for @ownerPurchaseFormSupplierVendor.
  ///
  /// In en, this message translates to:
  /// **'Supplier / Vendor *'**
  String get ownerPurchaseFormSupplierVendor;

  /// No description provided for @ownerPurchaseFormBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch *'**
  String get ownerPurchaseFormBranch;

  /// No description provided for @ownerPurchaseFormIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get ownerPurchaseFormIssueDate;

  /// No description provided for @ownerPurchaseFormDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get ownerPurchaseFormDueDate;

  /// No description provided for @ownerPurchaseFormDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get ownerPurchaseFormDays;

  /// No description provided for @ownerPurchaseFormDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get ownerPurchaseFormDaysSuffix;

  /// No description provided for @ownerPurchaseFormDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String ownerPurchaseFormDueLabel(String date);

  /// No description provided for @ownerPurchaseFormRefOptional.
  ///
  /// In en, this message translates to:
  /// **'Ref # (Optional)'**
  String get ownerPurchaseFormRefOptional;

  /// No description provided for @ownerPurchaseFormVendorInv.
  ///
  /// In en, this message translates to:
  /// **'Vendor inv #'**
  String get ownerPurchaseFormVendorInv;

  /// No description provided for @ownerPurchaseFormDescOptional.
  ///
  /// In en, this message translates to:
  /// **'Invoice description (optional)'**
  String get ownerPurchaseFormDescOptional;

  /// No description provided for @ownerPurchaseFormLineItems.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get ownerPurchaseFormLineItems;

  /// No description provided for @ownerPurchaseFormAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get ownerPurchaseFormAddLine;

  /// No description provided for @ownerPurchaseFormItemN.
  ///
  /// In en, this message translates to:
  /// **'Item {n}'**
  String ownerPurchaseFormItemN(String n);

  /// No description provided for @ownerPurchaseFormProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get ownerPurchaseFormProduct;

  /// No description provided for @ownerPurchaseFormSearchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product…'**
  String get ownerPurchaseFormSearchProduct;

  /// No description provided for @ownerPurchaseFormCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get ownerPurchaseFormCreate;

  /// No description provided for @ownerPurchaseFormSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get ownerPurchaseFormSaveDraft;

  /// No description provided for @ownerPurchaseFormSelectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select supplier'**
  String get ownerPurchaseFormSelectSupplier;

  /// No description provided for @ownerPurchaseFormSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get ownerPurchaseFormSelectBranch;

  /// No description provided for @ownerPurchaseFormNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches available'**
  String get ownerPurchaseFormNoBranches;

  /// No description provided for @ownerPurchaseFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get ownerPurchaseFormAccount;

  /// No description provided for @ownerPurchaseFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ownerPurchaseFormDescription;

  /// No description provided for @ownerPurchaseFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description…'**
  String get ownerPurchaseFormDescriptionHint;

  /// No description provided for @ownerPurchaseFormQty.
  ///
  /// In en, this message translates to:
  /// **'QTY'**
  String get ownerPurchaseFormQty;

  /// No description provided for @ownerPurchaseFormUom.
  ///
  /// In en, this message translates to:
  /// **'UOM'**
  String get ownerPurchaseFormUom;

  /// No description provided for @ownerPurchaseFormUnitPriceExVat.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (Ex VAT)'**
  String get ownerPurchaseFormUnitPriceExVat;

  /// No description provided for @ownerPurchaseFormTaxCode.
  ///
  /// In en, this message translates to:
  /// **'Tax Code'**
  String get ownerPurchaseFormTaxCode;

  /// No description provided for @ownerPurchaseFormTotalExVat.
  ///
  /// In en, this message translates to:
  /// **'Total (Ex VAT)'**
  String get ownerPurchaseFormTotalExVat;

  /// No description provided for @ownerPurchaseFormTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get ownerPurchaseFormTax;

  /// No description provided for @ownerPurchaseFormTotalIncl.
  ///
  /// In en, this message translates to:
  /// **'Total (Incl.)'**
  String get ownerPurchaseFormTotalIncl;

  /// No description provided for @ownerPurchaseFormLastFromSupplier.
  ///
  /// In en, this message translates to:
  /// **'Last from supplier: {amount}'**
  String ownerPurchaseFormLastFromSupplier(String amount);

  /// No description provided for @ownerPurchaseFormSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get ownerPurchaseFormSubtotal;

  /// No description provided for @ownerPurchaseFormTotalTaxVat.
  ///
  /// In en, this message translates to:
  /// **'Total Tax (VAT):'**
  String get ownerPurchaseFormTotalTaxVat;

  /// No description provided for @ownerPurchaseFormGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total:'**
  String get ownerPurchaseFormGrandTotal;

  /// No description provided for @ownerPurchaseFormInvoiceDiscount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount'**
  String get ownerPurchaseFormInvoiceDiscount;

  /// No description provided for @ownerPurchaseFormFreight.
  ///
  /// In en, this message translates to:
  /// **'Freight ({currency})'**
  String ownerPurchaseFormFreight(String currency);

  /// No description provided for @ownerPurchaseFormNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ownerPurchaseFormNotes;

  /// No description provided for @ownerPurchaseFormInternalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal notes'**
  String get ownerPurchaseFormInternalNotes;

  /// No description provided for @ownerPurchaseFormColDescription.
  ///
  /// In en, this message translates to:
  /// **'Column — Description'**
  String get ownerPurchaseFormColDescription;

  /// No description provided for @ownerPurchaseFormColDiscount.
  ///
  /// In en, this message translates to:
  /// **'Column — Discount'**
  String get ownerPurchaseFormColDiscount;

  /// No description provided for @ownerPurchaseFormAmountsTaxInclusive.
  ///
  /// In en, this message translates to:
  /// **'Amounts are tax inclusive'**
  String get ownerPurchaseFormAmountsTaxInclusive;

  /// No description provided for @ownerPurchaseFormUpdateLastPrice.
  ///
  /// In en, this message translates to:
  /// **'Update last purchase price for all products on save (master catalog)'**
  String get ownerPurchaseFormUpdateLastPrice;

  /// No description provided for @ownerPurchaseFormSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Saved as draft'**
  String get ownerPurchaseFormSavedDraft;

  /// No description provided for @ownerPurchaseFormCreated.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoice Created!'**
  String get ownerPurchaseFormCreated;

  /// No description provided for @ownerPurchaseFormCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create invoice. Please try again.'**
  String get ownerPurchaseFormCreateFailed;

  /// No description provided for @ownerPurchaseFormDiscountType.
  ///
  /// In en, this message translates to:
  /// **'Discount type'**
  String get ownerPurchaseFormDiscountType;

  /// No description provided for @ownerPurchaseFormFixedAmount.
  ///
  /// In en, this message translates to:
  /// **'Fixed ({currency})'**
  String ownerPurchaseFormFixedAmount(String currency);

  /// No description provided for @ownerPurchaseFormPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent (%)'**
  String get ownerPurchaseFormPercent;

  /// No description provided for @ownerPurchaseFormDueType.
  ///
  /// In en, this message translates to:
  /// **'Due type'**
  String get ownerPurchaseFormDueType;

  /// No description provided for @ownerPurchaseFormDueNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get ownerPurchaseFormDueNet;

  /// No description provided for @ownerPurchaseFormDueEom.
  ///
  /// In en, this message translates to:
  /// **'EOM'**
  String get ownerPurchaseFormDueEom;

  /// No description provided for @ownerPurchaseFormDueCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get ownerPurchaseFormDueCustom;

  /// No description provided for @ownerPurchaseFormApCreates.
  ///
  /// In en, this message translates to:
  /// **'Creates '**
  String get ownerPurchaseFormApCreates;

  /// No description provided for @ownerPurchaseFormApLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts Payable'**
  String get ownerPurchaseFormApLabel;

  /// No description provided for @ownerPurchaseFormApAfter.
  ///
  /// In en, this message translates to:
  /// **'. After goods received, click \"Update Stock\" in the list.'**
  String get ownerPurchaseFormApAfter;

  /// No description provided for @ownerPurchaseFormProductPriceMeta.
  ///
  /// In en, this message translates to:
  /// **'{unit} · {price}'**
  String ownerPurchaseFormProductPriceMeta(String unit, String price);

  /// No description provided for @ownerCommissionsEditRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Commission Rule'**
  String get ownerCommissionsEditRule;

  /// No description provided for @ownerCommissionsNewRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'New Commission Rule'**
  String get ownerCommissionsNewRuleTitle;

  /// No description provided for @ownerCommissionsPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority *'**
  String get ownerCommissionsPriority;

  /// No description provided for @ownerCommissionsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ownerCommissionsStatus;

  /// No description provided for @ownerCommissionsService.
  ///
  /// In en, this message translates to:
  /// **'Service *'**
  String get ownerCommissionsService;

  /// No description provided for @ownerCommissionsCustomService.
  ///
  /// In en, this message translates to:
  /// **'Custom service name (no link)'**
  String get ownerCommissionsCustomService;

  /// No description provided for @ownerCommissionsServiceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Service name (e.g. Oil Change)'**
  String get ownerCommissionsServiceNameHint;

  /// No description provided for @ownerCommissionsEmployeeRole.
  ///
  /// In en, this message translates to:
  /// **'Employee role'**
  String get ownerCommissionsEmployeeRole;

  /// No description provided for @ownerCommissionsRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get ownerCommissionsRoleHint;

  /// No description provided for @ownerCommissionsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get ownerCommissionsType;

  /// No description provided for @ownerCommissionsTypePercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage of total (%)'**
  String get ownerCommissionsTypePercentage;

  /// No description provided for @ownerCommissionsTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount per job ({currency})'**
  String ownerCommissionsTypeFixed(String currency);

  /// No description provided for @ownerCommissionsValuePercent.
  ///
  /// In en, this message translates to:
  /// **'Value (%)'**
  String get ownerCommissionsValuePercent;

  /// No description provided for @ownerCommissionsValueSar.
  ///
  /// In en, this message translates to:
  /// **'Value ({currency})'**
  String ownerCommissionsValueSar(String currency);

  /// No description provided for @ownerCommissionsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ownerCommissionsNotes;

  /// No description provided for @ownerCommissionsCreateRule.
  ///
  /// In en, this message translates to:
  /// **'Create Rule'**
  String get ownerCommissionsCreateRule;

  /// No description provided for @ownerCommissionsSaveRule.
  ///
  /// In en, this message translates to:
  /// **'Save Rule'**
  String get ownerCommissionsSaveRule;

  /// No description provided for @ownerAddSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier to Workshop'**
  String get ownerAddSupplierTitle;

  /// No description provided for @ownerAddSupplierSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search all registered suppliers...'**
  String get ownerAddSupplierSearchHint;

  /// No description provided for @ownerAddSupplierWorkshopOnly.
  ///
  /// In en, this message translates to:
  /// **'Workshop-only'**
  String get ownerAddSupplierWorkshopOnly;

  /// No description provided for @ownerAddSupplierAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add Selected ({count})'**
  String ownerAddSupplierAddSelected(String count);

  /// No description provided for @ownerAddSupplierPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Pick on-platform suppliers below (they can use the supplier portal), or add a workshop-only vendor who has no login.'**
  String get ownerAddSupplierPickerHint;

  /// No description provided for @ownerAddSupplierWorkshopOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add workshop-only supplier'**
  String get ownerAddSupplierWorkshopOnlyTitle;

  /// No description provided for @ownerAddSupplierWorkshopOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'This vendor is stored for your workshop only. They are not given a supplier portal account. To link an on-platform supplier that can log in, use the list above and Add Selected.'**
  String get ownerAddSupplierWorkshopOnlyHint;

  /// No description provided for @ownerAddSupplierName.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get ownerAddSupplierName;

  /// No description provided for @ownerAddSupplierCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get ownerAddSupplierCompanyHint;

  /// No description provided for @ownerAddSupplierMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get ownerAddSupplierMobile;

  /// No description provided for @ownerAddSupplierVatNumber.
  ///
  /// In en, this message translates to:
  /// **'VAT number'**
  String get ownerAddSupplierVatNumber;

  /// No description provided for @ownerAddSupplierAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get ownerAddSupplierAddress;

  /// No description provided for @ownerAddSupplierNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ownerAddSupplierNotes;

  /// No description provided for @ownerAddSupplierBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get ownerAddSupplierBack;

  /// No description provided for @ownerAddSupplierAddToWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Add to workshop'**
  String get ownerAddSupplierAddToWorkshop;

  /// No description provided for @ownerAddSupplierSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get ownerAddSupplierSelect;

  /// No description provided for @ownerAddSupplierSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get ownerAddSupplierSelected;

  /// No description provided for @ownerAddSupplierColSupplier.
  ///
  /// In en, this message translates to:
  /// **'SUPPLIER'**
  String get ownerAddSupplierColSupplier;

  /// No description provided for @ownerAddSupplierColContact.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get ownerAddSupplierColContact;

  /// No description provided for @ownerAddSupplierColAction.
  ///
  /// In en, this message translates to:
  /// **'ACTION'**
  String get ownerAddSupplierColAction;

  /// No description provided for @ownerAddSupplierNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No suppliers match your search'**
  String get ownerAddSupplierNoMatch;

  /// No description provided for @ownerAddSupplierCrValue.
  ///
  /// In en, this message translates to:
  /// **'{label} {value}'**
  String ownerAddSupplierCrValue(String label, String value);

  /// No description provided for @ownerNonAffiliatedAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Non-Affiliated Supplier'**
  String get ownerNonAffiliatedAddTitle;

  /// No description provided for @ownerNonAffiliatedEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Non-Affiliated Supplier'**
  String get ownerNonAffiliatedEditTitle;

  /// No description provided for @ownerNonAffiliatedSupplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier name *'**
  String get ownerNonAffiliatedSupplierName;

  /// No description provided for @ownerNonAffiliatedNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Local Trading Co.'**
  String get ownerNonAffiliatedNameHint;

  /// No description provided for @ownerNonAffiliatedContactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get ownerNonAffiliatedContactPerson;

  /// No description provided for @ownerNonAffiliatedPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get ownerNonAffiliatedPhone;

  /// No description provided for @ownerNonAffiliatedEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ownerNonAffiliatedEmail;

  /// No description provided for @ownerNonAffiliatedVatId.
  ///
  /// In en, this message translates to:
  /// **'VAT ID'**
  String get ownerNonAffiliatedVatId;

  /// No description provided for @ownerNonAffiliatedCrNumber.
  ///
  /// In en, this message translates to:
  /// **'CR Number'**
  String get ownerNonAffiliatedCrNumber;

  /// No description provided for @ownerNonAffiliatedAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get ownerNonAffiliatedAddress;

  /// No description provided for @ownerNonAffiliatedOpeningBalanceSar.
  ///
  /// In en, this message translates to:
  /// **'Opening balance ({currency})'**
  String ownerNonAffiliatedOpeningBalanceSar(String currency);

  /// No description provided for @ownerNonAffiliatedAsOfDate.
  ///
  /// In en, this message translates to:
  /// **'As of date'**
  String get ownerNonAffiliatedAsOfDate;

  /// No description provided for @ownerNonAffiliatedDateHint.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get ownerNonAffiliatedDateHint;

  /// No description provided for @ownerNonAffiliatedAddSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get ownerNonAffiliatedAddSupplier;

  /// No description provided for @ownerNonAffiliatedRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get ownerNonAffiliatedRequired;

  /// No description provided for @ownerNonAffiliatedUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again.'**
  String get ownerNonAffiliatedUpdateFailed;

  /// No description provided for @ownerNonAffiliatedAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add supplier. Please try again.'**
  String get ownerNonAffiliatedAddFailed;

  /// No description provided for @ownerNonAffiliatedNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String ownerNonAffiliatedNetworkError(String error);

  /// No description provided for @ownerRolesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Workshop Role'**
  String get ownerRolesCreateTitle;

  /// No description provided for @ownerRolesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get ownerRolesEditTitle;

  /// No description provided for @ownerRolesFieldPortal.
  ///
  /// In en, this message translates to:
  /// **'PORTAL'**
  String get ownerRolesFieldPortal;

  /// No description provided for @ownerRolesFieldRoleName.
  ///
  /// In en, this message translates to:
  /// **'ROLE NAME'**
  String get ownerRolesFieldRoleName;

  /// No description provided for @ownerRolesFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get ownerRolesFieldDescription;

  /// No description provided for @ownerRolesFieldBranchAccess.
  ///
  /// In en, this message translates to:
  /// **'BRANCH ACCESS'**
  String get ownerRolesFieldBranchAccess;

  /// No description provided for @ownerRolesPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get ownerRolesPermissionsTitle;

  /// No description provided for @ownerRolesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total} selected'**
  String ownerRolesSelectedCount(String selected, String total);

  /// No description provided for @ownerRolesSectionCount.
  ///
  /// In en, this message translates to:
  /// **'{selected}/{total}'**
  String ownerRolesSectionCount(String selected, String total);

  /// No description provided for @ownerRolesPickRoleName.
  ///
  /// In en, this message translates to:
  /// **'— Pick a role name —'**
  String get ownerRolesPickRoleName;

  /// No description provided for @ownerRolesTypeCustomName.
  ///
  /// In en, this message translates to:
  /// **'Type a custom name'**
  String get ownerRolesTypeCustomName;

  /// No description provided for @ownerRolesSelectPortal.
  ///
  /// In en, this message translates to:
  /// **'Select portal'**
  String get ownerRolesSelectPortal;

  /// No description provided for @ownerRolesSelectBranchAccess.
  ///
  /// In en, this message translates to:
  /// **'Select branch access'**
  String get ownerRolesSelectBranchAccess;

  /// No description provided for @ownerRolesAllBranchesNoRestriction.
  ///
  /// In en, this message translates to:
  /// **'All Branches (no restriction)'**
  String get ownerRolesAllBranchesNoRestriction;

  /// No description provided for @ownerRolesSpecificBranches.
  ///
  /// In en, this message translates to:
  /// **'Specific Branches...'**
  String get ownerRolesSpecificBranches;

  /// No description provided for @ownerRolesCustomName.
  ///
  /// In en, this message translates to:
  /// **'Custom name…'**
  String get ownerRolesCustomName;

  /// No description provided for @ownerRolesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Role'**
  String get ownerRolesDeleteTitle;

  /// No description provided for @ownerRoleNameLockerCollector.
  ///
  /// In en, this message translates to:
  /// **'Locker Collector'**
  String get ownerRoleNameLockerCollector;

  /// No description provided for @ownerRoleNameLockerSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Locker Supervisor'**
  String get ownerRoleNameLockerSupervisor;

  /// No description provided for @ownerRoleNameManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get ownerRoleNameManager;

  /// No description provided for @ownerRoleNameCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get ownerRoleNameCashier;

  /// No description provided for @ownerRoleNameTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get ownerRoleNameTechnician;

  /// No description provided for @ownerRoleNameSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get ownerRoleNameSupervisor;

  /// No description provided for @ownerRoleNameTeamLeader.
  ///
  /// In en, this message translates to:
  /// **'Team Leader'**
  String get ownerRoleNameTeamLeader;

  /// No description provided for @ownerPermActionView.
  ///
  /// In en, this message translates to:
  /// **'view'**
  String get ownerPermActionView;

  /// No description provided for @ownerPermActionApprove.
  ///
  /// In en, this message translates to:
  /// **'approve'**
  String get ownerPermActionApprove;

  /// No description provided for @ownerPermActionReject.
  ///
  /// In en, this message translates to:
  /// **'reject'**
  String get ownerPermActionReject;

  /// No description provided for @ownerPermActionCreate.
  ///
  /// In en, this message translates to:
  /// **'create'**
  String get ownerPermActionCreate;

  /// No description provided for @ownerPermActionEdit.
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get ownerPermActionEdit;

  /// No description provided for @ownerPermActionDelete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get ownerPermActionDelete;

  /// No description provided for @ownerPermActionAdd.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get ownerPermActionAdd;

  /// No description provided for @ownerPermActionExport.
  ///
  /// In en, this message translates to:
  /// **'export'**
  String get ownerPermActionExport;

  /// No description provided for @ownerPermActionIssue.
  ///
  /// In en, this message translates to:
  /// **'issue'**
  String get ownerPermActionIssue;

  /// No description provided for @ownerPermSecControl.
  ///
  /// In en, this message translates to:
  /// **'CONTROL'**
  String get ownerPermSecControl;

  /// No description provided for @ownerPermSecOperations.
  ///
  /// In en, this message translates to:
  /// **'OPERATIONS'**
  String get ownerPermSecOperations;

  /// No description provided for @ownerPermSecAccounting.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNTING'**
  String get ownerPermSecAccounting;

  /// No description provided for @ownerPermDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get ownerPermDashboard;

  /// No description provided for @ownerPermApprovalsQueue.
  ///
  /// In en, this message translates to:
  /// **'Approvals Queue (Page Access)'**
  String get ownerPermApprovalsQueue;

  /// No description provided for @ownerPermTopUpRequests.
  ///
  /// In en, this message translates to:
  /// **'Top-up requests'**
  String get ownerPermTopUpRequests;

  /// No description provided for @ownerPermExpenseRequests.
  ///
  /// In en, this message translates to:
  /// **'Expense requests'**
  String get ownerPermExpenseRequests;

  /// No description provided for @ownerPermSupplierInvoices.
  ///
  /// In en, this message translates to:
  /// **'Supplier invoices'**
  String get ownerPermSupplierInvoices;

  /// No description provided for @ownerPermSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales returns'**
  String get ownerPermSalesReturns;

  /// No description provided for @ownerPermEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get ownerPermEmployees;

  /// No description provided for @ownerPermBranchPortals.
  ///
  /// In en, this message translates to:
  /// **'Branch Portals'**
  String get ownerPermBranchPortals;

  /// No description provided for @ownerPermAccessPermissions.
  ///
  /// In en, this message translates to:
  /// **'Access Permissions'**
  String get ownerPermAccessPermissions;

  /// No description provided for @ownerPermRolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get ownerPermRolesPermissions;

  /// No description provided for @ownerPermDepartmentsTab.
  ///
  /// In en, this message translates to:
  /// **'Departments tab'**
  String get ownerPermDepartmentsTab;

  /// No description provided for @ownerPermProductsTab.
  ///
  /// In en, this message translates to:
  /// **'Products tab'**
  String get ownerPermProductsTab;

  /// No description provided for @ownerPermServicesTab.
  ///
  /// In en, this message translates to:
  /// **'Services tab'**
  String get ownerPermServicesTab;

  /// No description provided for @ownerPermCategoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories tab'**
  String get ownerPermCategoriesTab;

  /// No description provided for @ownerPermMasterCatalog.
  ///
  /// In en, this message translates to:
  /// **'Master Catalog (Page Access)'**
  String get ownerPermMasterCatalog;

  /// No description provided for @ownerPermDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get ownerPermDepartments;

  /// No description provided for @ownerPermCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get ownerPermCategories;

  /// No description provided for @ownerPermProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get ownerPermProducts;

  /// No description provided for @ownerPermServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get ownerPermServices;

  /// No description provided for @ownerPermManageInventory.
  ///
  /// In en, this message translates to:
  /// **'Manage Inventory'**
  String get ownerPermManageInventory;

  /// No description provided for @ownerPermPurchaseInvoicesPage.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoices (Page Access)'**
  String get ownerPermPurchaseInvoicesPage;

  /// No description provided for @ownerPermInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get ownerPermInvoices;

  /// No description provided for @ownerPermPriceReport.
  ///
  /// In en, this message translates to:
  /// **'Price Report'**
  String get ownerPermPriceReport;

  /// No description provided for @ownerPermSuppliersList.
  ///
  /// In en, this message translates to:
  /// **'Suppliers list'**
  String get ownerPermSuppliersList;

  /// No description provided for @ownerPermPurchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase history'**
  String get ownerPermPurchaseHistory;

  /// No description provided for @ownerPermFilterAffiliated.
  ///
  /// In en, this message translates to:
  /// **'Filter Affiliated Suppliers'**
  String get ownerPermFilterAffiliated;

  /// No description provided for @ownerPermReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get ownerPermReports;

  /// No description provided for @ownerPermOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ownerPermOrders;

  /// No description provided for @ownerPermDailySales.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales'**
  String get ownerPermDailySales;

  /// No description provided for @ownerPermByTechnician.
  ///
  /// In en, this message translates to:
  /// **'By Technician'**
  String get ownerPermByTechnician;

  /// No description provided for @ownerPermByCustomer.
  ///
  /// In en, this message translates to:
  /// **'By Customer'**
  String get ownerPermByCustomer;

  /// No description provided for @ownerPermByProduct.
  ///
  /// In en, this message translates to:
  /// **'By Product'**
  String get ownerPermByProduct;

  /// No description provided for @ownerPermByDepartment.
  ///
  /// In en, this message translates to:
  /// **'By Department'**
  String get ownerPermByDepartment;

  /// No description provided for @ownerPermByBranch.
  ///
  /// In en, this message translates to:
  /// **'By Branch'**
  String get ownerPermByBranch;

  /// No description provided for @ownerPermByCashier.
  ///
  /// In en, this message translates to:
  /// **'By Cashier'**
  String get ownerPermByCashier;

  /// No description provided for @ownerPermPosMonitoring.
  ///
  /// In en, this message translates to:
  /// **'POS Monitoring'**
  String get ownerPermPosMonitoring;

  /// No description provided for @ownerPermLockerManagement.
  ///
  /// In en, this message translates to:
  /// **'Locker Management'**
  String get ownerPermLockerManagement;

  /// No description provided for @ownerPermMyPettyCash.
  ///
  /// In en, this message translates to:
  /// **'My Petty Cash'**
  String get ownerPermMyPettyCash;

  /// No description provided for @ownerPermPromoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo Codes'**
  String get ownerPermPromoCodes;

  /// No description provided for @ownerPermCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate Management'**
  String get ownerPermCorporate;

  /// No description provided for @ownerPermCommissionsPage.
  ///
  /// In en, this message translates to:
  /// **'Commissions (Page Access)'**
  String get ownerPermCommissionsPage;

  /// No description provided for @ownerPermLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ownerPermLedger;

  /// No description provided for @ownerPermRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get ownerPermRules;

  /// No description provided for @ownerPermCoaPage.
  ///
  /// In en, this message translates to:
  /// **'Chart of Accounts (Page Access)'**
  String get ownerPermCoaPage;

  /// No description provided for @ownerPermCoa.
  ///
  /// In en, this message translates to:
  /// **'Chart of Accounts'**
  String get ownerPermCoa;

  /// No description provided for @ownerPermTrialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial Balance'**
  String get ownerPermTrialBalance;

  /// No description provided for @ownerPermPnl.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get ownerPermPnl;

  /// No description provided for @ownerPermBalanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get ownerPermBalanceSheet;

  /// No description provided for @ownerPermTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get ownerPermTransactions;

  /// No description provided for @ownerPermJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'Journal Entries'**
  String get ownerPermJournalEntries;

  /// No description provided for @ownerPermPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get ownerPermPurchases;

  /// No description provided for @ownerPermExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get ownerPermExpenses;

  /// No description provided for @ownerPermReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get ownerPermReceipts;

  /// No description provided for @ownerPermPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get ownerPermPayments;

  /// No description provided for @ownerPermAdvances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get ownerPermAdvances;

  /// No description provided for @ownerPermPayrollRun.
  ///
  /// In en, this message translates to:
  /// **'Payroll Run'**
  String get ownerPermPayrollRun;

  /// No description provided for @ownerPermApprovalLimits.
  ///
  /// In en, this message translates to:
  /// **'Approval Limits'**
  String get ownerPermApprovalLimits;

  /// No description provided for @ownerEmpFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Employee'**
  String get ownerEmpFormAddTitle;

  /// No description provided for @ownerEmpFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get ownerEmpFormEditTitle;

  /// No description provided for @ownerEmpFormBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get ownerEmpFormBasicInfo;

  /// No description provided for @ownerEmpFormFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get ownerEmpFormFullName;

  /// No description provided for @ownerEmpFormMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get ownerEmpFormMobile;

  /// No description provided for @ownerEmpFormEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ownerEmpFormEmail;

  /// No description provided for @ownerEmpFormIqama.
  ///
  /// In en, this message translates to:
  /// **'Iqama / CNIC'**
  String get ownerEmpFormIqama;

  /// No description provided for @ownerEmpFormBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get ownerEmpFormBranch;

  /// No description provided for @ownerEmpFormSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select Branch'**
  String get ownerEmpFormSelectBranch;

  /// No description provided for @ownerEmpFormNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches'**
  String get ownerEmpFormNoBranches;

  /// No description provided for @ownerEmpFormRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get ownerEmpFormRole;

  /// No description provided for @ownerEmpFormSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select role'**
  String get ownerEmpFormSelectRole;

  /// No description provided for @ownerEmpFormRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Job title — controls which workshop sub-flow they\'re slotted into.'**
  String get ownerEmpFormRoleHint;

  /// No description provided for @ownerEmpFormDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get ownerEmpFormDepartments;

  /// No description provided for @ownerEmpFormDepartmentsSuffix.
  ///
  /// In en, this message translates to:
  /// **' (Workshop departments this technician can work in)'**
  String get ownerEmpFormDepartmentsSuffix;

  /// No description provided for @ownerEmpFormTechSettings.
  ///
  /// In en, this message translates to:
  /// **'Technician Settings'**
  String get ownerEmpFormTechSettings;

  /// No description provided for @ownerEmpFormIsTechnician.
  ///
  /// In en, this message translates to:
  /// **'This employee is a Technician'**
  String get ownerEmpFormIsTechnician;

  /// No description provided for @ownerEmpFormTechType.
  ///
  /// In en, this message translates to:
  /// **'Technician Type'**
  String get ownerEmpFormTechType;

  /// No description provided for @ownerEmpFormTechTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Default for new technicians: both Workshop and On-Call are enabled.'**
  String get ownerEmpFormTechTypeHint;

  /// No description provided for @ownerEmpFormWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get ownerEmpFormWorkshop;

  /// No description provided for @ownerEmpFormOnCall.
  ///
  /// In en, this message translates to:
  /// **'On-Call'**
  String get ownerEmpFormOnCall;

  /// No description provided for @ownerEmpFormFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get ownerEmpFormFinancial;

  /// No description provided for @ownerEmpFormBasicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary ({currency})'**
  String ownerEmpFormBasicSalary(String currency);

  /// No description provided for @ownerEmpFormCommissionPct.
  ///
  /// In en, this message translates to:
  /// **'Commission %'**
  String get ownerEmpFormCommissionPct;

  /// No description provided for @ownerEmpFormCommissionType.
  ///
  /// In en, this message translates to:
  /// **'Commission Type'**
  String get ownerEmpFormCommissionType;

  /// No description provided for @ownerEmpFormSelectType.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get ownerEmpFormSelectType;

  /// No description provided for @ownerEmpFormStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ownerEmpFormStatus;

  /// No description provided for @ownerEmpFormSelectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select status'**
  String get ownerEmpFormSelectStatus;

  /// No description provided for @ownerEmpFormInitialPassword.
  ///
  /// In en, this message translates to:
  /// **'Initial Password'**
  String get ownerEmpFormInitialPassword;

  /// No description provided for @ownerEmpFormPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password (optional — a temporary password is generated if blank)'**
  String get ownerEmpFormPasswordHint;

  /// No description provided for @ownerEmpFormPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to auto-generate'**
  String get ownerEmpFormPasswordPlaceholder;

  /// No description provided for @ownerEmpFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get ownerEmpFormSave;

  /// No description provided for @ownerEmpFormMobileHint.
  ///
  /// In en, this message translates to:
  /// **'05XXXXXXXX'**
  String get ownerEmpFormMobileHint;

  /// No description provided for @ownerEmpRoleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get ownerEmpRoleStaff;

  /// No description provided for @ownerEmpCommOfRevenue.
  ///
  /// In en, this message translates to:
  /// **'% of Revenue'**
  String get ownerEmpCommOfRevenue;

  /// No description provided for @ownerEmpCommOfProfit.
  ///
  /// In en, this message translates to:
  /// **'% of Profit'**
  String get ownerEmpCommOfProfit;

  /// No description provided for @ownerEmpCommFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get ownerEmpCommFixed;

  /// No description provided for @ownerEmpCommOfService.
  ///
  /// In en, this message translates to:
  /// **'% of Service'**
  String get ownerEmpCommOfService;

  /// No description provided for @ownerEmpCommFixedPerOrder.
  ///
  /// In en, this message translates to:
  /// **'Fixed per Order'**
  String get ownerEmpCommFixedPerOrder;

  /// No description provided for @ownerEmpFormNoDepartments.
  ///
  /// In en, this message translates to:
  /// **'No departments found. Create one first.'**
  String get ownerEmpFormNoDepartments;

  /// No description provided for @ownerEmpMenuResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get ownerEmpMenuResetPassword;

  /// No description provided for @ownerEmpMenuPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get ownerEmpMenuPermissions;

  /// No description provided for @ownerEmpResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get ownerEmpResetTitle;

  /// No description provided for @ownerEmpResetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get ownerEmpResetNewPassword;

  /// No description provided for @ownerEmpResetHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get ownerEmpResetHint;

  /// No description provided for @ownerEmpAssignRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Role'**
  String get ownerEmpAssignRoleTitle;

  /// No description provided for @ownerEmpAssignRoleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom roles available. Create a role first from the Roles tab.'**
  String get ownerEmpAssignRoleEmpty;

  /// No description provided for @ownerEmpColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ownerEmpColName;

  /// No description provided for @ownerEmpColRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get ownerEmpColRole;

  /// No description provided for @ownerEmpColAssignedRole.
  ///
  /// In en, this message translates to:
  /// **'Assigned Role'**
  String get ownerEmpColAssignedRole;

  /// No description provided for @ownerEmpColDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get ownerEmpColDepartment;

  /// No description provided for @ownerEmpColBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get ownerEmpColBranch;

  /// No description provided for @ownerEmpColPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get ownerEmpColPhone;

  /// No description provided for @ownerEmpColCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission %'**
  String get ownerEmpColCommission;

  /// No description provided for @ownerEmpColWorkshopDuty.
  ///
  /// In en, this message translates to:
  /// **'Workshop Duty'**
  String get ownerEmpColWorkshopDuty;

  /// No description provided for @ownerEmpColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ownerEmpColStatus;

  /// No description provided for @ownerEmpColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get ownerEmpColActions;

  /// No description provided for @ownerCommonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ownerCommonClose;

  /// No description provided for @ownerEmpDutyOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get ownerEmpDutyOff;

  /// No description provided for @techPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Portal'**
  String get techPortalTitle;

  /// No description provided for @techPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your workspace'**
  String get techPortalSubtitle;

  /// No description provided for @techLoginInvalidCreds.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get techLoginInvalidCreds;

  /// No description provided for @techLoginNoPortalAccess.
  ///
  /// In en, this message translates to:
  /// **'This account does not have Technician portal access. Use the correct portal for your role.'**
  String get techLoginNoPortalAccess;

  /// No description provided for @techLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get techLoginSuccess;

  /// No description provided for @techLoginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get techLoginEmailRequired;

  /// No description provided for @techLoginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get techLoginEmailInvalid;

  /// No description provided for @techLoginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get techLoginPasswordRequired;

  /// No description provided for @techDashWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back,'**
  String get techDashWelcomeBack;

  /// No description provided for @techDashPerformance.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE'**
  String get techDashPerformance;

  /// No description provided for @techDashDutyMode.
  ///
  /// In en, this message translates to:
  /// **'DUTY MODE'**
  String get techDashDutyMode;

  /// No description provided for @techDashOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You are currently offline'**
  String get techDashOfflineTitle;

  /// No description provided for @techDashOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'The cashier has set your status to offline. Workshop and on-call duties are unavailable until you are marked online again.'**
  String get techDashOfflineBody;

  /// No description provided for @techDashWorkshopDutyHint.
  ///
  /// In en, this message translates to:
  /// **'(In-house)'**
  String get techDashWorkshopDutyHint;

  /// No description provided for @techDashOnCallDutyHint.
  ///
  /// In en, this message translates to:
  /// **'(Emergency)'**
  String get techDashOnCallDutyHint;

  /// No description provided for @techDashDutyHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn workshop or on-call duty on for the jobs you want to receive. Only one can be active at a time.'**
  String get techDashDutyHelp;

  /// No description provided for @techDashRevenueEarned.
  ///
  /// In en, this message translates to:
  /// **'Revenue Earned'**
  String get techDashRevenueEarned;

  /// No description provided for @techDashJobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Completed'**
  String get techDashJobsCompleted;

  /// No description provided for @techDashCommissionEarned.
  ///
  /// In en, this message translates to:
  /// **'Commission Earned'**
  String get techDashCommissionEarned;

  /// No description provided for @techDashTodayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get techDashTodayRevenue;

  /// No description provided for @techDashViewAssignedOrders.
  ///
  /// In en, this message translates to:
  /// **'VIEW ASSIGNED ORDERS'**
  String get techDashViewAssignedOrders;

  /// No description provided for @techShellAssignedOrders.
  ///
  /// In en, this message translates to:
  /// **'Assigned Orders'**
  String get techShellAssignedOrders;

  /// No description provided for @techShellSalaries.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get techShellSalaries;

  /// No description provided for @techShellTechnicianRole.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get techShellTechnicianRole;

  /// No description provided for @techVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String techVersionLabel(String version);

  /// No description provided for @techOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED ORDERS'**
  String get techOrdersTitle;

  /// No description provided for @techOrdersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search order ID, plate or customer'**
  String get techOrdersSearchHint;

  /// No description provided for @techOrdersShowingMatches.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} match(es) · {currency} {amount} commission'**
  String techOrdersShowingMatches(String count, String currency, String amount);

  /// No description provided for @techOrdersTotalCommission.
  ///
  /// In en, this message translates to:
  /// **'Total commission: {currency} {amount} · {count} job(s)'**
  String techOrdersTotalCommission(
    String count,
    String currency,
    String amount,
  );

  /// No description provided for @techOrdersNoSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No orders match your search'**
  String get techOrdersNoSearchMatch;

  /// No description provided for @techOrdersNoJobsInRange.
  ///
  /// In en, this message translates to:
  /// **'No invoiced jobs in this range'**
  String get techOrdersNoJobsInRange;

  /// No description provided for @techOrdersSearchHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Try order ID, plate number or customer name'**
  String get techOrdersSearchHintEmpty;

  /// No description provided for @techOrdersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Completed jobs appear here after the cashier generates the invoice'**
  String get techOrdersEmptyHint;

  /// No description provided for @techOrdersCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get techOrdersCommission;

  /// No description provided for @techOrdersCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get techOrdersCustomer;

  /// No description provided for @techOrdersVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get techOrdersVehicle;

  /// No description provided for @techOrdersDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get techOrdersDepartment;

  /// No description provided for @techOrdersGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get techOrdersGeneral;

  /// No description provided for @techOrdersOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Order value'**
  String get techOrdersOrderValue;

  /// No description provided for @techOrdersViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get techOrdersViewDetails;

  /// No description provided for @techOrderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'ORDER DETAILS'**
  String get techOrderDetailsTitle;

  /// No description provided for @techOrderDetailsPlateNo.
  ///
  /// In en, this message translates to:
  /// **'Plate No'**
  String get techOrderDetailsPlateNo;

  /// No description provided for @techOrderDetailsServiceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get techOrderDetailsServiceType;

  /// No description provided for @techOrderDetailsStandardService.
  ///
  /// In en, this message translates to:
  /// **'Standard Service'**
  String get techOrderDetailsStandardService;

  /// No description provided for @techOrderDetailsCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get techOrderDetailsCompletedAt;

  /// No description provided for @techOrderDetailsServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get techOrderDetailsServices;

  /// No description provided for @techOrderDetailsProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get techOrderDetailsProducts;

  /// No description provided for @techOrderDetailsYourCommission.
  ///
  /// In en, this message translates to:
  /// **'YOUR COMMISSION'**
  String get techOrderDetailsYourCommission;

  /// No description provided for @techBroadcastOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW BROADCAST JOB'**
  String get techBroadcastOverlayTitle;

  /// No description provided for @techBroadcastOverlayOnCall.
  ///
  /// In en, this message translates to:
  /// **'On-call broadcast'**
  String get techBroadcastOverlayOnCall;

  /// No description provided for @techBroadcastOverlayWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop broadcast'**
  String get techBroadcastOverlayWorkshop;

  /// No description provided for @techBroadcastOverlayDecline.
  ///
  /// In en, this message translates to:
  /// **'DECLINE'**
  String get techBroadcastOverlayDecline;

  /// No description provided for @techBroadcastOverlayAccept.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT JOB'**
  String get techBroadcastOverlayAccept;

  /// No description provided for @techBroadcastCouldNotDecline.
  ///
  /// In en, this message translates to:
  /// **'Could not decline'**
  String get techBroadcastCouldNotDecline;

  /// No description provided for @techBroadcastCouldNotAccept.
  ///
  /// In en, this message translates to:
  /// **'Could not accept job'**
  String get techBroadcastCouldNotAccept;

  /// No description provided for @techBroadcastListTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician broadcasts'**
  String get techBroadcastListTitle;

  /// No description provided for @techBroadcastNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active broadcasts'**
  String get techBroadcastNoActive;

  /// No description provided for @techBroadcastCountActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active · {window} per item'**
  String techBroadcastCountActive(String count, String window);

  /// No description provided for @techBroadcastWindow.
  ///
  /// In en, this message translates to:
  /// **'{m}:{s} window'**
  String techBroadcastWindow(String m, String s);

  /// No description provided for @techBroadcastLabel.
  ///
  /// In en, this message translates to:
  /// **'BROADCAST'**
  String get techBroadcastLabel;

  /// No description provided for @techBroadcastOnCall.
  ///
  /// In en, this message translates to:
  /// **'On call'**
  String get techBroadcastOnCall;

  /// No description provided for @techBroadcastWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get techBroadcastWorkshop;

  /// No description provided for @techBroadcastSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get techBroadcastSoon;

  /// No description provided for @techBroadcastClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get techBroadcastClosed;

  /// No description provided for @techBroadcastRemaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get techBroadcastRemaining;

  /// No description provided for @techBroadcastExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get techBroadcastExpired;

  /// No description provided for @techBroadcastReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get techBroadcastReject;

  /// No description provided for @techBroadcastAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get techBroadcastAccept;

  /// No description provided for @techCommSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search order ID or invoice no.'**
  String get techCommSearchHint;

  /// No description provided for @techCommNoSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No commissions match your search'**
  String get techCommNoSearchMatch;

  /// No description provided for @techCommNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No commissions found'**
  String get techCommNoneFound;

  /// No description provided for @techCommSearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try order ID or invoice number'**
  String get techCommSearchEmptyHint;

  /// No description provided for @techCommEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Completed jobs in this date range will appear here'**
  String get techCommEmptyHint;

  /// No description provided for @techCommTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMISSION'**
  String get techCommTitle;

  /// No description provided for @techCommCreditedWallet.
  ///
  /// In en, this message translates to:
  /// **'Credited to wallet'**
  String get techCommCreditedWallet;

  /// No description provided for @techSalariesTab.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get techSalariesTab;

  /// No description provided for @techAdvancesTab.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get techAdvancesTab;

  /// No description provided for @techSalariesNoneInRange.
  ///
  /// In en, this message translates to:
  /// **'No salary payments in this range'**
  String get techSalariesNoneInRange;

  /// No description provided for @techAdvancesNoneInRange.
  ///
  /// In en, this message translates to:
  /// **'No advance transactions in this range'**
  String get techAdvancesNoneInRange;

  /// No description provided for @techTryDifferentDateRange.
  ///
  /// In en, this message translates to:
  /// **'Try a different date range'**
  String get techTryDifferentDateRange;

  /// No description provided for @techBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance: {currency} {amount}'**
  String techBalanceLabel(String currency, String amount);

  /// No description provided for @techSelectedDateRange.
  ///
  /// In en, this message translates to:
  /// **'Selected date range'**
  String get techSelectedDateRange;

  /// No description provided for @techAdvanceLabel.
  ///
  /// In en, this message translates to:
  /// **'ADVANCE'**
  String get techAdvanceLabel;

  /// No description provided for @techDeductedLabel.
  ///
  /// In en, this message translates to:
  /// **'DEDUCTED'**
  String get techDeductedLabel;

  /// No description provided for @techTotalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total received: {currency} {amount}'**
  String techTotalReceived(String currency, String amount);

  /// No description provided for @techSalariesTitle.
  ///
  /// In en, this message translates to:
  /// **'SALARIES'**
  String get techSalariesTitle;

  /// No description provided for @techPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String techPaidOn(String date);

  /// No description provided for @techNetCash.
  ///
  /// In en, this message translates to:
  /// **'Net cash'**
  String get techNetCash;

  /// No description provided for @techBasicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic salary'**
  String get techBasicSalary;

  /// No description provided for @techAdvanceDeduction.
  ///
  /// In en, this message translates to:
  /// **'Advance deduction'**
  String get techAdvanceDeduction;

  /// No description provided for @techPenalties.
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get techPenalties;

  /// No description provided for @techGrossPayable.
  ///
  /// In en, this message translates to:
  /// **'Gross payable'**
  String get techGrossPayable;

  /// No description provided for @techTotalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Total deductions'**
  String get techTotalDeductions;

  /// No description provided for @techNetPaid.
  ///
  /// In en, this message translates to:
  /// **'Net paid'**
  String get techNetPaid;

  /// No description provided for @techPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from: {name}'**
  String techPaidFrom(String name);

  /// No description provided for @techMethod.
  ///
  /// In en, this message translates to:
  /// **'Method: {method}'**
  String techMethod(String method);

  /// No description provided for @techPenaltyNote.
  ///
  /// In en, this message translates to:
  /// **'Penalty note: {note}'**
  String techPenaltyNote(String note);

  /// No description provided for @techYouAckedSalary.
  ///
  /// In en, this message translates to:
  /// **'You {status} this salary'**
  String techYouAckedSalary(String status);

  /// No description provided for @techPerfCommissionTimeline.
  ///
  /// In en, this message translates to:
  /// **'COMMISSION TIMELINE'**
  String get techPerfCommissionTimeline;

  /// No description provided for @techPerfRecentJobs.
  ///
  /// In en, this message translates to:
  /// **'RECENT JOBS'**
  String get techPerfRecentJobs;

  /// No description provided for @techPerfDailyPerformance.
  ///
  /// In en, this message translates to:
  /// **'DAILY PERFORMANCE'**
  String get techPerfDailyPerformance;

  /// No description provided for @techPerfTotalJobs.
  ///
  /// In en, this message translates to:
  /// **'TOTAL JOBS'**
  String get techPerfTotalJobs;

  /// No description provided for @techPerfTotalCommission.
  ///
  /// In en, this message translates to:
  /// **'TOTAL COMMISSION'**
  String get techPerfTotalCommission;

  /// No description provided for @techPerfDailyCommission.
  ///
  /// In en, this message translates to:
  /// **'Daily commission'**
  String get techPerfDailyCommission;

  /// No description provided for @techPerfNoCommissionMonth.
  ///
  /// In en, this message translates to:
  /// **'No commission data for this month'**
  String get techPerfNoCommissionMonth;

  /// No description provided for @techPerfNoRecentJobs.
  ///
  /// In en, this message translates to:
  /// **'No recent jobs found'**
  String get techPerfNoRecentJobs;

  /// No description provided for @techPerfSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get techPerfSeeAll;

  /// No description provided for @techRecentJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'RECENT JOBS'**
  String get techRecentJobsTitle;

  /// No description provided for @techNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get techNotificationsTitle;

  /// No description provided for @techNotificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No New Alerts'**
  String get techNotificationsEmptyTitle;

  /// No description provided for @techNotificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up!'**
  String get techNotificationsEmptyBody;

  /// No description provided for @techProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'MY PROFILE'**
  String get techProfileTitle;

  /// No description provided for @techProfileBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get techProfileBasicInfo;

  /// No description provided for @techProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get techProfileEmail;

  /// No description provided for @techProfileMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get techProfileMobile;

  /// No description provided for @techProfileDutyDetails.
  ///
  /// In en, this message translates to:
  /// **'Duty Details'**
  String get techProfileDutyDetails;

  /// No description provided for @techProfileType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get techProfileType;

  /// No description provided for @techProfileDutyMode.
  ///
  /// In en, this message translates to:
  /// **'Duty Mode'**
  String get techProfileDutyMode;

  /// No description provided for @techProfileCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get techProfileCommission;

  /// No description provided for @techProfileAssociations.
  ///
  /// In en, this message translates to:
  /// **'Associations'**
  String get techProfileAssociations;

  /// No description provided for @techProfileWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get techProfileWorkshop;

  /// No description provided for @techProfileBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get techProfileBranch;

  /// No description provided for @techProfileDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get techProfileDepartments;

  /// No description provided for @techProfileNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get techProfileNA;

  /// No description provided for @techProfileTechnicianName.
  ///
  /// In en, this message translates to:
  /// **'Technician Name'**
  String get techProfileTechnicianName;

  /// No description provided for @techProfileRoleId.
  ///
  /// In en, this message translates to:
  /// **'Technician • ID: {id}'**
  String techProfileRoleId(String id);

  /// No description provided for @techProfileStandard.
  ///
  /// In en, this message translates to:
  /// **'STANDARD'**
  String get techProfileStandard;

  /// No description provided for @techProfileFooter.
  ///
  /// In en, this message translates to:
  /// **'Technician Portal • Version {version}'**
  String techProfileFooter(String version);

  /// No description provided for @techChatTitle.
  ///
  /// In en, this message translates to:
  /// **'CHAT'**
  String get techChatTitle;

  /// No description provided for @techChatMyChats.
  ///
  /// In en, this message translates to:
  /// **'My Chats'**
  String get techChatMyChats;

  /// No description provided for @techChatMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get techChatMembers;

  /// No description provided for @techChatSearchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get techChatSearchChats;

  /// No description provided for @techChatSearchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members'**
  String get techChatSearchMembers;

  /// No description provided for @techChatNoChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get techChatNoChatsYet;

  /// No description provided for @techChatNoChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation from Members,\nthen it will appear here'**
  String get techChatNoChatsHint;

  /// No description provided for @techChatNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get techChatNoMembers;

  /// No description provided for @techChatTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get techChatTryDifferentSearch;

  /// No description provided for @techChatStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get techChatStartConversation;

  /// No description provided for @techChatGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get techChatGroup;

  /// No description provided for @techChatWorkshopTeam.
  ///
  /// In en, this message translates to:
  /// **'Workshop team'**
  String get techChatWorkshopTeam;

  /// No description provided for @techChatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get techChatTypeMessage;

  /// No description provided for @techChatNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get techChatNewGroup;

  /// No description provided for @techChatGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get techChatGroupName;

  /// No description provided for @techChatSearchMembersToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search members to add'**
  String get techChatSearchMembersToAdd;

  /// No description provided for @techChatCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get techChatCreating;

  /// No description provided for @techChatCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get techChatCreateGroup;

  /// No description provided for @techChatGroupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get techChatGroupNameRequired;

  /// No description provided for @techChatSelectMember.
  ///
  /// In en, this message translates to:
  /// **'Select at least one member'**
  String get techChatSelectMember;

  /// No description provided for @techChatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get techChatTyping;

  /// No description provided for @techMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'MONTH'**
  String get techMonthTitle;

  /// No description provided for @techMonthApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get techMonthApply;

  /// No description provided for @techMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get techMonthJan;

  /// No description provided for @techMonthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get techMonthFeb;

  /// No description provided for @techMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get techMonthMar;

  /// No description provided for @techMonthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get techMonthApr;

  /// No description provided for @techMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get techMonthMay;

  /// No description provided for @techMonthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get techMonthJun;

  /// No description provided for @techMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get techMonthJul;

  /// No description provided for @techMonthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get techMonthAug;

  /// No description provided for @techMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get techMonthSep;

  /// No description provided for @techMonthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get techMonthOct;

  /// No description provided for @techMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get techMonthNov;

  /// No description provided for @techMonthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get techMonthDec;

  /// No description provided for @techOfflineAskCashier.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Ask the cashier to mark you online.'**
  String get techOfflineAskCashier;

  /// No description provided for @techNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get techNotSignedIn;

  /// No description provided for @techCouldNotSubmitResponse.
  ///
  /// In en, this message translates to:
  /// **'Could not submit response'**
  String get techCouldNotSubmitResponse;

  /// No description provided for @techJobAccepted.
  ///
  /// In en, this message translates to:
  /// **'Job accepted'**
  String get techJobAccepted;

  /// No description provided for @techBroadcastDeclined.
  ///
  /// In en, this message translates to:
  /// **'Broadcast declined'**
  String get techBroadcastDeclined;

  /// No description provided for @techNotifCommissionCredited.
  ///
  /// In en, this message translates to:
  /// **'Commission Credited'**
  String get techNotifCommissionCredited;

  /// No description provided for @techNotifCommissionCreditedBody.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount} added to your daily earnings for {orderId}'**
  String techNotifCommissionCreditedBody(
    String currency,
    String amount,
    String orderId,
  );

  /// No description provided for @techAckAccepted.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get techAckAccepted;

  /// No description provided for @techAckRejected.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get techAckRejected;

  /// No description provided for @techMoneyAmount.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount}'**
  String techMoneyAmount(String currency, String amount);

  /// No description provided for @lockerNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get lockerNavDashboard;

  /// No description provided for @lockerNavPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get lockerNavPendingRequests;

  /// No description provided for @lockerNavRecordCollection.
  ///
  /// In en, this message translates to:
  /// **'Record Collection'**
  String get lockerNavRecordCollection;

  /// No description provided for @lockerNavApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get lockerNavApprovals;

  /// No description provided for @lockerNavDepositToBank.
  ///
  /// In en, this message translates to:
  /// **'Deposit to Bank'**
  String get lockerNavDepositToBank;

  /// No description provided for @lockerNavIssuePettyCash.
  ///
  /// In en, this message translates to:
  /// **'Issue Petty Cash'**
  String get lockerNavIssuePettyCash;

  /// No description provided for @lockerNavPettyCashIssueLog.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash Issue Log'**
  String get lockerNavPettyCashIssueLog;

  /// No description provided for @lockerNavExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get lockerNavExpenses;

  /// No description provided for @lockerNavCollectionsHistory.
  ///
  /// In en, this message translates to:
  /// **'Collections History'**
  String get lockerNavCollectionsHistory;

  /// No description provided for @lockerNavCollectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Collection History'**
  String get lockerNavCollectionHistory;

  /// No description provided for @lockerNavDifferencesReport.
  ///
  /// In en, this message translates to:
  /// **'Differences Report'**
  String get lockerNavDifferencesReport;

  /// No description provided for @lockerNavAssignedRequests.
  ///
  /// In en, this message translates to:
  /// **'Assigned Requests'**
  String get lockerNavAssignedRequests;

  /// No description provided for @lockerNavDifferencesHistory.
  ///
  /// In en, this message translates to:
  /// **'Differences History'**
  String get lockerNavDifferencesHistory;

  /// No description provided for @lockerFooterPortal.
  ///
  /// In en, this message translates to:
  /// **'Locker Portal'**
  String get lockerFooterPortal;

  /// No description provided for @lockerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} — coming soon'**
  String lockerComingSoon(String feature);

  /// No description provided for @lockerQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get lockerQuickActions;

  /// No description provided for @lockerRecentCollections.
  ///
  /// In en, this message translates to:
  /// **'Recent Collections'**
  String get lockerRecentCollections;

  /// No description provided for @lockerViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get lockerViewAll;

  /// No description provided for @lockerNoRecentCollections.
  ///
  /// In en, this message translates to:
  /// **'No recent collections'**
  String get lockerNoRecentCollections;

  /// No description provided for @lockerLabelRequested.
  ///
  /// In en, this message translates to:
  /// **'REQUESTED'**
  String get lockerLabelRequested;

  /// No description provided for @lockerLabelExpected.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED'**
  String get lockerLabelExpected;

  /// No description provided for @lockerLabelReceived.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED'**
  String get lockerLabelReceived;

  /// No description provided for @lockerLabelDifference.
  ///
  /// In en, this message translates to:
  /// **'DIFFERENCE'**
  String get lockerLabelDifference;

  /// No description provided for @lockerLabelRequest.
  ///
  /// In en, this message translates to:
  /// **'REQUEST'**
  String get lockerLabelRequest;

  /// No description provided for @lockerSelectRequest.
  ///
  /// In en, this message translates to:
  /// **'Select request…'**
  String get lockerSelectRequest;

  /// No description provided for @lockerLabelBranch.
  ///
  /// In en, this message translates to:
  /// **'BRANCH'**
  String get lockerLabelBranch;

  /// No description provided for @lockerLabelCashier.
  ///
  /// In en, this message translates to:
  /// **'CASHIER'**
  String get lockerLabelCashier;

  /// No description provided for @lockerLabelOfficer.
  ///
  /// In en, this message translates to:
  /// **'OFFICER'**
  String get lockerLabelOfficer;

  /// No description provided for @lockerLabelCounterClosing.
  ///
  /// In en, this message translates to:
  /// **'COUNTER CLOSING'**
  String get lockerLabelCounterClosing;

  /// No description provided for @lockerCashHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the cash amount actually received from the cashier.'**
  String get lockerCashHelper;

  /// No description provided for @lockerLabelCash.
  ///
  /// In en, this message translates to:
  /// **'CASH'**
  String get lockerLabelCash;

  /// No description provided for @lockerPayBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get lockerPayBank;

  /// No description provided for @lockerPayTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby'**
  String get lockerPayTabby;

  /// No description provided for @lockerPayTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara'**
  String get lockerPayTamara;

  /// No description provided for @lockerPayCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get lockerPayCorporate;

  /// No description provided for @lockerTapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get lockerTapToAddPhoto;

  /// No description provided for @lockerCameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or Gallery'**
  String get lockerCameraOrGallery;

  /// No description provided for @lockerRetakeChange.
  ///
  /// In en, this message translates to:
  /// **'Retake / Change'**
  String get lockerRetakeChange;

  /// No description provided for @lockerAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'ADD PHOTO'**
  String get lockerAddPhoto;

  /// No description provided for @lockerTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get lockerTakePhoto;

  /// No description provided for @lockerOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Open camera'**
  String get lockerOpenCamera;

  /// No description provided for @lockerChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get lockerChooseGallery;

  /// No description provided for @lockerPickExistingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing photo'**
  String get lockerPickExistingPhoto;

  /// No description provided for @lockerTabVariance.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get lockerTabVariance;

  /// No description provided for @lockerTabPettyCashFunds.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash Funds'**
  String get lockerTabPettyCashFunds;

  /// No description provided for @lockerNoPendingFundRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending fund requests'**
  String get lockerNoPendingFundRequests;

  /// No description provided for @lockerFundApproved.
  ///
  /// In en, this message translates to:
  /// **'Fund request approved'**
  String get lockerFundApproved;

  /// No description provided for @lockerFundRejected.
  ///
  /// In en, this message translates to:
  /// **'Fund request rejected'**
  String get lockerFundRejected;

  /// No description provided for @lockerRejectFundRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Fund Request'**
  String get lockerRejectFundRequest;

  /// No description provided for @lockerProvideRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection.'**
  String get lockerProvideRejectionReason;

  /// No description provided for @lockerRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get lockerRejectionReason;

  /// No description provided for @lockerReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required'**
  String get lockerReasonRequired;

  /// No description provided for @lockerFallbackCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get lockerFallbackCashier;

  /// No description provided for @lockerTitleCollectionsHistory.
  ///
  /// In en, this message translates to:
  /// **'Collections History'**
  String get lockerTitleCollectionsHistory;

  /// No description provided for @lockerKpiTotalExpected.
  ///
  /// In en, this message translates to:
  /// **'TOTAL EXPECTED'**
  String get lockerKpiTotalExpected;

  /// No description provided for @lockerKpiTotalReceived.
  ///
  /// In en, this message translates to:
  /// **'TOTAL RECEIVED'**
  String get lockerKpiTotalReceived;

  /// No description provided for @lockerKpiNetDifference.
  ///
  /// In en, this message translates to:
  /// **'NET DIFFERENCE'**
  String get lockerKpiNetDifference;

  /// No description provided for @lockerClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get lockerClearAll;

  /// No description provided for @lockerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get lockerFilterAll;

  /// No description provided for @lockerSortExpectedAmount.
  ///
  /// In en, this message translates to:
  /// **'Expected Amount'**
  String get lockerSortExpectedAmount;

  /// No description provided for @lockerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get lockerStatusPending;

  /// No description provided for @lockerTitleMyPending.
  ///
  /// In en, this message translates to:
  /// **'My Pending Requests'**
  String get lockerTitleMyPending;

  /// No description provided for @lockerTitleMyCollections.
  ///
  /// In en, this message translates to:
  /// **'My Collections'**
  String get lockerTitleMyCollections;

  /// No description provided for @lockerTitleAllCollections.
  ///
  /// In en, this message translates to:
  /// **'All Collections'**
  String get lockerTitleAllCollections;

  /// No description provided for @lockerTitleAssignOfficers.
  ///
  /// In en, this message translates to:
  /// **'Assign Officers'**
  String get lockerTitleAssignOfficers;

  /// No description provided for @lockerTitlePendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get lockerTitlePendingRequests;

  /// No description provided for @lockerTitleRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get lockerTitleRequests;

  /// No description provided for @lockerMinSar.
  ///
  /// In en, this message translates to:
  /// **'MIN ({currency})'**
  String lockerMinSar(String currency);

  /// No description provided for @lockerMaxSar.
  ///
  /// In en, this message translates to:
  /// **'MAX ({currency})'**
  String lockerMaxSar(String currency);

  /// No description provided for @lockerAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get lockerAny;

  /// No description provided for @lockerTotalExpectedFiltered.
  ///
  /// In en, this message translates to:
  /// **'TOTAL EXPECTED (FILTERED)'**
  String get lockerTotalExpectedFiltered;

  /// No description provided for @lockerApproveAndForward.
  ///
  /// In en, this message translates to:
  /// **'Approve & forward'**
  String get lockerApproveAndForward;

  /// No description provided for @lockerApproveAndRecord.
  ///
  /// In en, this message translates to:
  /// **'Approve & record'**
  String get lockerApproveAndRecord;

  /// No description provided for @lockerFilterPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get lockerFilterPending;

  /// No description provided for @lockerFilterAssigned.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED'**
  String get lockerFilterAssigned;

  /// No description provided for @lockerFilterCollected.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get lockerFilterCollected;

  /// No description provided for @lockerFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get lockerFilterCompleted;

  /// No description provided for @lockerTodaysCollected.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collected'**
  String get lockerTodaysCollected;

  /// No description provided for @lockerOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String lockerOverdueCount(String count);

  /// No description provided for @lockerCollectionsToday.
  ///
  /// In en, this message translates to:
  /// **'collections today'**
  String get lockerCollectionsToday;

  /// No description provided for @lockerThisMonthApproved.
  ///
  /// In en, this message translates to:
  /// **'This month (approved)'**
  String get lockerThisMonthApproved;

  /// No description provided for @lockerQaPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get lockerQaPendingRequests;

  /// No description provided for @lockerQaPendingRequestsSub.
  ///
  /// In en, this message translates to:
  /// **'Review and assign cashiers\' closing requests'**
  String get lockerQaPendingRequestsSub;

  /// No description provided for @lockerQaRecordCollection.
  ///
  /// In en, this message translates to:
  /// **'Record Collection'**
  String get lockerQaRecordCollection;

  /// No description provided for @lockerQaRecordCollectionSub.
  ///
  /// In en, this message translates to:
  /// **'Collect cash and record amounts'**
  String get lockerQaRecordCollectionSub;

  /// No description provided for @lockerQaApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get lockerQaApprovals;

  /// No description provided for @lockerQaApprovalsSub.
  ///
  /// In en, this message translates to:
  /// **'Approve variance and fund requests'**
  String get lockerQaApprovalsSub;

  /// No description provided for @lockerQaCollectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Collection History'**
  String get lockerQaCollectionHistory;

  /// No description provided for @lockerQaCollectionHistorySub.
  ///
  /// In en, this message translates to:
  /// **'View past collections'**
  String get lockerQaCollectionHistorySub;

  /// No description provided for @lockerQaDepositBank.
  ///
  /// In en, this message translates to:
  /// **'Deposit to Bank'**
  String get lockerQaDepositBank;

  /// No description provided for @lockerQaDepositBankSub.
  ///
  /// In en, this message translates to:
  /// **'Transfer vault cash to bank'**
  String get lockerQaDepositBankSub;

  /// No description provided for @lockerQaIssuePettyCash.
  ///
  /// In en, this message translates to:
  /// **'Issue Petty Cash'**
  String get lockerQaIssuePettyCash;

  /// No description provided for @lockerQaIssuePettyCashSub.
  ///
  /// In en, this message translates to:
  /// **'Issue float to cashiers'**
  String get lockerQaIssuePettyCashSub;

  /// No description provided for @lockerQaExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get lockerQaExpenses;

  /// No description provided for @lockerQaExpensesSub.
  ///
  /// In en, this message translates to:
  /// **'Record locker expenses'**
  String get lockerQaExpensesSub;

  /// No description provided for @lockerQaDifferencesReport.
  ///
  /// In en, this message translates to:
  /// **'Differences Report'**
  String get lockerQaDifferencesReport;

  /// No description provided for @lockerQaDifferencesReportSub.
  ///
  /// In en, this message translates to:
  /// **'Shorts and overs overview'**
  String get lockerQaDifferencesReportSub;

  /// No description provided for @lockerQaAssignedRequests.
  ///
  /// In en, this message translates to:
  /// **'Assigned Requests'**
  String get lockerQaAssignedRequests;

  /// No description provided for @lockerQaAssignedRequestsSub.
  ///
  /// In en, this message translates to:
  /// **'Requests assigned to you'**
  String get lockerQaAssignedRequestsSub;

  /// No description provided for @lockerQaDifferencesHistory.
  ///
  /// In en, this message translates to:
  /// **'Differences History'**
  String get lockerQaDifferencesHistory;

  /// No description provided for @lockerQaDifferencesHistorySub.
  ///
  /// In en, this message translates to:
  /// **'Your variance history'**
  String get lockerQaDifferencesHistorySub;

  /// No description provided for @lockerPettyIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Petty Cash'**
  String get lockerPettyIssueTitle;

  /// No description provided for @lockerVaultBalance.
  ///
  /// In en, this message translates to:
  /// **'Locker Vault Balance'**
  String get lockerVaultBalance;

  /// No description provided for @lockerIssueFloat.
  ///
  /// In en, this message translates to:
  /// **'Issue Float'**
  String get lockerIssueFloat;

  /// No description provided for @lockerFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get lockerFailedToLoad;

  /// No description provided for @lockerAnUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get lockerAnUnexpectedError;

  /// No description provided for @lockerNoFloatsYet.
  ///
  /// In en, this message translates to:
  /// **'No floats issued yet'**
  String get lockerNoFloatsYet;

  /// No description provided for @lockerNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get lockerNoDescription;

  /// No description provided for @lockerAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount ({currency})'**
  String lockerAmountLabel(String currency);

  /// No description provided for @lockerIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get lockerIssueDate;

  /// No description provided for @lockerReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get lockerReferenceOptional;

  /// No description provided for @lockerWeeklyFloatHint.
  ///
  /// In en, this message translates to:
  /// **'Weekly float / top-up note'**
  String get lockerWeeklyFloatHint;

  /// No description provided for @lockerSelectCashier.
  ///
  /// In en, this message translates to:
  /// **'Select cashier...'**
  String get lockerSelectCashier;

  /// No description provided for @lockerRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get lockerRequired;

  /// No description provided for @lockerInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get lockerInvalidAmount;

  /// No description provided for @lockerExceedsVault.
  ///
  /// In en, this message translates to:
  /// **'Exceeds vault balance'**
  String get lockerExceedsVault;

  /// No description provided for @lockerPleaseSelectCashier.
  ///
  /// In en, this message translates to:
  /// **'Please select a cashier'**
  String get lockerPleaseSelectCashier;

  /// No description provided for @lockerIssueAndPostGl.
  ///
  /// In en, this message translates to:
  /// **'Issue & Post GL'**
  String get lockerIssueAndPostGl;

  /// No description provided for @lockerRecentFloatsIssued.
  ///
  /// In en, this message translates to:
  /// **'Recent petty cash floats issued'**
  String get lockerRecentFloatsIssued;

  /// No description provided for @lockerFloatIssuedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Float issued successfully'**
  String get lockerFloatIssuedSuccess;

  /// No description provided for @lockerPettyCashFloatDefault.
  ///
  /// In en, this message translates to:
  /// **'Petty cash float'**
  String get lockerPettyCashFloatDefault;

  /// No description provided for @lockerPettyIssueLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash Issue Log'**
  String get lockerPettyIssueLogTitle;

  /// No description provided for @lockerKpiLockerVault.
  ///
  /// In en, this message translates to:
  /// **'LOCKER VAULT'**
  String get lockerKpiLockerVault;

  /// No description provided for @lockerKpiTotalIssued.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ISSUED'**
  String get lockerKpiTotalIssued;

  /// No description provided for @lockerKpiIssueCount.
  ///
  /// In en, this message translates to:
  /// **'ISSUE COUNT'**
  String get lockerKpiIssueCount;

  /// No description provided for @lockerKpiAverageIssue.
  ///
  /// In en, this message translates to:
  /// **'AVERAGE ISSUE'**
  String get lockerKpiAverageIssue;

  /// No description provided for @lockerNoPettyIssues.
  ///
  /// In en, this message translates to:
  /// **'No petty cash issues in this range'**
  String get lockerNoPettyIssues;

  /// No description provided for @lockerAllBranches.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get lockerAllBranches;

  /// No description provided for @lockerAllCashiers.
  ///
  /// In en, this message translates to:
  /// **'All cashiers'**
  String get lockerAllCashiers;

  /// No description provided for @lockerIssuedFloats.
  ///
  /// In en, this message translates to:
  /// **'ISSUED FLOATS'**
  String get lockerIssuedFloats;

  /// No description provided for @lockerRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s)'**
  String lockerRecordCount(String count);

  /// No description provided for @lockerDateLabel.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get lockerDateLabel;

  /// No description provided for @lockerReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE'**
  String get lockerReferenceLabel;

  /// No description provided for @lockerJeLabel.
  ///
  /// In en, this message translates to:
  /// **'JE'**
  String get lockerJeLabel;

  /// No description provided for @lockerPettyCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get lockerPettyCashTitle;

  /// No description provided for @lockerNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get lockerNewRequest;

  /// No description provided for @lockerNoPettyRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No petty cash requests yet.'**
  String get lockerNoPettyRequestsYet;

  /// No description provided for @lockerPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get lockerPurpose;

  /// No description provided for @lockerDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get lockerDate;

  /// No description provided for @lockerSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get lockerSubmitRequest;

  /// No description provided for @lockerEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get lockerEnterValidAmount;

  /// No description provided for @lockerDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'DEPOSIT TO BANK'**
  String get lockerDepositTitle;

  /// No description provided for @lockerSlowConnection.
  ///
  /// In en, this message translates to:
  /// **'Slow connection — still working…'**
  String get lockerSlowConnection;

  /// No description provided for @lockerNoBankRegisters.
  ///
  /// In en, this message translates to:
  /// **'No bank registers configured'**
  String get lockerNoBankRegisters;

  /// No description provided for @lockerDepositAndPostGl.
  ///
  /// In en, this message translates to:
  /// **'Deposit & Post GL'**
  String get lockerDepositAndPostGl;

  /// No description provided for @lockerRecentBankDeposits.
  ///
  /// In en, this message translates to:
  /// **'Recent locker → bank deposits'**
  String get lockerRecentBankDeposits;

  /// No description provided for @lockerNoDepositsYet.
  ///
  /// In en, this message translates to:
  /// **'No deposits yet'**
  String get lockerNoDepositsYet;

  /// No description provided for @lockerBankDeposit.
  ///
  /// In en, this message translates to:
  /// **'Bank deposit'**
  String get lockerBankDeposit;

  /// No description provided for @lockerFailedToLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load'**
  String get lockerFailedToLoadTitle;

  /// No description provided for @lockerCashInTransit.
  ///
  /// In en, this message translates to:
  /// **'Cash in Transit — Locker'**
  String get lockerCashInTransit;

  /// No description provided for @lockerAmountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get lockerAmountMustBePositive;

  /// No description provided for @lockerAmountExceedsVault.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds vault balance'**
  String get lockerAmountExceedsVault;

  /// No description provided for @lockerDepositPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deposit posted successfully. GL entry recorded (Journal #{journalId}).'**
  String lockerDepositPostedSuccess(String journalId);

  /// No description provided for @lockerExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get lockerExpensesTitle;

  /// No description provided for @lockerExpensesSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Expenses submitted for approval'**
  String get lockerExpensesSubmitted;

  /// No description provided for @lockerViewProof.
  ///
  /// In en, this message translates to:
  /// **'View proof'**
  String get lockerViewProof;

  /// No description provided for @lockerAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get lockerAddLine;

  /// No description provided for @lockerSubmitLines.
  ///
  /// In en, this message translates to:
  /// **'Submit {count} line(s)'**
  String lockerSubmitLines(String count);

  /// No description provided for @lockerSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get lockerSubmitting;

  /// No description provided for @lockerVaultBalanceDialog.
  ///
  /// In en, this message translates to:
  /// **'Vault balance'**
  String get lockerVaultBalanceDialog;

  /// No description provided for @lockerExceedVaultBody.
  ///
  /// In en, this message translates to:
  /// **'Total exceeds vault balance. Submit anyway?'**
  String get lockerExceedVaultBody;

  /// No description provided for @lockerSubmitAnyway.
  ///
  /// In en, this message translates to:
  /// **'Submit anyway'**
  String get lockerSubmitAnyway;

  /// No description provided for @lockerLineSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: select a branch'**
  String lockerLineSelectBranch(String n);

  /// No description provided for @lockerLineSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: select a category'**
  String lockerLineSelectCategory(String n);

  /// No description provided for @lockerLineEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: enter a valid amount'**
  String lockerLineEnterAmount(String n);

  /// No description provided for @lockerDifferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Differences Report'**
  String get lockerDifferencesTitle;

  /// No description provided for @lockerChipAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get lockerChipAll;

  /// No description provided for @lockerChipShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get lockerChipShort;

  /// No description provided for @lockerChipOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get lockerChipOver;

  /// No description provided for @lockerChipPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get lockerChipPending;

  /// No description provided for @lockerPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get lockerPendingApproval;

  /// No description provided for @lockerNoDifferences.
  ///
  /// In en, this message translates to:
  /// **'No differences found'**
  String get lockerNoDifferences;

  /// No description provided for @lockerLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get lockerLoginFailed;

  /// No description provided for @lockerLoginNoAccess.
  ///
  /// In en, this message translates to:
  /// **'This account does not have locker portal access. Ask your workshop admin to create a locker user.'**
  String get lockerLoginNoAccess;

  /// No description provided for @lockerLoginUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get lockerLoginUnexpected;

  /// No description provided for @lockerNoRequestSelected.
  ///
  /// In en, this message translates to:
  /// **'No request selected.'**
  String get lockerNoRequestSelected;

  /// No description provided for @lockerFailedLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Failed to load requests.'**
  String get lockerFailedLoadRequests;

  /// No description provided for @lockerFailedLoadRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load request details.'**
  String get lockerFailedLoadRequestDetails;

  /// No description provided for @lockerCouldNotLoadOfficers.
  ///
  /// In en, this message translates to:
  /// **'Could not load officers.'**
  String get lockerCouldNotLoadOfficers;

  /// No description provided for @lockerAssignmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Assignment failed.'**
  String get lockerAssignmentFailed;

  /// No description provided for @lockerNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated.'**
  String get lockerNotAuthenticated;

  /// No description provided for @lockerOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed.'**
  String get lockerOperationFailed;

  /// No description provided for @lockerBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad request: {detail}'**
  String lockerBadRequest(String detail);

  /// No description provided for @lockerFailedLoadSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to load session.'**
  String get lockerFailedLoadSession;

  /// No description provided for @lockerFailedLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data.'**
  String get lockerFailedLoadData;

  /// No description provided for @lockerFailedIssueFloat.
  ///
  /// In en, this message translates to:
  /// **'Failed to issue float.'**
  String get lockerFailedIssueFloat;

  /// No description provided for @lockerAttachPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Attach a photo as proof of collection (optional).'**
  String get lockerAttachPhotoHint;

  /// No description provided for @lockerCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get lockerCashCollected;

  /// No description provided for @lockerOverMinusShort.
  ///
  /// In en, this message translates to:
  /// **'Over − Short'**
  String get lockerOverMinusShort;

  /// No description provided for @lockerNetShort.
  ///
  /// In en, this message translates to:
  /// **'Net Short'**
  String get lockerNetShort;

  /// No description provided for @lockerNetOver.
  ///
  /// In en, this message translates to:
  /// **'Net Over'**
  String get lockerNetOver;

  /// No description provided for @lockerBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get lockerBalanced;

  /// No description provided for @lockerCashShortage.
  ///
  /// In en, this message translates to:
  /// **'Cash shortage'**
  String get lockerCashShortage;

  /// No description provided for @lockerCashSurplus.
  ///
  /// In en, this message translates to:
  /// **'Cash surplus'**
  String get lockerCashSurplus;

  /// No description provided for @lockerVarianceRecords.
  ///
  /// In en, this message translates to:
  /// **'VARIANCE RECORDS'**
  String get lockerVarianceRecords;

  /// No description provided for @lockerRecordsOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total} records'**
  String lockerRecordsOfTotal(String visible, String total);

  /// No description provided for @lockerRequestsInRange.
  ///
  /// In en, this message translates to:
  /// **'{count} request(s) in range'**
  String lockerRequestsInRange(String count);

  /// No description provided for @lockerBankRegister.
  ///
  /// In en, this message translates to:
  /// **'Bank Register'**
  String get lockerBankRegister;

  /// No description provided for @lockerSelectBankRegister.
  ///
  /// In en, this message translates to:
  /// **'Select bank register…'**
  String get lockerSelectBankRegister;

  /// No description provided for @lockerBankSlipHint.
  ///
  /// In en, this message translates to:
  /// **'Bank slip / transfer reference (optional)'**
  String get lockerBankSlipHint;

  /// No description provided for @lockerKpiBankRegisters.
  ///
  /// In en, this message translates to:
  /// **'Bank Registers'**
  String get lockerKpiBankRegisters;

  /// No description provided for @lockerKpiRecentDeposits.
  ///
  /// In en, this message translates to:
  /// **'Recent Deposits'**
  String get lockerKpiRecentDeposits;

  /// No description provided for @lockerTabRecordExpenses.
  ///
  /// In en, this message translates to:
  /// **'Record expenses'**
  String get lockerTabRecordExpenses;

  /// No description provided for @lockerTabExpensesLog.
  ///
  /// In en, this message translates to:
  /// **'Expenses log'**
  String get lockerTabExpensesLog;

  /// No description provided for @lockerPostedExpenses.
  ///
  /// In en, this message translates to:
  /// **'POSTED EXPENSES'**
  String get lockerPostedExpenses;

  /// No description provided for @lockerPostedCount.
  ///
  /// In en, this message translates to:
  /// **'POSTED COUNT'**
  String get lockerPostedCount;

  /// No description provided for @lockerExpenseLines.
  ///
  /// In en, this message translates to:
  /// **'Expense lines'**
  String get lockerExpenseLines;

  /// No description provided for @lockerLineN.
  ///
  /// In en, this message translates to:
  /// **'Line {n}'**
  String lockerLineN(String n);

  /// No description provided for @lockerCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get lockerCategoryLabel;

  /// No description provided for @lockerProofUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'PROOF URL (OPTIONAL)'**
  String get lockerProofUrlOptional;

  /// No description provided for @lockerStatusPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get lockerStatusPosted;

  /// No description provided for @lockerSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get lockerSelectCategory;

  /// No description provided for @lockerSelectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get lockerSelectedPeriod;

  /// No description provided for @lockerAcrossBranches.
  ///
  /// In en, this message translates to:
  /// **'Across branches'**
  String get lockerAcrossBranches;

  /// No description provided for @lockerPerIssue.
  ///
  /// In en, this message translates to:
  /// **'Per issue'**
  String get lockerPerIssue;

  /// No description provided for @lockerRequestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'REQUEST DETAILS'**
  String get lockerRequestDetailsTitle;

  /// No description provided for @lockerSampleOfficeSupplies.
  ///
  /// In en, this message translates to:
  /// **'Office supplies'**
  String get lockerSampleOfficeSupplies;

  /// No description provided for @lockerSampleBranchMainRiyadh.
  ///
  /// In en, this message translates to:
  /// **'Main — Riyadh'**
  String get lockerSampleBranchMainRiyadh;

  /// No description provided for @lockerFallbackUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get lockerFallbackUser;

  /// No description provided for @lockerStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get lockerStatusUnknown;

  /// No description provided for @lockerPosStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get lockerPosStatusOpen;

  /// No description provided for @lockerPosStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get lockerPosStatusClosed;

  /// No description provided for @lockerTryAgainGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get lockerTryAgainGeneric;

  /// No description provided for @ownerDashboardTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get ownerDashboardTotalSales;

  /// No description provided for @ownerDashboardTotalSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Selected period · all branches'**
  String get ownerDashboardTotalSalesSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
