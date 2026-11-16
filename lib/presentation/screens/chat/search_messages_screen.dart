import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class SearchMessagesScreen extends StatefulWidget {
  final String conversationId;

  const SearchMessagesScreen({super.key, required this.conversationId});

  @override
  State<SearchMessagesScreen> createState() => _SearchMessagesScreenState();
}

class _SearchMessagesScreenState extends State<SearchMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.searchInConversation(
      widget.conversationId,
      _searchController.text.trim(),
      date: _selectedDate,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: "Filter Messages by Date",
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _onSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.currentUser?.id ?? "";

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _onSearch(),
          onChanged: (_) => _onSearch(),
          decoration: InputDecoration(
            hintText: "Search messages...",
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch();
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: _selectedDate != null ? Theme.of(context).primaryColor : null,
            ),
            tooltip: "Filter by Date",
            onPressed: _pickDate,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.event_busy_rounded),
              tooltip: "Clear Date Filter",
              onPressed: () {
                setState(() => _selectedDate = null);
                _onSearch();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Filtered by date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chat.isSearching
                ? const Center(child: CircularProgressIndicator())
                : chat.searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty && _selectedDate == null
                              ? "Type a query or pick a date to search"
                              : "No messages found matching criteria",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: chat.searchResults.length,
                        separatorBuilder: (ctx, idx) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final msg = chat.searchResults[index];
                          final isMe = msg.senderId == currentUserId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                              child: Text(
                                isMe ? "Me" : msg.senderName.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            title: Text(
                              msg.text,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "${isMe ? "You" : msg.senderName} • ${DateFormatter.formatChatDateHeader(msg.timestamp)} at ${DateFormatter.formatMessageTime(msg.timestamp)}",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
