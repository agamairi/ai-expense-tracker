import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_expense_tracker/domain/models/custom_category.dart';
import 'package:ai_expense_tracker/data/database.dart' hide CustomCategory;
import 'package:ai_expense_tracker/data/repositories/custom_category_repository_impl.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';

class ManageCategoriesView extends StatefulWidget {
  const ManageCategoriesView({super.key});

  @override
  State<ManageCategoriesView> createState() => _ManageCategoriesViewState();
}

class _ManageCategoriesViewState extends State<ManageCategoriesView> {
  final _categoryRepo = CustomCategoryRepositoryImpl(AppDatabase.instance);
  final _transactionRepo = TransactionRepositoryImpl(AppDatabase.instance);
  
  List<CustomCategory> _categories = [];
  bool _isLoading = true;

  final List<Color> _presetColors = [
    Colors.pink[300]!, Colors.red[400]!, Colors.blue[400]!, Colors.purple[300]!,
    Colors.orange[400]!, Colors.amber[400]!, Colors.teal[300]!, Colors.cyan[300]!,
    Colors.green[400]!, Colors.indigo[300]!, Colors.brown[300]!, Colors.grey[400]!,
  ];

  final List<IconData> _presetIcons = [
    Icons.category, Icons.shopping_bag, Icons.fastfood, Icons.directions_car,
    Icons.home, Icons.movie, Icons.favorite, Icons.pets,
    Icons.flight, Icons.fitness_center, Icons.school, Icons.build,
    Icons.card_giftcard, Icons.local_hospital, Icons.music_note, Icons.more_horiz,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final list = await _categoryRepo.getAllCustomCategories();
    setState(() {
      _categories = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteCategory(CustomCategory category) async {
    final transactions = await _transactionRepo.getAllTransactions();
    final hasReferences = transactions.any((tx) => tx.customCategoryId == category.id);

    if (hasReferences) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Cannot Delete Category"),
            content: const Text("This category is referenced by one or more transactions. You cannot delete it while it has transactions."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete category?"),
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
        await _categoryRepo.deleteCustomCategory(category.id);
        _loadCategories();
      }
    }
  }

  void _showAddEditDialog([CustomCategory? category]) {
    final nameController = TextEditingController(text: category?.name ?? '');
    Color selectedColor = category != null ? Color(category.colorValue) : _presetColors[0];
    IconData selectedIcon = category != null ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons') : _presetIcons[0];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(category == null ? "Add Category" : "Edit Category"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    const Text("Color", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetColors.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Icon", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetIcons.map((icon) {
                        final isSelected = selectedIcon.codePoint == icon.codePoint;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(50) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                            ),
                            child: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                          ),
                        );
                      }).toList(),
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final newCategory = CustomCategory(
                      id: category?.id ?? 0,
                      name: name,
                      colorValue: selectedColor.value,
                      iconCodePoint: selectedIcon.codePoint,
                    );

                    if (category == null) {
                      await _categoryRepo.insertCustomCategory(newCategory);
                    } else {
                      await _categoryRepo.updateCustomCategory(newCategory);
                    }
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadCategories();
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
        title: const Text("Manage Categories"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Category"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(category.colorValue),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Colors.white),
                    ),
                    title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.grey[400],
                          onPressed: () => _showAddEditDialog(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.grey[400],
                          onPressed: () => _deleteCategory(category),
                        ),
                      ],
                    ),
                    onTap: () => _showAddEditDialog(category),
                  ),
                ),
              );
            },
          ),
    );
  }
}
