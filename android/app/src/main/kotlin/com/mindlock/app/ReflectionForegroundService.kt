package com.mindlock.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ReflectionForegroundService : Service() {
    private val CHANNEL_ID = "REFLECTION_SERVICE_CHANNEL"
    private val NOTIFICATION_ID = 1002

    companion object {
        var isActive = false
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        isActive = true
        
        // Notify MindLockAccessibilityService that reflection is active
        MindLockAccessibilityService.isReflectionActive = true
        val updateIntent = Intent("com.mindlock.UPDATE_STATE").apply {
            putExtra("reflection_active", true)
        }
        sendBroadcast(updateIntent)
        
        // Persist state for reboot recovery
        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("is_reflection_active", true).apply()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("MINDLOCK: Nightly Reflection")
            .setContentText("Your phone is locked until you complete your daily summary. 🦾")
            .setSmallIcon(R.drawable.launch_background)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Launch the Reflection Overlay Activity or tell Flutter to show full-screen
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("route", "/reflection/overlay")
        }
        startActivity(launchIntent)

        return START_STICKY
    }

    override fun onDestroy() {
        isActive = false
        MindLockAccessibilityService.isReflectionActive = false
        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("is_reflection_active", false).apply()
        
        // Notify MindLockAccessibilityService immediately
        val updateIntent = Intent("com.mindlock.UPDATE_STATE").apply {
            putExtra("reflection_active", false)
        }
        sendBroadcast(updateIntent)
        
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Daily Reflection Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
