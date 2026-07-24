import 'package:drift/drift.dart';
import 'package:ai_expense_tracker/domain/models/account.dart' as domain;
import 'package:ai_expense_tracker/domain/repositories/account_repository.dart';
import 'package:ai_expense_tracker/data/database.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase _db;

  AccountRepositoryImpl(this._db);

  domain.Account _mapToDomain(Account driftModel) {
    return domain.Account(
      id: driftModel.id,
      name: driftModel.name,
      balance: driftModel.balance,
      currency: driftModel.currency,
    );
  }

  @override
  Future<List<domain.Account>> getAllAccounts() async {
    final list = await _db.select(_db.accounts).get();
    return list.map(_mapToDomain).toList();
  }

  @override
  Future<int> insertAccount(domain.Account account) async {
    return await _db.into(_db.accounts).insert(
      AccountsCompanion(
        name: Value(account.name),
        balance: Value(account.balance),
        currency: Value(account.currency),
      ),
    );
  }

  @override
  Future<void> updateAccount(domain.Account account) async {
    await _db.update(_db.accounts).replace(
      Account(
        id: account.id,
        name: account.name,
        balance: account.balance,
        currency: account.currency,
      ),
    );
  }

  @override
  Future<void> ensureDefaultAccount() async {
    final list = await getAllAccounts();
    if (list.isEmpty) {
      await _db.into(_db.accounts).insert(
        const AccountsCompanion(
          name: Value("Checking"),
          balance: Value(0.0),
          currency: Value("USD"),
        ),
      );
    }
  }

  @override
  Future<void> deleteAccount(int id) async {
    await (_db.delete(_db.accounts)..where((tbl) => tbl.id.equals(id))).go();
  }
}
