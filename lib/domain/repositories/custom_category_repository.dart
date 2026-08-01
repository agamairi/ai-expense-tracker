import 'package:ai_expense_tracker/domain/models/custom_category.dart';

abstract class CustomCategoryRepository {
  Future<List<CustomCategory>> getAllCustomCategories();
  Future<int> insertCustomCategory(CustomCategory category);
  Future<void> updateCustomCategory(CustomCategory category);
  Future<void> deleteCustomCategory(int id);
}
