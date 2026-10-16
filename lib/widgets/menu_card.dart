import 'package:flutter/material.dart';
import '../utils/app_text_styles.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;
    final compact = isTablet && size.width > size.height;

    final iconPad = compact ? 8.0 : 16.0;
    final iconGlyph = compact ? 22.0 : 32.0;
    final titleSize = compact ? 14.0 : 16.0;
    final cardPad = compact ? 8.0 : 16.0;
    final radius = compact ? 12.0 : 20.0;

    return Card(
      elevation: compact ? 3 : 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: EdgeInsets.all(cardPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: (color ?? theme.colorScheme.secondary),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconGlyph,
                  color: color ?? theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: compact ? 8 : 16),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(fontSize: titleSize),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
