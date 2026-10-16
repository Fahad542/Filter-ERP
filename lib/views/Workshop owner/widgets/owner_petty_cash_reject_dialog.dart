import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/toast_service.dart';

Future<void> showPettyCashRejectRequestDialog(
  BuildContext context, {
  required Future<bool> Function(String reason) onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (ctx) => _PettyCashRejectDialogBody(onConfirm: onConfirm),
  );
}

class _PettyCashRejectDialogBody extends StatefulWidget {
  final Future<bool> Function(String reason) onConfirm;

  const _PettyCashRejectDialogBody({required this.onConfirm});

  @override
  State<_PettyCashRejectDialogBody> createState() =>
      _PettyCashRejectDialogBodyState();
}

class _PettyCashRejectDialogBodyState extends State<_PettyCashRejectDialogBody> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reject Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please provide a reason for rejection.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Budget not approved',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final reason = _reasonController.text.trim();
                      if (reason.isEmpty) {
                        ToastService.showError(
                          context,
                          'Please enter a rejection reason',
                        );
                        return;
                      }
                      Navigator.pop(context);
                      final ok = await widget.onConfirm(reason);
                      if (!context.mounted) return;
                      if (ok) {
                        ToastService.showSuccess(
                          context,
                          'Request rejected successfully',
                        );
                      } else {
                        ToastService.showError(
                          context,
                          'Failed to reject request',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm Reject',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
