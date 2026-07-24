import 'package:drift/drift.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  IntColumn get type => intEnum<TransactionType>()();
  TextColumn get merchant => text()();
  IntColumn get category => intEnum<TransactionCategory>()();
  IntColumn get accountId => integer()();
  TextColumn get rawText => text()();
  IntColumn get status => intEnum<TransactionStatus>()();
}

class AppRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchantRegex => text()();
  IntColumn get assignedCategory => intEnum<TransactionCategory>()();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get balance => real()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get category => intEnum<TransactionCategory>()();
  RealColumn get monthlyLimit => real()();
}
