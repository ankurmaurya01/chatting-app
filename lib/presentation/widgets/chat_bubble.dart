import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String currentUserId;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    this.onLongPress,
    this.onSwipeReply,
  });

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 15, color: AppColors.readTick);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 15, color: Colors.white70);
      case MessageStatus.sent:
      default:
        return const Icon(Icons.done_rounded, size: 15, color: Colors.white70);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bubble Background Colors
    final bubbleColor = isMe
        ? themeProvider.bubbleColor
        : (isDark ? AppColors.darkReceivedBubble : AppColors.lightReceivedBubble);

    final textColor = isMe
        ? Colors.white
        : (isDark ? AppColors.darkReceivedBubbleText : AppColors.lightReceivedBubbleText);

    final subTextColor = isMe
        ? Colors.white70
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    final baseFontSize = 15.0 + themeProvider.fontSizeDelta;

    // Bubble BorderRadius
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Dismissible(
      key: Key("reply_${message.id}"),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onSwipeReply?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(Icons.reply_rounded, color: Theme.of(context).primaryColor),
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Message Container
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Forwarded tag
                      if (message.isForwarded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.forward_rounded, size: 13, color: subTextColor),
                              const SizedBox(width: 4),
                              Text(
                                "Forwarded",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sender name for group chats
                      if (!isMe && message.senderName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),

                      // Reply-to quotation banner
                      if (message.replyTo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: isMe ? Colors.white : Theme.of(context).primaryColor,
                                width: 3.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.replyTo!.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                message.replyTo!.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Message Plain Text
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: baseFontSize,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Footer: Pinned, Starred, Edited, Expiration, Timestamp & Status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (message.isPinned) ...[
                            Icon(Icons.push_pin_rounded, size: 12, color: subTextColor),
                            const SizedBox(width: 3),
                          ],
                          if (message.starredByUsers.contains(currentUserId)) ...[
                            const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                            const SizedBox(width: 3),
                          ],
                          if (message.isEdited) ...[
                            Text(
                              "edited",
                              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: subTextColor),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (message.expiresAt != null) ...[
                            Icon(Icons.timer_outlined, size: 12, color: subTextColor),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            DateFormatter.formatMessageTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: subTextColor,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(message.status),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Emoji Reactions Row
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6, left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: message.reactions.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
