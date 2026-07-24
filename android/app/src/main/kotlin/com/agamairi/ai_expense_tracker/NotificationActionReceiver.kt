package com.agamairi.ai_expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val transactionId = intent.getIntExtra("transaction_id", -1)
        if (transactionId == -1) return

        when (action) {
            "com.agamairi.ai_expense_tracker.APPROVE" -> {
                invokeFlutterAction(transactionId, "approve")
                NotificationManagerCompat.from(context).cancel(transactionId)
            }
            "com.agamairi.ai_expense_tracker.REJECT" -> {
                invokeFlutterAction(transactionId, "reject")
                NotificationManagerCompat.from(context).cancel(transactionId)
            }
            "com.agamairi.ai_expense_tracker.EDIT" -> {
                val launchIntent = Intent(context, MainActivity::class.java)
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                launchIntent.putExtra("route", "/edit")
                launchIntent.putExtra("transaction_id", transactionId)
                context.startActivity(launchIntent)
                NotificationManagerCompat.from(context).cancel(transactionId)
            }
        }
    }

    private fun invokeFlutterAction(transactionId: Int, action: String) {
        val engine = FlutterEngineCache.getInstance().get("persistent_engine")
        engine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, "com.agamairi.ai_expense_tracker/actions").invokeMethod(
                "onNotificationAction",
                mapOf("transactionId" to transactionId, "action" to action)
            )
        }
    }
}
