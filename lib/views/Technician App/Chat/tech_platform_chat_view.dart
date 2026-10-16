import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/global_locale_toolbar_icon.dart';
import '../../../widgets/notification_toolbar_icon.dart';
import '../../../models/platform_chat_models.dart';
import '../Notifications/notifications_view.dart';
import 'tech_platform_chat_view_model.dart';
import 'widgets/platform_chat_widgets.dart';

/// Workshop team chat — technician app styling with My Chats + Members tabs.
class TechPlatformChatView extends StatefulWidget {
  const TechPlatformChatView({super.key, this.embeddedInShell = false});

  /// When true, header uses hamburger + opens parent [Scaffold] drawer.
  final bool embeddedInShell;

  @override
  State<TechPlatformChatView> createState() => _TechPlatformChatViewState();
}

class _TechPlatformChatViewState extends State<TechPlatformChatView>
    with SingleTickerProviderStateMixin {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatsSearchController = TextEditingController();
  final _membersSearchController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _groupContactSearchController = TextEditingController();

  late final TabController _tabController;

  static const _chatBg = Color(0xFFF8F9FD);
  static const _threadBg = TechChatThreadBackground.fallbackColor;
  static const _composerBg = Color(0xFFF0F2F5);
  static const _outBubble = Color(0xFFFFF8E1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chatsSearchController.addListener(() => setState(() {}));
    _membersSearchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechPlatformChatViewModel>().refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _composerController.dispose();
    _scrollController.dispose();
    _chatsSearchController.dispose();
    _membersSearchController.dispose();
    _groupNameController.dispose();
    _groupContactSearchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TechPlatformChatViewModel>(
      builder: (context, vm, _) {
        if (vm.activeConversation != null) {
          return _buildThread(context, vm);
        }
        return _buildMain(context, vm);
      },
    );
  }

  Widget _buildMain(BuildContext context, TechPlatformChatViewModel vm) {
    return Scaffold(
      backgroundColor: _chatBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewGroupSheet(context, vm),
        backgroundColor: AppColors.secondaryLight,
        foregroundColor: AppColors.primaryLight,
        elevation: 4,
        child: const Icon(Icons.group_add_rounded, size: 26),
      ),
      body: Column(
        children: [
          _buildScreenHeader(
            context,
            title: AppLocalizations.of(context)!.techChatTitle,
            useMenu: widget.embeddedInShell,
            onLeading: widget.embeddedInShell
                ? () => Scaffold.of(context).openDrawer()
                : () => Navigator.of(context).pop(),
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyChatsTab(vm),
                _buildMembersTab(vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewGroupSheet(
    BuildContext context,
    TechPlatformChatViewModel vm,
  ) async {
    vm.openGroupBuilder();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: _GroupBuilderSheet(
              vm: vm,
              groupNameController: _groupNameController,
              contactSearchController: _groupContactSearchController,
              onCreated: () {
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
          ),
        );
      },
    );
    vm.closeNewChat();
    _groupNameController.clear();
    _groupContactSearchController.clear();
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.secondaryLight,
            unselectedLabelColor: AppColors.secondaryLight.withOpacity(0.55),
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: l10n.techChatMyChats),
              Tab(text: l10n.techChatMembers),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyChatsTab(TechPlatformChatViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildSearchBar(
          controller: _chatsSearchController,
          hint: l10n.techChatSearchChats,
          onChanged: vm.setListSearch,
        ),
        if (vm.error != null && vm.error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(vm.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        Expanded(
          child: vm.loadingList
              ? const TechChatListShimmer()
              : vm.filteredConversations.isEmpty
                  ? _emptyState(
                      title: l10n.techChatNoChatsYet,
                      subtitle: l10n.techChatNoChatsHint,
                      customIcon: const TechChatActionIcon(size: 40, color: Colors.black26),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: vm.filteredConversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) =>
                          _conversationTile(vm, vm.filteredConversations[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildMembersTab(TechPlatformChatViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildSearchBar(
          controller: _membersSearchController,
          hint: l10n.techChatSearchMembers,
          onChanged: vm.setMembersSearch,
        ),
        Expanded(
          child: vm.loadingMembers
              ? const TechChatListShimmer()
              : vm.filteredMembers.isEmpty
                  ? _emptyState(
                      icon: Icons.people_outline_rounded,
                      title: l10n.techChatNoMembers,
                      subtitle: l10n.techChatTryDifferentSearch,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: vm.filteredMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) =>
                          _memberTile(vm, vm.filteredMembers[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.black.withOpacity(0.35),
              size: 22,
            ),
            suffixIcon: controller.text.trim().isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black.withOpacity(0.35),
                      size: 20,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required String subtitle,
    IconData? icon,
    Widget? customIcon,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIcon ??
              Icon(icon ?? Icons.chat_bubble_outline_rounded,
                  size: 48, color: Colors.black.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.black.withOpacity(0.45), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _conversationTile(TechPlatformChatViewModel vm, PlatformChatConversation conv) {
    final l10n = AppLocalizations.of(context)!;
    final preview = conv.lastMessage ?? l10n.techChatStartConversation;
    final time = conv.lastMessageAt != null
        ? DateFormat(
            'HH:mm',
            Localizations.localeOf(context).toString(),
          ).format(conv.lastMessageAt!.toLocal())
        : '';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => vm.openConversation(conv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PlatformChatAvatar(title: conv.title, isGroup: conv.isGroup),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (time.isNotEmpty)
                    Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  if (conv.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conv.unreadCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberTile(TechPlatformChatViewModel vm, PlatformChatContact contact) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            PlatformChatAvatar(title: contact.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${contact.role}${contact.branchName != null ? ' · ${contact.branchName}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Material(
              color: AppColors.primaryLight.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: vm.creating ? null : () => vm.startDirectChat(contact),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: TechChatActionIcon(
                    size: 22,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThread(BuildContext context, TechPlatformChatViewModel vm) {
    final conv = vm.activeConversation!;
    _scrollToBottom();
    return Scaffold(
      backgroundColor: _threadBg,
      body: Column(
        children: [
          _buildThreadHeader(
            context,
            title: conv.title,
            isGroup: conv.isGroup,
            subtitle: vm.typingLabel.isNotEmpty
                ? vm.typingLabel
                : (conv.isGroup
                    ? AppLocalizations.of(context)!.techChatGroup
                    : AppLocalizations.of(context)!.techChatWorkshopTeam),
            onBack: vm.closeThread,
          ),
          Expanded(
            child: TechChatThreadBackground(
              child: vm.loadingMessages
                  ? const TechChatThreadShimmer()
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, index) {
                      final msg = vm.messages[index];
                      final showDate = index == 0 ||
                          !_sameDay(msg.createdAt, vm.messages[index - 1].createdAt);
                      return Column(
                        children: [
                          if (showDate && msg.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: _dateChip(msg.createdAt!),
                            ),
                          _messageBubble(msg, conv.isGroup),
                        ],
                      );
                    },
                  ),
            ),
          ),
          Container(
            color: _composerBg,
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.paddingOf(context).bottom),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _composerController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.techChatTypeMessage,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(vm),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: vm.sending ? null : () => _send(vm),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: vm.sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondaryLight,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: AppColors.secondaryLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadHeader(
    BuildContext context, {
    required String title,
    required bool isGroup,
    String? subtitle,
    required VoidCallback onBack,
  }) {
    const headerBodyHeight = 72.0;
    final topPad = MediaQuery.paddingOf(context).top;
    final extraSubtitle = subtitle != null && subtitle.isNotEmpty;

    return SizedBox(
      height: topPad + headerBodyHeight + (extraSubtitle ? 8 : 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.secondaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 2),
            PlatformChatAvatar(title: title, isGroup: isGroup, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (extraSubtitle)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.secondaryLight.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const GlobalLocaleToolbarIcon(inCluster: true),
            const SizedBox(width: 6),
            NotificationToolbarIcon(
              inCluster: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool useMenu,
    required VoidCallback onLeading,
  }) {
    const headerBodyHeight = 88.0;
    final topPad = MediaQuery.paddingOf(context).top;
    final extraSubtitle = subtitle != null && subtitle.isNotEmpty;

    return SizedBox(
      height: topPad + headerBodyHeight + (extraSubtitle ? 10 : 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    if (extraSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.secondaryLight.withOpacity(0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: useMenu ? _menuButton(onLeading) : _backButton(onLeading),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GlobalLocaleToolbarIcon(inCluster: true),
                  const SizedBox(width: 6),
                  NotificationToolbarIcon(
                    inCluster: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _send(TechPlatformChatViewModel vm) {
    final text = _composerController.text;
    _composerController.clear();
    vm.sendText(text);
    _scrollToBottom();
  }

  Widget _messageBubble(PlatformChatMessage msg, bool isGroup) {
    final align = msg.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlign = msg.isSelf ? Alignment.centerRight : Alignment.centerLeft;
    final bg = msg.isSelf ? _outBubble : Colors.white;
    final content = msg.isVoice ? '🎤 Voice message' : msg.content;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: rowAlign,
        child: Column(
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
          if (!msg.isSelf && isGroup)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                msg.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(msg.isSelf ? 12 : 4),
                bottomRight: Radius.circular(msg.isSelf ? 4 : 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(content, style: const TextStyle(fontSize: 15, height: 1.35)),
                const SizedBox(height: 2),
                Text(
                  msg.createdAt != null
                      ? DateFormat(
                          'HH:mm',
                          Localizations.localeOf(context).toString(),
                        ).format(msg.createdAt!.toLocal())
                      : '',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(DateTime date) {
    final label = DateFormat(
      'd MMM yyyy',
      Localizations.localeOf(context).toString(),
    ).format(date.toLocal());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _GroupBuilderSheet extends StatelessWidget {
  const _GroupBuilderSheet({
    required this.vm,
    required this.groupNameController,
    required this.contactSearchController,
    required this.onCreated,
  });

  final TechPlatformChatViewModel vm;
  final TextEditingController groupNameController;
  final TextEditingController contactSearchController;
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.techChatNewGroup,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: groupNameController,
            onChanged: vm.setGroupName,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.techChatGroupName,
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (vm.groupMemberPicks.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: vm.groupMemberPicks
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(c.name, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => vm.toggleGroupMember(c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: contactSearchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.techChatSearchMembersToAdd,
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              vm.contactSearch = v;
              vm.loadGroupContacts(query: v);
            },
          ),
        ),
        Expanded(
          child: vm.contactsLoading
              ? const TechChatListShimmer(itemCount: 5)
              : ListView.builder(
                  itemCount: vm.contacts.length,
                  itemBuilder: (context, index) {
                    final c = vm.contacts[index];
                    final selected = vm.groupMemberPicks.any((m) => m.userId == c.userId);
                    return ListTile(
                      onTap: () => vm.toggleGroupMember(c),
                      leading: PlatformChatAvatar(title: c.name),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(c.role),
                      trailing: Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected ? AppColors.primaryLight : Colors.grey,
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.creating
                  ? null
                  : () async {
                      await vm.createGroup(context: context);
                      if (vm.activeConversation != null) onCreated();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.secondaryLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                vm.creating
                    ? AppLocalizations.of(context)!.techChatCreating
                    : AppLocalizations.of(context)!.techChatCreateGroup,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
