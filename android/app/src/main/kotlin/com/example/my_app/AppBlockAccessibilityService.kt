package com.example.flutter_my_app_main

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

private const val TAG = "AppBlockAccessibilityService"

class AppBlockAccessibilityService : AccessibilityService() {

    private lateinit var database: AppBlockDatabase

    override fun onCreate() {
        super.onCreate()
        database = AppBlockDatabase(this)
        Log.d(TAG, "AppBlockAccessibilityService created")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AppBlockAccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null && database.isAppBlocked(packageName)) {
                Log.d(TAG, "Blocking app: $packageName")
                blockApp()
            }
        }
    }

    private fun blockApp() {
        try {
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            Log.d(TAG, "Sent user to home screen")
        } catch (e: Exception) {
            Log.e(TAG, "Error blocking app: ${e.message}")
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AppBlockAccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AppBlockAccessibilityService destroyed")
    }
}