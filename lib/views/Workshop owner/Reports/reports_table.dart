import 'package:flutter/material.dart';

/// A unified table widget that renders a sticky header + data rows
/// inside a single rounded card — no visual gap between header and rows.
///
/// Usage:
/// ```dart
/// ReportsTable(
///   columns: ['NAME', 'ORDERS', 'REVENUE (SAR)'],
///   rows: items.map((i) => [Text(i.name), Text('${i.orders}'), Text('SAR ${i.revenue}')]).toList(),
///   emptyWidget: _EmptyState(message: 'No data'),
/// )
/// ```
class ReportsTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final Widget? emptyWidget;
  final void Function(int index)? onRowTap;
  /// Optional flex weights per column (defaults to 1 each).
  final List<int>? columnFlex;
  /// Optional text/cell alignment per column (defaults: start, last → end).
  final List<Alignment>? columnAlignments;

  const ReportsTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyWidget,
    this.onRowTap,
    this.columnFlex,
    this.columnAlignments,
  });

  int _flexFor(int index) {
    final flexes = columnFlex;
    if (flexes == null || index < 0 || index >= flexes.length) return 1;
    return flexes[index].clamp(1, 100);
  }

  Alignment _alignFor(int index, {required bool isLast}) {
    final aligns = columnAlignments;
    if (aligns != null && index >= 0 && index < aligns.length) {
      return aligns[index];
    }
    return isLast ? Alignment.centerRight : Alignment.centerLeft;
  }

  TextAlign _textAlignFor(Alignment alignment) {
    if (alignment == Alignment.centerRight ||
        alignment == Alignment.topRight ||
        alignment == Alignment.bottomRight) {
      return TextAlign.end;
    }
    if (alignment == Alignment.center ||
        alignment == Alignment.topCenter ||
        alignment == Alignment.bottomCenter) {
      return TextAlign.center;
    }
    return TextAlign.start;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: columns.asMap().entries.map((e) {
                final isLast = e.key == columns.length - 1;
                final align = _alignFor(e.key, isLast: isLast);
                return Expanded(
                  flex: _flexFor(e.key),
                  child: Text(
                    e.value,
                    textAlign: _textAlignFor(align),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Rows or empty state ─────────────────────────────────────────────
          if (rows.isEmpty && emptyWidget != null)
            emptyWidget!
          else
            ...rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              final rowBody = Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.07),
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: entry.value.asMap().entries.map((e) {
                    final isLastCell = e.key == entry.value.length - 1;
                    final align = _alignFor(e.key, isLast: isLastCell);
                    return Expanded(
                      flex: _flexFor(e.key),
                      child: Align(
                        alignment: align,
                        child: e.value,
                      ),
                    );
                  }).toList(),
                ),
              );
              if (onRowTap == null) return rowBody;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onRowTap!(entry.key),
                  child: rowBody,
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keep legacy widgets for backward compatibility during migration
// ─────────────────────────────────────────────────────────────────────────────

/// @deprecated Use [ReportsTable] instead.
class ReportsTableHeader extends StatelessWidget {
  final List<String> columns;

  const ReportsTableHeader({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: columns.asMap().entries.map((e) {
          final isLast = e.key == columns.length - 1;
          return Expanded(
            child: Text(
              e.value,
              textAlign: isLast ? TextAlign.end : TextAlign.start,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// @deprecated Use [ReportsTable] instead.
class ReportsTableRow extends StatelessWidget {
  final List<Widget> cells;
  final Color? borderColor;

  const ReportsTableRow({
    super.key,
    required this.cells,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: borderColor ?? Colors.grey.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: cells.asMap().entries.map((e) {
          final isLast = e.key == cells.length - 1;
          return Expanded(
            child: Align(
              alignment:
                  isLast ? Alignment.centerRight : Alignment.centerLeft,
              child: e.value,
            ),
          );
        }).toList(),
      ),
    );
  }
}
