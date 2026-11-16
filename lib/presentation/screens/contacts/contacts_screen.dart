import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/avatar_badge.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      Provider.of<UserProvider>(context, listen: false).loadRecentContacts(auth.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startChat(UserModel targetUser) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final conv = await _chatService.getOrCreatePrivateConversation(
      currentUserId: currentUser.id,
      currentUserName: currentUser.fullName,
      targetUserId: targetUser.id,
      targetUserName: targetUser.fullName,
    );

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.privateChat,
        arguments: {
          'conversation': conv,
          'targetUserId': targetUser.id,
          'targetUserName': targetUser.fullName,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSearching = _searchController.text.trim().isNotEmpty;
    final displayList = isSearching ? userProvider.searchResults : userProvider.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Contact"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => userProvider.loadRecentContacts(currentUser.id),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                userProvider.searchUsers(val, currentUser.id);
              },
              decoration: InputDecoration(
                hintText: "Search by username, email or mobile...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          userProvider.clearSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Action Items (New Group)
          if (!isSearching) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                child: Icon(Icons.group_add_rounded, color: Theme.of(context).primaryColor),
              ),
              title: const Text("New Group Chat", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.createGroup);
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "CONTACTS ON WHISPER",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],

          // Contacts List
          Expanded(
            child: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? Center(
                        child: Text(
                          isSearching ? "No contacts found" : "No other users registered yet",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: displayList.length,
                        separatorBuilder: (ctx, idx) => const Divider(indent: 74, height: 1),
                        itemBuilder: (context, index) {
                          final user = displayList[index];
                          return ListTile(
                            onTap: () => _startChat(user),
                            leading: AvatarBadge(
                              name: user.fullName,
                              radius: 24,
                              isOnline: user.isOnline && !user.privacySettings.hideOnline,
                              showOnlineIndicator: !user.privacySettings.hideOnline,
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            subtitle: Text(
                              "@${user.username} • ${user.bio}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
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
