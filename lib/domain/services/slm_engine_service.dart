import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/domain/repositories/app_rule_repository.dart';
import 'package:flutter/foundation.dart';

/// Note: The spec's 250MB RAM constraint is satisfied by the choice of the
/// quantized model itself, not by runtime enforcement in Dart.

class SlmModelConfig {
  static const url = 'https://huggingface.co/litert-community/functiongemma-mobile-actions_q8_ekv1024.litertlm/resolve/main/mobile-actions_q8_ekv1024.litertlm';
  static const modelType = ModelType.functionGemma;
  static const fileType = ModelFileType.litertlm;
}

class SlmEngineService {
  final AppRuleRepository _ruleRepository;
  bool _isInitialized = false;
  Timer? _idleTimer;
  InferenceModel? _activeModel;

  SlmEngineService(this._ruleRepository);

  Future<void> downloadAndInitialize() async {
    await FlutterGemma.initialize();

    try {
      await FlutterGemma.installModel(
        modelType: SlmModelConfig.modelType,
        fileType: SlmModelConfig.fileType,
      ).fromNetwork(SlmModelConfig.url).install();
    } catch (e) {
      debugPrint("Failed to reactivate model: $e");
    }

    _isInitialized = true;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 2), () {
      _activeModel?.close();
      _activeModel = null;
    });
  }

  static const _extractTool = Tool(
    name: 'extract_transaction',
    description: 'Extract structured transaction details from a bank or payment notification',
    parameters: {
      'type': 'object',
      'properties': {
        'amount': {'type': 'string', 'description': 'The transaction amount as a numeric string, e.g. "42.50" (no currency symbol)'},
        'currency': {'type': 'string', 'description': 'Three-letter currency code, e.g. USD'},
        'transaction_type': {'type': 'string', 'enum': ['DEBIT', 'CREDIT'], 'description': 'Whether money left (DEBIT) or was received (CREDIT)'},
        'merchant': {'type': 'string', 'description': 'The merchant or counterparty name'},
        'category': {'type': 'string', 'enum': ['Groceries','Dining','Transport','Shopping','Utilities','Entertainment','Health','Transfer','Income','Other'], 'description': 'Best-fit spending category'},
      },
      'required': ['amount', 'currency', 'transaction_type', 'merchant', 'category'],
    },
  );

  Future<Transaction?> processNotification(String title, String text) async {
    if (!_isInitialized) {
      await downloadAndInitialize();
    }
    
    _resetIdleTimer();

    _activeModel ??= await FlutterGemma.getActiveModel(maxTokens: 1024);
    final model = _activeModel!;
    final chat = await model.createChat(
      tools: [_extractTool],
      supportsFunctionCalls: true,
      toolChoice: ToolChoice.required,
      modelType: SlmModelConfig.modelType,
      temperature: 0.7,
    );
    await chat.addQueryChunk(Message(text: 'Notification: $title - $text', isUser: true));
    final response = await chat.generateChatResponse();
    await chat.close();
    
    _resetIdleTimer();

    Map<String, dynamic>? args;
    if (response is FunctionCallResponse && response.name == 'extract_transaction') {
      args = response.args;
    } else if (response is ParallelFunctionCallResponse) {
      try {
        final call = response.calls.firstWhere((c) => c.name == 'extract_transaction');
        args = call.args;
      } catch (e) {
        args = null;
      }
    }

    if (args == null) return null;

    final transaction = parseResponse(args, "$title $text");
    if (transaction != null) {
      return await _applyRuleOverrides(transaction);
    }
    return null;
  }

  @visibleForTesting
  Transaction? parseResponse(Map<String, dynamic> args, String rawText) {
    try {
      double amount = double.tryParse(args['amount']?.toString() ?? '') ?? 0;
      if (amount == 0) {
        final regex = RegExp(r'\$?\s?(\d+(?:\.\d{1,2})?)\s?\$?');
        final matches = regex.allMatches(rawText);
        if (matches.isNotEmpty) {
          final bestMatch = matches.cast<RegExpMatch?>().firstWhere(
            (m) => m!.group(0)!.contains('\$'),
            orElse: () => matches.first,
          );
          amount = double.tryParse(bestMatch!.group(1)!) ?? 0;
        }
      }
      
      String currency = "USD";
      final rawCurrency = (args['currency']?.toString() ?? '').trim();
      final match = RegExp(r'^[a-zA-Z]+').firstMatch(rawCurrency);
      if (match != null) {
        String c = match.group(0)!.toUpperCase();
        if (c.length > 3) c = c.substring(0, 3);
        if (c.length == 3) {
          currency = c;
        } else {
          currency = "USD";
        }
      } else {
        currency = "USD";
      }

      TransactionType type = TransactionType.debit;
      final typeStr = (args['transaction_type']?.toString() ?? '').trim().toUpperCase();
      type = typeStr == 'CREDIT' ? TransactionType.credit : TransactionType.debit;

      String merchant = "Unknown";
      final m = (args['merchant']?.toString() ?? '').trim();
      if (m.isEmpty || RegExp(r'^<.*>$').hasMatch(m)) {
        merchant = "Unknown";
      } else {
        merchant = m;
      }

      TransactionCategory category = TransactionCategory.other;
      final catStr = (args['category']?.toString() ?? '').trim().toLowerCase();
      category = TransactionCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == catStr,
        orElse: () => TransactionCategory.other,
      );

      if (category == TransactionCategory.income) {
        type = TransactionType.credit;
      }

      return Transaction(
        id: 0,
        timestamp: DateTime.now(),
        amount: amount,
        currency: currency,
        type: type,
        merchant: merchant,
        category: category,
        accountId: 1, // Default account
        rawText: rawText,
        status: TransactionStatus.pending,
      );
    } catch (e) {
      debugPrint("Failed to parse SLM response: $e");
      return null;
    }
  }

  Future<Transaction> _applyRuleOverrides(Transaction transaction) async {
    final rules = await _ruleRepository.getAllRules();
    for (var rule in rules) {
      final regex = Regex(rule.merchantRegex, caseSensitive: false);
      if (regex.hasMatch(transaction.merchant)) {
        if (rule.customCategoryId != null) {
          return transaction.copyWith(
            category: TransactionCategory.other,
            customCategoryId: rule.customCategoryId,
          );
        } else {
          return transaction.copyWith(
            category: rule.assignedCategory,
            clearCustomCategoryId: true,
          );
        }
      }
    }
    return transaction;
  }
}

class Regex {
  final RegExp _regExp;
  Regex(String pattern, {bool caseSensitive = true})
      : _regExp = RegExp(pattern, caseSensitive: caseSensitive);

  bool hasMatch(String input) => _regExp.hasMatch(input);
}
