package com.agamairi.ai_expense_tracker

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class ExpenseNotificationService : NotificationListenerService() {
    private var regex = Regex("debited|credited|spent|withdrawn|paid|transfer", RegexOption.IGNORE_CASE)
    private var packageWhitelist: Set<String> = emptySet()

    override fun onListenerConnected() {
        super.onListenerConnected()
        loadPreferences()
    }

    private fun loadPreferences() {
        val prefs = getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)
        val pattern = prefs.getString("notification_regex", "debited|credited|spent|withdrawn|paid|transfer") 
            ?: "debited|credited|spent|withdrawn|paid|transfer"
        try {
            regex = Regex(pattern, RegexOption.IGNORE_CASE)
        } catch (e: Exception) {
            Log.e("ExpenseNotification", "Invalid regex pattern: $pattern", e)
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
            Log.d("ExpenseNotification", "Matched notification: $content")
            
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
