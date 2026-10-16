import 'package:flutter/material.dart';

import '../../../widgets/pos_shimmer.dart';
class TechListCardShimmer extends StatelessWidget {
  const TechListCardShimmer({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 24),
    this.includeSearchBar = false,
  });

  final int itemCount;
  final EdgeInsets padding;
  final bool includeSearchBar;

  static const Color _baseFill = Color(0xFFEBEBEB);
  static const Color _shimmerEdge = Color(0xFFF0F0F0);
  static const Color _shimmerPeak = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (includeSearchBar) ...[
          _TechShimmerBox(width: double.infinity, height: 48, radius: 16),
          const SizedBox(height: 10),
        ],
        ...List.generate(itemCount, (_) => _cardPlaceholder()),
      ],
    );
  }

  Widget _cardPlaceholder() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _TechListShimmer(
          child: Row(
            children: [
              _TechShimmerBox(width: 38, height: 38, radius: 12),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TechShimmerLine(width: 130, height: 10, radius: 6),
                    SizedBox(height: 8),
                    _TechShimmerLine(width: 96, height: 14, radius: 6),
                    SizedBox(height: 6),
                    _TechShimmerLine(width: 72, height: 10, radius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TechShimmerLine(width: 76, height: 16, radius: 6),
                  SizedBox(height: 6),
                  _TechShimmerLine(width: 52, height: 10, radius: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechListShimmer extends StatefulWidget {
  const _TechListShimmer({required this.child});

  final Widget child;

  @override
  State<_TechListShimmer> createState() => _TechListShimmerState();
}

class _TechListShimmerState extends State<_TechListShimmer>
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
                TechListCardShimmer._shimmerEdge,
                TechListCardShimmer._shimmerPeak,
                TechListCardShimmer._shimmerEdge,
              ],
              stops: const [0.28, 0.5, 0.72],
              transform: _TechSlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _TechSlidingGradientTransform extends GradientTransform {
  const _TechSlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class _TechShimmerBox extends StatelessWidget {
  const _TechShimmerBox({
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
        color: TechListCardShimmer._baseFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _TechShimmerLine extends StatelessWidget {
  const _TechShimmerLine({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _TechShimmerBox(width: width, height: height, radius: radius);
  }
}

/// Profile / detail body placeholder.
class TechDetailShimmer extends StatelessWidget {
  const TechDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return PosShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  PosShimmerCircle(size: 72),
                  SizedBox(height: 16),
                  PosShimmerLine(width: 160, height: 16, radius: 8),
                  SizedBox(height: 8),
                  PosShimmerLine(width: 120, height: 12, radius: 6),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosShimmerLine(width: 140, height: 14, radius: 6),
                      SizedBox(height: 14),
                      PosShimmerLine(width: double.infinity, height: 44, radius: 12),
                      SizedBox(height: 10),
                      PosShimmerLine(width: double.infinity, height: 44, radius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
