import 'package:flutter/material.dart';
import '../../data/models/message_model.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final MessageReply? replyingTo;
  final MessageModel? editingMessage;
  final VoidCallback onCancelReplyOrEdit;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleEmoji;
  final bool isEmojiVisible;
  final Function(String) onChanged;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.replyingTo,
    this.editingMessage,
    required this.onCancelReplyOrEdit,
    required this.onSendMessage,
    required this.onToggleEmoji,
    required this.isEmojiVisible,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply or Edit Top Preview Banner
            if (replyingTo != null || editingMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.cardColor,
                child: Row(
                  children: [
                    Icon(
                      editingMessage != null ? Icons.edit_rounded : Icons.reply_rounded,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editingMessage != null
                                ? "Editing message"
                                : "Replying to ${replyingTo!.senderName}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editingMessage != null ? editingMessage!.text : replyingTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: onCancelReplyOrEdit,
                    ),
                  ],
                ),
              ),

            // Input Field Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Emoji Toggle Button
                  IconButton(
                    icon: Icon(
                      isEmojiVisible ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: onToggleEmoji,
                  ),

                  // Text Field Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: onChanged,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Action Button
                  GestureDetector(
                    onTap: onSendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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
}
