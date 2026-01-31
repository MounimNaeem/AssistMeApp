import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { NotificationSchedule, CalendarEvent } from "./types";
import {
  isScheduleDue,
  calculateNextScheduledAt,
  toTimestamp,
} from "./utils/scheduler";
import {
  getUsersWithTokens,
  sendNotificationToUsers,
  sendEventReminderToUsers,
  cleanupInvalidTokens,
} from "./utils/fcm";

// Initialize Firebase Admin
initializeApp();

/**
 * Scheduled function that runs every 3 minutes to check and send due notifications
 *
 * Flow:
 * 1. Query all enabled notification schedules
 * 2. Check which schedules are due (nextScheduledAt <= now)
 * 3. Query calendar events with due reminders
 * 4. Get all users with FCM tokens
 * 5. Send push notifications for schedules and event reminders
 * 6. Update lastSentAt/nextScheduledAt for schedules
 * 7. Mark event reminders as sent
 */
export const processScheduledNotifications = onSchedule(
  {
    schedule: "every 3 minutes",
    timeZone: "UTC",
    region: "us-central1",
    retryCount: 3,
    memory: "256MiB",
  },
  async () => {
    logger.info("Starting scheduled notification processing");

    const db = getFirestore();
    const now = new Date();

    try {
      // Step 1: Get all notification schedules
      const schedulesSnapshot = await db
        .collection("notification_schedules")
        .where("enabled", "==", true)
        .get();

      // Step 2: Filter schedules that are due
      const dueSchedules: NotificationSchedule[] = [];

      for (const doc of schedulesSnapshot.docs) {
        const schedule = doc.data() as NotificationSchedule;
        schedule.id = doc.id;

        if (isScheduleDue(schedule, now)) {
          dueSchedules.push(schedule);
        }
      }

      // Step 3: Get calendar events with due reminders
      const dueEvents = await getDueCalendarEvents(db, now);

      // Check if there's anything to process
      if (dueSchedules.length === 0 && dueEvents.length === 0) {
        logger.info("No notifications or event reminders due at this time");
        return;
      }

      logger.info(
        `Found ${dueSchedules.length} due schedule(s) and ${dueEvents.length} due event reminder(s)`
      );

      // Step 4: Get all users with FCM tokens (once for all notifications)
      const users = await getUsersWithTokens();

      if (users.length === 0) {
        logger.info("No users with FCM tokens found");
        // Still update schedules and events to prevent repeated checks
        if (dueSchedules.length > 0) {
          await updateSchedulesAfterSend(db, dueSchedules, now);
        }
        if (dueEvents.length > 0) {
          await markEventRemindersAsSent(db, dueEvents);
        }
        return;
      }

      logger.info(`Found ${users.length} user(s) with FCM tokens`);

      const allInvalidTokens: string[] = [];

      // Step 5a: Send notifications for each due schedule
      for (const schedule of dueSchedules) {
        logger.info(`Processing schedule: ${schedule.id} - "${schedule.title}"`);

        const result = await sendNotificationToUsers(schedule, users);
        allInvalidTokens.push(...result.invalidTokens);

        logger.info(
          `Schedule ${schedule.id}: sent to ${result.successCount} users`
        );
      }

      // Step 5b: Send notifications for each due event reminder
      for (const event of dueEvents) {
        logger.info(`Processing event reminder: ${event.id} - "${event.title}"`);

        const result = await sendEventReminderToUsers(event, users);
        allInvalidTokens.push(...result.invalidTokens);

        logger.info(
          `Event ${event.id}: reminder sent to ${result.successCount} users`
        );
      }

      // Step 6: Update schedules with new times
      if (dueSchedules.length > 0) {
        await updateSchedulesAfterSend(db, dueSchedules, now);
      }

      // Step 7: Mark event reminders as sent
      if (dueEvents.length > 0) {
        await markEventRemindersAsSent(db, dueEvents);
      }

      // Step 8: Clean up invalid tokens
      if (allInvalidTokens.length > 0) {
        const uniqueInvalidTokens = [...new Set(allInvalidTokens)];
        await cleanupInvalidTokens(uniqueInvalidTokens);
      }

      logger.info("Scheduled notification processing completed");
    } catch (error) {
      logger.error("Error processing scheduled notifications:", error);
      throw error; // Re-throw to trigger retry
    }
  }
);

/**
 * Get calendar events with due reminders
 * Queries events where reminderEnabled = true, then filters in code
 * to avoid requiring a composite index
 */
async function getDueCalendarEvents(
  db: FirebaseFirestore.Firestore,
  now: Date
): Promise<CalendarEvent[]> {
  // Query only by reminderEnabled to avoid composite index requirement
  const eventsSnapshot = await db
    .collection("calendar_events")
    .where("reminderEnabled", "==", true)
    .get();

  const events: CalendarEvent[] = [];
  const nowTimestamp = Timestamp.fromDate(now);

  for (const doc of eventsSnapshot.docs) {
    const event = doc.data() as CalendarEvent;
    event.id = doc.id;

    // Filter in code: reminderSent = false AND reminderAt <= now
    if (
      !event.reminderSent &&
      event.reminderAt &&
      event.reminderAt.toMillis() <= nowTimestamp.toMillis()
    ) {
      events.push(event);
    }
  }

  return events;
}

/**
 * Mark event reminders as sent
 */
async function markEventRemindersAsSent(
  db: FirebaseFirestore.Firestore,
  events: CalendarEvent[]
): Promise<void> {
  const batch = db.batch();

  for (const event of events) {
    const eventRef = db.collection("calendar_events").doc(event.id);
    batch.update(eventRef, {
      reminderSent: true,
    });

    logger.info(`Marked event ${event.id} reminder as sent`);
  }

  await batch.commit();
}

/**
 * Update schedules after sending notifications
 */
async function updateSchedulesAfterSend(
  db: FirebaseFirestore.Firestore,
  schedules: NotificationSchedule[],
  sentAt: Date
): Promise<void> {
  const batch = db.batch();

  for (const schedule of schedules) {
    const nextScheduledAt = calculateNextScheduledAt(schedule, sentAt);

    const scheduleRef = db.collection("notification_schedules").doc(schedule.id);
    batch.update(scheduleRef, {
      lastSentAt: toTimestamp(sentAt),
      nextScheduledAt: toTimestamp(nextScheduledAt),
      updatedAt: Timestamp.now(),
    });

    logger.info(
      `Schedule ${schedule.id}: next run at ${nextScheduledAt.toISOString()}`
    );
  }

  await batch.commit();
}
