import '../models/create_invoice_model.dart';
import '../models/store_closing_model.dart';

Future<void> executeInvoiceThermalPrint({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) async {
  throw UnsupportedError(
    'Wi‑Fi thermal printing needs Android, iOS, or desktop — not supported on web.',
  );
}

Future<void> executeStoreClosingThermalPrint({
  required StoreClosingReport report,
  String? closingId,
}) async {
  throw UnsupportedError(
    'Wi‑Fi thermal printing needs Android, iOS, or desktop — not supported on web.',
  );
}
