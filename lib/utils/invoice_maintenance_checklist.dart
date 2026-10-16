import '../models/create_invoice_model.dart';

/// Same 6 bilingual items as printed on cashier [InvoiceDialog] checklist table
/// (`pos_widgets` PDF-style layout — left lane = rows `0–2`, right = `3–5`).
abstract final class InvoiceMaintenanceChecklist {
  const InvoiceMaintenanceChecklist._();

  static const List<({String en, String ar})> rows = <({String en, String ar})>[
    (en: 'Tire Pressure Check', ar: 'فحص هواء الاطارات'),
    (en: 'Brake Fluid Check', ar: 'فحص سائل الفرامل'),
    (en: 'Wipers Fluid Check', ar: 'فحص سائل المساحات'),
    (en: 'Power Steering Fluid Check', ar: 'فحص سائل المقود'),
    (en: 'Transmission Fluid Check', ar: 'فحص سائل نقل الحركة'),
    (en: 'Radiator Fluid Check', ar: 'فحص سائل مبرد المحرك'),
  ];

  static int get laneRowCount => 3;

  static ({String en, String ar}) cell(int tableRowIndex, {required bool leftColumn}) =>
      rows[tableRowIndex + (leftColumn ? 0 : 3)];

  /// From API [invoice.maintenanceChecklistChecks] when valid; else valid [fallback].
  /// Otherwise `null` (caller should treat as “no checklist payload”).
  static List<bool>? resolvedChecks(
    Invoice invoice, [
    List<bool>? fallback,
  ]) {
    final m = invoice.maintenanceChecklistChecks;
    if (m != null && m.length == rows.length) return List<bool>.from(m);
    if (fallback != null && fallback.length == rows.length) {
      return List<bool>.from(fallback);
    }
    return null;
  }

  /// All [rows] for UI dialogs — unchecked when no payload (always length 6).
  static List<bool> displayChecks(
    Invoice invoice, [
    List<bool>? fallback,
  ]) {
    return resolvedChecks(invoice, fallback) ??
        List<bool>.filled(rows.length, false);
  }

  static bool hasAnyChecked(List<bool> checks) => checks.any((v) => v);

  /// Saved checklist with at least one tick; `null` = omit from print / WhatsApp.
  static List<bool>? checksForReceipt(
    Invoice invoice, [
    List<bool>? fallback,
  ]) {
    final c = resolvedChecks(invoice, fallback);
    if (c == null || !hasAnyChecked(c)) return null;
    return c;
  }

  /// Indices of checked rows only (for thermal / PDF line lists).
  static List<int> checkedRowIndices(List<bool> checks) {
    final out = <int>[];
    for (var i = 0; i < rows.length && i < checks.length; i++) {
      if (checks[i]) out.add(i);
    }
    return out;
  }
}
