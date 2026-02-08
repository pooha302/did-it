package com.pooha302.didit

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.graphics.Color
import android.net.Uri
import android.util.Log

class DidItRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return DidItRemoteViewsFactory(this.applicationContext)
    }
}

class DidItRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var actionIds: List<String> = listOf()

    override fun onCreate() {
        // Initial load
        onDataSetChanged()
    }

    override fun onDataSetChanged() {
        // IMPORTANT: The Flutter 'home_widget' plugin saves data to "HomeWidgetPreferences".
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val idsString = prefs.getString("action_ids", "") ?: ""
        
        Log.d("DidItWidget", "Factory: Loading IDs from prefs: $idsString")
        
        if (idsString.isNotEmpty()) {
            actionIds = idsString.split(",")
        } else {
            // Fallback
            actionIds = listOf() 
        }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = actionIds.size

    override fun getViewAt(position: Int): RemoteViews {
        // Return loading or empty view if index out of bounds
        if (position >= actionIds.size) return RemoteViews(context.packageName, R.layout.widget_item)

        val views = RemoteViews(context.packageName, R.layout.widget_item)
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        
        val id = actionIds[position]
        val title = prefs.getString("title_$id", "Action")
        val count = prefs.getInt("count_$id", 0)
        val colorHex = prefs.getString("color_$id", "#38BDF8") ?: "#38BDF8"

        views.setTextViewText(R.id.widget_title, title)
        views.setTextViewText(R.id.widget_count, count.toString())
        
        try {
            val color = Color.parseColor(colorHex)
            views.setInt(R.id.widget_line, "setColorFilter", color)
        } catch (e: Exception) {}

        // Fill-in Intent for clicks
        val fillInIntent = Intent().apply {
            data = Uri.parse("didit://increment?id=$id")
        }
        // Set on the root container of the item
        views.setOnClickFillInIntent(R.id.widget_root_item, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
