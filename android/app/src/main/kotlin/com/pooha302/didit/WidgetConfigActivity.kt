package com.pooha302.didit

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView

class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set the result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if the user presses the back button.
        setResult(RESULT_CANCELED)

        setContentView(R.layout.activity_widget_config)

        // Find the widget id from the intent.
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        // If this activity was started with an intent without an app widget ID, finish with an error.
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        // Load Action List
        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val idsString = prefs.getString("action_ids", "") ?: ""
        val actionIds = if (idsString.isNotEmpty()) idsString.split(",") else listOf()

        if (actionIds.isEmpty()) {
            // No actions available, just finish (maybe show a toast?)
            finish()
            return
        }

        val titles = actionIds.map { id ->
            prefs.getString("title_$id", id) ?: id
        }

        val listView = findViewById<ListView>(R.id.action_list_view)
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, titles) // Use standard simple item
        listView.adapter = adapter

        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedActionId = actionIds[position]
            saveActionPref(this, appWidgetId, selectedActionId)

            // Make sure we pass back the original appWidgetId
            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
    
    // Save the selected Action ID for this specific widget instance
    private fun saveActionPref(context: Context, appWidgetId: Int, actionId: String) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        prefs.edit().putString("selected_id_$appWidgetId", actionId).apply()
        
        // Push initial update
        val appWidgetManager = AppWidgetManager.getInstance(context)
        DidItWidgetProvider.updateWidget(context, appWidgetManager, appWidgetId)
    }
}
