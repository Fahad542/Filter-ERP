import 'package:flutter/material.dart';

import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';

/// One item in [OwnerStyledDropdown].
class OwnerDropdownOption<T> {
  final T value;
  final String label;

  const OwnerDropdownOption({
    required this.value,
    required this.label,
  });
}

/// Shared floating-menu dropdown (Discounts-style):
/// white panel, primary selected row + checkmark, soft shadow.
///
/// Width:
/// - default: menu matches the trigger width
/// - override with [menuWidth], or clamp via [menuMinWidth] / [menuMaxWidth]
class OwnerStyledDropdown<T> extends StatelessWidget {
  final T? value;
  final List<OwnerDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;

  /// Text shown on the closed trigger. Defaults to selected option label / [hint].
  final String? displayLabel;
  final String hint;

  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? triggerStyle;
  final IconData? leadingIcon;

  /// Exact menu width. When null, uses the trigger width (then clamps).
  final double? menuWidth;
  final double? menuMinWidth;
  final double? menuMaxWidth;
  final double menuMaxHeight;

  final bool enabled;
  final bool isExpanded;

  /// When true, option / trigger labels go through [LocalizedApiText].
  final bool localizeLabels;

  const OwnerStyledDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.displayLabel,
    this.hint = 'Select',
    this.height = 38,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.backgroundColor,
    this.borderColor,
    this.triggerStyle,
    this.leadingIcon,
    this.menuWidth,
    this.menuMinWidth,
    this.menuMaxWidth,
    this.menuMaxHeight = 300,
    this.enabled = true,
    this.isExpanded = true,
    this.localizeLabels = true,
  });

  String get _closedLabel {
    if (displayLabel != null && displayLabel!.trim().isNotEmpty) {
      return displayLabel!;
    }
    if (value != null) {
      for (final o in options) {
        if (o.value == value) return o.label;
      }
    }
    return hint;
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled || onChanged == null) return;

    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );

    var width = menuWidth ?? box.size.width;
    if (menuMinWidth != null) {
      width = width < menuMinWidth! ? menuMinWidth! : width;
    }
    if (menuMaxWidth != null) {
      width = width > menuMaxWidth! ? menuMaxWidth! : width;
    }

    final picked = await showMenu<T>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      constraints: BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: menuMaxHeight,
      ),
      items: [
        for (final o in options)
          PopupMenuItem<T>(
            value: o.value,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: _OwnerDropdownMenuRow(
              label: o.label,
              selected: value == o.value,
              localize: localizeLabels,
            ),
          ),
      ],
    );

    if (!context.mounted || picked == null) return;
    onChanged!(picked);
  }

  @override
  Widget build(BuildContext context) {
    final style = triggerStyle ??
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: enabled ? AppColors.secondaryLight : Colors.grey.shade400,
        );
    final child = InkWell(
      borderRadius: borderRadius,
      onTap: enabled ? () => _open(context) : null,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor ?? Colors.grey.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: localizeLabels
                  ? LocalizedApiText(
                      _closedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    )
                  : Text(
                      _closedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );

    if (!isExpanded) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}

class _OwnerDropdownMenuRow extends StatelessWidget {
  final String label;
  final bool selected;
  final bool localize;

  const _OwnerDropdownMenuRow({
    required this.label,
    required this.selected,
    this.localize = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: AppColors.secondaryLight,
      height: 1.15,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.secondaryLight,
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: localize
                ? LocalizedApiText(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  )
                : Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
          ),
        ],
      ),
    );
  }
}
