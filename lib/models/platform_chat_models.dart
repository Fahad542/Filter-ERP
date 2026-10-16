class PlatformChatContact {
  PlatformChatContact({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.category,
    required this.entityName,
    this.workshopId,
    this.branchName,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final String category;
  final String entityName;
  final String? workshopId;
  final String? branchName;

  factory PlatformChatContact.fromJson(Map<String, dynamic> json) {
    return PlatformChatContact(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      entityName: json['entityName']?.toString() ?? '',
      workshopId: json['workshopId']?.toString(),
      branchName: json['branchName']?.toString(),
    );
  }
}

class PlatformChatConversation {
  PlatformChatConversation({
    required this.id,
    required this.type,
    required this.title,
    this.name,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String type;
  final String title;
  final String? name;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get isGroup => type == 'group';

  factory PlatformChatConversation.fromJson(
    Map<String, dynamic> json, {
    int unreadCount = 0,
  }) {
    return PlatformChatConversation(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'direct',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Chat',
      name: json['name']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: _parseDate(json['lastMessageAt']),
      unreadCount: unreadCount,
    );
  }

  PlatformChatConversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return PlatformChatConversation(
      id: id,
      type: type,
      title: title,
      name: name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class PlatformChatMessage {
  PlatformChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.senderRole,
    this.fileUrl,
    this.isSelf = false,
    this.receiptStatus,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final String type;
  final DateTime? createdAt;
  final String? senderRole;
  final String? fileUrl;
  final bool isSelf;
  final String? receiptStatus;

  bool get isVoice => type == 'voice';

  factory PlatformChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderId = json['senderId']?.toString() ?? '';
    final isSelfFlag = json['isSelf'] == true ||
        (currentUserId != null && senderId == currentUserId);
    return PlatformChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: senderId,
      senderName: json['senderName']?.toString() ?? 'User',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      createdAt: _parseDate(json['createdAt']),
      senderRole: json['senderRole']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      isSelf: isSelfFlag,
      receiptStatus: json['receiptStatus']?.toString(),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
