import '../models/create_invoice_model.dart';
import 'thermal_safe_text.dart';

class ThermalTechnicianCommissionRow {
  const ThermalTechnicianCommissionRow({
    required this.technicianName,
    required this.departmentName,
    required this.commissionAmount,
    required this.commissionPercent,
  });

  final String technicianName;
  final String departmentName;
  final double commissionAmount;
  final double commissionPercent;
}

List<ThermalTechnicianCommissionRow> thermalTechnicianCommissionRowsFromInvoice(
  Invoice invoice,
) {
  final rows = <ThermalTechnicianCommissionRow>[];
  for (final dept in invoice.departments) {
    for (final c in dept.commissions) {
      final name = c.technicianName.trim();
      if (name.isEmpty) continue;
      rows.add(
        ThermalTechnicianCommissionRow(
          technicianName: name,
          departmentName: dept.departmentName.trim(),
          commissionAmount: c.commissionAmount,
          commissionPercent: c.commissionPercent,
        ),
      );
    }
  }
  rows.sort((a, b) {
    final deptCmp = a.departmentName.toLowerCase().compareTo(
          b.departmentName.toLowerCase(),
        );
    if (deptCmp != 0) return deptCmp;
    return a.technicianName.toLowerCase().compareTo(b.technicianName.toLowerCase());
  });
  return rows;
}

String thermalFmtCommissionPercent(double p) {
  if (p <= 0) return '—';
  final text =
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
  return '$text%';
}

String technicianNamesCsvFromInvoice(Invoice invoice) {
  return technicianNamesFromInvoice(invoice).join(', ');
}

/// Plain comma-separated names for thermal/PDF (no table cells or bidi marks).
String technicianNamesPlainCsvFromInvoice(Invoice invoice) {
  return technicianNamesFromInvoice(invoice)
      .map(pdfStripBidiAndInvisible)
      .where((n) => n.isNotEmpty)
      .join(', ');
}

/// Unique technician names for invoice receipts (digital + thermal).
List<String> technicianNamesFromInvoice(Invoice invoice) {
  final names = <String>{};
  for (final dept in invoice.departments) {
    for (final c in dept.commissions) {
      final name = c.technicianName.trim();
      if (name.isNotEmpty) names.add(name);
    }
  }
  final list = names.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}
