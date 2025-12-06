package com.example.flutter_my_app_main

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

private const val TAG = "GuardService"
private const val CHANNEL_ID = "guard_service_channel"
private const val RESTART_INTENT = "com.example.flutter_my_app_main.RESTART_GUARD"

class GuardService : Service() {

    private var wakeLock: PowerManager.WakeLock? = null
    private val restartDelayMs = 5000L

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
        startForegroundWithNotification()
        Log.d(TAG, "GuardService onCreate")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guard Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guard Service Running")
            .setContentText("Monitoring app for security")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        startForeground(101, notification)
        Log.d(TAG, "GuardService started in foreground")
    }

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "GuardService::WakeLock")
            wakeLock?.acquire(10 * 60 * 1000L /*10 minutes, renewed on each onCreate*/ )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire WakeLock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) it.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to release WakeLock: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // If service is killed, START_STICKY requests restart
        Log.d(TAG, "onStartCommand called")
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
        scheduleRestart()
        Log.d(TAG, "GuardService destroyed; scheduled restart")
    }

    private fun scheduleRestart() {
        try {
            val restartIntent = Intent(applicationContext, RestartReceiver::class.java)
            restartIntent.action = RESTART_INTENT
            val pending = PendingIntent.getBroadcast(applicationContext, 1, restartIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAt = System.currentTimeMillis() + restartDelayMs
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        } catch (e: Exception) {
            Log.e(TAG, "scheduleRestart failed: ${e.message}")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
