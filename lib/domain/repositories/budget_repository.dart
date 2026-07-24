import 'package:ai_expense_tracker/domain/models/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getAllBudgets();
  Future<void> upsertBudget(Budget budget);
  Future<void> deleteBudget(int id);
}
