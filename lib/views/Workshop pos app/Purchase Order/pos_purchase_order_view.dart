import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../utils/toast_service.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import 'po_pos_ui.dart';
import 'po_product_search_field.dart';
import '../../../models/purchase_order_models.dart';
import 'purchase_order_view_model.dart';

class PosPurchaseOrderView extends StatefulWidget {
  const PosPurchaseOrderView({super.key});

  @override
  State<PosPurchaseOrderView> createState() => _PosPurchaseOrderViewState();
}

class _PosPurchaseOrderViewState extends State<PosPurchaseOrderView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<PurchaseOrderViewModel>();
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PosScreenAppBar(
        title: l10n.posNavPurchaseOrder,
        showBackButton: false,
        showHamburger: true,
        onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
      ),
      body: wrapPosShellRailBody(
        context,
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isTablet ? 20 : 12, 12, isTablet ? 20 : 12, 0),
              child: PosSegmentedListTabs(
                layout: PosSegmentedTabLayout.expanded,
                tabs: [
                  PosSegmentedTab(id: '0', label: l10n.posPoTabCreate),
                  PosSegmentedTab(id: '1', label: l10n.posPoTabHistory),
                  PosSegmentedTab(id: '2', label: l10n.posPoTabIncoming),
                ],
                selectedId: '${_tabController.index}',
                onSelected: (id) {
                  final idx = int.tryParse(id) ?? 0;
                  _tabController.index = idx;
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _CreatePoTab(vm: vm, isTablet: isTablet),
                  _HistoryTab(vm: vm, isTablet: isTablet),
                  _IncomingTab(vm: vm, isTablet: isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePoTab extends StatefulWidget {
  const _CreatePoTab({required this.vm, required this.isTablet});

  final PurchaseOrderViewModel vm;
  final bool isTablet;

  @override
  State<_CreatePoTab> createState() => _CreatePoTabState();
}

class _CreatePoTabState extends State<_CreatePoTab> {
  int? _pendingProductFocusIndex;

  PurchaseOrderViewModel get vm => widget.vm;
  bool get isTablet => widget.isTablet;

  @override
  void reassemble() {
    super.reassemble();
    _pendingProductFocusIndex = null;
  }

  void _clearPendingProductFocus() {
    if (_pendingProductFocusIndex == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pendingProductFocusIndex != null) {
        setState(() => _pendingProductFocusIndex = null);
      }
    });
  }

  void _onTabFromLineEnd(int index) {
    final nextIndex = index + 1;
    if (nextIndex >= vm.lines.length) {
      vm.addLine();
    }
    setState(() => _pendingProductFocusIndex = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('yyyy-MM-dd');

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _FieldLabel(
                  label: l10n.posPoDate,
                  child: _PoDateField(
                    date: vm.issueDate,
                    dateFmt: dateFmt,
                    onPick: () => _pickIssueDate(context, vm),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                flex: 3,
                child: _FieldLabel(
                  label: l10n.posPoSupplier,
                  child: DropdownButtonFormField<String>(
                    value: vm.selectedSupplierId,
                    isExpanded: true,
                    decoration: _poLineFieldDecoration(
                      hint: l10n.posPoSelectSupplier,
                    ),
                    hint: Text(l10n.posPoSelectSupplier),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2124),
                    ),
                    items: vm.suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.supplierId,
                            child: Text(
                              s.supplierName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: vm.setSupplier,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                flex: 2,
                child: _FieldLabel(
                  label: l10n.posPoReference,
                  child: _PoReferenceField(
                    loading: vm.referenceLoading,
                    reference: vm.draftReference,
                    loadingLabel: l10n.posPoReferenceLoading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FieldLabel(
            label: l10n.posPoDescription,
            child: TextField(
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: _poLineFieldDecoration(
                hint: l10n.posPoDescriptionHint,
              ),
              onChanged: vm.setDescription,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.posPoLineItems,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (vm.productsLoading)
                const PosShimmer(
                  child: PosShimmerBox(width: 72, height: 12, radius: 6),
                )
              else
                Text(
                  l10n.posPoAvailableProductsCount(vm.products.length),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (vm.lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2, right: 36),
              child: Row(
                children: [
                  Expanded(
                    flex: 34,
                    child: Text(
                      l10n.posPoProductColumn,
                      style: _poLineHeaderStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 28,
                    child: Text(
                      l10n.posPoItemDescription,
                      style: _poLineHeaderStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text(l10n.posPoQty, style: _poLineHeaderStyle),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text('UOM', style: _poLineHeaderStyle),
                  ),
                ],
              ),
            ),
          ...List.generate(vm.lines.length, (index) {
            final line = vm.lines[index];
            return _PoLineRow(
              key: ObjectKey(line),
              index: index,
              line: line,
              vm: vm,
              l10n: l10n,
              pendingProductFocusIndex: _pendingProductFocusIndex,
              onPendingFocusHandled: _clearPendingProductFocus,
              onTabFromEnd: () => _onTabFromLineEnd(index),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                vm.addLine();
                setState(
                  () => _pendingProductFocusIndex = vm.lines.length - 1,
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.posPoAddLine),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: isTablet ? 46 : 44,
            child: ElevatedButton(
              onPressed: vm.isSubmitting
                  ? null
                  : () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final ok = await vm.submitPurchaseOrder(
                        (msg) => ToastService.showError(context, msg),
                      );
                      if (!context.mounted || !ok) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        ToastService.showSuccess(
                          context,
                          l10n.posPoSubmitSuccess,
                          messageOnly: true,
                        );
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.onPrimaryLight,
                disabledBackgroundColor:
                    AppColors.primaryLight.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: vm.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondaryLight,
                      ),
                    )
                  : Text(
                      l10n.posPoSubmit,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.vm, required this.isTablet});

  final PurchaseOrderViewModel vm;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (vm.history.isEmpty) {
      return PoPosEmptyState(
        message: l10n.posPoNoHistory,
        icon: Icons.history_rounded,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      itemCount: vm.history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final po = vm.history[index];
        final title =
            po.invoiceNumber.isEmpty ? po.id : po.invoiceNumber;
        return PoPosCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.secondaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2124),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${po.supplierName} · ${po.issueDate}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PoPosStatusBadge(status: po.status),
                  const SizedBox(height: 6),
                  Text(
                    '${po.grandTotal.toStringAsFixed(2)} SAR',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IncomingTab extends StatefulWidget {
  const _IncomingTab({required this.vm, required this.isTablet});

  final PurchaseOrderViewModel vm;
  final bool isTablet;

  @override
  State<_IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<_IncomingTab> {
  String? _loadingInvoiceId;

  PurchaseOrderViewModel get vm => widget.vm;
  bool get isTablet => widget.isTablet;

  Future<void> _openReceiveSheet(String invoiceId) async {
    if (_loadingInvoiceId != null) return;

    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<PurchaseOrderViewModel>();

    setState(() => _loadingInvoiceId = invoiceId);
    try {
      final detail = await vm.loadIncomingDetail(invoiceId);
      if (!mounted) return;
      if (detail == null) {
        ToastService.showError(context, 'Could not load invoice');
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (sheetContext) => _PoReceiveSheet(
          detail: detail,
          invoiceId: invoiceId,
          vm: vm,
          l10n: l10n,
        ),
      );
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingInvoiceId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (vm.incoming.isEmpty) {
      return PoPosEmptyState(
        message: l10n.posPoNoIncoming,
        icon: Icons.local_shipping_outlined,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      itemCount: vm.incoming.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final inv = vm.incoming[index];
        final isLoading = _loadingInvoiceId == inv.id;
        return PoPosCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.secondaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.invoiceNo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2124),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inv.supplierName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (inv.productLabel.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        inv.productLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : () => _openReceiveSheet(inv.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.onPrimaryLight,
                    disabledBackgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondaryLight,
                          ),
                        )
                      : Text(
                          l10n.posPoReceive,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PoReceiveSheet extends StatefulWidget {
  const _PoReceiveSheet({
    required this.detail,
    required this.invoiceId,
    required this.vm,
    required this.l10n,
  });

  final IncomingSupplierInvoiceDetail detail;
  final String invoiceId;
  final PurchaseOrderViewModel vm;
  final AppLocalizations l10n;

  @override
  State<_PoReceiveSheet> createState() => _PoReceiveSheetState();
}

class _PoReceiveSheetState extends State<_PoReceiveSheet> {
  late final Map<String, TextEditingController> _qtyControllers;

  @override
  void initState() {
    super.initState();
    _qtyControllers = {
      for (var i = 0; i < widget.detail.lines.length; i++)
        _lineKey(widget.detail.lines[i], i): TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _lineKey(IncomingSupplierInvoiceLine line, int index) {
    final id = line.id.trim();
    return id.isNotEmpty ? id : 'line-$index';
  }

  Future<void> _submit() async {
    final map = <String, String>{};
    for (var i = 0; i < widget.detail.lines.length; i++) {
      final line = widget.detail.lines[i];
      final key = _lineKey(line, i);
      map[line.id.isNotEmpty ? line.id : key] =
          _qtyControllers[key]?.text ?? '';
    }

    final ok = await widget.vm.receiveInvoice(
      widget.invoiceId,
      widget.detail.lines,
      map,
      (msg) {
        if (mounted) ToastService.showError(context, msg);
      },
    );
    if (!mounted || !ok) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ToastService.showSuccess(
        context,
        widget.l10n.posPoReceiveSuccess,
        messageOnly: true,
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.l10n.posPoReceive} — ${widget.detail.invoiceNo}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.l10n.posPoReceivedQtyHint),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.detail.lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ln = widget.detail.lines[index];
                final key = _lineKey(ln, index);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ln.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${widget.l10n.posPoInvoiceQty}: ${ln.invoiceQty}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    TextField(
                      controller: _qtyControllers[key],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: poPosInputDecoration(
                        hint: '${ln.invoiceQty}',
                        labelText: widget.l10n.posPoReceivedQty,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: widget.vm,
            builder: (context, _) {
              return SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.vm.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.onPrimaryLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.vm.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondaryLight,
                          ),
                        )
                      : Text(
                          widget.l10n.posPoConfirmReceive,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _pickIssueDate(
  BuildContext context,
  PurchaseOrderViewModel vm,
) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: vm.issueDate,
    firstDate: DateTime(now.year - 2, 1, 1),
    lastDate: DateTime(now.year + 2, 12, 31),
  );
  if (picked != null) {
    vm.setIssueDate(picked);
  }
}

class _PoLineRow extends StatefulWidget {
  const _PoLineRow({
    super.key,
    required this.index,
    required this.line,
    required this.vm,
    required this.l10n,
    required this.onTabFromEnd,
    this.pendingProductFocusIndex,
    this.onPendingFocusHandled,
  });

  final int index;
  final PoLineDraft line;
  final PurchaseOrderViewModel vm;
  final AppLocalizations l10n;
  final VoidCallback onTabFromEnd;
  final int? pendingProductFocusIndex;
  final VoidCallback? onPendingFocusHandled;

  @override
  State<_PoLineRow> createState() => _PoLineRowState();
}

class _PoLineRowState extends State<_PoLineRow> {
  final GlobalKey<PoProductSearchFieldState> _productFieldKey =
      GlobalKey<PoProductSearchFieldState>();
  late final FocusNode _descFocus;
  late final FocusNode _qtyFocus;

  @override
  void initState() {
    super.initState();
    _descFocus = FocusNode();
    _qtyFocus = FocusNode();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    _schedulePendingProductFocus();
  }

  @override
  void didUpdateWidget(covariant _PoLineRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingProductFocusIndex != oldWidget.pendingProductFocusIndex) {
      _schedulePendingProductFocus();
    }
  }

  void _schedulePendingProductFocus() {
    if (widget.pendingProductFocusIndex != widget.index) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.pendingProductFocusIndex != widget.index) return;
      _productFieldKey.currentState?.requestFocus();
      widget.onPendingFocusHandled?.call();
    });
  }

  bool _onHardwareKey(KeyEvent event) {
    if (!mounted || !_qtyFocus.hasFocus) return false;
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed) {
      widget.onTabFromEnd();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _descFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final index = widget.index;
    final vm = widget.vm;
    final l10n = widget.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 34,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: PoProductSearchField(
                  key: _productFieldKey,
                  compact: true,
                  products: vm.products,
                  isLoading: vm.productsLoading == true,
                  hint: l10n.posPoSearchProductHint,
                  initialText: line.productName,
                  onFocusRequest: vm.ensureBranchProductsLoaded,
                  onSelected: (p) {
                    vm.applyProductToLine(index, p);
                    _descFocus.requestFocus();
                  },
                  onCleared: () => vm.clearProductFromLine(index),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 28,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: TextFormField(
                  key: ValueKey('po-desc-$index'),
                  focusNode: _descFocus,
                  initialValue: line.description,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _poLineFieldDecoration(
                    hint: l10n.posPoItemDescription,
                  ),
                  onChanged: (v) => line.description = v,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: TextFormField(
                  key: ValueKey('po-qty-$index'),
                  focusNode: _qtyFocus,
                  initialValue: line.qty,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _poLineFieldDecoration(hint: l10n.posPoQty),
                  onChanged: (v) => line.qty = v,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ExcludeFocus(
              child: SizedBox(
                width: 72,
                child: InputDecorator(
                  decoration: _poLineFieldDecoration(hint: 'UOM'),
                  child: Text(
                    line.uom.isEmpty ? '—' : line.uom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            ExcludeFocus(
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: vm.lines.length > 1
                    ? () => vm.removeLine(index)
                    : null,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: vm.lines.length > 1
                      ? Colors.red.shade400
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoReferenceField extends StatelessWidget {
  const _PoReferenceField({
    required this.loading,
    required this.reference,
    required this.loadingLabel,
  });

  final bool loading;
  final String reference;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _poLineFieldDecoration(hint: loading ? loadingLabel : reference),
      child: loading
          ? const PosShimmer(
              child: Row(
                children: [
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 6,
                    ),
                  ),
                ],
              ),
            )
          : Text(
              reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: Color(0xFF1E2124),
              ),
            ),
    );
  }
}

class _PoDateField extends StatelessWidget {
  const _PoDateField({
    required this.date,
    required this.dateFmt,
    required this.onPick,
  });

  final DateTime date;
  final DateFormat dateFmt;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: _poLineFieldDecoration(hint: '').copyWith(
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.secondaryLight.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            dateFmt.format(date),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

const _poLineHeaderStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w800,
  color: Color(0xFF64748B),
  letterSpacing: 0.2,
);

InputDecoration _poLineFieldDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: Colors.grey.shade400,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
