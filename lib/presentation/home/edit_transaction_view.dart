import 'package:flutter/material.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/account.dart' as domain;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/data/repositories/account_repository_impl.dart';

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
  int? _selectedAccountId;
  
  List<domain.Account> _accounts = [];

  final _transactionRepo = TransactionRepositoryImpl(AppDatabase.instance);
  final _accountRepo = AccountRepositoryImpl(AppDatabase.instance);

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
    setState(() {
      _accounts = accounts;
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
      category: _selectedCategory,
      accountId: _selectedAccountId,
      status: TransactionStatus.approved,
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
                children: TransactionCategory.values.map((cat) {
                  return _buildCategoryChip(cat, colorScheme);
                }).toList(),
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
    final isSelected = _selectedCategory == category;
    final label = category.name.substring(0, 1).toUpperCase() + category.name.substring(1);
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
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
}
