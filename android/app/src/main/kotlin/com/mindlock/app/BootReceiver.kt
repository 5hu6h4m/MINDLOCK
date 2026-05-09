package com.mindlock.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            // Restart the foreground service after reboot
            val serviceIntent = Intent(context, ForegroundReminderService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }

            // Restore states in Accessibility Service via Preferences
            // (Accessibility Service will read these from prefs on start)
            
            // Explicitly start services if they should be running
            val prefs = context.getSharedPreferences("mindlock_prefs", Context.MODE_PRIVATE)
            
            if (prefs.getBoolean("is_reflection_active", false)) {
                val reflectionIntent = Intent(context, ReflectionForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(reflectionIntent)
                } else {
                    context.startService(reflectionIntent)
                }
            }

            // Restore Daily Reflection Alarm
            ReflectionScheduler.restore(context)

            // Note: Accessibility Service restarts automatically if enabled.
            // It will pick up no_scroll_active, deep_sleep_active, and mission_active from prefs.
        }
    }
}
