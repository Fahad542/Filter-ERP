import 'package:flutter/foundation.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../models/corporate_booking_model.dart';
import '../../../services/realtime_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../l10n/app_localizations_en.dart';

class CorporateBookingViewModel extends ChangeNotifier with TranslatableMixin {
  final PosRepository _repository;
  final SessionService _sessionService;

  CorporateBookingViewModel({
    required PosRepository repository,
    required SessionService sessionService,
  })  : _repository = repository,
        _sessionService = sessionService;

  List<CorporateBooking> _allBookings = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _searchQuery = '';
  final RealtimeService _realtimeService = RealtimeService();
  bool _realtimeBound = false;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasBookings => _allBookings.isNotEmpty;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  Future<void> retranslate() async {
    AppTranslationService.clearCache();
    notifyListeners();
  }

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  String _currentFilter = 'All'; // 'All', 'Pending', 'Approve'
  String get currentFilter => _currentFilter;

  List<CorporateBooking> get _activeBookings => _allBookings
      .where((booking) => !_isCompletedBooking(booking))
      .toList();

  int get filterTabCountAll => _activeBookings.length;

  int get filterTabCountPending =>
      _activeBookings.where(_isPendingBooking).length;

  int get filterTabCountApprove =>
      _activeBookings.where(_isApprovedBooking).length;

  int get filterTabCountCancelled =>
      _activeBookings.where(_isCancelledBooking).length;

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  String _bookingStatusLower(CorporateBooking b) =>
      '${b.statusDisplay} ${b.status} ${b.orderStatus ?? ''}'.toLowerCase();

  bool _isApprovedBooking(CorporateBooking booking) {
    final raw = _bookingStatusLower(booking);
    if (raw.contains('cancelled') ||
        raw.contains('canceled') ||
        raw.contains('rejected')) {
      return false;
    }
    return raw.contains('approved') || raw.contains('in progress');
  }

  bool _isPendingBooking(CorporateBooking booking) {
    final raw = _bookingStatusLower(booking);
    if (raw.contains('cancelled') ||
        raw.contains('canceled') ||
        raw.contains('rejected') ||
        _isApprovedBooking(booking)) {
      return false;
    }
    return raw.contains('waiting approval') ||
        raw.contains('pending') ||
        booking.status.toLowerCase() == 'submitted' ||
        raw.contains('submitted');
  }

  bool _isCancelledBooking(CorporateBooking booking) {
    final raw = _bookingStatusLower(booking);
    return raw.contains('cancelled') ||
        raw.contains('canceled') ||
        raw.contains('rejected');
  }

  bool _matchesSearch(CorporateBooking b, String query) {
    final haystack = [
      b.id,
      b.bookingCode,
      b.vehiclePlate,
      b.vehicleName,
      b.companyName,
      b.department,
      b.branchName,
      b.statusDisplay,
      b.status,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _isCompletedBooking(CorporateBooking booking) {
    final statusRaw =
        '${booking.statusDisplay} ${booking.status} ${booking.orderStatus}'
            .toLowerCase();
    return statusRaw.contains('complete') || statusRaw.contains('invoiced');
  }

  List<CorporateBooking> get filteredBookings {
    final activeBookings = _activeBookings;
    List<CorporateBooking> filtered;

    switch (_currentFilter) {
      case 'Pending':
        filtered = activeBookings.where(_isPendingBooking).toList();
        break;
      case 'Approve':
        filtered = activeBookings.where(_isApprovedBooking).toList();
        break;
      case 'Cancelled':
        filtered = activeBookings.where(_isCancelledBooking).toList();
        break;
      case 'All':
      default:
        filtered = List<CorporateBooking>.from(activeBookings);
        break;
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((b) => _matchesSearch(b, q)).toList();
    }

    filtered.sort((a, b) {
      final bi = int.tryParse(b.id) ?? -1;
      final ai = int.tryParse(a.id) ?? -1;
      if (bi != ai) return bi.compareTo(ai);
      return b.submittedAt.compareTo(a.submittedAt);
    });
    return filtered;
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> fetchCorporateBookings({bool refresh = false}) async {
    if (refresh) {
      _isRefreshing = true;
    } else if (_allBookings.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception(AppLocalizationsEn().posCorporateAuthTokenNotFound);
      }

      final user = await _sessionService.getUser();
      final branchId = (user?.branchId ?? '').trim();

      // Backend scopes to cashier branch when branchId omitted.
      final response = await _repository.getCorporateBookings(
        'all',
        branchId.isNotEmpty ? branchId : null,
        token,
        limit: 50,
        offset: 0,
      );
      _allBookings = response.bookings;
      if (_allBookings.isEmpty && !response.success) {
        _errorMessage = AppLocalizationsEn().posCorporateLoadError;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> bindRealtime() async {
    if (_realtimeBound) return;
    final token = await _sessionService.getToken();
    if (token == null || token.isEmpty) return;
    _realtimeService.connect(token);
    _realtimeService.on(
      RealtimeService.eventCorporateWalkInOrderUpdated,
      _onCorporateWalkInUpdated,
    );
    _realtimeService.on(
      RealtimeService.eventCashierOrdersUpdated,
      _onCashierOrdersUpdated,
    );
    _realtimeService.on(
      RealtimeService.eventCashierCorporateWalkInApproved,
      _onCashierOrdersUpdated,
    );
    _realtimeService.on(
      RealtimeService.eventCashierCorporateWalkInRejected,
      _onCashierOrdersUpdated,
    );
    _realtimeBound = true;
  }

  void unbindRealtime() {
    if (!_realtimeBound) return;
    _realtimeService.off(
      RealtimeService.eventCorporateWalkInOrderUpdated,
      _onCorporateWalkInUpdated,
    );
    _realtimeService.off(
      RealtimeService.eventCashierOrdersUpdated,
      _onCashierOrdersUpdated,
    );
    _realtimeService.off(
      RealtimeService.eventCashierCorporateWalkInApproved,
      _onCashierOrdersUpdated,
    );
    _realtimeService.off(
      RealtimeService.eventCashierCorporateWalkInRejected,
      _onCashierOrdersUpdated,
    );
    _realtimeService.disconnect();
    _realtimeBound = false;
  }

  Future<void> _onCorporateWalkInUpdated(Map<String, dynamic> payload) async {
    final eventName = (payload['event']?.toString() ?? '').trim().toLowerCase();
    if (eventName != 'lines_updated_by_branch') {
      await fetchCorporateBookings(refresh: true);
      return;
    }
    final orderId = (payload['orderId']?.toString() ?? payload['id']?.toString() ?? '').trim();
    if (orderId.isEmpty) {
      await fetchCorporateBookings(refresh: true);
      return;
    }
    await refreshCorporateOrderLines(orderId);
  }

  Future<void> _onCashierOrdersUpdated(Map<String, dynamic> _) async {
    await fetchCorporateBookings(refresh: true);
  }

  Future<void> refreshCorporateOrderLines(String orderId) async {
    try {
      final token = await _sessionService.getToken();
      if (token == null || token.isEmpty) return;
      final updated = await _repository.getCorporateWalkInOrder(orderId, token);
      if (updated == null) return;
      final index = _allBookings.indexWhere((b) => b.id.trim() == orderId.trim());
      if (index == -1) {
        // If list shape differs (booking not currently loaded), keep data fresh.
        await fetchCorporateBookings(refresh: true);
        return;
      }
      _allBookings[index] = updated;
      notifyListeners();
    } catch (_) {
      // Fallback keeps list consistent if detail endpoint is unavailable.
      await fetchCorporateBookings(refresh: true);
    }
  }

  Future<bool> approveBooking(String bookingId) async {
    try {
      final token = await _sessionService.getToken();
      if (token == null) {
         throw Exception(AppLocalizationsEn().posCorporateAuthTokenNotFound);
      }
      final result = await _repository.approveCorporateBooking(bookingId, token);
      if (result.success) {
        final index = _allBookings.indexWhere((b) => b.id.trim() == bookingId.trim());
        if (index != -1) {
          final prev = _allBookings[index];
          _allBookings[index] = prev.copyWith(
            status: 'approved',
            statusDisplay: 'Approved',
            orderStatus: 'in progress',
            orderId: result.salesOrderId ?? prev.orderId,
          );
        }
        notifyListeners();
      }
      return result.success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken();
      if (token == null) {
         throw Exception(AppLocalizationsEn().posCorporateAuthTokenNotFound);
      }
      final success = await _repository.rejectCorporateBooking(bookingId, reason, token);
      if (success) {
        final index = _allBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _allBookings.removeAt(index);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    unbindRealtime();
    super.dispose();
  }
}
