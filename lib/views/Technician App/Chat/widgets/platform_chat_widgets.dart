import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../widgets/pos_shimmer.dart';

class PlatformChatAvatar extends StatelessWidget {
  const PlatformChatAvatar({
    super.key,
    required this.title,
    this.isGroup = false,
    this.size = 48,
  });

  final String title;
  final bool isGroup;
  final double size;

  static const _palette = [
    (bg: Color(0xFF23262D), fg: Color(0xFFFCC245)),
    (bg: Color(0xFFFCC245), fg: Color(0xFF111111)),
    (bg: Color(0xFF2E323A), fg: Color(0xFFFCC245)),
    (bg: Color(0xFFFFF4D6), fg: Color(0xFF92400E)),
  ];

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isEmpty) return '?';
    return parts.first.length >= 2
        ? parts.first.substring(0, 2).toUpperCase()
        : parts.first[0].toUpperCase();
  }

  ({Color bg, Color fg}) _colorsFor(String name) {
    var h = 0;
    for (var i = 0; i < name.length; i++) {
      h = (h * 31 + name.codeUnitAt(i)) % _palette.length;
    }
    return _palette[h];
  }

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.35),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(Icons.groups_rounded, color: AppColors.secondaryLight, size: size * 0.45),
      );
    }
    final colors = _colorsFor(title);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        _initials(title),
        style: TextStyle(
          color: colors.fg,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

/// Custom chat bubble asset (white-outline icon on dark backgrounds).
class TechChatActionIcon extends StatelessWidget {
  const TechChatActionIcon({
    super.key,
    this.size = 22,
    this.color,
  });

  final double size;
  final Color? color;

  static const _assetPath = 'assets/images/tech_chat_icon.png';

  @override
  Widget build(BuildContext context) {
    final icon = Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
    );
    return icon;
  }
}

/// Placeholder for My Chats / Members list while loading.
class TechChatListShimmer extends StatelessWidget {
  const TechChatListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return PosShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              PosShimmerCircle(size: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PosShimmerLine(width: 120, height: 14, radius: 6),
                    SizedBox(height: 6),
                    PosShimmerLine(width: 180, height: 12, radius: 6),
                  ],
                ),
              ),
              SizedBox(width: 8),
              PosShimmerLine(width: 36, height: 10, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Repeating wallpaper behind the chat message list.
class TechChatThreadBackground extends StatelessWidget {
  const TechChatThreadBackground({super.key, required this.child});

  static const assetPath = 'assets/images/tech_chat_bg.png';
  static const fallbackColor = Color(0xFFEFEAE2);

  static const decoration = BoxDecoration(
    color: fallbackColor,
    image: DecorationImage(
      image: AssetImage(assetPath),
      repeat: ImageRepeat.repeat,
    ),
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      child: child,
    );
  }
}

/// Placeholder for chat thread while messages load.
class TechChatThreadShimmer extends StatelessWidget {
  const TechChatThreadShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: const [
        Center(child: _TechChatDateShimmer()),
        SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: _TechChatBubbleShimmer(width: 200, isSelf: false),
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _TechChatBubbleShimmer(width: 150, isSelf: true),
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _TechChatBubbleShimmer(width: 170, isSelf: false),
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _TechChatBubbleShimmer(width: 220, isSelf: true),
        ),
      ],
    );
  }
}

/// Higher-contrast shimmer for patterned chat backgrounds.
class _TechChatShimmer extends StatefulWidget {
  const _TechChatShimmer({required this.child});

  final Widget child;

  @override
  State<_TechChatShimmer> createState() => _TechChatShimmerState();
}

class _TechChatShimmerState extends State<_TechChatShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
            final shimmerWidth = bounds.width * 0.65;
            final dx =
                (bounds.width + shimmerWidth) * _controller.value - shimmerWidth;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFEDEDED),
                Color(0xFFF8F8F8),
                Color(0xFFEDEDED),
                Color(0xFFE0E0E0),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _TechChatShimmerSlide(dx),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _TechChatShimmerSlide extends GradientTransform {
  const _TechChatShimmerSlide(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class _TechChatShimmerBar extends StatelessWidget {
  const _TechChatShimmerBar({
    required this.width,
    this.height = 10,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _TechChatShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _TechChatDateShimmer extends StatelessWidget {
  const _TechChatDateShimmer();

  @override
  Widget build(BuildContext context) {
    return _TechChatShimmer(
      child: Container(
        width: 96,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechChatBubbleShimmer extends StatelessWidget {
  const _TechChatBubbleShimmer({
    required this.width,
    required this.isSelf,
  });

  final double width;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isSelf ? 12 : 4),
          bottomRight: Radius.circular(isSelf ? 4 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TechChatShimmerBar(width: width * 0.58),
          const SizedBox(height: 8),
          _TechChatShimmerBar(width: width * 0.32, height: 8),
        ],
      ),
    );
  }
}
