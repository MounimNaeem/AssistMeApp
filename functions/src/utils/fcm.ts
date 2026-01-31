import { getMessaging, Message } from "firebase-admin/messaging";
import { getFirestore } from "firebase-admin/firestore";
import { NotificationSchedule, UserWithToken, SendResult, CalendarEvent } from "../types";
import * as logger from "firebase-functions/logger";

/**
 * Get all users with valid FCM tokens
 */
export async function getUsersWithTokens(): Promise<UserWithToken[]> {
  const db = getFirestore();
  const usersSnapshot = await db
    .collection("users")
    .where("fcmToken", "!=", null)
    .get();

  const users: UserWithToken[] = [];

  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    if (data.fcmToken && typeof data.fcmToken === "string") {
      users.push({
        id: doc.id,
        fcmToken: data.fcmToken,
      });
    }
  }

  return users;
}

/**
 * Send push notification to multiple users
 * Uses sendEach for better error handling per token
 */
export async function sendNotificationToUsers(
  schedule: NotificationSchedule,
  users: UserWithToken[]
): Promise<SendResult> {
  if (users.length === 0) {
    logger.info("No users with FCM tokens to notify");
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  const messaging = getMessaging();

  // Build messages for each user
  const messages: Message[] = users.map((user) => ({
    token: user.fcmToken,
    notification: {
      title: schedule.title,
      body: schedule.body,
    },
    data: {
      scheduleId: schedule.id,
      type: "scheduled_notification",
    },
    android: {
      priority: "high" as const,
      notification: {
        channelId: "high_importance_channel",
        priority: "high" as const,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  }));

  // Send all messages
  const response = await messaging.sendEach(messages);

  // Track invalid tokens for cleanup
  const invalidTokens: string[] = [];

  response.responses.forEach((resp, index) => {
    if (!resp.success && resp.error) {
      const errorCode = resp.error.code;
      // These error codes indicate the token is no longer valid
      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(users[index].fcmToken);
        logger.warn(`Invalid token for user ${users[index].id}: ${errorCode}`);
      } else {
        logger.error(
          `Failed to send to user ${users[index].id}: ${resp.error.message}`
        );
      }
    }
  });

  logger.info(
    `Notification sent: ${response.successCount} success, ${response.failureCount} failed`
  );

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokens,
  };
}

/**
 * Clean up invalid FCM tokens from user documents
 */
export async function cleanupInvalidTokens(
  invalidTokens: string[]
): Promise<void> {
  if (invalidTokens.length === 0) return;

  const db = getFirestore();
  const batch = db.batch();

  // Find users with these invalid tokens and clear them
  const usersSnapshot = await db
    .collection("users")
    .where("fcmToken", "in", invalidTokens)
    .get();

  for (const doc of usersSnapshot.docs) {
    batch.update(doc.ref, { fcmToken: null });
    logger.info(`Clearing invalid token for user ${doc.id}`);
  }

  await batch.commit();
  logger.info(`Cleaned up ${usersSnapshot.size} invalid tokens`);
}

/**
 * Format reminder time for notification body
 */
function formatReminderTime(minutesBefore: number): string {
  if (minutesBefore < 60) {
    return `in ${minutesBefore} minute${minutesBefore === 1 ? "" : "s"}`;
  } else if (minutesBefore === 60) {
    return "in 1 hour";
  } else if (minutesBefore < 1440) {
    const hours = Math.floor(minutesBefore / 60);
    return `in ${hours} hour${hours === 1 ? "" : "s"}`;
  } else {
    return "in 1 day";
  }
}

/**
 * Send calendar event reminder notification to all users with FCM tokens
 * Since this is a shared calendar, all users receive event reminders
 */
export async function sendEventReminderToUsers(
  event: CalendarEvent,
  users: UserWithToken[]
): Promise<SendResult> {
  if (users.length === 0) {
    logger.info("No users with FCM tokens to notify for event reminder");
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  const messaging = getMessaging();
  const reminderText = formatReminderTime(event.reminderMinutesBefore);

  // Build messages for each user
  const messages: Message[] = users.map((user) => ({
    token: user.fcmToken,
    notification: {
      title: `📅 ${event.title}`,
      body: `Event starting ${reminderText}`,
    },
    data: {
      eventId: event.id,
      type: "calendar_event_reminder",
    },
    android: {
      priority: "high" as const,
      notification: {
        channelId: "high_importance_channel",
        priority: "high" as const,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  }));

  // Send all messages
  const response = await messaging.sendEach(messages);

  // Track invalid tokens for cleanup
  const invalidTokens: string[] = [];

  response.responses.forEach((resp, index) => {
    if (!resp.success && resp.error) {
      const errorCode = resp.error.code;
      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(users[index].fcmToken);
        logger.warn(`Invalid token for user ${users[index].id}: ${errorCode}`);
      } else {
        logger.error(
          `Failed to send event reminder to user ${users[index].id}: ${resp.error.message}`
        );
      }
    }
  });

  logger.info(
    `Event reminder sent: ${response.successCount} success, ${response.failureCount} failed`
  );

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokens,
  };
}
