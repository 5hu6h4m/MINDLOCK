package com.mindlock.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.*

object ReflectionScheduler {
    fun schedule(context: Context, hour: Int, minute: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReflectionAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, 1002, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            
            // If time is already past, schedule for tomorrow
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_MONTH, 1)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }
        Log.d("MINDLOCK", "ReflectionScheduler: Scheduled for $hour:$minute")
    }

    fun restore(context: Context) {
        val prefs = context.getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
        val hour = prefs.getInt("reflection_hour", 22)
        val minute = prefs.getInt("reflection_minute", 30)
        schedule(context, hour, minute)
    }
}
