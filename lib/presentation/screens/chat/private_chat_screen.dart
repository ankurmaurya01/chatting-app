import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/privacy_service.dart';
import '../../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/message_input_bar.dart';
import '../../widgets/reaction_picker_sheet.dart';
import '../../widgets/typing_indicator_widget.dart';

class PrivateChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String targetUserId;
  final String targetUserName;

  const PrivateChatScreen({
    super.key,
    required this.conversation,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final PrivacyService _privacyService = PrivacyService();

  bool _isEmojiPickerVisible = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      // Mark unread messages as read
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

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showDisappearingDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text("Disappearing Messages"),
          children: [
            SimpleDialogOption(
              onPressed: () {
                _chatService.setDisappearingDuration(
                  conversationId: widget.conversation.id,
                  seconds: AppConstants.disappearingOff,
                );
                Navigator.pop(ctx);
              },
              child: const Text("Off"),
            ),
            SimpleDialogOption(
              onPressed: () {
                _chatService.setDisappearingDuration(
                  conversationId: widget.conversation.id,
                  seconds: AppConstants.disappearing24Hours,
                );
                Navigator.pop(ctx);
              },
              child: const Text("24 Hours"),
            ),
            SimpleDialogOption(
              onPressed: () {
                _chatService.setDisappearingDuration(
                  conversationId: widget.conversation.id,
                  seconds: AppConstants.disappearing7Days,
                );
                Navigator.pop(ctx);
              },
              child: const Text("7 Days"),
            ),
            SimpleDialogOption(
              onPressed: () {
                _chatService.setDisappearingDuration(
                  conversationId: widget.conversation.id,
                  seconds: AppConstants.disappearing90Days,
                );
                Navigator.pop(ctx);
              },
              child: const Text("90 Days"),
            ),
          ],
        );
      },
    );
  }

  void _showBlockDialog(String currentUserId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Block ${widget.targetUserName}?"),
        content: const Text(
          "Blocked contacts will no longer be able to send you messages or view your presence.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _privacyService.blockUser(
                blockerId: currentUserId,
                blockedId: widget.targetUserId,
                blockedUsername: widget.targetUserName,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${widget.targetUserName} has been blocked.")),
              );
            },
            child: const Text("Block", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String currentUserId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Report ${widget.targetUserName}"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Reason for reporting (spam, abuse, harassment...)",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                _privacyService.reportUser(
                  reporterId: currentUserId,
                  reportedUserId: widget.targetUserId,
                  reason: reason,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Report submitted. Thank you for keeping Whisper safe.")),
                );
              }
            },
            child: const Text("Submit Report", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<UserModel?>(
          stream: _userService.getUserStream(widget.targetUserId),
          builder: (context, userSnap) {
            final targetUser = userSnap.data;
            final isOnline = targetUser?.isOnline ?? false;
            final hideOnline = targetUser?.privacySettings.hideOnline ?? false;
            final hideLastSeen = targetUser?.privacySettings.hideLastSeen ?? false;

            String subtitleText = "Offline";
            if (isOnline && !hideOnline) {
              subtitleText = "Online";
            } else if (!hideLastSeen && targetUser?.lastSeen != null) {
              subtitleText = DateFormatter.formatLastSeen(targetUser!.lastSeen);
            }

            return Row(
              children: [
                AvatarBadge(
                  name: widget.targetUserName,
                  radius: 20,
                  isOnline: isOnline && !hideOnline,
                  showOnlineIndicator: !hideOnline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.targetUserName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: (isOnline && !hideOnline)
                              ? AppColors.online
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.searchMessages,
                arguments: {'conversationId': widget.conversation.id},
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'disappearing') _showDisappearingDialog();
              if (val == 'clear') _chatService.clearChat(widget.conversation.id, currentUser.id);
              if (val == 'mute') _chatService.toggleMuteConversation(widget.conversation.id, currentUser.id, false);
              if (val == 'block') _showBlockDialog(currentUser.id);
              if (val == 'report') _showReportDialog(currentUser.id);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'disappearing', child: Text("Disappearing Messages")),
              const PopupMenuItem(value: 'clear', child: Text("Clear Chat")),
              const PopupMenuItem(value: 'mute', child: Text("Mute Notifications")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'block', child: Text("Block User", style: TextStyle(color: Colors.red))),
              const PopupMenuItem(value: 'report', child: Text("Report User", style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Container(
        color: themeProvider.chatWallpaperColor,
        child: Column(
          children: [
            // Disappearing Messages Notification Banner
            if (widget.conversation.disappearingDurationSeconds > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.amber.withOpacity(0.12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      "Disappearing messages are on (${widget.conversation.disappearingDurationSeconds ~/ 86400}d)",
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // Messages List Stream
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 40, color: Theme.of(context).dividerColor),
                          const SizedBox(height: 12),
                          const Text(
                            "End-to-End Encrypted",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Messages are securely encrypted with AES-256.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
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

                      // Date separator check
                      bool showDateHeader = false;
                      if (index == messages.length - 1) {
                        showDateHeader = true;
                      } else {
                        final nextMessage = messages[index + 1];
                        if (message.timestamp.day != nextMessage.timestamp.day ||
                            message.timestamp.month != nextMessage.timestamp.month ||
                            message.timestamp.year != nextMessage.timestamp.year) {
                          showDateHeader = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateHeader)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor, width: 0.6),
                              ),
                              child: Text(
                                DateFormatter.formatChatDateHeader(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ChatBubble(
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
                                onForward: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Forward feature available from Contacts")),
                                  );
                                },
                                onTogglePin: () {
                                  chatProvider.togglePin(
                                    widget.conversation.id,
                                    message.id,
                                    message.isPinned,
                                  );
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
                                  chatProvider.deleteForMe(
                                    widget.conversation.id,
                                    message.id,
                                    currentUser.id,
                                  );
                                },
                                onDeleteForEveryone: () {
                                  chatProvider.deleteForEveryone(
                                    widget.conversation.id,
                                    message.id,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Typing Indicator
            StreamBuilder<ConversationModel?>(
              stream: _chatService
                  .getConversationsStream(currentUser.id)
                  .map((list) => list.firstWhere((c) => c.id == widget.conversation.id,
                      orElse: () => widget.conversation)),
              builder: (context, snap) {
                final conv = snap.data;
                final isTyping = conv?.typingUserIds.contains(widget.targetUserId) ?? false;
                if (!isTyping) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.centerLeft,
                  child: TypingIndicatorWidget(userName: widget.targetUserName),
                );
              },
            ),

            // Message Input Bar
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

            // Emoji Picker Drawer
            if (_isEmojiPickerVisible)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  textEditingController: _inputController,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
