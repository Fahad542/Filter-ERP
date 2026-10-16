import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import 'current_shift_view_model.dart';


String _shiftLang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _shiftDigits(BuildContext context, Object? value) {
  return AppTranslationService.localizeDigitsForLanguage(
    value?.toString() ?? '',
    _shiftLang(context),
  );
}

String _shiftStatusLabel(BuildContext context, String status) {
  final lang = _shiftLang(context);
  final s = status.trim().toLowerCase().replaceAll('_', ' ');
  if (lang == 'ar') {
    if (s == 'active' || s == 'open' || s == 'opened') return 'نشط';
    if (s == 'inactive' || s == 'closed') return 'غير نشط';
    if (s == 'pending') return 'قيد الانتظار';
  }
  return status.trim().isEmpty ? '—' : status.trim().toUpperCase();
}

String _shiftElapsedText(BuildContext context, String raw) {
  final lang = _shiftLang(context);
  var text = raw.trim();
  if (text.isEmpty) return '—';
  if (lang == 'ar') {
    text = text
        .replaceAll(RegExp(r'\bhours?\b', caseSensitive: false), 'س')
        .replaceAll(RegExp(r'\bhrs?\b', caseSensitive: false), 'س')
        .replaceAll(RegExp(r'\bh\b', caseSensitive: false), 'س')
        .replaceAll(RegExp(r'\bminutes?\b', caseSensitive: false), 'د')
        .replaceAll(RegExp(r'\bmins?\b', caseSensitive: false), 'د')
        .replaceAll(RegExp(r'\bm\b', caseSensitive: false), 'د');
  }
  return _shiftDigits(context, text);
}

class PosCurrentShiftView extends StatefulWidget {
  const PosCurrentShiftView({super.key});

  @override
  State<PosCurrentShiftView> createState() => _PosCurrentShiftViewState();
}

class _PosCurrentShiftViewState extends State<PosCurrentShiftView> {
  @override
  void initState() {
    super.initState();
    // Fetch is handled by pos_shell when the tab is pressed
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CurrentShiftViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PosScreenAppBar(
        title: l10n.posCurrentShiftTitle,
        showBackButton: false,
        showHamburger: true,
        onMenuPressed: () =>
            PosShellScaffoldRegistry.openDrawer(),
      ),
      body: wrapPosShellRailBody(context, _buildBody(vm, l10n)),
    );
  }

  Widget _buildBody(CurrentShiftViewModel vm, AppLocalizations l10n) {
    if (vm.isLoading) {
      return const _CurrentShiftShimmer();
    }

    if (vm.errorMessage != null && vm.currentSession == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            LocalizedApiText(vm.errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => vm.fetchCurrentSession(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.posCurrentShiftRetry, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final session = vm.currentSession;
    if (session == null) {
      return Center(child: Text(l10n.posCurrentShiftNoActiveSession));
    }

    // Attempt to format the date
    String parsedDate = session.openedAt;
    try {
      final dateTime = DateTime.parse(session.openedAt);
      parsedDate = _shiftDigits(context, DateFormat('dd MMM yyyy, hh:mm a', _shiftLang(context)).format(dateTime));
    } catch (_) {}

    return RefreshIndicator(
      onRefresh: () async => vm.fetchCurrentSession(),
      color: AppColors.primaryLight,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondaryLight, Color(0xFF2C3136)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryLight.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.posCurrentShiftDetails,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _shiftStatusLabel(context, session.status),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => vm.fetchCurrentSession(),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildInfoTile(l10n.posCurrentShiftLabelCashier, session.cashierName, Icons.person_rounded),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 20)),
                    _buildInfoTile(l10n.posCurrentShiftLabelSessionId, '#${_shiftDigits(context, session.posSessionId)}', Icons.tag_rounded),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildInfoTile(l10n.posCurrentShiftLabelBranch, session.branchName, Icons.storefront_rounded),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 20)),
                    _buildInfoTile(l10n.posCurrentShiftLabelElapsedTime, _shiftElapsedText(context, session.elapsedTime), Icons.timer_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(l10n.posCurrentShiftLabelOpenedAt, parsedDate, Icons.access_time_rounded),
          const Divider(height: 32),
          _buildDetailRow(l10n.posCurrentShiftLabelBranchAddress, session.branchAddress, Icons.location_on_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LocalizedApiText(
            _shiftDigits(context, value),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.secondaryLight, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              LocalizedApiText(_shiftDigits(context, value), style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}


class _CurrentShiftShimmer extends StatelessWidget {
  const _CurrentShiftShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3136),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const PosShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosShimmerBox(width: 115, height: 10, radius: 6, dark: true),
                        SizedBox(height: 10),
                        PosShimmerBox(width: 58, height: 20, radius: 8, dark: true),
                      ],
                    ),
                    PosShimmerBox(width: 38, height: 38, radius: 19, dark: true),
                  ],
                ),
                SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(child: _ShiftInfoTileShimmer()),
                    SizedBox(width: 24),
                    Expanded(child: _ShiftInfoTileShimmer()),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _ShiftInfoTileShimmer()),
                    SizedBox(width: 24),
                    Expanded(child: _ShiftInfoTileShimmer()),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const PosShimmer(child: _ShiftDetailRowShimmer()),
        const Divider(height: 32),
        const PosShimmer(child: _ShiftDetailRowShimmer(wide: true)),
      ],
    );
  }
}

class _ShiftInfoTileShimmer extends StatelessWidget {
  const _ShiftInfoTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PosShimmerBox(width: 14, height: 14, radius: 7, dark: true),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              PosShimmerBox(width: 72, height: 9, radius: 5, dark: true),
              SizedBox(height: 8),
              PosShimmerBox(width: 118, height: 14, radius: 7, dark: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiftDetailRowShimmer extends StatelessWidget {
  const _ShiftDetailRowShimmer({this.wide = false});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PosShimmerBox(width: 40, height: 40, radius: 12),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PosShimmerBox(width: 95, height: 10, radius: 5),
              const SizedBox(height: 8),
              PosShimmerBox(width: wide ? 260 : 165, height: 15, radius: 7),
            ],
          ),
        ),
      ],
    );
  }
}
