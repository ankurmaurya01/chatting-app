import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_badge.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final chatService = ChatService();
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Archived Chats"),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: chatProvider.getConversations(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final archived = (snapshot.data ?? [])
              .where((conv) => conv.archivedBy.contains(currentUser.id))
              .toList();

          if (archived.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 16),
                  const Text(
                    "No archived chats",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Conversations you archive will appear here.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: archived.length,
            separatorBuilder: (ctx, idx) => const Divider(indent: 74, height: 1),
            itemBuilder: (context, index) {
              final conv = archived[index];
              final isGroup = conv.type == ConversationType.group;

              String displayName;
              String targetUserId = "";
              if (isGroup) {
                displayName = conv.groupName ?? "Group Chat";
              } else {
                final otherEntry = conv.participantNames.entries.firstWhere(
                  (e) => e.key != currentUser.id,
                  orElse: () => const MapEntry("", "Chat"),
                );
                displayName = otherEntry.value;
                targetUserId = otherEntry.key;
              }

              return ListTile(
                onTap: () {
                  if (isGroup) {
                    Navigator.pushNamed(context, AppRoutes.groupChat, arguments: {'conversation': conv});
                  } else {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.privateChat,
                      arguments: {
                        'conversation': conv,
                        'targetUserId': targetUserId,
                        'targetUserName': displayName,
                      },
                    );
                  }
                },
                leading: AvatarBadge(name: displayName, radius: 26, isGroup: isGroup),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  conv.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.unarchive_outlined),
                  tooltip: "Unarchive",
                  onPressed: () {
                    chatService.toggleArchiveConversation(conv.id, currentUser.id, true);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
