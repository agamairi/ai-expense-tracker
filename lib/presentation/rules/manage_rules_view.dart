import 'package:flutter/material.dart';
import 'package:ai_expense_tracker/domain/models/app_rule.dart' as domain;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/data/database.dart' hide CustomCategory;
import 'package:ai_expense_tracker/data/repositories/app_rule_repository_impl.dart';
import 'package:ai_expense_tracker/domain/services/category_colors.dart';
import 'package:ai_expense_tracker/domain/models/custom_category.dart';
import 'package:ai_expense_tracker/data/repositories/custom_category_repository_impl.dart';

class ManageRulesView extends StatefulWidget {
  const ManageRulesView({super.key});

  @override
  State<ManageRulesView> createState() => _ManageRulesViewState();
}

class _ManageRulesViewState extends State<ManageRulesView> {
  final _ruleRepo = AppRuleRepositoryImpl(AppDatabase.instance);
  final _customCategoryRepo = CustomCategoryRepositoryImpl(AppDatabase.instance);
  
  List<domain.AppRule> _rules = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rules = await _ruleRepo.getAllRules();
    final customCats = await _customCategoryRepo.getAllCustomCategories();
    
    setState(() {
      _rules = rules;
      _customCategories = customCats;
      _isLoading = false;
    });
  }

  Future<void> _deleteRule(domain.AppRule rule) async {
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete this rule?"),
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
        await _ruleRepo.deleteRule(rule.id);
        _loadData();
      }
    }
  }

  void _showAddEditDialog([domain.AppRule? rule]) {
    final patternController = TextEditingController(text: rule?.merchantRegex ?? '');
    String? selectedCategoryKey = rule != null ? (rule.customCategoryId != null ? 'custom:${rule.customCategoryId}' : 'enum:${rule.assignedCategory.name}') : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(rule == null ? "Add Rule" : "Edit Rule"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: patternController,
                      decoration: const InputDecoration(
                        labelText: "Merchant pattern (regex)",
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryKey,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: [
                        ...TransactionCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: 'enum:${cat.name}',
                            child: Text(cat.name.replaceFirst(cat.name[0], cat.name[0].toUpperCase())),
                          );
                        }),
                        ..._customCategories.map((cat) {
                          return DropdownMenuItem(
                            value: 'custom:${cat.id}',
                            child: Text(cat.name),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedCategoryKey = val);
                      },
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
                    final pattern = patternController.text.trim();
                    if (pattern.isEmpty) return;

                    bool isCustom = selectedCategoryKey!.startsWith('custom:');
                    TransactionCategory cat = isCustom ? TransactionCategory.other : TransactionCategory.values.firstWhere((e) => 'enum:${e.name}' == selectedCategoryKey);
                    int? customId = isCustom ? int.parse(selectedCategoryKey!.substring(7)) : null;

                    final newRule = domain.AppRule(
                      id: rule?.id ?? 0,
                      merchantRegex: pattern,
                      assignedCategory: cat,
                      customCategoryId: customId,
                    );

                    if (rule == null) {
                      await _ruleRepo.insertRule(newRule);
                    } else {
                      await _ruleRepo.updateRule(newRule);
                    }
                    
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
        title: const Text("Manage Category Rules"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Rule"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _rules.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text("No category rules set. Add one to auto-categorize matching merchants.", textAlign: TextAlign.center),
              ))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _rules.length,
                itemBuilder: (context, index) {
                  final rule = _rules[index];
                  
                  Color catColor = categoryColor(rule.assignedCategory);
                  String catName = rule.assignedCategory.name.toUpperCase();
                  if (rule.customCategoryId != null) {
                    final custom = _customCategories.where((c) => c.id == rule.customCategoryId).firstOrNull;
                    if (custom != null) {
                      catColor = Color(custom.colorValue);
                      catName = custom.name.toUpperCase();
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(rule.merchantRegex, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: catColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: catColor),
                              ),
                              child: Text(
                                catName,
                                style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.grey[400],
                              onPressed: () => _showAddEditDialog(rule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.grey[400],
                              onPressed: () => _deleteRule(rule),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditDialog(rule),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
