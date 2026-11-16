import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final ChatService _chatService = ChatService();
  final Set<String> _selectedUserIds = {};
  final Map<String, String> _selectedUserNames = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _toggleUser(UserModel user) {
    setState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
        _selectedUserNames.remove(user.id);
      } else {
        _selectedUserIds.add(user.id);
        _selectedUserNames[user.id] = user.fullName;
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name.")),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one participant.")),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    setState(() => _isCreating = true);

    try {
      _selectedUserNames[currentUser.id] = currentUser.fullName;

      final groupConv = await _chatService.createGroupConversation(
        groupName: name,
        description: _descController.text.trim(),
        creatorId: currentUser.id,
        creatorName: currentUser.fullName,
        memberIds: _selectedUserIds.toList(),
        memberNames: _selectedUserNames,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.groupChat,
          arguments: {'conversation': groupConv},
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating group: $e")),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: "Group Name",
                    hint: "Enter group topic or name",
                    prefixIcon: Icons.group_rounded,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _descController,
                    label: "Group Description (Optional)",
                    hint: "What is this group about?",
                    prefixIcon: Icons.description_outlined,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "SELECT PARTICIPANTS (${_selectedUserIds.length})",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: userProvider.contacts.length,
                separatorBuilder: (ctx, idx) => const Divider(indent: 74, height: 1),
                itemBuilder: (context, index) {
                  final user = userProvider.contacts[index];
                  final isSelected = _selectedUserIds.contains(user.id);

                  return ListTile(
                    onTap: () => _toggleUser(user),
                    leading: AvatarBadge(name: user.fullName, radius: 24),
                    title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("@${user.username}"),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (val) => _toggleUser(user),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: "Create Group (${_selectedUserIds.length} members)",
                isLoading: _isCreating,
                onPressed: _createGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
