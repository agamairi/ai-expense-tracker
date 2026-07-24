import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/account_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/account.dart' as domain;

void main() {
  late AppDatabase db;
  late AccountRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AccountRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  final testAccount = domain.Account(
    id: 1,
    name: 'Savings',
    balance: 1000.0,
    currency: 'USD',
  );

  test('insertAccount and getAllAccounts round-trip', () async {
    await repo.insertAccount(testAccount);
    final list = await repo.getAllAccounts();
    expect(list.length, 2); // 1 checking (from onCreate) + 1 inserted
    expect(list.any((a) => a.name == 'Savings'), isTrue);
  });

  test('updateAccount persists changes', () async {
    // There is already 1 checking account, insert another to update
    await repo.insertAccount(testAccount);
    final list = await repo.getAllAccounts();
    final inserted = list.firstWhere((a) => a.name == 'Savings');
    
    await repo.updateAccount(domain.Account(
      id: inserted.id,
      name: inserted.name,
      balance: 2000.0,
      currency: inserted.currency,
    ));
    final updatedList = await repo.getAllAccounts();
    final updated = updatedList.firstWhere((a) => a.name == 'Savings');
    expect(updated.balance, 2000.0);
  });

  test('ensureDefaultAccount inserts exactly one account when empty, and is idempotent', () async {
    // Clear the table to simulate missing default account (e.g. from an old version migration)
    await db.delete(db.accounts).go();

    // Should be empty initially
    var list = await repo.getAllAccounts();
    expect(list.length, 0);

    // Call once
    await repo.ensureDefaultAccount();
    list = await repo.getAllAccounts();
    expect(list.length, 1);
    expect(list.first.name, 'Checking');

    // Call again (idempotent)
    await repo.ensureDefaultAccount();
    list = await repo.getAllAccounts();
    expect(list.length, 1); // Still 1
  });
}
