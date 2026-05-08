package com.mindlock.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log

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
        
        // Critical apps that should NEVER be blocked
        val SAFE_PACKAGES = setOf(
            "com.android.dialer",
            "com.google.android.dialer",
            "com.android.contacts",
            "com.google.android.contacts",
            "com.android.settings",
            "com.mindlock.app", // Always allow ourselves
        )

        var instance: MindLockAccessibilityService? = null
        
        // Deep Sleep State
        var isDeepSleepActive = false

        // Mission Mode State
        var isMissionActive = false
        var missionBlockedPackages = setOf<String>()
        var missionIntensity = "medium" // light, medium, hardcore, strict
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("MINDLOCK", "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // 1. Deep Sleep Blocking (Block EVERYTHING except SAFE_PACKAGES)
        if (isDeepSleepActive) {
            if (packageName !in SAFE_PACKAGES) {
                performGlobalAction(GLOBAL_ACTION_HOME)
                Log.d("MINDLOCK", "Sleep Blocking: $packageName")
                return
            }
        }

        // 2. Mission Mode Blocking Logic
        if (isMissionActive) {
            // Never block safe apps
            if (packageName in SAFE_PACKAGES) return

            // If STRICT mission mode with empty package list, block ALL entertainment
            val shouldBlock = if (missionIntensity == "STRICT" && missionBlockedPackages.isEmpty()) {
                packageName in ENTERTAINMENT_PACKAGES
            } else {
                packageName in missionBlockedPackages
            }

            if (shouldBlock && missionIntensity != "light") {
                performGlobalAction(GLOBAL_ACTION_HOME)
                
                // Send broadcast to MainActivity -> Flutter
                val intent = Intent("com.MindLock.MISSION_ESCAPE_ATTEMPT")
                intent.putExtra("package", packageName)
                sendBroadcast(intent)
                Log.d("MINDLOCK", "Mission Blocking: $packageName")
                return
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
        performGlobalAction(GLOBAL_ACTION_HOME)
        android.os.Handler(mainLooper).postDelayed({
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
        }, 1000)
    }

    fun navigateHome() {
        performGlobalAction(GLOBAL_ACTION_HOME)
    }
}
