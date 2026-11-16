import 'package:flutter/material.dart';
import '../../core/security/app_lock_service.dart';
import '../../data/models/user_model.dart';
import '../../data/services/privacy_service.dart';

class PrivacyProvider extends ChangeNotifier {
  final PrivacyService _privacyService = PrivacyService();
  final AppLockService _appLockService = AppLockService();

  bool _isAppLockEnabled = false;
  bool _isBiometricsEnabled = false;
  bool _canCheckBiometrics = false;
  bool _isTwoStepEnabled = false;
  List<String> _blockedUserIds = [];

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get canCheckBiometrics => _canCheckBiometrics;
  bool get isTwoStepEnabled => _isTwoStepEnabled;
  List<String> get blockedUserIds => _blockedUserIds;

  PrivacyProvider() {
    _init();
  }

  Future<void> _init() async {
    _isAppLockEnabled = await _appLockService.isAppLockEnabled();
    _isBiometricsEnabled = await _appLockService.isBiometricsEnabled();
    _canCheckBiometrics = await _appLockService.canCheckBiometrics();
    _isTwoStepEnabled = await _appLockService.isTwoStepEnabled();
    notifyListeners();
  }

  // Set App Lock PIN
  Future<void> setAppLockPin(String pin) async {
    await _appLockService.setPin(pin);
    _isAppLockEnabled = true;
    notifyListeners();
  }

  // Disable App Lock
  Future<void> disableAppLock() async {
    await _appLockService.disableAppLock();
    _isAppLockEnabled = false;
    _isBiometricsEnabled = false;
    notifyListeners();
  }

  // Toggle Biometric
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _appLockService.setBiometricsEnabled(enabled);
    _isBiometricsEnabled = enabled;
    notifyListeners();
  }

  // Set Two-Step Verification PIN
  Future<void> setTwoStepPin(String pin) async {
    await _appLockService.setTwoStepPin(pin);
    _isTwoStepEnabled = true;
    notifyListeners();
  }

  Future<void> disableTwoStep() async {
    await _appLockService.disableTwoStep();
    _isTwoStepEnabled = false;
    notifyListeners();
  }

  // Update Online / Last Seen / Read Receipts / Typing Indicators
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    await _privacyService.updatePrivacySettings(userId: userId, settings: settings);
    notifyListeners();
  }

  // Block & Unblock User
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    required String blockedUsername,
  }) async {
    await _privacyService.blockUser(
      blockerId: blockerId,
      blockedId: blockedId,
      blockedUsername: blockedUsername,
    );
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _privacyService.unblockUser(blockerId: blockerId, blockedId: blockedId);
  }

  // Report User
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? details,
  }) async {
    await _privacyService.reportUser(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason,
      details: details,
    );
  }

  // Stream blocked users
  Stream<List<String>> getBlockedUsersStream(String userId) {
    return _privacyService.getBlockedUserIdsStream(userId);
  }
}
