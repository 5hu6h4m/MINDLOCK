package com.mindlock.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.Context
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.widget.Toast
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MindLockAccessibilityService : AccessibilityService() {

    companion object {
        val BLOCK_KEYWORDS = setOf("youtube", "instagram", "tiktok", "snapchat", "facebook", "twitter", "reddit")
        
        val BLOCKED_PACKAGES = setOf(
            "com.google.android.youtube",
            "com.instagram.android",
            "com.snapchat.android",
            "com.facebook.katana",
            "com.zhiliaoapp.musically",
            "com.twitter.android",
            "com.reddit.frontpage"
        )

        val SAFE_PACKAGES = setOf(
            "com.mindlock.app",
            "com.android.launcher",
            "com.oppo.launcher",
            "com.coloros.launcher",
            "com.realme.launcher",
            "com.sec.android.app.launcher",
            "com.google.android.apps.nexuslauncher",
            "com.android.settings",
            "com.android.systemui",
            "com.android.dialer",
            "com.google.android.inputmethod",
            "com.samsung.android.honeyboard",
            "com.microsoft.emmx",
            "inputmethod",
            "keyboard"
        )

        var instance: MindLockAccessibilityService? = null
        var isDeepSleepActive = false
        var isMissionActive = false
        var missionBlockedPackages = setOf<String>()
        var missionIntensity = "medium"
        var isNoScrollActive = false
        var isReflectionActive = false

        fun getInternalUsageStats(context: Context): Map<String, Long> {
            val prefs = context.getSharedPreferences("mindlock_usage", Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            val result = mutableMapOf<String, Long>()
            val all = prefs.all
            for ((key, value) in all) {
                if (key.startsWith(today) && value is Long) {
                    val pkg = key.substringAfter("${today}_")
                    result[pkg] = value / 60000 // Convert to minutes
                }
            }
            return result
        }
    }

    private var currentPackage: String? = null
    private var startTime: Long = 0
    private var stateReceiver: BroadcastReceiver? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        
        // Show a persistent notification to keep the service alive
        createNotificationChannel()
        val notification = android.app.Notification.Builder(this, "accessibility_service")
            .setContentTitle("MindLock Shield Active")
            .setContentText("Protecting your focus...")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .build()
        // Note: Accessibility Services don't strictly need startForeground, 
        // but it helps some Chinese ROMs keep it alive.
        
        stateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "com.mindlock.UPDATE_STATE") {
                    isNoScrollActive = intent.getBooleanExtra("no_scroll_active", isNoScrollActive)
                    isDeepSleepActive = intent.getBooleanExtra("deep_sleep_active", isDeepSleepActive)
                    isMissionActive = intent.getBooleanExtra("mission_active", isMissionActive)
                    isReflectionActive = intent.getBooleanExtra("reflection_active", isReflectionActive)
                }
            }
        }
        val filter = IntentFilter("com.mindlock.UPDATE_STATE")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stateReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stateReceiver, filter)
        }
        
        // Initialize state from prefs
        val prefs = getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
        isNoScrollActive = prefs.getBoolean("no_scroll_active", false)
        isDeepSleepActive = prefs.getBoolean("deep_sleep_active", false)
        isMissionActive = prefs.getBoolean("mission_active", false)
        isReflectionActive = prefs.getBoolean("is_reflection_active", false)
        missionIntensity = prefs.getString("mission_intensity", "medium") ?: "medium"
        missionBlockedPackages = prefs.getStringSet("mission_blocked_apps", emptySet()) ?: emptySet()

        vibratePattern() // Initial vibration to signal connection
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                "accessibility_service",
                "MindLock System Service",
                android.app.NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val packageName = event.packageName?.toString()?.lowercase() ?: ""
        
        // --- SAFE LIST (NEVER BLOCK) ---
        // During reflection or deep sleep, we ONLY allow MindLock and SystemUI.
        // Even the Launcher is blocked to prevent bypassing.
        val isReflectionOrDeepSleep = isReflectionActive || isDeepSleepActive
        val isCriticalApp = packageName == "com.mindlock.app" || packageName == "com.android.systemui"
        val isSystemApp = SAFE_PACKAGES.any { packageName.contains(it) }

        if (packageName == "") return
        if (isCriticalApp) return
        if (isSystemApp && !isReflectionOrDeepSleep) return

        // --- TRACK USAGE ---
        if (packageName != currentPackage) {
            if (currentPackage != null && startTime > 0) {
                val durationMs = System.currentTimeMillis() - startTime
                if (durationMs > 1000) recordUsage(currentPackage!!, durationMs)
            }
            currentPackage = packageName
            startTime = System.currentTimeMillis()
        }

        // --- ENFORCE BLOCKING ---
        // Prioritize memory state for instant response, fallback to prefs
        val noScroll = isNoScrollActive
        val deepSleep = isDeepSleepActive
        val reflection = isReflectionActive
        val mission = isMissionActive

        val isSafe = SAFE_PACKAGES.any { packageName.contains(it) }
        val isEntertainment = BLOCKED_PACKAGES.contains(packageName) || 
                             BLOCK_KEYWORDS.any { packageName.contains(it) }

        // 1. Deep Sleep / Reflection (Global Lockdown)
        if ((reflection || deepSleep) && !isSafe) {
            vibratePattern()
            
            if (reflection) {
                // FORCE REDIRECT: Take them back to the summary screen
                val launchIntent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra("route", "/reflection/overlay")
                }
                startActivity(launchIntent)
            } else {
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            return
        }

        // 2. Anti-Scroll (Targeted Discipline)
        if (noScroll && event.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
            if (isEntertainment && !isSafe) {
                vibratePattern() // Warn user
                
                // Nuclear Stop: Force Home to break the scroll dopamine loop
                performGlobalAction(GLOBAL_ACTION_HOME)
                return
            }
        }

        // 3. Mission Mode
        if (mission && packageName != "com.mindlock.app" && packageName != "com.android.systemui") {
            val intensity = missionIntensity
            val blockedApps = missionBlockedPackages

            val shouldBlock = if (intensity.equals("hardcore", ignoreCase = true) && blockedApps.isEmpty()) {
                isEntertainment
            } else {
                packageName in blockedApps
            }

            if (shouldBlock && !intensity.equals("light", ignoreCase = true)) {
                vibratePattern()
                performGlobalAction(GLOBAL_ACTION_HOME)
                val intent = Intent("com.MindLock.MISSION_ESCAPE_ATTEMPT")
                intent.putExtra("package", packageName)
                sendBroadcast(intent)
            }
        }
    }

    private fun vibratePattern() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Pulse pattern: 0ms delay, 100ms on, 100ms off
                val effect = android.os.VibrationEffect.createWaveform(longArrayOf(0, 100, 100), -1)
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(100)
            }
        } catch (e: Exception) {}
    }

    private fun recordUsage(pkg: String, durationMs: Long) {
        val prefs = getSharedPreferences("mindlock_usage", Context.MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val key = "${today}_${pkg}"
        prefs.edit().putLong(key, prefs.getLong(key, 0L) + durationMs).apply()
    }

    override fun onInterrupt() { instance = null }
    override fun onDestroy() { 
        instance = null 
        try {
            if (stateReceiver != null) unregisterReceiver(stateReceiver)
        } catch (e: Exception) {}
    }
    fun navigateHome() { performGlobalAction(GLOBAL_ACTION_HOME) }
}
