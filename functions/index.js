const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send push notification when a new notification is created
 */
exports.sendPushNotification = functions.firestore
  .document('users/{userId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const notification = snap.data();

    try {
      // Get user's FCM tokens
      const tokensSnapshot = await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .get();

      if (tokensSnapshot.empty) {
        console.log(`No FCM tokens found for user ${userId}`);
        return null;
      }

      // Prepare notification payload
      const payload = {
        notification: {
          title: notification.title || 'Tasker',
          body: notification.body || '',
          ...(notification.imageUrl && { imageUrl: notification.imageUrl })
        },
        data: {
          notificationId: snap.id,
          type: notification.type || '',
          actionUrl: notification.actionUrl || '',
          ...notification.data
        }
      };

      // Get all tokens
      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

      // Send to all tokens
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'tasker_channel'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      });

      // Handle failures and remove invalid tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Failed to send to token: ${tokens[idx]}`);
            if (resp.error?.code === 'messaging/invalid-registration-token' ||
                resp.error?.code === 'messaging/registration-token-not-registered') {
              failedTokens.push(tokens[idx]);
            }
          }
        });

        // Remove invalid tokens
        const batch = admin.firestore().batch();
        failedTokens.forEach(token => {
          const tokenRef = admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('fcmTokens')
            .doc(token);
          batch.delete(tokenRef);
        });
        await batch.commit();
        console.log(`Removed ${failedTokens.length} invalid tokens`);
      }

      console.log(`Successfully sent notification to ${response.successCount} devices`);
      return response;
    } catch (error) {
      console.error('Error sending push notification:', error);
      return null;
    }
  });

/**
 * Clean up old FCM tokens (run daily)
 */
exports.cleanupOldTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 days old

    try {
      const usersSnapshot = await admin.firestore().collection('users').get();
      let deletedCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const tokensSnapshot = await userDoc.ref
          .collection('fcmTokens')
          .where('lastUsed', '<', cutoffDate)
          .get();

        if (!tokensSnapshot.empty) {
          const batch = admin.firestore().batch();
          tokensSnapshot.docs.forEach(doc => batch.delete(doc.ref));
          await batch.commit();
          deletedCount += tokensSnapshot.size;
        }
      }

      console.log(`Cleaned up ${deletedCount} old FCM tokens`);
      return null;
    } catch (error) {
      console.error('Error cleaning up old tokens:', error);
      return null;
    }
  });
