import 'package:shared_preferences/shared_preferences.dart';

import '../data/network/api_constants.dart';

/// Direct Bevatel Chat developer API credentials.
///
/// Defaults are **embedded** below so cashiers never open a settings dialog.
/// Override at build time:
/// ```text
/// --dart-define=BEVATEL_API_ACCESS_TOKEN=...
/// --dart-define=BEVATEL_API_ACCOUNT_ID=...
/// ```
/// Or paste the access token into [embeddedAccessToken] before shipping.
abstract final class BevatelChatCredentials {
  static const prefAccountId = 'bevatel_chat_api_account_id';
  static const prefAccessToken = 'bevatel_chat_api_access_token';
  static const prefInboxId = 'bevatel_chat_whatsapp_inbox_id';
  static const prefTemplateName = 'bevatel_chat_template_name';
  static const prefTemplateLanguage = 'bevatel_chat_template_language';
  static const prefSendInvoicePdf = 'bevatel_send_invoice_as_pdf';
  static const prefPdfCaptionLines = 'bevatel_pdf_include_caption_lines';
  static const prefPdfUploadUrl = 'bevatel_pdf_custom_upload_post_url';

  /// WhatsApp Manager **Category** column values — not the API template **Name** (e.g. test4).
  static bool templateNameLooksLikeMetaCategory(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'MARKETING':
      case 'UTILITY':
      case 'AUTHENTICATION':
        return true;
      default:
        return false;
    }
  }

  static const String accountIdEnv =
      String.fromEnvironment('BEVATEL_API_ACCOUNT_ID', defaultValue: '');
  static const String accessTokenEnv =
      String.fromEnvironment('BEVATEL_API_ACCESS_TOKEN', defaultValue: '');
  static const String inboxIdEnv =
      String.fromEnvironment('BEVATEL_WHATSAPP_INBOX_ID', defaultValue: '');
  static const String templateNameEnv =
      String.fromEnvironment('BEVATEL_WHATSAPP_TEMPLATE_NAME', defaultValue: '');
  static const String templateLanguageEnv =
      String.fromEnvironment('BEVATEL_WHATSAPP_TEMPLATE_LANGUAGE', defaultValue: '');

  static const String pdfUploadUrlEnv =
      String.fromEnvironment('BEVATEL_PDF_UPLOAD_URL', defaultValue: '');

  static const bool sendInvoicePdfEnv =
      bool.fromEnvironment('BEVATEL_SEND_INVOICE_AS_PDF', defaultValue: true);
  static const bool pdfCaptionLinesEnv =
      bool.fromEnvironment('BEVATEL_PDF_INCLUDE_CAPTION_LINES', defaultValue: false);

  // ── Embedded app defaults (no UI) ───────────────────────────────────────────

  static const String embeddedAccountId = '39044';
  static const String embeddedInboxId = '104571';
  static const String embeddedTemplateName = 'test4';
  static const String embeddedTemplateLanguage = '';
  /// The access token is no longer embedded in the Flutter app — it now lives
  /// on the NestJS backend (`BEVATEL_ACCESS_TOKEN`), which exposes
  /// `POST /cashier/invoice/:invoiceId/whatsapp-send`. This constant is kept
  /// only so the legacy direct-call path (`BevatelDeveloperWhatsappService`)
  /// still compiles; it is no longer invoked from `InvoiceAutoDispatch`.
  /// **Do not** re-embed the token here — rotate it in Bevatel dashboard.
  static const String embeddedAccessToken = '';

  /// Resolution order: **dart-define → embedded constant → SharedPreferences** (legacy).
  static String _pick(
    String env,
    SharedPreferences p,
    String prefKey,
    String baked,
  ) {
    final e = env.trim();
    if (e.isNotEmpty) return e;
    final b = baked.trim();
    if (b.isNotEmpty) return b;
    return p.getString(prefKey)?.trim() ?? '';
  }

  static Future<
      ({
        String accountId,
        String accessToken,
        String inboxId,
        String templateName,
        String templateLanguage,
        bool sendInvoicePdf,
        bool pdfIncludeCaptionLines,
        String pdfCustomUploadPostUrl,
      })?> resolve() async {
    final p = await SharedPreferences.getInstance();

    final aid = _pick(accountIdEnv, p, prefAccountId, embeddedAccountId);
    final tok = _pick(accessTokenEnv, p, prefAccessToken, embeddedAccessToken);
    final inbox = _pick(inboxIdEnv, p, prefInboxId, embeddedInboxId);

    var tname = templateNameEnv.trim();
    if (tname.isEmpty) tname = embeddedTemplateName.trim();
    if (tname.isEmpty) tname = p.getString(prefTemplateName)?.trim() ?? '';

    var tlang = templateLanguageEnv.trim();
    if (tlang.isEmpty) tlang = embeddedTemplateLanguage.trim();
    if (tlang.isEmpty) tlang = p.getString(prefTemplateLanguage)?.trim() ?? '';
    if (tlang.isEmpty) tlang = 'en';

    final apiDefault = ApiConstants.cashierInvoicePdfUploadUrl;
    var pdfUp = pdfUploadUrlEnv.trim();
    if (pdfUp.isEmpty) pdfUp = p.getString(prefPdfUploadUrl)?.trim() ?? '';
    if (pdfUp.isNotEmpty && !_uploadUrlMatchesApiHost(pdfUp, apiDefault)) {
      pdfUp = '';
      await p.remove(prefPdfUploadUrl);
    }
    if (pdfUp.isEmpty) pdfUp = apiDefault;

    final sendPdf = p.getBool(prefSendInvoicePdf) ??
        sendInvoicePdfEnv;
    final pdfCaption = p.getBool(prefPdfCaptionLines) ??
        pdfCaptionLinesEnv;

    if (aid.isEmpty || tok.isEmpty || inbox.isEmpty) return null;

    return (
      accountId: aid,
      accessToken: tok,
      inboxId: inbox,
      templateName: tname,
      templateLanguage: tlang,
      sendInvoicePdf: sendPdf,
      pdfIncludeCaptionLines: pdfCaption,
      pdfCustomUploadPostUrl: pdfUp,
    );
  }

  static bool _uploadUrlMatchesApiHost(String uploadUrl, String apiBase) {
    final u = Uri.tryParse(uploadUrl.trim());
    final a = Uri.tryParse(apiBase.trim());
    if (u == null || a == null) return false;
    return u.host == a.host && u.port == a.port;
  }

  static Future<void> save({
    required String accountId,
    required String accessToken,
    required String inboxId,
    required String templateName,
    String templateLanguage = 'en',
    bool sendInvoicePdf = true,
    bool pdfIncludeCaptionLines = false,
    String pdfCustomUploadPostUrl = '',
  }) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(prefAccountId, accountId.trim());
    await pref.setString(prefAccessToken, accessToken.trim());
    await pref.setString(prefInboxId, inboxId.trim());
    await pref.setString(prefTemplateName, templateName.trim());
    await pref.setString(prefTemplateLanguage, templateLanguage.trim());
    await pref.setBool(prefSendInvoicePdf, sendInvoicePdf);
    await pref.setBool(prefPdfCaptionLines, pdfIncludeCaptionLines);
    await pref.setString(prefPdfUploadUrl, pdfCustomUploadPostUrl.trim());
  }
}
