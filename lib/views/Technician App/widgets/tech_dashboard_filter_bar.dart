import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/riyadh_business_range.dart';

class TechDashboardOverlapFilters extends StatelessWidget {
  const TechDashboardOverlapFilters({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.dateOnly = false,
    this.trailing,
  });

  final DateTime startDate;
  final DateTime endDate;
  final Future<void> Function(DateTime date) onStartDateChanged;
  final Future<void> Function(DateTime date) onEndDateChanged;
  /// When true, only a calendar date is picked (no time picker / time label).
  final bool dateOnly;
  final Widget? trailing;

  static DateFormat _dateFormatFor(BuildContext context) =>
      DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString());

  static DateFormat _timeFormatFor(BuildContext context) =>
      DateFormat('hh:mm a', Localizations.localeOf(context).toString());

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickStart(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: _dateOnly(endDate),
    );
    if (pickedDate == null) return;

    if (dateOnly) {
      var combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      final endDay = _dateOnly(endDate);
      if (combined.isAfter(endDay)) combined = endDay;
      await onStartDateChanged(combined);
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startDate),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (pickedTime == null) return;

    var combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (combined.isAfter(endDate)) {
      combined = endDate;
    }
    await onStartDateChanged(combined);
  }

  Future<void> _pickEnd(BuildContext context) async {
    // Picker values are Asia/Riyadh wall clock (matches web / API encoding).
    final now = riyadhNowWall();
    final latestDay = _dateOnly(now);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate.isBefore(startDate) ? startDate : endDate,
      firstDate: _dateOnly(startDate),
      lastDate: latestDay,
    );
    if (pickedDate == null) return;

    if (dateOnly) {
      var combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      final startDay = _dateOnly(startDate);
      if (combined.isBefore(startDay)) combined = startDay;
      if (combined.isAfter(latestDay)) combined = latestDay;
      await onEndDateChanged(combined);
      return;
    }

    final initialTime = _dateOnly(pickedDate) == latestDay
        ? TimeOfDay.fromDateTime(now)
        : TimeOfDay.fromDateTime(endDate);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (pickedTime == null) return;

    var combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // Keep the time the user picked (including 12:00 AM). Do not rewrite
    // midnight to "now" / end-of-day — that blocked matching start/end times.
    if (combined.isBefore(startDate)) {
      combined = startDate;
    }
    if (combined.isAfter(now)) {
      combined = now;
    }
    await onEndDateChanged(combined);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _overlapContainer(
              child: _dateTimeField(
                context,
                label: dateOnly
                    ? AppLocalizations.of(context)!.ownerCommonStartDate
                    : null,
                value: startDate,
                onTap: () => _pickStart(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _overlapContainer(
              child: _dateTimeField(
                context,
                label: dateOnly
                    ? AppLocalizations.of(context)!.ownerCommonEndDate
                    : null,
                value: endDate,
                onTap: () => _pickEnd(context),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _overlapContainer({required Widget child}) {
    return Container(
      height: dateOnly ? 56 : 62,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dateTimeField(
    BuildContext context, {
    String? label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null) ...[
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.secondaryLight.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              TechDashboardOverlapFilters._dateFormatFor(context).format(value),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w700,
                fontSize: dateOnly ? 13 : 13,
                height: 1.2,
              ),
            ),
            if (!dateOnly) ...[
              const SizedBox(height: 5),
              Text(
                TechDashboardOverlapFilters._timeFormatFor(context).format(value),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.secondaryLight.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
