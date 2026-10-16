/// Fixed "No Cash" expense types (not deducted from petty-cash wallet).
const List<String> noCashExpenseTypes = [
  'Water tanker',
  'Car wash chemical',
  'Tools purchase',
  'Polishing material',
  'Car covers',
  'Upholstery',
  'Miscellaneous',
];

const Map<String, String> noCashExpenseTypeLabelsAr = {
  'Water tanker': 'وايت الماء',
  'Car wash chemical': 'كيماويات غسيل السيارات',
  'Tools purchase': 'شراء أدوات',
  'Polishing material': 'مواد التلميع',
  'Car covers': 'أغطية السيارات',
  'Upholstery': 'تنجيد',
  'Miscellaneous': 'متنوع',
};

String noCashExpenseTypeLabel(String name, String languageCode) {
  final trimmed = name.trim();
  if (languageCode.startsWith('ar')) {
    return noCashExpenseTypeLabelsAr[trimmed] ?? trimmed;
  }
  return trimmed;
}

/// POS petty-cash expense category labels (English API name → Arabic display).
const Map<String, String> pettyCashExpenseCategoryLabelsAr = {
  'Advertising and promotion': 'مصاريف الطباعة والإعلان',
  'Bank charges': 'رسوم خدمة البنك',
  'Charity / Donations / Reward Expenses':
      'الأعمال الخيرية / التبرعات / مصاريف المكافآت',
  'Customer Compensation Expenses': 'مصاريف تعويضات العملاء',
  'Customer services expenses': 'مصاريف خدمات العملاء',
  'Development & Renovation Expenses': 'مصاريف التطوير والتجديد',
  'Food & Entertainment': 'نفقات الطعام والترفيه',
  'Fuel Allowance Expenses': 'مصاريف بدل البنزين',
  'Information Technology Expenses': 'تكنولوجيا المعلومات مصروفات',
  'Labour uniform & shoes Expenses': 'مصاريف زي العمل والأحذية',
  'Medical Expenses': 'النفقات الطبية',
  'Misc Accommodation Expenses': 'مصاريف التدبير المنزلي',
  'Misc Expenses': 'مصاريف متنوعة',
  'Misc Government Expenses': 'مصاريف حكومية متنوعة',
  'Motor vehicle Repair Expenses': 'مصاريف إصلاح المركبات',
  'Municipal / Garbage Expenses - شركة الهلب للتجارية و المقاولات':
      'Municipal / Garbage Expenses - شركة الهلب للتجارية و المقاولات',
  'POL Expenses': 'مصاريف البنزين',
  'Printing and stationery': 'الطباعة والقرطاسية',
  'Repair & maintenance Expenses - Accomodation':
      'مصاريف الإصلاح والصيانة - سكن',
  'Repair & maintenance Expenses - Car Wash':
      'مصاريف الإصلاح والصيانة - غسيل',
  'Salary Advances': 'سلف رواتب',
  'No Cash': 'غير نقدي',
};

String pettyCashExpenseCategoryLabel(String name, String languageCode) {
  final trimmed = name.trim();
  if (trimmed == 'No Cash') {
    return languageCode.startsWith('ar') ? 'غير نقدي' : 'Non Cash';
  }
  if (languageCode.startsWith('ar')) {
    return pettyCashExpenseCategoryLabelsAr[trimmed] ?? trimmed;
  }
  return trimmed;
}
