import '../models/create_invoice_model.dart';
import '../models/store_closing_model.dart';
import 'thermal_print_isolate_pipeline.dart';
import 'network_thermal_printer.dart';
import 'store_closing_print_pipeline.dart';
import 'thermal_printer_settings.dart';

/// Invoice thermal print: fast ESC/POS (no PDF raster).
Future<void> executeInvoiceThermalPrint({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) async {
  final settingsFuture = ThermalPrinterSettings.load();
  final bytesFuture = prepareInvoiceEscPosBytesOffUi(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
  final cfg = await settingsFuture;
  final bytes = await bytesFuture;
  await sendEscPosBytesToTcpPrinter(
    host: cfg.host,
    port: cfg.port,
    bytes: bytes,
  );
}

/// Alias of [executeInvoiceThermalPrint] (PDF raster path).
Future<void> executeInvoiceThermalPrintRaster({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) =>
    executeInvoiceThermalPrint(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecksFallback: maintenanceChecksFallback,
    );

/// Store closing **80 mm** thermal — fast ESC/POS (no PDF raster).
Future<void> executeStoreClosingThermalPrint({
  required StoreClosingReport report,
  String? closingId,
}) async {
  final settingsFuture = ThermalPrinterSettings.load();
  final bytes = await prepareStoreClosingEscPosBytes(
    report: report,
    closingId: closingId,
  );
  if (bytes.isEmpty) {
    throw StateError('Could not prepare store closing receipt for printing.');
  }
  final cfg = await settingsFuture;
  await sendEscPosBytesToTcpPrinter(
    host: cfg.host,
    port: cfg.port,
    bytes: bytes,
  );
}
