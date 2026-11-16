class AppConstants {
  static const String appName = "Whisper";
  static const String appTagline = "Fast, Secure & Private Text Messaging";
  
  // Collections
  static const String usersCollection = "users";
  static const String usernamesCollection = "usernames";
  static const String conversationsCollection = "conversations";
  static const String messagesCollection = "messages";
  static const String groupsCollection = "groups";
  static const String userBlocksCollection = "userBlocks";
  static const String userReportsCollection = "userReports";
  static const String notificationsCollection = "notifications";
  static const String appSettingsCollection = "appSettings";

  // Shared Preferences Keys
  static const String prefKeyThemeMode = "pref_theme_mode";
  static const String prefKeyChatWallpaper = "pref_chat_wallpaper";
  static const String prefKeyBubbleColor = "pref_bubble_color";
  static const String prefKeyFontSize = "pref_font_size";
  static const String prefKeyAppLockPin = "pref_app_lock_pin";
  static const String prefKeyBiometricsEnabled = "pref_biometrics_enabled";
  static const String prefKeyTwoStepPin = "pref_two_step_pin";
  static const String prefKeyRememberMe = "pref_remember_me";

  // Notification Channel
  static const String notificationChannelId = "whisper_messages_channel";
  static const String notificationChannelName = "Whisper Messages";
  static const String notificationChannelDesc = "Direct and group message notifications";

  // Disappearing messages durations (seconds)
  static const int disappearingOff = 0;
  static const int disappearing24Hours = 86400;
  static const int disappearing7Days = 604800;
  static const int disappearing90Days = 7776000;
}
