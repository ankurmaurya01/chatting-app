import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const OtpVerificationScreen({super.key, required this.registrationData});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final code = _otpController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete 6-digit OTP code.")),
      );
      return;
    }

    final success = await authProvider.register(
      username: widget.registrationData['username'],
      fullName: widget.registrationData['fullName'],
      mobile: widget.registrationData['mobile'],
      email: widget.registrationData['email'],
      dob: widget.registrationData['dob'],
      password: widget.registrationData['password'],
      smsCode: code,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Account Created!"),
          content: const Text(
            "Your mobile number has been verified and a verification link has been sent to your email. You can now chat securely.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.chats, (route) => false);
              },
              child: const Text("Get Started"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mobile = widget.registrationData['mobile'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Mobile")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                "Enter Verification Code",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "We sent a 6-digit SMS verification code to $mobile",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 32),

              if (authProvider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: "Verify & Complete Signup",
                isLoading: authProvider.isLoading,
                onPressed: _verifyOtp,
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  authProvider.sendMobileOtp(mobile);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("A new OTP code has been dispatched.")),
                  );
                },
                child: const Text("Didn't receive code? Resend SMS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
