import 'dart:async';

import '../models/store_closing_model.dart';
import 'thermal_esc_pos_profile_warmup.dart';
import 'thermal_print_isolate_pipeline.dart';

/// Store closing thermal print on a background isolate (PDF layout when possible).
Future<List<int>> prepareStoreClosingEscPosBytes({
  required StoreClosingReport report,
  String? closingId,
}) async {
  unawaited(warmThermalEscPosCapabilityProfile());
  return prepareStoreClosingEscPosBytesOffUi(
    report: report,
    closingId: closingId,
  );
}
