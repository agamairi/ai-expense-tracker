import 'package:flutter/material.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:intl/intl.dart';
import 'package:ai_expense_tracker/domain/services/category_colors.dart';

class AuditLogView extends StatefulWidget {
  final TransactionCategory? initialCategory;
  final int? initialTab;
  const AuditLogView({super.key, this.initialCategory, this.initialTab});

  @override
  State<AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends State<AuditLogView> with WidgetsBindingObserver {
  final _repo = TransactionRepositoryImpl(AppDatabase.instance);
  int _selectedTab = 0; // 0 = Approved, 1 = Rejected, 2 = Pending
  
  List<model.Transaction> _transactions = [];
  bool _isLoading = true;
  TransactionCategory? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCategory = widget.initialCategory;
    _selectedTab = widget.initialTab ?? 0;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // In a real app, you would fetch by status directly if repository supports it efficiently
    final list = await _repo.getAllTransactions();
    
    setState(() {
      _transactions = list;
      _isLoading = false;
    });
  }

  List<model.Transaction> get _filteredTransactions {
    TransactionStatus targetStatus;
    if (_selectedTab == 0) {
      targetStatus = TransactionStatus.approved;
    } else if (_selectedTab == 1) {
      targetStatus = TransactionStatus.rejected;
    } else {
      targetStatus = TransactionStatus.pending;
    }

    return _transactions.where((tx) {
      final statusMatch = tx.status == targetStatus;
      final categoryMatch = _selectedCategory == null || tx.category == _selectedCategory;
      final dateMatch = _selectedDateRange == null ||
          (tx.timestamp.isAfter(_selectedDateRange!.start) &&
           tx.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      final searchMatch = _searchQuery.isEmpty ||
          tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase());
      return statusMatch && categoryMatch && dateMatch && searchMatch;
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<dynamic> get _groupedItems {
    final filtered = _filteredTransactions;
    if (filtered.isEmpty) return [];

    final List<dynamic> items = [];
    DateTime? lastDate;

    for (final tx in filtered) {
      final date = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      if (lastDate == null || date != lastDate) {
        items.add(date);
        lastDate = date;
      }
      items.add(tx);
    }
    return items;
  }

  Widget _buildDateHeader(DateTime date, ColorScheme colorScheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    String label;
    if (date == today) {
      label = "Today";
    } else if (date == yesterday) {
      label = "Yesterday";
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16, left: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  int _getCount(int tabIndex) {
    TransactionStatus targetStatus;
    if (tabIndex == 0) {
      targetStatus = TransactionStatus.approved;
    } else if (tabIndex == 1) {
      targetStatus = TransactionStatus.rejected;
    } else {
      targetStatus = TransactionStatus.pending;
    }

    return _transactions.where((tx) {
      return tx.status == targetStatus && (_selectedCategory == null || tx.category == _selectedCategory);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateRange != null 
                          ? "${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}"
                          : DateFormat('MMMM yyyy').format(DateTime.now()), 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedDateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          color: Colors.grey[400],
                          onPressed: () => setState(() => _selectedDateRange = null),
                        ),
                      GestureDetector(
                        onTap: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange: _selectedDateRange,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: colorScheme,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (range != null) {
                            setState(() => _selectedDateRange = range);
                          }
                        },
                        child: Icon(Icons.calendar_today, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by merchant...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomTabBar(colorScheme),
            const SizedBox(height: 16),
            _buildFilterRow(colorScheme),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      color: colorScheme.primary,
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groupedItems.length + 1, // +1 for bottom padding
                        itemBuilder: (context, index) {
                          if (index == _groupedItems.length) {
                            return const SizedBox(height: 130);
                          }
                          final item = _groupedItems[index];
                          if (item is DateTime) {
                            return _buildDateHeader(item, colorScheme);
                          }
                          final tx = item as model.Transaction;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildAuditCard(colorScheme, tx),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1),
      ),
      child: Row(
        children: [
          _buildTabItem(0, "Approved", _getCount(0).toString(), colorScheme),
          _buildTabItem(1, "Rejected", _getCount(1).toString(), colorScheme),
          _buildTabItem(2, "Pending", _getCount(2).toString(), colorScheme),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, String count, ColorScheme colorScheme) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : Colors.grey[400],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black.withAlpha(100) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip("All Categories", null, colorScheme),
          ...TransactionCategory.values.map((cat) {
            String name = cat.name;
            name = name[0].toUpperCase() + name.substring(1);
            return _buildFilterChip(name, cat, colorScheme);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionCategory? category, ColorScheme colorScheme) {
    final isSelected = _selectedCategory == category;
    final activeColor = category != null ? categoryColor(category) : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(50) : colorScheme.surfaceContainerHighest,
            border: Border.all(color: isSelected ? activeColor : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditCard(ColorScheme colorScheme, model.Transaction tx) {
    final isApproved = tx.status == TransactionStatus.approved;
    final isPending = tx.status == TransactionStatus.pending;
    final dateStr = DateFormat('MMM dd, HH:mm').format(tx.timestamp);
    final amountStr = "\$${tx.amount.toStringAsFixed(2)}";

    final card = Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isApproved ? colorScheme.primary.withAlpha(25) : 
                         isPending ? Colors.orange.withAlpha(25) : Colors.red.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApproved ? Icons.check_circle_outline : 
                  isPending ? Icons.pending_outlined : Icons.cancel_outlined, 
                  color: isApproved ? colorScheme.primary : 
                         isPending ? Colors.orange : Colors.red, 
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.merchant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text("ID: TR-${tx.id.toString().padLeft(4, '0')}", style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              if (tx.status == TransactionStatus.rejected)
                IconButton(
                  icon: const Icon(Icons.restore, size: 20),
                  color: Colors.grey[500],
                  onPressed: () async {
                    await _repo.updateTransaction(tx.copyWith(status: TransactionStatus.pending));
                    _loadData();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.grey[500],
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/edit', arguments: tx);
                  if (result == true) {
                    _loadData();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.grey[500],
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete this transaction?"),
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
                    await _repo.deleteTransaction(tx.id);
                    _loadData();
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amountStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tx.category.name.toUpperCase(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          // Granular Raw Text details
          if (tx.rawText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tx.rawText,
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey("tx_${tx.id}"),
      direction: isPending 
          ? DismissDirection.horizontal 
          : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (isPending) {
          if (direction == DismissDirection.endToStart) {
            await _repo.updateTransaction(tx.copyWith(status: TransactionStatus.rejected));
            _loadData();
          } else if (direction == DismissDirection.startToEnd) {
            await _repo.updateTransaction(tx.copyWith(status: TransactionStatus.approved));
            _loadData();
          }
        } else {
          if (direction == DismissDirection.endToStart) {
            final result = await Navigator.pushNamed(context, '/edit', arguments: tx);
            if (result == true) {
              _loadData();
            }
          }
        }
        return false;
      },
      background: isPending
          ? Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            )
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      secondaryBackground: isPending
          ? Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.close, color: Colors.white, size: 32),
            )
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.edit, color: Colors.white, size: 32),
            ),
      child: card,
    );
  }
}
