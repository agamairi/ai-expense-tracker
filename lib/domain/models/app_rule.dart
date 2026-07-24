import 'package:ai_expense_tracker/domain/models/enums.dart';

class AppRule {
  final int id;
  final String merchantRegex;
  final TransactionCategory assignedCategory;

  const AppRule({
    required this.id,
    required this.merchantRegex,
    required this.assignedCategory,
  });
}
