package com.mindlock.app

import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.KeyEvent
import android.app.AlarmManager
import android.app.PendingIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.MindLock/native"
    private var flutterChannel: MethodChannel? = null

    companion object {
        var instance: MainActivity? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
    }

    fun lockDevice() {
        try {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, MindLockAdminReceiver::class.java)
            if (dpm.isAdminActive(adminComponent)) {
                dpm.lockNow()
            } else {
                Log.w("MINDLOCK", "Device Admin not active. Cannot lock.")
                // Launch settings to enable admin
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "MindLock needs this to lock your screen during sleep sessions.")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            }
        } catch (e: Exception) {
            Log.e("MINDLOCK", "Lock failed: ${e.message}")
        }
    }

    private val missionEscapeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.MindLock.MISSION_ESCAPE_ATTEMPT") {
                val pkg = intent.getStringExtra("package") ?: ""
                flutterChannel?.invokeMethod("onMissionEscapeAttempt", mapOf("package" to pkg))
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.getBooleanExtra("request_admin", false)) {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, MindLockAdminReceiver::class.java)
            if (!dpm.isAdminActive(adminComponent)) {
                val adminIntent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "MindLock needs this to lock your screen during sleep sessions.")
                }
                startActivity(adminIntent)
            }
        }
        val route = intent.getStringExtra("route")
        if (route == "/alarm") {
            val id = intent.getIntExtra("reminder_id", 0)
            val title = intent.getStringExtra("title") ?: ""
            val body = intent.getStringExtra("body") ?: ""
            val priority = intent.getIntExtra("priority", 1)
            
            val data = mapOf(
                "id" to id,
                "title" to title,
                "body" to body,
                "priority" to priority
            )
            flutterChannel?.invokeMethod("onNativeAlarm", data)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        flutterChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                    "lockScreen" -> {
                        lockDevice()
                        result.success(null)
                    }

                    "goHome" -> {
                        val intent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(null)
                    }

                    "pauseMedia" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val eventDown = KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE)
                        val eventUp = KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE)
                        audioManager.dispatchMediaKeyEvent(eventDown)
                        audioManager.dispatchMediaKeyEvent(eventUp)
                        result.success(null)
                    }

                    "isDNDPermissionGranted" -> {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(notificationManager.isNotificationPolicyAccessGranted)
                        } else {
                            result.success(true)
                        }
                    }

                    "setDeepSleepMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        MindLockAccessibilityService.isDeepSleepActive = enabled
                        if (enabled) {
                            MindLockAccessibilityService.instance?.navigateHome()
                        }
                        result.success(true)
                    }

                    "startSleepTimerSeconds" -> {
                        val seconds = call.argument<Int>("seconds") ?: 0
                        val intent = Intent(this, ForegroundReminderService::class.java).apply {
                            action = "START_SLEEP_TIMER"
                            putExtra("seconds", seconds)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }

                    "stopSleepTimer" -> {
                        val intent = Intent(this, ForegroundReminderService::class.java).apply {
                            action = "STOP_SLEEP_TIMER"
                        }
                        startService(intent)
                        result.success(true)
                    }

                    "getRemainingSleepTime" -> {
                        if (ForegroundReminderService.isSleepTimerActive) {
                            val remainingMs = ForegroundReminderService.sleepTimerEndTime - System.currentTimeMillis()
                            result.success(remainingMs / 1000)
                        } else {
                            result.success(0L)
                        }
                    }

                    "setNoScrollMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        MindLockAccessibilityService.isNoScrollActive = enabled
                        result.success(true)
                    }

                    "isNoScrollActive" -> {
                        result.success(MindLockAccessibilityService.isNoScrollActive)
                    }

                    "scheduleNativeReminder" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val timeMs = call.argument<Long>("timeMs") ?: 0L
                        val priority = call.argument<Int>("priority") ?: 1
                        val tone = call.argument<String>("tone") ?: "default"
                        val repeatInterval = call.argument<Int>("repeatIntervalMinutes") ?: 0
                        val remainingRepeats = call.argument<Int>("remainingRepeats") ?: 0

                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, ReminderReceiver::class.java).apply {
                            putExtra("id", id)
                            putExtra("title", title)
                            putExtra("body", body)
                            putExtra("priority", priority)
                            putExtra("tone", tone)
                            putExtra("repeatInterval", repeatInterval)
                            putExtra("remainingRepeats", remainingRepeats)
                        }
                        
                        val pendingIntent = PendingIntent.getBroadcast(
                            this, id, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
                        } else {
                            alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
                        }
                        result.success(true)
                    }

                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        try {
            registerReceiver(missionEscapeReceiver, IntentFilter("com.MindLock.MISSION_ESCAPE_ATTEMPT"))
        } catch (e: Exception) {}
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(missionEscapeReceiver)
        } catch (e: Exception) {}
    }
}
