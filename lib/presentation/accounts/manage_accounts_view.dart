import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_expense_tracker/domain/models/account.dart' as domain;
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/account_repository_impl.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/enums.dart';

class ManageAccountsView extends StatefulWidget {
  const ManageAccountsView({super.key});

  @override
  State<ManageAccountsView> createState() => _ManageAccountsViewState();
}

class _ManageAccountsViewState extends State<ManageAccountsView> {
  final _accountRepo = AccountRepositoryImpl(AppDatabase.instance);
  final _transactionRepo = TransactionRepositoryImpl(AppDatabase.instance);
  
  List<domain.Account> _accounts = [];
  List<model.Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final list = await _accountRepo.getAllAccounts();
    final txs = await _transactionRepo.getAllTransactions();
    setState(() {
      _accounts = list;
      _transactions = txs;
      _isLoading = false;
    });
  }

  Future<void> _deleteAccount(domain.Account account) async {
    final transactions = await _transactionRepo.getAllTransactions();
    final hasReferences = transactions.any((tx) => tx.accountId == account.id);

    if (hasReferences) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Cannot Delete Account"),
            content: const Text("This account is referenced by one or more transactions. You cannot delete it while it has transactions."),
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
          title: const Text("Delete account?"),
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
        await _accountRepo.deleteAccount(account.id);
        _loadAccounts();
      }
    }
  }

  void _showAddEditDialog([domain.Account? account]) {
    final nameController = TextEditingController(text: account?.name ?? '');
    final balanceController = TextEditingController(text: account != null ? account.balance.toStringAsFixed(2) : '0.00');
    final currencyController = TextEditingController(text: account?.currency ?? 'USD');
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(account == null ? "Add Account" : "Edit Account"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(
                        labelText: "Balance",
                        prefixText: "\$ ",
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: currencyController,
                      decoration: const InputDecoration(
                        labelText: "Currency",
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      onChanged: (val) {
                         if (val != val.toUpperCase()) {
                           currencyController.value = currencyController.value.copyWith(
                             text: val.toUpperCase(),
                           );
                         }
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
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text) ?? 0.0;
                    final currency = currencyController.text.toUpperCase();
                    
                    if (name.isEmpty) return;
                    if (currency.length != 3) return;

                    final newAccount = domain.Account(
                      id: account?.id ?? 0,
                      name: name,
                      balance: balance,
                      currency: currency,
                    );

                    if (account == null) {
                      await _accountRepo.insertAccount(newAccount);
                    } else {
                      await _accountRepo.updateAccount(newAccount);
                    }
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadAccounts();
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
        title: const Text("Manage Accounts"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Account"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _accounts.length,
            itemBuilder: (context, index) {
              final account = _accounts[index];
              double liveBalance = account.balance;
              for (final tx in _transactions) {
                if (tx.accountId == account.id && tx.status == TransactionStatus.approved) {
                  liveBalance += (tx.type == TransactionType.credit ? tx.amount : -tx.amount);
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
                    title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("${liveBalance.toStringAsFixed(2)} ${account.currency}", style: TextStyle(color: Colors.grey[400])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.grey[400],
                          onPressed: () => _showAddEditDialog(account),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.grey[400],
                          onPressed: () => _deleteAccount(account),
                        ),
                      ],
                    ),
                    onTap: () => _showAddEditDialog(account),
                  ),
                ),
              );
            },
          ),
    );
  }
}
