# AssistMe - Firebase Cloud Functions

Scheduled push notification system for the AssistMe app.

## Setup

### Prerequisites
- Node.js 18+
- Firebase CLI (`npm install -g firebase-tools`)
- Firebase project with Blaze plan (required for scheduled functions)

### Installation

```bash
cd functions
npm install
```

### Firebase Configuration

1. Login to Firebase:
```bash
firebase login
```

2. Initialize Firebase in the project root (if not already done):
```bash
firebase init functions
```

3. Ensure `firebase.json` exists in the project root with:
```json
{
  "functions": {
    "source": "functions",
    "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
  }
}
```

## Deployment

### Build and Deploy
```bash
npm run deploy
```

### Deploy with specific project
```bash
firebase deploy --only functions --project YOUR_PROJECT_ID
```

## Local Development

### Run emulator
```bash
npm run serve
```

### View logs
```bash
npm run logs
```

## Function Details

### `processScheduledNotifications`
- **Schedule**: Every 5 minutes
- **Timezone**: Asia/Kolkata (configurable in index.ts)
- **Memory**: 256MB

**Flow:**
1. Query enabled notification schedules from `notification_schedules` collection
2. Check which schedules are due (`nextScheduledAt <= now`)
3. Get all users with FCM tokens from `users` collection
4. Send push notifications via FCM
5. Update `lastSentAt` and `nextScheduledAt` in Firestore
6. Clean up invalid FCM tokens

## Firestore Collections

### `notification_schedules/{schedule_id}`
| Field | Type | Description |
|-------|------|-------------|
| id | string | Schedule identifier |
| title | string | Notification title |
| body | string | Notification body |
| enabled | boolean | Whether schedule is active |
| frequencyType | string | 'days', 'weeks', or 'months' |
| frequencyValue | number | Frequency interval |
| preferredTime | string | Time in "HH:mm" format |
| lastSentAt | timestamp | Last notification sent time |
| nextScheduledAt | timestamp | Next scheduled send time |
| createdAt | timestamp | Creation time |
| updatedAt | timestamp | Last update time |

### `users/{user_id}`
| Field | Type | Description |
|-------|------|-------------|
| fcmToken | string/null | FCM device token |

## Timezone Configuration

Update the timezone in `src/index.ts`:

```typescript
export const processScheduledNotifications = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "America/New_York", // Change this
    // ...
  },
```

## Troubleshooting

### View function logs
```bash
firebase functions:log --only processScheduledNotifications
```

### Test locally
```bash
npm run serve
# In another terminal, trigger the function manually via emulator UI
```
