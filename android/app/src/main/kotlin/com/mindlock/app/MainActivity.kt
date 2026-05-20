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
import android.widget.Toast
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.net.Uri
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import android.app.usage.UsageStatsManager
import androidx.work.*
import android.os.BatteryManager
import java.util.*
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.MindLock/native"
    private var flutterChannel: MethodChannel? = null
    private var lastBatteryUpdate = 0L
    private val updateHandler = Handler(Looper.getMainLooper())
    private var isPolling = false

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (isPolling) {
                flutterChannel?.invokeMethod("onBatteryInfoUpdate", getBatteryInfo())
                updateHandler.postDelayed(this, 500) // Poll every 500ms
            }
        }
    }

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
        } else if (route != null) {
            flutterChannel?.invokeMethod("onNativeNavigation", mapOf("route" to route))
        }
    }

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return
            
            when (intent.action) {
                Intent.ACTION_POWER_CONNECTED -> {
                    flutterChannel?.invokeMethod("onPowerConnected", getBatteryInfo())
                    startPolling()
                }
                Intent.ACTION_POWER_DISCONNECTED -> {
                    flutterChannel?.invokeMethod("onPowerDisconnected", null)
                    stopPolling()
                }
                Intent.ACTION_BATTERY_CHANGED -> {
                    // Still handle broadcast for status changes
                    val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                    if (status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL) {
                        if (!isPolling) startPolling()
                    } else {
                        stopPolling()
                    }
                }
            }
        }
    }

    private fun getBatteryInfo(): Map<String, Any> {
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = level * 100 / scale.toFloat()
        
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        
        val chargePlug = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
        val plugType = when (chargePlug) {
            BatteryManager.BATTERY_PLUGGED_AC -> "AC"
            BatteryManager.BATTERY_PLUGGED_USB -> "USB"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
            else -> "Unknown"
        }

        // Get current in microamperes and convert to milliamperes
        var currentNow = 0L
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentNow = bm.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
            // Some devices return microamperes, some milliamperes. 
            // Usually if it's > 10,000 it's microamperes.
            if (Math.abs(currentNow) > 10000) {
                currentNow /= 1000
            }
            // Positive value means charging, negative means discharging (on some devices it's inverted)
            // We'll return absolute value if charging
        }

        var remainingTime = -1L
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            remainingTime = bm.computeChargeTimeRemaining() // milliseconds
        }
        
        // If system estimation is valid (above 0 and below 24 hours), use it.
        // Otherwise, use our self-calibrating fallback.
        val isSystemEstimateValid = remainingTime > 0 && remainingTime < 1000 * 60 * 60 * 24

        // Self-Calibrating Fallback
        if (isCharging && !isSystemEstimateValid) {
            val absCurrent = Math.abs(currentNow).coerceAtLeast(1L)
            val remainingPct = (100.0 - batteryPct).coerceAtLeast(0.0)
            
            // Basic but reliable formula: (Remaining% of 5000mAh) / Current
            // Time (ms) = (remainingPct / 100) * (5000 / absCurrent) * 3600 * 1000
            val estimatedMs = (remainingPct * 50 * 3600000.0 / absCurrent).toLong()
            
            if (estimatedMs > 0) {
                remainingTime = estimatedMs
            }
        }

        return mapOf(
            "level" to batteryPct.toInt(),
            "isCharging" to isCharging,
            "plugType" to plugType,
            "currentNow" to Math.abs(currentNow).toInt(),
            "remainingTimeMs" to remainingTime
        )
    }

    private fun startPolling() {
        if (!isPolling) {
            isPolling = true
            updateHandler.post(pollRunnable)
        }
    }

    private fun stopPolling() {
        isPolling = false
        updateHandler.removeCallbacks(pollRunnable)
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

                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }

                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    }

                    "hasOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(Settings.canDrawOverlays(this))
                        } else {
                            result.success(true)
                        }
                    }

                    "openOverlaySettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "checkExactAlarmPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            result.success(alarmManager.canScheduleExactAlarms())
                        } else {
                            result.success(true)
                        }
                    }

                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "requestBatteryExemption" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "startMission" -> {
                        val blockedApps = call.argument<List<String>>("blockedApps")?.toSet() ?: emptySet()
                        val intensity = call.argument<String>("intensity") ?: "medium"
                        val seconds = call.argument<Int>("seconds") ?: 0
                        
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        val endTime = System.currentTimeMillis() + (seconds * 1000)
                        Log.d("MINDLOCK", "Starting mission: $seconds seconds, EndTime: $endTime")
                        
                        prefs.edit().putBoolean("mission_active", true)
                                    .putLong("mission_end_time", endTime)
                                    .putStringSet("mission_blocked_apps", blockedApps)
                                    .putString("mission_intensity", intensity)
                                    .commit() // Use commit() for synchronous saving
                        
                        MindLockAccessibilityService.isMissionActive = true
                        MindLockAccessibilityService.missionBlockedPackages = blockedApps
                        MindLockAccessibilityService.missionIntensity = intensity

                        // SECURE BROADCAST UPDATE
                        val intentUpdate = Intent("com.mindlock.UPDATE_STATE")
                        intentUpdate.putExtra("mission_active", true)
                        intentUpdate.setPackage(packageName)
                        sendBroadcast(intentUpdate)

                        // Start Foreground Timer
                        val intent = Intent(this, MissionForegroundService::class.java).apply {
                            action = "START_MISSION_TIMER"
                            putExtra("seconds", seconds)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        result.success(true)
                    }

                    "stopMission" -> {
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putBoolean("mission_active", false).apply()
                        
                        MindLockAccessibilityService.isMissionActive = false
                        MindLockAccessibilityService.missionBlockedPackages = emptySet()

                        // SECURE BROADCAST UPDATE
                        val intentUpdate = Intent("com.mindlock.UPDATE_STATE")
                        intentUpdate.putExtra("mission_active", false)
                        intentUpdate.setPackage(packageName)
                        sendBroadcast(intentUpdate)

                        // Stop Foreground Timer
                        val intent = Intent(this, MissionForegroundService::class.java).apply {
                            action = "STOP_MISSION_TIMER"
                        }
                        startService(intent)

                        result.success(true)
                    }

                    "getRemainingMissionTime" -> {
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        val isActive = prefs.getBoolean("mission_active", false)
                        val endTime = prefs.getLong("mission_end_time", 0L)
                        val now = System.currentTimeMillis()
                        
                        Log.d("MINDLOCK", "getRemainingMissionTime: active=$isActive, end=$endTime, now=$now")
                        
                        if (isActive && endTime > now) {
                            result.success((endTime - now) / 1000)
                        } else {
                            result.success(0L)
                        }
                    }

                    "getActiveMissionDetails" -> {
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        val isActive = prefs.getBoolean("mission_active", false)
                        if (isActive) {
                            val intensity = prefs.getString("mission_intensity", "medium")
                            val blockedApps = prefs.getStringSet("mission_blocked_apps", emptySet())?.toList() ?: emptyList()
                            result.success(mapOf(
                                "intensity" to intensity,
                                "blockedApps" to blockedApps
                            ))
                        } else {
                            result.success(null)
                        }
                    }

                    "setDNDMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (notificationManager.isNotificationPolicyAccessGranted) {
                                try {
                                    if (enabled) {
                                        notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_NONE)
                                        Toast.makeText(this, "Native DND: ON", Toast.LENGTH_SHORT).show()
                                    } else {
                                        notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
                                        Toast.makeText(this, "Native DND: OFF", Toast.LENGTH_SHORT).show()
                                    }
                                    result.success(true)
                                } catch (e: Exception) {
                                    Toast.makeText(this, "Native DND Failed: ${e.message}", Toast.LENGTH_LONG).show()
                                    result.success(false)
                                }
                            } else {
                                Toast.makeText(this, "Native DND: Permission Denied", Toast.LENGTH_SHORT).show()
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }

                    "openDNDSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "vibrate" -> {
                        val intensity = call.argument<Int>("intensity") ?: 1
                        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val effect = when(intensity) {
                                1 -> VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
                                2 -> VibrationEffect.createOneShot(300, VibrationEffect.DEFAULT_AMPLITUDE)
                                else -> VibrationEffect.createWaveform(longArrayOf(0, 100, 50, 100), -1)
                            }
                            vibrator.vibrate(effect)
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(300)
                        }
                        result.success(null)
                    }

                    "wakeDevice" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            setShowWhenLocked(true)
                            setTurnScreenOn(true)
                        } else {
                            @Suppress("DEPRECATION")
                            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }

                    "openUrl" -> {
                        val url = call.argument<String>("url") ?: ""
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    }

                    "openEmail" -> {
                        val recipient = call.argument<String>("recipient") ?: ""
                        val subject = call.argument<String>("subject") ?: ""
                        val intent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:")
                            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                            putExtra(Intent.EXTRA_SUBJECT, subject)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(null)
                    }

                    "getAppApkPath" -> {
                        result.success(applicationContext.packageCodePath)
                    }

                    "getUsageStats" -> {
                        val period = call.argument<String>("period") ?: "day"
                        val stats = getUsageStatsForPeriod(period)
                        result.success(stats)
                    }

                    "checkUsageStatsPermission" -> {
                        result.success(isUsageStatsPermissionGranted())
                    }

                    "openUsageStatsSettings" -> {
                        openUsageStatsSettings()
                        result.success(true)
                    }

                    "setDeepSleepMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putBoolean("deep_sleep_active", enabled).apply()
                        
                        MindLockAccessibilityService.isDeepSleepActive = enabled
                        if (enabled) {
                            MindLockAccessibilityService.instance?.navigateHome()
                        }
                        
                        // SECURE BROADCAST UPDATE
                        val intentUpdate = Intent("com.mindlock.UPDATE_STATE")
                        intentUpdate.putExtra("deep_sleep_active", enabled)
                        intentUpdate.setPackage(packageName)
                        sendBroadcast(intentUpdate)
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
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putBoolean("no_scroll_active", enabled).commit()
                        
                        MindLockAccessibilityService.isNoScrollActive = enabled
                        
                        // SECURE BROADCAST UPDATE
                        val intent = Intent("com.mindlock.UPDATE_STATE")
                        intent.putExtra("no_scroll_active", enabled)
                        intent.setPackage(packageName) // Crucial: Target our own package
                        sendBroadcast(intent)
                        
                        result.success(true)
                    }

                    "isNoScrollActive" -> {
                        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
                        result.success(prefs.getBoolean("no_scroll_active", false))
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

                    "setAwarenessMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        toggleAwarenessWork(enabled)
                        result.success(true)
                    }

                    "scheduleDailyReflection" -> {
                        val hour = call.argument<Int>("hour") ?: 22
                        val minute = call.argument<Int>("minute") ?: 30
                        scheduleDailyReflection(hour, minute)
                        result.success(true)
                    }

                    "stopReflectionService" -> {
                        val intent = Intent(this, ReflectionForegroundService::class.java)
                        stopService(intent)
                        result.success(true)
                    }

                    "snoozeDailyReflection" -> {
                        snoozeDailyReflection()
                        result.success(true)
                    }

                    "triggerNightlyLockdown" -> {
                        val intent = Intent(this, ReflectionAlarmReceiver::class.java)
                        sendBroadcast(intent)
                        result.success(true)
                    }

                    "getAppApkPath" -> {
                        try {
                            val path = applicationContext.packageManager.getApplicationInfo(packageName, 0).publicSourceDir
                            result.success(path)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Could not get APK path", e.message)
                        }
                    }

                    "getBatteryInfo" -> {
                        result.success(getBatteryInfo())
                    }

                else -> result.notImplemented()
            }
        }
    }

    private fun toggleAwarenessWork(enabled: Boolean) {
        val workManager = androidx.work.WorkManager.getInstance(this)
        if (enabled) {
            val awarenessRequest = PeriodicWorkRequestBuilder<AwarenessWorker>(2, TimeUnit.HOURS)
                .setConstraints(Constraints.Builder().setRequiresDeviceIdle(false).build())
                .addTag("awareness_work")
                .build()
            WorkManager.getInstance(this).enqueueUniquePeriodicWork("awareness_work", ExistingPeriodicWorkPolicy.REPLACE, awarenessRequest)
        } else {
            workManager.cancelUniqueWork("awareness_work")
        }
    }

    private fun scheduleDailyReflection(hour: Int, minute: Int) {
        // Save to prefs for reboot recovery
        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
        prefs.edit().putInt("reflection_hour", hour).putInt("reflection_minute", minute).apply()

        ReflectionScheduler.schedule(this, hour, minute)
    }

    private fun snoozeDailyReflection() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, ReflectionAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 1003, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val calendar = Calendar.getInstance().apply {
            add(Calendar.MINUTE, 15) // Snooze for 15 minutes
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
    }

    override fun onStart() {
        super.onStart()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(missionEscapeReceiver, IntentFilter("com.MindLock.MISSION_ESCAPE_ATTEMPT"), Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(missionEscapeReceiver, IntentFilter("com.MindLock.MISSION_ESCAPE_ATTEMPT"))
            }

            // Register battery receiver
            val batteryFilter = IntentFilter().apply {
                addAction(Intent.ACTION_POWER_CONNECTED)
                addAction(Intent.ACTION_POWER_DISCONNECTED)
                addAction(Intent.ACTION_BATTERY_CHANGED)
            }
            registerReceiver(batteryReceiver, batteryFilter)
            
        } catch (e: Exception) {}
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(missionEscapeReceiver)
            unregisterReceiver(batteryReceiver)
        } catch (e: Exception) {}
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedPackage = packageName
        val expectedClass = MindLockAccessibilityService::class.java.canonicalName
        val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        
        if (enabledServices.isNullOrEmpty()) return false
        
        val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            // Check if our service is in the string at all
            if (componentNameString.contains(expectedPackage, ignoreCase = true) && 
                componentNameString.contains("MindLockAccessibilityService", ignoreCase = true)) {
                return true
            }
            
            val enabledService = ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && 
                enabledService.packageName == expectedPackage && 
                enabledService.className == expectedClass) {
                return true
            }
        }
        return false
    }

    private fun getUsageStatsForPeriod(period: String): Map<String, Long> {
        if (!isUsageStatsPermissionGranted()) {
            return MindLockAccessibilityService.getInternalUsageStats(this)
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        
        when (period) {
            "day" -> {
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
            }
            "week" -> calendar.add(Calendar.DAY_OF_YEAR, -7)
            "month" -> calendar.add(Calendar.MONTH, -1)
            "year" -> calendar.add(Calendar.YEAR, -1)
        }
        
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        // Use queryAndAggregateUsageStats for more reliable long-term data
        val stats = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        val result = mutableMapOf<String, Long>()
        
        for (pkg in stats.keys) {
            val usageStat = stats[pkg]
            val totalTime = usageStat?.totalTimeInForeground ?: 0L
            if (totalTime > 0) {
                result[pkg] = totalTime / 60000 // Convert to minutes
            }
        }
        return result
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.data = Uri.fromParts("package", packageName, null)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }
}
