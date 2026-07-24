package com.agamairi.ai_expense_tracker

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class ExpenseTrackerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        FlutterEngineCache.getInstance().put("persistent_engine", flutterEngine)
    }
}
