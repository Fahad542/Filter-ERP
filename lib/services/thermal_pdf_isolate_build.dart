import 'dart:isolate';

import 'package:flutter/services.dart';

import '../models/create_invoice_model.dart';
import '../models/store_closing_model.dart';
import '../widgets/thermal_invoice_pdf.dart';
import '../widgets/thermal_store_closing_pdf.dart';
import 'thermal_pdf_asset_loader.dart';

/// Thermal invoice PDF on a background isolate (Noto Arabic fonts, same layout).
///
/// Brand logo + Noto Sans Arabic font bytes are preloaded on the **main
/// isolate** via [loadThermalPdfAssetsOnMainIsolate] before spawning the
/// worker — the worker never calls `rootBundle.load` or `AssetManifest`
/// (which are not available without a full `WidgetsFlutterBinding`).
Future<Uint8List> buildThermalInvoicePdfBytesInIsolate({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) async {
  final assets = await loadThermalPdfAssetsOnMainIsolate();

  final rootToken = RootIsolateToken.instance;
  if (rootToken == null) {
    return buildThermalInvoicePdfBytes(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecksFallback: maintenanceChecksFallback,
      preloadedAssets: assets,
    );
  }

  return Isolate.run(
    () => _invoicePdfInWorker(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecksFallback: maintenanceChecksFallback,
      rootToken: rootToken,
      preloadedAssets: assets,
    ),
  );
}

Future<Uint8List> buildThermalStoreClosingPdfBytesInIsolate({
  required StoreClosingReport report,
  String? closingId,
}) async {
  final assets = await loadThermalPdfAssetsOnMainIsolate();

  final rootToken = RootIsolateToken.instance;
  if (rootToken == null) {
    return buildThermalStoreClosingPdfBytes(
      report: report,
      closingId: closingId,
      preloadedAssets: assets,
    );
  }

  return Isolate.run(
    () => _storeClosingPdfInWorker(
      report: report,
      closingId: closingId,
      rootToken: rootToken,
      preloadedAssets: assets,
    ),
  );
}

Future<Uint8List> _invoicePdfInWorker({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  required RootIsolateToken rootToken,
  required ThermalPdfAssetBytes preloadedAssets,
}) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
  return buildThermalInvoicePdfBytes(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
    preloadedAssets: preloadedAssets,
  );
}

Future<Uint8List> _storeClosingPdfInWorker({
  required StoreClosingReport report,
  String? closingId,
  required RootIsolateToken rootToken,
  required ThermalPdfAssetBytes preloadedAssets,
}) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
  return buildThermalStoreClosingPdfBytes(
    report: report,
    closingId: closingId,
    preloadedAssets: preloadedAssets,
  );
}
