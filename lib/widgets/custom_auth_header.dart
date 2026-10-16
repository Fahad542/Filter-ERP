import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/pos_tablet_layout.dart';
import '../views/Workshop pos app/More Tab/settings_view_model.dart';
import 'app_brand_logo.dart';

class CustomAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final double? height;
  /// Extra gap below [subtitle] (e.g. POS login before the form card).
  final double subtitleBottomSpacing;

  const CustomAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.onBackTap,
    this.height,
    this.subtitleBottomSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final compact = PosTabletLayout.compactLandscapeChrome(context);

    final double iconContainerSize =
        compact ? 42 : (isTablet ? 50 : 40);
    final double iconSize = compact ? 24 : (isTablet ? 30 : 22);
    final double logoHeight = compact ? 38 : 45;
    final double toolbarRowHeight = compact ? 44 : 50;

    return ClipRect(
      child: Container(
        height: height ?? screenHeight * 0.35,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final minTitleBlockHeight =
                  (compact ? 44.0 : 52.0) + subtitleBottomSpacing;

              // Tighter top inset when the header is compressed (e.g. keyboard open).
              final topSpacing = availableHeight < 160
                  ? (availableHeight * 0.02).clamp(0.0, 4.0)
                  : (availableHeight * (compact ? 0.03 : 0.06))
                      .clamp(0.0, compact ? 14.0 : (isTablet ? 40.0 : 10.0));

              final showTitles = availableHeight >=
                  topSpacing + toolbarRowHeight + minTitleBlockHeight;

              final maxMidSpacing = compact ? 24.0 : (isTablet ? 60.0 : 30.0);
              final midSpacing = showTitles
                  ? (availableHeight -
                          topSpacing -
                          toolbarRowHeight -
                          minTitleBlockHeight)
                      .clamp(0.0, maxMidSpacing)
                  : 0.0;

              return SizedBox(
                height: availableHeight,
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    // Top row: Back | Logo (center) | Language
                    SizedBox(
                      height: toolbarRowHeight,
                      width: double.infinity,
                      child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back — start side (left in LTR, right in RTL/Arabic)
                        if (showBackButton)
                          PositionedDirectional(
                            start: 16,
                            child: InkWell(
                              onTap: onBackTap ?? () => Navigator.pop(context),
                              child: Container(
                                width: iconContainerSize,
                                height: iconContainerSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.black,
                                    size: iconSize,
                                    textDirection:
                                        Directionality.of(context),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Logo – dead center
                        SizedBox(
                          height: logoHeight,
                          child: AppBrandLogo(
                            height: logoHeight,
                            color: Colors.black,
                            fit: BoxFit.contain,
                            fallbackSize: compact ? 30 : 36,
                          ),
                        ),

                        // Language — end side (right in LTR, left in RTL/Arabic)
                        PositionedDirectional(
                          end: 16,
                          child: Consumer<SettingsViewModel>(
                            builder: (context, settings, _) {
                              return InkWell(
                                onTap: () {
                                  final newLocale =
                                  settings.locale.languageCode == 'en'
                                      ? const Locale('ar')
                                      : const Locale('en');
                                  settings.updateLocale(newLocale);
                                },
                                child: Container(
                                  width: iconContainerSize,
                                  height: iconContainerSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/global.png',
                                      width: iconSize,
                                      height: iconSize,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.language,
                                        size: iconSize,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                    if (showTitles)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: midSpacing),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.h2.copyWith(
                                      color: AppColors.onPrimaryLight,
                                      fontSize: compact ? 18 : (isTablet ? 22 : 20),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: compact ? 4 : 8),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.onPrimaryLight
                                          .withOpacity(0.7),
                                      fontSize: compact ? 12 : (isTablet ? 14 : 13),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (subtitleBottomSpacing > 0)
                                    SizedBox(height: subtitleBottomSpacing),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}