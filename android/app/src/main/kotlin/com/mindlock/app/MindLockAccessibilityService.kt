package com.mindlock.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.widget.Toast

class MindLockAccessibilityService : AccessibilityService() {

    companion object {
        // Entertainment app packages to monitor for scrolling/blocking
        val ENTERTAINMENT_PACKAGES = setOf(
            "com.google.android.youtube",
            "com.instagram.android",
            "com.zhiliaoapp.musically",  // TikTok
            "com.snapchat.android",
            "com.reddit.frontpage",
            "com.facebook.android",
            "com.twitter.android",
            "com.facebook.katana"
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

        // No Scroll State
        var isNoScrollActive = false
        private var lastScrollToastTime = 0L
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("MINDLOCK", "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val packageName = event.packageName?.toString() ?: return

        // --- 1. No Scroll Logic (Blocks scrolling in entertainment apps) ---
        if (isNoScrollActive && event.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
            if (packageName in ENTERTAINMENT_PACKAGES) {
                // If they scroll, we force them BACK to stop the feed consumption
                performGlobalAction(GLOBAL_ACTION_BACK)
                
                val now = System.currentTimeMillis()
                if (now - lastScrollToastTime > 3000) {
                    Toast.makeText(this, "NO SCROLL MODE ACTIVE! 🚫", Toast.LENGTH_SHORT).show()
                    lastScrollToastTime = now
                }
                return
            }
        }

        // --- 2. Window State Logic (App Blocking) ---
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            // 2.1 Deep Sleep Blocking (Block EVERYTHING except SAFE_PACKAGES)
            if (isDeepSleepActive) {
                if (packageName !in SAFE_PACKAGES) {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    Log.d("MINDLOCK", "Sleep Blocking: $packageName")
                    return
                }
            }

            // 2.2 Mission Mode Blocking Logic
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
