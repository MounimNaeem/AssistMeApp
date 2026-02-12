package com.example.assist_me_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*

class TodayEventsWidget : AppWidgetProvider() {

    companion object {
        private const val TAG = "TodayEventsWidget"
        const val ACTION_PREV_DAY = "com.example.assist_me_app.ACTION_PREV_DAY"
        const val ACTION_NEXT_DAY = "com.example.assist_me_app.ACTION_NEXT_DAY"
        const val ACTION_TODAY = "com.example.assist_me_app.ACTION_TODAY"
        const val ACTION_ITEM_CLICK = "com.example.assist_me_app.ACTION_ITEM_CLICK"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TodayEventsWidget::class.java)
            )

            // Notify data changed for all widgets
            appWidgetManager.notifyAppWidgetViewDataChanged(ids, R.id.events_list)

            // Send update broadcast
            val intent = Intent(context, TodayEventsWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive: ${intent.action}")

        when (intent.action) {
            ACTION_PREV_DAY -> navigateDay(context, -1)
            ACTION_NEXT_DAY -> navigateDay(context, 1)
            ACTION_TODAY -> goToToday(context)
            ACTION_ITEM_CLICK -> openApp(context)
        }
    }

    private fun navigateDay(context: Context, direction: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val currentOffset = prefs.getInt("day_offset", 0)
        val newOffset = (currentOffset + direction).coerceIn(-7, 7)

        prefs.edit().putInt("day_offset", newOffset).apply()
        Log.d(TAG, "Navigate day: $currentOffset -> $newOffset")

        updateAllWidgets(context)
    }

    private fun goToToday(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putInt("day_offset", 0).apply()
        Log.d(TAG, "Go to today")

        updateAllWidgets(context)
    }

    private fun openApp(context: Context) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening app", e)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            Log.d(TAG, "Updating widget $appWidgetId")

            val views = RemoteViews(context.packageName, R.layout.today_events_widget)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val dayOffset = prefs.getInt("day_offset", 0)

            // Calculate display date
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, dayOffset)

            // Set date display
            val dateFormat = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
            views.setTextViewText(R.id.widget_date, dateFormat.format(calendar.time))

            // Set day name
            val dayName = when (dayOffset) {
                0 -> "TODAY"
                1 -> "TOMORROW"
                -1 -> "YESTERDAY"
                else -> SimpleDateFormat("EEEE", Locale.getDefault())
                    .format(calendar.time).uppercase(Locale.getDefault())
            }
            views.setTextViewText(R.id.widget_day_name, dayName)

            // Show/hide Today button
            views.setViewVisibility(
                R.id.footer_container,
                if (dayOffset != 0) View.VISIBLE else View.GONE
            )

            // Set up ListView with RemoteViewsService
            // Use unique URI for each widget to ensure proper refresh
            val serviceIntent = Intent(context, EventsWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra("day_offset", dayOffset)
                data = Uri.parse("widget://$appWidgetId/$dayOffset/${System.currentTimeMillis()}")
            }
            views.setRemoteAdapter(R.id.events_list, serviceIntent)
            views.setEmptyView(R.id.events_list, R.id.no_events_text)

            // Set up click listener template for list items
            val itemClickIntent = Intent(context, TodayEventsWidget::class.java).apply {
                action = ACTION_ITEM_CLICK
            }
            val itemClickPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                itemClickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.events_list, itemClickPendingIntent)

            // Previous day button
            val prevIntent = Intent(context, TodayEventsWidget::class.java).apply {
                action = ACTION_PREV_DAY
            }
            views.setOnClickPendingIntent(
                R.id.btn_prev_day,
                PendingIntent.getBroadcast(
                    context, 1, prevIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            // Next day button
            val nextIntent = Intent(context, TodayEventsWidget::class.java).apply {
                action = ACTION_NEXT_DAY
            }
            views.setOnClickPendingIntent(
                R.id.btn_next_day,
                PendingIntent.getBroadcast(
                    context, 2, nextIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            // Today button
            val todayIntent = Intent(context, TodayEventsWidget::class.java).apply {
                action = ACTION_TODAY
            }
            views.setOnClickPendingIntent(
                R.id.btn_today,
                PendingIntent.getBroadcast(
                    context, 3, todayIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            // Click on header opens app
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context, 4, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_date, openAppPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_day_name, openAppPendingIntent)

            // Update the widget first
            appWidgetManager.updateAppWidget(appWidgetId, views)

            // Then notify adapter to refresh data
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.events_list)

            Log.d(TAG, "Widget $appWidgetId updated successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget $appWidgetId", e)
        }
    }
}
