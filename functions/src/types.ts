import { Timestamp } from "firebase-admin/firestore";

/**
 * Frequency type options for notification schedules
 */
export type FrequencyType =
  | "daily" // Every day
  | "days" // Every X days
  | "weekly" // Every week
  | "weeks" // Every X weeks
  | "months" // Every X months
  | "selected_days"; // Specific days of the week

/**
 * Day of the week abbreviation
 */
export type DayOfWeek = "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun";

/**
 * Notification schedule stored in Firestore
 * Collection: notification_schedules/{schedule_id}
 */
export interface NotificationSchedule {
  id: string;
  title: string;
  body: string;
  enabled: boolean;
  frequencyType: FrequencyType;
  frequencyValue: number;
  preferredTime: string; // "HH:mm" format
  selectedDays: DayOfWeek[]; // For 'selected_days' frequency type
  lastSentAt: Timestamp | null;
  nextScheduledAt: Timestamp | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/**
 * User document with FCM token
 * Collection: users/{user_id}
 */
export interface UserWithToken {
  id: string;
  fcmToken: string;
}

/**
 * Result of sending notifications
 */
export interface SendResult {
  successCount: number;
  failureCount: number;
  invalidTokens: string[];
}

/**
 * Calendar event stored in Firestore
 * Collection: calendar_events/{event_id}
 */
export interface CalendarEvent {
  id: string;
  userId: string;
  title: string;
  description: string;
  eventDateTime: Timestamp;
  endDateTime: Timestamp | null;
  eventColor: number;
  reminderEnabled: boolean;
  reminderMinutesBefore: number;
  reminderAt: Timestamp | null;
  reminderSent: boolean;
  createdAt: Timestamp;
}
