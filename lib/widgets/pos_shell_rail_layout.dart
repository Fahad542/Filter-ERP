import 'package:flutter/material.dart';

/// When tablet landscape shell shows the side menu rail, body content is
/// padded on the [start] edge so it does not sit under the rail (RTL-aware).
///
/// When the rail is a sibling column (full-height beside content), set
/// [bodyRailPadding] to 0 and [sideMenuActive] to true so app bars still
/// hide the hamburger / treat the rail as present.
class PosShellRailLayout extends InheritedWidget {
  final double bodyRailPadding;

  /// True when the shell side menu is shown (even if [bodyRailPadding] is 0).
  final bool sideMenuActive;

  const PosShellRailLayout({
    super.key,
    required double bodyRailPadding,
    this.sideMenuActive = false,
    required super.child,
  }) : bodyRailPadding = bodyRailPadding;

  /// @deprecated Use [bodyRailPadding].
  double get bodyLeftPadding => bodyRailPadding;

  /// Inset reserved beside tab body for the shell menu rail (0 when hidden).
  static double bodyRailOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<PosShellRailLayout>()
            ?.bodyRailPadding ??
        0;
  }

  /// @deprecated Use [bodyRailOf].
  static double bodyLeftOf(BuildContext context) => bodyRailOf(context);

  /// True when the shell shows the fixed side menu strip (not Orders Hub).
  static bool hasSideMenuRail(BuildContext context) {
    final layout =
        context.dependOnInheritedWidgetOfExactType<PosShellRailLayout>();
    if (layout == null) return false;
    return layout.sideMenuActive || layout.bodyRailPadding > 0;
  }

  /// @deprecated Use [hasSideMenuRail].
  static bool hasLeftMenuRail(BuildContext context) => hasSideMenuRail(context);

  @override
  bool updateShouldNotify(PosShellRailLayout oldWidget) =>
      oldWidget.bodyRailPadding != bodyRailPadding ||
      oldWidget.sideMenuActive != sideMenuActive;
}

/// Pads [child] when shell landscape rail is active (start edge follows locale).
Widget wrapPosShellRailBody(BuildContext context, Widget child) {
  final inset = PosShellRailLayout.bodyRailOf(context);
  if (inset <= 0) return child;
  return Padding(
    padding: EdgeInsetsDirectional.only(start: inset),
    child: child,
  );
}

/// Optically centers [child] under the full-width app bar (logo/title) when the
/// body is inset for the side menu rail.
Widget alignPosBodyToAppBarCenter(BuildContext context, Widget child) {
  final rail = PosShellRailLayout.bodyRailOf(context);
  if (rail <= 0) return child;
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  final dx = (isRtl ? 0.5 : -0.5) * rail;
  return Transform.translate(offset: Offset(dx, 0), child: child);
}
