import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../models/inventory_sales_api_model.dart';
import 'inventory_sales_view_model.dart';

String _dashStr(String? s) {
  if (s == null || s.trim().isEmpty) return '—';
  return s.trim();
}

String _inventoryFmtQty(num v) {
  if (v == v.round()) return '${v.round()}';
  return v.toDouble().toStringAsFixed(2);
}

/// Row flex weights (sum = 100). Columns share parent width responsively.
const int _kFlexItem = 34;
const int _kFlexDept = 28;
const int _kFlexType = 12;
const int _kFlexSku = 16;
const int _kFlexQty = 10;
const double _kInvTableColGap = 8.0;

/// Nudges SKU column slightly right (visual alignment).
const double _kInvSkuLeftInset = 6.0;

/// KPI row width as a fraction of [maxWidth] (narrower row, centered).
const double _kInventoryKpiRowWidthFactor = 0.78;

/// All KPI stat cards in one row; narrower than [maxWidth], centered.
class _InventoryKpiGrid extends StatelessWidget {
  const _InventoryKpiGrid({required this.vm, required this.maxWidth});

  final InventorySalesViewModel vm;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final children = [
      _StatCard(
        label: AppLocalizations.of(context)!.posInvSalesStatTotalUnits,
        value: _inventoryFmtQty(vm.displayTotalUnits),
      ),
      _StatCard(
        label: AppLocalizations.of(context)!.posInvSalesStatDistinctItems,
        value: '${vm.displayDistinctItems}',
      ),
      _StatCard(
        label: AppLocalizations.of(context)!.posInvSalesStatUniqueProducts,
        value: '${vm.displayUniqueProductsCount}',
      ),
      _StatCard(
        label: AppLocalizations.of(context)!.posInvSalesStatDaysActive,
        value: '${vm.displayDaysWithActivity}',
      ),
    ];
    const gap = 8.0;
    final rowW = (maxWidth * _kInventoryKpiRowWidthFactor).clamp(
      0.0,
      double.infinity,
    );
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: rowW,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cashier drawer tab: period KPIs (except Total sales) and products for the date range.
class PosInventorySalesView extends StatefulWidget {
  const PosInventorySalesView({super.key});

  @override
  State<PosInventorySalesView> createState() => _PosInventorySalesViewState();
}

DateTime _invSalesPickerEarliest(DateTime now) =>
    DateTime(now.year - 4, now.month, now.day);

DateTime _invSalesPickerLatest(DateTime now) =>
    DateTime(now.year + 4, now.month, now.day);

class _PosInventorySalesViewState extends State<PosInventorySalesView> {
  DateTime? _draftFrom;
  DateTime? _draftTo;
  Timer? _ksaClockTimer;

  /// Time window (minutes from midnight, KSA wall clock); mirrors VM after sync.
  int _draftFromMinutes = 0;
  int _draftToMinutes = 23 * 60 + 59;

  @override
  void initState() {
    super.initState();
    _ksaClockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDraftFromVm());
  }

  @override
  void dispose() {
    _ksaClockTimer?.cancel();
    super.dispose();
  }

  void _syncDraftFromVm() {
    if (!mounted) return;
    final vm = context.read<InventorySalesViewModel>();
    final r = vm.resolveDateRange();
    setState(() {
      _draftFrom = r.from;
      _draftTo = r.toInclusive;
      if (vm.isCustomRange) {
        _draftFromMinutes = vm.rangeFromMinutes;
        _draftToMinutes = vm.rangeToMinutes;
      } else {
        _draftFromMinutes = 0;
        _draftToMinutes = 23 * 60 + 59;
      }
    });
  }

  bool _isDraftTimeWindowValid(int fromMin, int toMin) {
    final a = _draftFrom;
    final b = _draftTo;
    if (a == null || b == null) return true;
    final start = DateTime(a.year, a.month, a.day, fromMin ~/ 60, fromMin % 60);
    final end = DateTime(b.year, b.month, b.day, toMin ~/ 60, toMin % 60);
    return !start.isAfter(end);
  }

  Future<void> _applyFilters() async {
    final vm = context.read<InventorySalesViewModel>();
    vm.dismissErrorBanner();
    final a = _draftFrom;
    final b = _draftTo;
    if (a == null || b == null) {
      _syncDraftFromVm();
      return;
    }
    await vm.applyCustomRangeWithTimes(
      a,
      b,
      _draftFromMinutes,
      _draftToMinutes,
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncDraftFromVm();
    });
  }

  Future<void> _clearFilters() async {
    final vm = context.read<InventorySalesViewModel>();
    vm.dismissErrorBanner();
    await vm.resetFiltersToDefaultAndFetch();
    if (!mounted) return;
    _syncDraftFromVm();
  }

  Future<void> _pickDraftFrom() async {
    final now = DateTime.now();
    final earliest = _invSalesPickerEarliest(now);
    final latest = _invSalesPickerLatest(now);
    final vm = context.read<InventorySalesViewModel>();
    final basis = vm.resolveDateRange();
    var cur = _draftFrom ?? basis.from;
    if (cur.isBefore(earliest)) cur = earliest;
    if (cur.isAfter(latest)) cur = latest;

    final picked = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest,
      initialDate: cur,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.secondaryLight,
            brightness: Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    setState(
      () => _draftFrom = DateTime(picked.year, picked.month, picked.day),
    );
    if (_draftTo != null && _draftFrom!.isAfter(_draftTo!)) {
      setState(() => _draftTo = _draftFrom);
    }
  }

  Future<void> _pickDraftTo() async {
    final now = DateTime.now();
    final earliest = _invSalesPickerEarliest(now);
    final latest = _invSalesPickerLatest(now);
    final vm = context.read<InventorySalesViewModel>();
    final basis = vm.resolveDateRange();
    final floor = _draftFrom ?? basis.from;
    var cur = _draftTo ?? basis.toInclusive;
    if (cur.isAfter(latest)) cur = latest;
    if (cur.isBefore(floor)) cur = floor;

    final picked = await showDatePicker(
      context: context,
      firstDate: floor.isBefore(earliest) ? earliest : floor,
      lastDate: latest,
      initialDate: cur,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.secondaryLight,
            brightness: Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _draftTo = DateTime(picked.year, picked.month, picked.day));
    if (_draftFrom != null && _draftTo!.isBefore(_draftFrom!)) {
      setState(() => _draftFrom = _draftTo);
    }
  }

  Future<void> _pickDraftFromTime() async {
    var fromMin = _draftFromMinutes;
    final toMin = _draftToMinutes;
    if (!_isDraftTimeWindowValid(fromMin, toMin)) {
      fromMin = toMin;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: fromMin ~/ 60, minute: fromMin % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.secondaryLight,
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (!mounted || picked == null) return;

    final nextFrom = picked.hour * 60 + picked.minute;
    if (!_isDraftTimeWindowValid(nextFrom, _draftToMinutes)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.posInvSalesErrStartTimeBeforeEndSameRange,
          ),
        ),
      );
      return;
    }

    setState(() => _draftFromMinutes = nextFrom);
  }

  Future<void> _pickDraftToTime() async {
    final fromMin = _draftFromMinutes;
    var toMin = _draftToMinutes;
    if (!_isDraftTimeWindowValid(fromMin, toMin)) {
      toMin = fromMin;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: toMin ~/ 60, minute: toMin % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.secondaryLight,
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (!mounted || picked == null) return;

    final nextTo = picked.hour * 60 + picked.minute;
    if (!_isDraftTimeWindowValid(_draftFromMinutes, nextTo)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.posInvSalesErrEndTimeAfterStartSameRange,
          ),
        ),
      );
      return;
    }

    setState(() => _draftToMinutes = nextTo);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventorySalesViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: PosTabletLayout.textScaler(context)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: PosScreenAppBar(
          title: l10n.posInvSalesTitle,
          subtitle: vm.appBarSubtitleForLocale(
            Localizations.localeOf(context).languageCode,
          ),
          showBackButton: false,
          showHamburger: true,
          onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
        ),
        body: wrapPosShellRailBody(context, _buildBody(context, vm)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, InventorySalesViewModel vm) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildBodyContent(context, vm),
    );
  }

  Widget _buildBodyContent(BuildContext context, InventorySalesViewModel vm) {
    if (vm.isLoading && vm.lines.isEmpty && vm.errorMessage == null) {
      return const _InventorySalesLoadingShimmer();
    }

    final range = vm.resolveDateRange();
    final leftPad = PosShellRailLayout.bodyLeftOf(context);
    final contentWidth = MediaQuery.sizeOf(context).width - leftPad;
    final wideManual = contentWidth > 620;
    final tablet = PosTabletLayout.isTablet(context);
    final hPad = tablet ? 20.0 : 24.0;
    final sectionTitleSize = tablet ? 13.0 : 12.0;
    final sectionCountSize = tablet ? 11.0 : 10.0;

    Widget? banner;
    if (vm.errorMessage != null) {
      banner = Padding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade800,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LocalizedApiText(
                  vm.errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: vm.dismissErrorBanner,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade800,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final viewportH = MediaQuery.sizeOf(context).height;
    final emptyMinHeight = (viewportH * 0.35).clamp(220.0, 480.0);

    final listPhysics = const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );

    Widget buildListPane(double maxW, double maxH) {
      return Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExcludeSemantics(
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: () => vm.fetch(),
            notificationPredicate: (notification) {
              return notification.depth == 0 &&
                  notification.metrics.axis == Axis.vertical;
            },
            child: SingleChildScrollView(
              physics: listPhysics,
              primary: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: maxH),
                child: SizedBox(
                  width: maxW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PeriodProductsHeadWide(),
                      for (var i = 0; i < vm.productsSummary.length; i++)
                        _PeriodProductsRowWide(
                          row: vm.productsSummary[i],
                          stripe: i.isOdd,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final emptyBody = Padding(
      padding: EdgeInsets.fromLTRB(hPad + 8, 24, hPad + 8, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: emptyMinHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.posInvSalesNoSalesTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(
                  context,
                )!.posInvSalesNoSalesSubtitleFriendly,
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.isLoading)
          const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.primaryLight,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final paneW = constraints.maxWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      tablet ? 16 : 20,
                      hPad,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: tablet && wideManual
                                  ? 800
                                  : double.infinity,
                            ),
                            child: _ManualRangeStrip(
                              draftFromLabel: DateFormat(
                                'y-MM-dd',
                              ).format(_draftFrom ?? range.from),
                              draftToLabel: DateFormat(
                                'y-MM-dd',
                              ).format(_draftTo ?? range.toInclusive),
                              draftFromTimeLabel:
                                  InventorySalesViewModel.formatMinutesAs12h(
                                    _draftFromMinutes,
                                  ),
                              draftToTimeLabel:
                                  InventorySalesViewModel.formatMinutesAs12h(
                                    _draftToMinutes,
                                  ),
                              onTapFrom: () {
                                _pickDraftFrom();
                              },
                              onTapTo: () {
                                _pickDraftTo();
                              },
                              onTapFromTime: _pickDraftFromTime,
                              onTapToTime: _pickDraftToTime,
                              onClear: () => _clearFilters(),
                              onApply: () => _applyFilters(),
                              busy: vm.isLoading,
                              compact: tablet,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ExcludeSemantics(
                          child: _InventoryKpiGrid(
                            vm: vm,
                            maxWidth: math.max(0.0, paneW - 2 * hPad),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?banner,
                  if (vm.productsSummary.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: tablet ? 18 : 16,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: tablet ? 12 : 10),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.posInvSalesByItemPeriod,
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.posInvSalesItemsCount(vm.productsSummary.length),
                            style: TextStyle(
                              fontSize: sectionCountSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
                        child: LayoutBuilder(
                          builder: (context, c) {
                            return buildListPane(c.maxWidth, c.maxHeight);
                          },
                        ),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primaryLight,
                        onRefresh: () => vm.fetch(),
                        notificationPredicate: (notification) {
                          return notification.depth == 0 &&
                              notification.metrics.axis == Axis.vertical;
                        },
                        child: LayoutBuilder(
                          builder: (context, c) {
                            return SingleChildScrollView(
                              physics: listPhysics,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: c.maxHeight,
                                ),
                                child: emptyBody,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );

    return body;
  }
}

class _ManualRangeStrip extends StatelessWidget {
  const _ManualRangeStrip({
    required this.draftFromLabel,
    required this.draftToLabel,
    required this.draftFromTimeLabel,
    required this.draftToTimeLabel,
    required this.onTapFrom,
    required this.onTapTo,
    required this.onTapFromTime,
    required this.onTapToTime,
    required this.onClear,
    required this.onApply,
    required this.busy,
    this.compact = false,
  });

  final String draftFromLabel;
  final String draftToLabel;
  final String draftFromTimeLabel;
  final String draftToTimeLabel;
  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;
  final VoidCallback onTapFromTime;
  final VoidCallback onTapToTime;
  final Future<void> Function() onClear;
  final Future<void> Function() onApply;
  final bool busy;

  /// Tighter outer padding on tablets.
  final bool compact;

  static const double _gap = 8;

  /// Minimum logical width before we switch to horizontal scroll.
  static const double _fillMinWidth =
      128 * 2 + 112 * 2 + 92 * 2 + _gap * 6 + 32;

  @override
  Widget build(BuildContext context) {
    final fromBtn = _DatePill(
      title: AppLocalizations.of(context)!.posInvSalesStartDate,
      value: draftFromLabel,
      onTap: onTapFrom,
      icon: Icons.calendar_today_outlined,
      dense: true,
    );
    final toBtn = _DatePill(
      title: AppLocalizations.of(context)!.posInvSalesEndDate,
      value: draftToLabel,
      onTap: onTapTo,
      icon: Icons.event_available_outlined,
      dense: true,
    );
    final fromTimeBtn = _TimePill(
      title: AppLocalizations.of(context)!.posInvSalesStartTime,
      value: draftFromTimeLabel,
      onTap: onTapFromTime,
      dense: true,
    );
    final toTimeBtn = _TimePill(
      title: AppLocalizations.of(context)!.posInvSalesEndTime,
      value: draftToTimeLabel,
      onTap: onTapToTime,
      dense: true,
    );

    final vPad = compact ? 10.0 : 12.0;
    final hPadBtn = compact ? 10.0 : 12.0;
    final lblSz = compact ? 12.0 : 12.5;

    final clearBtn = FilledButton(
      onPressed: busy
          ? null
          : () async {
              await onClear();
            },
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: hPadBtn, vertical: vPad),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppLocalizations.of(context)!.posInvSalesClear,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: lblSz),
      ),
    );

    final applyBtn = FilledButton(
      onPressed: busy
          ? null
          : () async {
              await onApply();
            },
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondaryLight,
        foregroundColor: AppColors.onSecondaryLight,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: hPadBtn, vertical: vPad),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppLocalizations.of(context)!.posInvSalesApply,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: lblSz),
      ),
    );

    Widget hGap() => const SizedBox(width: _gap);

    return LayoutBuilder(
      builder: (context, cons) {
        final fill = cons.maxWidth >= _fillMinWidth;
        if (fill) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 26, child: fromBtn),
              hGap(),
              Expanded(flex: 26, child: toBtn),
              hGap(),
              Expanded(flex: 22, child: fromTimeBtn),
              hGap(),
              Expanded(flex: 22, child: toTimeBtn),
              hGap(),
              clearBtn,
              hGap(),
              applyBtn,
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 128, child: fromBtn),
              hGap(),
              SizedBox(width: 128, child: toBtn),
              hGap(),
              SizedBox(width: 112, child: fromTimeBtn),
              hGap(),
              SizedBox(width: 112, child: toTimeBtn),
              hGap(),
              clearBtn,
              hGap(),
              applyBtn,
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tablet = PosTabletLayout.isTablet(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 8 : 10,
        vertical: tablet ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tablet ? 8.0 : 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
              height: 1.2,
              color: AppColors.secondaryLight,
            ),
          ),
          SizedBox(height: tablet ? 8 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: LocalizedApiText(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: tablet ? 16 : 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: AppColors.secondaryLight,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.title,
    required this.value,
    required this.onTap,
    required this.icon,
    this.dense = false,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final IconData icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hp = dense ? 10.0 : 16.0;
    final vp = dense ? 8.0 : 12.0;
    final iconInset = dense ? 6.0 : 8.0;
    final iconSize = dense ? 16.0 : 18.0;
    final gap = dense ? 8.0 : 12.0;
    final titleSize = dense ? 7.5 : 9.0;
    final valueSize = dense ? 12.0 : 14.0;

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hp, vertical: vp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconInset),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.secondaryLight,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: dense ? 0.6 : 0.8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LocalizedApiText(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.2,
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
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.title,
    required this.value,
    required this.onTap,
    this.dense = false,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hp = dense ? 10.0 : 14.0;
    final vp = dense ? 8.0 : 10.0;
    final iconInset = dense ? 6.0 : 7.0;
    final iconSize = dense ? 15.0 : 17.0;
    final gap = dense ? 8.0 : 10.0;
    final titleSize = dense ? 7.5 : 9.0;
    final valueSize = dense ? 12.0 : 13.0;

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hp, vertical: vp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconInset),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: iconSize,
                  color: AppColors.secondaryLight,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: dense ? 0.6 : 0.8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LocalizedApiText(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.2,
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
}

class _PeriodProductsHeadWide extends StatelessWidget {
  const _PeriodProductsHeadWide();

  @override
  Widget build(BuildContext context) {
    final tablet = PosTabletLayout.isTablet(context);
    final hdrSize = tablet ? 9.5 : 9.0;
    TextStyle hdr() => TextStyle(
      fontSize: hdrSize,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w900,
      color: Colors.grey.shade600,
    );

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 14 : 16,
        vertical: tablet ? 12 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _kFlexItem,
            child: Text(
              AppLocalizations.of(context)!.posInvSalesColItemName,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: hdr(),
            ),
          ),
          const SizedBox(width: _kInvTableColGap),
          Expanded(
            flex: _kFlexDept,
            child: Text(
              AppLocalizations.of(context)!.posInvSalesColDepartment,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: hdr(),
            ),
          ),
          const SizedBox(width: _kInvTableColGap),
          Expanded(
            flex: _kFlexType,
            child: Text(
              AppLocalizations.of(context)!.posInvSalesColType,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: hdr(),
            ),
          ),
          const SizedBox(width: _kInvTableColGap),
          Expanded(
            flex: _kFlexSku,
            child: Padding(
              padding: const EdgeInsets.only(left: _kInvSkuLeftInset),
              child: Text(
                AppLocalizations.of(context)!.posInvSalesColSkuShort,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: hdr(),
              ),
            ),
          ),
          const SizedBox(width: _kInvTableColGap),
          Expanded(
            flex: _kFlexQty,
            child: Text(
              AppLocalizations.of(context)!.posInvSalesColQtyShort,
              textAlign: TextAlign.end,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: hdr(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodProductsRowWide extends StatelessWidget {
  const _PeriodProductsRowWide({required this.row, required this.stripe});

  final InventoryProductPeriodSummary row;
  final bool stripe;

  static String _qtyLine(double q) {
    if (q == q.roundToDouble()) return '${q.round()}';
    return q.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final skuText = row.sku != null && row.sku!.trim().isNotEmpty
        ? row.sku!.trim()
        : '—';
    final typeLabel = row.itemType.trim().isEmpty ? '—' : row.itemType.trim();
    final deptLabel = _dashStr(row.departmentName ?? row.departmentId);

    final tablet = PosTabletLayout.isTablet(context);
    TextStyle cellSecondary() => TextStyle(
      fontSize: tablet ? 11.5 : 11,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
      height: 1.2,
    );

    return Material(
      color: stripe ? const Color(0xFFFBFDFF) : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tablet ? 14 : 16,
          vertical: tablet ? 12 : 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _kFlexItem,
              child: LocalizedApiText(
                row.productName,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 13.5 : 13,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: _kInvTableColGap),
            Expanded(
              flex: _kFlexDept,
              child: LocalizedApiText(
                deptLabel,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: cellSecondary(),
              ),
            ),
            const SizedBox(width: _kInvTableColGap),
            Expanded(
              flex: _kFlexType,
              child: LocalizedApiText(
                typeLabel,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: cellSecondary(),
              ),
            ),
            const SizedBox(width: _kInvTableColGap),
            Expanded(
              flex: _kFlexSku,
              child: Padding(
                padding: const EdgeInsets.only(left: _kInvSkuLeftInset),
                child: LocalizedApiText(
                  skuText,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: cellSecondary(),
                ),
              ),
            ),
            const SizedBox(width: _kInvTableColGap),
            Expanded(
              flex: _kFlexQty,
              child: LocalizedApiText(
                _qtyLine(row.totalQty),
                textAlign: TextAlign.end,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 14.5 : 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 68, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          LocalizedApiText(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade800, height: 1.35),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context)!.posInvSalesRetry),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventorySalesLoadingShimmer extends StatelessWidget {
  const _InventorySalesLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final tablet = PosTabletLayout.isTablet(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tablet ? 18 : 12,
        tablet ? 10 : 12,
        tablet ? 18 : 12,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PosShimmer(
            child: PosShimmerBox(
              width: double.infinity,
              height: 40,
              radius: 14,
            ),
          ),
          const SizedBox(height: 10),
          PosShimmer(child: _chipRow(short: !tablet)),
          const SizedBox(height: 8),
          if (tablet) ...[
            PosShimmer(child: _chipRow(short: true)),
            const SizedBox(height: 8),
          ],
          Expanded(child: _inventoryList(tablet)),
        ],
      ),
    );
  }

  Widget _chipRow({bool short = false}) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: short ? 4 : 5,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) =>
            PosShimmerBox(width: i == 0 ? 70 : 94, height: 30, radius: 12),
      ),
    );
  }

  Widget _inventoryList(bool tablet) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tablet ? 8 : 5,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: tablet ? 2 : 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 8,
        mainAxisExtent: tablet ? 92 : 80,
      ),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: const PosShimmer(
          child: Row(
            children: [
              PosShimmerBox(width: 50, height: 50, radius: 12),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PosShimmerLine(width: double.infinity, height: 12),
                    SizedBox(height: 7),
                    PosShimmerLine(width: 112, height: 10),
                    SizedBox(height: 7),
                    PosShimmerLine(width: 70, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 8),
              PosShimmerBox(width: 44, height: 22, radius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
