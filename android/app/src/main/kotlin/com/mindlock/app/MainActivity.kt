package com.mindlock.app

import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.MindLock/native"

    private var flutterChannel: MethodChannel? = null

    private val missionEscapeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.MindLock.MISSION_ESCAPE_ATTEMPT") {
                val pkg = intent.getStringExtra("package") ?: ""
                flutterChannel?.invokeMethod("onMissionEscapeAttempt", mapOf("package" to pkg))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        flutterChannel?.setMethodCallHandler { call, result ->
            when (call.method) {

                    "lockScreen" -> {
                        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        dpm.lockNow()
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
                        val event = KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE)
                        audioManager.dispatchMediaKeyEvent(event)
                        result.success(null)
                    }

                    "closeApp" -> {
                        val packageName = call.argument<String>("package")
                        // Requires accessibility service in production
                        result.success(null)
                    }

                    "wakeDevice" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                        val wakeLock = pm.newWakeLock(
                            android.os.PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                            android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP,
                            "MindLock::WakeLock"
                        )
                        wakeLock.acquire(10 * 60 * 1000L)
                        result.success(null)
                    }

                    "isAccessibilityEnabled" -> {
                        val enabled = isAccessibilityServiceEnabled()
                        result.success(enabled)
                    }

                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    "hasOverlayPermission" -> {
                        val granted = Settings.canDrawOverlays(this)
                        result.success(granted)
                    }

                    "openOverlaySettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                android.net.Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "requestBatteryExemption" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                android.net.Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "vibrate" -> {
                        val intensity = call.argument<Int>("intensity") ?: 1
                        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                                    as android.os.VibratorManager
                            vm.defaultVibrator
                        } else {
                            @Suppress("DEPRECATION")
                            getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
                        }
                        val ms = when (intensity) {
                            0 -> 0L
                            1 -> 200L
                            2 -> 400L
                            else -> 800L
                        }
                        if (ms > 0) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                vibrator.vibrate(android.os.VibrationEffect.createOneShot(
                                    ms, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
                            } else {
                                @Suppress("DEPRECATION")
                                vibrator.vibrate(ms)
                            }
                        }
                        result.success(null)
                    }

                    "startMission" -> {
                        val blockedApps = call.argument<List<String>>("blockedApps") ?: listOf()
                        val intensity = call.argument<String>("intensity") ?: "medium"
                        MindLockAccessibilityService.isMissionActive = true
                        MindLockAccessibilityService.missionBlockedPackages = blockedApps.toSet()
                        MindLockAccessibilityService.missionIntensity = intensity
                        result.success(null)
                    }

                    "stopMission" -> {
                        MindLockAccessibilityService.isMissionActive = false
                        MindLockAccessibilityService.missionBlockedPackages = emptySet()
                        result.success(null)
                    }

                    "setDNDMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (notificationManager.isNotificationPolicyAccessGranted) {
                                val filter = if (enabled) android.app.NotificationManager.INTERRUPTION_FILTER_PRIORITY else android.app.NotificationManager.INTERRUPTION_FILTER_ALL
                                notificationManager.setInterruptionFilter(filter)
                                result.success(true)
                            } else {
                                startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }

                    "isDNDPermissionGranted" -> {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(notificationManager.isNotificationPolicyAccessGranted)
                        } else {
                            result.success(true)
                        }
                    }

                    "pauseMedia" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as android.app.AudioManager
                        val eventDown = android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_MEDIA_PAUSE)
                        val eventUp = android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, android.view.KeyEvent.KEYCODE_MEDIA_PAUSE)
                        audioManager.dispatchMediaKeyEvent(eventDown)
                        audioManager.dispatchMediaKeyEvent(eventUp)
                        result.success(true)
                    }

                    "lockScreen" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            MindLockAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    "openUrl" -> {
                        val url = call.argument<String>("url") ?: ""
                        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }

                    "openEmail" -> {
                        val recipient = call.argument<String>("recipient") ?: ""
                        val subject = call.argument<String>("subject") ?: ""
                        val intent = Intent(Intent.ACTION_SENDTO).apply {
                            data = android.net.Uri.parse("mailto:")
                            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                            putExtra(Intent.EXTRA_SUBJECT, subject)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(missionEscapeReceiver, IntentFilter("com.MindLock.MISSION_ESCAPE_ATTEMPT"), Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(missionEscapeReceiver, IntentFilter("com.MindLock.MISSION_ESCAPE_ATTEMPT"))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(missionEscapeReceiver)
        } catch (e: Exception) {}
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "$packageName/${MindLockAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.split(':').any { it.equals(service, ignoreCase = true) }
    }
}
