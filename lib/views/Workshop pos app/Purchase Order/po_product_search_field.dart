import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/purchase_order_models.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_shimmer.dart';

/// Product search for PO lines — same [Autocomplete] pattern as Add New Order.
class PoProductSearchField extends StatefulWidget {
  const PoProductSearchField({
    super.key,
    required this.products,
    required this.hint,
    this.initialText = '',
    required this.onSelected,
    this.compact = false,
    this.isLoading,
    this.emptyMessage,
    this.loadingMessage,
    this.onFocusRequest,
    this.onCleared,
  });

  final List<PoBranchProduct> products;
  final String hint;
  final String initialText;
  final ValueChanged<PoBranchProduct> onSelected;
  final bool compact;
  final bool? isLoading;
  final String? emptyMessage;
  final String? loadingMessage;
  final VoidCallback? onFocusRequest;
  final VoidCallback? onCleared;

  bool get loading => isLoading ?? false;
  String get noProductsMessage =>
      emptyMessage ?? 'No branch products found';
  String get loadingProductsMessage =>
      loadingMessage ?? 'Loading products…';

  @override
  State<PoProductSearchField> createState() => PoProductSearchFieldState();
}

class PoProductSearchFieldState extends State<PoProductSearchField> {
  FocusNode? _fieldFocusNode;

  void requestFocus() => _fieldFocusNode?.requestFocus();

  double _autocompleteMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return math.min(280.0, math.max(120.0, (h - kb) * 0.36));
  }

  Iterable<PoBranchProduct> _productOptions(TextEditingValue value) {
    if (widget.loading && widget.products.isEmpty) {
      return const Iterable<PoBranchProduct>.empty();
    }
    final q = value.text.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products
        .where((p) => p.name.toLowerCase().contains(q))
        .take(60);
  }

  InputDecoration _fieldDecoration({
    required bool showClear,
    required VoidCallback? onClear,
  }) {
    const radius = 10.0;
    return InputDecoration(
      hintText: widget.loading && widget.products.isEmpty
          ? widget.loadingProductsMessage
          : widget.hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      isDense: true,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      suffixIcon: showClear
          ? InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Color(0xFF757575),
                ),
              ),
            )
          : null,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: AppColors.primaryLight,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildOptionsView(
    BuildContext context,
    AutocompleteOnSelected<PoBranchProduct> onSelected,
    Iterable<PoBranchProduct> options,
    double dropdownWidth,
  ) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final optionsList = options.toList(growable: false);

    if (optionsList.isEmpty) {
      final child = widget.loading
          ? const PosShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PosShimmerLine(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  PosShimmerLine(width: 140, height: 11),
                  SizedBox(height: 8),
                  PosShimmerLine(width: 100, height: 11),
                ],
              ),
            )
          : Text(
              widget.noProductsMessage,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
      return Align(
        alignment: isAr ? Alignment.topRight : Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: dropdownWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: child,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isAr ? Alignment.topRight : Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: dropdownWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _autocompleteMaxHeight(context),
            ),
          child: ListView.builder(
            primary: false,
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: optionsList.length,
            itemBuilder: (context, index) {
              final product = optionsList[index];
              return InkWell(
                onTap: () => onSelected(product),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.compact ? 12 : 13,
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (product.unit.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          product.unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.products.isEmpty) {
      return TextField(
        enabled: false,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _fieldDecoration(showClear: false, onClear: null),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownWidth = constraints.maxWidth;
        return Autocomplete<PoBranchProduct>(
          key: ValueKey<String>(
            'po_ac_${widget.initialText}_${widget.products.length}',
          ),
          displayStringForOption: (product) => product.name,
          initialValue: TextEditingValue(text: widget.initialText),
          optionsBuilder: _productOptions,
          onSelected: widget.onSelected,
          optionsViewOpenDirection: OptionsViewOpenDirection.down,
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            _fieldFocusNode = focusNode;
            return ListenableBuilder(
              listenable: textController,
              builder: (context, _) {
                final showClear = textController.text.isNotEmpty;
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textInputAction: TextInputAction.next,
                  onTap: () {
                    widget.onFocusRequest?.call();
                  },
                  onSubmitted: (_) => onFieldSubmitted(),
                  decoration: _fieldDecoration(
                    showClear: showClear,
                    onClear: showClear
                        ? () {
                            textController.clear();
                            widget.onCleared?.call();
                            setState(() {});
                          }
                        : null,
                  ),
                );
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildOptionsView(
              context,
              onSelected,
              options,
              dropdownWidth,
            );
          },
        );
      },
    );
  }
}
