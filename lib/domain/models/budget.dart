import 'package:ai_expense_tracker/domain/models/enums.dart';

class Budget {
  final int id;
  final TransactionCategory category;
  final double monthlyLimit;
  final int? customCategoryId;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    this.customCategoryId,
  });

  Budget copyWith({
    int? id,
    TransactionCategory? category,
    double? monthlyLimit,
    int? customCategoryId,
    bool clearCustomCategoryId = false,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      customCategoryId: clearCustomCategoryId ? null : (customCategoryId ?? this.customCategoryId),
    );
  }
}
