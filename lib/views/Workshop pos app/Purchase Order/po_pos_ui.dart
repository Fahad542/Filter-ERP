import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_keyboard_locale.dart';

/// Shared POS chrome for Purchase Order screens (matches Petty Cash / Promo).
class PoPosSectionTitle extends StatelessWidget {
  const PoPosSectionTitle({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: AppColors.secondaryLight.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2124),
          ),
        ),
      ],
    );
  }
}

class PoPosLabel extends StatelessWidget {
  const PoPosLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class PoPosCard extends StatelessWidget {
  const PoPosCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration poPosInputDecoration({
  required String hint,
  IconData? prefixIcon,
  String? labelText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hint,
    hintStyle: TextStyle(
      color: Colors.grey.shade400,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    ),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(
            prefixIcon,
            color: AppColors.secondaryLight.withValues(alpha: 0.4),
            size: 16,
          ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade100),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade100),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

class PoPosTextField extends StatelessWidget {
  const PoPosTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hint = '',
    this.label,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.valueKey,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String hint;
  final String? label;
  final IconData? icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      key: valueKey,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLines: maxLines,
      keyboardType: keyboardType,
      hintLocales: appKeyboardHintLocales(context),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: poPosInputDecoration(
        hint: hint,
        prefixIcon: icon,
        labelText: label,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: field,
    );
  }
}

class PoPosPrimaryButton extends StatelessWidget {
  const PoPosPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.check_circle_outline,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 44 : 40,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryLight,
          disabledBackgroundColor: AppColors.secondaryLight,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          shadowColor: AppColors.secondaryLight.withValues(alpha: 0.4),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}

class PoPosStatusBadge extends StatelessWidget {
  const PoPosStatusBadge({super.key, required this.status});

  final String status;

  Color _bg() {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('draft')) {
      return const Color(0xFFFFF9EC);
    }
    if (s.contains('approv') || s.contains('complete') || s.contains('paid')) {
      return const Color(0xFFECFDF5);
    }
    if (s.contains('reject') || s.contains('cancel')) {
      return const Color(0xFFFFF5F5);
    }
    return const Color(0xFFF1F5F9);
  }

  Color _fg() {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('draft')) {
      return const Color(0xFFB48A14);
    }
    if (s.contains('approv') || s.contains('complete') || s.contains('paid')) {
      return const Color(0xFF15803D);
    }
    if (s.contains('reject') || s.contains('cancel')) {
      return const Color(0xFFB91C1C);
    }
    return const Color(0xFF475569);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _fg(),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PoPosEmptyState extends StatelessWidget {
  const PoPosEmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PoPosKpiChip extends StatelessWidget {
  const PoPosKpiChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
