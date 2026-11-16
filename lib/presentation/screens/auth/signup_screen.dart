import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: "Select your Date of Birth",
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _onSubmit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your date of birth.")),
      );
      return;
    }

    // Trigger Phone OTP dispatch
    final success = await authProvider.sendMobileOtp(_mobileController.text.trim());
    if (success && mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: {
          'username': _usernameController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
          'dob': _selectedDob!,
          'password': _passwordController.text,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Join Whisper",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Enter your information to set up your secure messaging profile.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 24),

                if (authProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Username
                CustomTextField(
                  controller: _usernameController,
                  label: "Username",
                  hint: "unique_handle",
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: Validators.validateUsername,
                ),
                const SizedBox(height: 16),

                // 2. Full Name
                CustomTextField(
                  controller: _fullNameController,
                  label: "Full Name",
                  hint: "John Doe",
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.validateFullName,
                ),
                const SizedBox(height: 16),

                // 3. Mobile Number
                CustomTextField(
                  controller: _mobileController,
                  label: "Mobile Number",
                  hint: "+1234567890",
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.validateMobile,
                ),
                const SizedBox(height: 16),

                // 4. Email Address
                CustomTextField(
                  controller: _emailController,
                  label: "Email Address",
                  hint: "you@example.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // 5. Date of Birth
                CustomTextField(
                  controller: _dobController,
                  label: "Date of Birth",
                  hint: "YYYY-MM-DD",
                  readOnly: true,
                  onTap: _pickDob,
                  prefixIcon: Icons.calendar_today_outlined,
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                  validator: (val) => Validators.validateDob(_selectedDob),
                ),
                const SizedBox(height: 16),

                // 6. Password
                CustomTextField(
                  controller: _passwordController,
                  label: "Password",
                  hint: "At least 8 characters with mix of types",
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                // 7. Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  hint: "Re-enter password",
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: "Continue to Mobile Verification",
                  isLoading: authProvider.isLoading,
                  onPressed: _onSubmit,
                ),

                const SizedBox(height: 20),

                // Back to Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
