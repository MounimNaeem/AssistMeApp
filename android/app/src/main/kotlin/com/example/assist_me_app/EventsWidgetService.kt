package com.example.assist_me_app

import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

class EventsWidgetService : RemoteViewsService() {

    companion object {
        private const val TAG = "EventsWidgetService"
    }

    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        Log.d(TAG, "onGetViewFactory called")
        return EventsRemoteViewsFactory(applicationContext)
    }
}

class EventsRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    companion object {
        private const val TAG = "EventsViewFactory"
        private const val PREFS_NAME = "HomeWidgetPreferences"
    }

    private var events: MutableList<EventItem> = mutableListOf()

    data class EventItem(val title: String, val time: String, val color: Int)

    override fun onCreate() {
        Log.d(TAG, "onCreate called")
        loadEvents()
    }

    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged called")
        loadEvents()
    }

    private fun loadEvents() {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val dayOffset = prefs.getInt("day_offset", 0)

            // Calculate the date key based on offset
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, dayOffset)
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val dateKey = dateFormat.format(calendar.time)

            Log.d(TAG, "Loading events for date: $dateKey (offset: $dayOffset)")

            // Try date-specific key first
            var eventsJson = prefs.getString("events_$dateKey", null)

            // Fall back to today_events if date-specific is empty
            if (eventsJson.isNullOrEmpty() && dayOffset == 0) {
                eventsJson = prefs.getString("today_events", null)
                Log.d(TAG, "Using today_events fallback")
            }

            if (eventsJson.isNullOrEmpty()) {
                Log.d(TAG, "No events found for $dateKey")
                events.clear()
                return
            }

            Log.d(TAG, "Events JSON: $eventsJson")

            val jsonArray = JSONArray(eventsJson)
            val list = mutableListOf<EventItem>()

            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val event = EventItem(
                    title = obj.optString("title", "Untitled"),
                    time = obj.optString("time", ""),
                    color = obj.optInt("color", 0xFF2196F3.toInt())
                )
                list.add(event)
                Log.d(TAG, "Loaded event: ${event.title} at ${event.time}")
            }

            events.clear()
            events.addAll(list)
            Log.d(TAG, "Total events loaded: ${events.size}")

        } catch (e: Exception) {
            Log.e(TAG, "Error loading events", e)
            events.clear()
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called")
        events.clear()
    }

    override fun getCount(): Int {
        Log.d(TAG, "getCount: ${events.size}")
        return events.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        Log.d(TAG, "getViewAt($position)")

        val views = RemoteViews(context.packageName, R.layout.widget_event_item)

        if (position >= 0 && position < events.size) {
            val event = events[position]
            views.setTextViewText(R.id.event_title, event.title)
            views.setTextViewText(R.id.event_time, event.time)
            views.setInt(R.id.event_color_bar, "setBackgroundColor", event.color)

            // Set fill intent for item click
            val fillIntent = Intent()
            views.setOnClickFillInIntent(R.id.event_item_container, fillIntent)

            Log.d(TAG, "Rendered event at $position: ${event.title}")
        } else {
            Log.w(TAG, "Invalid position: $position, events size: ${events.size}")
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? {
        // Return null to use default loading view
        return null
    }

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
