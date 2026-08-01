import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/data/database.dart' hide CustomCategory;
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/account.dart' as model_account;
import 'package:ai_expense_tracker/data/repositories/account_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/budget.dart' as domain_budget;
import 'package:ai_expense_tracker/data/repositories/budget_repository_impl.dart';
import 'package:ai_expense_tracker/presentation/history/audit_log_view.dart';
import 'package:ai_expense_tracker/domain/services/chart_preferences_service.dart';
import 'package:ai_expense_tracker/domain/services/category_colors.dart';
import 'package:ai_expense_tracker/domain/models/custom_category.dart';
import 'package:ai_expense_tracker/data/repositories/custom_category_repository_impl.dart';
import 'package:ai_expense_tracker/domain/services/custom_category_icons.dart';
import 'package:intl/intl.dart';

enum ChartPeriod {
  today,
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  all,
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => DashboardViewState();
}

class DashboardViewState extends State<DashboardView> {
  final _repo = TransactionRepositoryImpl(AppDatabase.instance);
  final _accountRepo = AccountRepositoryImpl(AppDatabase.instance);
  final _budgetRepo = BudgetRepositoryImpl(AppDatabase.instance);
  final _customCategoryRepo = CustomCategoryRepositoryImpl(AppDatabase.instance);
  final _chartPrefs = ChartPreferencesService();
  List<model.Transaction> _transactions = [];
  List<model_account.Account> _accounts = [];
  List<domain_budget.Budget> _budgets = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;
  ChartType _selectedChartType = ChartType.area;
  ChartDataMode _dataMode = ChartDataMode.cashflow;
  List<TransactionCategory> _compareCategories = [];
  ChartPeriod _selectedPeriod = ChartPeriod.oneMonth;
  final PageController _accountsPageController = PageController();
  int _currentAccountPage = 0;
  final List<String> _chartXLabels = [];
  double? _scrubbedValue;
  String? _scrubbedLabel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _accountsPageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await _repo.getAllTransactions();
    final accountList = await _accountRepo.getAllAccounts();
    final budgetList = await _budgetRepo.getAllBudgets();
    final cType = await _chartPrefs.getChartType();
    final dMode = await _chartPrefs.getDataMode();
    final compareCats = await _chartPrefs.getCompareCategories();
    final customCats = await _customCategoryRepo.getAllCustomCategories();
    setState(() {
      _transactions = list;
      _accounts = accountList;
      _budgets = budgetList;
      _customCategories = customCats;
      _selectedChartType = cType;
      _dataMode = dMode;
      _compareCategories = compareCats;
      _isLoading = false;
    });
  }

  Future<void> refresh() async {
    await _loadData();
  }

  List<model.Transaction> get _approvedTransactions =>
      _transactions.where((t) => t.status == TransactionStatus.approved).toList();

  List<model.Transaction> get _filteredTransactions {
    final now = DateTime.now();
    DateTime? startDate;
    switch (_selectedPeriod) {
      case ChartPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ChartPeriod.oneWeek:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ChartPeriod.oneMonth:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ChartPeriod.threeMonths:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case ChartPeriod.oneYear:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case ChartPeriod.all:
        startDate = null;
        break;
    }
    
    if (startDate == null) {
      return _approvedTransactions;
    }
    final start = startDate;
    return _approvedTransactions.where((t) => !t.timestamp.isBefore(start)).toList();
  }

  /// Returns a bucket key for the given timestamp.
  /// For [ChartPeriod.today], buckets by hour: "YYYY-MM-DD-HH".
  /// For all other periods, buckets by day: "YYYY-MM-DD".
  String _bucketKey(DateTime ts) {
    if (_selectedPeriod == ChartPeriod.today) {
      return "${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}-${ts.hour.toString().padLeft(2, '0')}";
    }
    return "${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}";
  }

  /// Returns a human-readable label for a bucket key.
  /// For [ChartPeriod.today], formats as hour label (e.g. "9AM", "2PM").
  /// For all other periods, formats as "MMM d" (e.g. "Jul 26").
  String _bucketLabel(String key) {
    if (_selectedPeriod == ChartPeriod.today) {
      // key format: "YYYY-MM-DD-HH"
      final parts = key.split('-');
      final hour = int.parse(parts[3]);
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), hour);
      return DateFormat('ha').format(dt);
    }
    final dt = DateTime.parse(key);
    return DateFormat('MMM d').format(dt);
  }

  double get _netCashflow {
    return _filteredTransactions.fold(0.0, (sum, tx) {
      if (tx.type == TransactionType.credit) {
        return sum + tx.amount;
      } else {
        return sum - tx.amount;
      }
    });
  }

  List<FlSpot> _getChartSpots() {
    if (_filteredTransactions.isEmpty) return [const FlSpot(0, 0)];
    
    Map<String, double> bucketTotals = {};
    for (final tx in _filteredTransactions) {
      final key = _bucketKey(tx.timestamp);
      final amount = tx.type == TransactionType.credit ? tx.amount : -tx.amount;
      bucketTotals[key] = (bucketTotals[key] ?? 0) + amount;
    }

    final sortedKeys = bucketTotals.keys.toList()..sort();
    
    List<FlSpot> spots = [const FlSpot(0, 0)];
    double cumulative = 0;
    
    for (int i = 0; i < sortedKeys.length; i++) {
      cumulative += bucketTotals[sortedKeys[i]]!;
      spots.add(FlSpot((i + 1).toDouble(), cumulative));
    }
    
    return spots;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 130.0, top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colorScheme),
              const SizedBox(height: 24),
              _buildSectionCard(
                colorScheme: colorScheme,
                child: _buildCashflowSection(colorScheme),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Accounts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.pushNamed(context, '/accounts');
                            _loadData();
                          },
                          child: Text("Manage", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAccountsRow(colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Budget", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.pushNamed(context, '/budgets');
                            _loadData();
                          },
                          child: Text("View All", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBudgetList(colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Recent Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildActivityList(colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final hasPending = _transactions.any((t) => t.status == TransactionStatus.pending);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("July 2026", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const AuditLogView(initialTab: 2)
            ));
          },
          child: Stack(
            children: [
              Icon(Icons.notifications_none, color: colorScheme.primary, size: 28),
              if (hasPending)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 1.5),
                    ),
                  ),
                )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: ChartPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          String label = "";
          switch (period) {
            case ChartPeriod.today: label = "1D"; break;
            case ChartPeriod.oneWeek: label = "1W"; break;
            case ChartPeriod.oneMonth: label = "1M"; break;
            case ChartPeriod.threeMonths: label = "3M"; break;
            case ChartPeriod.oneYear: label = "1Y"; break;
            case ChartPeriod.all: label = "ALL"; break;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                    _scrubbedValue = null;
                    _scrubbedLabel = null;
                  });
                }
              },
              selectedColor: colorScheme.primary,
              backgroundColor: Colors.transparent,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.onPrimary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? colorScheme.primary : Colors.white.withAlpha(20),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCashflowSection(ColorScheme colorScheme) {
    final net = _netCashflow;
    final showCompareLegend = _dataMode == ChartDataMode.compareCategories && _compareCategories.isNotEmpty && _selectedChartType != ChartType.pie;

    String defaultLabel = "";
    switch (_selectedPeriod) {
      case ChartPeriod.today: defaultLabel = "TODAY'S CASHFLOW"; break;
      case ChartPeriod.oneWeek: defaultLabel = "1W CASHFLOW"; break;
      case ChartPeriod.oneMonth: defaultLabel = "1M CASHFLOW"; break;
      case ChartPeriod.threeMonths: defaultLabel = "3M CASHFLOW"; break;
      case ChartPeriod.oneYear: defaultLabel = "1Y CASHFLOW"; break;
      case ChartPeriod.all: defaultLabel = "ALL TIME CASHFLOW"; break;
    }

    final displayLabel = (_selectedChartType == ChartType.pie) ? defaultLabel : (_scrubbedLabel ?? defaultLabel);
    final displayValue = (_selectedChartType == ChartType.pie) ? net : (_scrubbedValue ?? net);
    final displayIsPositive = displayValue >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayLabel, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text("${displayIsPositive ? '+' : '-'}\$${displayValue.abs().toStringAsFixed(2)}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildPeriodSelector(colorScheme),
        const SizedBox(height: 16),
        if (showCompareLegend)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: _compareCategories.map((cat) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryColor(cat), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(cat.name.replaceFirst(cat.name[0], cat.name[0].toUpperCase()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                );
              }).toList(),
            ),
          ),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(60),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(15), width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              key: ValueKey(_selectedChartType),
              child: _buildChart(colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(ColorScheme colorScheme) {
    if (_selectedChartType == ChartType.pie) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: _buildPieChartSection(colorScheme),
        ),
      );
    }
    _computeChartXLabels();

    double minY = 0;
    double maxY = 0;
    double minX = 0;
    double maxX = 0;
    List<BarChartGroupData>? barGroups;
    List<LineChartBarData>? lineBars;

    if (_selectedChartType == ChartType.bar) {
      barGroups = _getBarGroups(colorScheme);
      if (barGroups.isNotEmpty) {
        minY = barGroups.first.barRods.first.toY;
        maxY = minY;
        minX = barGroups.first.x.toDouble();
        maxX = minX;
        for (final group in barGroups) {
          if (group.x.toDouble() < minX) minX = group.x.toDouble();
          if (group.x.toDouble() > maxX) maxX = group.x.toDouble();
          for (final rod in group.barRods) {
            if (rod.toY < minY) minY = rod.toY;
            if (rod.toY > maxY) maxY = rod.toY;
          }
        }
      }
    } else {
      lineBars = _getLineBarsData(colorScheme);
      if (lineBars.isNotEmpty && lineBars.first.spots.isNotEmpty) {
        minY = lineBars.first.spots.first.y;
        maxY = minY;
        minX = lineBars.first.spots.first.x;
        maxX = minX;
        for (final line in lineBars) {
          for (final spot in line.spots) {
            if (spot.y < minY) minY = spot.y;
            if (spot.y > maxY) maxY = spot.y;
            if (spot.x < minX) minX = spot.x;
            if (spot.x > maxX) maxX = spot.x;
          }
        }
      }
    }

    double range = maxY - minY;
    double yInterval = (range / 3).ceilToDouble();
    
    double maxAbs = minY.abs() > maxY.abs() ? minY.abs() : maxY.abs();
    double minInterval = maxAbs * 0.15;
    if (minInterval < 100) minInterval = 100;
    
    if (yInterval < minInterval) {
      yInterval = minInterval.ceilToDouble();
    }
    
    if (yInterval == 0) yInterval = 10;

    double adjustedMinY = minY - yInterval;
    double adjustedMaxY = maxY + yInterval;

    if (_selectedChartType == ChartType.bar) {
      return BarChart(
        BarChartData(
          minY: adjustedMinY,
          maxY: adjustedMaxY,
          barTouchData: _buildBarTouchData(colorScheme),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withAlpha(15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      "\$${value.toInt()}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= _chartXLabels.length) return const SizedBox.shrink();
                  if (_chartXLabels[index].isEmpty) return const SizedBox.shrink();

                  int totalLabels = _chartXLabels.length;
                  bool shouldShow = false;
                  if (totalLabels <= 4) {
                    shouldShow = true;
                  } else {
                    int step = (totalLabels / 3).ceil();
                    if (index == 0 || index == totalLabels - 1 || index % step == 0) {
                      shouldShow = true;
                    }
                  }

                  if (!shouldShow) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _chartXLabels[index],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups ?? [],
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineTouchData: _buildLineTouchData(colorScheme),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withAlpha(15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    "\$${value.toInt()}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index < 0 || index >= _chartXLabels.length) return const SizedBox.shrink();
                if (_chartXLabels[index].isEmpty) return const SizedBox.shrink();

                int totalLabels = _chartXLabels.length;
                bool shouldShow = false;
                if (totalLabels <= 4) {
                  shouldShow = true;
                } else {
                  int step = (totalLabels / 3).ceil();
                  if (index == 0 || index == totalLabels - 1 || index % step == 0) {
                    shouldShow = true;
                  }
                }

                if (!shouldShow) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _chartXLabels[index],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBars ?? [],
      ),
    );
  }

  void _computeChartXLabels() {
    _chartXLabels.clear();
    if (_filteredTransactions.isEmpty) return;

    if (_dataMode == ChartDataMode.compareCategories && _compareCategories.isNotEmpty) {
      Set<String> allKeys = {};
      for (final tx in _filteredTransactions) {
        if (tx.type != TransactionType.debit) continue;
        if (_compareCategories.contains(tx.category)) {
          allKeys.add(_bucketKey(tx.timestamp));
        }
      }
      final sortedKeys = allKeys.toList()..sort();
      for (final key in sortedKeys) {
        _chartXLabels.add(_bucketLabel(key));
      }
    } else {
      Set<String> allKeys = {};
      for (final tx in _filteredTransactions) {
        allKeys.add(_bucketKey(tx.timestamp));
      }
      final sortedKeys = allKeys.toList()..sort();
      
      if (_selectedChartType != ChartType.bar && sortedKeys.isNotEmpty) {
        _chartXLabels.add(_bucketLabel(sortedKeys.first));
      } else if (_selectedChartType == ChartType.bar && sortedKeys.length == 1) {
        _chartXLabels.add('');
      }
      
      for (final key in sortedKeys) {
        _chartXLabels.add(_bucketLabel(key));
      }
    }
  }

  LineTouchData _buildLineTouchData(ColorScheme colorScheme) {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((index) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: colorScheme.primary.withAlpha(120),
              strokeWidth: 1.5,
            ),
            FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: barData.color ?? colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) => null).toList();
        },
      ),
      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
        if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null || touchResponse.lineBarSpots!.isEmpty) {
          setState(() {
            _scrubbedValue = null;
            _scrubbedLabel = null;
          });
          return;
        }

        final spot = touchResponse.lineBarSpots!.first;
        final index = spot.x.toInt();
        
        setState(() {
          _scrubbedValue = spot.y;
          if (_dataMode == ChartDataMode.compareCategories && _compareCategories.isNotEmpty) {
            if (spot.barIndex < _compareCategories.length) {
              final cat = _compareCategories[spot.barIndex];
              final catName = cat.name;
              _scrubbedLabel = catName.replaceFirst(catName[0], catName[0].toUpperCase());
            } else {
               _scrubbedLabel = (index >= 0 && index < _chartXLabels.length) ? _chartXLabels[index] : '';
            }
          } else {
            _scrubbedLabel = (index >= 0 && index < _chartXLabels.length) ? _chartXLabels[index] : '';
          }
        });
      },
    );
  }

  BarTouchData _buildBarTouchData(ColorScheme colorScheme) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return null;
        },
      ),
      touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
        if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.spot == null) {
          setState(() {
            _scrubbedValue = null;
            _scrubbedLabel = null;
          });
          return;
        }

        final spot = touchResponse.spot!;
        final index = spot.touchedBarGroupIndex;
        
        setState(() {
          _scrubbedValue = spot.touchedRodData.toY;
          if (_dataMode == ChartDataMode.compareCategories && _compareCategories.isNotEmpty) {
            if (spot.touchedRodDataIndex < _compareCategories.length) {
              final cat = _compareCategories[spot.touchedRodDataIndex];
              final catName = cat.name;
              _scrubbedLabel = catName.replaceFirst(catName[0], catName[0].toUpperCase());
            } else {
               _scrubbedLabel = (index >= 0 && index < _chartXLabels.length) ? _chartXLabels[index] : '';
            }
          } else {
            _scrubbedLabel = (index >= 0 && index < _chartXLabels.length) ? _chartXLabels[index] : '';
          }
        });
      },
    );
  }

  List<LineChartBarData> _getLineBarsData(ColorScheme colorScheme) {
    if (_dataMode == ChartDataMode.compareCategories && _compareCategories.isNotEmpty) {
      Map<TransactionCategory, Map<String, double>> catTotals = {};
      for (final cat in _compareCategories) {
        catTotals[cat] = {};
      }
      Set<String> allKeys = {};
      
      for (final tx in _filteredTransactions) {
        if (tx.type != TransactionType.debit) continue;
        if (_compareCategories.contains(tx.category)) {
          final key = _bucketKey(tx.timestamp);
          catTotals[tx.category]![key] = (catTotals[tx.category]![key] ?? 0) + tx.amount;
          allKeys.add(key);
        }
      }

      final sortedKeys = allKeys.toList()..sort();
      List<LineChartBarData> lines = [];
      
      for (final cat in _compareCategories) {
        List<FlSpot> spots = [];
        if (sortedKeys.isEmpty) {
          spots = [const FlSpot(0, 0)];
        } else if (sortedKeys.length == 1) {
          // Pad with a baseline zero point so the line chart doesn't degenerate
          spots.add(const FlSpot(0, 0));
          spots.add(FlSpot(1, catTotals[cat]![sortedKeys[0]] ?? 0));
        } else {
          for (int i = 0; i < sortedKeys.length; i++) {
            final key = sortedKeys[i];
            spots.add(FlSpot(i.toDouble(), catTotals[cat]![key] ?? 0));
          }
        }
        lines.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: categoryColor(cat),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: _selectedChartType == ChartType.area,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [categoryColor(cat).withAlpha(50), Colors.transparent],
              ),
            ),
          ),
        );
      }
      return lines;
    }
    
    return [
      LineChartBarData(
        spots: _getChartSpots(),
        isCurved: true,
        curveSmoothness: 0.35,
        color: colorScheme.primary,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: _selectedChartType == ChartType.area,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withAlpha(50),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ];
  }

  List<BarChartGroupData> _getBarGroups(ColorScheme colorScheme) {
    if (_transactions.isEmpty) return [];

    if (_dataMode == ChartDataMode.compareCategories && _compareCategories.isNotEmpty) {
      Map<TransactionCategory, Map<String, double>> catTotals = {};
      for (final cat in _compareCategories) {
        catTotals[cat] = {};
      }
      Set<String> allKeys = {};
      
      for (final tx in _filteredTransactions) {
        if (tx.type != TransactionType.debit) continue;
        if (_compareCategories.contains(tx.category)) {
          final key = _bucketKey(tx.timestamp);
          catTotals[tx.category]![key] = (catTotals[tx.category]![key] ?? 0) + tx.amount;
          allKeys.add(key);
        }
      }

      final sortedKeys = allKeys.toList()..sort();
      List<BarChartGroupData> groups = [];
      
      double barWidth = 6.0;
      double barsSpace = 4.0;
      if (_compareCategories.length > 2) {
        barWidth = 12.0 / _compareCategories.length;
        if (barWidth < 2) barWidth = 2;
        barsSpace = 2.0;
      }

      // Pad with a transparent zero-value group when only 1 bucket to avoid degenerate bar rendering
      if (sortedKeys.length == 1) {
        List<BarChartRodData> zeroRods = [];
        for (final _ in _compareCategories) {
          zeroRods.add(
            BarChartRodData(
              toY: 0,
              color: Colors.transparent,
              width: barWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(4)),
            ),
          );
        }
        groups.add(
          BarChartGroupData(
            x: 0,
            barsSpace: barsSpace,
            barRods: zeroRods,
          ),
        );
      }
      
      for (int i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        
        List<BarChartRodData> rods = [];
        for (final cat in _compareCategories) {
          final val = catTotals[cat]![key] ?? 0;
          rods.add(
            BarChartRodData(
              toY: val, 
              color: categoryColor(cat), 
              width: barWidth, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(4))
            ),
          );
        }
        
        groups.add(
          BarChartGroupData(
            x: sortedKeys.length == 1 ? i + 1 : i,
            barsSpace: barsSpace,
            barRods: rods,
          ),
        );
      }
      return groups;
    }

    Map<String, double> bucketTotals = {};
    for (final tx in _filteredTransactions) {
      final key = _bucketKey(tx.timestamp);
      final amount = tx.type == TransactionType.credit ? tx.amount : -tx.amount;
      bucketTotals[key] = (bucketTotals[key] ?? 0) + amount;
    }

    final sortedKeys = bucketTotals.keys.toList()..sort();
    
    List<BarChartGroupData> groups = [];
    
    if (sortedKeys.length == 1) {
      groups.add(
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.transparent,
              width: 8,
            ),
          ],
        ),
      );
    }
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final net = bucketTotals[key]!;
      final isPositive = net >= 0;
      
      groups.add(
        BarChartGroupData(
          x: sortedKeys.length == 1 ? i + 1 : i,
          barRods: [
            BarChartRodData(
              toY: net,
              color: isPositive ? colorScheme.primary : Colors.red[400],
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4), 
                bottom: Radius.circular(4)
              ),
            ),
          ],
        ),
      );
    }
    
    return groups;
  }

  Widget _buildAccountsRow(ColorScheme colorScheme) {
    final itemCount = _accounts.length + 1;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _accountsPageController,
            onPageChanged: (index) {
              setState(() {
                _currentAccountPage = index;
              });
            },
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == _accounts.length) {
                return _buildAddAccountCard(colorScheme);
              }
              
              final acc = _accounts[index];
              return _buildLargeAccountCard(colorScheme, acc);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (index) {
            final isCurrent = index == _currentAccountPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isCurrent ? 24 : 8,
              decoration: BoxDecoration(
                color: isCurrent ? colorScheme.primary : Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLargeAccountCard(ColorScheme colorScheme, model_account.Account acc) {
    final now = DateTime.now();
    double monthlyDelta = 0;
    double liveBalance = acc.balance;
    for (final tx in _approvedTransactions) {
      if (tx.accountId == acc.id) {
        liveBalance += (tx.type == TransactionType.credit ? tx.amount : -tx.amount);
        if (tx.timestamp.year == now.year && tx.timestamp.month == now.month) {
          monthlyDelta += (tx.type == TransactionType.credit ? tx.amount : -tx.amount);
        }
      }
    }
    final isPositive = monthlyDelta >= 0;
    final deltaStr = "${isPositive ? '+' : '-'}\$${monthlyDelta.abs().toStringAsFixed(2)}";

    final accountTxs = _approvedTransactions.where((t) => t.accountId == acc.id).toList();
    accountTxs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    List<FlSpot> spots = [];
    double cumulative = 0;
    if (accountTxs.isEmpty) {
      spots = [const FlSpot(0, 0)];
    } else {
      for (int i = 0; i < accountTxs.length; i++) {
        final tx = accountTxs[i];
        cumulative += (tx.type == TransactionType.credit ? tx.amount : -tx.amount);
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.account_balance_wallet, color: colorScheme.primary, size: 28),
              Text(acc.name, style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("\$${liveBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text("$deltaStr this month", style: TextStyle(color: isPositive ? Colors.green : Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 40,
                child: LineChart(
                  LineChartData(
                    minX: spots.first.x,
                    maxX: spots.last.x,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      drawHorizontalLine: false,
                    ),
                    titlesData: const FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: isPositive ? Colors.green : colorScheme.primary,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/accounts');
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(128),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(20), width: 2),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 48),
            const SizedBox(height: 16),
            const Text("Add Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(ColorScheme colorScheme) {
    if (_budgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text("No budgets set — tap View All to add one", style: TextStyle(color: Colors.grey))),
      );
    }

    final now = DateTime.now();
    Map<TransactionCategory, double> spendMap = {};
    
    for (final tx in _approvedTransactions) {
      if (tx.type == TransactionType.debit && tx.timestamp.year == now.year && tx.timestamp.month == now.month) {
        spendMap[tx.category] = (spendMap[tx.category] ?? 0) + tx.amount;
      }
    }
    
    final displayBudgets = _budgets.take(3).toList();

    return Column(
      children: displayBudgets.map((budget) {
        final spend = spendMap[budget.category] ?? 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildBudgetRow(colorScheme, budget.category, spend, budget.monthlyLimit, _getCategoryColor(colorScheme, budget.category, null), _getCategoryIcon(budget.category, null)),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(ColorScheme colorScheme, TransactionCategory cat, int? customCategoryId) {
    if (customCategoryId != null) {
      final custom = _customCategories.where((c) => c.id == customCategoryId).firstOrNull;
      if (custom != null) {
        return Color(custom.colorValue);
      }
    }
    switch (cat) {
      case TransactionCategory.groceries: return Colors.pink[200]!;
      case TransactionCategory.dining: return Colors.red[400]!;
      case TransactionCategory.transport: return colorScheme.primary;
      default: return Colors.orange[300]!;
    }
  }

  Widget _buildBudgetRow(ColorScheme colorScheme, TransactionCategory cat, double spend, double limit, Color color, IconData icon) {
    final progress = limit > 0 ? (spend / limit).clamp(0.0, 1.0) : 0.0;
    final label = cat.name.replaceFirst(cat.name[0], cat.name[0].toUpperCase());

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AuditLogView(initialCategory: cat)
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(15), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: color.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Icon(icon, color: Colors.grey[300], size: 20),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text("${(progress * 100).toInt()}% of limit", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
            Text("\$${spend.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(ColorScheme colorScheme) {
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text("No recent activity.", style: TextStyle(color: Colors.grey))),
      );
    }
    
    // Show 4 most recent
    final recent = List<model.Transaction>.from(_transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return Column(
      children: recent.take(4).map((tx) {
        final isPositive = tx.type == TransactionType.credit;
        final icon = _getCategoryIcon(tx.category, tx.customCategoryId);

        return _buildActivityRow(
          colorScheme, 
          tx.merchant, 
          "Aug ${tx.timestamp.day}", 
          "${isPositive ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}", 
          icon, 
          tx.status == TransactionStatus.pending ? "PENDING" : "AUDITED", 
          isPositive: isPositive
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category, int? customCategoryId) {
    if (customCategoryId != null) {
      final custom = _customCategories.where((c) => c.id == customCategoryId).firstOrNull;
      if (custom != null) {
        return iconForCustomCategory(custom.iconCodePoint);
      }
    }
    switch (category) {
      case TransactionCategory.groceries: return Icons.local_grocery_store;
      case TransactionCategory.dining: return Icons.restaurant;
      case TransactionCategory.transport: return Icons.directions_car;
      default: return Icons.receipt;
    }
  }

  Widget _buildActivityRow(ColorScheme colorScheme, String title, String subtitle, String amount, IconData icon, String tag, {bool isPositive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isPositive ? colorScheme.primary : Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(ColorScheme colorScheme) {
    final debits = _filteredTransactions.where((t) => t.type == TransactionType.debit).toList();
    
    if (debits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text("No spending data for this period", style: TextStyle(color: Colors.grey))),
      );
    }

    // Use a custom string key to group by either enum category or custom category id
    // format: "enum:NAME" or "custom:ID"
    Map<String, double> groupTotals = {};
    Map<String, TransactionCategory> groupToEnum = {};
    Map<String, int?> groupToCustom = {};

    for (final tx in debits) {
      String key;
      if (tx.customCategoryId != null) {
        key = "custom:${tx.customCategoryId}";
        groupToCustom[key] = tx.customCategoryId;
      } else {
        key = "enum:${tx.category.name}";
        groupToEnum[key] = tx.category;
      }
      groupTotals[key] = (groupTotals[key] ?? 0) + tx.amount;
    }

    final sortedKeys = groupTotals.keys.toList()..sort((a, b) => groupTotals[b]!.compareTo(groupTotals[a]!));
    double totalSpend = debits.fold(0.0, (sum, tx) => sum + tx.amount);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sortedKeys.map((key) {
                final amount = groupTotals[key]!;
                final percent = amount / totalSpend;
                Color color;
                if (key.startsWith("custom:")) {
                  final customId = groupToCustom[key]!;
                  color = _getCategoryColor(colorScheme, TransactionCategory.other, customId);
                } else {
                  color = categoryColor(groupToEnum[key]!);
                }
                return PieChartSectionData(
                  color: color,
                  value: amount,
                  title: percent > 0.05 ? '${(percent * 100).toStringAsFixed(0)}%' : '',
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: sortedKeys.map((key) {
            final amount = groupTotals[key]!;
            
            String name;
            Color color;
            if (key.startsWith("custom:")) {
              final customId = groupToCustom[key]!;
              final custom = _customCategories.where((c) => c.id == customId).firstOrNull;
              name = custom?.name ?? "Custom";
              color = _getCategoryColor(colorScheme, TransactionCategory.other, customId);
            } else {
              final cat = groupToEnum[key]!;
              name = cat.name.replaceFirst(cat.name[0], cat.name[0].toUpperCase());
              color = categoryColor(cat);
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "$name (\$${amount.toStringAsFixed(0)})",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required ColorScheme colorScheme, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
