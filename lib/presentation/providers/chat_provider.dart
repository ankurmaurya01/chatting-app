import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  MessageReply? _replyingTo;
  MessageModel? _editingMessage;
  bool _isSearching = false;
  String _searchQuery = "";
  DateTime? _searchDate;
  List<MessageModel> _searchResults = [];
  Timer? _typingDebounce;

  MessageReply? get replyingTo => _replyingTo;
  MessageModel? get editingMessage => _editingMessage;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  DateTime? get searchDate => _searchDate;
  List<MessageModel> get searchResults => _searchResults;

  void setReplyTo(MessageModel? message) {
    if (message == null) {
      _replyingTo = null;
    } else {
      _replyingTo = MessageReply(
        messageId: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        text: message.text,
      );
    }
    notifyListeners();
  }

  void setEditingMessage(MessageModel? message) {
    _editingMessage = message;
    notifyListeners();
  }

  void cancelReplyOrEdit() {
    _replyingTo = null;
    _editingMessage = null;
    notifyListeners();
  }

  // Conversation Stream
  Stream<List<ConversationModel>> getConversations(String userId) {
    return _chatService.getConversationsStream(userId);
  }

  // Messages Stream
  Stream<List<MessageModel>> getMessages(String conversationId, String currentUserId) {
    return _chatService.getMessagesStream(conversationId, currentUserId);
  }

  // Send Message
  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    int disappearingSeconds = 0,
  }) async {
    if (text.trim().isEmpty) return;

    if (_editingMessage != null) {
      await _chatService.editMessage(
        conversationId: conversationId,
        messageId: _editingMessage!.id,
        newPlainText: text,
      );
      _editingMessage = null;
    } else {
      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        plainText: text,
        replyTo: _replyingTo,
        disappearingSeconds: disappearingSeconds,
      );
      _replyingTo = null;
    }
    notifyListeners();
  }

  // Forward Message
  Future<void> forwardMessage({
    required String targetConversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _chatService.sendMessage(
      conversationId: targetConversationId,
      senderId: senderId,
      senderName: senderName,
      plainText: text,
      isForwarded: true,
    );
  }

  // Message Actions
  Future<void> deleteForEveryone(String convId, String msgId) async {
    await _chatService.deleteMessageForEveryone(conversationId: convId, messageId: msgId);
  }

  Future<void> deleteForMe(String convId, String msgId, String userId) async {
    await _chatService.deleteMessageForMe(conversationId: convId, messageId: msgId, currentUserId: userId);
  }

  Future<void> togglePin(String convId, String msgId, bool current) async {
    await _chatService.togglePinMessage(conversationId: convId, messageId: msgId, currentPinnedStatus: current);
  }

  Future<void> toggleStar(String convId, String msgId, String userId, bool current) async {
    await _chatService.toggleStarMessage(
      conversationId: convId,
      messageId: msgId,
      currentUserId: userId,
      isCurrentlyStarred: current,
    );
  }

  Future<void> toggleReaction(String convId, String msgId, String userId, String emoji) async {
    await _chatService.toggleReaction(
      conversationId: convId,
      messageId: msgId,
      currentUserId: userId,
      emoji: emoji,
    );
  }

  // Read Receipts & Typing
  Future<void> markRead(String convId, String userId) async {
    await _chatService.markMessagesAsRead(conversationId: convId, currentUserId: userId);
  }

  void onUserTyping(String convId, String userId) {
    _chatService.setTypingStatus(conversationId: convId, currentUserId: userId, isTyping: true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _chatService.setTypingStatus(conversationId: convId, currentUserId: userId, isTyping: false);
    });
  }

  // Search Messages
  Future<void> searchInConversation(String convId, String query, {DateTime? date}) async {
    _isSearching = true;
    _searchQuery = query;
    _searchDate = date;
    notifyListeners();

    _searchResults = await _chatService.searchMessages(
      conversationId: convId,
      query: query,
      searchDate: date,
    );

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = "";
    _searchDate = null;
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    super.dispose();
  }
}
