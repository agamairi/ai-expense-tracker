package com.agamairi.ai_expense_tracker

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class ExpenseTrackerApplication : Application() {
    lateinit var actionsMethodCallHandler: ActionsMethodCallHandler
        private set

    override fun onCreate() {
        super.onCreate()

        val flutterEngine = FlutterEngine(this)
        actionsMethodCallHandler = ActionsMethodCallHandler(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler(actionsMethodCallHandler)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        FlutterEngineCache.getInstance().put("persistent_engine", flutterEngine)
    }

    companion object {
        const val METHOD_CHANNEL = "com.agamairi.ai_expense_tracker/actions"
    }
}
