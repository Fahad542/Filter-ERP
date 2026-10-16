import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

/// Shared Workshop Owner list UI — match Departments catalog look.
/// Prefer theme colors ([AppColors.primaryLight] / [AppColors.secondaryLight])
/// over rainbow accents (blue / purple / teal / orange for chrome).
abstract final class OwnerListStyle {
  static const cardRadius = BorderRadius.all(Radius.circular(16));
  static const iconRadius = BorderRadius.all(Radius.circular(12));

  static const cardBorder = Color(0xFFEEEEEE);
  static const mutedText = Color(0xFF9E9E9E);
  static const labelGrey = Color(0xFF8A94A6);

  /// White catalog card.
  static const cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: cardRadius,
    border: Border.fromBorderSide(BorderSide(color: cardBorder)),
  );

  /// Dark icon / initials box (yellow glyph on top).
  static const iconBoxDecoration = BoxDecoration(
    color: AppColors.secondaryLight,
    borderRadius: iconRadius,
  );

  static const double iconBoxSize = 44;

  /// Soft secondary tint for action / chip backgrounds (~8% opacity).
  static const Color actionBg = Color(0x1423262D);

  static const Color actionIcon = AppColors.secondaryLight;
  static const Color actionPrimaryIcon = AppColors.primaryLight;

  /// Delete stays red (destructive).
  static const Color deleteBg = Colors.red;
  static const Color deleteIcon = Colors.white;

  static TextStyle get titleStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLight,
      );

  static TextStyle get subtitleStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mutedText,
      );

  static TextStyle get metaStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mutedText,
      );
}

/// Leading icon box used on Owner list cards (department-style).
class OwnerListIconBox extends StatelessWidget {
  final IconData icon;
  final Widget? child;
  final bool showActiveDot;

  const OwnerListIconBox({
    super.key,
    this.icon = Icons.store_rounded,
    this.child,
    this.showActiveDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: OwnerListStyle.iconBoxSize,
      height: OwnerListStyle.iconBoxSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: OwnerListStyle.iconBoxDecoration,
            child: SizedBox(
              width: OwnerListStyle.iconBoxSize,
              height: OwnerListStyle.iconBoxSize,
              child: Center(
                child: child ??
                    Icon(
                      icon,
                      color: AppColors.primaryLight,
                      size: 22,
                    ),
              ),
            ),
          ),
          if (showActiveDot)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
