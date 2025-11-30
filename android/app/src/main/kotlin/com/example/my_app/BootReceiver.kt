package com.example.flutter_my_app_main

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

private const val TAG = "BootReceiver"

// =======================================================================================
// === BootReceiver for Self-Healing / Anti-Stop ===
// =======================================================================================
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device booted, starting GuardService...")

            val serviceIntent = Intent(context, GuardService::class.java)

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.d(TAG, "GuardService started from BootReceiver")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start GuardService from BootReceiver: ${e.message}")
            }
        }
    }
}
