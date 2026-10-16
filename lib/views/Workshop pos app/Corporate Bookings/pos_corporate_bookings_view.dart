import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../utils/app_button_busy.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/pos_tablet_layout.dart';
import '../../../../utils/business_timezone.dart';
import '../../../../widgets/pos_widgets.dart';
import '../../../../widgets/pos_shell_rail_layout.dart';
import '../../../../widgets/pos_segmented_list_tabs.dart';
import '../../../../widgets/pos_shimmer.dart';
import '../../../models/corporate_booking_model.dart';
import '../../../models/pos_order_model.dart';
import '../Home Screen/pos_view_model.dart';
import '../Navbar/pos_shell.dart';
import 'corporate_booking_view_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/LocalizedApiText.dart';
import '../../../../services/locker_translation_mixin.dart';

class _CorporateStatusColors {
  final Color background;
  final Color foreground;
  const _CorporateStatusColors({
    required this.background,
    required this.foreground,
  });
}

class PosCorporateBookingsView extends StatefulWidget {
  /// When `false`, the app bar shows the shell drawer (hamburger) instead of a
  /// back button. Used when this view is mounted directly as a shell tab.
  final bool showBackButton;

  const PosCorporateBookingsView({super.key, this.showBackButton = true});

  @override
  State<PosCorporateBookingsView> createState() =>
      _PosCorporateBookingsViewState();
}

class _PosCorporateBookingsViewState extends State<PosCorporateBookingsView> {
  CorporateBookingViewModel? _vmRef;
  String? _redirectingBookingId;
  String? _approvingBookingId;
  final TextEditingController _searchController = TextEditingController();

  String _localizedDigits(String value) {
    return AppTranslationService.localizeDigitsForLanguage(
      value,
      Localizations.localeOf(context).languageCode,
    );
  }

  String _formatDate(DateTime date, String pattern) {
    final locale = Localizations.localeOf(context).languageCode;
    final ksa = BusinessTimezone.toWall(date);
    try {
      return DateFormat(pattern, locale).format(ksa);
    } catch (_) {
      return DateFormat(pattern).format(ksa);
    }
  }
  String _statusText(dynamic booking) {
    final orderRaw = booking.orderStatus?.toString().trim() ?? '';
    final statusRaw = booking.status?.toString().trim() ?? '';
    final displayRaw = booking.statusDisplay?.toString().trim() ?? '';
    final combined = '$displayRaw $statusRaw $orderRaw'.toLowerCase();
    if (combined.contains('cancelled') || combined.contains('canceled')) {
      return 'Cancelled';
    }
    if (combined.contains('rejected')) {
      return 'Rejected';
    }
    if (displayRaw.isNotEmpty) return displayRaw;
    if (statusRaw.isNotEmpty) return statusRaw;
    return 'Pending';
  }

  bool _isApproved(dynamic booking) {
    final raw = '${_statusText(booking)} ${booking.orderStatus?.toString() ?? ''}'
        .toLowerCase();
    if (raw.contains('cancelled') || raw.contains('canceled') || raw.contains('rejected')) {
      return false;
    }
    return raw.contains('approved');
  }

  bool _isRejected(dynamic booking) {
    final raw = '${_statusText(booking)} ${booking.orderStatus?.toString() ?? ''}'
        .toLowerCase();
    return raw.contains('rejected') || raw.contains('cancelled');
  }

  bool _canReviewBooking(dynamic booking) {
    return !_isApproved(booking) && !_isRejected(booking);
  }

  bool _isPrimaryActionBusy(String bookingId) {
    return _approvingBookingId == bookingId ||
        _redirectingBookingId == bookingId;
  }

  Widget _buildCorporatePrimaryActionContent({
    required bool isBusy,
    required bool showApprove,
    required bool isTablet,
    bool dialog = false,
  }) {
    if (isBusy) {
      final loaderSize = dialog ? (isTablet ? 15.0 : 14.0) : (isTablet ? 14.0 : 13.0);
      return AppButtonBusy.loaderOnFill(
        AppColors.primaryLight,
        size: loaderSize,
        strokeWidth: 2.5,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final label = showApprove
        ? (dialog ? l10n.posCorporateActionApproveBooking : l10n.posCorporateActionApprove)
        : l10n.posCorporateActionContinue;
    return Text(
      label,
      style: TextStyle(
        color: AppColors.secondaryLight,
        fontSize: dialog ? (isTablet ? 12.5 : 12) : (isTablet ? 10 : 9.5),
        fontWeight: FontWeight.w800,
        letterSpacing: dialog ? 0.35 : 0.15,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<CorporateBookingViewModel>(context, listen: false);
      _vmRef = vm;
      vm.fetchCorporateBookings();
      vm.bindRealtime();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vmRef?.unbindRealtime();
    super.dispose();
  }

  Widget _buildSearchBar(CorporateBookingViewModel vm, bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 20.0 : 24.0,
        10,
        isTablet ? 20.0 : 24.0,
        4,
      ),
      child: PosWorkshopSearchBar(
        controller: _searchController,
        hintText: AppLocalizations.of(context)!.posCorporateSearchHint,
        onChanged: vm.setSearchQuery,
      ),
    );
  }

  Widget _buildFilterTabs(CorporateBookingViewModel vm, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 20.0 : 12.0,
        0,
        isTablet ? 20.0 : 12.0,
        8,
      ),
      child: PosSegmentedListTabs(
        layout: PosSegmentedTabLayout.expanded,
        containerColor: Colors.white,
        unselectedTabColor: Colors.white,
        tabVerticalPadding: isTablet ? 9 : 8,
        tabs: [
          PosSegmentedTab(
            id: 'All',
            label: l10n.posCorporateFilterAll,
            count: vm.filterTabCountAll,
          ),
          PosSegmentedTab(
            id: 'Pending',
            label: l10n.posCorporateFilterPending,
            count: vm.filterTabCountPending,
          ),
          PosSegmentedTab(
            id: 'Approve',
            label: l10n.posCorporateFilterApprove,
            count: vm.filterTabCountApprove,
          ),
          PosSegmentedTab(
            id: 'Cancelled',
            label: l10n.posCorporateFilterCancelled,
            count: vm.filterTabCountCancelled,
          ),
        ],
        selectedId: vm.currentFilter,
        onSelected: vm.setFilter,
      ),
    );
  }

  double _bookingCardExtent(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return isLandscape ? 134.0 : 138.0;
    }
    return 132.0;
  }

  Widget _buildInlineStatusBadge({
    required String label,
    required _CorporateStatusColors colors,
    required bool isLandscape,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: isLandscape ? 7.5 : 8,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPlateWithCorporateLine({
    required String plate,
    required String company,
    required bool isLandscape,
  }) {
    final plateText = plate.trim().isNotEmpty ? plate.trim() : '-';
    final companyText = company.trim();
    final baseStyle = TextStyle(
      fontSize: isLandscape ? 12 : 13,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF2D3139),
      letterSpacing: -0.2,
    );
    final companyStyle = TextStyle(
      fontSize: isLandscape ? 11 : 12,
      fontWeight: FontWeight.w700,
      color: AppColors.secondaryLight,
    );

    if (companyText.isEmpty) {
      return LocalizedApiText(
        plateText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return Row(
      children: [
        Flexible(
          child: LocalizedApiText(
            plateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: baseStyle,
          ),
        ),
        Text(' (', style: baseStyle),
        Flexible(
          child: LocalizedApiText(
            companyText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: companyStyle,
          ),
        ),
        Text(')', style: baseStyle),
      ],
    );
  }

  int _bookingGridColumns(bool isTablet, bool isLandscape) {
    if (!isTablet) return 1;
    return isLandscape ? 3 : 2;
  }

  Widget _buildBookingsList({
    required List<dynamic> bookings,
    required bool isTablet,
    required bool isLandscape,
    required CorporateBookingViewModel vm,
  }) {
    const listPhysics = BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );

    if (bookings.isEmpty) {
      return ListView(
        physics: listPhysics,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
        children: [
          SizedBox(height: isTablet ? 48 : 36),
          _buildEmptyState(isTablet),
        ],
      );
    }

    return GridView.builder(
      physics: listPhysics,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 14 : 10,
        6,
        isTablet ? 14 : 10,
        isTablet ? 12 : 10,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _bookingGridColumns(isTablet, isLandscape),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: _bookingCardExtent(isTablet, isLandscape),
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, isTablet);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _stateContext = context;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: PosTabletLayout.textScaler(context)),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PosScreenAppBar(
          title: AppLocalizations.of(context)!.posCorporateBookingsTitle,
          showBackButton: widget.showBackButton,
        ),
        body: wrapPosShellRailBody(
          context,
          Consumer<CorporateBookingViewModel>(
          builder: (context, vm, child) {
            final bookings = vm.filteredBookings;
            final showInitialShimmer = vm.isLoading && !vm.hasBookings;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(vm, isTablet),
                _buildFilterTabs(vm, isTablet),

                if (vm.isRefreshing)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primaryLight,
                    backgroundColor: Color(0xFFE8E4DC),
                  ),

                // ─── List of Bookings ───
                Expanded(
                  child: showInitialShimmer
                      ? _CorporateBookingsShimmer(
                          isTablet: isTablet,
                          isLandscape: isLandscape,
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryLight,
                          onRefresh: () => vm.fetchCorporateBookings(refresh: true),
                          child: _buildBookingsList(
                            bookings: bookings,
                            isTablet: isTablet,
                            isLandscape: isLandscape,
                            vm: vm,
                          ),
                        ),
                ),
              ],
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: isTablet ? 52 : 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.posCorporateNoBookingsTitle,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2124),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.posCorporateNoBookingsSubtitle,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(booking, bool isTablet) {
    final bookingId = booking.id.toString();
    final isPrimaryBusy = _isPrimaryActionBusy(bookingId);
    final showApprove = _canReviewBooking(booking);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final statusText = _statusText(booking);
    final statusColors = _corporateStatusColors(statusText);
    final statusLabel = _localizedStatusDisplay(statusText);
    final formattedDate = _formatDate(
      booking.bookedDateTime,
      'MMM dd, yyyy • hh:mm a',
    );
    final department = booking.department?.toString().trim() ?? '';
    final hasDepartment = department.isNotEmpty;
    final company = booking.companyName?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 10 : 8,
                isTablet ? 8 : 7,
                isTablet ? 10 : 8,
                isTablet ? 3 : 2,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: AppColors.secondaryLight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildPlateWithCorporateLine(
                                      plate: booking.vehiclePlate?.toString() ?? '',
                                      company: company,
                                      isLandscape: isLandscape,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildInlineStatusBadge(
                                    label: statusLabel,
                                    colors: statusColors,
                                    isLandscape: isLandscape,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              LocalizedApiText(
                                booking.vehicleName?.toString() ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isLandscape ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isLandscape ? 10 : 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasDepartment)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, left: 40),
                        child: Row(
                          children: [
                            Icon(
                              Icons.apartment_rounded,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: LocalizedApiText(
                                department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isLandscape ? 9.5 : 10.5,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // ─── Actions Bottom Row ───
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 9 : 8,
                isTablet ? 6 : 5,
                isTablet ? 9 : 8,
                isTablet ? 3 : 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () => _viewDetails(context, booking, isTablet),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(AppColors.secondaryLight),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        shadowColor: WidgetStateProperty.all(Colors.transparent),
                        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                        elevation: WidgetStateProperty.all(0),
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.standard,
                        padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                          vertical: isTablet ? 9 : 8,
                          horizontal: 6,
                        )),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.posCorporateActionDetails,
                        style: TextStyle(
                          fontSize: isTablet ? 10 : 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: isPrimaryBusy
                          ? null
                          : () async {
                        if (_canReviewBooking(booking)) {
                          final vm = Provider.of<CorporateBookingViewModel>(
                            context,
                            listen: false,
                          );
                          setState(() => _approvingBookingId = bookingId);
                          try {
                            final success = await vm.approveBooking(booking.id);
                            if (!success) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      vm.errorMessage ??
                                          AppLocalizations.of(context)!.posCorporateApproveError,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                            if (context.mounted) {
                              if (mounted) {
                                setState(() {
                                  _approvingBookingId = null;
                                  _redirectingBookingId = bookingId;
                                });
                              }
                              await _preloadCorporateProductsCatalog(context, booking);
                              if (context.mounted) {
                                await _navigateToProductGrid(context, booking);
                              }
                            }
                          } finally {
                            if (mounted && _approvingBookingId == bookingId) {
                              setState(() => _approvingBookingId = null);
                            }
                          }
                          return;
                        }

                        if (_isApproved(booking) && context.mounted) {
                          setState(() => _redirectingBookingId = bookingId);
                          try {
                            await _preloadCorporateProductsCatalog(context, booking);
                            if (context.mounted) {
                              await _navigateToProductGrid(context, booking);
                            }
                          } finally {
                            if (mounted && _redirectingBookingId == bookingId) {
                              setState(() => _redirectingBookingId = null);
                            }
                          }
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(AppColors.primaryLight),
                        foregroundColor: WidgetStateProperty.all(AppColors.secondaryLight),
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        shadowColor: WidgetStateProperty.all(Colors.transparent),
                        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                        elevation: WidgetStateProperty.all(0),
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.standard,
                        padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                          vertical: isTablet ? 9 : 8,
                          horizontal: 6,
                        )),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )),
                      ),
                      child: _buildCorporatePrimaryActionContent(
                        isBusy: isPrimaryBusy,
                        showApprove: showApprove,
                        isTablet: isTablet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(
      String label,
      String value,
      IconData icon,
      bool isTablet, {
        bool translateValue = false,
      }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: isTablet ? 16 : 14,
              color: AppColors.secondaryLight,
            ),
          ),
          SizedBox(width: isTablet ? 10 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 9 : 8,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                translateValue
                    ? LocalizedApiText(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2124),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                    : LocalizedApiText(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2124),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isTablet) {
    final colors = _corporateStatusColors(status);
    final displayStatus = _localizedStatusDisplay(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 5 : 5,
        vertical: isTablet ? 2 : 2,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: isTablet ? 7.5 : 7.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _CorporateStatusColors _corporateStatusColors(String status) {
    final s = status.toLowerCase();
    if (s.contains('cancelled') ||
        s.contains('canceled') ||
        s.contains('rejected')) {
      return const _CorporateStatusColors(
        background: Color(0xFFB42318),
        foreground: Colors.white,
      );
    }
    if (s.contains('approved') || s.contains('completed')) {
      return const _CorporateStatusColors(
        background: Color(0xFF15803D),
        foreground: Colors.white,
      );
    }
    if (s.contains('in progress')) {
      return const _CorporateStatusColors(
        background: Color(0xFF2563EB),
        foreground: Colors.white,
      );
    }
    if (s.contains('waiting') || s.contains('pending')) {
      return const _CorporateStatusColors(
        background: Color(0xFFEA580C),
        foreground: Colors.white,
      );
    }
    return _CorporateStatusColors(
      background: Colors.grey.shade700,
      foreground: Colors.white,
    );
  }

  String _localizedStatusDisplay(String status) {
    final s = status.toLowerCase();
    final l10n = AppLocalizations.of(_scaffoldContext)!;
    if (s.contains('cancelled') || s.contains('canceled')) {
      return l10n.posCorporateStatusCancelled;
    }
    if (s.contains('rejected')) {
      return l10n.posCorporateStatusRejected;
    }
    if (s.contains('approved')) {
      return l10n.posCorporateStatusApproved;
    }
    if (s.contains('in progress')) {
      return l10n.posCorporateStatusInProgress;
    }
    if (s.contains('completed')) {
      return l10n.posCorporateStatusCompleted;
    }
    if (s.contains('waiting')) {
      return l10n.posCorporateStatusWaitingApproval;
    }
    if (s.contains('pending')) {
      return l10n.posCorporateStatusPending;
    }
    return status;
  }

  // Helper — holds current build context for widgets that need l10n outside build()
  BuildContext get _scaffoldContext => _stateContext!;
  BuildContext? _stateContext;

  void _viewDetails(BuildContext context, booking, bool isTablet) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: isTablet ? 500 : MediaQuery.of(context).size.width * 0.88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 14,
                  vertical: isTablet ? 14 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.posCorporateDialogDetailsTitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LocalizedApiText(
                            booking.vehiclePlate?.toString() ?? '-',
                            style: TextStyle(
                              color: const Color(0xFF1E2124),
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(_statusText(booking), isTablet),
                  ],
                ),
              ),

              // Content Details
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 18 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSectionHeading(
                        AppLocalizations.of(context)!.posCorporateDetailsSectionBooking,
                        Icons.receipt_long_rounded,
                        isTablet,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(AppLocalizations.of(context)!.posCorporateDetailsBookingId, booking.id, isTablet),
                      _buildDetailRow(
                        AppLocalizations.of(context)!.posCorporateDetailsScheduledTime,
                        _formatDate(booking.bookedDateTime, 'MMM dd, yyyy - hh:mm a'),
                        isTablet,
                      ),
                      _buildDetailRowApi(
                        AppLocalizations.of(context)!.posCorporateDetailsDepartment,
                        booking.department?.toString() ?? '',
                        isTablet,
                      ),
                      if (_isRejected(booking) &&
                          (booking.rejectionReason?.trim().isNotEmpty ?? false))
                        _buildDetailRow(
                          AppLocalizations.of(context)!.posCorporateDetailsRejectionReason,
                          booking.rejectionReason!.trim(),
                          isTablet,
                        ),

                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 14),

                      _buildDetailSectionHeading(
                        AppLocalizations.of(context)!.posCorporateDetailsSectionVehicle,
                        Icons.directions_car_rounded,
                        isTablet,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRowApi(
                        AppLocalizations.of(context)!.posCorporateDetailsVehicleName,
                        booking.vehicleName?.toString() ?? '',
                        isTablet,
                      ),
                      _buildDetailRow(
                        AppLocalizations.of(context)!.posCorporateDetailsLicensePlate,
                        booking.vehiclePlate,
                        isTablet,
                      ),

                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 14),

                      _buildDetailSectionHeading(
                        AppLocalizations.of(context)!.posCorporateDetailsSectionProducts,
                        Icons.inventory_2_rounded,
                        isTablet,
                      ),
                      const SizedBox(height: 10),
                      if ((booking.items == null || booking.items!.isEmpty) &&
                          (booking.preSelectedProducts == null ||
                              booking.preSelectedProducts.isEmpty))
                        Container(
                          padding: EdgeInsets.all(isTablet ? 14 : 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.grey.shade500,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.posCorporateDetailsNoProducts,
                                  style: TextStyle(
                                    fontSize: isTablet ? 12.5 : 11.5,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (booking.items != null &&
                          booking.items!.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: booking.items!.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final item = booking.items![index];
                              final itemName =
                                  item['serviceName'] ??
                                      item['productName'] ??
                                      AppLocalizations.of(context)!.posCorporateDetailsSectionProducts;
                              final qty = item['qty'] ?? 1;

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: isTablet ? 17 : 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          LocalizedApiText(
                                            itemName.toString(),
                                            style: TextStyle(
                                              fontSize: isTablet ? 12.5 : 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondaryLight,
                                              letterSpacing: 0.15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppLocalizations.of(context)!.posCorporateDetailsQty(_localizedDigits(qty.toString())),
                                            style: TextStyle(
                                              fontSize: isTablet ? 11 : 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: booking.preSelectedProducts.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: isTablet ? 17 : 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.posCorporateDetailsProductId(_localizedDigits(booking.preSelectedProducts[index].toString())),
                                        style: TextStyle(
                                          fontSize: isTablet ? 12.5 : 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondaryLight,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action Buttons Bottom
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 14,
                  vertical: isTablet ? 14 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(AppColors.secondaryLight),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          shadowColor: WidgetStateProperty.all(Colors.transparent),
                          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                          elevation: WidgetStateProperty.all(0),
                          padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                            vertical: isTablet ? 11 : 10,
                          )),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.posCorporateActionClose,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 12.5 : 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_canReviewBooking(booking))
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _isPrimaryActionBusy(booking.id.toString())
                              ? null
                              : () async {
                            final vm = Provider.of<CorporateBookingViewModel>(
                              context,
                              listen: false,
                            );
                            final bid = booking.id.toString();
                            setState(() => _approvingBookingId = bid);
                            try {
                              final success = await vm.approveBooking(booking.id);
                              if (!success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        vm.errorMessage ??
                                            AppLocalizations.of(context)!.posCorporateApproveError,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  await _preloadCorporateProductsCatalog(context, booking);
                                }
                                if (context.mounted) Navigator.pop(ctx);
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _approvingBookingId = null);
                              }
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(AppColors.primaryLight),
                            foregroundColor: WidgetStateProperty.all(AppColors.secondaryLight),
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                            shadowColor: WidgetStateProperty.all(Colors.transparent),
                            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                            elevation: WidgetStateProperty.all(0),
                            padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                              vertical: isTablet ? 11 : 10,
                            )),
                            shape: WidgetStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            )),
                          ),
                          child: _buildCorporatePrimaryActionContent(
                            isBusy: _isPrimaryActionBusy(booking.id.toString()),
                            showApprove: true,
                            isTablet: isTablet,
                            dialog: true,
                          ),
                        ),
                      )
                    else if (_isApproved(booking))
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _isPrimaryActionBusy(booking.id.toString())
                              ? null
                              : () async {
                            final bid = booking.id.toString();
                            Navigator.pop(ctx);
                            setState(() => _redirectingBookingId = bid);
                            try {
                              await _preloadCorporateProductsCatalog(context, booking);
                              if (context.mounted) {
                                await _navigateToProductGrid(context, booking);
                              }
                            } finally {
                              if (mounted && _redirectingBookingId == bid) {
                                setState(() => _redirectingBookingId = null);
                              }
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(AppColors.primaryLight),
                            foregroundColor: WidgetStateProperty.all(AppColors.secondaryLight),
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                            shadowColor: WidgetStateProperty.all(Colors.transparent),
                            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                            elevation: WidgetStateProperty.all(0),
                            padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                              vertical: isTablet ? 11 : 10,
                            )),
                            shape: WidgetStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            )),
                          ),
                          child: _buildCorporatePrimaryActionContent(
                            isBusy: _isPrimaryActionBusy(booking.id.toString()),
                            showApprove: false,
                            isTablet: isTablet,
                            dialog: true,
                          ),
                        ),
                      )
                    else
                      const Expanded(flex: 1, child: SizedBox.shrink()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionHeading(
      String title,
      IconData icon,
      bool isTablet,
      ) {
    return Row(
      children: [
        Icon(icon, size: isTablet ? 17 : 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 13.5 : 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 8.0 : 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isTablet ? 12 : 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LocalizedApiText(
              value,
              style: TextStyle(
                color: AppColors.secondaryLight,
                fontSize: isTablet ? 12 : 11.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showReasonDialog(
      BuildContext context,
      booking,
      String action,
      bool isTablet,
      ) {
    final TextEditingController reasonController = TextEditingController();
    // action is already localised, use color based on heuristic
    final bool isReject = true; // Reject dialog only opens via Reject button
    final Color themeColor = isReject
        ? Colors.red.shade600
        : Colors.orange.shade600;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: isTablet ? 500 : MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple Header Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.posCorporateDialogRejectTitle,
                        style: TextStyle(
                          color: const Color(0xFF1E2124),
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.posCorporateDialogRejectBody(action, booking.companyName?.toString() ?? ''),
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.posCorporateDialogReasonLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isTablet ? 14 : 13,
                        color: AppColors.secondaryLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.posCorporateDialogReasonHint,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.posCorporateActionCancel,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.posCorporateDialogReasonRequired(action)),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          final vm = Provider.of<CorporateBookingViewModel>(
                            context,
                            listen: false,
                          );
                          final success = await vm.rejectBooking(
                            booking.id,
                            reasonController.text,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(ctx);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.posCorporateRejectSuccess),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  vm.errorMessage ?? AppLocalizations.of(context)!.posCorporateRejectError,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(themeColor),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          shadowColor: WidgetStateProperty.all(Colors.transparent),
                          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                          elevation: WidgetStateProperty.all(0),
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          )),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.posCorporateActionSubmitReason,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Linked cashier order id when the API provides it (not always same as booking [id]).
  String _preferredCashierOrderIdForBooking(dynamic booking) {
    if (booking is CorporateBooking) {
      final oid = booking.orderId?.trim() ?? '';
      if (oid.isNotEmpty) return oid;
    }
    return booking.id?.toString().trim() ?? '';
  }

  String? _resolveCorporateAccountIdForBooking(
    PosViewModel posVm,
    dynamic booking,
    String preferredOrderId,
  ) {
    if (booking is CorporateBooking) {
      final fromBooking = booking.corporateAccountId?.trim() ?? '';
      if (fromBooking.isNotEmpty) return fromBooking;
    }
    final order = _resolveCorporateOrderMatch(posVm, booking, preferredOrderId);
    return order?.corporateAccountId?.trim();
  }

  /// Loads `GET /cashier/corporate-accounts/:id/products` after approve (or before Orders).
  Future<void> _preloadCorporateProductsCatalog(
    BuildContext context,
    dynamic booking,
  ) async {
    final posVm = context.read<PosViewModel>();
    final preferredOrderId = _preferredCashierOrderIdForBooking(booking);
    await posVm.fetchOrders(
      silent: true,
      preferredOrderId: preferredOrderId.isNotEmpty ? preferredOrderId : null,
    );
    final corpId = _resolveCorporateAccountIdForBooking(
      posVm,
      booking,
      preferredOrderId,
    );
    if (corpId == null || corpId.isEmpty) return;

    List<dynamic>? portalItems;
    if (booking is CorporateBooking) {
      portalItems = booking.items;
      posVm.primeCorporateBookingFromPortal(
        corporateAccountId: corpId,
        bookingItems: portalItems,
        corporateBookingId: booking.id,
      );
      final token = await posVm.sessionService.getToken(role: 'cashier');
      if (token != null) {
        try {
          final detail = await posVm.posRepository.getCorporateBookingDetail(
            booking.id,
            token,
          );
          if (detail?.items != null && detail!.items!.isNotEmpty) {
            portalItems = detail.items;
            posVm.setCorporateBookingQuotedItems(detail.items);
          }
        } catch (_) {}
      }
    }

    final matched = _resolveCorporateOrderMatch(posVm, booking, preferredOrderId);
    String? deptId;
    final deptName =
        booking is CorporateBooking ? booking.department.trim() : '';
    if (deptName.isNotEmpty) {
      try {
        final depts = await posVm.catalogSync.loadDepartmentsLocal();
        for (final d in depts) {
          if (d.name.trim().toLowerCase() == deptName.toLowerCase()) {
            deptId = d.id;
            break;
          }
        }
      } catch (_) {}
    }

    if (matched != null) {
      await posVm.prepareCorporateJobProductCatalog(
        order: matched,
        departmentId: deptId,
        departmentName: deptName.isNotEmpty ? deptName : null,
        bookingItemsFallback: portalItems,
        corporateBookingId:
            booking is CorporateBooking ? booking.id : null,
      );
    } else {
      await posVm.loadCorporateProductsCatalog(
        corpId,
        departmentId: deptId,
        departmentName: deptName.isNotEmpty ? deptName : null,
      );
    }
  }

  Future<void> _navigateToProductGrid(BuildContext context, dynamic booking) async {
    final bid = booking.id?.toString() ?? '';
    if (mounted) {
      setState(() {
        _redirectingBookingId = bid;
      });
    }
    final posVm = Provider.of<PosViewModel>(context, listen: false);
    final preferredOrderId = _preferredCashierOrderIdForBooking(booking);

    // Keep customer/vehicle overlay fields aligned while opening Orders.
    posVm.setCustomerData(
      name: booking.companyName?.toString() ?? '',
      vat: '',
      mobile: '',
      vehicleNumber: booking.vehiclePlate?.toString() ?? '',
      make: booking.vehicleName?.toString() ?? '',
      model: '',
      odometer: 0,
    );

    // Avoid stale filters/search hiding valid orders right after navigation.
    posVm.setOrderSearchQuery('');
    posVm.setOrderStatusFilter('All');
    posVm.setOrdersListTab('All');

    await posVm.fetchOrders(
      silent: true,
      preferredOrderId: preferredOrderId.isNotEmpty ? preferredOrderId : null,
    );

    final matchedOrder =
        _resolveCorporateOrderMatch(posVm, booking, preferredOrderId);
    if (matchedOrder != null) {
      List<dynamic>? portalItems;
      String? deptId;
      final deptName =
          booking is CorporateBooking ? booking.department.trim() : '';
      if (booking is CorporateBooking) {
        portalItems = booking.items;
        final corpForPrime = _resolveCorporateAccountIdForBooking(
              posVm,
              booking,
              preferredOrderId,
            ) ??
            matchedOrder.corporateAccountId ??
            '';
        if (corpForPrime.isNotEmpty) {
          posVm.primeCorporateBookingFromPortal(
            corporateAccountId: corpForPrime,
            bookingItems: portalItems,
            corporateBookingId: booking.id,
          );
        }
      }
      if (deptName.isNotEmpty) {
        try {
          final depts = await posVm.catalogSync.loadDepartmentsLocal();
          for (final d in depts) {
            if (d.name.trim().toLowerCase() == deptName.toLowerCase()) {
              deptId = d.id;
              break;
            }
          }
        } catch (_) {}
      }
      await posVm.prepareCorporateJobProductCatalog(
        order: matchedOrder,
        departmentId: deptId,
        departmentName: deptName.isNotEmpty ? deptName : null,
        bookingItemsFallback: portalItems,
        corporateBookingId:
            booking is CorporateBooking ? booking.id : null,
      );
    }
    if (matchedOrder == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.posCorporateNoMatchingOrder,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      if (mounted) {
        setState(() {
          _redirectingBookingId = null;
        });
      }
      return;
    }

    posVm.selectOrder(matchedOrder);

    if (!context.mounted) return;
    navigateToPosShellOrdersTab(context);
    if (mounted) {
      setState(() {
        _redirectingBookingId = null;
      });
    }
  }

  PosOrder? _resolveCorporateOrderMatch(
      PosViewModel posVm,
      dynamic booking,
      String preferredOrderId,
      ) {
    final allOrders = List<PosOrder>.from(posVm.orders)
      ..sort((a, b) =>
          (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0));

    final bookingId = booking.id?.toString().trim() ?? '';
    final idsToTry = <String>{
      if (preferredOrderId.isNotEmpty) preferredOrderId,
      if (bookingId.isNotEmpty && bookingId != preferredOrderId) bookingId,
    };
    for (final id in idsToTry) {
      try {
        return allOrders.firstWhere((o) => o.id.trim() == id);
      } catch (_) {
        // Try next id or heuristics.
      }
    }

    final plate = booking.vehiclePlate?.toString().trim().toLowerCase() ?? '';
    final company = booking.companyName?.toString().trim().toLowerCase() ?? '';
    final hasBookingPlate = plate.isNotEmpty;

    // 1) Strong match: corporate + exact plate.
    if (hasBookingPlate) {
      final plateMatches = allOrders.where((o) {
        final isCorporate = o.source.toLowerCase().contains('corporate') ||
            (o.corporateAccountId?.isNotEmpty ?? false);
        if (!isCorporate) return false;
        final orderPlate = o.plateNumber.trim().toLowerCase();
        return orderPlate.isNotEmpty && orderPlate == plate;
      }).toList();
      if (plateMatches.isNotEmpty) return plateMatches.first;
    }

    // 2) Fallback only when booking itself has no plate.
    final candidates = allOrders.where((o) {
      final isCorporate = o.source.toLowerCase().contains('corporate') ||
          (o.corporateAccountId?.isNotEmpty ?? false);
      if (!isCorporate) return false;

      final orderPlate = o.plateNumber.trim().toLowerCase();
      final orderCompany = (o.corporateCompanyName ?? o.customerName).trim().toLowerCase();
      if (hasBookingPlate) return false;
      return orderPlate.isNotEmpty && orderPlate == plate ||
          (company.isNotEmpty && orderCompany == company);
    }).toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0));
    return candidates.first;
  }

  bool _bookingLooksCompleted(dynamic booking) {
    final statusRaw =
    '${booking.statusDisplay?.toString() ?? ''} ${booking.status?.toString() ?? ''}'
        .toLowerCase();
    return statusRaw.contains('complete') || statusRaw.contains('invoiced');
  }

  /// Detail row variant for API data — uses LocalizedApiText for the value.
  Widget _buildDetailRowApi(String label, String value, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 8.0 : 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isTablet ? 12 : 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LocalizedApiText(
              value,
              style: TextStyle(
                color: AppColors.secondaryLight,
                fontSize: isTablet ? 12 : 11.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorporateBookingsShimmer extends StatelessWidget {
  const _CorporateBookingsShimmer({
    required this.isTablet,
    required this.isLandscape,
  });
  final bool isTablet;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 14 : 10,
        6,
        isTablet ? 14 : 10,
        isTablet ? 12 : 10,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? (isLandscape ? 3 : 2) : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: isTablet ? (isLandscape ? 126.0 : 130.0) : 124.0,
      ),
      itemCount: isTablet ? (isLandscape ? 6 : 4) : 3,
      itemBuilder: (_, __) => const _CorporateBookingCardShimmer(),
    );
  }
}

class _CorporateBookingCardShimmer extends StatelessWidget {
  const _CorporateBookingCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PosShimmerBox(width: 32, height: 32, radius: 9),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: PosShimmerLine(
                                    width: double.infinity,
                                    height: 12,
                                  ),
                                ),
                                SizedBox(width: 6),
                                PosShimmerBox(width: 48, height: 14, radius: 7),
                              ],
                            ),
                            SizedBox(height: 5),
                            PosShimmerLine(width: 108, height: 9),
                            SizedBox(height: 4),
                            PosShimmerLine(width: 120, height: 9),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  PosShimmerLine(width: 112, height: 10),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 28,
                      radius: 8,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 28,
                      radius: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
