import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

/// Equal-width Cancel / Save footer for owner bottom sheets.
/// Cancel = secondary, Save = primary.
///
/// Save pe loader:
/// - [isLoading] true hone par text hide + spinner
/// - [onPrimary] agar [Future] return kare to loader auto trigger hota hai
class OwnerSheetActions extends StatefulWidget {
  final VoidCallback onCancel;
  final FutureOr<void> Function()? onPrimary;
  final String cancelLabel;
  final String primaryLabel;
  final bool isLoading;

  const OwnerSheetActions({
    super.key,
    required this.onCancel,
    required this.onPrimary,
    this.cancelLabel = 'Cancel',
    this.primaryLabel = 'Save',
    this.isLoading = false,
  });

  @override
  State<OwnerSheetActions> createState() => _OwnerSheetActionsState();
}

class _OwnerSheetActionsState extends State<OwnerSheetActions> {
  bool _internalLoading = false;

  bool get _loading => widget.isLoading || _internalLoading;

  Future<void> _handlePrimary() async {
    final cb = widget.onPrimary;
    if (cb == null || _loading) return;

    final result = cb();
    if (result is! Future) return;

    setState(() => _internalLoading = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => _internalLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loading;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: loading ? null : widget.onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.secondaryLight.withValues(alpha: 0.55),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                widget.cancelLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: loading || widget.onPrimary == null
                  ? null
                  : _handlePrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.secondaryLight,
                // Loading ke dauran bhi solid primary — loader clear dikhe
                disabledBackgroundColor: AppColors.primaryLight,
                disabledForegroundColor: AppColors.secondaryLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.secondaryLight,
                      ),
                    )
                  : Text(
                      widget.primaryLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
