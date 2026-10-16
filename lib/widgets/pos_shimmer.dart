import 'package:flutter/material.dart';

class PosShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PosShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PosShimmer> createState() => _PosShimmerState();
}

class _PosShimmerState extends State<PosShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PosShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final shimmerWidth = bounds.width * 0.55;
              final dx =
                  (bounds.width + shimmerWidth) * _controller.value -
                      shimmerWidth;

              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFFE0E0E0),
                  Color(0xFFF2F2F2),
                  Color(0xFFE0E0E0),
                ],
                stops: const [0.25, 0.50, 0.75],
                transform: _PosSlidingGradientTransform(dx),
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          );
        },
      ),
    );
  }
}

class _PosSlidingGradientTransform extends GradientTransform {
  final double dx;

  const _PosSlidingGradientTransform(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class PosShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  /// Use dark=true when shimmer is placed on a dark card/background.
  final bool dark;

  const PosShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 10,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFDFDFDF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class PosShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  /// Use dark=true when shimmer is placed on a dark card/background.
  final bool dark;

  const PosShimmerLine({
    super.key,
    required this.width,
    this.height = 12,
    this.radius = 8,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return PosShimmerBox(
      width: width,
      height: height,
      radius: radius,
      dark: dark,
    );
  }
}

class PosShimmerCircle extends StatelessWidget {
  final double size;

  /// Use dark=true when shimmer is placed on a dark card/background.
  final bool dark;

  const PosShimmerCircle({
    super.key,
    this.size = 40,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFDFDFDF),
        shape: BoxShape.circle,
      ),
    );
  }
}