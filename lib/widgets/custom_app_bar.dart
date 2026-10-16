import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../views/Workshop pos app/More Tab/settings_view_model.dart';
import '../utils/app_text_styles.dart';
import 'app_brand_logo.dart';
import 'app_bar_live_clock.dart';

Future<void> _makePhoneCall(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const CustomAppBar({
    super.key,
    this.height = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height + 25,
      title: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: const SizedBox(
          height: 45,
          child: AppBrandLogo(
            height: 45,
            color: Colors.black,
            fit: BoxFit.contain,
            fallbackIcon: Icons.store_mall_directory_rounded,
            fallbackSize: 36,
          ),
        ),
      ),
      centerTitle: true,
      elevation: 4,
      shadowColor: Colors.black26,
      backgroundColor: Theme.of(context).colorScheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: PosAppBarTrailingCluster(
            belowClock: [
              Consumer<SettingsViewModel>(
                builder: (context, settings, child) {
                  return IconButton(
                icon: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language,
                    size: 30,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                onPressed: () {
                  final newLocale = settings.locale.languageCode == 'en'
                      ? const Locale('ar')
                      : const Locale('en');
                  settings.updateLocale(newLocale);
                },
                    tooltip: 'Change Language',
                  );
                },
              ),
            ],
          ),
        ),
      ],
      // We keep the leading widget (Drawer icon) automatically
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + 25);
}
