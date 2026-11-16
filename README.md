# Whisper - Secure Text-Based Android Chat Application

Whisper is a modern, premium user-to-user text chatting application built with **Flutter**, **Dart**, and **Firebase**.

> **Architecture Note**: This application is strictly an authentic user-to-user text messaging platform. It contains **no admin portal, no admin dashboard, no admin login, and no administrative interfaces**. Photo, video, document, and audio sharing are intentionally excluded to keep the focus exclusively on private, fast, and encrypted text messaging.

---

## 📱 Technology Stack
- **Flutter & Dart**: Android-first native compilation (minSdkVersion 23, compileSdk 34).
- **Firebase Authentication**: Email/Password + Phone Auth (SMS OTP).
- **Cloud Firestore**: Real-time database for 1-on-1 and Group messaging.
- **Firebase Cloud Functions**: Unique username validation, background FCM push notifications, and automatic cleanup of disappearing messages.
- **Firebase Cloud Messaging (FCM)**: Real-time high-priority push notifications with background and foreground channels.
- **Firebase App Check**: Play Integrity enforcement for production security.
- **Biometrics & Security**: `local_auth` (Fingerprint/Biometrics), `flutter_secure_storage` (Hardware-backed encrypted key-value store), AES-256 client-side payload encryption.

---

## 🚀 Key Features

### 1. Authentication & Identity
- **Registration**:
  - Unique Username handle reservation (`@handle`).
  - Full Name.
  - Mobile Number with SMS OTP verification.
  - Email Address with email verification dispatch.
  - Date of Birth validation (minimum 13 years age restriction).
  - High-entropy password rules (uppercase, lowercase, number, special character).
  - Prevention of duplicate verified email and mobile accounts.
  - Never stores passwords in plaintext.
- **Flexible Sign In**:
  - Login using Username, Email, or Mobile Number + Password.
  - Forgot Password / Password Reset email workflow.
  - Secure "Remember Me" session persistence.

### 2. Real-Time Text Messaging
- **1-on-1 and Group Chat**:
  - Instant real-time message streaming.
  - End-to-end client-side encryption using AES-256-CBC with per-conversation key derivation.
  - Message Delivery Indicators: Sent (✓), Delivered (✓✓), and Read (Blue ✓✓).
  - Unread message counters & red badge notifications.
  - Typing indicators in real-time.
  - Online/Offline presence & intelligent Last Seen formatting.
  - Emoji picker support.

### 3. Message Management & Controls
- **Quoted Reply**: Swipe to reply or tap reply from action sheet.
- **Forwarding**: Forward text messages.
- **Edit Message**: Edit sent text messages in-place with an "edited" tag.
- **Delete Options**: "Delete for Me" and "Delete for Everyone".
- **Pin & Star**: Pin critical messages to conversation top; star favorites.
- **Reactions**: One-tap emoji reactions (👍, ❤️, 😂, 😮, 😢, 🙏, 🔥).
- **Message Search**: Real-time text search with calendar date filter.
- **Disappearing Messages**: Ephemeral messaging with auto-deletion timer (24 Hours, 7 Days, 90 Days).

### 4. Conversation & Privacy Controls
- **Conversation Actions**: Archive, Mute notifications, Pin conversation, Mark as unread, Clear chat history, Delete conversation.
- **Privacy Toggles**:
  - Hide Online Status.
  - Hide Last Seen.
  - Disable Read Receipts.
  - Disable Typing Indicators.
- **Security Lock**:
  - PIN App Lock (4-6 digits) hashed using salted SHA-256 in secure storage.
  - Android Fingerprint / Biometric authentication.
  - Two-Step Verification PIN.
  - Block and Report users.

### 5. Chat Customization
- **Theme Modes**: System Default, Light Mode, and Dark Mode.
- **Chat Wallpapers**: Custom tint/background selector.
- **Chat Bubble Colors**: Choose custom colors for sent messages.
- **Typography Scale**: Adjust chat message font size (-2 to +3).

---

## 📂 Project Directory Structure

```
chatting app/
├── android/
│   ├── app/
│   │   ├── src/main/AndroidManifest.xml   # Android permissions (Biometrics, FCM, Network)
│   │   ├── src/main/kotlin/.../MainActivity.kt  # FlutterFragmentActivity for local_auth
│   │   ├── build.gradle                   # App-level gradle configuration
│   │   └── proguard-rules.pro             # Proguard rules for Firebase & Biometrics
│   ├── build.gradle                       # Root gradle buildscript
│   └── settings.gradle
├── assets/
│   ├── icons/
│   └── images/
├── functions/                             # Firebase Cloud Functions (Node 18)
│   ├── index.js                           # Username reserve, FCM notifications, Disappearing timer
│   └── package.json
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart            # Brand, theme, bubble, and status colors
│   │   │   └── app_constants.dart         # Collection names, preferences keys
│   │   ├── routes/
│   │   │   └── app_routes.dart            # App routing names
│   │   ├── security/
│   │   │   ├── app_lock_service.dart      # PIN and Biometric authentication
│   │   │   └── encryption_service.dart    # AES-256 client-side encryption
│   │   ├── theme/
│   │   │   ├── app_theme.dart             # Material 3 Light & Dark themes
│   │   │   └── theme_provider.dart        # Dynamic theme & customization state
│   │   └── utils/
│   │       ├── date_formatter.dart        # Message, last seen, and header date formats
│   │       └── validators.dart            # Strict field validation logic
│   ├── data/
│   │   ├── models/
│   │   │   ├── conversation_model.dart    # 1-on-1 and Group conversation entities
│   │   │   ├── group_model.dart           # Group metadata and members
│   │   │   ├── message_model.dart         # Message entity with replies, reactions, timers
│   │   │   └── user_model.dart            # User profile and privacy settings
│   │   └── services/
│   │       ├── auth_service.dart          # Firebase Auth, Phone OTP, Username uniqueness
│   │       ├── chat_service.dart          # Firestore real-time messaging engine
│   │       ├── notification_service.dart  # FCM push notification handler
│   │       ├── privacy_service.dart       # User block, report, and privacy toggles
│   │       └── user_service.dart          # Presence, profile, contact discovery
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── auth_provider.dart         # Auth flow state machine
│   │   │   ├── chat_provider.dart         # Active chat & messaging state
│   │   │   ├── privacy_provider.dart      # Lock & privacy toggles state
│   │   │   └── user_provider.dart         # Contact discovery state
│   │   ├── screens/
│   │   │   ├── auth/                      # Login, Signup, OTP, Forgot Password
│   │   │   ├── chat/                      # PrivateChat, GroupChat, SearchMessages
│   │   │   ├── chats/                     # ChatsScreen, ArchivedChatsScreen
│   │   │   ├── contacts/                  # ContactsScreen, CreateGroupScreen
│   │   │   ├── lock/                      # AppLockScreen (PIN & Fingerprint)
│   │   │   ├── profile/                   # UserProfileScreen
│   │   │   ├── settings/                  # SettingsScreen, PrivacySettingsScreen, BlockedUsers
│   │   │   ├── splash/                    # SplashScreen
│   │   │   └── welcome/                   # WelcomeScreen
│   │   └── widgets/
│   │       ├── avatar_badge.dart          # Dynamic avatar with online indicator
│   │       ├── chat_bubble.dart           # Rich chat bubble with ticks, reactions, replies
│   │       ├── custom_button.dart         # Primary and outlined loading buttons
│   │       ├── custom_text_field.dart     # Styled input fields with validation
│   │       ├── message_input_bar.dart     # Multi-line input with emoji and reply banner
│   │       ├── reaction_picker_sheet.dart # Floating emoji bar & message actions
│   │       └── typing_indicator_widget.dart # Animated typing dots
│   └── main.dart                          # App entry point, MultiProvider, Firebase init
├── firebase.json                          # Firebase CLI config
├── firestore.indexes.json                 # Compound queries and indexing rules
├── firestore.rules                        # Strict Firestore security rules
├── pubspec.yaml                           # Flutter dependencies
└── FIREBASE_SETUP_GUIDE.md                # Step-by-step Firebase project connection guide
```

---

## 🛠️ Step-by-Step Setup & Build Instructions

### Prerequisites
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>=3.0.0 <4.0.0`).
2. Android Studio with Android SDK (API 34) and Java 17.
3. Firebase Account & Firebase CLI (`npm install -g firebase-tools`).

### Step 1: Firebase Project Configuration
1. Follow the steps detailed in [`FIREBASE_SETUP_GUIDE.md`](file:///c:/Users/Windows%2011/Desktop/chatting%20app/FIREBASE_SETUP_GUIDE.md) to generate your `google-services.json`.
2. Move `google-services.json` to `android/app/google-services.json`.
3. Deploy Firestore rules and indexes:
   ```bash
   firebase login
   firebase deploy --only firestore:rules,firestore:indexes
   ```
4. Deploy Firebase Cloud Functions:
   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

### Step 2: Install Flutter Dependencies
Run in the project root:
```bash
flutter pub get
```

### Step 3: Run on Android Emulator or Device
```bash
flutter run
```

### Step 4: Build Production Android Release APK
To generate the release APK for Android:
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`
