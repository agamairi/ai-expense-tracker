import 'package:drift/drift.dart';
import 'package:ai_expense_tracker/domain/models/app_rule.dart' as domain;
import 'package:ai_expense_tracker/domain/repositories/app_rule_repository.dart';
import 'package:ai_expense_tracker/data/database.dart';

class AppRuleRepositoryImpl implements AppRuleRepository {
  final AppDatabase _db;

  AppRuleRepositoryImpl(this._db);

  domain.AppRule _mapToDomain(AppRule driftModel) {
    return domain.AppRule(
      id: driftModel.id,
      merchantRegex: driftModel.merchantRegex,
      assignedCategory: driftModel.assignedCategory,
      customCategoryId: driftModel.customCategoryId,
    );
  }

  @override
  Future<List<domain.AppRule>> getAllRules() async {
    final list = await _db.select(_db.appRules).get();
    return list.map(_mapToDomain).toList();
  }

  @override
  Future<int> insertRule(domain.AppRule rule) async {
    return await _db.into(_db.appRules).insert(
      AppRulesCompanion(
        merchantRegex: Value(rule.merchantRegex),
        assignedCategory: Value(rule.assignedCategory),
        customCategoryId: Value(rule.customCategoryId),
      ),
    );
  }

  @override
  Future<void> deleteRule(int id) async {
    await (_db.delete(_db.appRules)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> updateRule(domain.AppRule rule) async {
    await _db.update(_db.appRules).replace(
      AppRulesCompanion(
        id: Value(rule.id),
        merchantRegex: Value(rule.merchantRegex),
        assignedCategory: Value(rule.assignedCategory),
        customCategoryId: Value(rule.customCategoryId),
      ),
    );
  }
}
