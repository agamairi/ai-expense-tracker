import 'package:ai_expense_tracker/domain/models/transaction.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAllTransactions();
  Future<List<Transaction>> getTransactionsByStatus(TransactionStatus status);
  Future<Transaction?> getTransactionById(int id);
  Future<int> insertTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(int id);
}
