import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class ReusableTableColumn {
  final String key;
  final String title;
  final double width;
  final Alignment alignment;

  const ReusableTableColumn({
    required this.key,
    required this.title,
    required this.width,
    this.alignment = Alignment.centerLeft,
  });
}

class ReusableDataTable<T> extends StatelessWidget {
  final List<T> items;
  final List<ReusableTableColumn> columns;
  final List<Widget> Function(BuildContext context, T item, int index) rowBuilder;
  final String emptyMessage;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsets headerPadding;
  final EdgeInsets rowPadding;
  final Color headerBackgroundColor;
  final Color headerTextColor;
  final Color tableBackgroundColor;
  final Color borderColor;
  final Color dividerColor;
  final double borderRadius;
  final double minWidth;
  final Color Function(T item, int index)? rowColorBuilder;
  final VoidCallback? Function(T item, int index)? onRowTapBuilder;

  const ReusableDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    this.emptyMessage = 'No data found',
    this.outerPadding = const EdgeInsets.fromLTRB(12, 8, 12, 100),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.rowPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.headerBackgroundColor = AppColors.secondaryLight,
    this.headerTextColor = Colors.white,
    this.tableBackgroundColor = Colors.white,
    this.borderColor = const Color(0x1F9E9E9E),
    this.dividerColor = const Color(0xFFEEEEEE),
    this.borderRadius = 16,
    this.minWidth = 400,
    this.rowColorBuilder,
    this.onRowTapBuilder,
  });

  double get _tableWidth {
    final columnsTotal = columns.fold<double>(0, (sum, c) => sum + c.width);
    // The Row sits inside a padded Container, so _tableWidth must absorb
    // that padding; otherwise the columns overflow the available inner space.
    final maxHPad = headerPadding.horizontal > rowPadding.horizontal
        ? headerPadding.horizontal
        : rowPadding.horizontal;
    final total = columnsTotal + maxHPad;
    return total < minWidth ? minWidth : total;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: outerPadding,
        child: _TableShell(
          borderRadius: borderRadius,
          borderColor: borderColor,
          backgroundColor: tableBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                emptyMessage,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: outerPadding,
      child: _TableShell(
        borderRadius: borderRadius,
        borderColor: borderColor,
        backgroundColor: tableBackgroundColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: headerBackgroundColor,
                    padding: headerPadding,
                    child: Row(
                      children: columns.map((column) {
                        return SizedBox(
                          width: column.width,
                          child: Align(
                            alignment: column.alignment,
                            child: Text(
                              column.title,
                              style: TextStyle(
                                color: headerTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(height: 1, color: dividerColor),
                  ...items.asMap().entries.expand((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final rowCells = rowBuilder(context, item, index);
                    final row = InkWell(
                      onTap: onRowTapBuilder?.call(item, index),
                      child: Container(
                        color: rowColorBuilder?.call(item, index) ?? tableBackgroundColor,
                        padding: rowPadding,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(columns.length, (cellIndex) {
                            final column = columns[cellIndex];
                            final child = cellIndex < rowCells.length
                                ? rowCells[cellIndex]
                                : const SizedBox.shrink();
                            return SizedBox(
                              width: column.width,
                              child: Align(
                                alignment: column.alignment,
                                child: child,
                              ),
                            );
                          }),
                        ),
                      ),
                    );

                    return [
                      row,
                      if (index != items.length - 1)
                        Divider(height: 1, color: dividerColor),
                    ];
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReusableTableActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const ReusableTableActionButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.borderColor,
    this.icon,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 3, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;

  const _TableShell({
    required this.child,
    required this.borderRadius,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TablePill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const TablePill({
    super.key,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
