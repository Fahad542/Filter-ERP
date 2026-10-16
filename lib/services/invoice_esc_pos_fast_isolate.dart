import 'dart:isolate';

import 'package:flutter/services.dart';

import '../models/create_invoice_model.dart';
import 'invoice_thermal_escpos.dart';

/// Builds receipt ESC/POS off the UI thread (no PDF raster).
Future<List<int>> buildInvoiceEscPosBytesIsolate({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  required RootIsolateToken rootToken,
}) {
  return Isolate.run(
    () => _buildOnBackground(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecksFallback: maintenanceChecksFallback,
      rootToken: rootToken,
    ),
  );
}

Future<List<int>> _buildOnBackground({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  required RootIsolateToken rootToken,
}) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
  return buildInvoiceEscPosBytes(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
}
