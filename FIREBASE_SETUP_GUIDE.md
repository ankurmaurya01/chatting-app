# Firebase Setup Guide for Whisper Chat Application

This guide walks you through connecting this Flutter Android application to your Firebase project.

---

## 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it `whisper-chat-app`.
3. Disable or enable Google Analytics according to your preference, then click **Create Project**.

---

## 2. Register Android App
1. In project overview, click the **Android** icon (`com.whisper.chat`).
2. Set **Android package name**: `com.whisper.chat`.
3. Set **App nickname**: `Whisper Chat`.
4. Obtain your SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
   Paste the SHA-1 and SHA-256 fingerprint (required for Firebase Phone Auth OTP).
5. Download `google-services.json` and place it in:
   `android/app/google-services.json`

---

## 3. Enable Authentication Methods
In the Firebase Console under **Build > Authentication > Sign-in method**:
1. **Email/Password**: Enable "Email/Password".
2. **Phone**: Enable "Phone".
   - Under *Phone numbers for testing*, add your developer test phone number (e.g., `+1 650-555-3434` with SMS code `123456`) for instant testing without consuming SMS quotas.

---

## 4. Setup Cloud Firestore Database
1. Go to **Build > Firestore Database** and click **Create database**.
2. Start in **Production mode**.
3. Select your preferred Cloud Firestore server location.

---

## 5. Deploy Security Rules and Indexes
Using Firebase CLI in the project directory:
```bash
# Login to Firebase
firebase login

# Initialize project link
firebase use --add

# Deploy Firestore Rules and Indexes
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 6. Deploy Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

## 7. Firebase Cloud Messaging (FCM)
FCM is automatically linked via `google-services.json`.
Notification channel ID used by the app is `whisper_messages_channel`.

---

## 8. Firebase App Check (Production Security)
1. In Firebase Console, go to **Build > App Check**.
2. Register your Android app with **Play Integrity** (or **SafetyNet** debug token during development).
3. The app is pre-configured with `FirebaseAppCheck.instance.activate()`.
