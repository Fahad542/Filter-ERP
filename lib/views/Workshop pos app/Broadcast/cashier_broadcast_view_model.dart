import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../models/cashier_active_broadcasts_model.dart';
import '../../../services/realtime_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../l10n/app_localizations_en.dart';

class CashierBroadcastViewModel extends ChangeNotifier with TranslatableMixin {
  CashierBroadcastViewModel({
    required this.posRepository,
    required this.sessionService,
  }) {
    _realtime.on(RealtimeService.eventCashierBroadcastUpdated, _onSocketBroadcast);
  }

  final PosRepository posRepository;
  final SessionService sessionService;
  final RealtimeService _realtime = RealtimeService();

  List<CashierActiveBroadcastItem> _broadcasts = [];
  int windowSeconds = 300;
  int soonThresholdSeconds = 60;
  int activeCountMeta = 0;
  bool isLoading = false;
  String? errorMessage;

  Future<void> retranslate() async {
    AppTranslationService.clearCache();
    notifyListeners();
  }

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Timer? _tick;
  Timer? _socketDebounce;
  Timer? _backgroundPoll;

  /// Coalesce overlapping [fetchActive] calls (tab visit + socket debounce).
  Future<void>? _fetchActiveInFlight;

  List<CashierActiveBroadcastItem> get broadcasts => List.unmodifiable(_broadcasts);

  void _onSocketBroadcast(Map<String, dynamic> _) {
    _socketDebounce?.cancel();
    _socketDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchActive(silent: true);
    });
  }

  Future<void> fetchActive({bool silent = false}) {
    if (_fetchActiveInFlight != null) return _fetchActiveInFlight!;
    _fetchActiveInFlight = _fetchActiveImpl(silent: silent)
        .whenComplete(() => _fetchActiveInFlight = null);
    return _fetchActiveInFlight!;
  }

  Future<void> _fetchActiveImpl({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken(role: 'cashier');
      if (token == null) {
        errorMessage = AppLocalizationsEn().posBroadcastSessionExpired;
        return;
      }
      final res = await posRepository.getCashierActiveBroadcasts(token);
      windowSeconds = res.windowSeconds;
      soonThresholdSeconds = res.soonThresholdSeconds;
      activeCountMeta = res.activeCount;
      final now = DateTime.now();
      _broadcasts = res.broadcasts.map((b) {
        if (b.expiresAt == null && b.remainingSeconds > 0) {
          return b.copyWith(expiresAt: now.add(Duration(seconds: b.remainingSeconds)));
        }
        return b;
      }).toList();
      _pruneExpired();
      _syncTicker();
      _syncBackgroundPoll();
    } catch (e) {
      if (!silent) {
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _pruneExpired() {
    final now = DateTime.now();
    _broadcasts.removeWhere((b) {
      final exp = b.expiresAt;
      if (exp != null) return !exp.isAfter(now);
      if (b.remainingSeconds <= 0) return true;
      return false;
    });
  }

  Duration remainingFor(CashierActiveBroadcastItem b) {
    final exp = b.expiresAt;
    if (exp != null) return exp.difference(DateTime.now());
    return Duration(seconds: b.remainingSeconds);
  }

  bool isExpired(CashierActiveBroadcastItem b) => remainingFor(b).isNegative;

  bool showSoon(CashierActiveBroadcastItem b) {
    final r = remainingFor(b);
    if (r.isNegative) return false;
    if (b.serverIsSoon) return true;
    return r.inSeconds <= soonThresholdSeconds;
  }

  double progressRemaining(CashierActiveBroadcastItem b) {
    final max = windowSeconds <= 0 ? 300 : windowSeconds;
    final left = remainingFor(b).inSeconds.clamp(0, max);
    return left / max;
  }

  void _syncTicker() {
    if (_broadcasts.isEmpty) {
      _tick?.cancel();
      _tick = null;
      return;
    }
    if (_tick != null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final before = _broadcasts.length;
      _pruneExpired();
      if (_broadcasts.length != before) {
        _syncBackgroundPoll();
        if (_broadcasts.isEmpty) {
          _tick?.cancel();
          _tick = null;
        }
        notifyListeners();
      }
      // Countdown UI ticks are driven by [PosCashierBroadcastView] local timer to avoid
      // full-tree rebuilds every second (semantics / nested sliver issues).
    });
  }

  void _syncBackgroundPoll() {
    if (_broadcasts.isEmpty) {
      _backgroundPoll?.cancel();
      _backgroundPoll = null;
      return;
    }
    _backgroundPoll ??= Timer.periodic(const Duration(seconds: 45), (_) {
      fetchActive(silent: true);
    });
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    _tick?.cancel();
    _socketDebounce?.cancel();
    _backgroundPoll?.cancel();
    _realtime.off(RealtimeService.eventCashierBroadcastUpdated, _onSocketBroadcast);
    super.dispose();
  }
}
