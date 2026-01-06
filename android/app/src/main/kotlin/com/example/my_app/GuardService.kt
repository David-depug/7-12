package com.example.flutter_my_app_main

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import android.content.Intent.ACTION_MAIN
import android.content.Intent.CATEGORY_HOME

private const val TAG = "GuardService"
private const val CHANNEL_ID = "guard_service_channel"
private const val RESTART_INTENT = "com.example.flutter_my_app_main.RESTART_GUARD"
private const val ACTION_START_BLOCKING = "com.example.flutter_my_app_main.START_BLOCKING"
private const val ACTION_STOP_BLOCKING = "com.example.flutter_my_app_main.STOP_BLOCKING"

class GuardService : Service() {

    private var wakeLock: PowerManager.WakeLock? = null
    private val restartDelayMs = 5000L
    private val checkIntervalMs = 1000L // Check every second
    private var checkHandler: Handler? = null
    private var checkRunnable: Runnable? = null
    private lateinit var database: AppBlockDatabase
    private var isBlockingEnabled = false

    override fun onCreate() {
        super.onCreate()
        database = AppBlockDatabase(this)
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
            .setContentTitle("App Blocking Service")
            .setContentText(if (isBlockingEnabled) "Monitoring and blocking apps" else "Service running")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        // For Android 14+ (API 34+), specify the foreground service type
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(101, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(101, notification)
        }
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
        Log.d(TAG, "onStartCommand called with action: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_BLOCKING -> startBlocking()
            ACTION_STOP_BLOCKING -> stopBlocking()
        }

        return START_STICKY
    }

    fun startBlocking() {
        if (isBlockingEnabled) return

        isBlockingEnabled = true
        startAppMonitoring()
        updateNotification()
        Log.d(TAG, "App blocking started")
    }

    fun stopBlocking() {
        if (!isBlockingEnabled) return

        isBlockingEnabled = false
        stopAppMonitoring()
        updateNotification()
        Log.d(TAG, "App blocking stopped")
    }

    private fun startAppMonitoring() {
        if (checkHandler == null) {
            checkHandler = Handler(Looper.getMainLooper())
        }

        checkRunnable = object : Runnable {
            override fun run() {
                if (isBlockingEnabled) {
                    checkAndBlockForegroundApp()
                    checkHandler?.postDelayed(this, checkIntervalMs)
                }
            }
        }

        checkHandler?.post(checkRunnable!!)
    }

    private fun stopAppMonitoring() {
        checkRunnable?.let { checkHandler?.removeCallbacks(it) }
        checkRunnable = null
    }

    private fun checkAndBlockForegroundApp() {
        try {
            val foregroundApp = UsageStatsUtils.getForegroundApp(this)
            if (foregroundApp != null && database.isAppBlocked(foregroundApp)) {
                Log.d(TAG, "Blocking app: $foregroundApp")
                blockApp()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking foreground app: ${e.message}")
        }
    }

    private fun blockApp() {
        try {
            val homeIntent = Intent(ACTION_MAIN).apply {
                addCategory(CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            Log.d(TAG, "Sent user to home screen")
        } catch (e: Exception) {
            Log.e(TAG, "Error blocking app: ${e.message}")
        }
    }

    private fun updateNotification() {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("App Blocking Service")
            .setContentText(if (isBlockingEnabled) "Monitoring and blocking apps" else "Service running")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(101, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAppMonitoring()
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
