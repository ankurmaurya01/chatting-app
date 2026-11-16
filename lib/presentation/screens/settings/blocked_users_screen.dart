import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/privacy_provider.dart';
import '../../widgets/avatar_badge.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final privacy = Provider.of<PrivacyProvider>(context);
    final userService = UserService();
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Contacts")),
      body: StreamBuilder<List<String>>(
        stream: privacy.getBlockedUsersStream(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final blockedIds = snapshot.data ?? [];

          if (blockedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block_rounded, size: 56, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 16),
                  const Text("No blocked contacts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    "Contacts you block will appear here.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: blockedIds.length,
            separatorBuilder: (ctx, idx) => const Divider(indent: 74, height: 1),
            itemBuilder: (context, index) {
              final blockedId = blockedIds[index];

              return FutureBuilder(
                future: userService.getUserById(blockedId),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  final name = user?.fullName ?? "Blocked Contact";
                  final username = user?.username ?? "user";

                  return ListTile(
                    leading: AvatarBadge(name: name, radius: 24),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("@$username"),
                    trailing: TextButton(
                      onPressed: () {
                        privacy.unblockUser(
                          blockerId: currentUser.id,
                          blockedId: blockedId,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$name unblocked")),
                        );
                      },
                      child: const Text("Unblock"),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
