import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  DateTime? _selectedDob;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser!;
    _nameController = TextEditingController(text: user.fullName);
    _bioController = TextEditingController(text: user.bio);
    _selectedDob = user.dob;
    _dobController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(user.dob));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    if (!_isEditing) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _onSave() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = auth.currentUser!;

    if (!_formKey.currentState!.validate()) return;

    final success = await userProvider.updateProfile(
      userId: user.id,
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      dob: _selectedDob!,
    );

    if (success && mounted) {
      await auth.refreshCurrentUser();
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: AvatarBadge(
                    name: user.fullName,
                    radius: 46,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "@${user.username}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                CustomTextField(
                  controller: _nameController,
                  label: "Full Name",
                  readOnly: !_isEditing,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.validateFullName,
                ),
                const SizedBox(height: 16),

                // Bio / Status
                CustomTextField(
                  controller: _bioController,
                  label: "About / Bio",
                  readOnly: !_isEditing,
                  maxLines: 2,
                  prefixIcon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: 16),

                // Date of Birth
                CustomTextField(
                  controller: _dobController,
                  label: "Date of Birth",
                  readOnly: true,
                  onTap: _pickDob,
                  prefixIcon: Icons.calendar_today_outlined,
                  suffixIcon: _isEditing ? const Icon(Icons.arrow_drop_down_rounded) : null,
                  validator: (val) => Validators.validateDob(_selectedDob),
                ),
                const SizedBox(height: 16),

                // Mobile Number (Verified badge)
                CustomTextField(
                  controller: TextEditingController(text: user.mobile),
                  label: "Mobile Number",
                  readOnly: true,
                  prefixIcon: Icons.phone_outlined,
                  suffixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Address
                CustomTextField(
                  controller: TextEditingController(text: user.email),
                  label: "Email Address",
                  readOnly: true,
                  prefixIcon: Icons.mail_outline_rounded,
                  suffixIcon: user.isEmailVerified
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                        )
                      : TextButton(
                          onPressed: () {
                            auth.refreshCurrentUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Verification link sent to email.")),
                            );
                          },
                          child: const Text("Verify", style: TextStyle(fontSize: 12)),
                        ),
                ),
                const SizedBox(height: 32),

                if (_isEditing)
                  CustomButton(
                    text: "Save Changes",
                    onPressed: _onSave,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
