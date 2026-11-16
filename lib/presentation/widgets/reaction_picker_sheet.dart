import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/message_model.dart';

class MessageActionSheet {
  static void show({
    required BuildContext context,
    required MessageModel message,
    required bool isMe,
    required String currentUserId,
    required Function(String emoji) onReactionSelected,
    required VoidCallback onReply,
    required VoidCallback onForward,
    required VoidCallback onTogglePin,
    required VoidCallback onToggleStar,
    required VoidCallback onEdit,
    required VoidCallback onDeleteForMe,
    required VoidCallback onDeleteForEveryone,
  }) {
    final emojis = ["👍", "❤️", "😂", "😮", "😢", "🙏", "🔥"];
    final isStarred = message.starredByUsers.contains(currentUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Emoji Reaction Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: emojis.map((emoji) {
                      final hasReacted = message.reactions[currentUserId] == emoji;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          onReactionSelected(emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: hasReacted ? theme.primaryColor.withOpacity(0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Action Menu Card
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Reply
                      ListTile(
                        leading: const Icon(Icons.reply_rounded),
                        title: const Text("Reply"),
                        onTap: () {
                          Navigator.pop(ctx);
                          onReply();
                        },
                      ),

                      // Copy
                      ListTile(
                        leading: const Icon(Icons.copy_rounded),
                        title: const Text("Copy Text"),
                        onTap: () {
                          Navigator.pop(ctx);
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Message copied to clipboard")),
                          );
                        },
                      ),

                      // Forward
                      ListTile(
                        leading: const Icon(Icons.forward_rounded),
                        title: const Text("Forward"),
                        onTap: () {
                          Navigator.pop(ctx);
                          onForward();
                        },
                      ),

                      // Star
                      ListTile(
                        leading: Icon(isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isStarred ? Colors.amber : null),
                        title: Text(isStarred ? "Unstar" : "Star"),
                        onTap: () {
                          Navigator.pop(ctx);
                          onToggleStar();
                        },
                      ),

                      // Pin
                      ListTile(
                        leading: Icon(message.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                        title: Text(message.isPinned ? "Unpin" : "Pin"),
                        onTap: () {
                          Navigator.pop(ctx);
                          onTogglePin();
                        },
                      ),

                      // Edit (Sender only)
                      if (isMe && !message.isDeletedForEveryone)
                        ListTile(
                          leading: const Icon(Icons.edit_rounded),
                          title: const Text("Edit Message"),
                          onTap: () {
                            Navigator.pop(ctx);
                            onEdit();
                          },
                        ),

                      const Divider(height: 1),

                      // Delete
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        title: const Text("Delete Message", style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showDeleteDialog(
                            context: context,
                            isMe: isMe,
                            onDeleteForMe: onDeleteForMe,
                            onDeleteForEveryone: onDeleteForEveryone,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showDeleteDialog({
    required BuildContext context,
    required bool isMe,
    required VoidCallback onDeleteForMe,
    required VoidCallback onDeleteForEveryone,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Delete message?"),
          content: Text(
            isMe
                ? "You can delete this message for everyone or delete it just for yourself."
                : "This message will be deleted for you only.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDeleteForMe();
              },
              child: const Text("Delete for Me", style: TextStyle(color: Colors.red)),
            ),
            if (isMe)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDeleteForEveryone();
                },
                child: const Text("Delete for Everyone", style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );
  }
}
