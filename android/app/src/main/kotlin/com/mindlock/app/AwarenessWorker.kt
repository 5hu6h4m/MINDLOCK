package com.mindlock.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.*

class AwarenessWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        val stats = getTopDistraction()
        if (stats != null) {
            showNotification(stats.first, stats.second)
        }
        return Result.success()
    }

    private fun getTopDistraction(): Pair<String, Long>? {
        val usageStatsManager = applicationContext.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (3 * 60 * 60 * 1000) // Last 3 hours

        val stats = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        var topPkg = ""
        var maxTime = 0L

        for (pkg in stats.keys) {
            // Filter out system apps and MindLock
            if (pkg == applicationContext.packageName || pkg.contains("android.settings") || pkg.contains("launcher")) continue
            
            val totalTime = stats[pkg]?.totalTimeInForeground ?: 0L
            if (totalTime > maxTime) {
                maxTime = totalTime
                topPkg = pkg
            }
        }

        if (topPkg.isEmpty() || maxTime < 5 * 60 * 1000) return null // Less than 5 mins is fine

        val appName = topPkg.split(".").last().uppercase()
        return Pair(appName, maxTime / 60000) // Name and Minutes
    }

    private fun showNotification(appName: String, minutes: Long) {
        val channelId = "AWARENESS_CHANNEL"
        val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Awareness Pulse", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Periodic awareness nudges to keep you focused."
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(applicationContext, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(applicationContext, 0, intent, PendingIntent.FLAG_IMMUTABLE)

        val message = when {
            minutes > 60 -> "⚠️ HIGH DISTRACTION: You've spent ${minutes}m on $appName recently. Time to lock in! 🦾"
            minutes > 30 -> "🔔 FOCUS CHECK: $appName has taken ${minutes}m of your time. Still on track?"
            else -> "📊 Awareness Pulse: You've used $appName for ${minutes}m. Stay disciplined! 🦾"
        }

        val notification = NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(R.drawable.launch_background) // Use app icon
            .setContentTitle("MINDLOCK Awareness Pulse")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false) // Doesn't disappear on click
            .setOngoing(true)    // Harder to dismiss
            .build()

        notificationManager.notify(999, notification)
    }
}
