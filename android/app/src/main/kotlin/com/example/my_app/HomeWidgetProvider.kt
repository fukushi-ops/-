package com.example.my_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.time.temporal.ChronoUnit
import java.util.Calendar

class HomeWidgetProvider : BaseHomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(
                context,
                appWidgetManager,
                widgetId,
                appWidgetManager.getAppWidgetOptions(widgetId),
                widgetData
            )
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(
            context,
            appWidgetManager,
            appWidgetId,
            newOptions,
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        )
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        options: Bundle,
        widgetData: SharedPreferences
    ) {
        val isMedium = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
            110
        ) >= 220
        val views = RemoteViews(
            context.packageName,
            if (isMedium) R.layout.home_widget_medium else R.layout.home_widget_layout
        )
        val tasks = readTasks(widgetData)
        val lessonsText = buildLessonsText(widgetData)
        val tasksText = buildTasksText(tasks)
        if (isMedium) {
            views.setTextViewText(R.id.widget_medium_lessons, lessonsText)
            views.setTextViewText(R.id.widget_medium_tasks, tasksText)
        } else {
            views.setTextViewText(R.id.widget_text, "$lessonsText\n$tasksText")
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun buildLessonsText(widgetData: SharedPreferences): String {
        val schedule = try {
            JSONObject(widgetData.getString("widget_lessons", "{}") ?: "{}")
        } catch (error: JSONException) {
            Log.e(TAG, "Could not read timetable data for widget", error)
            JSONObject()
        }
        val weekday = when (Calendar.getInstance().get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> "月"
            Calendar.TUESDAY -> "火"
            Calendar.WEDNESDAY -> "水"
            Calendar.THURSDAY -> "木"
            Calendar.FRIDAY -> "金"
            Calendar.SATURDAY -> "土"
            else -> "日"
        }
        val lessons = schedule.optJSONArray(weekday) ?: JSONArray()
        val lessonLines = (0 until minOf(6, lessons.length())).mapNotNull { index ->
            lessons.optJSONObject(index)?.let { lesson ->
                "${index + 1}限 ${lesson.optString("name")}"
            }
        }
        return (listOf("今日の授業") + lessonLines.ifEmpty { listOf("授業なし") })
            .joinToString("\n")
    }

    private fun buildTasksText(tasks: List<WidgetTask>): String {
        val taskLines = tasks.take(2).map { task ->
            val remaining = when {
                task.daysRemaining > 0 -> "あと${task.daysRemaining}日"
                task.daysRemaining == 0L -> "今日まで"
                else -> "期限超過${-task.daysRemaining}日"
            }
            "$remaining ${task.title}"
        }
        return (listOf("未提出課題") + taskLines.ifEmpty { listOf("課題なし") })
            .joinToString("\n")
    }

    private fun readTasks(widgetData: SharedPreferences): List<WidgetTask> {
        val taskArray = try {
            JSONArray(widgetData.getString("widget_tasks", "[]") ?: "[]")
        } catch (error: JSONException) {
            Log.e(TAG, "Could not read assignment data for widget", error)
            return emptyList()
        }
        val today = LocalDate.now()
        val tasks = mutableListOf<WidgetTask>()
        for (index in 0 until taskArray.length()) {
            val task = taskArray.optJSONObject(index) ?: continue
            val deadline = try {
                LocalDate.parse(task.optString("deadline").take(10))
            } catch (error: DateTimeParseException) {
                Log.e(TAG, "Skipping widget assignment with an invalid deadline", error)
                continue
            }
            tasks.add(
                WidgetTask(
                    title = task.optString("title"),
                    deadline = deadline,
                    daysRemaining = ChronoUnit.DAYS.between(today, deadline)
                )
            )
        }
        return tasks.sortedBy { it.deadline }
    }

    private data class WidgetTask(
        val title: String,
        val deadline: LocalDate,
        val daysRemaining: Long
    )

    private companion object {
        const val TAG = "HomeWidgetProvider"
    }
}
