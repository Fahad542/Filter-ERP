import 'package:flutter/material.dart';

/// Dashboard body placeholder while KPI/profile data loads (header stays real).
class TechDashboardShimmer extends StatelessWidget {
  const TechDashboardShimmer({super.key});

  static const Color _baseFill = Color(0xFFEBEBEB);
  static const Color _shimmerEdge = Color(0xFFF0F0F0);
  static const Color _shimmerPeak = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: _TechDashboardShimmerMask(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TechDashShimmerLine(width: 110, height: 12, radius: 6),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: List.generate(4, (_) => _statCardPlaceholder()),
            ),
            const SizedBox(height: 24),
            _quickActionPlaceholder(),
            const SizedBox(height: 32),
            const _TechDashShimmerLine(width: 88, height: 12, radius: 6),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _dutyTogglePlaceholder()),
                const SizedBox(width: 16),
                Expanded(child: _dutyTogglePlaceholder()),
              ],
            ),
            const SizedBox(height: 12),
            const _TechDashShimmerLine(
              width: double.infinity,
              height: 11,
              radius: 5,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statCardPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TechDashShimmerBox(width: 30, height: 30, radius: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TechDashShimmerLine(width: 78, height: 14, radius: 6),
              SizedBox(height: 6),
              _TechDashShimmerLine(width: 54, height: 9, radius: 5),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _quickActionPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TechDashShimmerBox(width: 20, height: 20, radius: 10),
          SizedBox(width: 12),
          _TechDashShimmerLine(width: 148, height: 13, radius: 6),
          SizedBox(width: 10),
          _TechDashShimmerBox(width: 24, height: 24, radius: 12),
        ],
      ),
    );
  }

  static Widget _dutyTogglePlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TechDashShimmerLine(width: 92, height: 13, radius: 6),
                SizedBox(height: 6),
                _TechDashShimmerLine(width: 64, height: 10, radius: 5),
              ],
            ),
          ),
          SizedBox(width: 8),
          _TechDashShimmerBox(width: 50, height: 28, radius: 14),
        ],
      ),
    );
  }
}

class _TechDashboardShimmerMask extends StatefulWidget {
  const _TechDashboardShimmerMask({required this.child});

  final Widget child;

  @override
  State<_TechDashboardShimmerMask> createState() =>
      _TechDashboardShimmerMaskState();
}

class _TechDashboardShimmerMaskState extends State<_TechDashboardShimmerMask>
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
    return AnimatedBuilder(
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
                TechDashboardShimmer._shimmerEdge,
                TechDashboardShimmer._shimmerPeak,
                TechDashboardShimmer._shimmerEdge,
              ],
              stops: const [0.28, 0.5, 0.72],
              transform: _TechDashSlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _TechDashSlidingGradientTransform extends GradientTransform {
  const _TechDashSlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class _TechDashShimmerBox extends StatelessWidget {
  const _TechDashShimmerBox({
    required this.width,
    required this.height,
    this.radius = 10,
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
        color: TechDashboardShimmer._baseFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _TechDashShimmerLine extends StatelessWidget {
  const _TechDashShimmerLine({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _TechDashShimmerBox(width: width, height: height, radius: radius);
  }
}
