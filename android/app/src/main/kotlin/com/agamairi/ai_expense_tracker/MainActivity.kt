package com.agamairi.ai_expense_tracker

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get("persistent_engine")
            ?: super.provideFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val trackerApplication = application as ExpenseTrackerApplication
        val handler = trackerApplication.actionsMethodCallHandler
        if (FlutterEngineCache.getInstance().get("persistent_engine") !== flutterEngine) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ExpenseTrackerApplication.METHOD_CHANNEL)
                .setMethodCallHandler(handler)
        }
        handler.attachActivity(this)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.getStringExtra("route") == "/edit") {
            val id = intent.getIntExtra("transaction_id", -1)
            if (id != -1) {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, ExpenseTrackerApplication.METHOD_CHANNEL)
                        .invokeMethod("onEditDeepLink", id)
                }
                intent.removeExtra("transaction_id")
            }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getStringExtra("route") == "/edit") {
            val id = intent.getIntExtra("transaction_id", -1)
            if (id != -1) {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, ExpenseTrackerApplication.METHOD_CHANNEL)
                        .invokeMethod("onEditDeepLink", id)
                }
                intent.removeExtra("transaction_id")
            }
        }
    }

    override fun onDestroy() {
        (application as ExpenseTrackerApplication).actionsMethodCallHandler.detachActivity(this)
        super.onDestroy()
    }
}
