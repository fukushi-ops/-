package com.example.my_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(
                context.packageName,
                R.layout.home_widget_layout
            )
            val text = widgetData.getString("widget_text", "ここに表示")
            views.setTextViewText(R.id.widget_text, text)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}