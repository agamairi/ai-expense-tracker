package com.agamairi.ai_expense_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.content.Context
import android.content.SharedPreferences
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class ExpenseNotificationService : NotificationListenerService() {
    private var regex = Regex("debited|credited|spent|withdrawn|paid|transfer", RegexOption.IGNORE_CASE)
    private var packageWhitelist: Set<String> = emptySet()

    companion object {
        private const val TAG = "ExpenseNotification"
        private const val FG_NOTIFICATION_ID = 1
        private const val FG_CHANNEL_ID = "listener_status"
        private const val FG_CHANNEL_NAME = "Listener Status"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        loadPreferences()
        startForegroundWithNotification()
    }

    override fun onListenerDisconnected() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onListenerDisconnected()
    }

    private fun startForegroundWithNotification() {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create a dedicated low-importance channel (separate from "expenses" and "test_notifications")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    FG_CHANNEL_ID,
                    FG_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Shows while BAInk is listening for transaction notifications"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    setSound(null, null)
                }
                manager.createNotificationChannel(channel)
            }

            val notification = NotificationCompat.Builder(this, FG_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("BAInk")
                .setContentText("Listening for transactions")
                .setOngoing(true)
                .setSilent(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // Android 14+ (API 34+): must specify foregroundServiceType
                startForeground(
                    FG_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(FG_NOTIFICATION_ID, notification)
            }

            Log.d(TAG, "Foreground service started — notification listener active")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service", e)
            // Don't crash the service — notification listening still works without foreground,
            // it just won't be protected from process death.
        }
    }

    private fun loadPreferences() {
        val prefs = getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)
        val pattern = prefs.getString("notification_regex", "debited|credited|spent|withdrawn|paid|transfer") 
            ?: "debited|credited|spent|withdrawn|paid|transfer"
        try {
            regex = Regex(pattern, RegexOption.IGNORE_CASE)
        } catch (e: Exception) {
            Log.e(TAG, "Invalid regex pattern: $pattern", e)
        }
        packageWhitelist = prefs.getStringSet("package_whitelist", emptySet()) ?: emptySet()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn?.notification ?: return
        val packageName = sbn.packageName ?: return

        loadPreferences()

        if (packageWhitelist.isNotEmpty() && !packageWhitelist.contains(packageName)) {
            return
        }

        val extras = notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""

        val content = "$title $text"

        if (regex.containsMatchIn(content)) {
            Log.d(TAG, "Matched notification: $content")
            
            val engine = FlutterEngineCache.getInstance().get("persistent_engine")
            engine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, "com.agamairi.ai_expense_tracker/actions").invokeMethod(
                    "onNotificationCaptured",
                    mapOf("title" to title, "text" to text)
                )
            }
        }
    }
}
