import 'package:intl/intl.dart';

class DateFormatter {
  // Format for chat message bubbles (e.g., 04:30 PM)
  static String formatMessageTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Format for conversations list last message timestamp
  static String formatConversationDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && now.day == dateTime.day) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime); // e.g. Mon, Tue
    } else if (now.year == dateTime.year) {
      return DateFormat('MMM d').format(dateTime); // e.g. Oct 12
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  // Format for chat message date headers (e.g. Today, Yesterday, or October 12, 2026)
  static String formatChatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return "Today";
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    } else if (now.year == dateTime.year) {
      return DateFormat('MMMM d').format(dateTime);
    } else {
      return DateFormat('MMMM d, yyyy').format(dateTime);
    }
  }

  // Format last seen (e.g. "Last seen today at 02:15 PM")
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return "Offline";
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return "Last seen just now";
    } else if (diff.inHours < 1) {
      return "Last seen ${diff.inMinutes}m ago";
    } else if (now.day == lastSeen.day && now.month == lastSeen.month && now.year == lastSeen.year) {
      return "Last seen today at ${DateFormat('hh:mm a').format(lastSeen)}";
    } else if (now.subtract(const Duration(days: 1)).day == lastSeen.day) {
      return "Last seen yesterday at ${DateFormat('hh:mm a').format(lastSeen)}";
    } else {
      return "Last seen ${DateFormat('MMM d, hh:mm a').format(lastSeen)}";
    }
  }
}
