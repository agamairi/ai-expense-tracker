import 'package:flutter/material.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/account.dart' as domain;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/data/database.dart' hide CustomCategory;
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/data/repositories/account_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/custom_category.dart';
import 'package:ai_expense_tracker/data/repositories/custom_category_repository_impl.dart';

class EditTransactionView extends StatefulWidget {
  const EditTransactionView({super.key});

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  bool _initialized = false;
  late model.Transaction _transaction;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  TransactionCategory _selectedCategory = TransactionCategory.other;
  int? _selectedCustomCategoryId;
  int? _selectedAccountId;
  
  List<domain.Account> _accounts = [];
  List<CustomCategory> _customCategories = [];

  final _transactionRepo = TransactionRepositoryImpl(AppDatabase.instance);
  final _accountRepo = AccountRepositoryImpl(AppDatabase.instance);
  final _customCategoryRepo = CustomCategoryRepositoryImpl(AppDatabase.instance);

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is model.Transaction) {
        _transaction = args;
        _amountController.text = _transaction.amount.toStringAsFixed(2);
        _merchantController.text = _transaction.merchant;
        _selectedCategory = _transaction.category;
        _selectedCustomCategoryId = _transaction.customCategoryId;
        _selectedAccountId = _transaction.accountId;
      } else {
        // Fallback for unexpected missing args, though route design says it shouldn't happen
        _transaction = model.Transaction(
          id: -1,
          timestamp: DateTime.now(),
          amount: 0.0,
          currency: 'USD',
          type: TransactionType.debit,
          merchant: '',
          category: TransactionCategory.other,
          accountId: 1,
          rawText: '',
          status: TransactionStatus.pending,
        );
        _amountController.text = "0.00";
        _merchantController.text = "";
      }
      _loadAccounts();
      _initialized = true;
    }
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountRepo.getAllAccounts();
    final customCategories = await _customCategoryRepo.getAllCustomCategories();
    setState(() {
      _accounts = accounts;
      _customCategories = customCategories;
      if (_accounts.isNotEmpty && _selectedAccountId == null) {
        _selectedAccountId = _accounts.first.id;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _saveAndApprove() async {
    final amount = double.tryParse(_amountController.text) ?? _transaction.amount;
    final updated = _transaction.copyWith(
      amount: amount,
      merchant: _merchantController.text,
      category: _selectedCustomCategoryId != null ? TransactionCategory.other : _selectedCategory,
      accountId: _selectedAccountId,
      status: TransactionStatus.approved,
      customCategoryId: _selectedCustomCategoryId,
    );
    if (_transaction.id == -1) {
      await _transactionRepo.insertTransaction(updated);
    } else {
      await _transactionRepo.updateTransaction(updated);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_transaction.id == -1 ? 'Add Transaction' : 'Edit Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(
                child: Text("AMOUNT", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Center(
                child: IntrinsicWidth(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("\$ ", style: TextStyle(color: colorScheme.primary, fontSize: 40, fontWeight: FontWeight.bold)),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: colorScheme.primary, fontSize: 48, fontWeight: FontWeight.w800),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(height: 2, color: colorScheme.primary, width: double.infinity, margin: const EdgeInsets.only(top: 8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              const Text("MERCHANT NAME", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.edit, color: Colors.grey[400], size: 20),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text("CATEGORY", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...TransactionCategory.values.map((cat) {
                    return _buildCategoryChip(cat, colorScheme);
                  }),
                  ..._customCategories.map((cat) {
                    return _buildCustomCategoryChip(cat, colorScheme);
                  }),
                  _buildNewCategoryChip(colorScheme),
                ],
              ),
              const SizedBox(height: 24),

              const Text("ACCOUNT", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    icon: const Icon(Icons.unfold_more, color: Colors.grey),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    items: _accounts.map((account) {
                      return DropdownMenuItem<int>(
                        value: account.id,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black.withAlpha(50), shape: BoxShape.circle),
                              child: const Icon(Icons.credit_card, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(account.name, style: const TextStyle(fontSize: 16)),
                                  Text(account.currency, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAccountId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text("RAW NOTIFICATION CONTEXT", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    iconColor: Colors.grey,
                    collapsedIconColor: Colors.grey,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Text(
                          _transaction.rawText.isNotEmpty ? _transaction.rawText : "No raw text available.",
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[800]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveAndApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(_transaction.id == -1 ? "Save Transaction" : "Save & Approve", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(TransactionCategory category, ColorScheme colorScheme) {
    final isSelected = _selectedCategory == category && _selectedCustomCategoryId == null;
    final label = category.name.substring(0, 1).toUpperCase() + category.name.substring(1);
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = category;
        _selectedCustomCategoryId = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : Colors.grey[300],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCategoryChip(CustomCategory category, ColorScheme colorScheme) {
    final isSelected = _selectedCustomCategoryId == category.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCustomCategoryId = category.id;
        _selectedCategory = TransactionCategory.other;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(category.colorValue) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), size: 16, color: isSelected ? Colors.white : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCategoryChip(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _showCreateCategoryDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withAlpha(128), width: 1),
        ),
        child: Text(
          "+ New",
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    Color selectedColor = _presetColors[0];
    IconData selectedIcon = _presetIcons[0];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New Category"),
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
                      id: 0,
                      name: name,
                      colorValue: selectedColor.value,
                      iconCodePoint: selectedIcon.codePoint,
                    );

                    final id = await _customCategoryRepo.insertCustomCategory(newCategory);
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    
                    await _loadAccounts();
                    setState(() {
                      _selectedCustomCategoryId = id;
                      _selectedCategory = TransactionCategory.other;
                    });
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
}
