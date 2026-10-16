import 'dart:typed_data';

import '../models/store_closing_model.dart';
import 'thermal_pdf_isolate_build.dart';

/// Pre-builds store-closing thermal PDF on a background isolate after reconcile.
final class StoreClosingPrintPrefetch {
  StoreClosingPrintPrefetch._();

  static final Map<String, _PrefetchEntry> _byKey = {};

  static String _cacheKey(StoreClosingReport report, String? closingId) =>
      '${closingId ?? report.id}_${report.timestamp.millisecondsSinceEpoch}';

  static void start({
    required StoreClosingReport report,
    String? closingId,
  }) {
    final key = _cacheKey(report, closingId);
    if (_byKey.containsKey(key)) return;
    _byKey[key] = _PrefetchEntry(
      buildThermalStoreClosingPdfBytesInIsolate(
        report: report,
        closingId: closingId,
      ),
    );
  }

  static Future<Uint8List>? pdfFutureFor(
    StoreClosingReport report,
    String? closingId,
  ) {
    return _byKey[_cacheKey(report, closingId)]?.future;
  }

  static void discard(StoreClosingReport report, String? closingId) {
    _byKey.remove(_cacheKey(report, closingId));
  }

  static void discardAll() => _byKey.clear();
}

final class _PrefetchEntry {
  _PrefetchEntry(this.future);
  final Future<Uint8List> future;
}
