// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Brand colors from [AppColors].
const _primary = 0xFFFCC247;
/// FILTER wordmark on launcher icon + splash (user-requested black).
const _logoColor = 0xFF000000;

const _srcPath = 'assets/images/Icon.png';
const _outDir = 'assets/icon';
const _androidRes = 'android/app/src/main/res';
const _launcherLogoFill = 0.68; // inset from canvas edge (~16% padding each side)
const _adaptiveLogoFill = 0.58; // adaptive icons crop edges — keep logo smaller
const _iosIconSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _iosLaunchImageSet =
    'ios/Runner/Assets.xcassets/LaunchImage.imageset';
const _splashLogoWidth = 480; // wordmark width for legacy layers
const _splashScreenSize = 512; // composed icon for launch_background
const _splashIconSize = 288; // Android 12+ windowSplashScreenAnimatedIcon
const _splashIconFill = 0.62;

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    print('Run from Flutter project root.');
    exit(1);
  }

  final srcBytes = File(_srcPath).readAsBytesSync();
  final src = img.decodeImage(srcBytes);
  if (src == null) {
    print('Could not decode $_srcPath');
    exit(1);
  }

  Directory(_outDir).createSync(recursive: true);

  const master = 1024;
  final composed = _buildLauncherIcon(src, master);
  final foreground = _buildAdaptiveForeground(src, 432);

  File('$_outDir/filter_erp_icon.png').writeAsBytesSync(img.encodePng(composed));
  File('$_outDir/filter_erp_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  _writeAndroidMipmaps(composed);
  _writeAdaptiveAndroid(foreground);
  _writeIosIcons(composed);

  print('Generated Filter ERP launcher icons.');
  print('  Master: $_outDir/filter_erp_icon.png');

  final splash = await Process.run(
    'flutter',
    ['test', 'test/generate_splash_assets_test.dart', '--reporter', 'compact'],
    runInShell: true,
  );
  if (splash.exitCode != 0) {
    print('Splash generation failed:\n${splash.stdout}\n${splash.stderr}');
    exit(splash.exitCode);
  }
  print('Generated splash (FILTER + Arabic tagline).');
}

img.Image _buildLauncherIcon(img.Image src, int size) {
  final out = img.Image(width: size, height: size);
  img.fill(
    out,
    color: img.ColorRgba8(
      (_primary >> 16) & 0xFF,
      (_primary >> 8) & 0xFF,
      _primary & 0xFF,
      255,
    ),
  );

  final scale = (size * _launcherLogoFill) / math.max(src.width, src.height);
  final drawW = (src.width * scale).round();
  final drawH = (src.height * scale).round();
  final offsetX = ((size - drawW) / 2).round();
  final offsetY = ((size - drawH) / 2).round();

  final resized = img.copyResize(src, width: drawW, height: drawH);

  for (var y = 0; y < drawH; y++) {
    for (var x = 0; x < drawW; x++) {
      final p = resized.getPixel(x, y);
      if (!_isLogoPixel(p)) continue;
      final alpha = _logoAlpha(p);
      if (alpha <= 0) continue;
      out.setPixelRgba(
        offsetX + x,
        offsetY + y,
        (_logoColor >> 16) & 0xFF,
        (_logoColor >> 8) & 0xFF,
        _logoColor & 0xFF,
        alpha,
      );
    }
  }
  return out;
}

img.Image _buildAdaptiveForeground(img.Image src, int size) {
  final out = img.Image(width: size, height: size, numChannels: 4);
  // Transparent canvas — Android adaptive background supplies primary color.
  final scale = (size * _adaptiveLogoFill) / math.max(src.width, src.height);
  final drawW = (src.width * scale).round();
  final drawH = (src.height * scale).round();
  final offsetX = ((size - drawW) / 2).round();
  final offsetY = ((size - drawH) / 2).round();
  final resized = img.copyResize(src, width: drawW, height: drawH);

  for (var y = 0; y < drawH; y++) {
    for (var x = 0; x < drawW; x++) {
      final p = resized.getPixel(x, y);
      if (!_isLogoPixel(p)) continue;
      final alpha = _logoAlpha(p);
      if (alpha <= 0) continue;
      out.setPixelRgba(
        offsetX + x,
        offsetY + y,
        (_logoColor >> 16) & 0xFF,
        (_logoColor >> 8) & 0xFF,
        _logoColor & 0xFF,
        alpha,
      );
    }
  }
  return out;
}

/// Secondary FILTER wordmark on transparent background (splash / launch screen).
img.Image _buildSplashLogo(img.Image src, int targetWidth) {
  final scale = targetWidth / src.width;
  final drawH = math.max(1, (src.height * scale).round());
  final out = img.Image(width: targetWidth, height: drawH, numChannels: 4);
  final resized = img.copyResize(src, width: targetWidth, height: drawH);

  for (var y = 0; y < drawH; y++) {
    for (var x = 0; x < targetWidth; x++) {
      final p = resized.getPixel(x, y);
      if (!_isLogoPixel(p)) continue;
      final alpha = _logoAlpha(p);
      if (alpha <= 0) continue;
      out.setPixelRgba(
        x,
        y,
        (_logoColor >> 16) & 0xFF,
        (_logoColor >> 8) & 0xFF,
        _logoColor & 0xFF,
        alpha,
      );
    }
  }
  return out;
}

void _writeSplashAssets(img.Image src) {
  final nodpi = Directory('$_androidRes/drawable-nodpi');
  nodpi.createSync(recursive: true);

  // Full yellow + black logo — most reliable for windowBackground splash.
  final splashScreen = _buildLauncherIcon(src, _splashScreenSize);
  File('$_outDir/splash_screen.png').writeAsBytesSync(img.encodePng(splashScreen));
  File('${nodpi.path}/splash_screen.png')
      .writeAsBytesSync(img.encodePng(splashScreen));

  // Transparent square logo for Android 12+ system splash icon slot.
  final splashIcon = _buildSplashIcon(src, _splashIconSize);
  File('${nodpi.path}/splash_icon.png').writeAsBytesSync(img.encodePng(splashIcon));

  final wordmark = _buildSplashLogo(src, _splashLogoWidth);
  File('$_outDir/splash_logo.png').writeAsBytesSync(img.encodePng(wordmark));
  File('${nodpi.path}/splash_logo.png').writeAsBytesSync(img.encodePng(wordmark));

  // Remove legacy copy from drawable/ (density scaling broke visibility on some devices).
  final legacy = File('$_androidRes/drawable/splash_logo.png');
  if (legacy.existsSync()) legacy.deleteSync();

  const iosWidths = {
    'LaunchImage.png': 400,
    'LaunchImage@2x.png': 800,
    'LaunchImage@3x.png': 1200,
  };
  final launchDir = Directory(_iosLaunchImageSet);
  if (!launchDir.existsSync()) return;
  for (final entry in iosWidths.entries) {
    final logo = _buildSplashLogo(src, entry.value);
    File('${launchDir.path}/${entry.key}').writeAsBytesSync(img.encodePng(logo));
  }
}

img.Image _buildSplashIcon(img.Image src, int size) {
  final out = img.Image(width: size, height: size, numChannels: 4);
  final scale = (size * _splashIconFill) / math.max(src.width, src.height);
  final drawW = (src.width * scale).round();
  final drawH = (src.height * scale).round();
  final offsetX = ((size - drawW) / 2).round();
  final offsetY = ((size - drawH) / 2).round();
  final resized = img.copyResize(src, width: drawW, height: drawH);

  for (var y = 0; y < drawH; y++) {
    for (var x = 0; x < drawW; x++) {
      final p = resized.getPixel(x, y);
      if (!_isLogoPixel(p)) continue;
      final alpha = _logoAlpha(p);
      if (alpha <= 0) continue;
      out.setPixelRgba(
        offsetX + x,
        offsetY + y,
        (_logoColor >> 16) & 0xFF,
        (_logoColor >> 8) & 0xFF,
        _logoColor & 0xFF,
        alpha,
      );
    }
  }
  return out;
}

bool _isLogoPixel(img.Pixel p) {
  final a = p.a.toInt();
  if (a < 8) return false;
  final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
  return lum > 40;
}

int _logoAlpha(img.Pixel p) {
  final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).clamp(0, 255);
  final a = p.a.toInt();
  return ((lum / 255) * a).round().clamp(0, 255);
}

void _writeAndroidMipmaps(img.Image master) {
  const sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final e in sizes.entries) {
    final dir = Directory('$_androidRes/${e.key}');
    dir.createSync(recursive: true);
    final resized = img.copyResize(master, width: e.value, height: e.value);
    File('${dir.path}/ic_launcher.png')
        .writeAsBytesSync(img.encodePng(resized));
  }
}

void _writeAdaptiveAndroid(img.Image foreground) {
  final anydpi = Directory('$_androidRes/mipmap-anydpi-v26');
  anydpi.createSync(recursive: true);

  const fgPath = '$_androidRes/drawable/ic_launcher_foreground.png';
  Directory('$_androidRes/drawable').createSync(recursive: true);
  File(fgPath).writeAsBytesSync(img.encodePng(foreground));

  File('${anydpi.path}/ic_launcher.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''');

  File('${anydpi.path}/ic_launcher_round.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''');

  final valuesDir = Directory('$_androidRes/values');
  valuesDir.createSync(recursive: true);
  final colorsFile = File('${valuesDir.path}/ic_launcher_colors.xml');
  if (!colorsFile.existsSync()) {
    colorsFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FCC247</color>
</resources>
''');
  }
}

void _writeIosIcons(img.Image master) {
  const iosSizes = [
    ('Icon-App-20x20@1x.png', 20),
    ('Icon-App-20x20@2x.png', 40),
    ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29),
    ('Icon-App-29x29@2x.png', 58),
    ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40),
    ('Icon-App-40x40@2x.png', 80),
    ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-60x60@2x.png', 120),
    ('Icon-App-60x60@3x.png', 180),
    ('Icon-App-76x76@1x.png', 76),
    ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167),
    ('Icon-App-1024x1024@1x.png', 1024),
  ];

  final dir = Directory(_iosIconSet);
  if (!dir.existsSync()) return;

  for (final spec in iosSizes) {
    final resized = img.copyResize(master, width: spec.$2, height: spec.$2);
    File('${dir.path}/${spec.$1}').writeAsBytesSync(img.encodePng(resized));
  }
}
