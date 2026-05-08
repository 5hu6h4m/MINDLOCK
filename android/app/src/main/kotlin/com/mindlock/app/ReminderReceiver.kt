package com.mindlock.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // 1. Handle Boot Completed
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("MINDLOCK", "Boot completed - System started")
            return
        }

        // 2. Handle Alarm Trigger
        val title = intent.getStringExtra("title") ?: "MINDLOCK Reminder"
        val body = intent.getStringExtra("body") ?: "Time to stay focused!"
        val id = intent.getIntExtra("id", 101)
        val priority = intent.getIntExtra("priority", 1)
        val tone = intent.getStringExtra("tone") ?: "default"
        val repeatInterval = intent.getIntExtra("repeatInterval", 0)
        val remainingRepeats = intent.getIntExtra("remainingRepeats", 0)

        Log.d("MINDLOCK", "ALARM FIRED: $title (Repeats left: $remainingRepeats)")

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "MINDLOCK_URGENT_CHANNEL_$tone"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "MindLock Alerts ($tone)", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Reminders with $tone tone"
                enableLights(true)
                enableVibration(true)
                setBypassDnd(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                
                val soundUri = when (tone) {
                    "soft" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    "urgent" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                    else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                }
                
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(if (tone == "soft") AudioAttributes.USAGE_NOTIFICATION else AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setSound(soundUri, audioAttributes)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Handle Repeat Scheduling
        if (remainingRepeats > 0 && repeatInterval > 0) {
            val nextTime = System.currentTimeMillis() + (repeatInterval * 60 * 1000)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val nextIntent = Intent(context, ReminderReceiver::class.java).apply {
                putExtras(intent.extras ?: android.os.Bundle())
                putExtra("remainingRepeats", remainingRepeats - 1)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context, id, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextTime, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, nextTime, pendingIntent)
            }
            Log.d("MINDLOCK", "Auto-scheduled NEXT repeat in $repeatInterval min")
        }

        // Open App
        val alarmIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("route", "/alarm")
            putExtra("reminder_id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("priority", priority)
        }
        
        try {
            context.startActivity(alarmIntent)
        } catch (e: Exception) {
            Log.e("MINDLOCK", "Activity start failed: ${e.message}")
        }

        val pendingIntent = PendingIntent.getActivity(
            context, id, alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(priority >= 2)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        notificationManager.notify(id, builder.build())
    }
}
