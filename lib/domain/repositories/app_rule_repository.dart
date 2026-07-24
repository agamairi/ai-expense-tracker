import 'package:ai_expense_tracker/domain/models/app_rule.dart';

abstract class AppRuleRepository {
  Future<List<AppRule>> getAllRules();
  Future<int> insertRule(AppRule rule);
  Future<void> updateRule(AppRule rule);
  Future<void> deleteRule(int id);
}
