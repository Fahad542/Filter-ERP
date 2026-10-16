import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// App bar / auth header logo; never throws if the PNG is missing from the bundle.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.high,
    this.fallbackIcon = Icons.store_mall_directory_rounded,
    this.fallbackSize,
  });

  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final FilterQuality filterQuality;
  final IconData fallbackIcon;
  final double? fallbackSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/images/icons.png",
      height: height,
      width: width,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stackTrace) {
        final sz = fallbackSize ?? height ?? width ?? 32;
        return Icon(
          fallbackIcon,
          size: sz,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        );
      },
    );
  }
}
