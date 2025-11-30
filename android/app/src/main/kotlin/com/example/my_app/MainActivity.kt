package com.example.flutter_my_app_main

import android.app.Activity
import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.*

private const val CHANNEL = "com.appguard.native_calls"
private const val TAG = "AdminChecker"

// =======================================================================================
// === Main Activity ===
// =======================================================================================

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 🔹 Check if Device Admin is active
        if (!checkDeviceAdminActive(this)) {
            // Show warning layout forcing admin activation
            showAdminWarning()
            // Request Device Admin permission
            requestDeviceAdminPermission(this)
            // Close MainActivity to prevent access
            finish()
            return
        }
    }

    private fun showAdminWarning() {
        // Simple full-screen red warning
        val scrollView = ScrollView(this)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.RED)
            gravity = Gravity.CENTER
            setPadding(50, 50, 50, 50)
        }

        val warningText = TextView(this).apply {
            text = """
                ⚠️ Security Notice! ⚠️

                You must enable Device Admin to use this application.
                The app will not work unless you grant the required permission.

                Please follow the instructions to activate the Device Admin.

                Attempting to bypass may cause automatic corrective actions.

                Scroll to the bottom and confirm activation.
            """.trimIndent()
            textSize = 20f
            setTextColor(Color.WHITE)
        }

        layout.addView(warningText)
        scrollView.addView(layout)
        setContentView(scrollView)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAdminActive" -> result.success(checkDeviceAdminActive(this))
                "requestAdminPermission" -> {
                    requestDeviceAdminPermission(this)
                    result.success(true)
                }
                "requestUsagePermission" -> {
                    requestUsageAccessPermission(this)
                    result.success(true)
                }
                "hasUsagePermission" -> result.success(hasUsageAccessPermission(this))
                "getUsageStats" -> {
                    try {
                        val usageStatsList = getUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve usage stats.", e.message)
                    }
                }
                "blockApp" -> {
                    val appName = call.argument<String>("appName")
                    Toast.makeText(this, "Block logic initiated for: $appName (Service Required)", Toast.LENGTH_LONG).show()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // =================== Device Admin Methods ===================

    private fun checkDeviceAdminActive(context: Context): Boolean {
        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(context, AdminReceiver::class.java)
        return devicePolicyManager.isAdminActive(componentName)
    }

    private fun requestDeviceAdminPermission(context: Context) {
        val componentName = ComponentName(context, AdminReceiver::class.java)
        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

        if (!devicePolicyManager.isAdminActive(componentName)) {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "⚠️ You must enable this permission to use the app.")
            startActivity(intent)
        } else {
            Toast.makeText(context, "Device Admin already enabled.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun requestUsageAccessPermission(context: Context) {
        if (!hasUsageAccessPermission(context)) {
            try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                context.startActivity(intent)
            } catch (e: Exception) {
                Toast.makeText(context, "Cannot open Usage Access settings.", Toast.LENGTH_LONG).show()
            }
        } else {
            Toast.makeText(context, "Usage Access already granted.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun hasUsageAccessPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
            return mode == AppOpsManager.MODE_ALLOWED
        }
        return false
    }

    private fun getUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) return emptyList()

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val usageList = mutableListOf<Map<String, Any>>()

        stats?.filter { it.totalTimeInForeground > 0 }?.forEach { usageStats ->
            try {
                val packageName = usageStats.packageName
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (usageStats.totalTimeInForeground / 1000).toInt()

                val usageMap = mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "totalTimeInSeconds" to totalTimeInSeconds
                )
                usageList.add(usageMap)
            } catch (e: Exception) {
                Log.w(TAG, "Package not found: ${usageStats.packageName}")
            }
        }

        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }
}

// =======================================================================================
// === Device Admin Receiver ===
// =======================================================================================

class AdminReceiver : DeviceAdminReceiver() {

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        // Launch full-screen warning immediately
        try {
            val warningIntent = Intent(context, WarningActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            context.startActivity(warningIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch WarningActivity: ${e.message}")
        }

        // Relaunch app immediately
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch app after disable request: ${e.message}")
        }

        // Prevent disabling
        return "\n" +
                "            ⚠\uFE0F Important Security Notice! ⚠\uFE0F\n" +
                "\n" +
                "            This application contains special security features that prevent disabling protection.\n" +
                "            \n" +
                "            Please read carefully:\n" +
                "\n" +
                "            1. Do not attempt to remove device admin privileges.\n" +
                "            2. Do not attempt to forcefully uninstall or disable the app.\n" +
                "            3. Usage will be monitored to ensure device safety.\n" +
                "            4. All user actions may be logged for security purposes.\n" +
                "            5. Attempting to bypass security features may result in automatic corrective actions.\n" +
                "            6. Ensure you understand and agree to all conditions before proceeding.\n" +
                "            7. This is a very long message to ensure user awareness.\n" +
                "            8. You must scroll to the bottom to press the Agree button.\n" +
                "            9. Add more terms here if needed.\n" +
                "            10. Continue reading until the end...\n" +
                "\n" +
                "            ⛔CAN'T DESAPLE THIS OPTION!\n!"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Device Admin Enabled!", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Device Admin Disabled!", Toast.LENGTH_SHORT).show()
    }
}

// =======================================================================================
// === Warning Activity ===
// =======================================================================================

class WarningActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.RED)
            gravity = Gravity.CENTER
            setPadding(50, 50, 50, 50)
        }

        val textView = TextView(this).apply {
            text = """
                🛑 Security alert detected!
                Attempt to disable admin privileges is not allowed.

                Returning to the app...
            """.trimIndent()
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        layout.addView(textView)
        setContentView(layout)

        // Return to app immediately
        Handler(Looper.getMainLooper()).post {
            try {
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                startActivity(launchIntent)
                finish()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to relaunch app: ${e.message}")
            }
        }
    }
}