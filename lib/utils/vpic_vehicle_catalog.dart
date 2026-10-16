import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_logger.dart';

/// NHTSA vPIC public API — same source as Add Customer make/model lookup.
abstract final class VpicVehicleCatalog {
  static const String _baseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles';

  static Future<Map<String, dynamic>?> _getVehicleJson(Uri uri) async {
    try {
      ApiLogger.request('GET', uri.toString());
      final res = await http.get(uri);
      ApiLogger.response(
        res.statusCode,
        uri.toString(),
        method: 'GET',
        body: res.body,
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final raw = res.body.trim();
      if (raw.isEmpty) return null;

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        final start = raw.indexOf('{');
        final end = raw.lastIndexOf('}');
        if (start == -1 || end == -1 || end <= start) return null;
        decoded = jsonDecode(raw.substring(start, end + 1));
      }
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// All manufacturer names from vPIC (sorted, de-duplicated).
  static Future<List<String>> fetchAllMakes() async {
    final uri = Uri.parse('$_baseUrl/getallmakes?format=json');
    final json = await _getVehicleJson(uri);
    final rawMakes = (json?['Results'] as List?) ?? const [];
    final fetched = rawMakes
        .map((e) => (e as Map?)?['Make_Name']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return fetched;
  }

  /// Models for a given make name (sorted, de-duplicated).
  static Future<List<String>> fetchModelsForMake(String make) async {
    final key = make.trim();
    if (key.isEmpty) return const [];
    final uri = Uri.parse(
      '$_baseUrl/GetModelsForMake/${Uri.encodeComponent(key)}?format=json',
    );
    final json = await _getVehicleJson(uri);
    final rawModels = (json?['Results'] as List?) ?? const [];
    final fetched = rawModels
        .map((e) => (e as Map?)?['Model_Name']?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return fetched;
  }
}
