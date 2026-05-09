package com.mindlock.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log
import android.provider.Settings
import android.os.Build
import android.app.NotificationManager as AndroidNotificationManager

class MissionForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "Mission_service"
        const val NOTIFICATION_ID = 1000
        
        var missionEndTime = 0L
        var isMissionTimerActive = false
    }

    override fun onCreate() {
        super.onCreate()
        try {
            createNotificationChannel()
            startForeground(NOTIFICATION_ID, buildNotification("Mission Started", "Stay focused!"))
        } catch (e: Exception) {
            Log.e("MINDLOCK", "Mission Service creation failed: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "START_MISSION_TIMER") {
            val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
            val storedEndTime = prefs.getLong("mission_end_time", 0L)
            
            if (storedEndTime > System.currentTimeMillis()) {
                missionEndTime = storedEndTime
                isMissionTimerActive = true
                startTimerCheck()
            } else {
                val seconds = intent.getIntExtra("seconds", 0)
                if (seconds > 0) {
                    missionEndTime = System.currentTimeMillis() + (seconds * 1000)
                    isMissionTimerActive = true
                    startTimerCheck()
                }
            }
        } else if (action == "STOP_MISSION_TIMER") {
            isMissionTimerActive = false
            val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("mission_active", false).apply()
            stopSelf()
        }
        return START_STICKY
    }

    private var timerRunnable: Runnable? = null
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    private fun startTimerCheck() {
        if (timerRunnable != null) return // Already running
        
        Log.d("MINDLOCK", "Service: Starting timer loop")
        timerRunnable = object : Runnable {
            override fun run() {
                if (!isMissionTimerActive) {
                    Log.d("MINDLOCK", "Service: Timer loop stopped (active=false)")
                    timerRunnable = null
                    return
                }
                
                val now = System.currentTimeMillis()
                if (now >= missionEndTime) {
                    Log.d("MINDLOCK", "Service: Mission Completed (Time's up)")
                    isMissionTimerActive = false
                    
                    // Turn off DND
                    try {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (nm.isNotificationPolicyAccessGranted) {
                                nm.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
                                Log.d("MINDLOCK", "Service: DND turned OFF")
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("MINDLOCK", "Service: Failed to turn off DND: ${e.message}")
                    }

                    val completeIntent = Intent("com.MindLock.MISSION_COMPLETED")
                    sendBroadcast(completeIntent)
                    
                    updateNotification("Mission Completed!", "Great focus session.")
                    timerRunnable = null
                    stopSelf()
                    return
                }
                
                val remainingMs = missionEndTime - now
                val minutes = (remainingMs / 1000) / 60
                val seconds = (remainingMs / 1000) % 60
                val timeStr = String.format("%02d:%02d", minutes, seconds)
                
                updateNotification("Active Mission", "$timeStr remaining")
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(timerRunnable!!)
    }

    private fun updateNotification(title: String, text: String) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification(title, text))
        } catch (e: Exception) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(title: String, text: String): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mission Control",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Live mission countdown timer"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}
