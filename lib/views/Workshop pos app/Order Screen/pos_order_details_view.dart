import 'package:flutter/material.dart';
import '../../../models/pos_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/plate_transliterator.dart';
import '../../../widgets/app_bar_live_clock.dart';



String _detailsPlateDisplay(BuildContext context, String raw, {bool upperCase = false}) {
  final plate = raw.trim();
  if (plate.isEmpty) return '-';
  final normalized = upperCase ? plate.toUpperCase() : plate;
  return PlateTransliterator.localize(
    normalized,
    Localizations.localeOf(context).languageCode,
  );
}

String _detailsStatusLabel(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  var s = status.trim().toLowerCase().replaceAll(' ', '_');
  if (s == 'complete') s = 'completed';
  if (s == 'job_edited') s = 'edited';
  switch (s) {
    case 'completed':
    case 'invoiced':
      return l10n.posOrdersStatusComplete;
    case 'edited':
      return l10n.posOrdersStatusEdited;
    case 'in_progress':
    case 'inprogress':
      return l10n.posOrdersStatusInProgress;
    case 'cancelled':
    case 'canceled':
      return l10n.posOrdersStatusCancelled;
    case 'rejected':
    case 'rejected_by_corporate':
      return l10n.posOrdersStatusRejected;
    default:
      return l10n.posOrdersStatusPending;
  }
}


String _detailsProductNameForLocale(BuildContext context, PosOrderJobItem item) {
  final lang = Localizations.localeOf(context).languageCode;
  final ar = item.productNameArabic.trim();
  if (lang == 'ar' && ar.isNotEmpty) return ar;
  final en = item.productName.trim();
  return en.isNotEmpty ? en : item.productId;
}

class PosOrderDetailsView extends StatelessWidget {
  final PosOrder order;

  const PosOrderDetailsView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.secondaryLight,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          l10n.posDetailsTitle,
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: filterAppBarActions(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 28 : 16,
          isTablet ? 20 : 14,
          isTablet ? 28 : 16,
          isTablet ? 32 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, isTablet),
            const SizedBox(height: 12),
            _buildSectionCard(
              isTablet: isTablet,
              title: l10n.posDetailsCustomerSection,
              icon: Icons.person_outline_rounded,
              children: [
                _infoRow(
                  l10n.posDetailsVehicleNo,
                  _detailsPlateDisplay(context, order.plateNumber),
                  isTablet,
                ),
                _infoRow(l10n.posDetailsCustomer, order.customerName, isTablet),
                _infoRow(
                  l10n.posDetailsMobile,
                  order.customer?.mobile.isNotEmpty == true
                      ? order.customer!.mobile
                      : '-',
                  isTablet,
                ),
                _infoRow(
                  l10n.posDetailsVat,
                  order.customer?.vatNumber.isNotEmpty == true
                      ? order.customer!.vatNumber
                      : '-',
                  isTablet,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              isTablet: isTablet,
              title: l10n.posDetailsVehicleSection,
              icon: Icons.directions_car_outlined,
              children: [
                _infoRow(
                  l10n.posDetailsMakeModel,
                  order.carModel.isNotEmpty ? order.carModel : '-',
                  isTablet,
                ),
                _infoRow(
                  l10n.posDetailsPlate,
                  _detailsPlateDisplay(context, order.plateNumber),
                  isTablet,
                ),
                _infoRow(l10n.posDetailsOdometer, l10n.posDetailsOdometerKm(order.odometerReading.toString()), isTablet),
              ],
            ),
            const SizedBox(height: 12),
            _buildJobsSection(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Center(
            child: Container(
              width: isTablet ? 54 : 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 14 : 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.plateNumber.isNotEmpty
                            ? _detailsPlateDisplay(context, order.plateNumber, upperCase: true)
                            : '—',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 19 : 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      LocalizedApiText(
                        () {
                          final m = order.carModel.isNotEmpty
                              ? order.carModel
                              : AppLocalizations.of(context)!.posCommonDash;
                          final c = order.customerName;
                          if (c.isNotEmpty) {
                            return '$c  •  $m';
                          }
                          return m;
                        }(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w500,
                          fontSize: isTablet ? 13 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.posDetailsCreated(order.date.isNotEmpty ? order.date : AppLocalizations.of(context)!.posCommonDash),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: order.statusColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: LocalizedApiText(
                              order.statusText,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 11 : 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 10,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.posDetailsOrderNo(order.id.split('-').last.toUpperCase()),
                    style: TextStyle(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 13 : 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required bool isTablet,
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: isTablet ? 18 : 16,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2124),
                  ),
                ),
              ),
            ]),

          SizedBox(height: isTablet ? 10 : 8),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: isTablet ? 12 : 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildJobsSection(BuildContext context, bool isTablet) {
    final jobs = order.jobs.where((j) => !j.isCancelledJob).toList();
    if (jobs.isEmpty) {
      return _buildSectionCard(
        isTablet: isTablet,
        title: AppLocalizations.of(context)!.posDetailsJobsSection,
        children: [_infoRow(AppLocalizations.of(context)!.posDetailsJobsSection, AppLocalizations.of(context)!.posDetailsNoJobsFound, isTablet)],
      );
    }

    return Column(
      children: jobs.asMap().entries.map((entry) {
        final i = entry.key;
        final job = entry.value;
        final techNames = job.distinctActiveTechnicians
            .map((t) => t.name)
            .where((n) => n.trim().isNotEmpty)
            .join(', ');
        return Padding(
          padding: EdgeInsets.only(bottom: i == jobs.length - 1 ? 0 : 12),
          child: _buildSectionCard(
            isTablet: isTablet,
            title: AppLocalizations.of(context)!.posDetailsJobTitle((i + 1).toString(), job.status.replaceAll('_', ' ').toUpperCase()),
            icon: Icons.work_outline_rounded,
            children: [
              _infoRow(
                AppLocalizations.of(context)!.posDetailsDepartment,
                job.department.isNotEmpty ? job.department : '-',
                isTablet,
              ),
              _infoRow(
                AppLocalizations.of(context)!.posDetailsTechnician,
                techNames.isNotEmpty ? techNames : '-',
                isTablet,
              ),
              _infoRow(
                AppLocalizations.of(context)!.posDetailsSubtotal,
                '${AppLocalizations.of(context)!.posCommonSar} ${(job.totalAmount - job.vatAmount).toStringAsFixed(2)}',
                isTablet,
              ),
              _infoRow(AppLocalizations.of(context)!.posDetailsVat15, '${AppLocalizations.of(context)!.posCommonSar} ${job.vatAmount.toStringAsFixed(2)}', isTablet),
              _infoRow(AppLocalizations.of(context)!.posDetailsTotal, '${AppLocalizations.of(context)!.posCommonSar} ${job.totalAmount.toStringAsFixed(2)}', isTablet),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.posDetailsItems(job.items.length.toString()),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 16 : 14,
                  color: const Color(0xFF1E2124),
                ),
              ),
              const SizedBox(height: 6),
              ...job.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 8,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE9EDF3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _detailsProductNameForLocale(context, item),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 14 : 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'x${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 13 : 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${AppLocalizations.of(context)!.posCommonSar} ${item.lineTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 13 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(String key, String value, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 130 : 96,
            child: Text(
              key,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: LocalizedApiText(
              value,
              style: TextStyle(
                color: const Color(0xFF1E2124),
                fontSize: isTablet ? 15 : 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}
