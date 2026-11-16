import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class AppLockService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Hash PIN with salt
  String _hashPin(String pin) {
    final bytes = utf8.encode("whisper_pin_salt_$pin");
    return sha256.convert(bytes).toString();
  }

  // Check if App Lock is enabled
  Future<bool> isAppLockEnabled() async {
    final pinHash = await _secureStorage.read(key: AppConstants.prefKeyAppLockPin);
    return pinHash != null && pinHash.isNotEmpty;
  }

  // Set PIN
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: AppConstants.prefKeyAppLockPin, value: hash);
  }

  // Verify PIN
  Future<bool> verifyPin(String enteredPin) async {
    final storedHash = await _secureStorage.read(key: AppConstants.prefKeyAppLockPin);
    if (storedHash == null) return true;
    return storedHash == _hashPin(enteredPin);
  }

  // Remove PIN / Disable App Lock
  Future<void> disableAppLock() async {
    await _secureStorage.delete(key: AppConstants.prefKeyAppLockPin);
    await _secureStorage.delete(key: AppConstants.prefKeyBiometricsEnabled);
  }

  // Biometric support check
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // Check if biometric is enabled by user
  Future<bool> isBiometricsEnabled() async {
    final val = await _secureStorage.read(key: AppConstants.prefKeyBiometricsEnabled);
    return val == 'true';
  }

  // Set Biometric preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.prefKeyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  // Authenticate with Biometrics (Fingerprint / Face)
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to unlock Whisper Chat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // Two-Step Verification PIN
  Future<bool> isTwoStepEnabled() async {
    final pin = await _secureStorage.read(key: AppConstants.prefKeyTwoStepPin);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setTwoStepPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: AppConstants.prefKeyTwoStepPin, value: hash);
  }

  Future<bool> verifyTwoStepPin(String enteredPin) async {
    final storedHash = await _secureStorage.read(key: AppConstants.prefKeyTwoStepPin);
    if (storedHash == null) return true;
    return storedHash == _hashPin(enteredPin);
  }

  Future<void> disableTwoStep() async {
    await _secureStorage.delete(key: AppConstants.prefKeyTwoStepPin);
  }
}
