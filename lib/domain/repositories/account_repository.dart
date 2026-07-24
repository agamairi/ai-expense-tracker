import 'package:ai_expense_tracker/domain/models/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAllAccounts();
  Future<int> insertAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(int id);
  Future<void> ensureDefaultAccount();
}
