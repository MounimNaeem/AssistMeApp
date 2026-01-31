import { Timestamp } from "firebase-admin/firestore";
import { NotificationSchedule, DayOfWeek } from "../types";

/**
 * Map day abbreviation to JS Date day number (0 = Sunday, 1 = Monday, etc.)
 */
const DAY_MAP: Record<DayOfWeek, number> = {
  Sun: 0,
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
};

/**
 * Calculate the next scheduled time based on frequency settings
 * Uses the previous nextScheduledAt as base and adds the appropriate interval
 * This preserves the user's local timezone without needing timezone conversion
 */
export function calculateNextScheduledAt(
  schedule: NotificationSchedule,
  fromDate: Date = new Date()
): Date {
  const { frequencyType, frequencyValue, selectedDays, nextScheduledAt } =
    schedule;

  // Use the previous nextScheduledAt as base if available, otherwise use fromDate
  const baseDate = nextScheduledAt ? nextScheduledAt.toDate() : fromDate;
  const nextDate = new Date(baseDate);

  switch (frequencyType) {
    case "daily":
      // Next day at same time
      nextDate.setDate(nextDate.getDate() + 1);
      break;

    case "days":
      // Every X days
      nextDate.setDate(nextDate.getDate() + frequencyValue);
      break;

    case "weekly":
      // Every week (7 days)
      nextDate.setDate(nextDate.getDate() + 7);
      break;

    case "weeks":
      // Every X weeks
      nextDate.setDate(nextDate.getDate() + frequencyValue * 7);
      break;

    case "months":
      // Every X months
      nextDate.setMonth(nextDate.getMonth() + frequencyValue);
      break;

    case "selected_days":
      // Find next matching day
      return calculateNextSelectedDay(nextDate, selectedDays);
  }

  return nextDate;
}

/**
 * Find the next occurrence of one of the selected days
 * Preserves the time from fromDate and finds the next matching day
 */
function calculateNextSelectedDay(
  fromDate: Date,
  selectedDays: DayOfWeek[]
): Date {
  if (!selectedDays || selectedDays.length === 0) {
    // Fallback to daily if no days selected
    const next = new Date(fromDate);
    next.setDate(next.getDate() + 1);
    return next;
  }

  // Convert selected days to day numbers
  const selectedDayNums = selectedDays.map((day) => DAY_MAP[day]);

  // Start checking from tomorrow, keeping the same time
  const checkDate = new Date(fromDate);
  checkDate.setDate(checkDate.getDate() + 1);

  // Find the next matching day (max 7 days ahead)
  for (let i = 0; i < 7; i++) {
    const dayNum = checkDate.getDay();
    if (selectedDayNums.includes(dayNum)) {
      return checkDate;
    }
    checkDate.setDate(checkDate.getDate() + 1);
  }

  // Should never reach here, but fallback to tomorrow
  const fallback = new Date(fromDate);
  fallback.setDate(fallback.getDate() + 1);
  return fallback;
}

/**
 * Check if a notification schedule is due to be sent
 * A schedule is due if:
 * - It's enabled
 * - nextScheduledAt is set and is <= current time
 * - OR nextScheduledAt is not set (first run)
 */
export function isScheduleDue(
  schedule: NotificationSchedule,
  now: Date = new Date()
): boolean {
  if (!schedule.enabled) {
    return false;
  }

  if (!schedule.nextScheduledAt) {
    // First run - check if current time matches preferred time on valid day
    return isValidSendTime(schedule, now);
  }

  const scheduledTime = schedule.nextScheduledAt.toDate();
  return scheduledTime <= now;
}

/**
 * Check if current time is valid for sending (for first-run scenarios)
 * Since the Flutter app always sets nextScheduledAt, this is mainly a fallback
 * For first run without nextScheduledAt, we allow sending immediately
 */
function isValidSendTime(
  _schedule: NotificationSchedule,
  _now: Date
): boolean {
  // If nextScheduledAt is not set, allow the first send
  // The Flutter app should always set nextScheduledAt, so this is a fallback
  return true;
}

/**
 * Create a Firestore Timestamp from a Date
 */
export function toTimestamp(date: Date): Timestamp {
  return Timestamp.fromDate(date);
}
