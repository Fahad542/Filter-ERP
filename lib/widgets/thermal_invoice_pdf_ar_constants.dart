// Bilingual labels for thermal invoice PDF matching common KSA bilingual receipts.

abstract final class ThermalInvoicePdfLabels {

  // Customer detail labels
  static const customerNameAr     = 'الاسم';
  static const customerMobileAr   = 'الجوال';
  static const customerTaxIdAr    = 'الرقم الضريبي للعميل';
  static const customerTaxIdEn    = 'Customer Tax ID';
  static const customerTypeAr     = 'نوع العميل';
  static const customerTypeEn     = 'Customer Type';
  static const corporateCompanyAr = 'الشركة';
  static const corporateCompanyEn = 'Company';
  static const vehicleAr          = 'المركبة';
  static const vehicleMakeAr      = 'الماركة';
  static const vehicleModelAr     = 'الموديل';
  static const vehicleYearAr      = 'السنة';
  static const vehiclePlateAr     = 'اللوحة';
  static const vehicleVinAr       = 'رقم الهيكل';
  static const vehicleOdometerAr  = 'عداد المسافة';

  // Meta block labels
  static const branchAr           = 'الفرع';
  static const vatNoAr            = 'الرقم الضريبي';
  static const addressAr          = 'العنوان';
  static const invoiceNoAr        = 'رقم الفاتورة';
  static const dateAr             = 'التاريخ';
  static const cashierAr          = 'الكاشير';

  /// Thermal PDF header meta — English line only (values may still be Arabic/Latin).
  static const vatNumberMetaEn   = 'VAT Number';
  static const addressMetaEn     = 'Address';
  static const invoiceNoMetaEn   = 'Invoice No';

  // Section headers
  static const customerDetailsSectionAr   = 'بيانات العميل';
  static const customerDetailsSectionEn   = 'CUSTOMER DETAILS';
  static const maintenanceSectionAr       = 'قائمة الصيانة';
  static const maintenanceSectionEn       = 'MAINTENANCE CHECKLIST';
  static const thankYouAr                 = 'شكراً لزيارتكم';
  static const thankYouEn                 = 'Thank you';

  static const documentTitleAr = 'فاتورة ضريبية مبسطة';
  static const documentTitleEn = 'Simplified Tax Invoice';
  /// Shown directly under the logo (Arabic subtitle line).
  static const documentSubtitleAr = 'لخدمات السيارات';
  static const documentSubtitleBoldAr = 'لخدمات';
  static const documentSubtitleRestAr = '  السيارات';

  /// Column headers (Arabic stacked above English in table).
  static const columnItemAr = 'الصنف';
  static const columnItemEn = 'Item';

  static const columnQtyAr = 'عدد';
  static const columnQtyEn = 'Qty';

  static const columnUnitAr = 'سعر الوحدة';
  static const columnUnitEn = 'Unit Price';

  static const columnTotalAr = 'الإجمالي';
  static const columnTotalEn = 'Total';

  /// Technician commission table (matches digital invoice).
  static const techColTechnicianAr = 'الفني';
  static const techColTechnicianEn = 'Technician';
  static const techColDepartmentAr = 'القسم';
  static const techColDepartmentEn = 'Department';
  static const techColCommissionPctAr = 'نسبة العمولة';
  static const techColCommissionPctEn = 'Commission %';
  static const techColCommissionAr = 'العمولة';
  static const techColCommissionEn = 'Commission';

  /// A4 WhatsApp simplified tax invoice — full goods/services grid (Arabic header above English).
  static const goodsServicesAr = 'البضائع / الخدمات';
  static const goodsServicesEn = 'Goods / Services';

  static const unitPriceExclFullAr = 'سعر الوحدة (بدون ضريبة)\nريال سعودي';
  static const unitPriceExclFullEn = 'Unit Price (Excl. VAT)\n(SAR)';

  static const quantityFullAr = 'الكمية';
  static const quantityFullEn = 'Quantity';

  static const discountColAr = 'الخصم';
  static const discountColEn = 'Discount';

  static const totalBeforeTaxColAr = 'الإجمالي قبل الضريبة';
  static const totalBeforeTaxColEn = 'Total Before Tax';

  static const vatPercentColAr = 'ضريبة القيمة المضافة';
  static const vatPercentColEn = 'VAT';

  static const totalWithVatColAr = 'الإجمالي مع الضريبة';
  static const totalWithVatColEn = 'Total With VAT';

  static const invoiceNoLabelAr = 'رقم الفاتورة';
  static const invoiceNoLabelEn = 'Invoice Number';

  static const vatRegLabelAr =
      'رقم تسجيل ضريبة القيمة المضافة'; // shortened in UI vs official long form OK
  static const vatRegLabelEn = 'VAT Registration Number';

  static const dateLabelAr = 'التاريخ';
  static const dateLabelEn = 'Date';

  static const cashierLabelAr = 'أمين الصندوق';
  static const cashierLabelEn = 'Cashier';

  static const branchLabelAr = 'الفرع';
  static const branchLabelEn = 'Branch';

  static const locationLabelAr = 'الموقع';
  static const locationLabelEn = 'Location';

  /// Customer vehicle block — labels match bilingual tax invoice layout.
  static const custNameAr = 'الاسم';
  static const custNameEn = 'Name';

  static const custPhoneAr = 'الهاتف';
  static const custPhoneEn = 'Phone';

  static const custPlateAr = 'رقم اللوحة';
  static const custPlateEn = 'Plate';

  static const custTimeAr = 'الوقت';
  static const custTimeEn = 'Time';

  static const mileageAr = 'عداد الكيلومترات';
  static const mileageEn = 'Mileage';

  static const custModelAr = 'الموديل';
  static const custModelEn = 'Model';

  static const vinAr = 'رقم الهيكل';
  static const vinEn = 'VIN';

  static const custMakeAr = 'الطراز';
  static const custMakeEn = 'Make';

  static const custYearAr = 'سنة الصنع';
  static const custYearEn = 'Year';

  /// Summary section — Arabic + English + amount row ([thermal_invoice_pdf] stacks Arabic then EN).
  static const totalExclVatAr = 'الإجمالي (غير شاملة ضريبة القيمة المضافة)';
  static const totalExclVatEn = 'Total (Excluding VAT)';

  /// Line-item / per-article discounts (excludes invoice-level & promo).
  static const itemDiscountAr = 'خصم الأصناف';
  static const itemDiscountEn = 'Item Discount';

  /// Department-level invoice discount (excludes line-item and promo).
  static const invoiceDiscountAr = 'خصم الفاتورة';
  static const invoiceDiscountEn = 'Invoice Discount';

  /// Department promo amount only ([ThermalInvoiceTotals.promoDiscount]).
  static const promoDiscountAr = 'خصم الرمز الترويجي';
  static const promoDiscountEn = 'Promo Code Discount';

  static const referralDiscountAr = 'خصم الإحالة';
  static const referralDiscountEn = 'Referral Discount';

  /// Short enough for 80mm thermal — one Arabic line (was wrapping to two).
  static const taxableAr =
      'الإجمالي الخاضع للضريبة (غير شامل ض.ق.م)';
  static const taxableEn = 'Total Taxable Amount (Excluding VAT)';

  static const totalVatAr = 'مجموع ضريبة القيمة المضافة';
  static const totalVatEn = 'Total VAT';

  static const totalDueAr = 'إجمالي المبلغ';
  static const totalDueEn = 'Total Amount';

  static const paymentDetailsAr = 'تفاصيل الدفع';
  static const paymentDetailsEn = 'Payment';

  /// Same labels as cashier digital invoice grid (`Next oil change (km)`).
  static const nextOilChangeAr = 'التغيير القادم للزيت (كم)';
  static const nextOilChangeEn = 'Next oil change (km)';

  // Store closing thermal receipt
  static const storeClosingTitleAr = 'تقرير إغلاق المتجر';
  static const storeClosingTitleEn = 'Store Closing Report';
  static const storeClosingSectionEn = 'COUNTER RECONCILIATION';
  static const closingIdMetaEn = 'Closing ID';
  static const closingIdAr = 'رقم الإغلاق';

  static const closingCategoryAr = 'الفئة';
  static const closingCategoryEn = 'Category';
  static const closingSystemAr = 'النظام';
  static const closingSystemEn = 'System';
  static const closingPhysicalAr = 'فعلي';
  static const closingPhysicalEn = 'Physical';
  static const closingDiffAr = 'الفرق';
  static const closingDiffEn = 'Diff';

  static const closingCashAr = 'النقد';
  static const closingCashEn = 'Cash';
  static const closingBankAr = 'البنك / البطاقات';
  static const closingBankEn = 'Bank / Cards';
  static const closingCorporateAr = 'الشركات';
  static const closingCorporateEn = 'Corporate';
  static const closingTamaraAr = 'تمارا';
  static const closingTamaraEn = 'Tamara';
  static const closingTabbyAr = 'تابي';
  static const closingTabbyEn = 'Tabby';
  static const closingOthersAr = 'أخرى';
  static const closingOthersEn = 'Others';
  static const closingTotalAr = 'الإجمالي';
  static const closingTotalEn = 'Total';
  static const closingGrandTotalAr = 'الإجمالي الكلي';
  static const closingGrandTotalEn = 'Grand Total';
  static const closingSalesReturnAr = 'خصم: إجمالي مرتجعات المبيعات';
  static const closingSalesReturnEn = 'Less: Total sales return';
  static const closingCommissionAr = 'عمولة الكاشير';
  static const closingCommissionEn = 'Cashier commission';

  static const sessionStartEn = 'Session Start';
  static const sessionStartAr = 'بداية الوردية';
  static const sessionEndEn = 'Session End';
  static const sessionEndAr = 'نهاية الوردية';

  static const departmentSalesSectionEn = 'DEPARTMENT SALES';
  static const departmentSalesSectionAr = 'مبيعات الأقسام';
  static const departmentColEn = 'Department';
  static const departmentColAr = 'القسم';
  static const departmentOrdersEn = 'Orders';
  static const departmentOrdersAr = 'الطلبات';
  static const departmentRevenueEn = 'Revenue';
  static const departmentRevenueAr = 'الإيراد';

  /// Arabic line above payment (no trailing colon).
  static String paymentArabicLine(String normalizedPaymentEnglish) {
    final p = normalizedPaymentEnglish.toLowerCase().trim();
    String inner;
    if (p.contains('card') ||
        p.contains('visa') ||
        p.contains('mada') ||
        p.contains('master')) {
      inner = 'البطاقة';
    } else if (p.contains('cash')) {
      inner = 'نقداً';
    } else if (p.contains('employee')) {
      inner = 'الموظفين';
    } else if (p.contains('split')) {
      inner = 'مشترك';
    } else if (p.contains('bank') || p.contains('transfer')) {
      inner = 'تحويل بنكي';
    } else if (p.contains('corporate') ||
        p.contains('company') ||
        p.contains('billing') ||
        p.contains('monthly')) {
      inner = 'الشركات';
    } else {
      final raw = normalizedPaymentEnglish.trim();
      inner = raw.isEmpty ? '-' : raw;
    }
    return 'نوع الدفع ( $inner )';
  }
}