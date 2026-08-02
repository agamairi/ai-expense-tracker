import 'package:drift/drift.dart';
import 'package:ai_expense_tracker/domain/models/budget.dart' as domain;
import 'package:ai_expense_tracker/domain/repositories/budget_repository.dart';
import 'package:ai_expense_tracker/data/database.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase _db;

  BudgetRepositoryImpl(this._db);

  domain.Budget _mapToDomain(Budget driftModel) {
    return domain.Budget(
      id: driftModel.id,
      category: driftModel.category,
      monthlyLimit: driftModel.monthlyLimit,
      customCategoryId: driftModel.customCategoryId,
    );
  }

  @override
  Future<List<domain.Budget>> getAllBudgets() async {
    final list = await _db.select(_db.budgets).get();
    return list.map(_mapToDomain).toList();
  }

  @override
  Future<void> upsertBudget(domain.Budget budget) async {
    final existing = await (_db.select(_db.budgets)
      ..where((t) {
        if (budget.customCategoryId != null) {
          return t.customCategoryId.equals(budget.customCategoryId!);
        } else {
          return t.category.equals(budget.category.index) & t.customCategoryId.isNull();
        }
      })
    ).getSingleOrNull();
    
    if (existing != null) {
      await _db.update(_db.budgets).replace(
        Budget(
          id: existing.id,
          category: budget.category,
          monthlyLimit: budget.monthlyLimit,
          customCategoryId: budget.customCategoryId,
        ),
      );
    } else {
      await _db.into(_db.budgets).insert(
        BudgetsCompanion(
          category: Value(budget.category),
          monthlyLimit: Value(budget.monthlyLimit),
          customCategoryId: Value(budget.customCategoryId),
        ),
      );
    }
  }

  @override
  Future<void> deleteBudget(int id) async {
    await (_db.delete(_db.budgets)..where((tbl) => tbl.id.equals(id))).go();
  }
}
