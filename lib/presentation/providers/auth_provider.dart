import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, authenticating, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Phone OTP Flow State
  String? _verificationId;
  bool _isOtpSent = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationId => _verificationId;
  bool get isOtpSent => _isOtpSent;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
      } else {
        _status = AuthStatus.authenticated;
        _currentUser = await _authService.getCurrentUserModel();
      }
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 1. Send OTP for Mobile Verification
  Future<bool> sendMobileOtp(String mobileNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if mobile already exists
      final isUsed = await _authService.isMobileRegistered(mobileNumber);
      if (isUsed) {
        _errorMessage = "This mobile number is already associated with an account.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _authService.sendMobileOtp(
        phoneNumber: mobileNumber,
        onCodeSent: (verId) {
          _verificationId = verId;
          _isOtpSent = true;
          _isLoading = false;
          notifyListeners();
        },
        onVerificationFailed: (e) {
          _errorMessage = e.message ?? "Phone verification failed.";
          _isLoading = false;
          notifyListeners();
        },
        onAutoVerify: (credential) {
          _isLoading = false;
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 2. Complete Signup
  Future<bool> register({
    required String username,
    required String fullName,
    required String mobile,
    required String email,
    required DateTime dob,
    required String password,
    required String smsCode,
  }) async {
    if (_verificationId == null) {
      _errorMessage = "Mobile verification expired. Please request OTP again.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.registerUser(
        username: username,
        fullName: fullName,
        mobile: mobile,
        email: email,
        dob: dob,
        password: password,
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. Login
  Future<bool> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        identifier: identifier,
        password: password,
        rememberMe: rememberMe,
      );
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 4. Forgot Password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 5. Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  // Refresh User Model
  Future<void> refreshCurrentUser() async {
    _currentUser = await _authService.getCurrentUserModel();
    notifyListeners();
  }
}
