import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// One option in [PosMenuDropdown].
class PosMenuDropdownOption<T> {
  const PosMenuDropdownOption({
    required this.value,
    this.label,
    this.searchLabel,
    this.child,
  }) : assert(label != null || child != null);

  final T value;
  final String? label;
  /// Used for search filtering when [PosMenuDropdown.searchable] is true.
  final String? searchLabel;
  final Widget? child;
}

/// Bordered POS dropdown — same [DropdownButton] pattern as Add New Order fleet/corporate fields.
/// Set [searchable] to type/filter in the field itself (overlay list has no search box).
class PosMenuDropdown<T> extends StatefulWidget {
  const PosMenuDropdown({
    super.key,
    required this.placeholder,
    required this.options,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.enabled = true,
    this.isTablet,
    this.compact = false,
    this.searchable = false,
    this.searchHint = 'Search…',
    this.emptySearchLabel = 'No matches',
  });

  final String placeholder;
  final IconData? prefixIcon;
  final List<PosMenuDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool? isTablet;
  final bool compact;
  final bool searchable;
  final String searchHint;
  final String emptySearchLabel;

  static Color get _hintColor => Colors.grey.shade500;

  static double fieldHeight({required bool tablet, bool compact = false}) {
    if (compact) return tablet ? 36 : 34;
    return tablet ? 40 : 38;
  }

  @override
  State<PosMenuDropdown<T>> createState() => _PosMenuDropdownState<T>();
}

class _PosMenuDropdownState<T> extends State<PosMenuDropdown<T>>
    with WidgetsBindingObserver {
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _menuOpen = false;
  /// Ignore outside taps for one frame so the opening tap cannot dismiss.
  bool _barrierArmed = false;
  bool _openingOverlay = false;
  /// Locked when the menu opens so keyboard cannot flip it up/down.
  bool _lockedOpenAbove = false;
  String _query = '';
  bool _syncingText = false;
  /// Blocks focus-listener from opening a second overlay (clear/focus race).
  bool _suppressFocusOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTextFromValue(force: true);
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!widget.searchable || _suppressFocusOpen) return;
    if (!_searchFocus.hasFocus) return;
    if (_openingOverlay || _menuOpen) return;
    final canOpen = widget.enabled &&
        widget.onChanged != null &&
        widget.options.isNotEmpty;
    if (!canOpen) return;
    _toggleSearchableOverlay(forceOpen: true);
  }

  /// Scroll the trigger field toward the top of the viewport so list fits.
  Future<void> _ensureFieldVisibleForMenu() async {
    final fieldCtx = _fieldKey.currentContext;
    if (fieldCtx == null || !fieldCtx.mounted) return;
    if (Scrollable.maybeOf(fieldCtx) == null) return;
    await Scrollable.ensureVisible(
      fieldCtx,
      // Keep field near the top third — leaves space below for the overlay.
      alignment: 0.18,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    // Let layout settle after keyboard + scroll.
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }

  /// Overlay MediaQuery often reports 0 insets — read keyboard from the view.
  double _keyboardInsetOf(BuildContext context) {
    final view = View.of(context);
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  Size _screenSizeOf(BuildContext context) {
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    return Size(
      view.physicalSize.width / dpr,
      view.physicalSize.height / dpr,
    );
  }

  @override
  void didChangeMetrics() {
    if (!_menuOpen && !_searchFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_menuOpen || _searchFocus.hasFocus) {
        await _ensureFieldVisibleForMenu();
        if (mounted && _menuOpen) _overlayEntry?.markNeedsBuild();
      }
    });
  }

  double _menuMaxHeight(BuildContext context) {
    return math.min(
      340.0,
      math.max(
        160.0,
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            0.42,
      ),
    );
  }

  T? _validatedValue() {
    if (widget.value == null) return null;
    for (final opt in widget.options) {
      if (opt.value == widget.value) return widget.value;
    }
    return null;
  }

  String _optionSearchText(PosMenuDropdownOption<T> opt) {
    return (opt.searchLabel ?? opt.label ?? '').trim();
  }

  PosMenuDropdownOption<T>? _selectedOption() {
    final v = _validatedValue();
    if (v == null) return null;
    for (final opt in widget.options) {
      if (opt.value == v) return opt;
    }
    return null;
  }

  void _syncTextFromValue({bool force = false}) {
    if (!widget.searchable) return;
    if (_menuOpen && !force) return;
    final label = (_selectedOption()?.label ?? '').trim();
    if (_searchCtrl.text == label) return;
    _syncingText = true;
    _searchCtrl.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
    _query = '';
    _syncingText = false;
  }

  bool _optionsIdentityChanged(
    List<PosMenuDropdownOption<T>> a,
    List<PosMenuDropdownOption<T>> b,
  ) {
    if (identical(a, b)) return false;
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return true;
    }
    return false;
  }

  List<PosMenuDropdownOption<T>> _filteredOptions() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => _optionSearchText(o).toLowerCase().contains(q))
        .toList();
  }

  void _closeOverlay({bool restoreSelectedText = true}) {
    _barrierArmed = false;
    _lockedOpenAbove = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_menuOpen && mounted) {
      setState(() => _menuOpen = false);
    } else {
      _menuOpen = false;
    }
    if (restoreSelectedText) {
      _syncTextFromValue(force: true);
    }
  }

  void _clearSearchOrSelection() {
    // Close any open panel first — otherwise ensureVisible scroll leaves a
    // ghost field/panel beside the real TextField (looks like "double fields").
    if (_menuOpen) {
      _closeOverlay(restoreSelectedText: false);
    }
    _syncingText = true;
    _searchCtrl.clear();
    _query = '';
    _syncingText = false;
    widget.onChanged?.call(null);
    setState(() {});

    _suppressFocusOpen = true;
    unawaited(() async {
      await _ensureFieldVisibleForMenu();
      if (!mounted) return;
      _openSearchableOverlay();
      if (!_searchFocus.hasFocus) {
        _searchFocus.requestFocus();
      }
      // Allow focus listener again after this open finishes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _suppressFocusOpen = false;
      });
    }());
  }

  void _onSearchTextChanged(String v) {
    if (_syncingText) return;
    setState(() => _query = v);
    final sel = _selectedOption();
    if (sel != null && v.trim() != (sel.label ?? '').trim()) {
      widget.onChanged?.call(null);
    }
    if (!_menuOpen) {
      _toggleSearchableOverlay(forceOpen: true);
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _toggleSearchableOverlay({bool forceOpen = false}) {
    if (!widget.enabled || widget.onChanged == null || widget.options.isEmpty) {
      return;
    }
    if (_menuOpen && !forceOpen) {
      _closeOverlay();
      return;
    }
    if (_menuOpen && forceOpen) return;
    if (_openingOverlay) return;
    _openingOverlay = true;
    unawaited(_ensureFieldVisibleForMenu().whenComplete(() {
      _openingOverlay = false;
      if (mounted) _openSearchableOverlay();
    }));
  }

  void _openSearchableOverlay() {
    if (_menuOpen && _overlayEntry != null) return;
    // Never stack two overlays — remove any stale entry first.
    _overlayEntry?.remove();
    _overlayEntry = null;
    _menuOpen = false;

    final tablet = widget.isTablet ?? MediaQuery.sizeOf(context).width > 600;
    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    _barrierArmed = false;
    final fieldWidth = box.size.width;

    {
      final fieldOffset = box.localToGlobal(Offset.zero);
      final screen = _screenSizeOf(context);
      final keyboard = _keyboardInsetOf(context);
      final safeTop = MediaQuery.paddingOf(context).top;
      const gap = 4.0;
      final usableBottom = screen.height - keyboard - (keyboard > 0 ? 8.0 : 0.0);
      final spaceBelow =
          usableBottom - fieldOffset.dy - box.size.height - gap;
      final spaceAbove = fieldOffset.dy - safeTop - gap;
      _lockedOpenAbove = spaceBelow < 96 && spaceAbove > spaceBelow;
    }

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final fieldBox =
            _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        final fieldSize = fieldBox != null && fieldBox.hasSize
            ? fieldBox.size
            : Size(fieldWidth, PosMenuDropdown.fieldHeight(tablet: tablet));
        final fieldOffset = fieldBox != null && fieldBox.hasSize
            ? fieldBox.localToGlobal(Offset.zero)
            : Offset.zero;
        final screen = _screenSizeOf(overlayContext);
        final screenH = screen.height;
        final screenW = screen.width;
        final keyboard = _keyboardInsetOf(overlayContext);
        final safeTop = MediaQuery.paddingOf(overlayContext).top;
        const gap = 4.0;
        final usableBottom = screenH - keyboard - (keyboard > 0 ? 8.0 : 0.0);
        final openAbove = _lockedOpenAbove;
        final panelW = math.min(fieldSize.width, screenW - 24);
        final left = fieldOffset.dx
            .clamp(0.0, math.max(0.0, screenW - panelW))
            .toDouble();

        late final double top;
        late final double maxPanelH;
        if (openAbove) {
          final spaceAbove = fieldOffset.dy - safeTop - gap;
          maxPanelH = spaceAbove.clamp(72.0, 320.0).toDouble();
          top = (fieldOffset.dy - gap - maxPanelH).clamp(safeTop, usableBottom);
        } else {
          top = fieldOffset.dy + fieldSize.height + gap;
          final spaceBelow = usableBottom - top;
          maxPanelH = spaceBelow.clamp(72.0, 320.0).toDouble();
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_barrierArmed) {
                    _searchFocus.unfocus();
                    _closeOverlay();
                  }
                },
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: panelW,
              height: maxPanelH,
              child: Material(
                color: Colors.transparent,
                child: _PosOptionsOverlayPanel<T>(
                  options: _filteredOptions(),
                  selectedValue: _validatedValue(),
                  emptySearchLabel: widget.emptySearchLabel,
                  isTablet: tablet,
                  onSelected: (value) {
                    var label = '';
                    for (final o in widget.options) {
                      if (o.value == value) {
                        label = (o.label ?? '').trim();
                        break;
                      }
                    }
                    _syncingText = true;
                    _searchCtrl.value = TextEditingValue(
                      text: label,
                      selection: TextSelection.collapsed(offset: label.length),
                    );
                    _query = '';
                    _syncingText = false;
                    _closeOverlay(restoreSelectedText: false);
                    widget.onChanged?.call(value);
                    _searchFocus.unfocus();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _menuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_menuOpen) return;
      _barrierArmed = true;
    });
  }

  @override
  void didUpdateWidget(covariant PosMenuDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_menuOpen) {
      _syncTextFromValue(force: true);
    }
    if (!_menuOpen) return;

    if (!widget.enabled ||
        !widget.searchable ||
        widget.options.isEmpty ||
        widget.onChanged == null) {
      _closeOverlay();
      return;
    }

    if (_optionsIdentityChanged(oldWidget.options, widget.options) ||
        oldWidget.value != widget.value ||
        oldWidget.searchHint != widget.searchHint) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablet = widget.isTablet ?? MediaQuery.sizeOf(context).width > 600;
    final radius = tablet ? 10.0 : 9.0;
    final fieldHeight = PosMenuDropdown.fieldHeight(
      tablet: tablet,
      compact: widget.compact,
    );
    final hintSize = widget.compact
        ? (tablet ? 11.0 : 10.0)
        : (tablet ? 12.0 : 11.0);
    final itemSize = hintSize;
    final canOpen =
        widget.enabled && widget.onChanged != null && widget.options.isNotEmpty;
    final dropdownValue = _validatedValue();
    final selectedOption = _selectedOption();
    final showClear = widget.searchable &&
        canOpen &&
        (_searchCtrl.text.isNotEmpty || selectedOption != null);

    final hintStyle = AppTextStyles.bodyMedium.copyWith(
      color: PosMenuDropdown._hintColor,
      fontSize: hintSize,
      fontWeight: FontWeight.w500,
    );
    final selectedStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.secondaryLight,
      fontWeight: FontWeight.w600,
      fontSize: itemSize,
    );

    final itemTextStyle = AppTextStyles.bodyMedium.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: itemSize,
      color: AppColors.secondaryLight,
    );

    final Widget fieldContent;
    if (widget.searchable) {
      fieldContent = Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              enabled: canOpen,
              textInputAction: TextInputAction.done,
              onChanged: _onSearchTextChanged,
              onTap: canOpen
                  ? () {
                      if (!_menuOpen) {
                        _toggleSearchableOverlay(forceOpen: true);
                      }
                    }
                  : null,
              style: selectedStyle,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.searchHint.isNotEmpty
                    ? widget.searchHint
                    : widget.placeholder,
                hintStyle: hintStyle,
                contentPadding: EdgeInsets.symmetric(vertical: tablet ? 9 : 8),
              ),
            ),
          ),
          if (showClear)
            GestureDetector(
              onTap: _clearSearchOrSelection,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.close_rounded,
                  size: tablet ? 18 : 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          GestureDetector(
            onTap: canOpen
                ? () {
                    if (_menuOpen) {
                      _searchFocus.unfocus();
                      _closeOverlay();
                    } else {
                      _searchFocus.requestFocus();
                      _toggleSearchableOverlay(forceOpen: true);
                    }
                  }
                : null,
            child: Icon(
              _menuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey.shade400,
              size: tablet ? 18 : 16,
            ),
          ),
        ],
      );
    } else {
      final dropdown = Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
          highlightColor: AppColors.primaryLight.withValues(alpha: 0.08),
          splashColor: AppColors.primaryLight.withValues(alpha: 0.12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: dropdownValue,
            isExpanded: true,
            isDense: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(tablet ? 12 : 10),
            elevation: 6,
            menuMaxHeight: _menuMaxHeight(context),
            hint: Text(
              widget.placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hintStyle,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade400,
              size: tablet ? 18 : 16,
            ),
            style: selectedStyle,
            items: widget.options
                .map(
                  (opt) => DropdownMenuItem<T>(
                    value: opt.value,
                    child: opt.child ??
                        Text(
                          opt.label ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: itemTextStyle,
                        ),
                  ),
                )
                .toList(),
            onChanged: canOpen ? widget.onChanged : null,
          ),
        ),
      );
      fieldContent = Center(child: dropdown);
    }

    return SizedBox(
      key: _fieldKey,
      height: fieldHeight,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: canOpen ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: _menuOpen
                ? AppColors.primaryLight.withValues(alpha: 0.55)
                : Colors.grey.shade200,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: tablet ? 8 : 6),
        child: widget.prefixIcon == null
            ? fieldContent
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    widget.prefixIcon,
                    size: tablet ? 18 : 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: fieldContent),
                ],
              ),
      ),
    );
  }
}

class _PosOptionsOverlayPanel<T> extends StatelessWidget {
  const _PosOptionsOverlayPanel({
    required this.options,
    required this.selectedValue,
    required this.emptySearchLabel,
    required this.isTablet,
    required this.onSelected,
  });

  final List<PosMenuDropdownOption<T>> options;
  final T? selectedValue;
  final String emptySearchLabel;
  final bool isTablet;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final itemSize = isTablet ? 12.0 : 11.0;

    final optionList = options.isEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text(
              emptySearchLabel,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: itemSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            physics: const ClampingScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Colors.grey.shade100,
            ),
            itemBuilder: (context, index) {
              final opt = options[index];
              final selected = opt.value == selectedValue;
              return InkWell(
                onTap: () => onSelected(opt.value),
                child: Container(
                  color: selected
                      ? AppColors.primaryLight.withValues(alpha: 0.12)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: opt.child ??
                            Text(
                              opt.label ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: itemSize,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.secondaryLight,
                        ),
                    ],
                  ),
                ),
              );
            },
          );

    return Material(
      elevation: 10,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: optionList,
    );
  }
}
