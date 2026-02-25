package com.mounim.assistme

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class DailyFitnessWidget : AppWidgetProvider() {

    companion object {
        private const val TAG = "DailyFitnessWidget"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, DailyFitnessWidget::class.java)
            )

            // Directly update all widgets (no broadcast to prevent infinite loop)
            val widget = DailyFitnessWidget()
            for (id in ids) {
                widget.updateAppWidget(context, appWidgetManager, id)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    // No need to override onReceive - the default implementation handles updates correctly

    internal fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            Log.d(TAG, "Updating widget $appWidgetId")

            val views = RemoteViews(context.packageName, R.layout.daily_fitness_widget)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Get data from shared preferences
            val totalCalories = prefs.getInt("total_calories", 0)
            val gymStreak = prefs.getInt("gym_streak", 0)
            val hasLoggedToday = prefs.getBoolean("has_logged_today", false)

            Log.d(TAG, "Widget data - Calories: $totalCalories, Streak: $gymStreak, LoggedToday: $hasLoggedToday")

            // Update calories text
            views.setTextViewText(R.id.calories_value, "$totalCalories kcal")

            // Update streak text
            views.setTextViewText(R.id.streak_value, "$gymStreak days")

            // Show/hide reminder based on whether user has logged today
            if (hasLoggedToday) {
                views.setViewVisibility(R.id.reminder_text, View.GONE)
            } else {
                views.setViewVisibility(R.id.reminder_text, View.VISIBLE)
                views.setTextViewText(R.id.reminder_text, "⚠️ Log gym session!")
            }

            // Set up click listener to open app
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context, appWidgetId, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)

            Log.d(TAG, "Widget $appWidgetId updated successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget $appWidgetId", e)
        }
    }
}
