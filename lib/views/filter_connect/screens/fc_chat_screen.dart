import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../data/fc_mock_data.dart';
import '../widgets/fc_widgets.dart';

class FcChatScreen extends StatefulWidget {
  const FcChatScreen({super.key});

  @override
  State<FcChatScreen> createState() => _FcChatScreenState();
}

class _FcChatScreenState extends State<FcChatScreen> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    if (_open != null) {
      final t = MockData.chats[_open!];
      return Column(
        children: [
          ListTile(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _open = null),
            ),
            title: Text(t.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
            subtitle: const Text('14 members · Linked to CRM'),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MockData.messages.length,
              itemBuilder: (_, i) {
                final m = MockData.messages[i];
                return Align(
                  alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.isMe
                          ? AppColors.primaryLight.withOpacity(0.35)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!m.isMe)
                          Text(m.author, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        Text(m.body, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 4),
                        Text(m.time, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ...List.generate(MockData.chats.length, (i) {
          final t = MockData.chats[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FcCard(
              onTap: () => setState(() => _open = i),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight.withOpacity(0.35),
                    child: Icon(
                      t.isGroup ? Icons.groups_rounded : Icons.person,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(t.preview, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (t.unread > 0)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryLight,
                      child: Text('${t.unread}',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}