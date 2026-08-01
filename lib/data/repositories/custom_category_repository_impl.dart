import 'package:drift/drift.dart';
import 'package:ai_expense_tracker/domain/models/custom_category.dart' as domain;
import 'package:ai_expense_tracker/domain/repositories/custom_category_repository.dart';
import 'package:ai_expense_tracker/data/database.dart';

class CustomCategoryRepositoryImpl implements CustomCategoryRepository {
  final AppDatabase _db;

  CustomCategoryRepositoryImpl(this._db);

  domain.CustomCategory _mapToDomain(CustomCategory driftModel) {
    return domain.CustomCategory(
      id: driftModel.id,
      name: driftModel.name,
      colorValue: driftModel.colorValue,
      iconCodePoint: driftModel.iconCodePoint,
    );
  }

  @override
  Future<List<domain.CustomCategory>> getAllCustomCategories() async {
    final list = await _db.select(_db.customCategories).get();
    return list.map(_mapToDomain).toList();
  }

  @override
  Future<int> insertCustomCategory(domain.CustomCategory category) async {
    return await _db.into(_db.customCategories).insert(
      CustomCategoriesCompanion(
        name: Value(category.name),
        colorValue: Value(category.colorValue),
        iconCodePoint: Value(category.iconCodePoint),
      ),
    );
  }

  @override
  Future<void> updateCustomCategory(domain.CustomCategory category) async {
    await _db.update(_db.customCategories).replace(
      CustomCategory(
        id: category.id,
        name: category.name,
        colorValue: category.colorValue,
        iconCodePoint: category.iconCodePoint,
      ),
    );
  }

  @override
  Future<void> deleteCustomCategory(int id) async {
    await (_db.delete(_db.customCategories)..where((tbl) => tbl.id.equals(id))).go();
  }
}
