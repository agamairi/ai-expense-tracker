import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_expense_tracker/domain/models/budget.dart' as domain;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/data/database.dart' hide CustomCategory;
import 'package:ai_expense_tracker/data/repositories/budget_repository_impl.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/custom_category.dart';
import 'package:ai_expense_tracker/data/repositories/custom_category_repository_impl.dart';

class ManageBudgetsView extends StatefulWidget {
  const ManageBudgetsView({super.key});

  @override
  State<ManageBudgetsView> createState() => _ManageBudgetsViewState();
}

class _ManageBudgetsViewState extends State<ManageBudgetsView> {
  final _budgetRepo = BudgetRepositoryImpl(AppDatabase.instance);
  final _transactionRepo = TransactionRepositoryImpl(AppDatabase.instance);
  final _customCategoryRepo = CustomCategoryRepositoryImpl(AppDatabase.instance);
  
  List<domain.Budget> _budgets = [];
  List<CustomCategory> _customCategories = [];
  Map<String, double> _spend = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final budgets = await _budgetRepo.getAllBudgets();
    final transactions = await _transactionRepo.getAllTransactions();
    final customCats = await _customCategoryRepo.getAllCustomCategories();
    
    final now = DateTime.now();
    Map<String, double> spend = {};
    for (final tx in transactions) {
      if (tx.status == TransactionStatus.approved && 
          tx.type == TransactionType.debit && 
          tx.timestamp.year == now.year && 
          tx.timestamp.month == now.month) {
        String key = tx.customCategoryId != null ? 'custom:${tx.customCategoryId}' : 'enum:${tx.category.name}';
        spend[key] = (spend[key] ?? 0) + tx.amount;
      }
    }

    setState(() {
      _budgets = budgets;
      _customCategories = customCats;
      _spend = spend;
      _isLoading = false;
    });
  }

  Future<void> _deleteBudget(domain.Budget budget) async {
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete budget?"),
          content: const Text("This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _budgetRepo.deleteBudget(budget.id);
        _loadData();
      }
    }
  }

  void _showAddEditDialog([domain.Budget? budget]) {
    final limitController = TextEditingController(text: budget != null ? budget.monthlyLimit.toStringAsFixed(2) : '');
    String? selectedCategoryKey = budget != null ? (budget.customCategoryId != null ? 'custom:${budget.customCategoryId}' : 'enum:${budget.category.name}') : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final usedCategories = _budgets.map((b) => b.customCategoryId != null ? 'custom:${b.customCategoryId}' : 'enum:${b.category.name}').toSet();
            final availableEnumCategories = TransactionCategory.values.where((c) {
              return budget != null && budget.customCategoryId == null && budget.category == c || !usedCategories.contains('enum:${c.name}');
            }).toList();
            final availableCustomCategories = _customCategories.where((c) {
              return budget != null && budget.customCategoryId == c.id || !usedCategories.contains('custom:${c.id}');
            }).toList();

            return AlertDialog(
              title: Text(budget == null ? "Add Budget" : "Edit Budget"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryKey,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: [
                        ...availableEnumCategories.map((cat) {
                          return DropdownMenuItem(
                            value: 'enum:${cat.name}',
                            child: Text(cat.name.replaceFirst(cat.name[0], cat.name[0].toUpperCase())),
                          );
                        }),
                        ...availableCustomCategories.map((cat) {
                          return DropdownMenuItem(
                            value: 'custom:${cat.id}',
                            child: Text(cat.name),
                          );
                        }),
                      ],
                      onChanged: budget == null ? (val) {
                        setDialogState(() => selectedCategoryKey = val);
                      } : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: limitController,
                      decoration: const InputDecoration(
                        labelText: "Monthly Limit",
                        prefixText: "\$ ",
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedCategoryKey == null) return;
                    final limit = double.tryParse(limitController.text) ?? 0.0;
                    if (limit <= 0) return;

                    bool isCustom = selectedCategoryKey!.startsWith('custom:');
                    TransactionCategory cat = isCustom ? TransactionCategory.other : TransactionCategory.values.firstWhere((e) => 'enum:${e.name}' == selectedCategoryKey);
                    int? customId = isCustom ? int.parse(selectedCategoryKey!.substring(7)) : null;

                    final newBudget = domain.Budget(
                      id: budget?.id ?? 0,
                      category: cat,
                      monthlyLimit: limit,
                      customCategoryId: customId,
                    );

                    await _budgetRepo.upsertBudget(newBudget);
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Manage Budgets"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Budget"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _budgets.isEmpty
            ? const Center(child: Text("No budgets set. Add one to get started."))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _budgets.length,
                itemBuilder: (context, index) {
                  final budget = _budgets[index];
                  String key = budget.customCategoryId != null ? 'custom:${budget.customCategoryId}' : 'enum:${budget.category.name}';
                  final currentSpend = _spend[key] ?? 0.0;
                  final progress = (currentSpend / budget.monthlyLimit).clamp(0.0, 1.0);
                  final isOver = currentSpend > budget.monthlyLimit;

                  String catName = budget.category.name.replaceFirst(budget.category.name[0], budget.category.name[0].toUpperCase());
                  if (budget.customCategoryId != null) {
                    final custom = _customCategories.where((c) => c.id == budget.customCategoryId).firstOrNull;
                    if (custom != null) {
                      catName = custom.name;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(catName, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("\$${currentSpend.toStringAsFixed(0)} / \$${budget.monthlyLimit.toStringAsFixed(0)}", 
                              style: TextStyle(color: isOver ? Colors.red : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white.withAlpha(20),
                              valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : colorScheme.primary),
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.grey[400],
                              onPressed: () => _showAddEditDialog(budget),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.grey[400],
                              onPressed: () => _deleteBudget(budget),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditDialog(budget),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
