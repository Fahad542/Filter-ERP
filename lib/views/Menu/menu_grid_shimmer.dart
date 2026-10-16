import 'package:flutter/material.dart';

class MenuGridShimmer extends StatelessWidget {
  const MenuGridShimmer({
    super.key,
    required this.crossAxisCount,
    required this.childAspectRatio,
    this.itemCount = 6,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final int itemCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  static const Color _baseFill = Color(0xFFEBEBEB);
  static const Color _shimmerEdge = Color(0xFFF0F0F0);
  static const Color _shimmerPeak = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;
    final compact = isTablet && size.width > size.height;
    final radius = compact ? 12.0 : 20.0;
    final iconSize = compact ? 40.0 : 56.0;
    final titleWidth = compact ? 72.0 : 88.0;
    final elevation = compact ? 3.0 : 4.0;

    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        return Card(
          elevation: elevation,
          shadowColor: Colors.black12,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 16),
            child: _MenuShimmer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MenuShimmerCircle(size: iconSize),
                  SizedBox(height: compact ? 8 : 16),
                  _MenuShimmerLine(
                    width: titleWidth,
                    height: compact ? 12 : 14,
                    radius: 7,
                  ),
                  const SizedBox(height: 6),
                  _MenuShimmerLine(
                    width: titleWidth * 0.72,
                    height: compact ? 10 : 12,
                    radius: 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuShimmer extends StatefulWidget {
  const _MenuShimmer({required this.child});

  final Widget child;

  @override
  State<_MenuShimmer> createState() => _MenuShimmerState();
}

class _MenuShimmerState extends State<_MenuShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final shimmerWidth = bounds.width * 0.5;
              final dx = (bounds.width + shimmerWidth) * _controller.value -
                  shimmerWidth;

              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  MenuGridShimmer._shimmerEdge,
                  MenuGridShimmer._shimmerPeak,
                  MenuGridShimmer._shimmerEdge,
                ],
                stops: const [0.28, 0.5, 0.72],
                transform: _MenuSlidingGradientTransform(dx),
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

class _MenuSlidingGradientTransform extends GradientTransform {
  const _MenuSlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class _MenuShimmerLine extends StatelessWidget {
  const _MenuShimmerLine({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MenuGridShimmer._baseFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _MenuShimmerCircle extends StatelessWidget {
  const _MenuShimmerCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: MenuGridShimmer._baseFill,
        shape: BoxShape.circle,
      ),
    );
  }
}
