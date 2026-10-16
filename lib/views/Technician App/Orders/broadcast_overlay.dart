import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/technician_broadcast_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/toast_service.dart';
import '../technician_view_model.dart';

class BroadcastOverlay extends StatelessWidget {
  const BroadcastOverlay({super.key});

  /// Material 3 ignores `disabledBackgroundColor` on `styleFrom`; force same fill when sibling is busy.
  static ButtonStyle _solidActionStyle({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color?>(backgroundColor),
      foregroundColor: MaterialStateProperty.all<Color?>(foregroundColor),
      iconColor: MaterialStateProperty.all<Color?>(foregroundColor),
      elevation: MaterialStateProperty.all<double>(0),
      shadowColor: MaterialStateProperty.all<Color?>(Colors.transparent),
      surfaceTintColor: MaterialStateProperty.all<Color?>(Colors.transparent),
      shape: MaterialStateProperty.all<OutlinedBorder>(shape),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<TechAppViewModel, ({bool show, int timerSecs, String? jobId})>(
      selector: (_, vm) => (
        show: vm.showBroadcastAcceptanceUi,
        timerSecs: vm.broadcastTimerSeconds,
        jobId: vm.primaryBroadcast?.jobId,
      ),
      builder: (context, state, _) {
        if (!state.show) return const SizedBox.shrink();

        final vm = context.read<TechAppViewModel>();
        if (!vm.hasActiveBroadcast) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        final b = vm.primaryBroadcast!;
        final title = b.displayTitle;
        final modeLabel = _modeLabel(b.broadcastMode, l10n);
        final amountLabel = b.amountLabel;
        final hasAmount = amountLabel != null && amountLabel.toString().trim().isNotEmpty;
        final ringTotal = vm.broadcastRingTotalSecs;
        final progress = ringTotal > 0 ? (state.timerSecs / ringTotal).clamp(0.0, 1.0) : 0.0;

        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
                    ],
                  ),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimer(state.timerSecs, progress),
                        const SizedBox(height: 24),
                        Text(
                          l10n.techBroadcastOverlayTitle,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        if (modeLabel != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            modeLabel,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (hasAmount) ...[
                          const SizedBox(height: 16),
                          Text(
                            amountLabel.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildActionButtons(context, vm, b, l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _modeLabel(String? mode, AppLocalizations l10n) {
    if (mode == null || mode.isEmpty) return null;
    final m = mode.toLowerCase();
    if (m.contains('on_call') || m.contains('oncall')) {
      return l10n.techBroadcastOverlayOnCall;
    }
    if (m.contains('workshop')) return l10n.techBroadcastOverlayWorkshop;
    return mode;
  }

  Widget _buildTimer(int seconds, double progressValue) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    final timeStr = '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: Colors.grey.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
          ),
        ),
        Text(
          timeStr,
          style: const TextStyle(
            decoration: TextDecoration.none,
            color: AppColors.secondaryLight,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    TechAppViewModel vm,
    TechBroadcast b,
    AppLocalizations l10n,
  ) {
    final jobId = b.jobId;
    final acceptBusy = vm.isBroadcastAcceptBusy(jobId);
    final rejectBusy = vm.isBroadcastRejectBusy(jobId);
    final anyBusy = acceptBusy || rejectBusy;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: anyBusy
                  ? null
                  : () async {
                      final ok = await vm.rejectBroadcastJob(context, jobId);
                      if (!context.mounted) return;
                      if (!ok) {
                        ToastService.showError(
                          context,
                          l10n.techBroadcastCouldNotDecline,
                        );
                      }
                    },
              style: _solidActionStyle(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: AppColors.onSecondaryLight,
              ),
              child: rejectBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSecondaryLight),
                    )
                  : Text(
                      l10n.techBroadcastOverlayDecline,
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: anyBusy
                  ? null
                  : () async {
                      final ok = await vm.acceptBroadcastJob(context, jobId);
                      if (!context.mounted) return;
                      if (!ok) {
                        ToastService.showError(
                          context,
                          l10n.techBroadcastCouldNotAccept,
                        );
                      }
                    },
              style: _solidActionStyle(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.black87,
              ),
              child: acceptBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                    )
                  : Text(
                      l10n.techBroadcastOverlayAccept,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
