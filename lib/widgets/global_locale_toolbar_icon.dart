import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/pos_tablet_layout.dart';
import '../views/Workshop pos app/More Tab/settings_view_model.dart';

/// Same globe / language toggle as [PosScreenAppBar] (EN ↔ AR).
class GlobalLocaleToolbarIcon extends StatelessWidget {
  const GlobalLocaleToolbarIcon({super.key, this.inCluster = false});

  final bool inCluster;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final box = isTablet ? PosTabletLayout.appBarIconBox : 40.0;
    final img = isTablet ? 26.0 : 22.0;

    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        return Padding(
          padding: EdgeInsetsDirectional.only(end: inCluster ? 4 : 6),
          child: InkWell(
            onTap: () {
              final newLocale = settings.locale.languageCode == 'en'
                  ? const Locale('ar')
                  : const Locale('en');
              settings.updateLocale(newLocale);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: box,
              height: box,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/global.png',
                  width: img,
                  height: img,
                  color: Colors.black,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.language_rounded,
                    size: img,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
