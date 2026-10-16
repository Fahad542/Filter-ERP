import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Arabic: "Car services"
const _arabicTagline = 'خدمات السيارات';
const _primary = Color(0xFFFCC247);

const _splashW = 1024;
const _splashH = 600;
const _splashIconSize = 288;

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export splash PNG assets', () async {
    await _loadArabicFont();

    final iconBytes = await rootBundle.load('assets/images/Icon.png');
    final iconCodec = await ui.instantiateImageCodec(
      iconBytes.buffer.asUint8List(),
    );
    final iconFrame = await iconCodec.getNextFrame();
    final iconImage = iconFrame.image;

    final splashBytes = await _renderSplash(
      width: _splashW,
      height: _splashH,
      iconImage: iconImage,
      logoWidth: _splashW * 0.36,
      taglineSize: 28,
      taglineGap: 20,
    );

    final iconSplashBytes = await _renderSplash(
      width: _splashIconSize,
      height: _splashIconSize,
      iconImage: iconImage,
      logoWidth: _splashIconSize * 0.62,
      taglineSize: 18,
      taglineGap: 10,
    );

    _writeBytes('assets/icon/splash_screen.png', splashBytes);
    _writeBytes(
      'android/app/src/main/res/drawable-nodpi/splash_screen.png',
      splashBytes,
    );
    _writeBytes(
      'android/app/src/main/res/drawable-nodpi/splash_icon.png',
      iconSplashBytes,
    );

    final decoded = img.decodePng(splashBytes);
    expect(decoded, isNotNull);
    _writeIosLaunchImages(decoded!);
  });
}

Future<void> _loadArabicFont() async {
  final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
  final loader = FontLoader('NotoSansArabicBold')
    ..addFont(Future.value(fontData));
  await loader.load();
}

Future<Uint8List> _renderSplash({
  required int width,
  required int height,
  required ui.Image iconImage,
  required double logoWidth,
  required double taglineSize,
  required double taglineGap,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = _primary,
  );

  final logoScale = logoWidth / iconImage.width;
  final logoHeight = iconImage.height * logoScale;
  final logoLeft = (width - logoWidth) / 2;

  final tagline = _buildTaglineParagraph(
    fontSize: taglineSize,
    maxWidth: width - 80,
  );
  final totalHeight = logoHeight + taglineGap + tagline.height;
  var top = (height - totalHeight) / 2;

  final blackLogo = Paint()
    ..colorFilter = const ColorFilter.mode(Colors.black, BlendMode.srcIn);
  canvas.drawImageRect(
    iconImage,
    Rect.fromLTWH(0, 0, iconImage.width.toDouble(), iconImage.height.toDouble()),
    Rect.fromLTWH(logoLeft, top, logoWidth, logoHeight),
    blackLogo,
  );

  top += logoHeight + taglineGap;
  canvas.drawParagraph(tagline, Offset(40, top));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(data, isNotNull);
  return data!.buffer.asUint8List();
}

ui.Paragraph _buildTaglineParagraph({
  required double fontSize,
  required double maxWidth,
}) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      fontFamily: 'NotoSansArabicBold',
      fontSize: fontSize,
      maxLines: 2,
    ),
  )
    ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)))
    ..addText(_arabicTagline);

  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: maxWidth));
  return paragraph;
}

void _writeBytes(String path, Uint8List bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

void _writeIosLaunchImages(img.Image master) {
  const dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
  if (!Directory(dir).existsSync()) return;

  const specs = {
    'LaunchImage.png': 400,
    'LaunchImage@2x.png': 800,
    'LaunchImage@3x.png': 1200,
  };
  for (final e in specs.entries) {
    final resized = img.copyResize(
      master,
      width: e.value,
      height: (e.value * master.height / master.width).round(),
    );
    File('$dir/${e.key}').writeAsBytesSync(img.encodePng(resized));
  }
}
