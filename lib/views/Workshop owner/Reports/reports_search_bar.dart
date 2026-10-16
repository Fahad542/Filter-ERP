import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class ReportsSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const ReportsSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<ReportsSearchBar> createState() => _ReportsSearchBarState();
}

class _ReportsSearchBarState extends State<ReportsSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: (v) {
                setState(() {});
                widget.onChanged(v);
              },
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                setState(() {});
                widget.onChanged('');
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Colors.grey.shade400),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.search_rounded,
                size: 15,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
