package com.agamairi.ai_expense_tracker

import android.Manifest
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles calls from the persistent Flutter engine for the lifetime of the process.
 *
 * The engine starts from [ExpenseTrackerApplication] before an Activity is guaranteed
 * to be configured, so this handler deliberately owns all application-context calls.
 * Activity-only calls use the most recently attached [MainActivity].
 */
class ActionsMethodCallHandler(
    private val application: Application,
) : MethodChannel.MethodCallHandler {
    private var activity: MainActivity? = null
    private var testNotificationIdCounter = 9000

    fun attachActivity(activity: MainActivity) {
        this.activity = activity
    }

    fun detachActivity(activity: MainActivity) {
        if (this.activity === activity) {
            this.activity = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val prefs = application.getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)

        when (call.method) {
            "showCustomNotification" -> {
                val id = call.argument<Int>("id") ?: return
                val title = call.argument<String>("title") ?: ""
                val text = call.argument<String>("text") ?: ""

                showNotification(id, title, text)
                result.success(null)
            }
            "getPackageWhitelist" -> {
                val set = prefs.getStringSet("package_whitelist", emptySet())
                result.success(set?.toList() ?: emptyList<String>())
            }
            "setPackageWhitelist" -> {
                val list = call.argument<List<String>>("whitelist") ?: emptyList()
                prefs.edit().putStringSet("package_whitelist", list.toSet()).apply()
                result.success(null)
            }
            "getNotificationRegex" -> {
                val regex = prefs.getString("notification_regex", "debited|credited|spent|withdrawn|paid|transfer")
                result.success(regex)
            }
            "setNotificationRegex" -> {
                val regex = call.argument<String>("regex") ?: ""
                prefs.edit().putString("notification_regex", regex).apply()
                result.success(null)
            }
            "isNotificationListenerEnabled" -> {
                val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(application)
                result.success(enabledPackages.contains(application.packageName))
            }
            "openNotificationListenerSettings" -> {
                withActivity(result) {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
            }
            "requestPostNotificationsPermission" -> {
                withActivity(result) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
            }
            "isPostNotificationsGranted" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    result.success(
                        application.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                            PackageManager.PERMISSION_GRANTED,
                    )
                } else {
                    result.success(true)
                }
            }
            "isIgnoringBatteryOptimizations" -> {
                val pm = application.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    result.success(pm.isIgnoringBatteryOptimizations(application.packageName))
                } else {
                    result.success(true)
                }
            }
            "requestIgnoreBatteryOptimizations" -> {
                withActivity(result) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            android.net.Uri.parse("package:${application.packageName}"),
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }
            }
            "getInstalledApps" -> {
                val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    application.packageManager.queryIntentActivities(
                        intent,
                        PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong()),
                    )
                } else {
                    application.packageManager.queryIntentActivities(intent, PackageManager.MATCH_ALL)
                }
                val apps = resolveInfos.mapNotNull { info ->
                    val packageName = info.activityInfo.packageName
                    if (packageName == application.packageName) {
                        null
                    } else {
                        val label = info.loadLabel(application.packageManager).toString()
                        mapOf("packageName" to packageName, "label" to label)
                    }
                }.distinctBy { it["packageName"] }.sortedBy { it["label"]?.lowercase() }
                result.success(apps)
            }
            "consumeLaunchTransactionId" -> {
                withActivity(result) {
                    val id = intent?.getIntExtra("transaction_id", -1) ?: -1
                    if (intent?.getStringExtra("route") == "/edit" && id != -1) {
                        intent?.removeExtra("transaction_id")
                        result.success(id)
                    } else {
                        result.success(null)
                    }
                }
            }
            "postTestNotification" -> {
                val title = call.argument<String>("title") ?: ""
                val text = call.argument<String>("text") ?: ""
                postTestNotification(title, text)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun withActivity(result: MethodChannel.Result, block: MainActivity.() -> Unit) {
        val attachedActivity = activity
        if (attachedActivity == null) {
            result.error("activity_unavailable", "No activity is attached to the persistent Flutter engine.", null)
        } else {
            attachedActivity.block()
        }
    }

    private fun showNotification(id: Int, title: String, text: String) {
        val approveIntent = Intent(application, NotificationActionReceiver::class.java).apply {
            action = "com.agamairi.ai_expense_tracker.APPROVE"
            putExtra("transaction_id", id)
        }
        val approvePending = PendingIntent.getBroadcast(
            application,
            id,
            approveIntent,
            PendingIntent.FLAG_IMMUTABLE,
        )

        val rejectIntent = Intent(application, NotificationActionReceiver::class.java).apply {
            action = "com.agamairi.ai_expense_tracker.REJECT"
            putExtra("transaction_id", id)
        }
        val rejectPending = PendingIntent.getBroadcast(
            application,
            id + 1000,
            rejectIntent,
            PendingIntent.FLAG_IMMUTABLE,
        )

        val editIntent = Intent(application, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/edit")
            putExtra("transaction_id", id)
        }
        val editPending = PendingIntent.getActivity(
            application,
            id + 2000,
            editIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val manager = application.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("expenses", "Expenses", NotificationManager.IMPORTANCE_HIGH)
            manager.createNotificationChannel(channel)
        }

        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                androidx.core.content.ContextCompat.checkSelfPermission(
                    application,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notification = NotificationCompat.Builder(application, "expenses")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(text)
            .addAction(android.R.drawable.ic_input_add, "Approve", approvePending)
            .addAction(android.R.drawable.ic_delete, "Reject", rejectPending)
            .addAction(android.R.drawable.ic_menu_edit, "Edit", editPending)
            .setAutoCancel(true)
            .build()

        manager.notify(id, notification)
    }

    private fun postTestNotification(title: String, text: String) {
        val manager = application.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "test_notifications",
                "Test Notifications",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }

        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                androidx.core.content.ContextCompat.checkSelfPermission(
                    application,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notification = NotificationCompat.Builder(application, "test_notifications")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(text)
            .setAutoCancel(true)
            .build()

        manager.notify(testNotificationIdCounter++, notification)
    }
}
