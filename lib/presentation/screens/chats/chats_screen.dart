import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_badge.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  String _filter = "";

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      _notificationService.init(auth.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showConversationOptions(BuildContext context, ConversationModel conv, String currentUserId) {
    final isPinned = conv.pinnedBy.contains(currentUserId);
    final isMuted = conv.mutedBy.contains(currentUserId);
    final isMarkedUnread = conv.markedUnreadBy.contains(currentUserId);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
                title: Text(isPinned ? "Unpin Conversation" : "Pin Conversation"),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.togglePinConversation(conv.id, currentUserId, isPinned);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text("Archive Conversation"),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.toggleArchiveConversation(conv.id, currentUserId, false);
                },
              ),
              ListTile(
                leading: Icon(isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined),
                title: Text(isMuted ? "Unmute Notifications" : "Mute Notifications"),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.toggleMuteConversation(conv.id, currentUserId, isMuted);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mark_chat_unread_outlined),
                title: Text(isMarkedUnread ? "Mark as Read" : "Mark as Unread"),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.toggleMarkUnreadConversation(conv.id, currentUserId, isMarkedUnread);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all_rounded),
                title: const Text("Clear Chat Messages"),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.clearChat(conv.id, currentUserId);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text("Delete Conversation", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.deleteConversation(conv.id, currentUserId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Whisper",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Open in-page search or focus
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'new_group') {
                Navigator.pushNamed(context, AppRoutes.createGroup);
              } else if (value == 'archived') {
                Navigator.pushNamed(context, AppRoutes.archivedChats);
              } else if (value == 'profile') {
                Navigator.pushNamed(context, AppRoutes.profile);
              } else if (value == 'settings') {
                Navigator.pushNamed(context, AppRoutes.settings);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add_outlined, size: 20),
                    SizedBox(width: 12),
                    Text("New Group"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20),
                    SizedBox(width: 12),
                    Text("Archived Chats"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20),
                    SizedBox(width: 12),
                    Text("My Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text("Settings"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.contacts),
        child: const Icon(Icons.chat_rounded),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search conversations...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = "");
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Conversation List Stream
          Expanded(
            child: StreamBuilder<List<ConversationModel>>(
              stream: chatProvider.getConversations(currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 64, color: Theme.of(context).dividerColor),
                        const SizedBox(height: 16),
                        const Text(
                          "No conversations yet",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap the chat button below to start a conversation.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter out archived conversations
                final activeConversations = snapshot.data!.where((conv) {
                  return !conv.archivedBy.contains(currentUser.id);
                }).toList();

                // Apply search filter
                final filtered = activeConversations.where((conv) {
                  if (_filter.isEmpty) return true;
                  if (conv.type == ConversationType.group) {
                    return (conv.groupName ?? "").toLowerCase().contains(_filter);
                  } else {
                    final otherName = conv.participantNames.entries
                        .firstWhere((e) => e.key != currentUser.id,
                            orElse: () => const MapEntry("", "User"))
                        .value;
                    return otherName.toLowerCase().contains(_filter) ||
                        conv.lastMessage.toLowerCase().contains(_filter);
                  }
                }).toList();

                // Sort: Pinned first, then by timestamp
                filtered.sort((a, b) {
                  final aPinned = a.pinnedBy.contains(currentUser.id);
                  final bPinned = b.pinnedBy.contains(currentUser.id);
                  if (aPinned && !bPinned) return -1;
                  if (!aPinned && bPinned) return 1;
                  return b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp);
                });

                if (filtered.isEmpty) {
                  return const Center(child: Text("No conversations found matching search."));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const Divider(indent: 74, height: 1),
                  itemBuilder: (context, index) {
                    final conv = filtered[index];
                    final isGroup = conv.type == ConversationType.group;
                    final isPinned = conv.pinnedBy.contains(currentUser.id);
                    final isMuted = conv.mutedBy.contains(currentUser.id);

                    // Name & Avatar
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

                    final unreadCount = conv.unreadCounts[currentUser.id] ?? 0;
                    final isMarkedUnread = conv.markedUnreadBy.contains(currentUser.id);
                    final isTyping = conv.typingUserIds.any((id) => id != currentUser.id);

                    return ListTile(
                      onTap: () {
                        if (isGroup) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.groupChat,
                            arguments: {'conversation': conv},
                          );
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
                      onLongPress: () => _showConversationOptions(context, conv, currentUser.id),
                      leading: AvatarBadge(
                        name: displayName,
                        radius: 26,
                        isGroup: isGroup,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          if (isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.push_pin_rounded,
                                  size: 14, color: Theme.of(context).primaryColor),
                            ),
                          if (isMuted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.volume_off_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          Text(
                            DateFormatter.formatConversationDate(conv.lastMessageTimestamp),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: unreadCount > 0
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: isTyping
                                  ? Text(
                                      "typing...",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : Text(
                                      conv.lastMessage.isNotEmpty
                                          ? conv.lastMessage
                                          : "No messages yet",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: unreadCount > 0
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontWeight:
                                            unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$unreadCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isMarkedUnread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
