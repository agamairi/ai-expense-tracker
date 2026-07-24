import 'package:ai_expense_tracker/domain/models/enums.dart';

class Transaction {
  final int id;
  final DateTime timestamp;
  final double amount;
  final String currency;
  final TransactionType type;
  final String merchant;
  final TransactionCategory category;
  final int accountId;
  final String rawText;
  final TransactionStatus status;

  const Transaction({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.currency,
    required this.type,
    required this.merchant,
    required this.category,
    required this.accountId,
    required this.rawText,
    required this.status,
  });

  Transaction copyWith({
    int? id,
    DateTime? timestamp,
    double? amount,
    String? currency,
    TransactionType? type,
    String? merchant,
    TransactionCategory? category,
    int? accountId,
    String? rawText,
    TransactionStatus? status,
  }) {
    return Transaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      rawText: rawText ?? this.rawText,
      status: status ?? this.status,
    );
  }
}
