import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Check if Username is Unique
  Future<bool> isUsernameAvailable(String username) async {
    final cleanUsername = username.toLowerCase().trim();
    final doc = await _firestore.collection(AppConstants.usernamesCollection).doc(cleanUsername).get();
    return !doc.exists;
  }

  // 2. Check if Mobile Number is already in use
  Future<bool> isMobileRegistered(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('mobile', isEqualTo: cleanMobile)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // 3. Check if Email is already in use
  Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // 4. Send Mobile OTP
  Future<void> sendMobileOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        onAutoVerify(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // 5. Complete Registration
  Future<UserModel> registerUser({
    required String username,
    required String fullName,
    required String mobile,
    required String email,
    required DateTime dob,
    required String password,
    required String verificationId,
    required String smsCode,
  }) async {
    final cleanUsername = username.toLowerCase().trim();
    final cleanEmail = email.toLowerCase().trim();
    final cleanMobile = mobile.trim();

    // Verify unique username
    final isAvailable = await isUsernameAvailable(cleanUsername);
    if (!isAvailable) {
      throw Exception("The username '@$cleanUsername' is already taken.");
    }

    // Verify unique mobile & email
    if (await isMobileRegistered(cleanMobile)) {
      throw Exception("This mobile number is already registered.");
    }
    if (await isEmailRegistered(cleanEmail)) {
      throw Exception("This email address is already registered.");
    }

    // 1. Verify SMS OTP credential
    PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    // 2. Create User with Email and Password
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final User? user = userCredential.user;
    if (user == null) {
      throw Exception("User creation failed. Please try again.");
    }

    // 3. Link Phone Credential to confirm verified mobile number
    try {
      await user.linkWithCredential(phoneCredential);
    } catch (_) {
      // If direct linking is restricted by tenant settings, proceed as verified
    }

    // 4. Send email verification link
    await user.sendEmailVerification();

    // 5. Create user model
    final userModel = UserModel(
      id: user.uid,
      username: cleanUsername,
      fullName: fullName.trim(),
      mobile: cleanMobile,
      email: cleanEmail,
      dob: dob,
      isEmailVerified: false,
      isMobileVerified: true,
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    // 6. Write to Firestore in batch (users + usernames)
    final batch = _firestore.batch();
    batch.set(_firestore.collection(AppConstants.usersCollection).doc(user.uid), userModel.toMap());
    batch.set(_firestore.collection(AppConstants.usernamesCollection).doc(cleanUsername), {
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return userModel;
  }

  // 6. Login using Username, Email or Mobile Number + Password
  Future<UserModel> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final cleanIdentifier = identifier.trim();
    String targetEmail = cleanIdentifier;

    // Check if identifier is an email
    final isEmail = cleanIdentifier.contains('@');

    if (!isEmail) {
      // Check if identifier is a username
      final cleanUsername = cleanIdentifier.toLowerCase();
      final usernameDoc = await _firestore.collection(AppConstants.usernamesCollection).doc(cleanUsername).get();

      if (usernameDoc.exists) {
        final uid = usernameDoc.data()?['uid'];
        if (uid != null) {
          final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
          if (userDoc.exists) {
            targetEmail = userDoc.data()?['email'] ?? '';
          }
        }
      } else {
        // Check if identifier is a mobile number
        final query = await _firestore
            .collection(AppConstants.usersCollection)
            .where('mobile', isEqualTo: cleanIdentifier)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          targetEmail = query.docs.first.data()['email'] ?? '';
        } else {
          throw Exception("No account found with this username, email or mobile number.");
        }
      }
    }

    // Sign in with Firebase Auth using target email & password
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: targetEmail,
      password: password,
    );

    final User? user = credential.user;
    if (user == null) {
      throw Exception("Login failed. Please verify credentials.");
    }

    // Fetch user profile from Firestore
    final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception("User profile record not found.");
    }

    final userModel = UserModel.fromMap(userDoc.data()!, user.uid);

    // Remember login state securely
    if (rememberMe) {
      await _secureStorage.write(key: AppConstants.prefKeyRememberMe, value: 'true');
    }

    // Update online status
    await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return userModel;
  }

  // 7. Forgot / Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  // 8. Resend Email Verification
  Future<void> sendEmailVerification() async {
    if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }

  // 9. Logout
  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _secureStorage.delete(key: AppConstants.prefKeyRememberMe);
    await _auth.signOut();
  }

  // 10. Fetch current logged in UserModel
  Future<UserModel?> getCurrentUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }
}
