import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
  Future<void> init(String userId) async {
    // Request permission on Android 13+ and iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM device registration token
      String? token = await _fcm.getToken();
      if (token != null) {
        await saveTokenToDatabase(userId, token);
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        saveTokenToDatabase(userId, newToken);
      });
    }

    // Configure foreground notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handled automatically or surfaced in-app
    });
  }

  // Save device FCM token to user document
  Future<void> saveTokenToDatabase(String userId, String token) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'fcmToken': token,
    });
  }
}
