import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';

/// Month + year picker row for technician KPI / commission screens.
class TechMonthFilterBar extends StatelessWidget {
  const TechMonthFilterBar({
    super.key,
    required this.month,
    required this.year,
    required this.onChanged,
    this.onApply,
    this.isLoading = false,
    this.title,
    this.showApply = true,
  });

  final int month;
  final int year;
  final void Function(int month, int year) onChanged;
  final VoidCallback? onApply;
  final bool isLoading;
  final String? title;
  final bool showApply;

  static List<String> _monthLabels(AppLocalizations l10n) => [
        l10n.techMonthJan,
        l10n.techMonthFeb,
        l10n.techMonthMar,
        l10n.techMonthApr,
        l10n.techMonthMay,
        l10n.techMonthJun,
        l10n.techMonthJul,
        l10n.techMonthAug,
        l10n.techMonthSep,
        l10n.techMonthOct,
        l10n.techMonthNov,
        l10n.techMonthDec,
      ];

  static List<int> get yearChoices {
    final now = DateTime.now().year;
    return List<int>.generate(6, (i) => now - i);
  }

  static List<int> get _yearChoices => yearChoices;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthLabels = _monthLabels(l10n);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title ?? l10n.techMonthTitle,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  value: month,
                  items: List.generate(12, (i) {
                    final m = i + 1;
                    return DropdownMenuItem(
                      value: m,
                      child: Text(monthLabels[i]),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) onChanged(v, year);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown<int>(
                  value: _yearChoices.contains(year) ? year : _yearChoices.first,
                  items: _yearChoices
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(month, v);
                  },
                ),
              ),
              if (showApply) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 84,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.techMonthApply,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade600),
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  static String monthYearLabel(int month, int year, [Locale? locale]) {
    if (month < 1 || month > 12) return year.toString();
    return '${DateFormat('MMMM', locale?.toString()).format(DateTime(year, month))} $year';
  }
}
