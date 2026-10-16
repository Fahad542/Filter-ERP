import 'package:flutter/widgets.dart';

import '../../../data/repositories/platform_chat_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/platform_chat_models.dart';
import '../../../services/realtime_service.dart';
import '../../../services/session_service.dart';

enum TechNewChatMode { closed, menu, direct, group }

class TechPlatformChatViewModel extends ChangeNotifier {
  TechPlatformChatViewModel({
    PlatformChatRepository? repository,
    SessionService? sessionService,
    RealtimeService? realtimeService,
  })  : _repository = repository ?? PlatformChatRepository(),
        _sessionService = sessionService ?? SessionService(),
        _realtime = realtimeService ?? RealtimeService();

  final PlatformChatRepository _repository;
  final SessionService _sessionService;
  final RealtimeService _realtime;

  List<PlatformChatConversation> conversations = [];
  List<PlatformChatMessage> messages = [];
  List<PlatformChatContact> contacts = [];
  List<PlatformChatContact> groupMemberPicks = [];

  PlatformChatConversation? activeConversation;
  String? currentUserId;

  bool loadingList = false;
  bool loadingMessages = false;
  bool sending = false;
  bool contactsLoading = false;
  bool creating = false;
  String? error;

  int totalUnread = 0;
  String listSearch = '';
  String membersSearch = '';
  String contactSearch = '';
  String groupName = '';
  TechNewChatMode newChatMode = TechNewChatMode.closed;
  String typingLabel = '';

  List<PlatformChatContact> members = [];
  bool loadingMembers = false;

  void setListSearch(String value) {
    listSearch = value;
    notifyListeners();
  }

  void setMembersSearch(String value) {
    membersSearch = value;
    notifyListeners();
  }

  void setGroupName(String value) {
    groupName = value;
    notifyListeners();
  }

  List<PlatformChatContact> get filteredMembers {
    final q = membersSearch.trim().toLowerCase();
    if (q.isEmpty) return members;
    return members.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.role.toLowerCase().contains(q) ||
          (c.branchName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> loadMembers() async {
    final token = await _token();
    if (token == null) return;
    loadingMembers = true;
    notifyListeners();
    try {
      members = await _repository.listWorkshopContacts(token);
    } catch (e) {
      error = e.toString();
      members = [];
    } finally {
      loadingMembers = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([loadConversations(), loadMembers()]);
  }

  bool _socketBound = false;
  String? _joinedConversationId;

  Future<String?> _token() => _sessionService.getToken(role: 'tech');

  Future<void> refreshUnread() async {
    final token = await _token();
    if (token == null) return;
    try {
      totalUnread = await _repository.getTotalUnread(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadConversations() async {
    final token = await _token();
    if (token == null) return;
    loadingList = true;
    error = null;
    notifyListeners();
    try {
      final user = await _sessionService.getUser(role: 'tech');
      currentUserId = user?.id?.toString();
      await _ensureSocket(token);
      conversations = await _repository.listConversations(token);
      totalUnread = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
    } catch (e) {
      error = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(PlatformChatConversation conv) async {
    activeConversation = conv;
    messages = [];
    typingLabel = '';
    notifyListeners();
    await loadMessages(conv.id);
    final token = await _token();
    if (token != null) {
      try {
        await _repository.ackConversation(token, conv.id);
        final idx = conversations.indexWhere((c) => c.id == conv.id);
        if (idx >= 0) {
          totalUnread -= conversations[idx].unreadCount;
          conversations[idx] = conversations[idx].copyWith(unreadCount: 0);
        }
        notifyListeners();
      } catch (_) {}
    }
    _joinConversationRoom(conv.id);
  }

  void closeThread() {
    activeConversation = null;
    messages = [];
    typingLabel = '';
    _joinedConversationId = null;
    notifyListeners();
  }

  Future<void> _ensureCurrentUserId() async {
    if (currentUserId != null && currentUserId!.isNotEmpty) return;
    final user = await _sessionService.getUser(role: 'tech');
    currentUserId = user?.id?.toString();
  }

  Future<void> loadMessages(String conversationId) async {
    final token = await _token();
    if (token == null) return;
    await _ensureCurrentUserId();
    loadingMessages = true;
    error = null;
    notifyListeners();
    try {
      messages = await _repository.fetchMessages(
        token,
        conversationId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    final conv = activeConversation;
    if (trimmed.isEmpty || conv == null || sending) return;
    final token = await _token();
    if (token == null) return;
    await _ensureCurrentUserId();
    sending = true;
    notifyListeners();
    try {
      final msg = await _repository.sendMessage(
        token,
        conv.id,
        content: trimmed,
        currentUserId: currentUserId,
      );
      if (msg != null) {
        _appendMessageIfNew(msg);
        _bumpConversationPreview(conv.id, trimmed, msg.createdAt);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void openGroupBuilder() {
    newChatMode = TechNewChatMode.group;
    groupMemberPicks = [];
    groupName = '';
    contactSearch = '';
    loadGroupContacts();
    notifyListeners();
  }

  void closeNewChat() {
    newChatMode = TechNewChatMode.closed;
    contactSearch = '';
    groupName = '';
    groupMemberPicks = [];
    contacts = [];
    notifyListeners();
  }

  Future<void> loadContacts({String? query}) async {
    final token = await _token();
    if (token == null) return;
    contactsLoading = true;
    notifyListeners();
    try {
      contacts = await _repository.listWorkshopContacts(
        token,
        query: query ?? contactSearch,
      );
    } catch (e) {
      error = e.toString();
      contacts = [];
    } finally {
      contactsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupContacts({String? query}) async {
    final token = await _token();
    if (token == null) return;
    contactsLoading = true;
    notifyListeners();
    try {
      contacts = await _repository.searchGroupContacts(
        token,
        query: query ?? contactSearch,
      );
    } catch (e) {
      error = e.toString();
      contacts = [];
    } finally {
      contactsLoading = false;
      notifyListeners();
    }
  }

  Future<void> startDirectChat(PlatformChatContact contact) async {
    if (creating) return;
    final token = await _token();
    if (token == null) return;
    creating = true;
    error = null;
    notifyListeners();
    try {
      final conv = await _repository.createDirectChat(token, contact.userId);
      closeNewChat();
      if (conv != null) {
        await loadConversations();
        await openConversation(conv);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      creating = false;
      notifyListeners();
    }
  }

  void toggleGroupMember(PlatformChatContact contact) {
    final idx = groupMemberPicks.indexWhere((c) => c.userId == contact.userId);
    if (idx >= 0) {
      groupMemberPicks = [...groupMemberPicks]..removeAt(idx);
    } else {
      groupMemberPicks = [...groupMemberPicks, contact];
    }
    notifyListeners();
  }

  AppLocalizations _resolveL10n([BuildContext? context]) {
    if (context != null) {
      final fromContext = AppLocalizations.of(context);
      if (fromContext != null) return fromContext;
    }
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  Future<void> createGroup({BuildContext? context}) async {
    final l10n = _resolveL10n(context);
    final name = groupName.trim();
    if (name.isEmpty) {
      error = l10n.techChatGroupNameRequired;
      notifyListeners();
      return;
    }
    if (groupMemberPicks.isEmpty) {
      error = l10n.techChatSelectMember;
      notifyListeners();
      return;
    }
    if (creating) return;
    final token = await _token();
    if (token == null) return;
    creating = true;
    error = null;
    notifyListeners();
    try {
      final conv = await _repository.createGroupChat(
        token,
        name: name,
        memberUserIds: groupMemberPicks.map((c) => c.userId).toList(),
      );
      closeNewChat();
      if (conv != null) {
        await loadConversations();
        await openConversation(conv);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      creating = false;
      notifyListeners();
    }
  }

  bool _hasChatActivity(PlatformChatConversation c) {
    final preview = c.lastMessage?.trim();
    return preview != null && preview.isNotEmpty;
  }

  List<PlatformChatConversation> get activeConversations =>
      conversations.where(_hasChatActivity).toList();

  List<PlatformChatConversation> get filteredConversations {
    final q = listSearch.trim().toLowerCase();
    final base = activeConversations;
    if (q.isEmpty) return base;
    return base
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            (c.lastMessage ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _ensureSocket(String token) async {
    _realtime.connect(token);
    if (_socketBound) return;
    _socketBound = true;
    _realtime.on(RealtimeService.eventPlatformChatMessage, _onSocketMessage);
    _realtime.on(
      RealtimeService.eventPlatformChatConversationUpdated,
      _onSocketConversationUpdated,
    );
    _realtime.on(
      RealtimeService.eventPlatformChatConversationCreated,
      _onSocketConversationCreated,
    );
    _realtime.on(RealtimeService.eventPlatformChatTyping, _onSocketTyping);
  }

  void _joinConversationRoom(String conversationId) {
    if (_joinedConversationId == conversationId) return;
    _joinedConversationId = conversationId;
    _realtime.joinPlatformChatConversation(conversationId);
  }

  void _onSocketMessage(Map<String, dynamic> payload) {
    final msgMap = payload['message'];
    if (msgMap is! Map) return;
    final convId = payload['conversationId']?.toString() ??
        msgMap['conversationId']?.toString();
    final msg = PlatformChatMessage.fromJson(
      Map<String, dynamic>.from(msgMap),
      currentUserId: currentUserId,
    );
    if (activeConversation?.id == convId) {
      _appendMessageIfNew(msg);
      if (!msg.isSelf) {
        _token().then((token) {
          if (token != null && convId != null) {
            _repository.ackConversation(token, convId);
          }
        });
      }
    } else if (!msg.isSelf && convId != null) {
      final idx = conversations.indexWhere((c) => c.id == convId);
      if (idx >= 0) {
        conversations[idx] = conversations[idx].copyWith(
          lastMessage: msg.isVoice ? '🎤 Voice message' : msg.content,
          lastMessageAt: msg.createdAt,
          unreadCount: conversations[idx].unreadCount + 1,
        );
        totalUnread += 1;
      }
    }
    notifyListeners();
  }

  void _onSocketConversationUpdated(Map<String, dynamic> payload) {
    final convId = payload['conversationId']?.toString();
    if (convId == null) return;
    final idx = conversations.indexWhere((c) => c.id == convId);
    if (idx < 0) {
      loadConversations();
      return;
    }
    conversations[idx] = conversations[idx].copyWith(
      lastMessage: payload['lastMessage']?.toString(),
      lastMessageAt: DateTime.tryParse(payload['lastMessageAt']?.toString() ?? ''),
    );
    conversations.sort((a, b) {
      final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    notifyListeners();
  }

  void _onSocketConversationCreated(Map<String, dynamic> _) {
    loadConversations();
  }

  void _onSocketTyping(Map<String, dynamic> payload) {
    final convId = payload['conversationId']?.toString();
    if (convId != activeConversation?.id) return;
    final typing = payload['typing'] == true;
    final userId = payload['userId']?.toString();
    if (typing && userId != null && userId != currentUserId) {
      typingLabel =
          payload['userName']?.toString() ?? _resolveL10n().techChatTyping;
    } else {
      typingLabel = '';
    }
    notifyListeners();
  }

  void _appendMessageIfNew(PlatformChatMessage msg) {
    if (messages.any((m) => m.id == msg.id)) return;
    messages = [...messages, msg];
  }

  void _bumpConversationPreview(
    String convId,
    String preview,
    DateTime? at,
  ) {
    final idx = conversations.indexWhere((c) => c.id == convId);
    if (idx >= 0) {
      conversations[idx] = conversations[idx].copyWith(
        lastMessage: preview,
        lastMessageAt: at ?? DateTime.now(),
      );
      final item = conversations.removeAt(idx);
      conversations = [item, ...conversations];
    }
  }

  @override
  void dispose() {
    _realtime.off(RealtimeService.eventPlatformChatMessage, _onSocketMessage);
    _realtime.off(
      RealtimeService.eventPlatformChatConversationUpdated,
      _onSocketConversationUpdated,
    );
    _realtime.off(
      RealtimeService.eventPlatformChatConversationCreated,
      _onSocketConversationCreated,
    );
    _realtime.off(RealtimeService.eventPlatformChatTyping, _onSocketTyping);
    super.dispose();
  }
}
