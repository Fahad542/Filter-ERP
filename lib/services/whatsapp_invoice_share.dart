import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_formatters.dart';

/// Which installed WhatsApp client to open for a share deeplink.
enum WhatsAppClientApp {
  personal,
  business,
}

/// Sends / opens the cashier invoice for WhatsApp (file share or link chat).
abstract final class WhatsappInvoiceShare {
  WhatsappInvoiceShare._();

  static const _channel = MethodChannel('com.filter_erp.app/whatsapp_share');

  /// Digits WhatsApp expects (`9665…`).
  static String? phoneDigits(String? raw) {
    final saudi = normalizeSaudiMobileTo966Digits(raw);
    if (saudi != null) return saudi;
    final d = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length < 8 || d.length > 15) return null;
    return d;
  }

  /// Prefer Dart [Directory.systemTemp] — avoids `path_provider` → `objective_c`
  /// FFI crashes on some iOS Simulator / Flutter SDK combos (`DOBJC_initializeApi`).
  static Directory _invoiceTempDir() {
    final folder = Directory('${Directory.systemTemp.path}/whatsapp_invoices');
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return folder;
  }

  /// Android opens that number's WhatsApp chat with this PDF attached.
  /// Other platforms share the PDF file itself (never a web link).
  static Future<bool> shareDownloadedPdf({
    required Uint8List bytes,
    required String filename,
    required String? phoneRaw,
  }) async {
    final safe = filename.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final file = File('${_invoiceTempDir().path}/$safe');
    await file.writeAsBytes(bytes, flush: true);

    final digits = phoneDigits(phoneRaw);
    if (Platform.isAndroid && digits != null) {
      try {
        final opened = await _channel.invokeMethod<bool>('sharePdf', {
          'path': file.path,
          'phone': digits,
        });
        if (opened == true) return true;
      } catch (_) {}
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: safe,
          ),
        ],
        fileNameOverrides: [safe],
      ),
    );
    return true;
  }

  /// Opens the selected WhatsApp app with [phoneRaw]'s chat and [message] pre-filled.
  /// Never falls back from Business → personal (or vice versa).
  static Future<bool> openCustomerChatWithMessage({
    required String? phoneRaw,
    required String message,
    required WhatsAppClientApp app,
  }) async {
    final digits = phoneDigits(phoneRaw);
    if (digits == null) {
      throw StateError('Customer does not have a valid WhatsApp / mobile number');
    }
    final text = message.trim();
    if (text.isEmpty) {
      throw StateError('Message is empty');
    }

    final business = app == WhatsAppClientApp.business;

    // Android: pin Intent to com.whatsapp or com.whatsapp.w4b.
    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>('openChat', {
          'phone': digits,
          'text': text,
          'business': business,
        });
        if (opened == true) return true;
      } on PlatformException {
        return false;
      } catch (_) {
        return false;
      }
      return false;
    }

    // iOS: use the matching URL scheme only — no wa.me fallback (that opens
    // whichever WhatsApp is the default / personal).
    final encoded = Uri.encodeComponent(text);
    final schemeUri = business
        ? Uri.parse('whatsapp-business://send?phone=$digits&text=$encoded')
        : Uri.parse('whatsapp://send?phone=$digits&text=$encoded');

    try {
      // Prefer launching even if canLaunchUrl is false — iOS sometimes lies
      // about custom schemes; only the matching scheme is attempted.
      final ok = await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}

    if (await canLaunchUrl(schemeUri)) {
      return launchUrl(schemeUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
