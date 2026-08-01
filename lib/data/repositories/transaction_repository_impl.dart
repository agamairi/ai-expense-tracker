import 'package:drift/drift.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:ai_expense_tracker/data/database.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  domain.Transaction _mapToDomain(Transaction driftModel) {
    return domain.Transaction(
      id: driftModel.id,
      timestamp: driftModel.timestamp,
      amount: driftModel.amount,
      currency: driftModel.currency,
      type: driftModel.type,
      merchant: driftModel.merchant,
      category: driftModel.category,
      accountId: driftModel.accountId,
      rawText: driftModel.rawText,
      status: driftModel.status,
      customCategoryId: driftModel.customCategoryId,
    );
  }

  @override
  Future<List<domain.Transaction>> getAllTransactions() async {
    final list = await _db.select(_db.transactions).get();
    return list.map(_mapToDomain).toList();
  }

  @override
  Future<List<domain.Transaction>> getTransactionsByStatus(TransactionStatus status) async {
    final query = _db.select(_db.transactions)..where((tbl) => tbl.status.equals(status.index));
    final list = await query.get();
    return list.map(_mapToDomain).toList();
  }

  @override
  Future<domain.Transaction?> getTransactionById(int id) async {
    final query = _db.select(_db.transactions)..where((tbl) => tbl.id.equals(id));
    final item = await query.getSingleOrNull();
    return item != null ? _mapToDomain(item) : null;
  }

  @override
  Future<int> insertTransaction(domain.Transaction transaction) async {
    return await _db.into(_db.transactions).insert(
      TransactionsCompanion(
        timestamp: Value(transaction.timestamp),
        amount: Value(transaction.amount),
        currency: Value(transaction.currency),
        type: Value(transaction.type),
        merchant: Value(transaction.merchant),
        category: Value(transaction.category),
        accountId: Value(transaction.accountId),
        rawText: Value(transaction.rawText),
        status: Value(transaction.status),
        customCategoryId: Value(transaction.customCategoryId),
      ),
    );
  }

  @override
  Future<void> updateTransaction(domain.Transaction transaction) async {
    await _db.update(_db.transactions).replace(
      Transaction(
        id: transaction.id,
        timestamp: transaction.timestamp,
        amount: transaction.amount,
        currency: transaction.currency,
        type: transaction.type,
        merchant: transaction.merchant,
        category: transaction.category,
        accountId: transaction.accountId,
        rawText: transaction.rawText,
        status: transaction.status,
        customCategoryId: transaction.customCategoryId,
      ),
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await (_db.delete(_db.transactions)..where((tbl) => tbl.id.equals(id))).go();
  }
}
