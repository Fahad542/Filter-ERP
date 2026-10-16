import 'dart:isolate';

import 'package:flutter/services.dart';

import '../models/store_closing_model.dart';
import 'thermal_store_closing_escpos.dart';

Future<List<int>> buildStoreClosingEscPosBytesIsolate({
  required StoreClosingReport report,
  String? closingId,
  required RootIsolateToken rootToken,
}) {
  return Isolate.run(
    () => _buildOnBackground(
      report: report,
      closingId: closingId,
      rootToken: rootToken,
    ),
  );
}

Future<List<int>> _buildOnBackground({
  required StoreClosingReport report,
  String? closingId,
  required RootIsolateToken rootToken,
}) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
  return buildStoreClosingEscPosBytes(
    report: report,
    closingId: closingId,
  );
}
