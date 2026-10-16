import 'package:flutter/material.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_sheet_actions.dart';
import 'inventory_management_view.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  UOM PROFILES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class UomProfilesTab extends StatelessWidget {
  final InventoryV2ViewModel vm;
  const UomProfilesTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explainer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.ownerInventoryUomExplainer,
                  style: const TextStyle(
                      color: AppColors.secondaryLight, fontSize: 11, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),

              // ── UOM Profiles table ──────────────────────────────────
              Text(AppLocalizations.of(context)!.ownerInventoryTabUomProfiles,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryLight)),
              const SizedBox(height: 10),

              UomProfileDataTable(
                profiles: vm.uomProfiles,
                onDelete: (id) => vm.deleteUomProfile(id),
              ),

              const SizedBox(height: 24),

              // ── Link profile to product ─────────────────────────────
              Text(AppLocalizations.of(context)!.ownerInventoryLinkProfileTitle,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryLight)),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.ownerInventoryLinkProfileSubtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 10),

              ...kInventoryProducts.map((p) {
                final linked = vm.uomProfiles
                    .cast<UomProfile?>()
                    .firstWhere(
                        (prof) => prof!.linkedProductIds.contains(p.id),
                    orElse: () => null);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedApiText(p.name,
                                style: const TextStyle(
                                    color: AppColors.secondaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('${AppLocalizations.of(context)!.ownerCommonSku}: ${p.sku}  ·  ',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: linked != null
                                        ? const Color(0xFFEBF1FF)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    linked != null ? linked.ruleLabel : p.unit,
                                    style: TextStyle(
                                      color: linked != null
                                          ? Color(0xFF2563EB)
                                          : Colors.grey.shade500,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showLinkUomFromProfileTab(context, vm, p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: linked != null ? const Color(0xFFEBF1FF) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: linked != null
                                  ? Color(0xFF2563EB).withValues(alpha: 0.3)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(linked != null ? Icons.edit_rounded : Icons.link_rounded,
                                  size: 12,
                                  color: linked != null ? Color(0xFF2563EB) : AppColors.secondaryLight),
                              const SizedBox(width: 4),
                              Text(
                                linked != null
                                    ? AppLocalizations.of(context)!.ownerInventoryChange
                                    : AppLocalizations.of(context)!.ownerInventoryLink,
                                style: TextStyle(
                                    color: linked != null ? Color(0xFF2563EB) : AppColors.secondaryLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // ── FAB — Create Profile ────────────────────────────────────────
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showNewProfileDialog(context, vm),
            backgroundColor: AppColors.secondaryLight,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              AppLocalizations.of(context)!.ownerInventoryNewProfile,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _showNewProfileDialog(
      BuildContext context, InventoryV2ViewModel vm) {
    showDialog(
      context: context,
      builder: (_) =>
          ChangeNotifierProvider.value(value: vm, child: const NewProfileDialog()),
    );
  }

  void _showLinkUomFromProfileTab(
      BuildContext context, InventoryV2ViewModel vm, InvProduct p) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: LinkUomDialog(product: p),
      ),
    );
  }
}

// ─── UOM Profile Card List ────────────────────────────────────────────────────

class UomProfileDataTable extends StatelessWidget {
  final List<UomProfile> profiles;
  final ValueChanged<String> onDelete;

  const UomProfileDataTable({
    super.key,
    required this.profiles,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.ownerInventoryNoProfilesYet,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: profiles
          .map((prof) => _UomProfileCard(
                profile: prof,
                onDelete: () => onDelete(prof.id),
              ))
          .toList(),
    );
  }
}

class _UomProfileCard extends StatelessWidget {
  final UomProfile profile;
  final VoidCallback onDelete;

  const _UomProfileCard({required this.profile, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final prof = profile;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name row + delete ──────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sync_alt_rounded,
                    size: 18, color: AppColors.secondaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prof.name,
                      style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (prof.notes != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        prof.notes!,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            AppColors.errorLight.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 13, color: AppColors.errorLight),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(context)!.ownerCommonDelete,
                          style: TextStyle(
                              color: AppColors.errorLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),

          // ── Rule + linked products ─────────────────────────────────
          Row(
            children: [
              // Rule pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      prof.ruleLabel,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Linked count pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppLocalizations.of(context)!.ownerInventoryLinkedProducts(
                    ownerLocalizeDigits(context, '${prof.linkedProductIds.length}'),
                  ),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─── UOM Unit Chip ──────────────────────────────────────────────────────────

class _UomUnitChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  const _UomUnitChip(this.label, {this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Link UOM Dialog ────────────────────────────────────────────────────────

class LinkUomDialog extends StatefulWidget {
  final InvProduct product;
  const LinkUomDialog({super.key, required this.product});

  @override
  State<LinkUomDialog> createState() => _LinkUomDialogState();
}

class _LinkUomDialogState extends State<LinkUomDialog> {
  String? _selectedProfileId; // null = no profile

  @override
  void initState() {
    super.initState();
    final vm = context.read<InventoryV2ViewModel>();
    // Pre-select currently linked profile if any
    final linked = vm.uomProfiles.cast<UomProfile?>().firstWhere(
          (p) => p!.linkedProductIds.contains(widget.product.id),
      orElse: () => null,
    );
    _selectedProfileId = linked?.id;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventoryV2ViewModel>();
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Link UOM profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Product info card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedApiText(
                      widget.product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.sku,
                      style: TextStyle(
                          color: theme.colorScheme.primary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── UOM Profile label ──
              const Text(
                'UOM PROFILE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryLight,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),

              // ── Dropdown ──
              DropdownButtonFormField<String?>(
                value: _selectedProfileId,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                decoration: InputDecoration(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 1.5),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— No profile (use product unit) —',
                        style: TextStyle(fontSize: 12)),
                  ),
                  ...vm.uomProfiles.map((prof) => DropdownMenuItem<String?>(
                    value: prof.id,
                    child: Text(
                      '${prof.name} — ${prof.ruleLabel}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedProfileId = v),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // ── Buttons ──
              OwnerSheetActions(
                onCancel: () => Navigator.pop(context),
                onPrimary: () {
                  // TODO: replace with your actual VM method signature
                  // e.g. vm.linkUomProfile(widget.product.id, _selectedProfileId);
                  Navigator.pop(context);
                },
                primaryLabel: 'Save link',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── New Profile Dialog ──────────────────────────────────────────────────────

const _kWarehouseUnits = [
  'Box', 'Carton', 'Dozen', 'Pack', 'Drum', 'Bag', 'liter', 'pcs'
];
const _kWorkshopUnits = [
  'pcs', 'Liter', 'liter', 'kg', 'ml', 'Set', 'piece'
];

class NewProfileDialog extends StatefulWidget {
  const NewProfileDialog({super.key});

  @override
  State<NewProfileDialog> createState() => _NewProfileDialogState();
}

class _NewProfileDialogState extends State<NewProfileDialog> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  String _warehouseUnit = 'Box';
  String _workshopUnit = 'Liter';

  String get _rulePreview =>
      '1 $_warehouseUnit = ${_qtyCtrl.text.isEmpty ? '?' : _qtyCtrl.text} $_workshopUnit';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New UOM profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Profile Name ──
              _label('PROFILE NAME *'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: _inputDecor(
                    context, 'e.g. Box → Liter (12)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // ── Conversion row ──
              Center(
                child: Text('1 =',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warehouse unit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('WAREHOUSE / PACKING UNIT'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _warehouseUnit,
                          decoration: _inputDecor(context, ''),
                          items: _kWarehouseUnits
                              .map((u) => DropdownMenuItem(
                              value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _warehouseUnit = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Qty
                  SizedBox(
                    width: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 22),
                        TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: _inputDecor(context, '12'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Workshop unit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('STOCK / WORKSHOP UNIT'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _workshopUnit,
                          decoration: _inputDecor(context, ''),
                          items: _kWorkshopUnits
                              .map((u) => DropdownMenuItem(
                              value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _workshopUnit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Rule preview ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RULE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      _rulePreview,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Notes ──
              _label('NOTES'),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: _inputDecor(
                    context, 'Optional — e.g. Product A & B use this packing'),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Buttons ──
              OwnerSheetActions(
                onCancel: () => Navigator.pop(context),
                onPrimary: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  // TODO: replace with your actual VM method signature
                  // e.g. vm.addUomProfile(UomProfile(...));
                  Navigator.pop(context);
                },
                primaryLabel: 'Save profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLight,
        letterSpacing: 0.5),
  );

  InputDecoration _inputDecor(BuildContext context, String hint) {
    final primary = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    );
  }
}