import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/app_lock_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockService _lockService = AppLockService();
  String _enteredPin = "";
  String? _error;
  bool _canBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canBio = await _lockService.canCheckBiometrics();
    final isBioOn = await _lockService.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _canBiometrics = canBio && isBioOn;
      });
      if (_canBiometrics) {
        _triggerBiometricAuth();
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final success = await _lockService.authenticateWithBiometrics();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.chats);
    }
  }

  void _onDigitPressed(String digit) async {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += digit;
      _error = null;
    });

    if (_enteredPin.length >= 4) {
      final isValid = await _lockService.verifyPin(_enteredPin);
      if (isValid && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.chats);
      } else if (_enteredPin.length == 6) {
        setState(() {
          _error = "Incorrect PIN. Please try again.";
          _enteredPin = "";
        });
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _error = null;
      });
    }
  }

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _onDigitPressed(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                "Whisper Locked",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter your PIN to continue",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Theme.of(context).dividerColor,
                    ),
                  );
                }),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              const Spacer(),

              // Numeric Keypad
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildKey("1"), _buildKey("2"), _buildKey("3")],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildKey("4"), _buildKey("5"), _buildKey("6")],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildKey("7"), _buildKey("8"), _buildKey("9")],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_canBiometrics)
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                          onPressed: _triggerBiometricAuth,
                        )
                      else
                        const SizedBox(width: 72),
                      _buildKey("0"),
                      IconButton(
                        iconSize: 28,
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: _onDeletePressed,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
