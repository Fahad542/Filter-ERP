// ════════════════════════════════════════════════════════════════════════════
// locker_shell.dart
//
// The Locker-portal equivalent of OwnerShell: a single reusable wrapper that
// supplies the SAME AppBar (OwnerAppBar, menu icon on the left, opens the
// drawer) and the SAME Drawer (LockerSidebar) on every locker screen.
//
// Unlike OwnerShell (which keeps every tab alive inside one outer Scaffold
// via an IndexedStack), the locker screens are still reached with normal
// Navigator.push() calls — so each one simply wraps its own content in a
// LockerShell instead of building its own bespoke Scaffold/AppBar/Drawer.
//
// Leading icon rules:
//   - Opened from the drawer → hamburger (default [Navigator.push])
//   - Opened from dashboard quick actions / View All → back arrow
//     (use [LockerShell.pushWithBack])
// ════════════════════════════════════════════════════════════════════════════

import 'package:filter_service_providers/views/Locker%20App/widgets/locker_dashboard_shared_widgets.dart';
import 'package:filter_service_providers/views/Locker%20App/widgets/locker_sidebar.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/app_colors.dart';
import '../Menu/menu_view.dart';
import '../Workshop Owner/widgets/owner_app_bar.dart';
import '../Workshop Owner/widgets/owner_ui_constants.dart';

class LockerShell extends StatefulWidget {
  /// Screen content. Do NOT wrap this in its own Scaffold — LockerShell
  /// supplies the Scaffold, AppBar and Drawer.
  final Widget body;

  /// Plain AppBar title (e.g. 'Collections History'). Ignored if
  /// [titleWidget] is supplied. When [subtitle] is also given, both are
  /// rendered as a two-line title (matches the Deposit/Petty Cash style).
  final String? title;
  final String? subtitle;

  /// Fully custom title widget (e.g. [LockerAppBarTitle] on the
  /// dashboards) — overrides [title]/[subtitle] when supplied.
  final Widget? titleWidget;

  /// Extra AppBar actions (e.g. a refresh button), rendered to the right.
  final List<Widget>? actions;

  /// White date chips that straddle the yellow header bottom edge —
  /// same pattern as Workshop Owner dashboard ([OwnerAppBar.bottomOverlap]).
  final Widget? bottomOverlap;

  final double appBarHeight;
  final Color backgroundColor;

  /// Whether the signed-in locker user is a supervisor (full sidebar item
  /// set) or a collector (trimmed set). Required so LockerSidebar always
  /// shows the right items, however this particular screen was reached.
  final bool isSupervisor;

  /// Optional pre-resolved display values — pass these when the caller
  /// already knows them (e.g. the dashboards, which load + Arabic-translate
  /// the user's name themselves) to avoid a second session read. Screens
  /// that don't have this handy can leave them null and LockerShell will
  /// resolve a sensible default itself.
  final String? userName;
  final String? roleLabel;

  /// Which sidebar entry represents THIS screen, so LockerSidebar highlights
  /// the right row instead of always highlighting "Dashboard". Leave it at
  /// the default (dashboard) for the dashboard itself or for screens with
  /// no dedicated sidebar entry (e.g. a detail screen reached from a list).
  final LockerSidebarItem currentItem;

  /// Optional FAB (e.g. Petty Cash "New Request").
  final Widget? floatingActionButton;

  /// Force a back arrow instead of the hamburger. When null, derived from
  /// the current route via [openedWithBack] (set by [pushWithBack]).
  final bool? showBackButton;

  /// Route argument marker used by [pushWithBack] / [openedWithBack].
  static const Object _showBackRouteArg = Object();

  /// Whether this route was opened via [pushWithBack] (dashboard → screen).
  static bool openedWithBack(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments == _showBackRouteArg;
  }

  /// Push a locker screen and show a back arrow on its AppBar (instead of
  /// the hamburger). Use for dashboard Quick Actions and "View All".
  /// Drawer navigation should keep using plain [Navigator.push].
  static Future<T?> pushWithBack<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(arguments: _showBackRouteArg),
        builder: (_) => page,
      ),
    );
  }

  const LockerShell({
    super.key,
    required this.body,
    required this.isSupervisor,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.bottomOverlap,
    this.appBarHeight = 72,
    this.backgroundColor = OwnerUi.scaffoldBackground,
    this.userName,
    this.roleLabel,
    this.currentItem = LockerSidebarItem.dashboard,
    this.floatingActionButton,
    this.showBackButton,
  });

  @override
  State<LockerShell> createState() => _LockerShellState();
}

class _LockerShellState extends State<LockerShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SessionService _sessionService = SessionService();

  String? _resolvedUserName;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    if (widget.userName == null) {
      _resolveUserName();
    }
  }

  Future<void> _resolveUserName() async {
    _resolving = true;
    try {
      final user = await _sessionService.getUser(role: 'locker');
      if (!mounted) return;
      setState(() => _resolvedUserName = user?.name);
    } catch (_) {
      // Non-fatal — the sidebar header just falls back to the default
      // "User" label; every other part of the screen still works.
    } finally {
      _resolving = false;
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.ownerShellLogoutTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.ownerShellLogoutBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        l10n.ownerShellLogoutCancel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        l10n.ownerShellLogoutConfirm,
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await _sessionService.clearSession(role: 'locker');
      await _sessionService.saveLastPortal('');
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MenuView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userName ?? _resolvedUserName;
    final roleLabel = widget.roleLabel ??
        localizedLockerUserType(
          context,
          widget.isSupervisor ? 'supervisor' : 'collector',
        );

    // Never pass a raw String into OwnerAppBar — that enables the owner
    // branch picker. Locker always uses a plain title (no branch sheet).
    // Subtitles under the app-bar title are intentionally omitted.
    final Widget resolvedTitle = widget.titleWidget ??
        Text(
          (widget.title ?? '').toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        );

    final showBack =
        widget.showBackButton ?? LockerShell.openedWithBack(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.backgroundColor,
      appBar: OwnerAppBar(
        title: resolvedTitle,
        height: widget.appBarHeight,
        showDrawer: !showBack,
        showBackButton: showBack,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        actions: widget.actions,
        bottomOverlap: widget.bottomOverlap,
      ),
      drawer: LockerSidebar(
        userName: displayName,
        roleLabel: roleLabel,
        isSupervisor: widget.isSupervisor,
        currentItem: widget.currentItem,
        onLogoutTap: () => _confirmLogout(context),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}