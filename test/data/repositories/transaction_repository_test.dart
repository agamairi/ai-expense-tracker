import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:ai_expense_tracker/domain/models/enums.dart';

void main() {
  late AppDatabase db;
  late TransactionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  final testTransaction = domain.Transaction(
    id: 1,
    timestamp: DateTime(2023, 1, 1),
    amount: 10.0,
    currency: 'USD',
    type: TransactionType.debit,
    merchant: 'Test Merchant',
    category: TransactionCategory.dining,
    accountId: 1,
    rawText: 'raw',
    status: TransactionStatus.pending,
  );

  test('insertTransaction and getTransactionById round-trip', () async {
    final id = await repo.insertTransaction(testTransaction);
    final fetched = await repo.getTransactionById(id);
    expect(fetched, isNotNull);
    expect(fetched!.amount, testTransaction.amount);
    expect(fetched.merchant, testTransaction.merchant);
  });

  test('getAllTransactions returns inserted rows', () async {
    await repo.insertTransaction(testTransaction);
    await repo.insertTransaction(testTransaction.copyWith(id: 2, amount: 20.0));
    final list = await repo.getAllTransactions();
    expect(list.length, 2);
  });

  test('getTransactionsByStatus filters correctly', () async {
    await repo.insertTransaction(testTransaction.copyWith(id: 1, status: TransactionStatus.pending));
    await repo.insertTransaction(testTransaction.copyWith(id: 2, status: TransactionStatus.approved));
    
    final pending = await repo.getTransactionsByStatus(TransactionStatus.pending);
    expect(pending.length, 1);
    expect(pending.first.status, TransactionStatus.pending);

    final approved = await repo.getTransactionsByStatus(TransactionStatus.approved);
    expect(approved.length, 1);
    expect(approved.first.status, TransactionStatus.approved);
  });

  test('updateTransaction persists changes', () async {
    final id = await repo.insertTransaction(testTransaction);
    final fetched = await repo.getTransactionById(id);
    final updated = fetched!.copyWith(amount: 50.0, status: TransactionStatus.approved);
    await repo.updateTransaction(updated);
    
    final fetchedUpdated = await repo.getTransactionById(id);
    expect(fetchedUpdated!.amount, 50.0);
    expect(fetchedUpdated.status, TransactionStatus.approved);
  });

  test('deleteTransaction removes the row', () async {
    final id = await repo.insertTransaction(testTransaction);
    await repo.deleteTransaction(id);
    final fetched = await repo.getTransactionById(id);
    expect(fetched, isNull);
  });
}
