package com.mindlock.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class ReflectionAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, ReflectionForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Reschedule for next day
        ReflectionScheduler.restore(context)
    }
}
