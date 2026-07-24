import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';

class ExportView extends StatefulWidget {
  const ExportView({super.key});

  @override
  State<ExportView> createState() => _ExportViewState();
}

class _ExportViewState extends State<ExportView> {
  bool _isCsvSelected = true;

  final List<_ColumnItem> _columns = [
    _ColumnItem("Date", true),
    _ColumnItem("Merchant", true),
    _ColumnItem("Amount", true),
    _ColumnItem("Category", true),
    _ColumnItem("Raw Text", false),
    _ColumnItem("Status", false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.account_circle, color: Colors.greenAccent),
        title: const Text(
          'Export Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Data\nColumns",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          "Select and drag to\nreorder",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = _columns.removeAt(oldIndex);
                            _columns.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < _columns.length; i++)
                            _buildColumnRow(i, _columns[i], colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(50),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCsvSelected = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isCsvSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  ".CSV",
                                  style: TextStyle(
                                    color: _isCsvSelected
                                        ? colorScheme.onPrimary
                                        : Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCsvSelected = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !_isCsvSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  ".JSON",
                                  style: TextStyle(
                                    color: !_isCsvSelected
                                        ? colorScheme.onPrimary
                                        : Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final repo = TransactionRepositoryImpl(
                            AppDatabase.instance,
                          );
                          final transactions = await repo.getAllTransactions();

                          final selectedColumns = _columns
                              .where((c) => c.isSelected)
                              .toList();

                          if (selectedColumns.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select at least one column.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exporting...')),
                            );
                          }

                          final tempDir = await getTemporaryDirectory();
                          final file = File(
                            '${tempDir.path}/expenses_export.${_isCsvSelected ? 'csv' : 'json'}',
                          );

                          if (_isCsvSelected) {
                            final StringBuffer csv = StringBuffer();
                            // Headers
                            csv.writeln(
                              selectedColumns
                                  .map((c) => _escapeCsv(c.name))
                                  .join(','),
                            );

                            // Rows
                            for (final tx in transactions) {
                              final row = selectedColumns
                                  .map((c) {
                                    switch (c.name) {
                                      case "Date":
                                        return _escapeCsv(
                                          DateFormat(
                                            'yyyy-MM-dd HH:mm:ss',
                                          ).format(tx.timestamp),
                                        );
                                      case "Merchant":
                                        return _escapeCsv(tx.merchant);
                                      case "Amount":
                                        return _escapeCsv(tx.amount.toString());
                                      case "Category":
                                        return _escapeCsv(tx.category.name);
                                      case "Raw Text":
                                        return _escapeCsv(tx.rawText);
                                      case "Status":
                                        return _escapeCsv(tx.status.name);
                                      default:
                                        return "";
                                    }
                                  })
                                  .join(',');
                              csv.writeln(row);
                            }
                            await file.writeAsString(csv.toString());
                          } else {
                            final List<Map<String, dynamic>> jsonList = [];
                            for (final tx in transactions) {
                              final Map<String, dynamic> row = {};
                              for (final c in selectedColumns) {
                                switch (c.name) {
                                  case "Date":
                                    row[c.name] = DateFormat(
                                      'yyyy-MM-dd HH:mm:ss',
                                    ).format(tx.timestamp);
                                    break;
                                  case "Merchant":
                                    row[c.name] = tx.merchant;
                                    break;
                                  case "Amount":
                                    row[c.name] = tx.amount;
                                    break;
                                  case "Category":
                                    row[c.name] = tx.category.name;
                                    break;
                                  case "Raw Text":
                                    row[c.name] = tx.rawText;
                                    break;
                                  case "Status":
                                    row[c.name] = tx.status.name;
                                    break;
                                }
                              }
                              jsonList.add(row);
                            }
                            await file.writeAsString(jsonEncode(jsonList));
                          }

                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path)],
                              text: 'Exported expenses data',
                            ),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Export successful!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Export failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text(
                        "Export Custom",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnRow(int index, _ColumnItem item, ColorScheme colorScheme) {
    return Container(
      key: ValueKey(item.name),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                item.isSelected = !item.isSelected;
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: item.isSelected
                      ? colorScheme.primary
                      : Colors.grey[700]!,
                ),
              ),
              child: item.isSelected
                  ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            item.name,
            style: TextStyle(
              color: item.isSelected ? Colors.white : Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

class _ColumnItem {
  final String name;
  bool isSelected;

  _ColumnItem(this.name, this.isSelected);
}
