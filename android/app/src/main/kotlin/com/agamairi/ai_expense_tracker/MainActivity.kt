package com.agamairi.ai_expense_tracker

import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL = "com.agamairi.ai_expense_tracker/actions"
    private var testNotificationIdCounter = 9000

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get("persistent_engine") ?: super.provideFlutterEngine(context)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.getStringExtra("route") == "/edit") {
            val id = intent.getIntExtra("transaction_id", -1)
            if (id != -1) {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, METHOD_CHANNEL).invokeMethod("onEditDeepLink", id)
                }
                intent.removeExtra("transaction_id")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)

            when (call.method) {
                "showCustomNotification" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler
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
                    val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
                    result.success(enabledPackages.contains(packageName))
                }
                "openNotificationListenerSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "requestPostNotificationsPermission" -> {
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
                "isPostNotificationsGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        result.success(checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
                    } else {
                        result.success(true)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, android.net.Uri.parse("package:$packageName"))
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "getInstalledApps" -> {
                    val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                    val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong()))
                    } else {
                        packageManager.queryIntentActivities(intent, PackageManager.MATCH_ALL)
                    }
                    val apps = resolveInfos.mapNotNull { info ->
                        val pkgName = info.activityInfo.packageName
                        if (pkgName == packageName) null
                        else {
                            val label = info.loadLabel(packageManager).toString()
                            mapOf("packageName" to pkgName, "label" to label)
                        }
                    }.distinctBy { it["packageName"] }.sortedBy { it["label"]?.lowercase() }
                    result.success(apps)
                }
                "consumeLaunchTransactionId" -> {
                    val id = intent?.getIntExtra("transaction_id", -1) ?: -1
                    if (intent?.getStringExtra("route") == "/edit" && id != -1) {
                        intent?.removeExtra("transaction_id")
                        result.success(id)
                    } else {
                        result.success(null)
                    }
                }
                "postTestNotification" -> {
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    postTestNotification(title, text)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun showNotification(id: Int, title: String, text: String) {
        val approveIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "com.agamairi.ai_expense_tracker.APPROVE"
            putExtra("transaction_id", id)
        }
        val approvePending = PendingIntent.getBroadcast(context, id, approveIntent, PendingIntent.FLAG_IMMUTABLE)

        val rejectIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "com.agamairi.ai_expense_tracker.REJECT"
            putExtra("transaction_id", id)
        }
        val rejectPending = PendingIntent.getBroadcast(context, id + 1000, rejectIntent, PendingIntent.FLAG_IMMUTABLE)

        val editIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/edit")
            putExtra("transaction_id", id)
        }
        val editPending = PendingIntent.getActivity(context, id + 2000, editIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("expenses", "Expenses", NotificationManager.IMPORTANCE_HIGH)
            manager.createNotificationChannel(channel)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                return
            }
        }

        val notification = NotificationCompat.Builder(context, "expenses")
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
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("test_notifications", "Test Notifications", NotificationManager.IMPORTANCE_LOW)
            manager.createNotificationChannel(channel)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                return
            }
        }

        val notification = NotificationCompat.Builder(context, "test_notifications")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(text)
            .setAutoCancel(true)
            .build()

        manager.notify(testNotificationIdCounter++, notification)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getStringExtra("route") == "/edit") {
            val id = intent.getIntExtra("transaction_id", -1)
            if (id != -1) {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, METHOD_CHANNEL).invokeMethod("onEditDeepLink", id)
                }
                intent.removeExtra("transaction_id")
            }
        }
    }

}
