import 'package:ai_expense_tracker/domain/models/enums.dart';

class Budget {
  final int id;
  final TransactionCategory category;
  final double monthlyLimit;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
  });

  Budget copyWith({
    int? id,
    TransactionCategory? category,
    double? monthlyLimit,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }
}
