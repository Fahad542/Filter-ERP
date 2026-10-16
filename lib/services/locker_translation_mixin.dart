import 'package:flutter/foundation.dart';
import 'package:translator/translator.dart';
import 'session_service.dart';
import '../utils/plate_transliterator.dart';
import '../models/workshop_owner_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/services/locker_translation_mixin.dart
//
// App-wide dynamic translation service — v2 (locale-safe rewrite)
//
// Static UI strings  → AppLocalizations (ARB / gen-l10n).
// Dynamic strings (names, notes, status labels from the DB/API) come back in
// English and are translated on the fly when the app locale is Arabic.
//
// KEY FIXES vs v1
// ───────────────
// 1. localizedTextForLanguage() now takes the language code directly from the
//    widget tree (Localizations.localeOf(context).languageCode) — no async
//    SessionService.getLocale() call that could return a stale value mid-flight.
//
// 2. _shouldKeepRaw: removed the rule that blocked strings starting with
//    "SAR <number>" — those come in notification messages ("SAR 450 for
//    approval") and must be translated to Arabic. Only bare numeric strings,
//    reference codes, URLs, emails, and phone numbers stay untouched.
//
// 3. Generation counter pattern documented for callers: always store a
//    generation int, bump it on every locale change, and discard results from
//    previous generations.
//
// Used by ALL modules: Locker, Owner, Accounting, Approvals, POS, etc.
// ─────────────────────────────────────────────────────────────────────────────

class AppTranslationService {
  AppTranslationService._();

  static final GoogleTranslator _translator = GoogleTranslator();

  /// In-memory LRU-style cache keyed by "targetLang:text".
  static final Map<String, String> _cache = {};

  /// Maximum cached entries — prevents unbounded growth.
  static const int _maxCache = 500;

  // ── Status map — instant lookup, no network call ──────────────────────────

  /// Canonical English status string → Arabic translation.
  /// Covers raw API values and formatted UI labels across ALL modules.
  static final Map<String, String> _statusMapAr = {
    // ── Locker / Petty Cash / Approvals ──────────────────────────────────
    'PENDING'           : 'قيد الانتظار',
    'ASSIGNED'          : 'معيَّن',
    'AWAITING'          : 'في انتظار الموافقة',
    'AWAITING APPROVAL' : 'في انتظار الموافقة',
    'COLLECTED'         : 'محصَّل',
    'APPROVED'          : 'معتمد',
    'REJECTED'          : 'مرفوض',
    'pending'           : 'قيد الانتظار',
    'assigned'          : 'معيَّن',
    'awaiting_approval' : 'في انتظار الموافقة',
    'pending_approval'  : 'في انتظار الموافقة',
    'collected'         : 'محصَّل',
    'approved'          : 'معتمد',
    'rejected'          : 'مرفوض',
    'SHORT'             : 'ناقص',
    'OVER'              : 'زائد',

    // ── Locker branch / role display phrases (common API values) ─────────
    'Lock Supervisor'   : 'مشرف اللوكر',
    'Locker Supervisor' : 'مشرف اللوكر',
    'Tire Branch'       : 'فرع الإطارات',
    'Tire Dept'         : 'قسم الإطارات',
    'Tire Department'   : 'قسم الإطارات',
    'Branch'            : 'فرع',
    'Supervisor'        : 'مشرف',
    'Collector'         : 'محصل',
    'Cashier'           : 'أمين الصندوق',

    // ── POS UI/API display labels ─────────────────────────────────────────
    'Online now'        : 'متصل الآن',
    'Not available'     : 'غير متاح',
    'Workshop Duty'     : 'دوام الورشة',
    'On-Call Duty'      : 'دوام عند الطلب',
    'On Call Duty'      : 'دوام عند الطلب',
    'Active'            : 'نشط',
    'COMPLETE'          : 'مكتمل',
    'COMPLETED'         : 'مكتمل',
    'INVOICED'          : 'مفوتر',
    'invoiced'          : 'مفوتر',
    'Invoiced'          : 'مفوتر',
    'IN PROGRESS'       : 'قيد التنفيذ',
    'In progress'       : 'قيد التنفيذ',
    'DRAFT'             : 'مسودة',
    'Products'          : 'المنتجات',
    'Services'          : 'الخدمات',
    'Products & Services': 'المنتجات والخدمات',
    'Other Oils'        : 'زيوت أخرى',
    'Other Oil Filters' : 'فلاتر زيت أخرى',
    'Gear Oil'          : 'زيت القير',
    'Oil Change Department': 'قسم تغيير الزيت',
    'Low'               : 'منخفض',
    'Out of stock'      : 'غير متوفر',
    'Out of Stock'      : 'غير متوفر',
    'In stock'          : 'متوفر',
    'In Stock'          : 'متوفر',
    'Assign Technicians' : 'تعيين الفنيين',
    'items'             : 'عناصر',
    'item'              : 'عنصر',
    'Item'              : 'عنصر',
    'Items'             : 'عناصر',
    'Total before VAT'  : 'الإجمالي قبل ضريبة القيمة المضافة',
    'VAT (15%)'         : 'ضريبة القيمة المضافة (15٪)',
    'Total (incl. VAT)' : 'الإجمالي شامل الضريبة',
    'No Order Selected' : 'لم يتم تحديد طلب',
    'Select an order from the list on the left to view details': 'اختر طلبًا من القائمة لعرض التفاصيل',
    'Delete Job'        : 'حذف المهمة',
    'YES, DELETE'       : 'نعم، احذف',
    'NO'                : 'لا',
    'Dept'              : 'القسم',
    'Dept:'             : 'القسم:',
    'Department'        : 'القسم',
    'dept'              : 'القسم',
    'dept 1'            : 'القسم 1',
    // ── Technician / Takeaway API labels ───────────────────────────────
    'Polishing Department'      : 'قسم التلميع',
    'Washing Department'        : 'قسم الغسيل',
    'Takeaway'                  : 'طلبات خارجية',
    'Technicians'               : 'الفنيون',
    'Search technicians...'     : 'ابحث عن فني...',
    'Search products & services...': 'ابحث عن المنتجات والخدمات...',
    'liter'                     : 'لتر',
    'Liter'                     : 'لتر',
    'litre'                     : 'لتر',
    'Litre'                     : 'لتر',
    'LITER'                     : 'لتر',
    'LITRE'                     : 'لتر',
    'L'                         : 'لتر',
    'ml'                        : 'مل',
    'ML'                        : 'مل',
    'Milliliter'                : 'مل',
    'milliliter'                : 'مل',
    'kg'                        : 'كجم',
    'KG'                        : 'كجم',
    'Kilogram'                  : 'كيلوغرام',
    'kilogram'                  : 'كيلوغرام',
    'g'                         : 'غرام',
    'Gram'                      : 'غرام',
    'gram'                      : 'غرام',
    'Set'                       : 'طقم',
    'set'                       : 'طقم',
    'Bottle'                    : 'زجاجة',
    'bottle'                    : 'زجاجة',
    'Can'                       : 'علبة',
    'can'                       : 'علبة',
    'Box'                       : 'صندوق',
    'box'                       : 'صندوق',
    'Piece'                     : 'قطعة',
    'piece'                     : 'قطعة',
    'Pcs'                       : 'قطعة',
    'pcs'                       : 'قطعة',
    'Unit'                      : 'وحدة',
    'unit'                      : 'وحدة',
    'Inactive'                  : 'غير نشط',
    'Low Stock'                 : 'مخزون منخفض',
    'Add Promo Code'            : 'إضافة رمز عرض',
    'Promo:'                    : 'العرض:',
    'Gross Amount'              : 'المبلغ الإجمالي',
    'Price after line discount' : 'السعر بعد خصم السطر',
    'Line discount'             : 'خصم السطر',
    'Total discount'            : 'إجمالي الخصم',
    'Total discount applied'    : 'إجمالي الخصم المطبق',
    'Price after total discount': 'السعر بعد إجمالي الخصم',
    'Promo discount'            : 'خصم العرض',
    'Price after promo'         : 'السعر بعد العرض',
    'Generate Invoice'          : 'إنشاء فاتورة',
    'Add customer details'      : 'إضافة بيانات العميل',
    'Select payment'            : 'اختيار طريقة الدفع',
    'Walk-in Customer'          : 'عميل عابر',
    'Bank transfer'             : 'تحويل بنكي',
    'Corporate credit'          : 'ائتمان شركة',
    'corporate credit'          : 'ائتمان شركة',
    'Tamara'                    : 'تمارا',
    'tamara'                    : 'تمارا',
    'Tabby'                     : 'تابي',
    'Oil Change'                : 'تغيير الزيت',
    'Car Wash'                  : 'غسيل السيارات',
    'Repair'                    : 'إصلاح',
    'AC Service'                : 'خدمة المكيف',
    'Battery'                   : 'بطارية',
    'Brakes'                    : 'فرامل',
    'Filters'                   : 'فلاتر',
    'Oils'                      : 'زيوت',
    'Online Only'               : 'المتصلون فقط',
    'Show All'                  : 'عرض الكل',
    'All technicians removed from this job': 'تمت إزالة جميع الفنيين من هذه المهمة',
    'Technicians assigned successfully': 'تم تعيين الفنيين بنجاح',
    // ── Accounting ────────────────────────────────────────────────────────
    'overdue'           : 'متأخر',
    'settled'           : 'مسوَّى',
    'OVERDUE'           : 'متأخر',
    'SETTLED'           : 'مسوَّى',
    // ── Accounting transaction types ──────────────────────────────────────
    'payable'           : 'مستحق الدفع',
    'receivable'        : 'مستحق القبض',
    'expense'           : 'مصروف',
    'advance'           : 'سلفة',
    'PAYABLE'           : 'مستحق الدفع',
    'RECEIVABLE'        : 'مستحق القبض',
    'EXPENSE'           : 'مصروف',
    'ADVANCE'           : 'سلفة',
    // ── Approvals queue types ─────────────────────────────────────────────
    'fund'              : 'شحن رصيد',
    'all'               : 'الكل',
    'FUND'              : 'شحن رصيد',
    'fund_request'      : 'طلب تمويل',
    'FUND REQUEST'      : 'طلب تمويل',
    'cashier expense'   : 'مصروف أمين الصندوق',
    'CASHIER EXPENSE'   : 'مصروف أمين الصندوق',
    'Petty cash request': 'طلب عهدة نقدية',
    // ── POS order / cashier statuses ─────────────────────────────────────
    'Draft'             : 'مسودة',
    'draft'             : 'مسودة',
    'Waiting'           : 'في الانتظار',
    'waiting'           : 'في الانتظار',
    'Accepted by Tech'  : 'مقبول من الفني',
    'accepted'          : 'مقبول',
    'In Progress'       : 'قيد التنفيذ',
    'in progress'       : 'قيد التنفيذ',
    'Tech Completed'    : 'أكمله الفني',
    'completed by technician': 'أكمله الفني',
    'Completed'         : 'مكتمل',
    'completed'         : 'مكتمل',
    'Cancelled'         : 'ملغى',
    'cancelled'         : 'ملغى',
    'canceled'          : 'ملغى',
    'Corp. pending approval': 'بانتظار موافقة الشركة',
    'waiting for corporate': 'بانتظار الشركة',
    'unapproved'        : 'غير معتمد',
    'Corporate approved': 'معتمد من الشركة',
    'corporate approved': 'معتمد من الشركة',
    'Rejected by corporate': 'مرفوض من الشركة',
    'rejected by corporate': 'مرفوض من الشركة',
    'Invoiced'          : 'مفوتر',
    'invoiced'          : 'مفوتر',
    // ── Employee / POS statuses ───────────────────────────────────────────
    'active'            : 'نشط',
    'inactive'          : 'غير نشط',
    'ACTIVE'            : 'نشط',
    'INACTIVE'          : 'غير نشط',
    'online'            : 'متصل',
    'offline'           : 'غير متصل',
    'busy'              : 'مشغول',
    'available'         : 'متاح',
    'ONLINE'            : 'متصل',
    'OFFLINE'           : 'غير متصل',
    'BUSY'              : 'مشغول',
    'AVAILABLE'         : 'متاح',
    // ── Bill / Invoice statuses ───────────────────────────────────────────
    'Pending'           : 'قيد الانتظار',
    'Paid'              : 'مدفوع',
    'Partially Paid'    : 'مدفوع جزئياً',
    'Overdue'           : 'متأخر',
    'paid'              : 'مدفوع',
    'partially paid'    : 'مدفوع جزئياً',
    'submitted'         : 'مرسل',
    'SUBMITTED'         : 'مرسل',
    'waiting approval'  : 'في انتظار الموافقة',
    'Waiting Approval'  : 'في انتظار الموافقة',
    'complete'          : 'مكتمل',
    'cash'              : 'نقداً',
    'Cash'              : 'نقداً',
    'card'              : 'بطاقة',
    'Card'              : 'بطاقة',
    'bank transfer'     : 'تحويل بنكي',
    'Bank Transfer'     : 'تحويل بنكي',
    'wallet'            : 'محفظة',
    'Wallet'            : 'محفظة',
    'All'               : 'الكل',
    'Today'             : 'اليوم',
    'general'           : 'عام',
    'General'           : 'عام',
    'service'           : 'خدمة',
    'Service'           : 'خدمة',
    'product'           : 'منتج',
    'Product'           : 'منتج',
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Translates [text] to [targetLang].
  /// Returns the original on error, empty input, numeric input, or if the
  /// text is already in the target script.
  static Future<String> translate(
      String text, {
        String targetLang = 'ar',
        String sourceLang = 'en',
      }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    if (_shouldKeepRaw(trimmed)) return text;
    if (_containsArabic(trimmed)) return text; // already Arabic

    // Status fast-path — no network call needed.
    if (targetLang == 'ar' && _statusMapAr.containsKey(trimmed)) {
      return _statusMapAr[trimmed]!;
    }

    final key = '$targetLang:$trimmed';
    if (_cache.containsKey(key)) return _cache[key]!;

    // Compound display labels: "Al-Basateen - Tire Branch", "Cashier2 - Tire Dept"
    // Translate each segment so mapped phrases (Tire Branch, Lock Supervisor…) apply.
    if (trimmed.contains(' - ')) {
      final parts = trimmed
          .split(' - ')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        final translated = await Future.wait(
          parts.map(
            (p) => translate(p, targetLang: targetLang, sourceLang: sourceLang),
          ),
        );
        final joined = translated.join(' - ');
        if (_cache.length >= _maxCache) {
          _cache.remove(_cache.keys.first);
        }
        _cache[key] = joined;
        return joined;
      }
    }

    try {
      final result = await _translator.translate(
        trimmed,
        from: sourceLang,
        to: targetLang,
      );
      final out = result.text.trim();
      if (out.isNotEmpty) {
        if (_cache.length >= _maxCache) {
          _cache.remove(_cache.keys.first);
        }
        _cache[key] = out;
        return out;
      }
    } catch (_) {
      // Fall through — return original below.
    }

    return text;
  }

  /// Translates only when the current session locale is Arabic.
  ///
  /// ⚠ PREFER [localizedTextForLanguage] in widgets — it reads locale directly
  /// from the widget tree and avoids the async SessionService round-trip.
  static Future<String> localizedText(String text) async {
    if (!await _isArabicFromSession()) return text;
    return translate(text);
  }

  /// Context/locale-safe variant for widgets.
  ///
  /// Pass [languageCode] from `Localizations.localeOf(context).languageCode`
  /// so the translation decision is based on the current live locale — not on
  /// SessionService which may lag by one frame after a locale switch.
  ///
  /// This avoids the "API data not re-translated on locale switch" bug: when
  /// the user switches language, didChangeDependencies fires with the new
  /// locale, you pass its languageCode here, and you always get the correct
  /// translation regardless of whether SessionService has flushed yet.
  static Future<String> localizedTextForLanguage(
      String text,
      String languageCode,
      ) async {
    if (languageCode != 'ar') return text;
    return translate(text);
  }


  // ── Plate transliteration — delegated to PlateTransliterator ─────────────
  //
  // All plate logic lives in plate_transliterator.dart so every screen can
  // import it directly without going through AppTranslationService.
  // These wrappers keep existing call-sites working unchanged.

  /// Converts a Latin plate string to its Arabic representation.
  /// Delegates to [PlateTransliterator.toArabic].
  static String localizePlateForArabic(String plate) =>
      PlateTransliterator.toArabic(plate);

  /// Localizes Western digits to Arabic-Indic digits when [languageCode] is Arabic.
  /// This is intentionally separate from text translation so API numeric values
  /// can be rendered locale-correctly without sending numbers to the translator.
  static String localizeDigitsForLanguage(String text, String languageCode) {
    if (languageCode != 'ar' || text.isEmpty) return text;
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic  = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var out = text;
    for (var i = 0; i < western.length; i++) {
      out = out.replaceAll(western[i], arabic[i]);
    }
    return out;
  }

  static String syncStatusOrRawForLanguage(String text, String languageCode) {
    if (languageCode != 'ar') return text;
    final trimmed = text.trim();
    return _statusMapAr[trimmed] ?? localizeDigitsForLanguage(text, languageCode);
  }

  /// Locale-safe dynamic API value renderer. Text is translated for Arabic,
  /// while bare numbers/dates/counts are digit-localized for Arabic.
  /// Plate numbers are transliterated; reference codes keep digits localized;
  /// URLs and emails are returned as-is.
  static Future<String> localizedDynamicValueForLanguage(
      String text,
      String languageCode,
      ) async {
    if (languageCode != 'ar') return text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    // URLs: don't touch.
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) return text;
    // Emails: don't touch.
    if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) return text;

    // Vehicle plate numbers → full Arabic transliteration (letters + digits).
    if (PlateTransliterator.looksLikePlate(trimmed)) {
      return localizePlateForArabic(trimmed);
    }

    // Other reference codes (INV-001, PO-002 …): digit-localize only.
    if (_looksLikeReferenceCode(trimmed)) {
      return localizeDigitsForLanguage(text, languageCode);
    }

    final translated = await localizedTextForLanguage(text, languageCode);
    return localizeDigitsForLanguage(translated, languageCode);
  }


  /// Nullable variant — returns null when input is null.
  static Future<String?> localizedTextNullable(String? text) async {
    if (text == null) return null;
    return localizedText(text);
  }

  /// Nullable variant using widget-tree language code (preferred in widgets).
  static Future<String?> localizedTextNullableForLanguage(
      String? text,
      String languageCode,
      ) async {
    if (text == null) return null;
    return localizedTextForLanguage(text, languageCode);
  }

  /// Translates a list of strings, returning originals on non-Arabic locale.
  static Future<List<String>> localizedAll(List<String> texts) async {
    if (!await _isArabicFromSession()) return texts;
    return Future.wait(texts.map(translate));
  }

  /// Translates a list of strings using widget-tree locale (preferred).
  static Future<List<String>> localizedAllForLanguage(
      List<String> texts,
      String languageCode,
      ) async {
    if (languageCode != 'ar') return texts;
    return Future.wait(texts.map(translate));
  }

  /// Translates a status string using the fast-path map first.
  static Future<String> localizedStatus(String status) async {
    if (!await _isArabicFromSession()) return status;
    return _statusMapAr[status] ?? translate(status);
  }

  /// Translates a status string using widget-tree locale (preferred).
  static Future<String> localizedStatusForLanguage(
      String status,
      String languageCode,
      ) async {
    if (languageCode != 'ar') return status;
    return _statusMapAr[status] ?? translate(status);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Reads locale from SessionService. Use only in non-widget contexts
  /// (ViewModels, background tasks). In widgets, prefer [localizedTextForLanguage].
  static Future<bool> _isArabicFromSession() async {
    final locale = await SessionService.getLocale();
    return locale == 'ar';
  }

  static bool _looksLikeReferenceCode(String text) {
    final v = text.trim();
    if (RegExp(r'^#?[A-Z]{1,6}[-_/]?[A-Z0-9]{2,}$').hasMatch(v)) return true;
    if (RegExp(r'^[A-Z0-9]{2,}[-_/][A-Z0-9\-_/]{2,}$').hasMatch(v)) return true;
    return false;
  }

  /// Strings that should NEVER be sent to the translation API:
  ///  • Pure numbers / decimals
  ///  • URLs
  ///  • Email addresses
  ///  • Phone numbers
  ///  • Reference codes like INV-001, PO-002, #REF2024
  ///  • Date strings like 01/05/2024
  ///
  /// NOTE: "SAR 450" embedded inside a sentence IS NOT blocked — we want
  /// the full sentence (e.g. "submitted an expense of SAR 450") to be
  /// translated. The translator preserves currency codes in context.
  /// Standalone "SAR" symbol is handled via l10n.ownerCurrencySar, not here.
  static bool _shouldKeepRaw(String text) {
    final v = text.trim();
    if (v.isEmpty) return true;
    // Pure number (integer or decimal) — keep as-is
    if (double.tryParse(v) != null) return true;
    // URL
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(v)) return true;
    // Email
    if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return true;
    // Phone number (7+ digits with optional +, spaces, dashes, parens)
    if (RegExp(r'^[+]?\d[\d\s().-]{5,}$').hasMatch(v)) return true;
    // Short uppercase reference codes: INV-001, PO-002, REF#2024
    if (RegExp(r'^#?[A-Z]{1,6}[-_/]?[A-Z0-9]{2,}$').hasMatch(v)) return true;
    if (RegExp(r'^[A-Z0-9]{2,}[-_/][A-Z0-9\-_/]{2,}$').hasMatch(v)) return true;
    // Date strings
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(v)) return true;
    return false;
  }

  static bool _containsArabic(String text) =>
      text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

  static void clearCache() => _cache.clear();
  static int get cacheSize => _cache.length;
}

// ── Lightweight translated DTOs ───────────────────────────────────────────────

/// Holds translated display strings for any request that has
/// branch / cashier / officer fields (Locker, Approvals, etc.).
class RequestTranslated {
  final String branchName;
  final String cashierName;
  final String? assignedOfficerName;

  const RequestTranslated({
    required this.branchName,
    required this.cashierName,
    this.assignedOfficerName,
  });
}

// ── Backward-compatibility alias ──────────────────────────────────────────────
typedef LockerRequestTranslated = RequestTranslated;

// ── Mixin for ChangeNotifier view-models ─────────────────────────────────────

/// Mix into any ChangeNotifier-based ViewModel that loads dynamic string data
/// from the API and needs on-the-fly Arabic translation.
///
/// Module-agnostic — use in Locker, Accounting, Approvals, Owner, POS, etc.
///
/// LOCALE SWITCH PATTERN
/// ─────────────────────
/// ViewModels must store raw API data and re-translate on locale change.
/// Do NOT overwrite raw fields. Pattern:
///
///   class MyViewModel extends ChangeNotifier with TranslatableMixin {
///     // Raw (always English from API)
///     List<MyItem> _rawItems = [];
///     // Display (translated)
///     List<MyItem> _items = [];
///     List<MyItem> get items => _items;
///
///     Future<void> load() async {
///       _rawItems = await repo.fetchItems();
///       await _applyTranslations();
///     }
///
///     // Called by bindLocaleRetranslation on every locale change
///     Future<void> retranslate() => _applyTranslations();
///
///     Future<void> _applyTranslations() async {
///       _items = await Future.wait(_rawItems.map(_translateItem));
///       notifyListeners();
///     }
///   }
///
/// In initState (or ViewModel constructor):
///   viewModel.bindLocaleRetranslation(settingsViewModel, viewModel.retranslate);
mixin TranslatableMixin {
  Listenable? _localeListenable;
  VoidCallback? _localeListener;

  /// Bind this ViewModel to SettingsViewModel (or any Listenable that notifies
  /// when locale changes). Call once from the ViewModel constructor or initState.
  ///
  /// [retranslate] should:
  ///   1. Clear the translation cache (AppTranslationService.clearCache())
  ///   2. Re-translate all raw API data
  ///   3. Call notifyListeners()
  void bindLocaleRetranslation(
      Listenable settingsViewModel,
      Future<void> Function() retranslate,
      ) {
    unbindLocaleRetranslation();
    _localeListenable = settingsViewModel;
    _localeListener = () async {
      AppTranslationService.clearCache();
      await retranslate();
    };
    settingsViewModel.addListener(_localeListener!);
  }

  /// Call this from the ViewModel dispose() method.
  void unbindLocaleRetranslation() {
    if (_localeListenable != null && _localeListener != null) {
      _localeListenable!.removeListener(_localeListener!);
    }
    _localeListenable = null;
    _localeListener = null;
  }

  // ── Core wrappers (SessionService locale — for ViewModels) ────────────────

  Future<String> t(String text) =>
      AppTranslationService.localizedText(text);

  Future<String?> tNullable(String? text) =>
      AppTranslationService.localizedTextNullable(text);

  Future<String> tStatus(String status) =>
      AppTranslationService.localizedStatus(status);

  Future<List<String>> tAll(List<String> texts) =>
      AppTranslationService.localizedAll(texts);

  // ── Widget-tree locale wrappers (preferred in didChangeDependencies) ───────

  /// Use these "ForLang" variants when you have the language code from
  /// `Localizations.localeOf(context).languageCode` — they skip the async
  /// SessionService call and always reflect the current live locale.
  Future<String> tForLang(String text, String languageCode) =>
      AppTranslationService.localizedTextForLanguage(text, languageCode);

  Future<String?> tNullableForLang(String? text, String languageCode) =>
      AppTranslationService.localizedTextNullableForLanguage(text, languageCode);

  Future<String> tStatusForLang(String status, String languageCode) =>
      AppTranslationService.localizedStatusForLanguage(status, languageCode);

  Future<List<String>> tAllForLang(List<String> texts, String languageCode) =>
      AppTranslationService.localizedAllForLanguage(texts, languageCode);

  // ── Domain helpers ────────────────────────────────────────────────────────

  /// Translates branch / cashier / officer fields of a dynamic request list.
  Future<List<RequestTranslated>> translateRequests(
      List<dynamic> rawRequests,
      ) async {
    return Future.wait(rawRequests.map((r) => _translateRequest(r)));
  }

  Future<RequestTranslated> _translateRequest(dynamic req) async {
    final branchName  = await t(req.branchName  as String);
    final cashierName = await t(req.cashierName as String);
    final officerName = await tNullable(req.assignedOfficerName as String?);

    return RequestTranslated(
      branchName:           branchName,
      cashierName:          cashierName,
      assignedOfficerName:  officerName,
    );
  }

  /// Translates a branch name coming from the API.
  Future<String> tBranch(String name) => t(name);

  /// Translates a cashier / officer display name.
  Future<String> tPerson(String name) => t(name);

  /// Translates free-text notes entered by a cashier / officer.
  Future<String?> tNotes(String? notes) => tNullable(notes);

  /// Translates a UI status label (e.g. "Awaiting Approval", "overdue").
  Future<String> tUiStatus(String label) => tStatus(label);

  /// Batch-translates a map of display fields.
  Future<Map<String, String>> tDetailFields(Map<String, String> fields) async {
    final keys   = fields.keys.toList();
    final values = await tAll(fields.values.toList());
    return Map.fromIterables(keys, values);
  }

  /// Translates a user / person display name (e.g. welcome header).
  Future<String?> translateUserName(String? name) async {
    if (name == null) return null;
    return t(name);
  }

  /// Translates an accounting party name (vendor, customer, employee).
  Future<String> tParty(String partyName) => t(partyName);

  /// Translates a reference string — skips translation for reference codes
  /// like "INV-001" or "REF#2024" that should stay unchanged.
  Future<String> tReference(String ref) async {
    final isCode = RegExp(r'^[A-Z0-9#\-_/]+$').hasMatch(ref.trim());
    if (isCode) return ref;
    return t(ref);
  }

  /// Translates branch name/location returned by API/database.
  Future<Branch> translateBranch(Branch branch) async {
    return branch.copyWith(
      translatedName:     await tBranch(branch.name),
      translatedLocation: await t(branch.location),
    );
  }

  /// Translates a list of branches without mutating raw API data.
  Future<List<Branch>> translateBranches(List<Branch> branches) async {
    return Future.wait(branches.map(translateBranch));
  }

  /// Translates all dynamic display fields on a petty-cash request.
  Future<PettyCashRequestItem> translatePettyCashRequest(
      PettyCashRequestItem request,
      ) async {
    return request.copyWith(
      translatedPartyName:       await tNullable(request.partyName),
      translatedBranchName:      await tBranch(request.branchName),
      translatedCashierName:     await tPerson(request.cashierName),
      translatedStatus:          await tUiStatus(request.status),
      //  translatedReason:          await tNotes(request.reason),
      //  translatedCategoryLabel:   await tNullable(request.categoryLabel),
      // translatedEmployeeName:    await tNullable(request.employeeName),
      // translatedRejectionReason: await tNullable(request.rejectionReason),
    );
  }

  /// Translates a list of petty-cash requests without mutating raw API data.
  Future<List<PettyCashRequestItem>> translatePettyCashRequests(
      List<PettyCashRequestItem> requests,
      ) async {
    return Future.wait(requests.map(translatePettyCashRequest));
  }
}

// ── Type aliases for backward-compatibility ───────────────────────────────────
typedef LockerTranslatableMixin = TranslatableMixin;
typedef LockerTranslationMixin  = TranslatableMixin;