import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'data/models/conversation_model.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/privacy_provider.dart';
import 'presentation/providers/user_provider.dart';

import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/welcome/welcome_screen.dart';
import 'presentation/screens/lock/app_lock_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/chats/chats_screen.dart';
import 'presentation/screens/chats/archived_chats_screen.dart';
import 'presentation/screens/chat/private_chat_screen.dart';
import 'presentation/screens/chat/group_chat_screen.dart';
import 'presentation/screens/chat/search_messages_screen.dart';
import 'presentation/screens/contacts/contacts_screen.dart';
import 'presentation/screens/contacts/create_group_screen.dart';
import 'presentation/screens/profile/user_profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/privacy_settings_screen.dart';
import 'presentation/screens/settings/blocked_users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely checks if options or default app already loaded)
  try {
    await Firebase.initializeApp();
    // Activate Firebase App Check for production security
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint("Firebase initialization info: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
      ],
      child: const WhisperChatApp(),
    ),
  );
}

class WhisperChatApp extends StatelessWidget {
  const WhisperChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AppRoutes.welcome:
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          case AppRoutes.appLock:
            return MaterialPageRoute(builder: (_) => const AppLockScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case AppRoutes.signup:
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case AppRoutes.otp:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => OtpVerificationScreen(registrationData: args));
          case AppRoutes.forgotPassword:
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

          case AppRoutes.chats:
            return MaterialPageRoute(builder: (_) => const ChatsScreen());
          case AppRoutes.archivedChats:
            return MaterialPageRoute(builder: (_) => const ArchivedChatsScreen());
          case AppRoutes.contacts:
            return MaterialPageRoute(builder: (_) => const ContactsScreen());
          case AppRoutes.createGroup:
            return MaterialPageRoute(builder: (_) => const CreateGroupScreen());

          case AppRoutes.privateChat:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PrivateChatScreen(
                conversation: args['conversation'] as ConversationModel,
                targetUserId: args['targetUserId'] as String,
                targetUserName: args['targetUserName'] as String,
              ),
            );
          case AppRoutes.groupChat:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => GroupChatScreen(
                conversation: args['conversation'] as ConversationModel,
              ),
            );
          case AppRoutes.searchMessages:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SearchMessagesScreen(
                conversationId: args['conversationId'] as String,
              ),
            );

          case AppRoutes.profile:
            return MaterialPageRoute(builder: (_) => const UserProfileScreen());
          case AppRoutes.settings:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case AppRoutes.privacySettings:
            return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
          case AppRoutes.blockedUsers:
            return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());

          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
