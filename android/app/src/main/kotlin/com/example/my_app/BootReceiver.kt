package com.example.flutter_my_app_main

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

private const val TAG_BOOT = "BootReceiver"

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG_BOOT, "Device booted, starting GuardService...")
            try {
                val serviceIntent = Intent(context, GuardService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                Log.e(TAG_BOOT, "Failed to start GuardService on boot: ${e.message}")
            }
        }
    }
}

// RestartReceiver used by GuardService scheduleRestart
class RestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.flutter_my_app_main.RESTART_GUARD") {
            try {
                val serviceIntent = Intent(context, GuardService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.d(TAG_BOOT, "RestartReceiver started GuardService")
            } catch (e: Exception) {
                Log.e(TAG_BOOT, "RestartReceiver failed: ${e.message}")
            }
        }
    }
}
