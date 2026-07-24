import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:ai_expense_tracker/domain/services/slm_engine_service.dart';
import 'package:ai_expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

class NotificationBridgeService {
  final SlmEngineService slmEngineService;
  final TransactionRepository _transactionRepository;
  
  static NotificationBridgeService? _instance;
  static NotificationBridgeService? get instance => _instance;

  NotificationBridgeService(this.slmEngineService, this._transactionRepository);

  void start() {
    _instance = this;
  }

  static Future<void> handleNativeEvent(String? method, dynamic arguments) async {
    if (method == 'onNotificationCaptured') {
      await _instance?._onNotificationEvent(arguments);
    }
  }

  Future<void> _onNotificationEvent(dynamic event) async {
    try {
      if (event is Map) {
        final title = event['title'] as String?;
        final text = event['text'] as String?;

        if (title != null && text != null) {
          final transaction = await slmEngineService.processNotification(title, text);
          if (transaction != null) {
            final pendingTransaction = transaction.copyWith(status: TransactionStatus.pending);
            final id = await _transactionRepository.insertTransaction(pendingTransaction);
            const MethodChannel('com.agamairi.ai_expense_tracker/actions').invokeMethod(
              'showCustomNotification',
              {
                'id': id,
                'title': 'New transaction detected',
                'text': '${pendingTransaction.merchant} • \$${pendingTransaction.amount.toStringAsFixed(2)} • ${pendingTransaction.category.name.toUpperCase()}',
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error processing notification event: $e");
    }
  }

  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
  }
}
