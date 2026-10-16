import '../data/network/api_constants.dart';
import '../data/network/base_api_service.dart';

/// Keys returned by [GET /public/mobile-app-menu].
class MobileAppMenuPortalKeys {
  static const superAdmin = 'super_admin';
  static const workshopOwner = 'workshop_owner';
  static const technician = 'technician';
  static const pos = 'pos';
  static const locker = 'locker';
  static const supplier = 'supplier';

  static const all = [
    superAdmin,
    workshopOwner,
    technician,
    pos,
    locker,
    supplier,
  ];
}

class MobileAppMenuPortal {
  const MobileAppMenuPortal({
    required this.key,
    this.titleEn,
    this.titleAr,
    this.sortOrder = 0,
  });

  final String key;
  final String? titleEn;
  final String? titleAr;
  final int sortOrder;

  factory MobileAppMenuPortal.fromJson(Map<dynamic, dynamic> json) {
    return MobileAppMenuPortal(
      key: json['key'] as String,
      titleEn: json['titleEn'] as String?,
      titleAr: json['titleAr'] as String?,
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : 0,
    );
  }
}

class MobileAppMenuService {
  MobileAppMenuService({BaseApiService? api}) : _api = api ?? BaseApiService();

  final BaseApiService _api;

  /// Returns enabled portals in sort order. On failure, empty list (fail-closed).
  Future<List<MobileAppMenuPortal>> fetchEnabledPortals() async {
    try {
      final raw = await BaseApiService.runWithoutUnauthorizedLogout(
        () => _api.get(ApiConstants.publicMobileAppMenuEndpoint),
      );
      if (raw is! Map) return const [];

      final portals = raw['portals'];
      if (portals is! List) return const [];

      final parsed = <MobileAppMenuPortal>[];
      for (final item in portals) {
        if (item is Map && item['key'] is String) {
          parsed.add(MobileAppMenuPortal.fromJson(item));
        }
      }
      return parsed;
    } catch (_) {
      return const [];
    }
  }
}
