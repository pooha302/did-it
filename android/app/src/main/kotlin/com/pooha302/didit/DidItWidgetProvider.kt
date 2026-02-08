package com.pooha302.didit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.graphics.Color
import android.net.Uri
import android.util.Log
import android.app.PendingIntent
import android.content.Intent
import com.pooha302.didit.R
import android.view.View
import android.widget.Toast

class DidItWidgetProvider : HomeWidgetProvider() {
    
    companion object {
        fun updateWidget(
            context: Context, 
            appWidgetManager: AppWidgetManager, 
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            val idsString = prefs.getString("action_ids", "") ?: ""
            val idList = if (idsString.isNotEmpty()) idsString.split(",") else listOf()
            val selectedId = prefs.getString("selected_id_$appWidgetId", null)
            
            if (selectedId == null) {
                 views.setTextViewText(R.id.widget_title, "Setup Required")
                 views.setTextViewText(R.id.widget_count, "--")
                 appWidgetManager.updateAppWidget(appWidgetId, views)
                 return
            }
            
            if (!idList.contains(selectedId)) {
                views.setTextViewText(R.id.widget_title, "Removed")
                views.setTextViewText(R.id.widget_count, "--")
                views.setViewVisibility(R.id.widget_goal, View.GONE)
                views.setInt(R.id.widget_line, "setColorFilter", Color.DKGRAY)
                
                val toastIntent = Intent(context, DidItWidgetProvider::class.java).apply {
                    action = "com.pooha302.didit.ACTION_TOAST_DELETED"
                }
                val pendingToast = PendingIntent.getBroadcast(
                    context, 
                    appWidgetId, 
                    toastIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingToast)
                
                appWidgetManager.updateAppWidget(appWidgetId, views)
                return
            }

            val actionId = selectedId
            val title = prefs.getString("title_$actionId", "Did it") ?: "Did it"
            val count = prefs.getInt("count_$actionId", 0)
            val goal = prefs.getInt("goal_$actionId", 0)
            val colorHex = prefs.getString("color_$actionId", "#38BDF8") ?: "#38BDF8"
            
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_count, count.toString())
            
            if (goal > 0) {
                views.setTextViewText(R.id.widget_goal, "/ $goal")
                views.setViewVisibility(R.id.widget_goal, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_goal, View.GONE)
            }
            
            try {
                val color = Color.parseColor(colorHex)
                views.setInt(R.id.widget_line, "setColorFilter", color)
            } catch (e: Exception) {}

            try {
                val intent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
                    action = "es.antonborri.home_widget.action.BACKGROUND"
                    data = Uri.parse("didit://increment?id=$actionId")
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context, 
                    appWidgetId, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            } catch (e: Exception) {
                Log.e("DidItWidget", "Incr setup failed", e)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == "com.pooha302.didit.ACTION_TOAST_DELETED") {
            Toast.makeText(context, "Action unavailable. Please remove widget.", Toast.LENGTH_SHORT).show()
        }
    }
}
