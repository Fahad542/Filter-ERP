class PromoRequirementLine {
  final String type;
  final String text;

  const PromoRequirementLine({required this.type, required this.text});
}

/// Human-readable invoice requirements for promo rules 1–3 + service toggle.
List<PromoRequirementLine> buildPromoApplicationRequirements({
  String selectedItemMatchMode = 'all_required',
  bool selectedServiceRequired = true,
  String productScope = 'all',
  String serviceScope = 'all',
  List<String> productNames = const [],
  List<String> serviceNames = const [],
  String applicableProducts = '',
  String applicableServices = '',
  bool isArabic = false,
}) {
  final lines = <PromoRequirementLine>[];
  final mode = _normalizeMode(selectedItemMatchMode);
  final hasProductSelection = _isSelectedScope(productScope) && _hasNamedItems(
        productNames,
        applicableProducts,
      );
  final hasServiceSelection = _isSelectedScope(serviceScope) && _hasNamedItems(
        serviceNames,
        applicableServices,
      );
  final bothSelected = hasProductSelection && hasServiceSelection;
  final serviceOptional = bothSelected && !selectedServiceRequired;

  lines.add(PromoRequirementLine(
    type: 'heading',
    text: _ruleTitle(mode, isArabic: isArabic),
  ));
  lines.add(PromoRequirementLine(
    type: 'text',
    text: _ruleSummary(mode, isArabic: isArabic),
  ));

  if (mode == 'all_required') {
    lines.add(PromoRequirementLine(
      type: 'text',
      text: isArabic
          ? 'يجب أن تتضمن الفاتورة جميع المنتجات/الفئات المحددة أدناه.'
          : 'Invoice must include ALL selected products/categories below.',
    ));
    if (bothSelected && selectedServiceRequired) {
      lines.add(PromoRequirementLine(
        type: 'text',
        text: isArabic
            ? 'يجب أن تتضمن الفاتورة أيضاً جميع الخدمات/الفئات المحددة أدناه.'
            : 'Invoice must also include ALL selected services/categories below.',
      ));
    } else if (serviceOptional) {
      lines.add(PromoRequirementLine(
        type: 'text',
        text: isArabic
            ? 'الخدمات المحددة اختيارية — المنتجات وحدها يمكن أن تفعّل العرض.'
            : 'Selected services are optional — products alone can unlock this promo.',
      ));
    }
  } else if (mode == 'any_present') {
    lines.add(PromoRequirementLine(
      type: 'text',
      text: serviceOptional
          ? (isArabic
              ? 'يجب أن تحتوي الفاتورة على منتج/فئة محددة واحدة على الأقل أو خدمة/فئة محددة واحدة على الأقل.'
              : 'Invoice needs at least one selected product/category OR one selected service/category.')
          : bothSelected && selectedServiceRequired
              ? (isArabic
                  ? 'يجب أن تحتوي الفاتورة على منتج/فئة محددة واحدة على الأقل وخدمة/فئة محددة واحدة على الأقل.'
                  : 'Invoice needs at least one selected product/category AND at least one selected service/category.')
              : (isArabic
                  ? 'يجب أن تحتوي الفاتورة على منتج/خدمة/فئة محددة واحدة على الأقل من القوائم أدناه.'
                  : 'Invoice needs at least one selected product/service/category from the lists below.'),
    ));
  }

  if (mode == 'all_required' || mode == 'any_present') {
    lines.add(PromoRequirementLine(
      type: 'text',
      text: isArabic
          ? 'يُطبَّق الخصم على بنود الفاتورة المؤهلة فقط (قبل ضريبة القيمة المضافة، وليس على إجمالي الفاتورة).'
          : 'Discount applies only on matching eligible line items (before VAT, not the full invoice).',
    ));
  } else if (mode == 'entire_order') {
    lines.add(PromoRequirementLine(
      type: 'text',
      text: serviceOptional
          ? (isArabic
              ? 'يجب أن تحتوي الفاتورة على منتج/فئة أو خدمة/فئة محددة واحدة على الأقل كمحفّز.'
              : 'Invoice needs at least one selected product/category OR service/category as a trigger.')
          : bothSelected && selectedServiceRequired
              ? (isArabic
                  ? 'يجب أن تحتوي الفاتورة على منتج/فئة وخدمة/فئة محددة واحدة على الأقل كمحفّز.'
                  : 'Invoice needs at least one selected product/category AND one selected service/category as a trigger.')
              : (isArabic
                  ? 'يجب أن تحتوي الفاتورة على عنصر محفّز مؤهل واحد على الأقل.'
                  : 'Invoice needs at least one eligible selected item as a trigger.'),
    ));
    lines.add(PromoRequirementLine(
      type: 'text',
      text: isArabic
          ? 'يُطبَّق الخصم على إجمالي الفاتورة كاملة (قبل ضريبة القيمة المضافة).'
          : 'Discount applies to the full invoice total (before VAT).',
    ));
  }

  final products = _resolveItemNames(
    scope: productScope,
    names: productNames,
    summary: applicableProducts,
  );
  final services = _resolveItemNames(
    scope: serviceScope,
    names: serviceNames,
    summary: applicableServices,
  );

  if (productScope.toLowerCase() == 'all') {
    lines.add(PromoRequirementLine(
      type: 'subheading',
      text: isArabic ? 'المنتجات' : 'Products',
    ));
    lines.add(PromoRequirementLine(
      type: 'bullet',
      text: isArabic ? 'جميع المنتجات' : 'All products',
    ));
  } else if (products.isNotEmpty) {
    lines.add(PromoRequirementLine(
      type: 'subheading',
      text: mode == 'all_required' && hasProductSelection && selectedServiceRequired
          ? (isArabic ? 'المنتجات / الفئات المطلوبة (الكل)' : 'Required products / categories (all)')
          : (isArabic ? 'المنتجات / الفئات المؤهلة' : 'Eligible products / categories'),
    ));
    for (final name in products) {
      lines.add(PromoRequirementLine(type: 'bullet', text: name));
    }
  }

  if (serviceScope.toLowerCase() == 'all') {
    lines.add(PromoRequirementLine(
      type: 'subheading',
      text: isArabic ? 'الخدمات' : 'Services',
    ));
    lines.add(PromoRequirementLine(
      type: 'bullet',
      text: isArabic ? 'جميع الخدمات' : 'All services',
    ));
  } else if (services.isNotEmpty) {
    lines.add(PromoRequirementLine(
      type: 'subheading',
      text: mode == 'all_required' && hasServiceSelection && selectedServiceRequired
          ? (isArabic
              ? 'الخدمات / الفئات المطلوبة (محفّز فقط — بدون خصم)'
              : 'Required services / categories (trigger only — no discount)')
          : (isArabic ? 'الخدمات / الفئات المؤهلة' : 'Eligible services / categories'),
    ));
    for (final name in services) {
      lines.add(PromoRequirementLine(type: 'bullet', text: name));
    }
  }

  if (bothSelected) {
    lines.add(PromoRequirementLine(
      type: 'note',
      text: selectedServiceRequired
          ? (isArabic
              ? 'المفتاح ON: يجب أن تتضمن الفاتورة منتج/فئة محددة وخدمة/فئة محددة. الخدمة المطلوبة محفّز فقط — لا يُطبَّق الخصم عليها.'
              : 'Toggle ON: invoice must include selected product/category and selected service/category. Required services are trigger-only — no discount on them.')
          : (isArabic
              ? 'المفتاح OFF: الخدمة المحددة اختيارية؛ يمكن تطبيق العرض على المنتجات/الفئات المحددة.'
              : 'Toggle OFF: selected service is optional; promo can apply on selected products/categories.'),
    ));
  }

  if (hasProductSelection || hasServiceSelection) {
    lines.add(PromoRequirementLine(
      type: 'note',
      text: isArabic
          ? 'فئة فقط = الخصم على كل المنتجات/الخدمات داخل تلك الفئة. فئة + منتجات/خدمات محددة = الخصم على المحدد فقط (حسب القاعدة).'
          : 'Category only = discount on all products/services in that category. Category + specific items = discount only on those selected items (per rule).',
    ));
  }

  return lines;
}

String buildPromoApplicationRequirementsSummary({
  String selectedItemMatchMode = 'all_required',
  bool selectedServiceRequired = true,
  String productScope = 'all',
  String serviceScope = 'all',
  List<String> productNames = const [],
  List<String> serviceNames = const [],
}) {
  final mode = _normalizeMode(selectedItemMatchMode);
  final bothSelected = _isSelectedScope(productScope) &&
      _isSelectedScope(serviceScope) &&
      (productNames.isNotEmpty || serviceNames.isNotEmpty);

  final buffer = StringBuffer(_ruleTitle(mode));
  if (mode == 'entire_order') {
    buffer.write(' · Full invoice discount');
  }
  if (bothSelected) {
    buffer.write(
      selectedServiceRequired
          ? ' · Product + service required'
          : ' · Product or service sufficient',
    );
  }
  return buffer.toString();
}

String _normalizeMode(String? raw) {
  final mode = (raw ?? 'all_required').trim().toLowerCase();
  if (mode == 'any_present' || mode == 'any' || mode == 'partial') {
    return 'any_present';
  }
  if (mode == 'entire_order' ||
      mode == 'entire_order_discount' ||
      mode == 'full_order') {
    return 'entire_order';
  }
  return 'all_required';
}

bool _isSelectedScope(String scope) => scope.trim().toLowerCase() == 'selected';

bool _hasNamedItems(List<String> names, String summary) =>
    names.isNotEmpty ||
    (summary.trim().isNotEmpty &&
        summary != 'All Products' &&
        summary != 'All Services' &&
        summary != 'Does not apply');

List<String> _resolveItemNames({
  required String scope,
  required List<String> names,
  required String summary,
}) {
  if (scope.toLowerCase() == 'all' || scope.toLowerCase() == 'none') {
    return const [];
  }
  if (names.isNotEmpty) return names;
  if (summary.trim().isEmpty ||
      summary == 'All Products' ||
      summary == 'All Services' ||
      summary == 'Does not apply') {
    return const [];
  }
  return summary
      .split(',')
      .map((part) => part.replaceAll(RegExp(r'\s*\+\d+\s*more\s*$'), '').trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String _ruleTitle(String mode, {bool isArabic = false}) {
  switch (mode) {
    case 'any_present':
      return isArabic
          ? 'القاعدة 2 — أي منتج/خدمة/فئة محددة'
          : 'Rule 2 — Any selected product/service/category';
    case 'entire_order':
      return isArabic
          ? 'القاعدة 3 — محفّز مؤهل، خصم على كامل الفاتورة'
          : 'Rule 3 — Eligible trigger, entire invoice discount';
    default:
      return isArabic
          ? 'القاعدة 1 — محفّز منتج/فئة محددة'
          : 'Rule 1 — Selected product/category trigger';
  }
}

String _ruleSummary(String mode, {bool isArabic = false}) {
  switch (mode) {
    case 'any_present':
      return isArabic
          ? 'يجب أن تحتوي الفاتورة على عنصر محدد واحد على الأقل. يُطبَّق الخصم على الأسطر المؤهلة فقط.'
          : 'Invoice needs at least one selected item. Discount applies only on matching eligible lines.';
    case 'entire_order':
      return isArabic
          ? 'يجب أن تحتوي الفاتورة على عنصر محفّز مؤهل. يُطبَّق الخصم على إجمالي الفاتورة.'
          : 'Invoice needs an eligible trigger item. Discount applies on the full invoice total.';
    default:
      return isArabic
          ? 'يجب أن تتضمن الفاتورة المنتج/الفئة المحددة. يمكن أن تكون الخدمات المحددة إلزامية أو اختيارية.'
          : 'Invoice must contain the selected product/category. Selected services can be mandatory or optional.';
  }
}
