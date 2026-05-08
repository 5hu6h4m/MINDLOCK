package com.mindlock.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class ForegroundReminderService : Service() {

    companion object {
        const val CHANNEL_ID = "MindLock_service"
        const val NOTIFICATION_ID = 999
        
        var sleepTimerEndTime = 0L
        var isSleepTimerActive = false
    }

    override fun onCreate() {
        super.onCreate()
        try {
            createNotificationChannel()
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            Log.e("MINDLOCK", "Service creation failed: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "START_SLEEP_TIMER") {
            val seconds = intent.getIntExtra("seconds", 0)
            if (seconds > 0) {
                sleepTimerEndTime = System.currentTimeMillis() + (seconds * 1000)
                isSleepTimerActive = true
                startTimerCheck()
            }
        } else if (action == "STOP_SLEEP_TIMER") {
            isSleepTimerActive = false
        }
        return START_STICKY
    }

    private fun startTimerCheck() {
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        val runnable = object : Runnable {
            override fun run() {
                if (!isSleepTimerActive) return
                
                val now = System.currentTimeMillis()
                if (now >= sleepTimerEndTime) {
                    executeSleepKill()
                    isSleepTimerActive = false
                    return
                }
                
                val remainingMs = sleepTimerEndTime - now
                val minutes = (remainingMs / 1000) / 60
                val seconds = (remainingMs / 1000) % 60
                val timeStr = String.format("%02d:%02d", minutes, seconds)
                
                updateNotification("Brutal Sleep Mode", "Shutting down in $timeStr")
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(runnable)
    }

    private fun executeSleepKill() {
        try {
            // 1. Brutal Audio Kill
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            audioManager.requestAudioFocus(null, android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            
            val eventDown = android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_MEDIA_PAUSE)
            val eventUp = android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, android.view.KeyEvent.KEYCODE_MEDIA_PAUSE)
            audioManager.dispatchMediaKeyEvent(eventDown)
            audioManager.dispatchMediaKeyEvent(eventUp)

            // 2. Go Home (Simulate clearing recents focus)
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)

            // 3. Force Lock Screen (Direct from Service)
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, MindLockAdminReceiver::class.java)
            
            if (dpm.isAdminActive(adminComponent)) {
                // Short delay to ensure Home intent settles
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    try {
                        dpm.lockNow()
                        Log.d("MINDLOCK", "Screen locked successfully")
                    } catch (e: Exception) {
                        Log.e("MINDLOCK", "Lock failed: ${e.message}")
                    }
                }, 500)
            } else {
                Log.w("MINDLOCK", "Admin not active. Launching MainActivity to request.")
                val mainIntent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra("request_admin", true)
                }
                startActivity(mainIntent)
            }

            updateNotification("Sleep Secured", "Phone locked. Goodnight.")
        } catch (e: Exception) {
            Log.e("MINDLOCK", "Brutal Sleep Kill failed: ${e.message}")
        }
    }

    private fun updateNotification(title: String, text: String) {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification(title, text))
        } catch (e: Exception) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(title: String = "MindLock", text: String = "Engine Active"): Notification {
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
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
    }

    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MindLock System",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Background core service"
                setShowBadge(false)
            }
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}
