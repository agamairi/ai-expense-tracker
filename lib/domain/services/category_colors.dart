import 'package:flutter/material.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

Color categoryColor(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.groceries:
      return Colors.pink[300]!;
    case TransactionCategory.dining:
      return Colors.red[400]!;
    case TransactionCategory.transport:
      return Colors.blue[400]!;
    case TransactionCategory.shopping:
      return Colors.purple[300]!;
    case TransactionCategory.utilities:
      return Colors.orange[400]!;
    case TransactionCategory.entertainment:
      return Colors.amber[400]!;
    case TransactionCategory.health:
      return Colors.teal[300]!;
    case TransactionCategory.transfer:
      return Colors.cyan[300]!;
    case TransactionCategory.income:
      return Colors.green[400]!;
    case TransactionCategory.other:
      return Colors.grey[400]!;
  }
}
