import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'record_collection_view_model.dart';

// ── Entry point ────────────────────────────────────────────────────────────────

class RecordCollectionView extends StatelessWidget {
  /// Optional — pass a specific request to skip the picker and jump straight
  /// to its closing details (e.g. when opened from that request's own detail
  /// screen). Leave null for the default entry point, where the user first
  /// picks a request from the dropdown.
  final LockerRequest? request;

  const RecordCollectionView({super.key, this.request});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordCollectionViewModel(initialRequest: request),
      child: const _RecordCollectionBody(),
    );
  }
}

// ── Inner StatefulWidget ───────────────────────────────────────────────────────

class _RecordCollectionBody extends StatefulWidget {
  const _RecordCollectionBody();

  @override
  State<_RecordCollectionBody> createState() => _RecordCollectionBodyState();
}

class _RecordCollectionBodyState extends State<_RecordCollectionBody> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController   = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.read<RecordCollectionViewModel>().init(l10n);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Resets the form fields whenever a new request is selected, so stale
  // amounts/notes from a previous request never carry over.
  void _onRequestChanged(LockerRequest request, RecordCollectionViewModel vm) {
    _amountController.clear();
    _notesController.clear();
    vm.selectRequest(request);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<RecordCollectionViewModel>(
      builder: (context, vm, _) {
        return LockerShell(
          isSupervisor: vm.isSupervisor,
          currentItem: LockerSidebarItem.recordCollection,
          title: l10n.lockerRecordCollectionTitle,
          backgroundColor: OwnerUi.scaffoldBackground,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestPicker(context, vm),
                if (vm.hasSelection) ..._buildSelectedRequestSections(context, vm),
                if (vm.hasError) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(
                    message: vm.errorMessage!,
                    onDismiss: vm.resetError,
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Request picker (dropdown) ───────────────────────────────────────────────

  Widget _buildRequestPicker(
      BuildContext context, RecordCollectionViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerLabelRequest,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        if (vm.loadingRequests)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: OwnerCardRowShimmer(),
          )
        else
          OwnerStyledDropdown<String>(
            value: vm.selectedRequest?.id,
            hint: l10n.lockerSelectRequest,
            height: 48,
            backgroundColor: Colors.white,
            borderColor: OwnerListStyle.cardBorder,
            triggerStyle: const TextStyle(
              color: AppColors.secondaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            options: [
              for (final r in vm.pendingRequests)
                OwnerDropdownOption(
                  value: r.id,
                  label:
                      '${r.referenceCode} — ${r.translatedBranchName ?? r.branchName} — '
                      '${r.translatedCashierName ?? r.cashierName} — '
                      '${l10n.lockerSarCurrency} ${r.lockedCashAmount.toStringAsFixed(2)}',
                ),
            ],
            onChanged: (id) {
              if (id == null) return;
              final picked =
                  vm.pendingRequests.firstWhere((r) => r.id == id);
              _onRequestChanged(picked, vm);
            },
          ),
        if (vm.requestsError != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(
            message: vm.requestsError!,
            onDismiss: () => vm.loadPendingRequests(),
          ),
        ],
      ],
    );
  }

  // ── Sections shown once a request is selected ───────────────────────────────

  List<Widget> _buildSelectedRequestSections(
      BuildContext context, RecordCollectionViewModel vm) {
    if (vm.loadingDetail) {
      return [
        const SizedBox(height: 24),
        const OwnerSectionCardShimmer(rowCount: 2),
        const SizedBox(height: 16),
        const OwnerCardRowShimmer(),
        const SizedBox(height: 10),
        const OwnerCardRowShimmer(),
      ];
    }

    if (vm.detailError != null) {
      return [
        const SizedBox(height: 16),
        _ErrorBanner(
          message: vm.detailError!,
          onDismiss: () => vm.selectRequest(vm.selectedRequest!),
        ),
      ];
    }

    final detail = vm.selectedDetail;
    if (detail == null) return const [];

    return [
      const SizedBox(height: 24),
      _buildAssetSummaryCard(context, vm, detail),
      const SizedBox(height: 32),
      _buildCounterClosingSection(context, vm, detail),
      const SizedBox(height: 24),
      _buildNotesSection(context),
      const SizedBox(height: 32),
      _buildEvidenceSection(context, vm),
    ];
  }

  // ── Asset summary card ─────────────────────────────────────────────────────

  Widget _buildAssetSummaryCard(BuildContext context,
      RecordCollectionViewModel vm, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final request = vm.selectedRequest!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: OwnerListStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const OwnerListIconBox(
                  icon: Icons.account_balance_wallet_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lockerExpectedAmount,
                      style: OwnerListStyle.metaStyle.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${l10n.lockerSarCurrency} ${vm.expectedAmount.toStringAsFixed(0)}',
                      style: OwnerListStyle.titleStyle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.referenceCode,
                      style: OwnerListStyle.subtitleStyle.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: OwnerListStyle.cardBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniInfo(
                  l10n.lockerLabelBranch,
                  request.translatedBranchName ?? detail.branchName,
                ),
              ),
              Expanded(
                child: _buildMiniInfo(
                  l10n.lockerLabelCashier,
                  request.translatedCashierName ?? detail.cashierName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontWeight: FontWeight.w900,
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Counter closing (cash entry + reference methods) ───────────────────────

  Widget _buildCounterClosingSection(BuildContext context,
      RecordCollectionViewModel vm, LockerRequestDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final isSubmitting = vm.isSubmitting;
    final cc = detail.counterClosing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerLabelCounterClosing,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.lockerCashHelper,
          style: TextStyle(
            color: Colors.black.withOpacity(0.35),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),

        // ── Cash — the only editable amount ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: OwnerListStyle.cardDecoration,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  l10n.lockerLabelCash,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  textAlign: TextAlign.end,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isSubmitting,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${l10n.lockerSarCurrency} ',
                    prefixStyle: TextStyle(
                      color: AppColors.secondaryLight.withOpacity(0.25),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.08)),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ),
        ),

        // ── Reference-only methods ───────────────────────────────────────────
        if (cc != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: OwnerListStyle.cardDecoration,
            child: Column(
              children: [
                _buildReferenceMethodRow(l10n.lockerPayBank, cc.bank.system,
                    currency: l10n.lockerSarCurrency),
                _buildReferenceDivider(),
                _buildReferenceMethodRow(l10n.lockerPayTabby, cc.tabby.system,
                    currency: l10n.lockerSarCurrency),
                _buildReferenceDivider(),
                _buildReferenceMethodRow(l10n.lockerPayTamara, cc.tamara.system,
                    currency: l10n.lockerSarCurrency),
                _buildReferenceDivider(),
                _buildReferenceMethodRow(l10n.lockerPayCorporate, cc.corporate.system,
                    isLast: true, currency: l10n.lockerSarCurrency),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        _buildDifferenceSummary(context, vm),
      ],
    );
  }

  Widget _buildReferenceDivider() =>
      const Divider(height: 1, color: Color(0x11000000));

  Widget _buildReferenceMethodRow(String label, double systemAmount,
      {bool isLast = false, String currency = 'SAR'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            '$currency ${systemAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Difference summary ─────────────────────────────────────────────────────

  Widget _buildDifferenceSummary(
      BuildContext context, RecordCollectionViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final received   = double.tryParse(_amountController.text) ?? 0;
    final expected   = vm.expectedAmount;
    final difference = expected - received;

    Color  diffColor    = Colors.green;
    String statusLabel  = l10n.lockerStatusMatched;

    if (difference > 0) {
      diffColor   = Colors.red;
      statusLabel = l10n.lockerShortLabel;
    } else if (difference < 0) {
      diffColor   = Colors.teal;
      statusLabel = l10n.lockerOverLabel;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: diffColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: diffColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildDiffRow(
            l10n.lockerLockedAmount,
            '${l10n.lockerSarCurrency} ${expected.toStringAsFixed(0)}',
            Colors.black38,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Colors.black12),
          ),
          _buildDiffRow(
            l10n.lockerReceivedAmountLabel,
            '${l10n.lockerSarCurrency} ${received.toStringAsFixed(0)}',
            Colors.black38,
          ),
          const SizedBox(height: 12),
          _buildDiffRow(
            l10n.lockerDifference,
            '${l10n.lockerSarCurrency} ${difference.abs().toStringAsFixed(0)}',
            diffColor,
            isMain: true,
            suffix: statusLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildDiffRow(
      String label,
      String value,
      Color color, {
        bool isMain = false,
        String? suffix,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontWeight: FontWeight.w900,
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
        Row(
          children: [
            if (suffix != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  suffix,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: isMain ? 18 : 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Notes ───────────────────────────────────────────────────────────────────

  Widget _buildNotesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerCollectionNotes,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: OwnerListStyle.cardDecoration,
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: l10n.lockerCollectionNotesHint,
              hintStyle:
              TextStyle(color: Colors.black.withOpacity(0.15), fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Evidence + submit ──────────────────────────────────────────────────────

  Widget _buildEvidenceSection(
      BuildContext context, RecordCollectionViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerCollectionEvidence,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.lockerAttachPhotoHint,
          style: TextStyle(
            color: Colors.black.withOpacity(0.35),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),

        // ── Image area ──────────────────────────────────────────────────────
        vm.hasImage
            ? _buildImagePreview(context, vm)
            : _buildImagePickerButton(context, vm),

        const SizedBox(height: 24),

        // ── Submit button ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
            vm.isSubmitting ? null : () => _handleSubmit(context, vm),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.secondaryLight,
              disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: vm.isSubmitting
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.secondaryLight,
              ),
            )
                : Text(
              l10n.lockerConfirmFinalise,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Shown when no image is picked yet — a dashed-border tap target that
  /// opens the source picker sheet.
  Widget _buildImagePickerButton(
      BuildContext context, RecordCollectionViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showImageSourceSheet(context, vm),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondaryLight.withOpacity(0.15),
            width: 1.5,
            // Simulated dashed look — actual dashing needs a custom painter,
            // but a thin solid border with the subdued colour reads well.
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: AppColors.secondaryLight,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.lockerTapToAddPhoto,
              style: TextStyle(
                color: AppColors.secondaryLight.withOpacity(0.6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.lockerCameraOrGallery,
              style: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown once an image has been picked — the full preview with a remove
  /// button (top-right) and a retake button (bottom bar).
  Widget _buildImagePreview(
      BuildContext context, RecordCollectionViewModel vm) {
    return Stack(
      children: [
        // ── Preview ──────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            vm.pickedImageBytes!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),

        // ── Remove (×) button — top-right ────────────────────────────────────
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: vm.clearImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),

        // ── Retake bar — bottom ───────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showImageSourceSheet(context, vm),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.lockerRetakeChange,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom sheet that lets the user choose between Camera and Gallery.
  /// Uses a modal sheet so it works identically on all Android versions.
  void _showImageSourceSheet(
      BuildContext context, RecordCollectionViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onCamera: () {
          Navigator.pop(context);
          vm.pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          vm.pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  // ── Submit handler ─────────────────────────────────────────────────────────

  Future<void> _handleSubmit(
      BuildContext context, RecordCollectionViewModel vm) async {
    final l10n     = AppLocalizations.of(context)!;
    final received = double.tryParse(_amountController.text);

    if (received == null || received <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lockerEnterValidAmount),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await vm.submit(
      receivedAmount: received,
      notes: _notesController.text.trim(),
      // proofUrl not passed — RecordCollectionViewModel.submit() automatically
      // uses the picked image's base64 data-URI when no explicit URL is given.
    );

    if (!mounted) return;
    if (success) {
      final result = vm.result!;
      _showSuccessSheet(context, result);
    }
  }

  // ── Success bottom sheet ───────────────────────────────────────────────────

  void _showSuccessSheet(BuildContext context, CollectionResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _SuccessSheet(
        result: result,
        onDone: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close RecordCollectionView
        },
      ),
    );
  }
}

// ── Image source picker sheet ───────────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImageSourceSheet({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.lockerAddPhoto,
            style: TextStyle(
              color: AppColors.secondaryLight.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _SourceOption(
            icon: Icons.camera_alt_rounded,
            label: l10n.lockerTakePhoto,
            subtitle: l10n.lockerOpenCamera,
            onTap: onCamera,
          ),
          const SizedBox(height: 10),
          _SourceOption(
            icon: Icons.photo_library_rounded,
            label: l10n.lockerChooseGallery,
            subtitle: l10n.lockerPickExistingPhoto,
            onTap: onGallery,
          ),
          const SizedBox(height: 10),
          // Cancel
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black45,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                l10n.lockerCancel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OwnerUi.contentBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: AppColors.secondaryLight, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.black26, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Success sheet ──────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final CollectionResult result;
  final VoidCallback onDone;

  const _SuccessSheet({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final l10n       = AppLocalizations.of(context)!;
    final hasDiff    = result.hasDifference;
    final isPending  = result.isPendingApproval;
    final accentColor = hasDiff ? Colors.orange : Colors.green;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        top: 32,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending
                  ? Icons.hourglass_top_rounded
                  : Icons.check_circle_outline_rounded,
              color: accentColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPending
                ? l10n.lockerSuccessPendingApproval
                : l10n.lockerSuccessCollectionRecorded,
            style: const TextStyle(
              color: AppColors.secondaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: OwnerUi.contentBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCell(
                  label: l10n.lockerReceivedLabel,
                  value: '${l10n.lockerSarCurrency} ${result.receivedAmount.toStringAsFixed(0)}',
                  color: Colors.teal,
                ),
                Container(width: 1, height: 40, color: Colors.black.withOpacity(0.06)),
                _StatCell(
                  label: l10n.lockerDiffLabel,
                  value: '${l10n.lockerSarCurrency} ${result.difference.abs().toStringAsFixed(0)}',
                  color: hasDiff ? Colors.red : Colors.green,
                ),
                Container(width: 1, height: 40, color: Colors.black.withOpacity(0.06)),
                _StatCell(
                  label: l10n.lockerStatusLabel,
                  value: isPending ? l10n.lockerStatusReview : l10n.lockerStatusOk,
                  color: accentColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.secondaryLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.lockerDone,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.red.shade300, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}