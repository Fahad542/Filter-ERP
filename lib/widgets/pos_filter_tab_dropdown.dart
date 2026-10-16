import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PosFilterTabOption {
  const PosFilterTabOption({
    required this.id,
    required this.label,
    this.count,
  });

  final String id;
  final String label;
  final int? count;
}

class PosFilterTabDropdown extends StatelessWidget {
  /// Matches From/To date chips on Cash Collection and Closing History.
  static const double dateChipHeight = 58;
  static const double dropdownWidth = 168;

  const PosFilterTabDropdown({
    super.key,
    required this.selectedId,
    required this.options,
    required this.onSelected,
    this.title,
    this.height = dateChipHeight,
  });

  final String selectedId;
  final List<PosFilterTabOption> options;
  final ValueChanged<String> onSelected;
  final String? title;
  final double? height;

  String _labelOf(PosFilterTabOption option) {
    if (option.count == null) return option.label;
    return '${option.label} (${option.count})';
  }

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlayState = Overlay.maybeOf(context);
    final overlay = overlayState?.context.findRenderObject();
    if (overlay is! RenderBox) return;

    final picked = await showMenu<String>(
      context: context,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          box.localToGlobal(Offset.zero, ancestor: overlay),
          box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _labelOf(option),
                    style: TextStyle(
                      fontWeight: option.id == selectedId
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 13,
                      color: option.id == selectedId
                          ? AppColors.secondaryLight
                          : const Color(0xFF1E2124),
                    ),
                  ),
                ),
                if (option.id == selectedId)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
              ],
            ),
          ),
      ],
    );
    if (picked == null || !context.mounted) return;
    onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = options.cast<PosFilterTabOption?>().firstWhere(
          (e) => e!.id == selectedId,
          orElse: () => options.isEmpty ? null : options.first,
        );
    final label = selected == null ? '—' : _labelOf(selected);

    return SizedBox(
      width: dropdownWidth,
      height: height,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openMenu(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2124),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
