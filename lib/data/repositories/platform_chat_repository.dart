import '../network/api_constants.dart';
import '../network/base_api_service.dart';
import '../../models/platform_chat_models.dart';

class PlatformChatRepository {
  PlatformChatRepository({BaseApiService? apiService})
      : _api = apiService ?? BaseApiService();

  final BaseApiService _api;

  Map<String, String> _auth(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<Map<String, int>> getUnreadSummary(String token) async {
    final res = await _api.get(
      ApiConstants.technicianPlatformChatUnread,
      headers: _auth(token),
    );
    final map = res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
    final byConv = map['byConversation'];
    final out = <String, int>{};
    if (byConv is Map) {
      byConv.forEach((k, v) {
        out[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }
    return out;
  }

  Future<int> getTotalUnread(String token) async {
    final res = await _api.get(
      ApiConstants.technicianPlatformChatUnread,
      headers: _auth(token),
    );
    if (res is Map) {
      return int.tryParse(res['total']?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Future<List<PlatformChatConversation>> listConversations(String token) async {
    final unread = await getUnreadSummary(token);
    final res = await _api.get(
      ApiConstants.technicianPlatformChatConversations,
      headers: _auth(token),
    );
    final list = _extractList(res, key: 'conversations');
    return list
        .map((e) => PlatformChatConversation.fromJson(
              Map<String, dynamic>.from(e),
              unreadCount: unread[e['id']?.toString() ?? ''] ?? 0,
            ))
        .toList();
  }

  Future<List<PlatformChatMessage>> fetchMessages(
    String token,
    String conversationId, {
    String? before,
    String? currentUserId,
  }) async {
    final query = <String, String>{
      if (before != null && before.isNotEmpty) 'before': before,
    };
    final res = await _api.getWithQueryParams(
      ApiConstants.technicianPlatformChatMessages(conversationId),
      query,
      token,
    );
    final list = _extractList(res, key: 'messages');
    return list
        .map((e) => PlatformChatMessage.fromJson(
              Map<String, dynamic>.from(e),
              currentUserId: currentUserId,
            ))
        .toList();
  }

  Future<PlatformChatMessage?> sendMessage(
    String token,
    String conversationId, {
    required String content,
    String type = 'text',
    String? fileUrl,
    String? currentUserId,
  }) async {
    final res = await _api.post(
      ApiConstants.technicianPlatformChatMessages(conversationId),
      {
        'content': content,
        'type': type,
        if (fileUrl != null) 'fileUrl': fileUrl,
      },
      headers: _auth(token),
    );
    final msg = _unwrap(res, 'message');
    if (msg == null) return null;
    return PlatformChatMessage.fromJson(
      Map<String, dynamic>.from(msg),
      currentUserId: currentUserId,
    );
  }

  Future<void> ackConversation(
    String token,
    String conversationId, {
    String level = 'read',
  }) async {
    await _api.post(
      ApiConstants.technicianPlatformChatAck(conversationId),
      {'level': level},
      headers: _auth(token),
    );
  }

  Future<PlatformChatConversation?> createDirectChat(
    String token,
    String otherUserId,
  ) async {
    final res = await _api.post(
      ApiConstants.technicianPlatformChatConversations,
      {
        'type': 'direct',
        'memberUserIds': [otherUserId],
      },
      headers: _auth(token),
    );
    final conv = _unwrap(res, 'conversation');
    if (conv == null) return null;
    return PlatformChatConversation.fromJson(Map<String, dynamic>.from(conv));
  }

  Future<PlatformChatConversation?> createGroupChat(
    String token, {
    required String name,
    required List<String> memberUserIds,
  }) async {
    final res = await _api.post(
      ApiConstants.technicianPlatformChatConversations,
      {
        'type': 'group',
        'name': name,
        'memberUserIds': memberUserIds,
      },
      headers: _auth(token),
    );
    final conv = _unwrap(res, 'conversation');
    if (conv == null) return null;
    return PlatformChatConversation.fromJson(Map<String, dynamic>.from(conv));
  }

  Future<List<PlatformChatContact>> listWorkshopContacts(
    String token, {
    String? query,
    String? role,
  }) async {
    final params = <String, String>{'category': 'workshop'};
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (role != null && role.isNotEmpty && role != 'all') params['role'] = role;
    final res = await _api.getWithQueryParams(
      ApiConstants.technicianPlatformChatContacts,
      params,
      token,
    );
    final list = _extractList(res, key: 'contacts');
    return list
        .map((e) => PlatformChatContact.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<PlatformChatContact>> searchGroupContacts(
    String token, {
    String? query,
  }) async {
    final params = <String, String>{'categories': 'workshop'};
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    final res = await _api.getWithQueryParams(
      ApiConstants.technicianPlatformChatContactsSearch,
      params,
      token,
    );
    final list = _extractList(res, key: 'contacts');
    return list
        .map((e) => PlatformChatContact.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<dynamic> _extractList(dynamic res, {required String key}) {
    if (res is List) return res;
    if (res is Map) {
      final inner = res[key] ?? res['data']?[key] ?? res['list'];
      if (inner is List) return inner;
    }
    return [];
  }

  Map<String, dynamic>? _unwrap(dynamic res, String key) {
    if (res is! Map) return null;
    final map = Map<String, dynamic>.from(res);
    final direct = map[key];
    if (direct is Map) return Map<String, dynamic>.from(direct);
    final nested = map['data'];
    if (nested is Map && nested[key] is Map) {
      return Map<String, dynamic>.from(nested[key] as Map);
    }
    return null;
  }
}
