import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/message_input_bar.dart';
import '../../widgets/reaction_picker_sheet.dart';

class GroupChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const GroupChatScreen({super.key, required this.conversation});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  bool _isEmojiPickerVisible = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      _chatService.markMessagesAsRead(
        conversationId: widget.conversation.id,
        currentUserId: auth.currentUser!.id,
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    chat.sendTextMessage(
      conversationId: widget.conversation.id,
      senderId: currentUser.id,
      senderName: currentUser.fullName,
      text: text,
      disappearingSeconds: widget.conversation.disappearingDurationSeconds,
    );

    _inputController.clear();
    setState(() => _isEmojiPickerVisible = false);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: AvatarBadge(
                    name: widget.conversation.groupName ?? "Group",
                    radius: 36,
                    isGroup: true,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.conversation.groupName ?? "Group",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if ((widget.conversation.groupDescription ?? "").isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      widget.conversation.groupDescription!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  "MEMBERS (${widget.conversation.participantIds.length})",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: widget.conversation.participantNames.entries.map((entry) {
                      final isAdmin = widget.conversation.groupAdminIds.contains(entry.key);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AvatarBadge(name: entry.value, radius: 20),
                        title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                        trailing: isAdmin
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "Admin",
                                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupName = widget.conversation.groupName ?? "Group Chat";

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _showGroupInfo,
          child: Row(
            children: [
              AvatarBadge(name: groupName, radius: 20, isGroup: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${widget.conversation.participantIds.length} members",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      body: Container(
        color: themeProvider.chatWallpaperColor,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatProvider.getMessages(widget.conversation.id, currentUser.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        "No messages in this group yet.",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser.id;

                      return ChatBubble(
                        message: message,
                        isMe: isMe,
                        currentUserId: currentUser.id,
                        onSwipeReply: () => chatProvider.setReplyTo(message),
                        onLongPress: () {
                          MessageActionSheet.show(
                            context: context,
                            message: message,
                            isMe: isMe,
                            currentUserId: currentUser.id,
                            onReactionSelected: (emoji) {
                              chatProvider.toggleReaction(
                                widget.conversation.id,
                                message.id,
                                currentUser.id,
                                emoji,
                              );
                            },
                            onReply: () => chatProvider.setReplyTo(message),
                            onForward: () {},
                            onTogglePin: () {
                              chatProvider.togglePin(widget.conversation.id, message.id, message.isPinned);
                            },
                            onToggleStar: () {
                              chatProvider.toggleStar(
                                widget.conversation.id,
                                message.id,
                                currentUser.id,
                                message.starredByUsers.contains(currentUser.id),
                              );
                            },
                            onEdit: () {
                              chatProvider.setEditingMessage(message);
                              _inputController.text = message.text;
                              _focusNode.requestFocus();
                            },
                            onDeleteForMe: () {
                              chatProvider.deleteForMe(widget.conversation.id, message.id, currentUser.id);
                            },
                            onDeleteForEveryone: () {
                              chatProvider.deleteForEveryone(widget.conversation.id, message.id);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            MessageInputBar(
              controller: _inputController,
              focusNode: _focusNode,
              replyingTo: chatProvider.replyingTo,
              editingMessage: chatProvider.editingMessage,
              onCancelReplyOrEdit: () {
                chatProvider.cancelReplyOrEdit();
                _inputController.clear();
              },
              onSendMessage: _onSendMessage,
              isEmojiVisible: _isEmojiPickerVisible,
              onToggleEmoji: () {
                if (_isEmojiPickerVisible) {
                  setState(() => _isEmojiPickerVisible = false);
                  _focusNode.requestFocus();
                } else {
                  _focusNode.unfocus();
                  setState(() => _isEmojiPickerVisible = true);
                }
              },
              onChanged: (val) {
                chatProvider.onUserTyping(widget.conversation.id, currentUser.id);
              },
            ),
            if (_isEmojiPickerVisible)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  textEditingController: _inputController,
                  config: const Config(height: 250, checkPlatformCompatibility: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
