import 'package:ai_expense_tracker/domain/models/enums.dart';

class AppRule {
  final int id;
  final String merchantRegex;
  final TransactionCategory assignedCategory;
  final int? customCategoryId;

  const AppRule({
    required this.id,
    required this.merchantRegex,
    required this.assignedCategory,
    this.customCategoryId,
  });

  AppRule copyWith({
    int? id,
    String? merchantRegex,
    TransactionCategory? assignedCategory,
    int? customCategoryId,
    bool clearCustomCategoryId = false,
  }) {
    return AppRule(
      id: id ?? this.id,
      merchantRegex: merchantRegex ?? this.merchantRegex,
      assignedCategory: assignedCategory ?? this.assignedCategory,
      customCategoryId: clearCustomCategoryId ? null : (customCategoryId ?? this.customCategoryId),
    );
  }
}
