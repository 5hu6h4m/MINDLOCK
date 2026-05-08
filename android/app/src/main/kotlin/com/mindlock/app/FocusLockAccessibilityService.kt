package com.mindlock.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class MindLockAccessibilityService : AccessibilityService() {

    companion object {
        // Entertainment app packages to monitor
        val ENTERTAINMENT_PACKAGES = setOf(
            "com.google.android.youtube",
            "com.instagram.android",
            "com.zhiliaoapp.musically",  // TikTok
            "com.snapchat.android",
            "com.reddit.frontpage",
            "com.facebook.android",
            "com.twitter.android",
        )

        var instance: MindLockAccessibilityService? = null
        var isSleepTimerActive = false
        var sleepTimerEndTime = 0L

        // Mission Mode State
        var isMissionActive = false
        var missionBlockedPackages = setOf<String>()
        var missionIntensity = "medium" // light, medium, hardcore
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Mission Mode Blocking Logic
        if (isMissionActive && missionIntensity != "light") {
            if (packageName in missionBlockedPackages) {
                // Force exit
                performGlobalAction(GLOBAL_ACTION_HOME)
                
                // Send broadcast to MainActivity -> Flutter
                val intent = Intent("com.MindLock.MISSION_ESCAPE_ATTEMPT")
                intent.putExtra("package", packageName)
                sendBroadcast(intent)
                return
            }
        }

        // Check if sleep timer is active and entertainment app is foreground
        if (isSleepTimerActive && packageName in ENTERTAINMENT_PACKAGES) {
            val now = System.currentTimeMillis()
            if (now >= sleepTimerEndTime) {
                // Timer ended while watching entertainment
                triggerSleepMode()
            }
        }
    }

    override fun onInterrupt() {
        instance = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    fun triggerSleepMode() {
        // Navigate to home
        performGlobalAction(GLOBAL_ACTION_HOME)

        // Lock screen after short delay
        android.os.Handler(mainLooper).postDelayed({
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
        }, 2000)
    }

    fun navigateHome() {
        performGlobalAction(GLOBAL_ACTION_HOME)
    }

    fun showRecentApps() {
        performGlobalAction(GLOBAL_ACTION_RECENTS)
    }
}
