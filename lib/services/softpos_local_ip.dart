import 'dart:io';

bool _isPrivateLanIpv4(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList();
  if (octets.any((o) => o == null || o < 0 || o > 255)) return false;
  final a = octets[0]!;
  final b = octets[1]!;
  if (a == 192 && b == 168) return true;
  if (a == 10) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  return false;
}

bool _isLikelyWifiInterface(String name) {
  final n = name.toLowerCase();
  return n.contains('wlan') ||
      n.contains('wifi') ||
      n == 'en0' ||
      (n.startsWith('en') && !n.contains('pdp'));
}

bool _isLikelyVpnOrMobileInterface(String name) {
  final n = name.toLowerCase();
  return n.contains('rmnet') ||
      n.contains('pdp') ||
      n.contains('ccmni') ||
      n.startsWith('tun') ||
      n.startsWith('tap') ||
      n.contains('vpn') ||
      n.startsWith('utun');
}

/// Prefer Wi‑Fi LAN IPv4 (matches phone Wi‑Fi settings), not mobile data/VPN.
Future<String?> getLocalIpv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    String? wifiPrivate;
    String? anyPrivate;
    String? fallback;

    for (final iface in interfaces) {
      if (_isLikelyVpnOrMobileInterface(iface.name)) continue;
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        final ip = addr.address;
        fallback ??= ip;
        if (!_isPrivateLanIpv4(ip)) continue;
        anyPrivate ??= ip;
        if (_isLikelyWifiInterface(iface.name)) {
          wifiPrivate ??= ip;
        }
      }
    }

    return wifiPrivate ?? anyPrivate ?? fallback;
  } catch (_) {}
  return null;
}
