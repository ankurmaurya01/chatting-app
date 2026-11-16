const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. Reserve Unique Username (Atomic Transaction)
 */
exports.reserveUsername = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can reserve a username."
    );
  }

  const username = (data.username || "").toLowerCase().trim();
  const uid = context.auth.uid;

  if (!/^[a-zA-Z0-9._]{3,25}$/.test(username)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Username must be 3-25 alphanumeric characters, periods, or underscores."
    );
  }

  const usernameRef = db.collection("usernames").doc(username);

  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(usernameRef);
    if (doc.exists) {
      if (doc.data().uid === uid) {
        return { success: true, message: "Username already owned by you." };
      }
      throw new functions.https.HttpsError(
        "already-exists",
        "This username is already taken. Please choose another."
      );
    }

    transaction.set(usernameRef, {
      uid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(db.collection("users").doc(uid), {
      username: username,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, username: username };
  });
});

/**
 * 2. On New Message Created: Send FCM Push Notification and Update Conversation
 */
exports.onMessageCreated = functions.firestore
  .document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const conversationId = context.params.conversationId;
    const senderId = messageData.senderId;
    const text = messageData.text || "New message";

    const convRef = db.collection("conversations").doc(conversationId);
    const convDoc = await convRef.get();

    if (!convDoc.exists) return null;
    const convData = convDoc.data();
    const participantIds = convData.participantIds || [];

    // Filter recipients excluding sender
    const recipientIds = participantIds.filter((id) => id !== senderId);

    // Get sender profile
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().fullName || senderDoc.data().username : "Someone";

    // Update conversation metadata
    const unreadUpdates = {};
    recipientIds.forEach((recId) => {
      unreadUpdates[`unreadCounts.${recId}`] = admin.firestore.FieldValue.increment(1);
    });

    await convRef.update({
      lastMessage: text,
      lastMessageSenderId: senderId,
      lastMessageTimestamp: messageData.timestamp || admin.firestore.FieldValue.serverTimestamp(),
      ...unreadUpdates,
    });

    // Send Push Notifications to recipients
    for (const recId of recipientIds) {
      // Check if conversation is muted by recipient
      const mutedList = convData.mutedBy || [];
      if (mutedList.includes(recId)) {
        continue;
      }

      // Check if sender is blocked by recipient
      const blockCheck = await db
        .collection("userBlocks")
        .where("blockerId", "==", recId)
        .where("blockedId", "==", senderId)
        .limit(1)
        .get();

      if (!blockCheck.empty) {
        continue;
      }

      const recUserDoc = await db.collection("users").doc(recId).get();
      if (!recUserDoc.exists) continue;

      const fcmToken = recUserDoc.data().fcmToken;
      if (!fcmToken) continue;

      const payload = {
        token: fcmToken,
        notification: {
          title: convData.type === "group" ? `${convData.groupName} (${senderName})` : senderName,
          body: text,
        },
        data: {
          conversationId: conversationId,
          type: convData.type || "private",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "whisper_messages_channel",
            sound: "default",
          },
        },
      };

      try {
        await admin.messaging().send(payload);
      } catch (err) {
        console.error(`Failed to send FCM to user ${recId}:`, err);
      }
    }

    return null;
  });

/**
 * 3. Scheduled Cleanup for Disappearing Messages (Runs hourly)
 */
exports.cleanupDisappearingMessages = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Query messages whose expiresAt timestamp is in the past
    const snapshot = await db
      .collectionGroup("messages")
      .where("expiresAt", "<=", now)
      .limit(500)
      .get();

    if (snapshot.empty) {
      console.log("No expired messages found.");
      return null;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Successfully purged ${snapshot.size} expired disappearing messages.`);
    return null;
  });
