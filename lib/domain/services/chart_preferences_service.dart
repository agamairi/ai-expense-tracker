import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

enum ChartType { line, area, bar, pie }
enum ChartDataMode { cashflow, compareCategories }

class ChartPreferencesService {
  static const _chartTypeKey = 'chart_type';
  static const _dataModeKey = 'data_mode';


  Future<ChartType> getChartType() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_chartTypeKey);
    return ChartType.values.firstWhere((e) => e.name == val, orElse: () => ChartType.area);
  }

  Future<void> setChartType(ChartType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chartTypeKey, type.name);
  }

  Future<ChartDataMode> getDataMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_dataModeKey);
    return ChartDataMode.values.firstWhere((e) => e.name == val, orElse: () => ChartDataMode.cashflow);
  }

  Future<void> setDataMode(ChartDataMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataModeKey, mode.name);
  }

  static const _compareCategoriesKey = 'compare_categories';

  Future<List<TransactionCategory>> getCompareCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_compareCategoriesKey);
    if (list == null) return [];
    return list
        .map((name) => TransactionCategory.values.firstWhere(
              (e) => e.name == name,
              orElse: () => TransactionCategory.other,
            ))
        .toList();
  }

  Future<void> setCompareCategories(List<TransactionCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _compareCategoriesKey,
      categories.map((e) => e.name).toList(),
    );
  }
}
